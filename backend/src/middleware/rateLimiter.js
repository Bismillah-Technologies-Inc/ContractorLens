/**
 * Rate limiting middleware for ContractorLens API
 * Stricter limits for auth routes, standard limits for other routes
 */

const rateLimit = require('express-rate-limit');
const { RateLimitError } = require('./error');

/**
 * Standard rate limiter for most API routes
 * 100 requests per 15 minutes per IP
 */
const standardLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  keyGenerator: (req) => {
    // Use IP address as key, but prefer authenticated user ID if available
    return req.user?.uid || req.ip;
  },
  handler: (req, res) => {
    const error = new RateLimitError('Rate limit exceeded. Please try again later.');
    res.status(429).json(error.toJSON());
  },
  skip: (req) => {
    // Skip rate limiting for health checks
    return req.path === '/health' || req.path === '/health';
  }
});

/**
 * Stricter rate limiter for authentication routes
 * 10 requests per 15 minutes per IP
 */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // Limit each IP to 10 requests per windowMs (stricter for auth)
  message: 'Too many authentication attempts from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.ip, // Always use IP for auth routes
  handler: (req, res) => {
    const error = new RateLimitError('Too many authentication attempts. Please try again later.');
    res.status(429).json(error.toJSON());
  },
  skip: (req) => {
    // Skip rate limiting for health checks
    return req.path === '/health' || req.path === '/health';
  }
});

/**
 * File upload rate limiter (more generous for large uploads)
 * 20 requests per 15 minutes per IP
 */
const uploadLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20, // Limit each IP to 20 uploads per windowMs
  message: 'Too many file uploads from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.user?.uid || req.ip,
  handler: (req, res) => {
    const error = new RateLimitError('Too many file uploads. Please try again later.');
    res.status(429).json(error.toJSON());
  }
});

/**
 * Development rate limiter (more generous for development)
 */
const developmentLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // Very high limit for development
  standardHeaders: true,
  legacyHeaders: false,
  skip: () => process.env.NODE_ENV === 'development',
  handler: (req, res) => {
    const error = new RateLimitError('Development rate limit exceeded.');
    res.status(429).json(error.toJSON());
  }
});

/**
 * Rate limiter configuration based on environment
 */
const getRateLimiter = () => {
  if (process.env.NODE_ENV === 'test') {
    // No rate limiting in tests
    return (req, res, next) => next();
  }
  
  if (process.env.NODE_ENV === 'development') {
    return developmentLimiter;
  }
  
  return standardLimiter;
};

/**
 * Middleware to apply appropriate rate limiter based on route
 */
const routeSpecificRateLimiting = (req, res, next) => {
  // Determine which rate limiter to use based on route
  const path = req.path;
  
  // Auth routes get stricter limiting
  if (path.startsWith('/api/v1/auth/') || 
      path === '/api/v1/auth/register' || 
      path === '/api/v1/auth/login' ||
      path === '/api/v1/auth/refresh') {
    return authLimiter(req, res, next);
  }
  
  // Upload routes use upload limiter
  if (path.includes('/upload') || path.includes('/scan') || path.includes('/image')) {
    return uploadLimiter(req, res, next);
  }
  
  // All other routes use standard limiter
  return standardLimiter(req, res, next);
};

/**
 * Rate limiter for websocket connections (if implemented later)
 */
const wsRateLimiter = (connection, next) => {
  // Implementation for WebSocket rate limiting
  // This would need to be integrated with a WebSocket server
  next();
};

module.exports = {
  standardLimiter,
  authLimiter,
  uploadLimiter,
  developmentLimiter,
  getRateLimiter,
  routeSpecificRateLimiting,
  wsRateLimiter
};