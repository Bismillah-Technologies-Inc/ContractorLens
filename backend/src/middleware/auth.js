const { auth } = require('../config/firebase');
const db = require('../config/database');
const { AuthenticationError } = require('./error');

/**
 * Firebase authentication middleware
 * Verifies Firebase ID token, fetches user profile from database, and attaches to request
 */
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new AuthenticationError('Missing or invalid authorization header');
    }

    const token = authHeader.split(' ')[1];
    
    if (!token) {
      throw new AuthenticationError('No token provided');
    }

    // Verify the Firebase ID token
    const decodedToken = await auth.verifyIdToken(token);
    
    // Fetch user profile from database
    let userProfile = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      emailVerified: decodedToken.email_verified,
      displayName: null,
      companyName: null
    };

    try {
      // Query user profile from database
      const result = await db.query(
        'SELECT display_name, company_name, default_quality_tier FROM contractorlens.Users WHERE user_id = $1',
        [decodedToken.uid]
      );

      if (result.rows.length > 0) {
        const dbUser = result.rows[0];
        userProfile.displayName = dbUser.display_name;
        userProfile.companyName = dbUser.company_name;
        userProfile.defaultQualityTier = dbUser.default_quality_tier;
      } else {
        // User exists in Firebase but not in our database
        // This can happen during initial registration
        // We'll create the user record on first authenticated request
        console.log(`User ${decodedToken.uid} not found in database, will be created on first API call`);
      }
    } catch (dbError) {
      console.error('Database error fetching user profile:', dbError);
      // Continue without database profile if there's a DB error
      // The user is still authenticated via Firebase
    }
    
    // Attach complete user info to request
    req.user = userProfile;
    
    next();
  } catch (error) {
    console.error('Authentication error:', error);
    
    if (error.name === 'AuthenticationError') {
      return res.status(error.statusCode).json(error.toJSON());
    }
    
    if (error.code === 'auth/id-token-expired') {
      const authError = new AuthenticationError('Token expired');
      authError.code = 'TOKEN_EXPIRED';
      return res.status(401).json(authError.toJSON());
    }
    
    if (error.code === 'auth/id-token-revoked') {
      const authError = new AuthenticationError('Token revoked');
      authError.code = 'TOKEN_REVOKED';
      return res.status(401).json(authError.toJSON());
    }
    
    const authError = new AuthenticationError('Invalid token');
    authError.code = 'INVALID_TOKEN';
    return res.status(401).json(authError.toJSON());
  }
};

/**
 * Optional authentication middleware
 * Attaches user if token is present, but doesn't require it
 */
const authenticateOptional = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      req.user = null;
      return next();
    }

    const token = authHeader.split(' ')[1];
    
    if (!token) {
      req.user = null;
      return next();
    }

    // Verify the Firebase ID token
    const decodedToken = await auth.verifyIdToken(token);
    
    // Fetch user profile from database
    let userProfile = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      emailVerified: decodedToken.email_verified,
      displayName: null,
      companyName: null
    };

    try {
      // Query user profile from database
      const result = await db.query(
        'SELECT display_name, company_name, default_quality_tier FROM contractorlens.Users WHERE user_id = $1',
        [decodedToken.uid]
      );

      if (result.rows.length > 0) {
        const dbUser = result.rows[0];
        userProfile.displayName = dbUser.display_name;
        userProfile.companyName = dbUser.company_name;
        userProfile.defaultQualityTier = dbUser.default_quality_tier;
      }
    } catch (dbError) {
      console.error('Database error fetching user profile:', dbError);
      // Continue without database profile
    }
    
    // Attach complete user info to request
    req.user = userProfile;
    
    next();
  } catch (error) {
    // If token is invalid, continue without authentication
    console.warn('Optional authentication failed:', error.message);
    req.user = null;
    next();
  }
};

/**
 * Authorization middleware - require specific user role or permission
 * (To be implemented based on actual authorization requirements)
 */
const requireRole = (role) => {
  return (req, res, next) => {
    if (!req.user) {
      throw new AuthenticationError('Authentication required');
    }
    
    // Implement role checking logic here
    // For now, just pass through
    next();
  };
};

/**
 * Ownership middleware - ensure user owns the resource
 * (To be implemented based on resource ownership patterns)
 */
const requireOwnership = (resourceType, idParam = 'id') => {
  return async (req, res, next) => {
    if (!req.user) {
      throw new AuthenticationError('Authentication required');
    }
    
    const resourceId = req.params[idParam];
    
    try {
      // Implement ownership checking logic here based on resourceType
      // For now, just pass through
      next();
    } catch (error) {
      next(error);
    }
  };
};

module.exports = { 
  authenticate, 
  authenticateOptional,
  requireRole,
  requireOwnership 
};