const db = require('../../config/database');
const logger = require('../../utils/logger');
const notificationService = require('../../utils/notifications');

// ── Dashboard ─────────────────────────────────────────────────────────────────

/**
 * GET /api/admin/dashboard
 */
const getDashboard = async (req, res) => {
  try {
    const [customers, workers, trees, revenue, monthlyRevenue, treesByStatus] = await Promise.all([
      db.query("SELECT COUNT(*) FROM users WHERE role = 'customer' AND status = 'active'"),
      db.query("SELECT COUNT(*) FROM worker_profiles WHERE worker_status = 'active'"),
      db.query("SELECT COUNT(*) FROM trees"),
      db.query("SELECT COALESCE(SUM(amount),0) AS total FROM payments WHERE status = 'captured'"),
      db.query(`
        SELECT
          TO_CHAR(created_at, 'YYYY-MM') AS month,
          COALESCE(SUM(amount), 0) AS revenue
        FROM payments
        WHERE status = 'captured' AND created_at > NOW() - INTERVAL '12 months'
        GROUP BY month ORDER BY month
      `),
      db.query("SELECT status, COUNT(*) FROM trees GROUP BY status"),
    ]);

    return res.json({
      success: true,
      data: {
        totalCustomers: parseInt(customers.rows[0].count, 10),
        totalWorkers: parseInt(workers.rows[0].count, 10),
        totalTrees: parseInt(trees.rows[0].count, 10),
        totalRevenue: parseFloat(revenue.rows[0].total),
        monthlyRevenue: monthlyRevenue.rows,
        treesByStatus: treesByStatus.rows,
      },
    });
  } catch (err) {
    logger.error('Admin dashboard error:', err);
    return res.status(500).json({ success: false, message: 'Failed to load admin dashboard.' });
  }
};

// ── Customer Management ───────────────────────────────────────────────────────

const getCustomers = async (req, res) => {
  const { page = 1, limit = 20, search, status } = req.query;
  const offset = (parseInt(page, 10) - 1) * parseInt(limit, 10);

  try {
    const conditions = ["u.role = 'customer'"];
    const values = [];
    let idx = 1;

    if (search) {
      conditions.push(`(u.name ILIKE $${idx} OR u.email ILIKE $${idx} OR u.mobile ILIKE $${idx})`);
      values.push(`%${search}%`);
      idx++;
    }
    if (status) {
      conditions.push(`u.status = $${idx++}`);
      values.push(status);
    }

    const where = `WHERE ${conditions.join(' AND ')}`;

    const [rows, count] = await Promise.all([
      db.query(
        `SELECT u.id, u.name, u.email, u.mobile, u.status, u.created_at,
                cp.total_trees, cp.active_trees, cp.pin_code
         FROM users u
         LEFT JOIN customer_profiles cp ON cp.user_id = u.id
         ${where}
         ORDER BY u.created_at DESC
         LIMIT $${idx++} OFFSET $${idx}`,
        [...values, limit, offset]
      ),
      db.query(`SELECT COUNT(*) FROM users u ${where}`, values),
    ]);

    return res.json({
      success: true,
      data: { customers: rows.rows, total: parseInt(count.rows[0].count, 10), page: parseInt(page, 10) },
    });
  } catch (err) {
    logger.error('Get customers error:', err);
    return res.status(500).json({ success: false, message: 'Failed to retrieve customers.' });
  }
};

const updateCustomerStatus = async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  const validStatuses = ['active', 'inactive', 'suspended'];

  if (!validStatuses.includes(status)) {
    return res.status(400).json({ success: false, message: 'Invalid status.' });
  }

  try {
    await db.query("UPDATE users SET status = $1 WHERE id = $2 AND role = 'customer'", [status, id]);
    return res.json({ success: true, message: `Customer ${status}.` });
  } catch (err) {
    logger.error('Update customer status error:', err);
    return res.status(500).json({ success: false, message: 'Update failed.' });
  }
};

// ── Worker Management ─────────────────────────────────────────────────────────

const getWorkers = async (req, res) => {
  const { page = 1, limit = 20, search, status } = req.query;
  const offset = (parseInt(page, 10) - 1) * parseInt(limit, 10);

  try {
    const conditions = ["u.role = 'worker'"];
    const values = [];
    let idx = 1;

    if (search) {
      conditions.push(`(u.name ILIKE $${idx} OR u.email ILIKE $${idx})`);
      values.push(`%${search}%`);
      idx++;
    }
    if (status) {
      conditions.push(`wp.worker_status = $${idx++}`);
      values.push(status);
    }

    const where = `WHERE ${conditions.join(' AND ')}`;

    const [rows, count] = await Promise.all([
      db.query(
        `SELECT u.id, u.name, u.email, u.mobile, u.status, u.created_at,
                wp.worker_status, wp.active_trees, wp.total_trees_planted, wp.rating, wp.total_earnings, wp.pin_code
         FROM users u
         LEFT JOIN worker_profiles wp ON wp.user_id = u.id
         ${where}
         ORDER BY u.created_at DESC
         LIMIT $${idx++} OFFSET $${idx}`,
        [...values, limit, offset]
      ),
      db.query(`SELECT COUNT(*) FROM users u LEFT JOIN worker_profiles wp ON wp.user_id = u.id ${where}`, values),
    ]);

    return res.json({
      success: true,
      data: { workers: rows.rows, total: parseInt(count.rows[0].count, 10), page: parseInt(page, 10) },
    });
  } catch (err) {
    logger.error('Get workers error:', err);
    return res.status(500).json({ success: false, message: 'Failed to retrieve workers.' });
  }
};

