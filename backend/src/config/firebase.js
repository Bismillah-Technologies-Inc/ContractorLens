const admin = require('firebase-admin');
require('dotenv').config();

let auth = null;
let firestore = null;

// Only initialize Firebase Admin SDK if required environment variables are present
if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
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

  if (!admin.apps.length) {
    try {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: process.env.FIREBASE_PROJECT_ID,
      });
      console.log('Firebase Admin SDK initialized successfully');
    } catch (error) {
      console.warn('Firebase Admin SDK initialization failed:', error.message);
      console.warn('Authentication will not be available');
    }
  }

  auth = admin.auth();
  firestore = admin.firestore();
} else {
  console.warn('Firebase environment variables not set. Authentication will not be available.');
  
  // Create mock auth object for development/testing
  auth = {
    verifyIdToken: async (token) => {
      throw new Error('Firebase not configured');
    }
  };
  
  firestore = null;
}

module.exports = { admin, auth, firestore };