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

const COLUMN_PATCHES = MULTI_LANGUAGE_TABLES.flatMap((table) => [
  { table, column: 'language_code', definition: "VARCHAR(10) NOT NULL DEFAULT 'en'" },
  { table, column: 'tenant_id', definition: "VARCHAR(64) NULL DEFAULT 'default'" },
]);

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

async function applySchemaPatches() {
  for (const patch of COLUMN_PATCHES) {
    await addColumn(patch);
  }
}

module.exports = { applySchemaPatches };
