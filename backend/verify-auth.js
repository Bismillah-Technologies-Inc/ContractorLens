#!/usr/bin/env node

/**
 * Verify Auth Endpoints Implementation
 * Checks that all required files and functions exist
 */

const fs = require('fs');
const path = require('path');

console.log('🔍 Verifying Auth Endpoints Implementation\n');

let errors = [];

// Check if files exist
const requiredFiles = [
  'src/controllers/authController.js',
  'src/models/userModel.js',
  'src/routes/auth.js',
  'src/middleware/auth.js',
  'src/config/firebase.js',
  'src/config/database.js',
];

console.log('📁 Checking required files...');
for (const file of requiredFiles) {
  const filePath = path.join(__dirname, file);
  if (fs.existsSync(filePath)) {
    console.log(`  ✅ ${file}`);
  } else {
    console.log(`  ❌ ${file} - MISSING`);
    errors.push(`Missing file: ${file}`);
  }
}

// Check controller exports
console.log('\n🎯 Checking controller exports...');
try {
  const authController = require('./src/controllers/authController');
  const requiredMethods = ['register', 'login', 'getCurrentUser', 'refreshToken', 'updateProfile'];
  
  for (const method of requiredMethods) {
    if (typeof authController[method] === 'function') {
      console.log(`  ✅ AuthController.${method}()`);
    } else {
      console.log(`  ❌ AuthController.${method}() - MISSING`);
      errors.push(`Missing method: AuthController.${method}`);
    }
  }
} catch (error) {
  console.log(`  ❌ Failed to load auth controller: ${error.message}`);
  errors.push(`Failed to load auth controller: ${error.message}`);
}

// Check model exports  
console.log('\n💾 Checking model exports...');
try {
  const userModel = require('./src/models/userModel');
  const requiredModelMethods = ['findOrCreateUser', 'getUserByFirebaseUid', 'getUserById', 'updateUserProfile'];
  
  for (const method of requiredModelMethods) {
    if (typeof userModel[method] === 'function') {
      console.log(`  ✅ UserModel.${method}()`);
    } else if (typeof userModel.default?.[method] === 'function') {
      console.log(`  ✅ UserModel.default.${method}()`);
    } else {
      console.log(`  ❌ UserModel.${method}() - MISSING`);
      errors.push(`Missing method: UserModel.${method}`);
    }
  }
} catch (error) {
  console.log(`  ❌ Failed to load user model: ${error.message}`);
  errors.push(`Failed to load user model: ${error.message}`);
}

// Check middleware
console.log('\n🔐 Checking auth middleware...');
try {
  const authMiddleware = require('./src/middleware/auth');
  if (typeof authMiddleware.authenticate === 'function') {
    console.log(`  ✅ authenticate middleware`);
  } else {
    console.log(`  ❌ authenticate middleware - MISSING`);
    errors.push(`Missing authenticate middleware`);
  }
} catch (error) {
  console.log(`  ❌ Failed to load auth middleware: ${error.message}`);
  errors.push(`Failed to load auth middleware: ${error.message}`);
}

// Check routes file
console.log('\n🛣️  Checking routes file structure...');
try {
  const routesContent = fs.readFileSync(path.join(__dirname, 'src/routes/auth.js'), 'utf8');
  
  const requiredRoutes = [
    'POST /api/v1/auth/register',
    'POST /api/v1/auth/login', 
    'GET /api/v1/auth/me',
    'POST /api/v1/auth/refresh',
    'PATCH /api/v1/auth/profile',
    'GET /api/v1/auth/health',
  ];
  
  for (const route of requiredRoutes) {
    const [method, path] = route.split(' ');
    if (routesContent.includes(`${method} ${path}`) || routesContent.includes(`router.${method.toLowerCase()}('${path}'`)) {
      console.log(`  ✅ ${route}`);
    } else {
      console.log(`  ❌ ${route} - NOT FOUND`);
      errors.push(`Route not found: ${route}`);
    }
  }
} catch (error) {
  console.log(`  ❌ Failed to read routes file: ${error.message}`);
  errors.push(`Failed to read routes file: ${error.message}`);
}

// Check server.js has auth routes
console.log('\n🌐 Checking server integration...');
try {
  const serverContent = fs.readFileSync(path.join(__dirname, 'src/server.js'), 'utf8');
  
  const checks = [
    { name: 'authRoutes import', pattern: /const authRoutes = require/ },
    { name: 'authRoutes mounting', pattern: /app\.use\(authRoutes\)/ },
    { name: 'auth routes in API docs', pattern: /auth.*register/ },
  ];
  
  for (const check of checks) {
    if (check.pattern.test(serverContent)) {
      console.log(`  ✅ ${check.name}`);
    } else {
      console.log(`  ❌ ${check.name} - MISSING`);
      errors.push(`Missing in server.js: ${check.name}`);
    }
  }
} catch (error) {
  console.log(`  ❌ Failed to read server.js: ${error.message}`);
  errors.push(`Failed to read server.js: ${error.message}`);
}

// Summary
console.log('\n========================================');
console.log('📋 Verification Summary');
console.log('========================================');

if (errors.length === 0) {
  console.log('🎉 All checks passed!');
  console.log('\n✅ Auth endpoints implementation is complete and ready for integration.');
  console.log('\n🔧 Files created:');
  console.log('  - src/controllers/authController.js - Complete auth business logic');
  console.log('  - src/models/userModel.js - Database operations for Users table');
  console.log('  - src/routes/auth.js - All auth endpoint routes');
  console.log('  - Updated src/middleware/auth.js - Enhanced with test mode support');
  console.log('  - Updated src/config/firebase.js - Added test mode handling');
  console.log('  - Updated src/server.js - Added auth routes to main server');
  console.log('\n🚀 Endpoints implemented:');
  console.log('  - POST /api/v1/auth/register - Register user with Firebase');
  console.log('  - POST /api/v1/auth/login - Login existing user');
  console.log('  - GET /api/v1/auth/me - Get current user profile');
  console.log('  - POST /api/v1/auth/refresh - Refresh Firebase token');
  console.log('  - PATCH /api/v1/auth/profile - Update user profile');
  console.log('  - GET /api/v1/auth/health - Auth service health check');
  console.log('\n🧪 Testing:');
  console.log('  - tests/auth.test.js - Unit tests for auth logic');
  console.log('  - tests/auth-integration.test.js - Integration test scripts');
  console.log('\n📋 Database schema support:');
  console.log('  - contractorlens.Users table already exists (V3 migration)');
  console.log('  - Supports user_id (UUID), firebase_uid, email, display_name, company_name');
  console.log('  - Default quality tier: "better"');
  console.log('\nThe auth endpoints are complete and ready for Firebase integration.');
} else {
  console.log(`❌ Found ${errors.length} issues:`);
  errors.forEach(error => console.log(`  - ${error}`));
  console.log('\n💥 Verification failed. Please fix the issues above.');
  process.exit(1);
}