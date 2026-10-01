/**
 * Admin Data Access Model
 */
const { pool } = require('../config/db');

class AdminModel {
  static async findByUsername(username) {
    const [rows] = await pool.query(
      'SELECT * FROM admins WHERE username = ? LIMIT 1',
      [username]
    );
    return rows[0] || null;
  }

  static async findByEmail(email) {
    const [rows] = await pool.query(
      'SELECT * FROM admins WHERE email = ? LIMIT 1',
      [email]
    );
    return rows[0] || null;
  }

  static async findById(id) {
    const [rows] = await pool.query(
      'SELECT id, username, email, role, full_name, is_active, created_at, updated_at FROM admins WHERE id = ? LIMIT 1',
      [id]
    );
    return rows[0] || null;
  }

  static async create({ username, email, passwordHash, role = 'content_admin', fullName }) {
    const [result] = await pool.query(
      `INSERT INTO admins (username, email, password_hash, role, full_name, is_active)
       VALUES (?, ?, ?, ?, ?, TRUE)`,
      [username, email, passwordHash, role, fullName]
    );
    return result.insertId;
  }

  static async updatePassword(id, passwordHash) {
    const [result] = await pool.query(
      'UPDATE admins SET password_hash = ? WHERE id = ?',
      [passwordHash, id]
    );
    return result.affectedRows > 0;
  }

  static async listAll() {
    const [rows] = await pool.query(
      'SELECT id, username, email, role, full_name, is_active, created_at FROM admins ORDER BY id ASC'
    );
    return rows;
  }
}

module.exports = AdminModel;
