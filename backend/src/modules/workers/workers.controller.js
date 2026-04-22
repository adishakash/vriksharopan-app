const db = require('../../config/database');
const logger = require('../../utils/logger');

/**
 * GET /api/workers/orders  (Worker only)
 * Returns pending and recent orders for the worker.
 */
const getOrders = async (req, res) => {
  const workerId = req.user.sub;
  const { status } = req.query;

  try {
    let query = `
      SELECT
        wo.*,
        t.tree_number, t.species, t.address_hint, t.latitude, t.longitude,
        cu.name AS customer_name
      FROM worker_orders wo
      JOIN trees t ON t.id = wo.tree_id
      JOIN users cu ON cu.id = t.customer_id
      WHERE wo.worker_id = $1
    `;
    const values = [workerId];

    if (status) {
      query += ` AND wo.status = $2`;
      values.push(status);
    }

    query += ' ORDER BY wo.assigned_at DESC LIMIT 50';

    const result = await db.query(query, values);
    return res.json({ success: true, data: result.rows });
  } catch (err) {
    logger.error('Get worker orders error:', err);
    return res.status(500).json({ success: false, message: 'Failed to retrieve orders.' });
  }
};

/**
 * PUT /api/workers/orders/:orderId  (Worker only)
 * Accept or reject an order.
 */
