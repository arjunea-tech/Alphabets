/**
 * Reading Stories Routes
 */
const express = require('express');
const { body, param } = require('express-validator');
const StoryController = require('../controllers/storyController');
const { verifyToken, requireRole } = require('../middleware/authMiddleware');
const { validateRequest } = require('../middleware/validateMiddleware');

const router = express.Router();

// Public: List reading stories
router.get('/', StoryController.getAll);

// Public: Get single reading story with all pages
router.get('/:id', StoryController.getById);

// Admin: Create story
router.post(
  '/',
  verifyToken,
  requireRole('super_admin', 'content_admin'),
  [
    body('title').trim().notEmpty().withMessage('Title is required'),
    validateRequest,
  ],
  StoryController.create
);

// Admin: Update story
router.put(
  '/:id',
  verifyToken,
  requireRole('super_admin', 'content_admin'),
  [param('id').notEmpty().withMessage('Story ID is required'), validateRequest],
  StoryController.update
);

// Admin: Delete story
router.delete(
  '/:id',
  verifyToken,
  requireRole('super_admin'),
  [param('id').notEmpty().withMessage('Story ID is required'), validateRequest],
  StoryController.delete
);

// Admin: Add page to story
router.post(
  '/:id/pages',
  verifyToken,
  requireRole('super_admin', 'content_admin'),
  [
    param('id').notEmpty().withMessage('Story ID is required'),
    body('pageNumber').isInt({ min: 1 }).withMessage('pageNumber must be an integer >= 1'),
    body('text').trim().notEmpty().withMessage('Page story text is required'),
    validateRequest,
  ],
  StoryController.addPage
);

// Admin: Update story page
router.put(
  '/:id/pages/:pageId',
  verifyToken,
  requireRole('super_admin', 'content_admin'),
  [
    param('pageId').isInt().withMessage('pageId must be an integer'),
    validateRequest,
  ],
  StoryController.updatePage
);

// Admin: Delete story page
router.delete(
  '/:id/pages/:pageId',
  verifyToken,
  requireRole('super_admin'),
  [
    param('pageId').isInt().withMessage('pageId must be an integer'),
    validateRequest,
  ],
  StoryController.deletePage
);

module.exports = router;
