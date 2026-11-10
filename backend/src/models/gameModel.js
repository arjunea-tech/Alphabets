/**
 * Games Data Access Model
 *
 * Every piece of game content (missions, target letters/words, distractors)
 * lives in the database and is managed from the admin panel. The Flutter app
 * renders exactly what is stored here — it has no hardcoded game content.
 *
 * levels_json shape:
 *   [{ "title": "Vowels", "prompt": "Pop only vowels", "targets": ["A","E"], "distractors": ["B","C"] }]
 */
const { pool, isPostgres } = require('../config/db');
const logger = require('../utils/logger');

let schemaReady = null;

/** Adds the levels_json column to databases created before it existed. Runs once per process. */
function ensureSchema() {
  if (!schemaReady) {
    const sql = isPostgres
      ? 'ALTER TABLE games ADD COLUMN IF NOT EXISTS levels_json JSON NULL'
      : 'ALTER TABLE games ADD COLUMN levels_json JSON NULL';
    schemaReady = pool.query(sql).catch((err) => {
      // MySQL has no IF NOT EXISTS for columns: a duplicate-column error means it is already there.
      if (err.code !== 'ER_DUP_FIELDNAME') {
        logger.warn(`⚠️ Could not ensure games.levels_json column: ${err.message}`);
        schemaReady = null;
      }
    });
  }
  return schemaReady;
}

function parseJson(value, fallback) {
  if (value === null || value === undefined) return fallback;
  if (typeof value !== 'string') return value;
  try {
    return JSON.parse(value);
  } catch (_) {
    return fallback;
  }
}

function toStringList(value) {
  if (Array.isArray(value)) {
    return value.map((v) => String(v).trim()).filter(Boolean);
  }
  if (typeof value === 'string') {
    return value.split(',').map((v) => v.trim()).filter(Boolean);
  }
  return [];
}

/** Normalises admin input into a clean list of levels; drops levels with no targets. */
function normalizeLevels(levels) {
  if (!Array.isArray(levels)) return [];
  return levels
    .map((lvl) => ({
      title: String(lvl?.title || '').trim(),
      prompt: String(lvl?.prompt || '').trim(),
      targets: toStringList(lvl?.targets),
      distractors: toStringList(lvl?.distractors),
    }))
    .filter((lvl) => lvl.targets.length > 0);
}

function mapRow(row) {
  if (!row) return null;
  return {
    ...row,
    options: parseJson(row.options_json, []),
    levels: normalizeLevels(parseJson(row.levels_json, [])),
  };
}

class GameModel {
  static async getAll({ gameType, onlyActive = true } = {}) {
    await ensureSchema();
    const conditions = [];
    const values = [];

    if (onlyActive) conditions.push('is_active = TRUE');
    if (gameType) {
      conditions.push('game_type = ?');
      values.push(gameType);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const [rows] = await pool.query(
      `SELECT * FROM games ${whereClause} ORDER BY display_order ASC`,
      values
    );

    return rows.map(mapRow);
  }

  static async getById(id) {
    await ensureSchema();
    const [rows] = await pool.query('SELECT * FROM games WHERE id = ? LIMIT 1', [id]);
    return mapRow(rows[0]);
  }

  static async create(data) {
    await ensureSchema();
    const gameType = data.gameType || data.game_type || 'puzzle';
    const title = data.title || '';
    const prompt = data.prompt || '';
    const clue = data.clue || '';
    const clueImage = data.clueImage !== undefined ? data.clueImage : (data.clue_image || null);
    const correctIndex = data.correctIndex !== undefined ? data.correctIndex : (data.correct_index || 0);
    const options = toStringList(data.options);
    const levels = normalizeLevels(data.levels);
    const successPraise = data.successPraise || data.success_praise || 'சூப்பர்! ⭐';
    const starsReward = data.starsReward !== undefined ? data.starsReward : (data.stars_reward || 3);
    const displayOrder = data.displayOrder !== undefined ? data.displayOrder : (data.display_order || 0);
    const isActive = data.isActive !== undefined ? data.isActive : (data.is_active !== undefined ? data.is_active : true);

    const gameId = data.id || `game_${gameType}_${Date.now()}`;
    await pool.query(
      `INSERT INTO games
        (id, game_type, title, prompt, clue, clue_image, correct_index, options_json, levels_json, success_praise, stars_reward, display_order, is_active)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        gameId,
        gameType,
        title,
        prompt,
        clue,
        clueImage,
        correctIndex,
        JSON.stringify(options),
        JSON.stringify(levels),
        successPraise,
        starsReward,
        displayOrder,
        isActive,
      ]
    );
    return this.getById(gameId);
  }

  static async update(id, data) {
    await ensureSchema();
    const fields = [];
    const values = [];

    const fieldMap = {
      gameType: 'game_type',
      game_type: 'game_type',
      title: 'title',
      prompt: 'prompt',
      clue: 'clue',
      clueImage: 'clue_image',
      clue_image: 'clue_image',
      correctIndex: 'correct_index',
      correct_index: 'correct_index',
      successPraise: 'success_praise',
      success_praise: 'success_praise',
      starsReward: 'stars_reward',
      stars_reward: 'stars_reward',
      displayOrder: 'display_order',
      display_order: 'display_order',
      isActive: 'is_active',
      is_active: 'is_active',
    };

    const handledCols = new Set();
    for (const [key, dbCol] of Object.entries(fieldMap)) {
      if (data[key] !== undefined && !handledCols.has(dbCol)) {
        fields.push(`${dbCol} = ?`);
        values.push(data[key]);
        handledCols.add(dbCol);
      }
    }

    if (data.options !== undefined) {
      fields.push('options_json = ?');
      values.push(JSON.stringify(toStringList(data.options)));
    }

    if (data.levels !== undefined) {
      fields.push('levels_json = ?');
      values.push(JSON.stringify(normalizeLevels(data.levels)));
    }

    if (fields.length === 0) return this.getById(id);

    values.push(id);
    await pool.query(`UPDATE games SET ${fields.join(', ')} WHERE id = ?`, values);
    return this.getById(id);
  }

  static async delete(id) {
    const [result] = await pool.query('DELETE FROM games WHERE id = ?', [id]);
    return result.affectedRows > 0;
  }
}

module.exports = GameModel;
