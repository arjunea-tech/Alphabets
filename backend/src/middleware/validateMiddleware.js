/**
 * Request Validation Middleware
 * Checks express-validator results and returns standard error responses.
 */
const { validationResult } = require('express-validator');
const { errorResponse } = require('../utils/apiResponse');

function validateRequest(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const errorDetails = errors.array().map((err) => ({
      field: err.path || err.param,
      message: err.msg,
      value: err.value,
    }));
    return errorResponse(res, 'Validation failed. Please check your inputs.', errorDetails, 422);
  }
  next();
}

module.exports = {
  validateRequest,
};
