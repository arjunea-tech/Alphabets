/**
 * Games Data Access Model
 */
const { pool } = require('../config/db');

class GameModel {
  static async getAll({ gameType, onlyActive = true } = {}) {
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

    return rows.map((row) => ({
      ...row,
      options: typeof row.options_json === 'string'
        ? JSON.parse(row.options_json)
        : row.options_json,
    }));
  }

  static async getById(id) {
    const [rows] = await pool.query('SELECT * FROM games WHERE id = ? LIMIT 1', [id]);
    if (!rows[0]) return null;
    return {
      ...rows[0],
      options: typeof rows[0].options_json === 'string'
        ? JSON.parse(rows[0].options_json)
        : rows[0].options_json,
    };
  }

  static async create({
    id,
    gameType,
    title,
    prompt,
    clue = '',
    clueImage = null,
    correctIndex = 0,
    options = [],
    successPraise = 'சூப்பர்! ⭐',
    starsReward = 3,
    displayOrder = 0,
    isActive = true,
  }) {
    const gameId = id || `game_${gameType}_${Date.now()}`;
    await pool.query(
      `INSERT INTO games 
        (id, game_type, title, prompt, clue, clue_image, correct_index, options_json, success_praise, stars_reward, display_order, is_active)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        gameId,
        gameType,
        title,
        prompt,
        clue,
        clueImage,
        correctIndex,
        JSON.stringify(options),
        successPraise,
        starsReward,
        displayOrder,
        isActive,
      ]
    );
    return this.getById(gameId);
  }

  static async update(id, data) {
    const fields = [];
    const values = [];

    const fieldMap = {
      gameType: 'game_type',
      title: 'title',
      prompt: 'prompt',
      clue: 'clue',
      clueImage: 'clue_image',
      correctIndex: 'correct_index',
      successPraise: 'success_praise',
      starsReward: 'stars_reward',
      displayOrder: 'display_order',
      isActive: 'is_active',
    };

    for (const [key, dbCol] of Object.entries(fieldMap)) {
      if (data[key] !== undefined) {
        fields.push(`${dbCol} = ?`);
        values.push(data[key]);
      }
    }

    if (data.options !== undefined) {
      fields.push('options_json = ?');
      values.push(JSON.stringify(data.options));
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
