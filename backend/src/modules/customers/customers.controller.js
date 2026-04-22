const db = require('../../config/database');
const logger = require('../../utils/logger');

/**
 * GET /api/customers/dashboard  (Customer only)
 */
const getDashboard = async (req, res) => {
  const userId = req.user.sub;

  try {
    const [user, profile, trees, payments] = await Promise.all([
      db.query('SELECT id, name, email, mobile, referral_code, created_at FROM users WHERE id = $1', [userId]),
      db.query('SELECT * FROM customer_profiles WHERE user_id = $1', [userId]),
      db.query(
        `SELECT status, COUNT(*) AS count FROM trees WHERE customer_id = $1 GROUP BY status`,
        [userId]
      ),
      db.query(
        `SELECT COALESCE(SUM(amount), 0) AS total_paid FROM payments
         WHERE user_id = $1 AND status = 'captured'`,
        [userId]
      ),
    ]);

    const treeSummary = {};
    for (const row of trees.rows) {
      treeSummary[row.status] = parseInt(row.count, 10);
    }
    const totalTrees = Object.values(treeSummary).reduce((a, b) => a + b, 0);
    const activeTrees = treeSummary['active'] || treeSummary['planted'] || 0;

    // Environmental impact metrics
    const co2Absorbed = activeTrees * 21.77; // kg CO2 per year per tree
    const oxygenGenerated = activeTrees * 100; // kg O2 per year per tree

    return res.json({
      success: true,
      data: {
        user: user.rows[0],
        profile: profile.rows[0] || {},
        impact: {
          totalTrees,
          activeTrees,
          co2AbsorbedKg: co2Absorbed.toFixed(2),
          oxygenGeneratedKg: oxygenGenerated.toFixed(2),
          treesPlanted: treeSummary,
        },
        totalSpent: parseFloat(payments.rows[0].total_paid),
      },
    });
  } catch (err) {
    logger.error('Customer dashboard error:', err);
    return res.status(500).json({ success: false, message: 'Failed to load dashboard.' });
  }
};

/**
 * PUT /api/customers/profile  (Customer only)
 * Update customer profile.
 */
const updateProfile = async (req, res) => {
  const userId = req.user.sub;
  const { name, mobile, address, city, state, pin_code } = req.body;

  try {
    await db.withTransaction(async (client) => {
      if (name || mobile) {
        await client.query(
          `UPDATE users SET
             name   = COALESCE($1, name),
             mobile = COALESCE($2, mobile),
             updated_at = NOW()
           WHERE id = $3`,
          [name, mobile, userId]
        );
      }

      if (address !== undefined || city !== undefined || state !== undefined || pin_code !== undefined) {
        await client.query(
          `UPDATE customer_profiles SET
             address  = COALESCE($1, address),
             city     = COALESCE($2, city),
             state    = COALESCE($3, state),
             pin_code = COALESCE($4, pin_code),
             updated_at = NOW()
           WHERE user_id = $5`,
          [address, city, state, pin_code, userId]
        );
      }
    });

    return res.json({ success: true, message: 'Profile updated.' });
  } catch (err) {
    logger.error('Update profile error:', err);
    return res.status(500).json({ success: false, message: 'Failed to update profile.' });
  }
};

/**
 * GET /api/customers/referrals  (Customer only)
 * Get referral stats and history.
 */
const getReferrals = async (req, res) => {
  const userId = req.user.sub;

  try {
    const userRes = await db.query('SELECT referral_code FROM users WHERE id = $1', [userId]);
    const referrals = await db.query(
      `SELECT r.created_at, r.reward_granted,
              u.name AS referred_name, u.email AS referred_email
       FROM referrals r
       JOIN users u ON u.id = r.referred_id
       WHERE r.referrer_id = $1
       ORDER BY r.created_at DESC`,
      [userId]
    );

    return res.json({
      success: true,
      data: {
        referralCode: userRes.rows[0]?.referral_code,
        referralLink: `https://vrisharopan.in/register?ref=${userRes.rows[0]?.referral_code}`,
        referrals: referrals.rows,
        totalReferrals: referrals.rows.length,
        rewardedReferrals: referrals.rows.filter((r) => r.reward_granted).length,
      },
    });
  } catch (err) {
    logger.error('Get referrals error:', err);
    return res.status(500).json({ success: false, message: 'Failed to retrieve referrals.' });
  }
};

/**
 * PUT /api/customers/fcm-token  (Customer only)
 * Update FCM token for push notifications.
 */
const updateFcmToken = async (req, res) => {
  const { fcm_token } = req.body;
  const userId = req.user.sub;

  try {
    await db.query('UPDATE users SET fcm_token = $1 WHERE id = $2', [fcm_token, userId]);
    return res.json({ success: true, message: 'FCM token updated.' });
  } catch (err) {
    logger.error('Update FCM token error:', err);
    return res.status(500).json({ success: false, message: 'Failed to update token.' });
  }
};

module.exports = { getDashboard, updateProfile, getReferrals, updateFcmToken };
