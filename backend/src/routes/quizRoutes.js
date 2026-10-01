/**
 * Quizzes and Questions Routes
 */
const express = require('express');
const { body, param } = require('express-validator');
const QuizController = require('../controllers/quizController');
const { verifyToken, requireRole } = require('../middleware/authMiddleware');
const { validateRequest } = require('../middleware/validateMiddleware');

const router = express.Router();

// Public: List quizzes (optional query: ?category=uyir)
router.get('/', QuizController.getAll);

// Public / Child: Get quiz with questions (answers hidden unless authenticated admin with includeAnswers=true)
router.get('/:id', QuizController.getById);

// Public / Child: Submit quiz answers
router.post(
  '/:id/submit',
  [
    param('id').notEmpty().withMessage('Quiz ID is required'),
    body('userId').trim().notEmpty().withMessage('userId is required'),
    body('answers').isArray().withMessage('answers must be an array of answer objects'),
    validateRequest,
  ],
  QuizController.submitQuiz
);

// Admin: Create quiz
router.post(
  '/',
  verifyToken,
  requireRole('super_admin', 'content_admin'),
  [
    body('title').trim().notEmpty().withMessage('Quiz title is required'),
    body('category').trim().notEmpty().withMessage('Quiz category is required'),
    validateRequest,
  ],
  QuizController.create
);

// Admin: Update quiz
router.put(
  '/:id',
  verifyToken,
  requireRole('super_admin', 'content_admin'),
  [param('id').notEmpty().withMessage('Quiz ID is required'), validateRequest],
  QuizController.update
);

// Admin: Delete quiz
router.delete(
  '/:id',
  verifyToken,
  requireRole('super_admin'),
  [param('id').notEmpty().withMessage('Quiz ID is required'), validateRequest],
  QuizController.delete
);

// Admin: Add question with options
router.post(
  '/:id/questions',
  verifyToken,
  requireRole('super_admin', 'content_admin'),
  [
    param('id').notEmpty().withMessage('Quiz ID is required'),
    body('questionText').trim().notEmpty().withMessage('questionText is required'),
    body('options').isArray({ min: 2 }).withMessage('At least two options are required'),
    validateRequest,
  ],
  QuizController.addQuestion
);

// Admin: Delete question
router.delete(
  '/:id/questions/:questionId',
  verifyToken,
  requireRole('super_admin'),
  [
    param('questionId').notEmpty().withMessage('questionId is required'),
    validateRequest,
  ],
  QuizController.deleteQuestion
);

module.exports = router;
