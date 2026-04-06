const Joi = require('joi');
const { auth } = require('../config/firebase');
const UserModel = require('../models/userModel');

/**
 * Joi validation schemas
 */
const authSchemas = {
  register: Joi.object({
    idToken: Joi.string().required(),
    displayName: Joi.string().required(),
    companyName: Joi.string().optional().allow(''),
  }),
  
  login: Joi.object({
    idToken: Joi.string().required(),
  }),
  
  refresh: Joi.object({
    idToken: Joi.string().required(),
  }),
};

/**
 * Auth controller for handling authentication endpoints
 */
class AuthController {
  /**
   * POST /auth/register - Register new user or update existing
   */
  static async register(req, res) {
    try {
      // Validate request body
      const { error, value } = authSchemas.register.validate(req.body);
      if (error) {
        return res.status(400).json({ error: `Validation error: ${error.details[0].message}` });
      }

      const { idToken, displayName, companyName } = value;

      // Verify Firebase token
      let decodedToken;
      try {
        decodedToken = await auth.verifyIdToken(idToken);
      } catch (firebaseError) {
        return res.status(401).json({ 
          error: 'Invalid Firebase token',
          code: 'INVALID_TOKEN' 
        });
      }

      // Check if email is verified
      if (!decodedToken.email_verified) {
        return res.status(400).json({ 
          error: 'Email not verified',
          code: 'EMAIL_NOT_VERIFIED' 
        });
      }

      // Find or create user in database
      const user = await UserModel.findOrCreateUser(
        decodedToken.uid,
        decodedToken.email,
        { displayName, companyName }
      );

      // Generate refresh token (using Firebase)
      const refreshToken = await auth.createCustomToken(decodedToken.uid);

      res.status(200).json({
        success: true,
        user: {
          userId: user.user_id,
          firebaseUid: user.firebase_uid,
          email: user.email,
          displayName: user.display_name,
          companyName: user.company_name,
          defaultQualityTier: user.default_quality_tier,
          createdAt: user.created_at,
        },
        token: idToken,
        refreshToken,
      });
    } catch (error) {
      console.error('Register error:', error);
      
      if (error.code === '23505') { // Unique constraint violation
        return res.status(409).json({ 
          error: 'User already exists with different Firebase UID',
          code: 'USER_EXISTS'
        });
      }
      
      res.status(500).json({ 
        error: 'Internal server error during registration',
        code: 'INTERNAL_ERROR' 
      });
    }
  }

