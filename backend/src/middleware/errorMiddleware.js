/**
 * Error Handling Middleware
 */
const { errorResponse } = require('../utils/apiResponse');
const logger = require('../utils/logger');

function notFoundHandler(req, res, next) {
  return errorResponse(res, `Resource not found: ${req.method} ${req.originalUrl}`, null, 404);
}

function globalErrorHandler(err, req, res, next) {
  logger.error('Unhandled Server Error:', err.stack || err.message);

  // Handle Multer upload errors
  if (err.name === 'MulterError') {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return errorResponse(res, 'Uploaded file exceeds maximum allowed size.', err.message, 400);
    }
    return errorResponse(res, `Upload error: ${err.message}`, err.message, 400);
  }

  // Handle custom file filter errors
  if (err.message && err.message.includes('Unsupported file type')) {
    return errorResponse(res, err.message, null, 400);
  }

  const statusCode = err.status || err.statusCode || 500;
  const message = err.isPublic || process.env.NODE_ENV !== 'production'
    ? err.message
    : 'An unexpected internal server error occurred.';

  return errorResponse(res, message, err.message, statusCode);
}

module.exports = {
  notFoundHandler,
  globalErrorHandler,
};
