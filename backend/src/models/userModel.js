/**
 * User (Child Learner) Data Access Model
 */
const { pool } = require('../config/db');

class UserModel {
  static async findById(id) {
    const [rows] = await pool.query(
      `SELECT u.*, COALESCE(s.total_stars, u.total_stars) as total_stars, 
              COALESCE(s.current_streak, 1) as current_streak,
              COALESCE(s.highest_streak, 1) as highest_streak
       FROM users u
       LEFT JOIN user_stars s ON u.id = s.user_id
       WHERE u.id = ? LIMIT 1`,
      [id]
    );
    return rows[0] || null;
  }

  static async findByEmail(emailOrUsername) {
    if (!emailOrUsername) return null;
    const clean = emailOrUsername.trim().toLowerCase();
    const [rows] = await pool.query(
      `SELECT u.*, COALESCE(s.total_stars, u.total_stars) as total_stars, 
              COALESCE(s.current_streak, 1) as current_streak,
              COALESCE(s.highest_streak, 1) as highest_streak
       FROM users u
       LEFT JOIN user_stars s ON u.id = s.user_id
       WHERE LOWER(u.email) = ? OR LOWER(u.child_name) = ? LIMIT 1`,
      [clean, clean]
    );
    return rows[0] || null;
  }

  static async create({ id, name, email, passwordHash, age = 5, avatarAsset = 'assets/images/welcome.png' }) {
    await pool.query(
      `INSERT INTO users (id, child_name, email, password_hash, age, avatar_asset, total_stars, is_active)
       VALUES (?, ?, ?, ?, ?, ?, 0, TRUE)`,
      [id, name, email ? email.trim().toLowerCase() : null, passwordHash, age, avatarAsset]
    );

    // Ensure stars row exists
    await pool.query(
      `INSERT INTO user_stars (user_id, total_stars, current_streak, highest_streak)
       VALUES (?, 0, 1, 1)
       ON DUPLICATE KEY UPDATE user_id = user_id`,
      [id]
    );

    return this.findById(id);
  }

  static async createOrUpdate({ id, childName = 'குழந்தை', email = null, age = 5, avatarAsset = 'assets/images/welcome.png' }) {
    await pool.query(
      `INSERT INTO users (id, child_name, email, age, avatar_asset, total_stars, is_active)
       VALUES (?, ?, ?, ?, ?, 0, TRUE)
       ON DUPLICATE KEY UPDATE 
         child_name = VALUES(child_name),
         email = COALESCE(VALUES(email), users.email),
         age = VALUES(age),
         avatar_asset = VALUES(avatar_asset)`,
      [id, childName, email, age, avatarAsset]
    );

    // Ensure stars row exists
    await pool.query(
      `INSERT INTO user_stars (user_id, total_stars, current_streak, highest_streak)
       VALUES (?, 0, 1, 1)
       ON DUPLICATE KEY UPDATE user_id = user_id`,
      [id]
    );

    return this.findById(id);
  }

  static async updateProfile(id, { childName, age, avatarAsset }) {
    const updates = [];
    const values = [];

    if (childName !== undefined) {
      updates.push('child_name = ?');
      values.push(childName);
    }
    if (age !== undefined) {
      updates.push('age = ?');
      values.push(age);
    }
    if (avatarAsset !== undefined) {
      updates.push('avatar_asset = ?');
      values.push(avatarAsset);
    }

    if (updates.length === 0) return this.findById(id);

    values.push(id);
    await pool.query(`UPDATE users SET ${updates.join(', ')} WHERE id = ?`, values);
    return this.findById(id);
  }

  static async listAll({ limit = 50, offset = 0 } = {}) {
    const [rows] = await pool.query(
      `SELECT u.id, u.child_name, u.email, u.age, u.avatar_asset, 
              COALESCE(s.total_stars, u.total_stars) as total_stars,
              u.created_at, u.updated_at
       FROM users u
       LEFT JOIN user_stars s ON u.id = s.user_id
       ORDER BY u.created_at DESC
       LIMIT ? OFFSET ?`,
      [parseInt(limit, 10), parseInt(offset, 10)]
    );
    return rows;
  }

  static async countUsers() {
    const [rows] = await pool.query('SELECT COUNT(*) as count FROM users');
    return rows[0].count;
  }
}

module.exports = UserModel;
