/**
 * Authentication and Role-Based Authorization Middleware
 */
const jwt = require('jsonwebtoken');
const config = require('../config/env');
const { errorResponse } = require('../utils/apiResponse');

/**
 * Verify JWT token from Authorization header
 */
function verifyToken(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return errorResponse(res, 'Authentication required. No token provided.', null, 401);
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, config.jwt.secret);
    req.user = decoded;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return errorResponse(res, 'Token expired. Please login again.', null, 401);
    }
    return errorResponse(res, 'Invalid authentication token.', null, 401);
  }
}

/**
 * Role authorization guard
 * @param  {...string} allowedRoles (e.g., 'super_admin', 'content_admin')
 */
function requireRole(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return errorResponse(res, 'Unauthorized. Please login first.', null, 401);
    }

    if (!allowedRoles.includes(req.user.role)) {
      return errorResponse(
        res,
        'Forbidden. You do not have permission to perform this action.',
        null,
        403
      );
    }

    next();
  };
}

module.exports = {
  verifyToken,
  requireRole,
};
