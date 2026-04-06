const { auth } = require('../config/firebase');

/**
 * Firebase authentication middleware
 * Verifies Firebase ID token and attaches user to request
 */
const authenticate = async (req, res, next) => {
  try {
    if (req.user) {
      return next();
    }
    
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        error: 'Missing or invalid authorization header' 
      });
    }

    const token = authHeader.split(' ')[1];
    
    if (!token) {
      return res.status(401).json({ 
        error: 'No token provided' 
      });
    }

    // Verify the Firebase ID token
    const decodedToken = await auth.verifyIdToken(token);
    
    // Attach user info to request
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      emailVerified: decodedToken.email_verified,
    };
    
    next();
  } catch (error) {
    console.error('Authentication error:', error);
    
    if (error.code === 'auth/id-token-expired') {
      return res.status(401).json({ 
        error: 'Token expired',
        code: 'TOKEN_EXPIRED'
      });
    }
    
    if (error.code === 'auth/id-token-revoked') {
      return res.status(401).json({ 
        error: 'Token revoked',
        code: 'TOKEN_REVOKED'
      });
    }
    
    return res.status(401).json({ 
      error: 'Invalid token',
      code: 'INVALID_TOKEN'
    });
  }
};

module.exports = { authenticate };