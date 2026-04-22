const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../../.env') });

const { Pool } = require('pg');
const config = require('../config');

const pool = new Pool({
  host: config.db.host,
  port: config.db.port,
  database: config.db.name,
  user: config.db.user,
  password: config.db.password,
  ssl: config.db.ssl,
});

const MIGRATIONS_DIR = path.join(__dirname, 'migrations');

async function ensureMigrationsTable(client) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      id          SERIAL PRIMARY KEY,
      filename    VARCHAR(255) UNIQUE NOT NULL,
      applied_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);
}

async function getAppliedMigrations(client) {
  const result = await client.query('SELECT filename FROM schema_migrations ORDER BY id');
  return result.rows.map((r) => r.filename);
}

async function applyMigration(client, filename) {
  const filepath = path.join(MIGRATIONS_DIR, filename);
  const sql = fs.readFileSync(filepath, 'utf8');
  console.log(`Applying migration: ${filename}`);
  await client.query(sql);
  await client.query('INSERT INTO schema_migrations (filename) VALUES ($1)', [filename]);
  console.log(`  ✓ ${filename} applied`);
}

async function migrate() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await ensureMigrationsTable(client);
    const applied = await getAppliedMigrations(client);
    const files = fs
      .readdirSync(MIGRATIONS_DIR)
      .filter((f) => f.endsWith('.sql'))
      .sort();

    let count = 0;
    for (const file of files) {
      if (!applied.includes(file)) {
        await applyMigration(client, file);
        count++;
      }
    }

    await client.query('COMMIT');

    if (count === 0) {
      console.log('All migrations already applied. Database is up to date.');
    } else {
      console.log(`\nMigration complete. Applied ${count} migration(s).`);
    }
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Migration failed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

migrate();
