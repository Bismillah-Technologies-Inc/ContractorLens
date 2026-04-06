const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

// Import only auth routes for testing
const authRoutes = require('./src/routes/auth');

const app = express();
const PORT = process.env.PORT || 3001;

// Basic middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'auth-test-server',
  });
});

// API docs
app.get('/api/v1', (req, res) => {
  res.json({
    name: 'Auth Test Server',
    version: '1.0.0',
    description: 'Auth endpoint test server',
    endpoints: {
      'POST /api/v1/auth/register': 'Register new user',
      'POST /api/v1/auth/login': 'Login existing user',
      'GET /api/v1/auth/me': 'Get current user profile',
      'POST /api/v1/auth/refresh': 'Refresh token',
      'PATCH /api/v1/auth/profile': 'Update profile',
      'GET /api/v1/auth/health': 'Auth service health',
    },
  });
});

// Mount auth routes
app.use(authRoutes);

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    message: `${req.method} ${req.originalUrl} is not a valid endpoint`,
  });
});

// Error handler
app.use((error, req, res, next) => {
  console.error('Error:', error);
  res.status(500).json({
    error: 'Internal server error',
    message: error.message,
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`✅ Auth Test Server running on port ${PORT}`);
  console.log(`🔍 Health check: http://localhost:${PORT}/health`);
  console.log(`📚 API docs: http://localhost:${PORT}/api/v1`);
  console.log(`🧪 Test mode: Auth endpoints are mock-authenticated`);
});

module.exports = app;