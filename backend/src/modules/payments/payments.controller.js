const Razorpay = require('razorpay');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
const config = require('../../config');
const db = require('../../config/database');
const logger = require('../../utils/logger');
const notificationService = require('../../utils/notifications');

const razorpay = config.razorpay.keyId && config.razorpay.keySecret
  ? new Razorpay({
      key_id: config.razorpay.keyId,
      key_secret: config.razorpay.keySecret,
    })
  : null;

if (!razorpay) {
  logger.warn('Razorpay is disabled because credentials are not configured.');
}

// ── RAZORPAY PLAN IDs ──────────────────────────────────────────
// These are created once in Razorpay dashboard.
// Monthly plan: INR 99 per tree per month.
// You must create the plan in Razorpay and store ID in env.
const MONTHLY_PLAN_ID = process.env.RAZORPAY_PLAN_ID || process.env.RAZORPAY_MONTHLY_PLAN_ID || 'plan_monthly_99';

/**
 * Create or get a Razorpay customer for the user.
 */
const ensureRazorpayCustomer = async (user, profile) => {
  if (profile.razorpay_customer_id) return profile.razorpay_customer_id;

  const customer = await razorpay.customers.create({
    name: user.name,
    email: user.email,
    contact: user.mobile || '',
    notes: { userId: user.id },
  });

  await db.query(
    'UPDATE customer_profiles SET razorpay_customer_id = $1 WHERE user_id = $2',
    [customer.id, user.id]
  );

  return customer.id;
};

/**
 * POST /api/payments/create-subscription
 * Creates a Razorpay subscription for the customer.
 */
const createSubscription = async (req, res) => {
  const { tree_count = 1 } = req.body;
  const userId = req.user.sub;

  if (!razorpay) {
    return res.status(503).json({ success: false, message: 'Payments are not configured.' });
  }

  if (tree_count < 1 || tree_count > 100) {
    return res.status(400).json({ success: false, message: 'tree_count must be between 1 and 100.' });
  }

  try {
    const userRes = await db.query('SELECT id, name, email, mobile FROM users WHERE id = $1', [userId]);
    const profileRes = await db.query('SELECT * FROM customer_profiles WHERE user_id = $1', [userId]);

    if (userRes.rows.length === 0) return res.status(404).json({ success: false, message: 'User not found.' });

    const user = userRes.rows[0];
    const profile = profileRes.rows[0] || {};

    const customerId = await ensureRazorpayCustomer(user, profile);
    const amount = config.pricing.treePriceMonthly * tree_count * 100; // in paise

    // Create subscription in Razorpay
    const subscription = await razorpay.subscriptions.create({
      plan_id: MONTHLY_PLAN_ID,
      customer_notify: 1,
      quantity: tree_count,
      total_count: 120, // 10 years
      notes: { userId, treeCount: tree_count },
    });

    // Store in DB
    await db.query(
      `INSERT INTO subscriptions
         (id, customer_id, razorpay_subscription_id, razorpay_plan_id, tree_count, amount_per_cycle, status)
       VALUES ($1, $2, $3, $4, $5, $6, 'pending')`,
      [
        uuidv4(),
        userId,
        subscription.id,
        MONTHLY_PLAN_ID,
        tree_count,
        (config.pricing.treePriceMonthly * tree_count),
      ]
    );

    return res.status(201).json({
      success: true,
      message: 'Subscription created. Complete payment to activate.',
      data: {
        subscriptionId: subscription.id,
        shortUrl: subscription.short_url,
        razorpayKeyId: config.razorpay.keyId,
        amount,
        currency: 'INR',
        treeCount: tree_count,
      },
    });
  } catch (err) {
    logger.error('Create subscription error:', err);
    return res.status(500).json({ success: false, message: 'Failed to create subscription.' });
  }
};

/**
 * POST /api/payments/webhook
 * Handles Razorpay webhook events.
 */
