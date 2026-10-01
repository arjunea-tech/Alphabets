/**
 * Quiz Evaluation & Scoring Service
 */
const { pool } = require('../config/db');
const QuizModel = require('../models/quizModel');
const ProgressModel = require('../models/progressModel');

class QuizService {
  /**
   * Evaluate a user's quiz submission
   * @param {string} userId
   * @param {string} quizId
   * @param {Array<{ questionId: string, selectedOptionId: number }>} answers
   */
  static async submitQuiz(userId, quizId, answers = []) {
    const quiz = await QuizModel.getById(quizId, { includeAnswers: true });
    if (!quiz) {
      throw new Error(`Quiz not found: ${quizId}`);
    }

    let correctCount = 0;
    let totalScore = 0;
    const questionEvaluations = [];

    // Map questions for quick lookup
    const questionMap = new Map();
    quiz.questions.forEach((q) => {
      questionMap.set(q.id, q);
    });

    for (const ans of answers) {
      const question = questionMap.get(ans.questionId);
      if (!question) continue;

      const correctOption = question.options.find((opt) => opt.isCorrect);
      const isCorrect = correctOption && Number(correctOption.id) === Number(ans.selectedOptionId);

      if (isCorrect) {
        correctCount += 1;
        totalScore += question.marks || 1;
      }

      questionEvaluations.push({
        questionId: question.id,
        selectedOptionId: ans.selectedOptionId,
        correctOptionId: correctOption ? correctOption.id : null,
        isCorrect,
        explanation: question.explanation,
      });
    }

    const totalQuestions = quiz.questions.length;
    const isPassed = correctCount >= quiz.pass_marks;
    const starsEarned = isPassed ? (quiz.stars_reward || 5) : Math.max(1, Math.floor(correctCount / 2));

    // Save quiz result
    await ProgressModel.recordQuizResult({
      userId,
      quizId,
      score: totalScore,
      totalQuestions,
      correctAnswers: correctCount,
      starsEarned,
    });

    // Update overall content progress
    await ProgressModel.upsertProgress({
      userId,
      contentType: 'quiz',
      contentId: quizId,
      completionStatus: isPassed ? 'completed' : 'in_progress',
      completionPercentage: Math.round((correctCount / totalQuestions) * 100),
      starsEarned,
    });

    return {
      quizId,
      title: quiz.title,
      score: totalScore,
      correctAnswers: correctCount,
      totalQuestions,
      isPassed,
      starsEarned,
      details: questionEvaluations,
    };
  }
}

module.exports = QuizService;
