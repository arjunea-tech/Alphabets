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
    body('gameType').trim().notEmpty().withMessage('gameType is required'),
    body('title').trim().notEmpty().withMessage('Title is required'),
    body('prompt').trim().notEmpty().withMessage('Prompt is required'),
    body('options').isArray({ min: 2 }).withMessage('options must be an array of choices'),
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
