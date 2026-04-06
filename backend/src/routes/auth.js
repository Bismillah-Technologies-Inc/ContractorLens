const express = require('express');
const router = express.Router();
const AuthController = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');

/**
 * @route POST /api/v1/auth/register
 * @desc Register new user or update existing user
 * @access Public
 * @body {string} idToken - Firebase ID token
 * @body {string} displayName - User's display name
 * @body {string} [companyName] - Optional company name
 */
router.post('/api/v1/auth/register', AuthController.register);

/**
 * @route POST /api/v1/auth/login
 * @desc Login existing user
 * @access Public
 * @body {string} idToken - Firebase ID token
 */
router.post('/api/v1/auth/login', AuthController.login);

/**
 * @route GET /api/v1/auth/me
 * @desc Get current authenticated user profile
 * @access Private (requires Firebase auth)
 */
router.get('/api/v1/auth/me', authenticate, AuthController.getCurrentUser);

/**
 * @route POST /api/v1/auth/refresh
 * @desc Refresh Firebase ID token
 * @access Public (but requires valid token)
 * @body {string} idToken - Expiring Firebase ID token
 */
router.post('/api/v1/auth/refresh', AuthController.refreshToken);

/**
 * @route PATCH /api/v1/auth/profile
 * @desc Update user profile
 * @access Private (requires Firebase auth)
 * @body {string} [displayName] - New display name
 * @body {string} [companyName] - New company name
 * @body {string} [defaultQualityTier] - New default quality tier (good/better/best)
 */
router.patch('/api/v1/auth/profile', authenticate, AuthController.updateProfile);

/**
 * @route GET /api/v1/auth/health
 * @desc Health check endpoint for auth service
 * @access Public
 */
router.get('/api/v1/auth/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'auth',
    version: '1.0.0',
  });
});

module.exports = router;