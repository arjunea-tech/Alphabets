/**
 * Admin Dashboard & Reports Controller
 */
const { pool } = require('../config/db');
const UserModel = require('../models/userModel');
const ProgressModel = require('../models/progressModel');
const { successResponse } = require('../utils/apiResponse');

class DashboardController {
  /**
   * Aggregate statistics for the Admin Dashboard
   */
  static async getStats(req, res, next) {
    try {
      const [userCount] = await pool.query('SELECT COUNT(*) as count FROM users');
      const [lessonCount] = await pool.query('SELECT COUNT(*) as count FROM lessons WHERE is_active = TRUE');
      const [letterCount] = await pool.query('SELECT COUNT(*) as count FROM letters WHERE is_active = TRUE');
      const [storyCount] = await pool.query('SELECT COUNT(*) as count FROM reading_stories WHERE is_published = TRUE');
      const [videoCount] = await pool.query('SELECT COUNT(*) as count FROM videos WHERE is_published = TRUE');
      const [quizCount] = await pool.query('SELECT COUNT(*) as count FROM quizzes WHERE is_active = TRUE');
      const [quizAttempts] = await pool.query('SELECT COUNT(*) as count FROM quiz_results');
      const [totalStars] = await pool.query('SELECT COALESCE(SUM(total_stars), 0) as total FROM user_stars');

      const [recentAttempts] = await pool.query(
        `SELECT r.id, r.score, r.total_questions, r.stars_earned, r.attempt_date,
                u.child_name, q.title as quiz_title
         FROM quiz_results r
         JOIN users u ON r.user_id = u.id
         JOIN quizzes q ON r.quiz_id = q.id
         ORDER BY r.attempt_date DESC
         LIMIT 5`
      );

      return successResponse(res, 'Dashboard statistics fetched successfully', {
        summary: {
          totalUsers: userCount[0].count,
          totalLessons: lessonCount[0].count,
          totalLetters: letterCount[0].count,
          totalStories: storyCount[0].count,
          totalVideos: videoCount[0].count,
          totalQuizzes: quizCount[0].count,
          totalQuizAttempts: quizAttempts[0].count,
          totalStarsAwarded: Number(totalStars[0].total),
        },
        recentQuizAttempts: recentAttempts,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * List all registered child learners
   */
  static async listUsers(req, res, next) {
    try {
      const { limit = 50, offset = 0 } = req.query;
      const users = await UserModel.listAll({ limit, offset });
      const total = await UserModel.countUsers();
      return successResponse(res, 'Users fetched successfully', {
        total,
        users,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * List all quiz results
   */
  static async listQuizResults(req, res, next) {
    try {
      const { limit = 50, offset = 0 } = req.query;
      const results = await ProgressModel.listAllQuizResults({ limit, offset });
      return successResponse(res, 'Quiz results fetched successfully', results);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = DashboardController;
