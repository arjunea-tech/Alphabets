/**
 * Lessons (Categories) Data Access Model
 */
const { pool } = require('../config/db');

class LessonModel {
  static async getAll({ onlyActive = true } = {}) {
    const condition = onlyActive ? 'WHERE is_active = TRUE' : '';
    const [rows] = await pool.query(
      `SELECT * FROM lessons ${condition} ORDER BY display_order ASC`
    );
    return rows.map((row) => ({
      ...row,
      gradientColors: typeof row.gradient_colors === 'string'
        ? JSON.parse(row.gradient_colors)
        : row.gradient_colors,
    }));
  }

  static async getById(id) {
    const [rows] = await pool.query('SELECT * FROM lessons WHERE id = ? LIMIT 1', [id]);
    if (!rows[0]) return null;
    return {
      ...rows[0],
      gradientColors: typeof rows[0].gradient_colors === 'string'
        ? JSON.parse(rows[0].gradient_colors)
        : rows[0].gradient_colors,
    };
  }

  static async create({
    id,
    categoryKey,
    title,
    subtitle = '',
    countText = '',
    buttonText = 'கற்கலாம்',
    iconEmoji = '⭐',
    gradientColors = ['#FF6B8B', '#FF8E53'],
    routeName = '',
    displayOrder = 0,
    isActive = true,
  }) {
    const lessonId = id || `lesson_${categoryKey}_${Date.now()}`;
    await pool.query(
      `INSERT INTO lessons 
        (id, category_key, title, subtitle, count_text, button_text, icon_emoji, gradient_colors, route_name, display_order, is_active)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        lessonId,
        categoryKey,
        title,
        subtitle,
        countText,
        buttonText,
        iconEmoji,
        JSON.stringify(gradientColors),
        routeName,
        displayOrder,
        isActive,
      ]
    );
    return this.getById(lessonId);
  }

  static async update(id, data) {
    const fields = [];
    const values = [];

    const fieldMap = {
      categoryKey: 'category_key',
      title: 'title',
      subtitle: 'subtitle',
      countText: 'count_text',
      buttonText: 'button_text',
      iconEmoji: 'icon_emoji',
      routeName: 'route_name',
      displayOrder: 'display_order',
      isActive: 'is_active',
    };

    for (const [key, dbCol] of Object.entries(fieldMap)) {
      if (data[key] !== undefined) {
        fields.push(`${dbCol} = ?`);
        values.push(data[key]);
      }
    }

    if (data.gradientColors !== undefined) {
      fields.push('gradient_colors = ?');
      values.push(JSON.stringify(data.gradientColors));
    }

    if (fields.length === 0) return this.getById(id);

    values.push(id);
    await pool.query(`UPDATE lessons SET ${fields.join(', ')} WHERE id = ?`, values);
    return this.getById(id);
  }

  static async delete(id) {
    const [result] = await pool.query('DELETE FROM lessons WHERE id = ?', [id]);
    return result.affectedRows > 0;
  }
}

module.exports = LessonModel;
