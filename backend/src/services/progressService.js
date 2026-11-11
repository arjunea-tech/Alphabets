/**
 * Progress Aggregation Service
 * Formats data directly compatible with Flutter's UserProgressModel
 */
const { pool } = require('../config/db');
const UserModel = require('../models/userModel');
const ProgressModel = require('../models/progressModel');

class ProgressService {
  /**
   * Get user progress formatted for the AGARAM Flutter app
   */
  static async getFlutterFormattedProgress(userId) {
    const user = await UserModel.findById(userId);
    if (!user) {
      throw new Error(`User not found: ${userId}`);
    }

    // 1. Completed letters
    const [completedLetters] = await pool.query(
      `SELECT content_id FROM user_progress 
       WHERE user_id = ? AND content_type = 'letter' AND completion_status = 'completed'`,
      [userId]
    );
    const completedLetterIds = completedLetters.map((r) => r.content_id);

    // 2. Completed stories count
    const [completedStories] = await pool.query(
      `SELECT COUNT(DISTINCT content_id) as count FROM user_progress 
       WHERE user_id = ? AND content_type = 'story' AND completion_status = 'completed'`,
      [userId]
    );

    // 3. Quiz high score
    const [quizHighScore] = await pool.query(
      `SELECT COALESCE(MAX(score), 0) as max_score FROM quiz_results WHERE user_id = ?`,
      [userId]
    );

    // 4. Games played count
    const [gamesPlayed] = await pool.query(
      `SELECT COUNT(*) as count FROM user_progress 
       WHERE user_id = ? AND content_type = 'game'`,
      [userId]
    );

    return {
      stars: user.total_stars,
      completedLetterIds,
      // PostgreSQL returns COUNT() as a string; the Flutter client reads these as int.
      completedStories: Number(completedStories[0]?.count) || 0,
      quizHighScore: quizHighScore[0]?.max_score || 0,
      gamesPlayed: Number(gamesPlayed[0]?.count) || 0,
      childName: user.child_name,
      avatarAsset: user.avatar_asset,
      age: user.age,
      currentStreak: user.current_streak,
      highestStreak: user.highest_streak,
    };
  }
}

module.exports = ProgressService;
