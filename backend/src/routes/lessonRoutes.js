/**
 * Lesson Categories Routes
 */
const express = require('express');
const { body, param } = require('express-validator');
const LessonController = require('../controllers/lessonController');
const { verifyToken, requireRole } = require('../middleware/authMiddleware');
const { validateRequest } = require('../middleware/validateMiddleware');

const router = express.Router();

// Public: List all lessons
router.get('/', LessonController.getAll);

// Public: Get single lesson
router.get('/:id', LessonController.getById);

// Admin: Create lesson
router.post(
  '/',
  verifyToken,
  requireRole('super_admin', 'content_admin'),
  [
    body('categoryKey').trim().notEmpty().withMessage('categoryKey is required'),
    body('title').trim().notEmpty().withMessage('title is required'),
    validateRequest,
  ],
  LessonController.create
);

// Admin: Update lesson
router.put(
  '/:id',
  verifyToken,
  requireRole('super_admin', 'content_admin'),
  [param('id').notEmpty().withMessage('Lesson ID is required'), validateRequest],
  LessonController.update
);

// Admin: Delete lesson
router.delete(
  '/:id',
  verifyToken,
  requireRole('super_admin'),
  [param('id').notEmpty().withMessage('Lesson ID is required'), validateRequest],
  LessonController.delete
);

module.exports = router;