const handleWebhook = async (req, res) => {
  const signature = req.headers['x-razorpay-signature'];
  const body = JSON.stringify(req.body);

  // Verify webhook signature
  const expectedSignature = crypto
    .createHmac('sha256', config.razorpay.webhookSecret)
    .update(body)
    .digest('hex');

  if (signature !== expectedSignature) {
    logger.warn('Invalid Razorpay webhook signature');
    return res.status(400).json({ success: false, message: 'Invalid signature.' });
  }

  const event = req.body.event;
  const payload = req.body.payload;

  try {
    switch (event) {
      case 'subscription.activated':
        await onSubscriptionActivated(payload.subscription.entity);
        break;
      case 'subscription.charged':
        await onSubscriptionCharged(payload.payment.entity, payload.subscription.entity);
        break;
      case 'subscription.cancelled':
        await onSubscriptionCancelled(payload.subscription.entity);
        break;
      case 'payment.captured':
        await onPaymentCaptured(payload.payment.entity);
        break;
      case 'payment.failed':
        await onPaymentFailed(payload.payment.entity);
        break;
      default:
        logger.info(`Unhandled Razorpay event: ${event}`);
    }

    return res.json({ success: true });
  } catch (err) {
    logger.error(`Webhook handler error for event ${event}:`, err);
    return res.status(500).json({ success: false });
  }
};

const onSubscriptionActivated = async (subscription) => {
  const result = await db.query(
    `UPDATE subscriptions
     SET status = 'active',
         current_start = to_timestamp($1),
         current_end   = to_timestamp($2),
         charge_at     = to_timestamp($3)
     WHERE razorpay_subscription_id = $4
     RETURNING id, customer_id, tree_count`,
    [subscription.current_start, subscription.current_end, subscription.charge_at, subscription.id]
  );

  if (result.rows.length === 0) return;
  const sub = result.rows[0];

  // Provision trees for the customer
  await provisionTrees(sub.customer_id, sub.id, sub.tree_count);

  await notificationService.sendToUser(sub.customer_id, {
    title: 'Subscription Activated!',
    body: `Your subscription for ${sub.tree_count} tree(s) is now active.`,
    type: 'payment_success',
  });
};

const onSubscriptionCharged = async (payment, subscription) => {
  const subRes = await db.query(
    'SELECT id, customer_id FROM subscriptions WHERE razorpay_subscription_id = $1',
    [subscription.id]
  );
  if (subRes.rows.length === 0) return;

  const sub = subRes.rows[0];

  await db.query(
    `INSERT INTO payments (id, user_id, subscription_id, razorpay_payment_id, amount, status, captured_at)
     VALUES ($1, $2, $3, $4, $5, 'captured', NOW())
     ON CONFLICT (razorpay_payment_id) DO NOTHING`,
    [uuidv4(), sub.customer_id, sub.id, payment.id, payment.amount / 100]
  );

  // Update subscription cycle dates
  await db.query(
    `UPDATE subscriptions
     SET current_start = to_timestamp($1),
         current_end   = to_timestamp($2),
         paid_count    = paid_count + 1
     WHERE razorpay_subscription_id = $3`,
    [subscription.current_start, subscription.current_end, subscription.id]
  );

  await notificationService.sendToUser(sub.customer_id, {
    title: 'Payment Successful',
    body: `Monthly subscription payment received. Your trees are growing!`,
    type: 'payment_success',
  });
};

const onSubscriptionCancelled = async (subscription) => {
  const result = await db.query(
    `UPDATE subscriptions SET status = 'cancelled', cancelled_at = NOW()
     WHERE razorpay_subscription_id = $1
     RETURNING customer_id`,
    [subscription.id]
  );

  if (result.rows.length === 0) return;

  await notificationService.sendToUser(result.rows[0].customer_id, {
    title: 'Subscription Cancelled',
    body: 'Your subscription has been cancelled.',
    type: 'subscription_renewal',
  });
};

const onPaymentCaptured = async (payment) => {
  await db.query(
    `UPDATE payments SET status = 'captured', captured_at = NOW()
     WHERE razorpay_payment_id = $1`,
    [payment.id]
  );
};

