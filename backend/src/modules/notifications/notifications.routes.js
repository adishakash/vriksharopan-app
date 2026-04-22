const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { authenticate } = require('../../middleware/authenticate');

/**
 * GET /api/notifications  - Get notifications for logged-in user
 */
router.get('/', authenticate, async (req, res) => {
  const userId = req.user.sub;
  const { page = 1, limit = 30, unread_only } = req.query;
  const offset = (parseInt(page, 10) - 1) * parseInt(limit, 10);

  try {
    const conditions = ['user_id = $1'];
    const values = [userId];
    let idx = 2;

    if (unread_only === 'true') {
      conditions.push(`is_read = false`);
    }

    const where = `WHERE ${conditions.join(' AND ')}`;

    const [rows, count, unread] = await Promise.all([
      db.query(
        `SELECT * FROM notifications ${where} ORDER BY created_at DESC LIMIT $${idx++} OFFSET $${idx}`,
        [...values, limit, offset]
      ),
      db.query(`SELECT COUNT(*) FROM notifications ${where}`, values),
      db.query('SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND is_read = false', [userId]),
    ]);

    return res.json({
      success: true,
      data: {
        notifications: rows.rows,
        total: parseInt(count.rows[0].count, 10),
        unreadCount: parseInt(unread.rows[0].count, 10),
      },
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Failed to retrieve notifications.' });
  }
});

/**
 * PUT /api/notifications/mark-read  - Mark all or specific notifications as read
 */
router.put('/mark-read', authenticate, async (req, res) => {
  const userId = req.user.sub;
  const { ids } = req.body;

  try {
    if (ids && Array.isArray(ids) && ids.length > 0) {
      await db.query(
        `UPDATE notifications SET is_read = true, read_at = NOW()
         WHERE user_id = $1 AND id = ANY($2::uuid[])`,
        [userId, ids]
      );
    } else {
      await db.query(
        `UPDATE notifications SET is_read = true, read_at = NOW()
         WHERE user_id = $1 AND is_read = false`,
        [userId]
      );
    }
    return res.json({ success: true, message: 'Notifications marked as read.' });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Failed to update notifications.' });
  }
});

module.exports = router;
