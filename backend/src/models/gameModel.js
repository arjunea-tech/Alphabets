/**
 * Level difficulty (controls game speed in the app). When missing (levels saved
 * before this field existed) it follows the level's position: 1st easy,
 * 2nd medium, 3rd and later hard.
 */
function normalizeDifficulty(value, index = 0) {
  const d = String(value || '').trim().toLowerCase();
  if (DIFFICULTIES.includes(d)) return d;
  return DIFFICULTIES[Math.min(index, DIFFICULTIES.length - 1)];
}/**
 * Games Data Access Model
 *
 * Every piece of game content (missions, target letters/words, distractors)
 * lives in the database and is managed from the admin panel. The Flutter app
 * renders exactly what is stored here — it has no hardcoded game content.
 *
 * levels_json shape:
 *   [{ "title": "Vowels", "prompt": "Pop only vowels", "targets": ["A","E"], "distractors": ["B","C"], "difficulty": "easy" }]
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

const DIFFICULTIES = ['easy', 'medium', 'hard'];

/**
 * Level difficulty (controls game speed in the app). When missing (levels saved
 * before this field existed) it follows the level's position: 1st easy,
 * 2nd medium, 3rd and later hard.
 */
function normalizeDifficulty(value, index = 0) {
  const d = String(value || '').trim().toLowerCase();
  if (DIFFICULTIES.includes(d)) return d;
  return DIFFICULTIES[Math.min(index, DIFFICULTIES.length - 1)];
}

/** Normalises admin input into a clean list of levels; drops levels with no targets. */
function normalizeLevels(levels) {
  if (!Array.isArray(levels)) return [];
  return levels
    .map((lvl, index) => ({
      title: String(lvl?.title || '').trim(),
      prompt: String(lvl?.prompt || '').trim(),
      targets: toStringList(lvl?.targets),
      distractors: toStringList(lvl?.distractors),
      difficulty: normalizeDifficulty(lvl?.difficulty, index),
    }))
    .filter((lvl) => lvl.targets.length > 0);
}

/** Every game offers at least this many levels (easy → medium → hard). */
const MIN_LEVELS = 3;

function dedupeCaseInsensitive(list) {
  const seen = new Set();
  return list.filter((v) => {
    const key = v.toUpperCase();
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

/**
 * Tops a game up to MIN_LEVELS levels so every game has Level 1/2/3 in the app
 * and in the admin editor (where they can be edited and saved like any level).
 *   1 level  → Part 1 (first half of its targets, easy), Part 2 (second half,
 *              medium), All (every target, hard). Fewer than 2 targets → the
 *              same targets three times, only faster.
 *   2 levels → kept, plus a 3rd "All" level with both levels' targets (hard).
 * Games that already have 3+ levels are returned unchanged.
 * Mirrored in the app: frontend/lib/models/game_item_model.dart (ensureMinLevels).
 */
function ensureMinLevels(levels, gameTitle = '') {
  if (levels.length === 0 || levels.length >= MIN_LEVELS) return levels;

  if (levels.length === 1) {
    const base = levels[0];
    const name = base.title || gameTitle || 'Level';
    const t = base.targets;
    const half = Math.ceil(t.length / 2);
    const parts = t.length >= 2 ? [t.slice(0, half), t.slice(half), t] : [t, t, t];
    const suffixes = ['Part 1', 'Part 2', 'All'];
    return parts.map((targets, i) => ({
      title: `${name} — ${suffixes[i]}`,
      prompt: base.prompt,
      targets,
      distractors: base.distractors,
      difficulty: DIFFICULTIES[i],
    }));
  }

  // 2 levels: add a combined, hard 3rd level
  return [
    ...levels,
    {
      title: 'All Together',
      prompt: levels[0].prompt,
      targets: dedupeCaseInsensitive([...levels[0].targets, ...levels[1].targets]),
      distractors: dedupeCaseInsensitive([...levels[0].distractors, ...levels[1].distractors]),
      difficulty: 'hard',
    },
  ];
}

function mapRow(row) {
  if (!row) return null;
  let levels = normalizeLevels(parseJson(row.levels_json, []));
  const options = parseJson(row.options_json, []);
  // Old games stored their content only in options_json
  if (levels.length === 0 && Array.isArray(options) && options.length > 0) {
    levels = normalizeLevels([{ title: row.title, prompt: row.prompt, targets: options }]);
  }
  return {
    ...row,
    options,
    levels: ensureMinLevels(levels, row.title),
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
