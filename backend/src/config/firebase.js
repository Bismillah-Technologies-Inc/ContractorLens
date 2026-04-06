const admin = require('firebase-admin');
require('dotenv').config();

// Check if we're in test mode or have incomplete Firebase config
const isTestMode = process.env.NODE_ENV === 'test' || 
                  !process.env.FIREBASE_PROJECT_ID ||
                  !process.env.FIREBASE_PRIVATE_KEY;

let auth = null;
let firestore = null;

if (!isTestMode && !admin.apps.length) {
  try {
    // Initialize Firebase Admin SDK
    const serviceAccount = {
      type: 'service_account',
      project_id: process.env.FIREBASE_PROJECT_ID,
      private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
      private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      client_email: process.env.FIREBASE_CLIENT_EMAIL,
      client_id: process.env.FIREBASE_CLIENT_ID,
      auth_uri: process.env.FIREBASE_AUTH_URI,
      token_uri: process.env.FIREBASE_TOKEN_URI,
    };

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: process.env.FIREBASE_PROJECT_ID,
    });

    auth = admin.auth();
    firestore = admin.firestore();
    
    console.log('✅ Firebase Admin SDK initialized successfully');
  } catch (error) {
    console.warn('⚠️ Firebase Admin SDK initialization failed:', error.message);
    console.warn('⚠️ Auth endpoints will use mock authentication in test mode');
  }
} else if (isTestMode) {
  console.log('🧪 Test mode: Using mock Firebase authentication');
  
  // Create mock auth object for testing
  auth = {
    verifyIdToken: async (token) => {
      // Simple mock verification for tests
      if (token === 'test-valid-token') {
        return {
          uid: 'test-user-uid',
          email: 'test@example.com',
          email_verified: true,
        };
      }
      throw new Error('Invalid token');
    },
    createCustomToken: async (uid) => {
      return `mock-custom-token-${uid}`;
    },
  };
  
  firestore = {
    collection: () => ({
      doc: () => ({
        get: async () => ({ exists: false }),
        set: async () => {},
      }),
    }),
  };
}

module.exports = { admin, auth, firestore };