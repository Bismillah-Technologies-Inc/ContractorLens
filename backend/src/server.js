const express = require('express');
const morgan = require('morgan');
require('dotenv').config();

// Import middleware
const { securityMiddleware, requestIdMiddleware } = require('./middleware/security');
const { routeSpecificRateLimiting } = require('./middleware/rateLimiter');
const { authenticate, authenticateOptional } = require('./middleware/auth');
const { errorHandler, notFoundHandler } = require('./middleware/error');
const { metricsMiddleware } = require('./middleware/metrics');

// Import routes
const estimatesRoutes = require('./routes/estimates');
const analysisRoutes = require('./routes/analysis');

// Import database connection (this will test the connection)
const db = require('./config/database');

const app = express();
const PORT = process.env.PORT || 3000;

// Request ID for tracing
app.use(requestIdMiddleware);

// Security middleware (CORS + Helmet + custom headers)
app.use(securityMiddleware);

// Request logging with Morgan
if (process.env.NODE_ENV === 'production') {
  // Production: concise logging
  app.use(morgan('combined', {
    skip: (req, res) => req.path === '/health' || res.statusCode < 400
  }));
} else {
  // Development: verbose logging
  app.use(morgan('dev'));
}

// Body parsing middleware
app.use(express.json({ limit: '10mb' })); // Large limit for takeoff data
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Metrics middleware
app.use(metricsMiddleware);

// Rate limiting (applied after security but before routes)
app.use(routeSpecificRateLimiting);

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    // Test database connection
    await db.query('SELECT 1');
    
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      version: '1.0.0',
      services: {
        database: 'connected',
        assemblyEngine: 'operational'
      }
    });
  } catch (error) {
    console.error('Health check failed:', error);
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: 'Database connection failed'
    });
  }
});

// API documentation endpoint
app.get('/api/v1', (req, res) => {
  res.json({
    name: 'ContractorLens Backend API',
    version: '1.0.0',
    description: 'Assembly Engine and cost calculation API for ContractorLens',
    endpoints: {
      'POST /api/v1/estimates': 'Create new estimate using Assembly Engine',
      'GET /api/v1/estimates': 'List user estimates with pagination',
      'GET /api/v1/estimates/:id': 'Get specific estimate details',
      'PUT /api/v1/estimates/:id/status': 'Update estimate status',
      'DELETE /api/v1/estimates/:id': 'Delete draft estimate',
      'POST /api/v1/analysis/enhanced-estimate': 'Create AI-enhanced estimate with Gemini analysis',
      'POST /api/v1/analysis/room-analysis': 'Analyze room images without creating estimate',
      'GET /api/v1/analysis/health': 'Gemini integration service health check',
      'GET /api/v1/analysis/capabilities': 'Service capabilities and supported features'
    },
    authentication: 'Firebase ID Token via Authorization: Bearer <token>',
    docs: 'https://docs.contractorlens.com/api'
  });
});

// Mount routes with appropriate authentication
app.use(estimatesRoutes);
app.use(analysisRoutes);

// 404 handler
app.use(notFoundHandler);

// Global error handler (must be last)
app.use(errorHandler);

// Graceful shutdown handling
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully...');
  
  server.close(() => {
    console.log('Server closed');
    db.end(() => {
      console.log('Database connections closed');
      process.exit(0);
    });
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully...');
  
  server.close(() => {
    console.log('Server closed');
    db.end(() => {
      console.log('Database connections closed');
      process.exit(0);
    });
  });
});

// Start server
const server = app.listen(PORT, () => {
  console.log(`🚀 ContractorLens Backend Server running on port ${PORT}`);
  console.log(`📊 Assembly Engine operational`);
  console.log(`🔍 Health check: http://localhost:${PORT}/health`);
  console.log(`📚 API docs: http://localhost:${PORT}/api/v1`);
  
  if (process.env.NODE_ENV === 'development') {
    console.log(`🔧 Development mode - detailed logging enabled`);
  }
});

module.exports = app;