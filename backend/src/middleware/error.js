/**
 * Error handling middleware for ContractorLens API
 * Returns consistent error format according to specs/contractorlens-full-spec.md
 */

class APIError extends Error {
  constructor(message, statusCode = 500, code = 'INTERNAL_ERROR', details = null) {
    super(message);
    this.name = 'APIError';
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    this.timestamp = new Date().toISOString();
  }

  toJSON() {
    const errorResponse = {
      error: {
        code: this.code,
        message: this.message,
        timestamp: this.timestamp,
        request_id: this.requestId || null
      }
    };

    // Include details if provided
    if (this.details) {
      errorResponse.error.details = this.details;
    }

    // Include validation errors if present
    if (this.validationErrors) {
      errorResponse.error.validation_errors = this.validationErrors;
    }

    // Include stack trace in development
    if (process.env.NODE_ENV !== 'production') {
      errorResponse.error.stack = this.stack;
    }

    return errorResponse;
  }
}

/**
 * Validation error for request validation failures
 */
class ValidationError extends APIError {
  constructor(message, validationErrors = []) {
    super(message, 400, 'VALIDATION_ERROR');
    this.validationErrors = validationErrors;
  }
}

/**
 * Authentication error
 */
class AuthenticationError extends APIError {
  constructor(message = 'Authentication required') {
    super(message, 401, 'AUTHENTICATION_ERROR');
  }
}

/**
 * Authorization error
 */
class AuthorizationError extends APIError {
  constructor(message = 'Permission denied') {
    super(message, 403, 'AUTHORIZATION_ERROR');
  }
}

/**
 * Resource not found error
 */
class NotFoundError extends APIError {
  constructor(message = 'Resource not found') {
    super(message, 404, 'NOT_FOUND');
  }
}

/**
 * Conflict error (e.g., duplicate resource)
 */
class ConflictError extends APIError {
  constructor(message = 'Resource conflict') {
    super(message, 409, 'CONFLICT');
  }
}

/**
 * Rate limiting error
 */
class RateLimitError extends APIError {
  constructor(message = 'Rate limit exceeded') {
    super(message, 429, 'RATE_LIMIT_EXCEEDED');
  }
}

/**
 * Global error handler middleware
 */
const errorHandler = (err, req, res, next) => {
  // Set default status code
  let statusCode = err.statusCode || 500;
  let errorCode = err.code || 'INTERNAL_ERROR';
  
  // Handle specific error types
  if (err.name === 'ValidationError' || err.name === 'JoiValidationError') {
    statusCode = 400;
    errorCode = 'VALIDATION_ERROR';
  } else if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
    statusCode = 401;
    errorCode = 'INVALID_TOKEN';
  } else if (err.code === '23505') { // PostgreSQL unique violation
    statusCode = 409;
    errorCode = 'CONFLICT';
  } else if (err.code === '23503') { // PostgreSQL foreign key violation
    statusCode = 400;
    errorCode = 'RELATED_RESOURCE_NOT_FOUND';
  } else if (err.code === '42P01') { // PostgreSQL undefined table
    statusCode = 500;
    errorCode = 'DATABASE_ERROR';
  }

  // Log error for debugging
  if (statusCode >= 500) {
    console.error('Server error:', {
      message: err.message,
      stack: err.stack,
      path: req.path,
      method: req.method,
      timestamp: new Date().toISOString()
    });
  }

  // Build error response
  const errorResponse = {
    error: {
      code: errorCode,
      message: err.message || 'Internal server error',
      timestamp: new Date().toISOString(),
      request_id: req.id || null
    }
  };

  // Include validation errors if present
  if (err.details && Array.isArray(err.details)) {
    errorResponse.error.validation_errors = err.details;
  }

  // Include stack trace in development
  if (process.env.NODE_ENV !== 'production' && err.stack) {
    errorResponse.error.stack = err.stack;
  }

  // Send error response
  res.status(statusCode).json(errorResponse);
};

/**
 * 404 Not Found middleware
 */
const notFoundHandler = (req, res, next) => {
  const error = new NotFoundError(`Endpoint ${req.method} ${req.originalUrl} not found`);
  next(error);
};

/**
 * Async handler wrapper to catch async errors
 */
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

module.exports = {
  APIError,
  ValidationError,
  AuthenticationError,
  AuthorizationError,
  NotFoundError,
  ConflictError,
  RateLimitError,
  errorHandler,
  notFoundHandler,
  asyncHandler
};