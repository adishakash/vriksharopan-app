const logger = require('../utils/logger');

/**
 * Global error handler middleware.
 * Must be registered as the last middleware in Express.
 */
const errorHandler = (err, req, res, next) => {
  // Log the full error internally
  logger.error('Unhandled error', {
    message: err.message,
    stack: err.stack,
    url: req.originalUrl,
    method: req.method,
    body: req.body,
    user: req.user ? req.user.sub : 'unauthenticated',
  });

  // PostgreSQL unique constraint violation
  if (err.code === '23505') {
    return res.status(409).json({ success: false, message: 'A record with this value already exists.' });
  }

  // PostgreSQL foreign key violation
  if (err.code === '23503') {
    return res.status(400).json({ success: false, message: 'Referenced record does not exist.' });
  }

  // Multer file size error
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({ success: false, message: 'File too large. Maximum size is 5MB.' });
  }

  // Default server error (never expose stack in production)
  const statusCode = err.statusCode || err.status || 500;
  return res.status(statusCode).json({
    success: false,
    message: err.expose ? err.message : 'An internal server error occurred.',
  });
};

module.exports = errorHandler;