const updateOrderStatus = async (req, res) => {
  const { orderId } = req.params;
  const { status, rejection_reason } = req.body;
  const workerId = req.user.sub;

  const allowedStatuses = ['accepted', 'rejected', 'completed'];
  if (!allowedStatuses.includes(status)) {
    return res.status(400).json({ success: false, message: 'Invalid status.' });
  }

  try {
    const updateFields = { status };
    if (status === 'accepted') updateFields.accepted_at = 'NOW()';
    if (status === 'rejected') {
      updateFields.rejected_at = 'NOW()';
      updateFields.rejection_reason = rejection_reason;
    }
    if (status === 'completed') updateFields.completed_at = 'NOW()';

    const result = await db.query(
      `UPDATE worker_orders
       SET status = $1,
           accepted_at  = CASE WHEN $1 = 'accepted'  THEN NOW() ELSE accepted_at  END,
           rejected_at  = CASE WHEN $1 = 'rejected'  THEN NOW() ELSE rejected_at  END,
           completed_at = CASE WHEN $1 = 'completed' THEN NOW() ELSE completed_at END,
           rejection_reason = COALESCE($2, rejection_reason),
           updated_at = NOW()
       WHERE id = $3 AND worker_id = $4
       RETURNING *, (SELECT customer_id FROM trees WHERE id = tree_id) AS customer_id`,
      [status, rejection_reason, orderId, workerId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Order not found.' });
    }

    // When order completed, mark tree as planted
    if (status === 'completed') {
      await db.query(
        `UPDATE trees SET status = 'planted', planted_at = NOW() WHERE id = $1 AND worker_id = $2`,
        [result.rows[0].tree_id, workerId]
      );

      // Update worker stats
      await db.query(
        `UPDATE worker_profiles SET total_trees_planted = total_trees_planted + 1 WHERE user_id = $1`,
        [workerId]
      );
    }

    return res.json({ success: true, message: `Order ${status}.`, data: result.rows[0] });
  } catch (err) {
    logger.error('Update order status error:', err);
    return res.status(500).json({ success: false, message: 'Failed to update order.' });
  }
};

/**
 * GET /api/workers/earnings  (Worker only)
 */
const getEarnings = async (req, res) => {
  const workerId = req.user.sub;
  const { month, year } = req.query;

  try {
    const profileRes = await db.query(
      `SELECT total_earnings, pending_earnings, active_trees, total_trees_planted
       FROM worker_profiles WHERE user_id = $1`,
      [workerId]
    );

    const earningsRes = await db.query(
      `SELECT we.*, t.tree_number
       FROM worker_earnings we
       LEFT JOIN trees t ON t.id = we.tree_id
       WHERE we.worker_id = $1
       ORDER BY we.created_at DESC
       LIMIT 100`,
      [workerId]
    );

    return res.json({
      success: true,
      data: {
        summary: profileRes.rows[0] || {},
        earnings: earningsRes.rows,
      },
    });
  } catch (err) {
    logger.error('Get earnings error:', err);
    return res.status(500).json({ success: false, message: 'Failed to retrieve earnings.' });
  }
};

/**
 * POST /api/workers/attendance/check-in  (Worker only)
 */
const checkIn = async (req, res) => {
  const workerId = req.user.sub;
  const { latitude, longitude } = req.body;

  try {
    const existing = await db.query(
      `SELECT id, check_out_at FROM worker_attendance
       WHERE worker_id = $1 AND date = CURRENT_DATE`,
      [workerId]
    );

    if (existing.rows.length > 0 && !existing.rows[0].check_out_at) {
      return res.status(409).json({ success: false, message: 'Already checked in today.' });
    }

    await db.query(
      `INSERT INTO worker_attendance (id, worker_id, latitude, longitude, date)
       VALUES (gen_random_uuid(), $1, $2, $3, CURRENT_DATE)
       ON CONFLICT (worker_id, date) DO UPDATE
       SET check_in_at = NOW(), latitude = $2, longitude = $3, check_out_at = NULL`,
      [workerId, latitude, longitude]
    );

    return res.json({ success: true, message: 'Checked in successfully.', data: { checkedInAt: new Date() } });
  } catch (err) {
    logger.error('Check-in error:', err);
    return res.status(500).json({ success: false, message: 'Check-in failed.' });
  }
};

/**
 * POST /api/workers/attendance/check-out  (Worker only)
 */
const checkOut = async (req, res) => {
  const workerId = req.user.sub;

  try {
    const result = await db.query(
      `UPDATE worker_attendance
       SET check_out_at = NOW()
       WHERE worker_id = $1 AND date = CURRENT_DATE AND check_out_at IS NULL
       RETURNING *`,
      [workerId]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({ success: false, message: 'No active check-in found.' });
    }

    return res.json({ success: true, message: 'Checked out successfully.', data: result.rows[0] });
  } catch (err) {
    logger.error('Check-out error:', err);
    return res.status(500).json({ success: false, message: 'Check-out failed.' });
  }
};

/**
 * GET /api/workers/dashboard  (Worker only)
 */
const getDashboard = async (req, res) => {
  const workerId = req.user.sub;

  try {
    const [profile, pendingOrders, recentActivity] = await Promise.all([
      db.query(
        `SELECT wp.*, u.name, u.email, u.mobile
         FROM worker_profiles wp
         JOIN users u ON u.id = wp.user_id
         WHERE wp.user_id = $1`,
        [workerId]
      ),
      db.query(
        `SELECT COUNT(*) AS count FROM worker_orders
         WHERE worker_id = $1 AND status IN ('pending', 'accepted', 'in_progress')`,
        [workerId]
      ),
      db.query(
        `SELECT wo.*, t.tree_number FROM worker_orders wo
         JOIN trees t ON t.id = wo.tree_id
         WHERE wo.worker_id = $1 ORDER BY wo.updated_at DESC LIMIT 5`,
        [workerId]
      ),
    ]);

    return res.json({
      success: true,
      data: {
        profile: profile.rows[0] || {},
        pendingOrdersCount: parseInt(pendingOrders.rows[0].count, 10),
        recentActivity: recentActivity.rows,
      },
    });
  } catch (err) {
    logger.error('Worker dashboard error:', err);
    return res.status(500).json({ success: false, message: 'Failed to load dashboard.' });
  }
};

/**
 * POST /api/workers/sync  (Worker only)
 * Handles offline data sync - accepts batched actions from worker app.
 */
const syncOfflineData = async (req, res) => {
  const workerId = req.user.sub;
  const { actions = [] } = req.body;

  if (!Array.isArray(actions) || actions.length === 0) {
    return res.json({ success: true, message: 'Nothing to sync.', data: { processed: 0 } });
  }

  const results = [];

  for (const action of actions) {
    try {
      if (action.type === 'maintenance_log') {
        await db.query(
          `INSERT INTO tree_maintenance_logs (id, tree_id, worker_id, action, health, notes, latitude, longitude, logged_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
           ON CONFLICT DO NOTHING`,
          [
            action.id,
            action.tree_id,
            workerId,
            action.action,
            action.health,
            action.notes,
            action.latitude,
            action.longitude,
            action.logged_at || new Date(),
          ]
        );
        results.push({ id: action.id, status: 'synced' });
      }
    } catch (err) {
      logger.error('Sync action error:', { action, error: err.message });
      results.push({ id: action.id, status: 'failed', error: err.message });
    }
  }

  return res.json({
    success: true,
    message: 'Sync completed.',
    data: { processed: results.length, results },
  });
};

module.exports = { getOrders, updateOrderStatus, getEarnings, checkIn, checkOut, getDashboard, syncOfflineData };
