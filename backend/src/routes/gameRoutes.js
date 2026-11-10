/**
 * Educational Games Routes
 */
const express = require('express');
const { body, param } = require('express-validator');
const GameController = require('../controllers/gameController');
const { verifyToken, requireRole } = require('../middleware/authMiddleware');
const { validateRequest } = require('../middleware/validateMiddleware');

const router = express.Router();

// Public: List games (optional query: ?gameType=puzzle)
router.get('/', GameController.getAll);

// Public: Get single game
router.get('/:id', GameController.getById);

// Admin: Create game
router.post(
  '/',
  verifyToken,
  requireRole('super_admin', 'content_admin'),
  [
    body().custom((val, { req }) => {
      if (!req.body.gameType && !req.body.game_type) {
        throw new Error('game_type is required');
      }
      return true;
    }),
    body('title').trim().notEmpty().withMessage('Title is required'),
    body('prompt').trim().notEmpty().withMessage('Prompt is required'),
    body('options').optional().isArray().withMessage('options must be an array of choices'),
    body('levels').optional().isArray().withMessage('levels must be an array'),
    body().custom((val, { req }) => {
      const levels = Array.isArray(req.body.levels) ? req.body.levels : [];
      const hasLevelContent = levels.some((l) => l && Array.isArray(l.targets) && l.targets.length > 0);
      const hasOptions = Array.isArray(req.body.options) && req.body.options.length > 0;
      if (!hasLevelContent && !hasOptions) {
        throw new Error('Add at least one level with target letters/words');
      }
      return true;
    }),
    validateRequest,
  ],
  GameController.create
);

// Admin: Update game
router.put(
  '/:id',
  verifyToken,
  requireRole('super_admin', 'content_admin'),
  [param('id').notEmpty().withMessage('Game ID is required'), validateRequest],
  GameController.update
);

// Admin: Delete game
router.delete(
  '/:id',
  verifyToken,
  requireRole('super_admin'),
  [param('id').notEmpty().withMessage('Game ID is required'), validateRequest],
  GameController.delete
);

module.exports = router;
