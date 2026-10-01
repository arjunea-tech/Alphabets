/**
 * Letters and Letter Groups Routes
 */
const express = require('express');
const { body, param } = require('express-validator');
const LetterController = require('../controllers/letterController');
const { verifyToken, requireRole } = require('../middleware/authMiddleware');
const { validateRequest } = require('../middleware/validateMiddleware');
const upload = require('../middleware/uploadMiddleware');

const router = express.Router();

// Public: List letter groups
router.get('/groups', LetterController.getGroups);

// Admin: Create letter group
router.post(
  '/groups',
  verifyToken,
  requireRole('super_admin', 'content_admin'),
  [
    body('name').trim().notEmpty().withMessage('Group name is required'),
    body('displayTitle').trim().notEmpty().withMessage('displayTitle is required'),
    body('letterType').isIn(['uyir', 'mei', 'aytham', 'uyirmei']).withMessage('Invalid letterType'),
    validateRequest,
  ],
  LetterController.createGroup
);

// Public: List letters (optional query params: ?type=uyir&groupId=...)
router.get('/', LetterController.getAll);

// Public: Get single letter detail
router.get('/:id', LetterController.getById);

// Admin: Upload / Attach video to letter
router.post(
  '/:id/video',
  verifyToken,
  requireRole('super_admin', 'content_admin'),
  upload.single('video'),
  LetterController.uploadVideo
);

// Admin: Delete / Remove video from letter
router.delete(
  '/:id/video',
  verifyToken,
  requireRole('super_admin', 'content_admin'),
  LetterController.deleteVideo
);

// Admin: Create letter
router.post(
  '/',
  verifyToken,
  requireRole('super_admin', 'content_admin'),
  [
    body('letter').trim().notEmpty().withMessage('Tamil letter is required'),
    body('type').isIn(['uyir', 'mei', 'aytham', 'uyirmei']).withMessage('type must be uyir, mei, aytham, or uyirmei'),
    body('word').trim().notEmpty().withMessage('Tamil vocabulary word is required'),
    body('meaning').trim().notEmpty().withMessage('English meaning is required'),
    body('phonetic').trim().notEmpty().withMessage('Phonetic pronunciation is required'),
    validateRequest,
  ],
  LetterController.create
);

// Admin: Update letter
router.put(
  '/:id',
  verifyToken,
  requireRole('super_admin', 'content_admin'),
  [param('id').notEmpty().withMessage('Letter ID is required'), validateRequest],
  LetterController.update
);

// Admin: Delete letter
router.delete(
  '/:id',
  verifyToken,
  requireRole('super_admin'),
  [param('id').notEmpty().withMessage('Letter ID is required'), validateRequest],
  LetterController.delete
);

module.exports = router;

