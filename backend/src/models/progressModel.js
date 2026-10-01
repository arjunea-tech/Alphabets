/**
 * User Progress, Star Ledger, and Quiz Results Model
 */
const { pool } = require('../config/db');

class ProgressModel {
  static async getUserProgress(userId) {
    const [progressRows] = await pool.query(
      'SELECT * FROM user_progress WHERE user_id = ? ORDER BY last_accessed_at DESC',
      [userId]
    );

    const [starRow] = await pool.query(
      'SELECT * FROM user_stars WHERE user_id = ? LIMIT 1',
      [userId]
    );

    return {
      stars: starRow[0]?.total_stars || 0,
      currentStreak: starRow[0]?.current_streak || 1,
      highestStreak: starRow[0]?.highest_streak || 1,
      completedItems: progressRows.map((row) => ({
        id: row.id,
        contentType: row.content_type,
        contentId: row.content_id,
        status: row.completion_status,
        percentage: row.completion_percentage,
        starsEarned: row.stars_earned,
        lastAccessedAt: row.last_accessed_at,
      })),
    };
  }

  static async upsertProgress({
    userId,
    contentType,
    contentId,
    completionStatus = 'completed',
    completionPercentage = 100,
    starsEarned = 1,
  }) {
    await pool.query(
      `INSERT INTO user_progress 
        (user_id, content_type, content_id, completion_status, completion_percentage, stars_earned, last_accessed_at)
       VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
       ON DUPLICATE KEY UPDATE 
         completion_status = VALUES(completion_status),
         completion_percentage = VALUES(completion_percentage),
         stars_earned = GREATEST(stars_earned, VALUES(stars_earned)),
         last_accessed_at = CURRENT_TIMESTAMP`,
      [userId, contentType, contentId, completionStatus, completionPercentage, starsEarned]
    );

    if (starsEarned > 0) {
      await this.addStars(userId, starsEarned);
    }

    return this.getUserProgress(userId);
  }

  static async addStars(userId, starsToAdd) {
    await pool.query(
      `INSERT INTO user_stars (user_id, total_stars, current_streak, highest_streak, last_earned_at)
       VALUES (?, ?, 1, 1, CURRENT_TIMESTAMP)
       ON DUPLICATE KEY UPDATE 
         total_stars = total_stars + VALUES(total_stars),
         last_earned_at = CURRENT_TIMESTAMP`,
      [userId, starsToAdd]
    );

    // Sync total_stars with users table
    await pool.query(
      `UPDATE users u
       JOIN user_stars s ON u.id = s.user_id
       SET u.total_stars = s.total_stars
       WHERE u.id = ?`,
      [userId]
    );

    const [rows] = await pool.query('SELECT total_stars FROM user_stars WHERE user_id = ?', [userId]);
    return rows[0]?.total_stars || 0;
  }

  static async recordQuizResult({
    userId,
    quizId,
    score,
    totalQuestions,
    correctAnswers,
    starsEarned,
  }) {
    const [result] = await pool.query(
      `INSERT INTO quiz_results 
        (user_id, quiz_id, score, total_questions, correct_answers, stars_earned, attempt_date)
       VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)`,
      [userId, quizId, score, totalQuestions, correctAnswers, starsEarned]
    );

    if (starsEarned > 0) {
      await this.addStars(userId, starsEarned);
    }

    return result.insertId;
  }

  static async getUserQuizHistory(userId) {
    const [rows] = await pool.query(
      `SELECT r.*, q.title as quiz_title, q.category as quiz_category 
       FROM quiz_results r
       JOIN quizzes q ON r.quiz_id = q.id
       WHERE r.user_id = ?
       ORDER BY r.attempt_date DESC`,
      [userId]
    );
    return rows;
  }

  static async listAllQuizResults({ limit = 50, offset = 0 } = {}) {
    const [rows] = await pool.query(
      `SELECT r.*, u.child_name, q.title as quiz_title 
       FROM quiz_results r
       JOIN users u ON r.user_id = u.id
       JOIN quizzes q ON r.quiz_id = q.id
       ORDER BY r.attempt_date DESC
       LIMIT ? OFFSET ?`,
      [parseInt(limit, 10), parseInt(offset, 10)]
    );
    return rows;
  }
}

module.exports = ProgressModel;
