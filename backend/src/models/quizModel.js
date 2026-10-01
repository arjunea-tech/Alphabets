/**
 * Quizzes, Questions, and Options Data Access Model
 */
const { pool } = require('../config/db');

class QuizModel {
  static async getAll({ category, onlyActive = true } = {}) {
    const conditions = [];
    const values = [];

    if (onlyActive) conditions.push('q.is_active = TRUE');
    if (category) {
      conditions.push('q.category = ?');
      values.push(category);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const [rows] = await pool.query(
      `SELECT q.*, COUNT(qq.id) as actual_question_count 
       FROM quizzes q
       LEFT JOIN quiz_questions qq ON q.id = qq.quiz_id
       ${whereClause}
       GROUP BY q.id
       ORDER BY q.display_order ASC`,
      values
    );
    return rows;
  }

  static async getById(id, { includeAnswers = false } = {}) {
    const [quizzes] = await pool.query('SELECT * FROM quizzes WHERE id = ? LIMIT 1', [id]);
    if (!quizzes[0]) return null;

    const [questions] = await pool.query(
      'SELECT * FROM quiz_questions WHERE quiz_id = ? AND is_active = TRUE ORDER BY display_order ASC',
      [id]
    );

    const questionIds = questions.map((q) => q.id);
    let optionsMap = {};

    if (questionIds.length > 0) {
      const placeholders = questionIds.map(() => '?').join(',');
      const selectFields = includeAnswers
        ? 'id, question_id, option_text, is_correct, display_order'
        : 'id, question_id, option_text, display_order';

      const [options] = await pool.query(
        `SELECT ${selectFields} FROM quiz_options WHERE question_id IN (${placeholders}) ORDER BY display_order ASC`,
        questionIds
      );

      options.forEach((opt) => {
        if (!optionsMap[opt.question_id]) optionsMap[opt.question_id] = [];
        optionsMap[opt.question_id].push({
          id: opt.id,
          optionText: opt.option_text,
          displayOrder: opt.display_order,
          ...(includeAnswers ? { isCorrect: Boolean(opt.is_correct) } : {}),
        });
      });
    }

    return {
      ...quizzes[0],
      questions: questions.map((q) => ({
        id: q.id,
        question: q.question_text,
        visualHint: q.visual_hint,
        visualImage: q.visual_image,
        marks: q.marks,
        displayOrder: q.display_order,
        options: optionsMap[q.id] || [],
        ...(includeAnswers ? { explanation: q.explanation } : {}),
      })),
    };
  }

  static async createQuiz({
    id,
    title,
    subtitle = '',
    iconEmoji = '❓',
    category = 'uyir',
    questionCount = 5,
    passMarks = 3,
    starsReward = 5,
    isActive = true,
    displayOrder = 0,
  }) {
    const quizId = id || `quiz_${category}_${Date.now()}`;
    await pool.query(
      `INSERT INTO quizzes (id, title, subtitle, icon_emoji, category, question_count, pass_marks, stars_reward, is_active, display_order)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [quizId, title, subtitle, iconEmoji, category, questionCount, passMarks, starsReward, isActive, displayOrder]
    );
    return this.getById(quizId, { includeAnswers: true });
  }

  static async updateQuiz(id, data) {
    const fields = [];
    const values = [];

    const fieldMap = {
      title: 'title',
      subtitle: 'subtitle',
      iconEmoji: 'icon_emoji',
      category: 'category',
      questionCount: 'question_count',
      passMarks: 'pass_marks',
      starsReward: 'stars_reward',
      isActive: 'is_active',
      displayOrder: 'display_order',
    };

    for (const [key, dbCol] of Object.entries(fieldMap)) {
      if (data[key] !== undefined) {
        fields.push(`${dbCol} = ?`);
        values.push(data[key]);
      }
    }

    if (fields.length === 0) return this.getById(id, { includeAnswers: true });

    values.push(id);
    await pool.query(`UPDATE quizzes SET ${fields.join(', ')} WHERE id = ?`, values);
    return this.getById(id, { includeAnswers: true });
  }

  static async deleteQuiz(id) {
    const [result] = await pool.query('DELETE FROM quizzes WHERE id = ?', [id]);
    return result.affectedRows > 0;
  }

  // --- Questions & Options ---
  static async addQuestion(quizId, { id, questionText, visualHint = null, visualImage = null, explanation = '', marks = 1, displayOrder = 0, options = [] }) {
    const qId = id || `q_${Date.now()}_${Math.round(Math.random() * 1000)}`;
    await pool.query(
      `INSERT INTO quiz_questions (id, quiz_id, question_text, visual_hint, visual_image, explanation, marks, display_order)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [qId, quizId, questionText, visualHint, visualImage, explanation, marks, displayOrder]
    );

    for (const opt of options) {
      await pool.query(
        `INSERT INTO quiz_options (question_id, option_text, is_correct, display_order)
         VALUES (?, ?, ?, ?)`,
        [qId, opt.optionText, Boolean(opt.isCorrect), opt.displayOrder || 0]
      );
    }

    return qId;
  }

  static async deleteQuestion(questionId) {
    const [result] = await pool.query('DELETE FROM quiz_questions WHERE id = ?', [questionId]);
    return result.affectedRows > 0;
  }
}

module.exports = QuizModel;
