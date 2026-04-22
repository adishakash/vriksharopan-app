const { Pool } = require('pg');
const config = require('../config');
const logger = require('../utils/logger');

const pool = new Pool({
  host: config.db.host,
  port: config.db.port,
  database: config.db.name,
  user: config.db.user,
  password: config.db.password,
  ssl: config.db.ssl,
  min: config.db.pool.min,
  max: config.db.pool.max,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on('error', (err) => {
  logger.error('Unexpected database pool error:', err);
});

pool.on('connect', () => {
  logger.debug('New database client connected');
});

/**
 * Execute a query against the pool.
 * @param {string} text  SQL query string
 * @param {Array}  params Query parameters
 */
const query = async (text, params) => {
  const start = Date.now();
  try {
    const result = await pool.query(text, params);
    const duration = Date.now() - start;
    logger.debug('Executed query', { text, duration, rows: result.rowCount });
    return result;
  } catch (err) {
    logger.error('Database query error', { text, error: err.message });
    throw err;
  }
};

/**
 * Acquire a client from the pool for transactions.
 */
const getClient = async () => {
  const client = await pool.connect();
  const originalQuery = client.query.bind(client);
  const release = client.release.bind(client);

  // Override release to log long-held clients
  const timeout = setTimeout(() => {
    logger.warn('A client has been checked out for more than 30 seconds!');
  }, 30000);

  client.release = () => {
    clearTimeout(timeout);
    client.query = originalQuery;
    client.release = release;
    return release();
  };

  return client;
};

/**
 * Execute multiple queries inside a transaction.
 * @param {Function} callback receives (client) and should execute queries
 */
const withTransaction = async (callback) => {
  const client = await getClient();
  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

module.exports = { query, getClient, withTransaction, pool };
