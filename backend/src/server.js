const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

// Import routes
const estimatesRoutes = require('./routes/estimates');
const analysisRoutes = require('./routes/analysis');
const authRoutes = require('./routes/auth');
const projectsRoutes = require('./routes/projects');
const { authenticate } = require('./middleware/auth');

// Import database connection (this will test the connection)
const db = require('./config/database');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}));

// CORS configuration
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? ['https://contractorlens.com', 'https://app.contractorlens.com']
    : ['http://localhost:3000', 'http://localhost:8080', 'http://127.0.0.1:3000'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
}));

// Body parsing middleware
app.use(express.json({ limit: '10mb' })); // Large limit for takeoff data
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging middleware (development only)
if (process.env.NODE_ENV !== 'production') {
  app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} ${req.method} ${req.path}`);
    next();
  });
}

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

// Mount routes
app.use((req, res, next) => {
  if (!req.path.startsWith('/api/v1')) {
    return next();
  }

  const publicPaths = [
    '/api/v1',
    '/api/v1/',
    '/api/v1/analysis/health',
    '/api/v1/webhooks/stripe'
  ];
  
  if (publicPaths.includes(req.path)) {
    return next();
  }
  
  return authenticate(req, res, next);
});

app.use(estimatesRoutes);
app.use(analysisRoutes);
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/projects', projectsRoutes);

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    message: `${req.method} ${req.originalUrl} is not a valid endpoint`,
    availableEndpoints: [
      'GET /health',
      'GET /api/v1',
      'POST /api/v1/estimates',
      'GET /api/v1/estimates',
      'GET /api/v1/estimates/:id',
      'PUT /api/v1/estimates/:id/status',
      'DELETE /api/v1/estimates/:id',
      'POST /api/v1/analysis/enhanced-estimate',
      'POST /api/v1/analysis/room-analysis',
      'GET /api/v1/analysis/health',
      'GET /api/v1/analysis/capabilities'
    ]
  });
});

// Global error handler
app.use((error, req, res, next) => {
  console.error('Global error handler:', error);
  
  // Don't leak error details in production
  const isDevelopment = process.env.NODE_ENV !== 'production';
  
  res.status(error.status || 500).json({
    error: 'Internal server error',
    message: isDevelopment ? error.message : 'Something went wrong',
    ...(isDevelopment && { stack: error.stack })
  });
});

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