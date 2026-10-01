/**
 * Admin Authentication Routes
 */
const express = require('express');
const { body } = require('express-validator');
const AdminAuthController = require('../controllers/adminAuthController');
const { verifyToken, requireRole } = require('../middleware/authMiddleware');
const { validateRequest } = require('../middleware/validateMiddleware');

const router = express.Router();

// Admin Login
router.post(
  '/login',
  [
    body('username').trim().notEmpty().withMessage('Username is required'),
    body('password').notEmpty().withMessage('Password is required'),
    validateRequest,
  ],
  AdminAuthController.login
);

// Get current admin profile
router.get('/me', verifyToken, AdminAuthController.me);

// Change password
router.post(
  '/change-password',
  verifyToken,
  [
    body('currentPassword').notEmpty().withMessage('Current password is required'),
    body('newPassword')
      .isLength({ min: 6 })
      .withMessage('New password must be at least 6 characters long'),
    validateRequest,
  ],
  AdminAuthController.changePassword
);

// Create new admin (Super Admin only)
router.post(
  '/create',
  verifyToken,
  requireRole('super_admin'),
  [
    body('username').trim().isLength({ min: 3 }).withMessage('Username must be at least 3 characters'),
    body('email').trim().isEmail().withMessage('Valid email is required'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    body('fullName').trim().notEmpty().withMessage('Full name is required'),
    validateRequest,
  ],
  AdminAuthController.createAdmin
);

module.exports = router;