const approveWorker = async (req, res) => {
  const { id } = req.params;
  const adminId = req.user.sub;

  try {
    const result = await db.query(
      `UPDATE worker_profiles
       SET worker_status = 'active', verified_at = NOW(), approved_by_id = $1
       WHERE user_id = $2
       RETURNING user_id`,
      [adminId, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Worker not found.' });
    }

    await notificationService.sendToUser(id, {
      title: 'Account Approved',
      body: 'Your worker account has been approved. You can now receive orders.',
      type: 'broadcast',
    });

    return res.json({ success: true, message: 'Worker approved.' });
  } catch (err) {
    logger.error('Approve worker error:', err);
    return res.status(500).json({ success: false, message: 'Approval failed.' });
  }
};

// ── Photo Moderation ──────────────────────────────────────────────────────────

const getPendingPhotos = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT tp.*, t.tree_number, wu.name AS worker_name
       FROM tree_photos tp
       JOIN trees t ON t.id = tp.tree_id
       JOIN users wu ON wu.id = tp.worker_id
       WHERE tp.status = 'pending_review'
       ORDER BY tp.created_at ASC
       LIMIT 50`
    );
    return res.json({ success: true, data: result.rows });
  } catch (err) {
    logger.error('Get pending photos error:', err);
    return res.status(500).json({ success: false, message: 'Failed to retrieve photos.' });
  }
};

const moderatePhoto = async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  const adminId = req.user.sub;

  if (!['approved', 'rejected'].includes(status)) {
    return res.status(400).json({ success: false, message: 'Status must be approved or rejected.' });
  }

  try {
    const result = await db.query(
      `UPDATE tree_photos
       SET status = $1, reviewed_by = $2, reviewed_at = NOW()
       WHERE id = $3
       RETURNING tree_id`,
      [status, adminId, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Photo not found.' });
    }

    // If approved, update tree's cover photo
    if (status === 'approved') {
      const photo = await db.query('SELECT photo_url FROM tree_photos WHERE id = $1', [id]);
      if (photo.rows.length > 0) {
        await db.query(
          'UPDATE trees SET cover_photo_url = $1 WHERE id = $2 AND (cover_photo_url IS NULL)',
          [photo.rows[0].photo_url, result.rows[0].tree_id]
        );
      }
    }

    return res.json({ success: true, message: `Photo ${status}.` });
  } catch (err) {
    logger.error('Moderate photo error:', err);
    return res.status(500).json({ success: false, message: 'Moderation failed.' });
  }
};

// ── Notifications ─────────────────────────────────────────────────────────────

const sendBroadcast = async (req, res) => {
  const { title, body, type = 'broadcast' } = req.body;

  if (!title || !body) {
    return res.status(400).json({ success: false, message: 'Title and body are required.' });
  }

  try {
    await notificationService.broadcastToAll({ title, body, type });
    return res.json({ success: true, message: 'Broadcast sent.' });
  } catch (err) {
    logger.error('Send broadcast error:', err);
    return res.status(500).json({ success: false, message: 'Broadcast failed.' });
  }
};

// ── Analytics ─────────────────────────────────────────────────────────────────

const getAnalytics = async (req, res) => {
  const { period = '12' } = req.query;
  const months = parseInt(period, 10);

  try {
    const [treesPerMonth, revenuePerMonth, workerProductivity, topCustomers] = await Promise.all([
      db.query(
        `SELECT TO_CHAR(planted_at, 'YYYY-MM') AS month, COUNT(*) AS trees_planted
         FROM trees WHERE planted_at > NOW() - INTERVAL '${months} months'
         GROUP BY month ORDER BY month`
      ),
      db.query(
        `SELECT TO_CHAR(captured_at, 'YYYY-MM') AS month, SUM(amount) AS revenue
         FROM payments WHERE status = 'captured' AND captured_at > NOW() - INTERVAL '${months} months'
         GROUP BY month ORDER BY month`
      ),
      db.query(
        `SELECT u.id, u.name, wp.total_trees_planted, wp.rating
         FROM worker_profiles wp
         JOIN users u ON u.id = wp.user_id
         WHERE wp.worker_status = 'active'
         ORDER BY wp.total_trees_planted DESC
         LIMIT 10`
      ),
      db.query(
        `SELECT u.id, u.name, cp.total_trees, COALESCE(SUM(p.amount),0) AS total_paid
         FROM customer_profiles cp
         JOIN users u ON u.id = cp.user_id
         LEFT JOIN payments p ON p.user_id = u.id AND p.status = 'captured'
         GROUP BY u.id, u.name, cp.total_trees
         ORDER BY cp.total_trees DESC
         LIMIT 10`
      ),
    ]);

    return res.json({
      success: true,
      data: {
        treesPerMonth: treesPerMonth.rows,
        revenuePerMonth: revenuePerMonth.rows,
        workerProductivity: workerProductivity.rows,
        topCustomers: topCustomers.rows,
      },
    });
  } catch (err) {
    logger.error('Analytics error:', err);
    return res.status(500).json({ success: false, message: 'Failed to load analytics.' });
  }
};

module.exports = {
  getDashboard,
  getCustomers,
  updateCustomerStatus,
  getWorkers,
  approveWorker,
  getPendingPhotos,
  moderatePhoto,
  sendBroadcast,
  getAnalytics,
};
