/**
 * Admin Dashboard & Reports Controller
 */
const { pool } = require('../config/db');
const UserModel = require('../models/userModel');
const ProgressModel = require('../models/progressModel');
const bcrypt = require('bcryptjs');
const { successResponse, errorResponse } = require('../utils/apiResponse');

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
      const { limit = 100, offset = 0, search = '' } = req.query;
      const users = await UserModel.listAll({ limit, offset, search });
      const total = await UserModel.countUsers(search);
      return successResponse(res, 'Users fetched successfully', {
        total,
        users,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Create new student learner from Admin Panel
   */
  static async createUser(req, res, next) {
    try {
      const { child_name, name, email, password, age = 5, avatar_asset = 'assets/images/welcome.png', total_stars = 0 } = req.body;
      const childName = (child_name || name || '').trim();

      if (!childName) {
        return errorResponse(res, 'மாணவர் பெயர் அவசியம் (Student name is required)', null, 400);
      }

      if (email && email.trim()) {
        const existing = await UserModel.findByEmail(email.trim());
        if (existing) {
          return errorResponse(res, 'இந்த மின்னஞ்சல் ஏற்கனவே உள்ளது (Email already exists)', null, 409);
        }
      }

      let passwordHash = null;
      if (password && password.trim().length >= 6) {
        const salt = await bcrypt.genSalt(10);
        passwordHash = await bcrypt.hash(password.trim(), salt);
      }

      const userId = `user_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
      const user = await UserModel.create({
        id: userId,
        name: childName,
        email: email ? email.trim().toLowerCase() : null,
        passwordHash,
        age: parseInt(age, 10) || 5,
        avatarAsset: avatar_asset || 'assets/images/welcome.png',
      });

      if (total_stars && parseInt(total_stars, 10) > 0) {
        await UserModel.updateUser(userId, { total_stars });
      }

      const freshUser = await UserModel.findById(userId);
      return successResponse(res, 'Student created successfully', freshUser, 201);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update student learner from Admin Panel
   */
  static async updateUser(req, res, next) {
    try {
      const { id } = req.params;
      const { child_name, email, age, avatar_asset, total_stars, is_active, password } = req.body;

      if (child_name !== undefined && !String(child_name).trim()) {
        return errorResponse(res, 'மாணவர் பெயர் அவசியம் (Student name is required)', null, 400);
      }

      // Another student may already own this email
      if (email && String(email).trim()) {
        const existing = await UserModel.findByEmail(String(email).trim());
        if (existing && existing.id !== id) {
          return errorResponse(res, 'இந்த மின்னஞ்சல் ஏற்கனவே உள்ளது (Email already exists)', null, 409);
        }
      }

      let passwordHash = undefined;
      if (password && password.trim().length >= 6) {
        const salt = await bcrypt.genSalt(10);
        passwordHash = await bcrypt.hash(password.trim(), salt);
      }

      const updated = await UserModel.updateUser(id, {
        child_name,
        email,
        age,
        avatar_asset,
        total_stars,
        is_active,
        passwordHash,
      });

      if (!updated) {
        return errorResponse(res, 'Student not found', null, 404);
      }

      return successResponse(res, 'Student updated successfully', updated);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Delete student learner from Admin Panel
   */
  static async deleteUser(req, res, next) {
    try {
      const { id } = req.params;
      const deleted = await UserModel.deleteUser(id);
      if (!deleted) {
        return errorResponse(res, 'Student not found', null, 404);
      }
      return successResponse(res, 'Student deleted successfully');
    } catch (error) {
      next(error);
    }
  }

  /**
   * List all quiz results
   */
  static async listQuizResults(req, res, next) {
    try {
      const { limit = 100, offset = 0 } = req.query;
      const results = await ProgressModel.listAllQuizResults({ limit, offset });
      return successResponse(res, 'Quiz results fetched successfully', results);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = DashboardController;
