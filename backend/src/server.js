const app = require('./app');
const config = require('./config');
const logger = require('./utils/logger');
const { pool } = require('./config/database');

const PORT = config.port;

// Graceful shutdown handler
const shutdown = async (signal) => {
  logger.info(`Received ${signal}. Starting graceful shutdown...`);
  try {
    await pool.end();
    logger.info('Database pool closed.');
    process.exit(0);
  } catch (err) {
    logger.error('Error during shutdown:', err);
    process.exit(1);
  }
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

process.on('uncaughtException', (err) => {
  logger.error('Uncaught Exception:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason) => {
  logger.error('Unhandled Rejection:', reason);
  process.exit(1);
});

const server = app.listen(PORT, () => {
  logger.info(`Vrisharopan API running on port ${PORT} in ${config.env} mode`);
});

server.timeout = 30000; // 30s request timeout

module.exports = server;
