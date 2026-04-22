const { v4: uuidv4 } = require('uuid');
const db = require('../../config/database');
const logger = require('../../utils/logger');
const notificationService = require('../../utils/notifications');

/**
 * GET /api/trees - paginated list of trees for logged-in customer or admin
 */
const getTrees = async (req, res) => {
  const { sub: userId, role } = req.user;
  const { page = 1, limit = 20, status, health, worker_id } = req.query;
  const offset = (parseInt(page, 10) - 1) * parseInt(limit, 10);

  try {
    const conditions = [];
    const values = [];
    let idx = 1;

    if (role === 'customer') {
      conditions.push(`t.customer_id = $${idx++}`);
      values.push(userId);
    }

    if (status) {
      conditions.push(`t.status = $${idx++}`);
      values.push(status);
    }
    if (health) {
      conditions.push(`t.health = $${idx++}`);
      values.push(health);
    }
    if (worker_id && (role === 'admin' || role === 'superadmin')) {
      conditions.push(`t.worker_id = $${idx++}`);
      values.push(worker_id);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const treesQuery = `
      SELECT
        t.id, t.tree_number, t.species, t.common_name, t.status, t.health,
        t.planted_at, t.latitude, t.longitude, t.cover_photo_url,
        t.address_hint, t.is_gift, t.is_adopted, t.notes, t.created_at,
        cu.name AS customer_name,
        wu.name AS worker_name
      FROM trees t
      LEFT JOIN users cu ON cu.id = t.customer_id
      LEFT JOIN users wu ON wu.id = t.worker_id
      ${whereClause}
      ORDER BY t.created_at DESC
      LIMIT $${idx++} OFFSET $${idx}
    `;

    const countQuery = `SELECT COUNT(*) FROM trees t ${whereClause}`;

    const [treesResult, countResult] = await Promise.all([
      db.query(treesQuery, [...values, limit, offset]),
      db.query(countQuery, values),
    ]);

    return res.json({
      success: true,
      data: {
        trees: treesResult.rows,
        total: parseInt(countResult.rows[0].count, 10),
        page: parseInt(page, 10),
        limit: parseInt(limit, 10),
      },
    });
  } catch (err) {
    logger.error('Get trees error:', err);
    return res.status(500).json({ success: false, message: 'Failed to retrieve trees.' });
  }
};

/**
 * GET /api/trees/:id - single tree with full details
 */
const getTreeById = async (req, res) => {
  const { id } = req.params;
  const { sub: userId, role } = req.user;

  try {
    const treeRes = await db.query(
      `SELECT
         t.*,
         cu.name AS customer_name, cu.email AS customer_email,
         wu.name AS worker_name, wu.email AS worker_email
       FROM trees t
       LEFT JOIN users cu ON cu.id = t.customer_id
       LEFT JOIN users wu ON wu.id = t.worker_id
       WHERE t.id = $1`,
      [id]
    );

    if (treeRes.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Tree not found.' });
    }

    const tree = treeRes.rows[0];

    // Non-admin users can only see their own trees
    if (role === 'customer' && tree.customer_id !== userId) {
      return res.status(403).json({ success: false, message: 'Access denied.' });
    }

    // Fetch photos and maintenance logs
    const [photos, maintenance] = await Promise.all([
      db.query(
        `SELECT tp.*, wu.name AS worker_name
         FROM tree_photos tp
         JOIN users wu ON wu.id = tp.worker_id
         WHERE tp.tree_id = $1 AND tp.status = 'approved'
         ORDER BY tp.taken_at DESC`,
        [id]
      ),
      db.query(
        `SELECT tml.*, wu.name AS worker_name
         FROM tree_maintenance_logs tml
         JOIN users wu ON wu.id = tml.worker_id
         WHERE tml.tree_id = $1
         ORDER BY tml.logged_at DESC`,
        [id]
      ),
    ]);

    return res.json({
      success: true,
      data: {
        tree,
        photos: photos.rows,
        maintenanceLogs: maintenance.rows,
      },
    });
  } catch (err) {
    logger.error('Get tree by ID error:', err);
    return res.status(500).json({ success: false, message: 'Failed to retrieve tree.' });
  }
};

/**
 * POST /api/trees/:id/geo-tag  (Worker only)
 * Worker geo-tags a tree's location.
 */
const geoTagTree = async (req, res) => {
  const { id } = req.params;
  const { latitude, longitude, address_hint } = req.body;
  const workerId = req.user.sub;

  if (!latitude || !longitude) {
    return res.status(400).json({ success: false, message: 'latitude and longitude are required.' });
  }

  try {
    const result = await db.query(
      `UPDATE trees
       SET latitude = $1, longitude = $2, address_hint = $3,
           geo_point = ST_SetSRID(ST_MakePoint($2, $1), 4326)
       WHERE id = $4 AND worker_id = $5
       RETURNING id, tree_number, latitude, longitude`,
      [latitude, longitude, address_hint, id, workerId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Tree not found or not assigned to you.' });
    }

    return res.json({ success: true, message: 'Tree geo-tagged successfully.', data: result.rows[0] });
  } catch (err) {
    logger.error('Geo-tag error:', err);
    return res.status(500).json({ success: false, message: 'Geo-tagging failed.' });
  }
};

/**
 * POST /api/trees/:id/photos  (Worker only)
 * Worker uploads a photo for a tree.
 */
const uploadPhoto = async (req, res) => {
  const { id: treeId } = req.params;
  const workerId = req.user.sub;

  if (!req.file) {
    return res.status(400).json({ success: false, message: 'Photo file is required.' });
  }

  const { latitude, longitude, caption } = req.body;
  const photoUrl = req.file.location; // S3 URL

  try {
    // Verify tree is assigned to this worker
    const treeRes = await db.query(
      'SELECT id, customer_id, tree_number FROM trees WHERE id = $1 AND worker_id = $2',
      [treeId, workerId]
    );

    if (treeRes.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Tree not found or not assigned to you.' });
    }

    const photoRes = await db.query(
      `INSERT INTO tree_photos (id, tree_id, worker_id, photo_url, caption, latitude, longitude)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [uuidv4(), treeId, workerId, photoUrl, caption, latitude, longitude]
    );

    return res.status(201).json({
      success: true,
      message: 'Photo uploaded successfully. Pending admin review.',
      data: photoRes.rows[0],
    });
  } catch (err) {
    logger.error('Upload photo error:', err);
    return res.status(500).json({ success: false, message: 'Photo upload failed.' });
  }
};

/**
 * POST /api/trees/:id/maintenance  (Worker only)
 * Worker logs a maintenance action.
 */
const logMaintenance = async (req, res) => {
  const { id: treeId } = req.params;
  const workerId = req.user.sub;
  const { action, health, notes, latitude, longitude } = req.body;

  try {
    const treeRes = await db.query(
      'SELECT id, customer_id FROM trees WHERE id = $1 AND worker_id = $2',
      [treeId, workerId]
    );

    if (treeRes.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Tree not assigned to you.' });
    }

    const logRes = await db.query(
      `INSERT INTO tree_maintenance_logs (id, tree_id, worker_id, action, health, notes, latitude, longitude)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [uuidv4(), treeId, workerId, action, health, notes, latitude, longitude]
    );

    // Update tree health status
    if (health) {
      await db.query('UPDATE trees SET health = $1, updated_at = NOW() WHERE id = $2', [health, treeId]);
    }

    // Notify customer
    await notificationService.sendToUser(treeRes.rows[0].customer_id, {
      title: 'Tree Updated',
      body: `Your tree has been ${action}. Health status: ${health || 'updated'}.`,
      type: 'tree_updated',
      data: { treeId },
    });

    return res.status(201).json({ success: true, message: 'Maintenance logged.', data: logRes.rows[0] });
  } catch (err) {
    logger.error('Log maintenance error:', err);
    return res.status(500).json({ success: false, message: 'Failed to log maintenance.' });
  }
};

/**
 * POST /api/trees/gift  (Customer only)
 * Gift a tree to a friend or family.
 */
const giftTree = async (req, res) => {
  const { tree_id, to_email, to_name, message } = req.body;
  const fromUserId = req.user.sub;

  try {
    // Verify tree belongs to sender
    const treeRes = await db.query(
      "SELECT id FROM trees WHERE id = $1 AND customer_id = $2 AND status = 'active'",
      [tree_id, fromUserId]
    );

    if (treeRes.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Active tree not found.' });
    }

    // Check if recipient is a registered user
    const recipientRes = await db.query('SELECT id FROM users WHERE email = $1', [to_email]);
    const toUserId = recipientRes.rows.length > 0 ? recipientRes.rows[0].id : null;

    const giftRes = await db.query(
      `INSERT INTO gifts (id, from_user_id, to_user_id, to_email, to_name, tree_id, message)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [uuidv4(), fromUserId, toUserId, to_email, to_name, tree_id, message]
    );

    // Update tree gift flag
    await db.query(
      'UPDATE trees SET is_gift = TRUE, gift_from_id = $1, gift_message = $2 WHERE id = $3',
      [fromUserId, message, tree_id]
    );

    if (toUserId) {
      await notificationService.sendToUser(toUserId, {
        title: 'You Received a Tree Gift!',
        body: `${to_name} has gifted you a tree. Message: ${message || 'Enjoy your tree!'}`,
        type: 'gift_tree',
        data: { giftId: giftRes.rows[0].id },
      });
    }

    return res.status(201).json({ success: true, message: 'Tree gifted successfully.', data: giftRes.rows[0] });
  } catch (err) {
    logger.error('Gift tree error:', err);
    return res.status(500).json({ success: false, message: 'Gifting failed.' });
  }
};

/**
 * POST /api/trees/:id/assign-worker  (Admin only)
 */
const assignWorker = async (req, res) => {
  const { id: treeId } = req.params;
  const { worker_id } = req.body;

  try {
    const workerRes = await db.query(
      "SELECT wp.id FROM worker_profiles wp JOIN users u ON u.id = wp.user_id WHERE u.id = $1 AND wp.worker_status = 'active'",
      [worker_id]
    );

    if (workerRes.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Active worker not found.' });
    }

    const result = await db.query(
      `UPDATE trees SET worker_id = $1, status = 'assigned', updated_at = NOW()
       WHERE id = $2
       RETURNING id, tree_number, customer_id`,
      [worker_id, treeId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Tree not found.' });
    }

    // Create a planting order for the worker
    await db.query(
      `INSERT INTO worker_orders (id, tree_id, worker_id, order_type, status)
       VALUES ($1, $2, $3, 'plant', 'pending')`,
      [uuidv4(), treeId, worker_id]
    );

    await notificationService.sendToUser(worker_id, {
      title: 'New Planting Order',
      body: `You have been assigned a new tree to plant. Tree #${result.rows[0].tree_number}.`,
      type: 'new_order',
      data: { treeId },
    });

    return res.json({ success: true, message: 'Worker assigned successfully.', data: result.rows[0] });
  } catch (err) {
    logger.error('Assign worker error:', err);
    return res.status(500).json({ success: false, message: 'Failed to assign worker.' });
  }
};

/**
 * GET /api/trees/map  - Returns trees with coordinates for map display
 */
const getTreesForMap = async (req, res) => {
  const { sub: userId, role } = req.user;
  const { sw_lat, sw_lng, ne_lat, ne_lng } = req.query;

  try {
    let query, values;

    if (sw_lat && sw_lng && ne_lat && ne_lng) {
      // Bounding box query using PostGIS
      query = `
        SELECT id, tree_number, latitude, longitude, status, health, species, common_name, cover_photo_url
        FROM trees
        WHERE geo_point IS NOT NULL
          AND ST_Within(geo_point, ST_MakeEnvelope($1, $2, $3, $4, 4326))
          ${role === 'customer' ? 'AND customer_id = $5' : ''}
        LIMIT 1000
      `;
      values = role === 'customer'
        ? [sw_lng, sw_lat, ne_lng, ne_lat, userId]
        : [sw_lng, sw_lat, ne_lng, ne_lat];
    } else {
      query = `
        SELECT id, tree_number, latitude, longitude, status, health, species, common_name, cover_photo_url
        FROM trees
        WHERE latitude IS NOT NULL AND longitude IS NOT NULL
          ${role === 'customer' ? 'AND customer_id = $1' : ''}
        LIMIT 1000
      `;
      values = role === 'customer' ? [userId] : [];
    }

    const result = await db.query(query, values);
    return res.json({ success: true, data: result.rows });
  } catch (err) {
    logger.error('Get trees for map error:', err);
    return res.status(500).json({ success: false, message: 'Failed to retrieve map data.' });
  }
};

module.exports = { getTrees, getTreeById, geoTagTree, uploadPhoto, logMaintenance, giftTree, assignWorker, getTreesForMap };
