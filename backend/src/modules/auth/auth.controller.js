const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const crypto = require('crypto');
const config = require('../../config');
const db = require('../../config/database');
const logger = require('../../utils/logger');

const SALT_ROUNDS = 12;

/**
 * Hash a plain-text password.
 */
const hashPassword = async (password) => bcrypt.hash(password, SALT_ROUNDS);

/**
 * Compare a plain-text password against a hash.
 */
const comparePassword = async (password, hash) => bcrypt.compare(password, hash);

/**
 * Sign a JWT access token.
 */
const signAccessToken = (payload) =>
  jwt.sign(payload, config.jwt.secret, { expiresIn: config.jwt.expiresIn });

/**
 * Sign a JWT refresh token.
 */
const signRefreshToken = (payload) =>
  jwt.sign(payload, config.jwt.refreshSecret, { expiresIn: config.jwt.refreshExpiresIn });

/**
 * Store a hashed refresh token in DB for the user.
 */
const storeRefreshToken = async (userId, rawToken) => {
  const hash = crypto.createHash('sha256').update(rawToken).digest('hex');
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days
  await db.query(
    `INSERT INTO refresh_tokens (id, user_id, token_hash, expires_at)
     VALUES ($1, $2, $3, $4)`,
    [uuidv4(), userId, hash, expiresAt]
  );
  return hash;
};

/**
 * Issue both tokens and store refresh token.
 */
const issueTokens = async (user) => {
  const payload = { sub: user.id, role: user.role, email: user.email };
  const accessToken = signAccessToken(payload);
  const refreshToken = signRefreshToken(payload);
  await storeRefreshToken(user.id, refreshToken);
  return { accessToken, refreshToken };
};

// ──────────────────────────────────────────────────────────────
// AUTH CONTROLLERS
// ──────────────────────────────────────────────────────────────

/**
 * POST /api/auth/register
 * Registers a new customer or worker.
 */
const register = async (req, res) => {
  const { name, email, password, mobile, role = 'customer', address, city, state, pin_code, referral_code } = req.body;

  const allowedRoles = ['customer', 'worker'];
  if (!allowedRoles.includes(role)) {
    return res.status(400).json({ success: false, message: 'Invalid role. Must be customer or worker.' });
  }

  try {
    // Check duplicate email
    const existing = await db.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existing.rows.length > 0) {
      return res.status(409).json({ success: false, message: 'An account with this email already exists.' });
    }

    const passwordHash = await hashPassword(password);

    // Resolve referrer
    let referredById = null;
    if (referral_code) {
      const referrer = await db.query('SELECT id FROM users WHERE referral_code = $1', [referral_code]);
      if (referrer.rows.length > 0) {
        referredById = referrer.rows[0].id;
      }
    }

    const result = await db.withTransaction(async (client) => {
      // Insert user
      const userRes = await client.query(
        `INSERT INTO users (name, email, password_hash, mobile, role, referred_by_id)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING id, name, email, mobile, role, referral_code, created_at`,
        [name, email, passwordHash, mobile, role, referredById]
      );
      const user = userRes.rows[0];

      // Insert profile
      if (role === 'customer') {
        await client.query(
          `INSERT INTO customer_profiles (user_id, address, city, state, pin_code)
           VALUES ($1, $2, $3, $4, $5)`,
          [user.id, address, city, state, pin_code]
        );
      } else if (role === 'worker') {
        await client.query(
          `INSERT INTO worker_profiles (user_id, address, city, state, pin_code)
           VALUES ($1, $2, $3, $4, $5)`,
          [user.id, address, city, state, pin_code]
        );
      }

      // Record referral
      if (referredById) {
        await client.query(
          `INSERT INTO referrals (referrer_id, referred_id) VALUES ($1, $2)`,
          [referredById, user.id]
        );
      }

      return user;
    });

    const tokens = await issueTokens(result);

    return res.status(201).json({
      success: true,
      message: 'Registration successful.',
      data: {
        user: {
          id: result.id,
          name: result.name,
          email: result.email,
          mobile: result.mobile,
          role: result.role,
          referralCode: result.referral_code,
        },
        ...tokens,
      },
    });
  } catch (err) {
    logger.error('Registration error:', err);
    return res.status(500).json({ success: false, message: 'Registration failed. Please try again.' });
  }
};

/**
 * POST /api/auth/login
 */
