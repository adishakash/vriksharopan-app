const jwt = require('jsonwebtoken');
const config = require('../config');

/**
 * Middleware to authenticate incoming requests using JWT.
 * Supports both user and admin tokens.
 */
const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, message: 'Access token required.' });
  }

  const token = authHeader.split(' ')[1];
  try {
    const payload = jwt.verify(token, config.jwt.secret);
    req.user = payload;
    return next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, message: 'Access token expired. Please refresh.' });
    }
    return res.status(401).json({ success: false, message: 'Invalid access token.' });
  }
};

/**
 * Role-based authorization middleware factory.
 * @param  {...string} roles - Allowed roles
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ success: false, message: 'Authentication required.' });
    }
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Access denied. Required role: ${roles.join(' or ')}.`,
      });
    }
    return next();
  };
};

/**
 * Middleware that allows either the resource owner or an admin to proceed.
 * Expects req.params.userId or req.params.id to be the target user ID.
 */
const ownerOrAdmin = (req, res, next) => {
  const { sub, role } = req.user;
  const targetId = req.params.userId || req.params.id;

  if (sub === targetId || role === 'admin' || role === 'superadmin') {
    return next();
  }
  return res.status(403).json({ success: false, message: 'Access denied.' });
};

module.exports = { authenticate, authorize, ownerOrAdmin };