  /**
   * POST /auth/login - Login existing user
   */
  static async login(req, res) {
    try {
      // Validate request body
      const { error, value } = authSchemas.login.validate(req.body);
      if (error) {
        return res.status(400).json({ error: `Validation error: ${error.details[0].message}` });
      }

      const { idToken } = value;

      // Verify Firebase token
      let decodedToken;
      try {
        decodedToken = await auth.verifyIdToken(idToken);
      } catch (firebaseError) {
        return res.status(401).json({ 
          error: 'Invalid Firebase token',
          code: 'INVALID_TOKEN' 
        });
      }

      // Get user from database
      const user = await UserModel.getUserByFirebaseUid(decodedToken.uid);
      
      if (!user) {
        return res.status(404).json({ 
          error: 'User not found. Please register first.',
          code: 'USER_NOT_FOUND' 
        });
      }

      // Generate refresh token
      const refreshToken = await auth.createCustomToken(decodedToken.uid);

      // TODO: Get subscription status from subscription table
      const subscriptionStatus = {
        tier: 'free',
        expiresAt: null,
        isActive: true,
      };

      res.status(200).json({
        success: true,
        user: {
          userId: user.user_id,
          firebaseUid: user.firebase_uid,
          email: user.email,
          displayName: user.display_name,
          companyName: user.company_name,
          defaultQualityTier: user.default_quality_tier,
          createdAt: user.created_at,
        },
        subscription: subscriptionStatus,
        token: idToken,
        refreshToken,
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({ 
        error: 'Internal server error during login',
        code: 'INTERNAL_ERROR' 
      });
    }
  }

  /**
   * GET /auth/me - Get current user profile
   */
  static async getCurrentUser(req, res) {
    try {
      // req.user is set by auth middleware
      const firebaseUid = req.user.uid;

      // Get user from database
      const user = await UserModel.getUserByFirebaseUid(firebaseUid);
      
      if (!user) {
        return res.status(404).json({ 
          error: 'User profile not found',
          code: 'PROFILE_NOT_FOUND' 
        });
      }

      // TODO: Get finish preferences from user settings
      const finishPreferences = {
        defaultQualityTier: user.default_quality_tier || 'better',
        preferredPaymentTerms: 'net_30',
        includeTaxInEstimates: true,
        markupPercentage: 15.0,
      };

      // TODO: Get subscription status from subscription table
      const subscriptionStatus = {
        tier: 'free',
        expiresAt: null,
        isActive: true,
      };

      res.status(200).json({
        success: true,
        user: {
          userId: user.user_id,
          firebaseUid: user.firebase_uid,
          email: user.email,
          displayName: user.display_name,
          companyName: user.company_name,
          defaultQualityTier: user.default_quality_tier,
          createdAt: user.created_at,
        },
        subscription: subscriptionStatus,
        preferences: finishPreferences,
      });
    } catch (error) {
      console.error('Get current user error:', error);
      res.status(500).json({ 
        error: 'Internal server error',
        code: 'INTERNAL_ERROR' 
      });
    }
  }

  /**
   * POST /auth/refresh - Refresh Firebase ID token
   */
  static async refreshToken(req, res) {
    try {
      // Validate request body
      const { error, value } = authSchemas.refresh.validate(req.body);
      if (error) {
        return res.status(400).json({ error: `Validation error: ${error.details[0].message}` });
      }

      const { idToken } = value;

      // Verify the old token
      let decodedToken;
      try {
        decodedToken = await auth.verifyIdToken(idToken, true); // Check if revoked
      } catch (firebaseError) {
        return res.status(401).json({ 
          error: 'Invalid or expired token',
          code: 'INVALID_TOKEN' 
        });
      }

      // Create new custom token
      const newToken = await auth.createCustomToken(decodedToken.uid);

      res.status(200).json({
        success: true,
        token: newToken,
      });
    } catch (error) {
      console.error('Refresh token error:', error);
      res.status(500).json({ 
        error: 'Internal server error during token refresh',
        code: 'INTERNAL_ERROR' 
      });
    }
  }

  /**
   * PATCH /auth/profile - Update user profile
   */
  static async updateProfile(req, res) {
    try {
      const firebaseUid = req.user.uid;

      // Get user first to get user_id
      const user = await UserModel.getUserByFirebaseUid(firebaseUid);
      if (!user) {
        return res.status(404).json({ 
          error: 'User not found',
          code: 'USER_NOT_FOUND' 
        });
      }

      // Validate update fields
      const schema = Joi.object({
        displayName: Joi.string().optional(),
        companyName: Joi.string().optional().allow(''),
        defaultQualityTier: Joi.string().valid('good', 'better', 'best').optional(),
      });

      const { error, value } = schema.validate(req.body);
      if (error) {
        return res.status(400).json({ error: `Validation error: ${error.details[0].message}` });
      }

      // Update user profile
      const updatedUser = await UserModel.updateUserProfile(user.user_id, value);

      res.status(200).json({
        success: true,
        user: {
          userId: updatedUser.user_id,
          firebaseUid: updatedUser.firebase_uid,
          email: updatedUser.email,
          displayName: updatedUser.display_name,
          companyName: updatedUser.company_name,
          defaultQualityTier: updatedUser.default_quality_tier,
          createdAt: updatedUser.created_at,
        },
      });
    } catch (error) {
      console.error('Update profile error:', error);
      res.status(500).json({ 
        error: 'Internal server error',
        code: 'INTERNAL_ERROR' 
      });
    }
  }
}

module.exports = AuthController;