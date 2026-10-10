/**
 * Languages Routes
 */
const express = require('express');
const LanguageController = require('../controllers/languageController');

const router = express.Router();

router.get('/', LanguageController.getAll);
router.get('/:code', LanguageController.getByCode);

module.exports = router;