const onPaymentFailed = async (payment) => {
  await db.query(
    `UPDATE payments SET status = 'failed' WHERE razorpay_payment_id = $1`,
    [payment.id]
  );

  const paymentRow = await db.query(
    'SELECT user_id FROM payments WHERE razorpay_payment_id = $1',
    [payment.id]
  );
  if (paymentRow.rows.length > 0) {
    await notificationService.sendToUser(paymentRow.rows[0].user_id, {
      title: 'Payment Failed',
      body: 'Your payment could not be processed. Please update your payment method.',
      type: 'payment_failed',
    });
  }
};

/**
 * Auto-provision trees for a newly activated subscription.
 */
const provisionTrees = async (customerId, subscriptionId, count) => {
  const existing = await db.query(
    'SELECT COUNT(*) FROM trees WHERE customer_id = $1 AND subscription_id = $2',
    [customerId, subscriptionId]
  );

  const existingCount = parseInt(existing.rows[0].count, 10);
  const toCreate = count - existingCount;

  if (toCreate <= 0) return;

  const inserts = [];
  for (let i = 0; i < toCreate; i++) {
    inserts.push(
      db.query(
        `INSERT INTO trees (customer_id, subscription_id, status)
         VALUES ($1, $2, 'pending_assignment')`,
        [customerId, subscriptionId]
      )
    );
  }
  await Promise.all(inserts);

  await db.query(
    `UPDATE customer_profiles
     SET total_trees = total_trees + $1
     WHERE user_id = $2`,
    [toCreate, customerId]
  );
};

/**
 * GET /api/payments
 * Returns paginated payment history for logged-in user.
 */
const getPayments = async (req, res) => {
  const userId = req.user.sub;
  const { page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page, 10) - 1) * parseInt(limit, 10);

  try {
    const result = await db.query(
      `SELECT p.*, s.tree_count FROM payments p
       LEFT JOIN subscriptions s ON s.id = p.subscription_id
       WHERE p.user_id = $1
       ORDER BY p.created_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    const count = await db.query('SELECT COUNT(*) FROM payments WHERE user_id = $1', [userId]);

    return res.json({
      success: true,
      data: {
        payments: result.rows,
        total: parseInt(count.rows[0].count, 10),
        page: parseInt(page, 10),
        limit: parseInt(limit, 10),
      },
    });
  } catch (err) {
    logger.error('Get payments error:', err);
    return res.status(500).json({ success: false, message: 'Failed to retrieve payments.' });
  }
};

/**
 * POST /api/payments/refund/:paymentId (Admin only)
 */
const refundPayment = async (req, res) => {
  const { paymentId } = req.params;
  const { amount, reason } = req.body;

  if (!razorpay) {
    return res.status(503).json({ success: false, message: 'Payments are not configured.' });
  }

  try {
    const paymentRes = await db.query(
      'SELECT * FROM payments WHERE id = $1',
      [paymentId]
    );
    if (paymentRes.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Payment not found.' });
    }

    const payment = paymentRes.rows[0];
    if (payment.status !== 'captured') {
      return res.status(400).json({ success: false, message: 'Only captured payments can be refunded.' });
    }

    const refundAmount = amount ? Math.round(amount * 100) : Math.round(payment.amount * 100);

    const refund = await razorpay.payments.refund(payment.razorpay_payment_id, {
      amount: refundAmount,
      notes: { reason: reason || 'Admin initiated refund' },
    });

    await db.query(
      `UPDATE payments SET status = 'refunded', refunded_at = NOW(), refund_id = $1
       WHERE id = $2`,
      [refund.id, paymentId]
    );

    return res.json({ success: true, message: 'Refund initiated successfully.', data: { refundId: refund.id } });
  } catch (err) {
    logger.error('Refund error:', err);
    return res.status(500).json({ success: false, message: 'Refund failed.' });
  }
};

module.exports = { createSubscription, handleWebhook, getPayments, refundPayment };
