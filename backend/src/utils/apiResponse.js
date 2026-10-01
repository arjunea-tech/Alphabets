/**
 * Standard API Response Formatter for AGARAM Application
 */

function successResponse(res, message = 'Success', data = null, statusCode = 200) {
  const response = {
    success: true,
    message,
  };

  if (data !== null && data !== undefined) {
    response.data = data;
  }

  return res.status(statusCode).json(response);
}

function errorResponse(res, message = 'Something went wrong', error = null, statusCode = 500) {
  const response = {
    success: false,
    message,
  };

  if (error !== null && error !== undefined) {
    response.error = typeof error === 'string' ? error : (error.message || error);
  }

  return res.status(statusCode).json(response);
}

module.exports = {
  successResponse,
  errorResponse,
};