const login = async (req, res) => {
  const { email, password } = req.body;

  try {
    const userRes = await db.query(
      `SELECT u.id, u.name, u.email, u.password_hash, u.role, u.status, u.fcm_token, u.referral_code
       FROM users u WHERE u.email = $1`,
      [email]
    );

    if (userRes.rows.length === 0) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    const user = userRes.rows[0];

    if (user.status === 'suspended') {
      return res.status(403).json({ success: false, message: 'Your account has been suspended. Contact support.' });
    }

    const valid = await comparePassword(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    // Update last login
    await db.query('UPDATE users SET last_login_at = NOW() WHERE id = $1', [user.id]);

    const tokens = await issueTokens(user);

    // Fetch role-specific profile
    let profile = null;
    if (user.role === 'customer') {
      const p = await db.query('SELECT * FROM customer_profiles WHERE user_id = $1', [user.id]);
      profile = p.rows[0] || null;
    } else if (user.role === 'worker') {
      const p = await db.query('SELECT * FROM worker_profiles WHERE user_id = $1', [user.id]);
      profile = p.rows[0] || null;
    }

    return res.json({
      success: true,
      message: 'Login successful.',
      data: {
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          status: user.status,
          referralCode: user.referral_code,
          profile,
        },
        ...tokens,
      },
    });
  } catch (err) {
    logger.error('Login error:', err);
    return res.status(500).json({ success: false, message: 'Login failed. Please try again.' });
  }
};

/**
 * POST /api/auth/admin/login
 */
const adminLogin = async (req, res) => {
  const { email, password } = req.body;

  try {
    const adminRes = await db.query(
      'SELECT id, name, email, password_hash, role, is_active FROM admin_users WHERE email = $1',
      [email]
    );

    if (adminRes.rows.length === 0) {
      return res.status(401).json({ success: false, message: 'Invalid credentials.' });
    }

    const admin = adminRes.rows[0];

    if (!admin.is_active) {
      return res.status(403).json({ success: false, message: 'Admin account is disabled.' });
    }

    const valid = await comparePassword(password, admin.password_hash);
    if (!valid) {
      return res.status(401).json({ success: false, message: 'Invalid credentials.' });
    }

    await db.query('UPDATE admin_users SET last_login_at = NOW() WHERE id = $1', [admin.id]);

    const payload = { sub: admin.id, role: admin.role, email: admin.email, isAdmin: true };
    const accessToken = signAccessToken(payload);

    return res.json({
      success: true,
      data: {
        admin: { id: admin.id, name: admin.name, email: admin.email, role: admin.role },
        accessToken,
      },
    });
  } catch (err) {
    logger.error('Admin login error:', err);
    return res.status(500).json({ success: false, message: 'Login failed.' });
  }
};

/**
 * POST /api/auth/refresh
 */
const refreshTokens = async (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) {
    return res.status(400).json({ success: false, message: 'Refresh token required.' });
  }

  try {
    const payload = jwt.verify(refreshToken, config.jwt.refreshSecret);
    const hash = crypto.createHash('sha256').update(refreshToken).digest('hex');

    const tokenRes = await db.query(
      `SELECT id FROM refresh_tokens
       WHERE user_id = $1 AND token_hash = $2 AND expires_at > NOW() AND revoked_at IS NULL`,
      [payload.sub, hash]
    );

    if (tokenRes.rows.length === 0) {
      return res.status(401).json({ success: false, message: 'Invalid or expired refresh token.' });
    }

    // Revoke old token
    await db.query('UPDATE refresh_tokens SET revoked_at = NOW() WHERE token_hash = $1', [hash]);

    // Get user
    const userRes = await db.query('SELECT id, name, email, role, status FROM users WHERE id = $1', [payload.sub]);
    if (userRes.rows.length === 0) {
      return res.status(401).json({ success: false, message: 'User not found.' });
    }

    const tokens = await issueTokens(userRes.rows[0]);
    return res.json({ success: true, data: tokens });
  } catch (err) {
    logger.error('Token refresh error:', err);
    return res.status(401).json({ success: false, message: 'Invalid refresh token.' });
  }
};

/**
 * POST /api/auth/logout
 */
const logout = async (req, res) => {
  const { refreshToken } = req.body;
  if (refreshToken) {
    const hash = crypto.createHash('sha256').update(refreshToken).digest('hex');
    await db.query('UPDATE refresh_tokens SET revoked_at = NOW() WHERE token_hash = $1', [hash]);
  }
  return res.json({ success: true, message: 'Logged out successfully.' });
};

/**
 * POST /api/auth/change-password
 */
const changePassword = async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  const userId = req.user.sub;

  try {
    const userRes = await db.query('SELECT password_hash FROM users WHERE id = $1', [userId]);
    if (userRes.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    const valid = await comparePassword(currentPassword, userRes.rows[0].password_hash);
    if (!valid) {
      return res.status(401).json({ success: false, message: 'Current password is incorrect.' });
    }

    const newHash = await hashPassword(newPassword);
    await db.query('UPDATE users SET password_hash = $1 WHERE id = $2', [newHash, userId]);

    // Revoke all existing refresh tokens
    await db.query('UPDATE refresh_tokens SET revoked_at = NOW() WHERE user_id = $1 AND revoked_at IS NULL', [userId]);

    return res.json({ success: true, message: 'Password changed successfully. Please login again.' });
  } catch (err) {
    logger.error('Change password error:', err);
    return res.status(500).json({ success: false, message: 'Failed to change password.' });
  }
};

module.exports = { register, login, adminLogin, refreshTokens, logout, changePassword, hashPassword, comparePassword };
