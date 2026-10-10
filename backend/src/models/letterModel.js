/**
 * Letters and Letter Groups Data Access Model
 */
const { pool } = require('../config/db');

class LetterModel {
  static async getAll({ type, groupId, meiBase, languageCode, tenantId, onlyActive = true } = {}) {
    const conditions = [];
    const values = [];

    if (onlyActive) {
      conditions.push('l.is_active = TRUE');
    }
    if (languageCode) {
      conditions.push('l.language_code = ?');
      values.push(languageCode);
    }
    if (tenantId) {
      conditions.push('l.tenant_id = ?');
      values.push(tenantId);
    }
    if (type) {
      conditions.push('l.type = ?');
      values.push(type);
    }
    if (groupId) {
      conditions.push('l.group_id = ?');
      values.push(groupId);
    }
    if (meiBase) {
      conditions.push('l.mei_base = ?');
      values.push(meiBase);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const [rows] = await pool.query(
      `SELECT l.*, g.display_title as group_title 
       FROM letters l
       LEFT JOIN letter_groups g ON l.group_id = g.id
       ${whereClause}
       ORDER BY l.display_order ASC`,
      values
    );

    return rows;
  }

  static async getById(id) {
    const [rows] = await pool.query(
      `SELECT l.*, g.display_title as group_title 
       FROM letters l
       LEFT JOIN letter_groups g ON l.group_id = g.id
       WHERE l.id = ? LIMIT 1`,
      [id]
    );
    return rows[0] || null;
  }

  static async create(data) {
    const letterId = data.id || `letter_${data.type}_${Date.now()}`;
    const letter = data.letter;
    const type = data.type;
    const groupId = data.groupId !== undefined ? data.groupId : (data.group_id ?? null);
    const word = data.word;
    const meaning = data.meaning;
    const phonetic = data.phonetic;
    const iconEmoji = data.iconEmoji !== undefined ? data.iconEmoji : (data.icon_emoji ?? '⭐');
    const imagePath = data.imagePath !== undefined ? data.imagePath : (data.image_path ?? null);
    const audioPath = data.audioPath !== undefined ? data.audioPath : (data.audio_path ?? null);
    const videoUrl = data.videoUrl !== undefined ? data.videoUrl : (data.video_url ?? null);
    const explanation = data.explanation ?? null;
    const meiBase = data.meiBase !== undefined ? data.meiBase : (data.mei_base ?? null);
    const uyirBase = data.uyirBase !== undefined ? data.uyirBase : (data.uyir_base ?? null);
    const displayOrder = data.displayOrder !== undefined ? data.displayOrder : (data.display_order ?? 0);
    const isActive = data.isActive !== undefined ? data.isActive : (data.is_active ?? true);

    await pool.query(
      `INSERT INTO letters 
        (id, letter, type, group_id, word, meaning, phonetic, icon_emoji, 
         image_path, audio_path, video_url, explanation, mei_base, uyir_base, display_order, is_active)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        letterId,
        letter,
        type,
        groupId,
        word,
        meaning,
        phonetic,
        iconEmoji,
        imagePath,
        audioPath,
        videoUrl,
        explanation,
        meiBase,
        uyirBase,
        displayOrder,
        isActive,
      ]
    );
    return this.getById(letterId);
  }

  static async update(id, data) {
    const dbUpdates = {};
    if (data.letter !== undefined) dbUpdates.letter = data.letter;
    if (data.type !== undefined) dbUpdates.type = data.type;
    if (data.groupId !== undefined) dbUpdates.group_id = data.groupId;
    else if (data.group_id !== undefined) dbUpdates.group_id = data.group_id;

    if (data.word !== undefined) dbUpdates.word = data.word;
    if (data.meaning !== undefined) dbUpdates.meaning = data.meaning;
    if (data.phonetic !== undefined) dbUpdates.phonetic = data.phonetic;

    if (data.iconEmoji !== undefined) dbUpdates.icon_emoji = data.iconEmoji;
    else if (data.icon_emoji !== undefined) dbUpdates.icon_emoji = data.icon_emoji;

    if (data.imagePath !== undefined) dbUpdates.image_path = data.imagePath || null;
    else if (data.image_path !== undefined) dbUpdates.image_path = data.image_path || null;

    if (data.audioPath !== undefined) dbUpdates.audio_path = data.audioPath || null;
    else if (data.audio_path !== undefined) dbUpdates.audio_path = data.audio_path || null;

    if (data.videoUrl !== undefined) dbUpdates.video_url = data.videoUrl || null;
    else if (data.video_url !== undefined) dbUpdates.video_url = data.video_url || null;

    if (data.explanation !== undefined) dbUpdates.explanation = data.explanation;

    if (data.meiBase !== undefined) dbUpdates.mei_base = data.meiBase;
    else if (data.mei_base !== undefined) dbUpdates.mei_base = data.mei_base;

    if (data.uyirBase !== undefined) dbUpdates.uyir_base = data.uyirBase;
    else if (data.uyir_base !== undefined) dbUpdates.uyir_base = data.uyir_base;

    if (data.displayOrder !== undefined) dbUpdates.display_order = data.displayOrder;
    else if (data.display_order !== undefined) dbUpdates.display_order = data.display_order;

    if (data.isActive !== undefined) dbUpdates.is_active = data.isActive ? 1 : 0;
    else if (data.is_active !== undefined) dbUpdates.is_active = data.is_active ? 1 : 0;

    const cols = Object.keys(dbUpdates);
    if (cols.length === 0) return this.getById(id);

    const fields = cols.map((col) => `${col} = ?`);
    fields.push('updated_at = CURRENT_TIMESTAMP');
    const values = cols.map((col) => dbUpdates[col]);

    values.push(id);
    await pool.query(`UPDATE letters SET ${fields.join(', ')} WHERE id = ?`, values);
    return this.getById(id);
  }

  static async delete(id) {
    const [result] = await pool.query('DELETE FROM letters WHERE id = ?', [id]);
    return result.affectedRows > 0;
  }

  // --- Letter Groups Operations ---
  static async getGroups({ letterType, languageCode } = {}) {
    const conditions = [];
    const values = [];
    if (letterType) {
      conditions.push('letter_type = ?');
      values.push(letterType);
    }
    if (languageCode) {
      conditions.push('language_code = ?');
      values.push(languageCode);
    }
    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const [rows] = await pool.query(
      `SELECT * FROM letter_groups ${whereClause} ORDER BY display_order ASC`,
      values
    );
    return rows;
  }

  static async createGroup({ id, name, displayTitle, letterType, description = '', displayOrder = 0, languageCode = 'ta', tenantId = 'default' }) {
    const groupId = id || `group_${letterType}_${Date.now()}`;
    await pool.query(
      `INSERT INTO letter_groups (id, name, display_title, letter_type, description, display_order, language_code, tenant_id)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [groupId, name, displayTitle, letterType, description, displayOrder, languageCode, tenantId]
    );
    const [rows] = await pool.query('SELECT * FROM letter_groups WHERE id = ?', [groupId]);
    return rows[0];
  }
}

module.exports = LetterModel;
