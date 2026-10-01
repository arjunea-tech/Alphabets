/**
 * Educational Videos Data Access Model
 */
const { pool } = require('../config/db');

class VideoModel {
  static async getAll({ category, onlyPublished = true } = {}) {
    const conditions = [];
    const values = [];

    if (onlyPublished) {
      conditions.push('is_published = TRUE');
    }
    if (category) {
      conditions.push('category = ?');
      values.push(category);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const [rows] = await pool.query(
      `SELECT * FROM videos ${whereClause} ORDER BY display_order ASC`,
      values
    );
    return rows;
  }

  static async getById(id) {
    const [rows] = await pool.query('SELECT * FROM videos WHERE id = ? LIMIT 1', [id]);
    return rows[0] || null;
  }

  static async create(payload) {
    const videoId = payload.id || `vid_${Date.now()}`;
    const title = payload.title || '';
    const description = payload.description || '';
    const category = payload.category || 'பாடல்';
    const duration = payload.duration || '03:00';
    const thumbnailEmoji = payload.thumbnail_emoji || payload.thumbnailEmoji || '🎬';
    const thumbnailImage = payload.thumbnail_image || payload.thumbnailImage || null;
    const videoUrl = payload.video_url || payload.videoUrl || '';
    const localVideoPath = payload.local_video_path || payload.localVideoPath || null;
    const displayOrder = payload.display_order !== undefined ? payload.display_order : (payload.displayOrder !== undefined ? payload.displayOrder : 0);
    const isPublished = payload.is_published !== undefined ? payload.is_published : (payload.isPublished !== undefined ? payload.isPublished : true);

    await pool.query(
      `INSERT INTO videos 
        (id, title, description, category, duration, thumbnail_emoji, thumbnail_image, video_url, local_video_path, display_order, is_published)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        videoId,
        title,
        description,
        category,
        duration,
        thumbnailEmoji,
        thumbnailImage,
        videoUrl,
        localVideoPath,
        displayOrder,
        isPublished,
      ]
    );
    return this.getById(videoId);
  }

  static async update(id, data) {
    const fields = [];
    const values = [];

    const fieldMap = {
      title: 'title',
      description: 'description',
      category: 'category',
      duration: 'duration',
      thumbnail_emoji: 'thumbnail_emoji',
      thumbnailEmoji: 'thumbnail_emoji',
      thumbnail_image: 'thumbnail_image',
      thumbnailImage: 'thumbnail_image',
      video_url: 'video_url',
      videoUrl: 'video_url',
      local_video_path: 'local_video_path',
      localVideoPath: 'local_video_path',
      display_order: 'display_order',
      displayOrder: 'display_order',
      is_published: 'is_published',
      isPublished: 'is_published',
    };

    const handledCols = new Set();
    for (const [key, dbCol] of Object.entries(fieldMap)) {
      if (data[key] !== undefined && !handledCols.has(dbCol)) {
        fields.push(`${dbCol} = ?`);
        values.push(data[key]);
        handledCols.add(dbCol);
      }
    }

    if (fields.length === 0) return this.getById(id);

    values.push(id);
    await pool.query(`UPDATE videos SET ${fields.join(', ')} WHERE id = ?`, values);
    return this.getById(id);
  }

  static async delete(id) {
    const [result] = await pool.query('DELETE FROM videos WHERE id = ?', [id]);
    return result.affectedRows > 0;
  }
}

module.exports = VideoModel;
