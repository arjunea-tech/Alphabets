/**
 * Languages Data Access Model
 */
const { pool } = require('../config/db');

class LanguageModel {
  static async getAll({ onlyActive = true } = {}) {
    const whereClause = onlyActive ? 'WHERE is_active = TRUE' : '';
    const [rows] = await pool.query(
      `SELECT * FROM languages ${whereClause} ORDER BY display_order ASC`
    );
    return rows;
  }

  static async getByCode(code) {
    const [rows] = await pool.query(
      'SELECT * FROM languages WHERE code = ? LIMIT 1',
      [code]
    );
    return rows[0] || null;
  }
}

module.exports = LanguageModel;
