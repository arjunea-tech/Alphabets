/**
 * Startup schema patches.
 *
 * Adds columns the code relies on to databases created before those columns
 * existed. Each patch is safe to run on every start: an existing column is
 * left untouched. (migrateMultiLanguage.js does the same job but only works on
 * MySQL, so PostgreSQL databases never received these columns.)
 */
const { pool, isPostgres } = require('./db');
const logger = require('../utils/logger');

const MULTI_LANGUAGE_TABLES = [
  'letters',
  'letter_groups',
  'lessons',
  'reading_stories',
  'quizzes',
  'games',
  'videos',
  'users',
];

const COLUMN_PATCHES = [
  ...MULTI_LANGUAGE_TABLES.flatMap((table) => [
    { table, column: 'language_code', definition: "VARCHAR(10) NOT NULL DEFAULT 'en'" },
    { table, column: 'tenant_id', definition: "VARCHAR(64) NULL DEFAULT 'default'" },
  ]),
  // Content unlocked (scratch code / payment) — kept on the account so it is asked only once.
  { table: 'users', column: 'has_content_access', definition: 'BOOLEAN NOT NULL DEFAULT FALSE' },
  { table: 'users', column: 'access_method', definition: 'VARCHAR(20) NULL' },
  { table: 'users', column: 'access_granted_at', definition: 'TIMESTAMP NULL' },
];

async function addColumn({ table, column, definition }) {
  const sql = isPostgres
    ? `ALTER TABLE ${table} ADD COLUMN IF NOT EXISTS ${column} ${definition}`
    : `ALTER TABLE ${table} ADD COLUMN ${column} ${definition}`;
  try {
    await pool.query(sql);
  } catch (err) {
    // MySQL has no IF NOT EXISTS for columns: a duplicate-column error means it is already there.
    if (err.code === 'ER_DUP_FIELDNAME') return;
    logger.warn(`⚠️ Could not ensure ${table}.${column} column: ${err.message}`);
  }
}

// Key/value settings the admin can edit (e.g. content price). Same SQL works on MySQL and PostgreSQL.
async function ensureAppSettingsTable() {
  try {
    await pool.query(
      `CREATE TABLE IF NOT EXISTS app_settings (
        setting_key VARCHAR(64) NOT NULL PRIMARY KEY,
        setting_value TEXT NOT NULL,
        updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
      )`
    );
  } catch (err) {
    logger.warn(`⚠️ Could not ensure app_settings table: ${err.message}`);
  }
}

async function applySchemaPatches() {
  for (const patch of COLUMN_PATCHES) {
    await addColumn(patch);
  }
  await ensureAppSettingsTable();
}

module.exports = { applySchemaPatches };
