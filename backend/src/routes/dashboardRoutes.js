/**
 * Admin Dashboard & Monitoring Routes
 */
const express = require('express');
const DashboardController = require('../controllers/dashboardController');
const { verifyToken, requireRole } = require('../middleware/authMiddleware');

const router = express.Router();

// Protected for super_admin and content_admin
router.use(verifyToken, requireRole('super_admin', 'content_admin'));

// Summary analytics
router.get('/stats', DashboardController.getStats);

// List all child user profiles
router.get('/users', DashboardController.listUsers);

// Create, update, delete student users
router.post('/users', DashboardController.createUser);
router.put('/users/:id', DashboardController.updateUser);
router.delete('/users/:id', DashboardController.deleteUser);

// List all quiz submissions
router.get('/quiz-results', DashboardController.listQuizResults);

module.exports = router;
