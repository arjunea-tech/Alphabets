/**
 * Audio Synthesis and Manifest Routes
 */
const express = require('express');
const { body } = require('express-validator');
const AudioController = require('../controllers/audioController');
const { validateRequest } = require('../middleware/validateMiddleware');

const router = express.Router();

// Public: Get current audio manifest
router.get('/manifest', AudioController.getManifest);

// Dynamic synthesis: Generate or retrieve cached audio for Tamil text
router.post(
  '/synthesize',
  [
    body('text').trim().notEmpty().withMessage('Tamil text is required'),
    validateRequest,
  ],
  AudioController.synthesize
);

module.exports = router;
