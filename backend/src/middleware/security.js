/**
 * Security middleware for ContractorLens API
 * Combines CORS and security headers with environment-specific configurations
 */

const cors = require('cors');
const helmet = require('helmet');

/**
 * CORS configuration with environment-specific origins
 * - Development: Allow all localhost origins
 * - Production: Restrict to specific domains
 */
const corsOptions = {
  origin: (origin, callback) => {
    // Allow requests with no origin (like mobile apps, curl, postman)
    if (!origin) {
      return callback(null, true);
    }

    const allowedOrigins = {
      development: [
        'http://localhost:3000',
        'http://localhost:3001', 
        'http://localhost:8080',
        'http://127.0.0.1:3000',
        'http://127.0.0.1:3001',
        'http://127.0.0.1:8080',
        'http://localhost:5173', // Vite dev server
        'http://127.0.0.1:5173'
      ],
      production: [
        'https://contractorlens.com',
        'https://www.contractorlens.com',
        'https://app.contractorlens.com',
        'https://admin.contractorlens.com',
        'https://client.contractorlens.com'
      ],
      staging: [
        'https://staging.contractorlens.com',
        'https://staging-app.contractorlens.com',
        'http://localhost:3000', // For local testing
        'http://localhost:3001'
      ]
    };

    const environment = process.env.NODE_ENV || 'development';
    const origins = allowedOrigins[environment] || allowedOrigins.development;

    if (origins.indexOf(origin) !== -1 || process.env.NODE_ENV === 'development') {
      callback(null, true);
    } else {
      console.warn(`CORS blocked origin: ${origin} in ${environment} environment`);
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: [
    'Content-Type',
    'Authorization',
    'X-Requested-With',
    'Accept',
    'X-API-Key',
    'X-Request-ID',
    'X-CSRF-Token'
  ],
  exposedHeaders: [
    'X-RateLimit-Limit',
    'X-RateLimit-Remaining',
    'X-RateLimit-Reset',
    'X-Request-ID'
  ],
  maxAge: 86400, // 24 hours in seconds
  preflightContinue: false,
  optionsSuccessStatus: 204
};

/**
 * Helmet security headers configuration
 * Customized for ContractorLens API
 */
const helmetOptions = {
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", 'https:', 'data:'],
      scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'", 'https:'],
      imgSrc: ["'self'", 'data:', 'https:', 'blob:'],
      fontSrc: ["'self'", 'https:', 'data:'],
      connectSrc: ["'self'", 'https:'],
      frameSrc: ["'self'", 'https:'],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'", 'https:', 'data:'],
      manifestSrc: ["'self'", 'https:'],
      workerSrc: ["'self'", 'blob:'],
      childSrc: ["'self'", 'blob:'],
      formAction: ["'self'", 'https:'],
      baseUri: ["'self'"],
      frameAncestors: ["'self'"],
      upgradeInsecureRequests: process.env.NODE_ENV === 'production' ? [] : null
    }
  },
  crossOriginEmbedderPolicy: false, // Allow embedding for iframes if needed
  crossOriginOpenerPolicy: false,
  crossOriginResourcePolicy: { policy: "cross-origin" }, // Allow cross-origin resources
  dnsPrefetchControl: { allow: false },
  expectCt: false,
  frameguard: { action: 'sameorigin' },
  hidePoweredBy: true,
  hsts: {
    maxAge: 31536000, // 1 year in seconds
    includeSubDomains: true,
    preload: true
  },
  ieNoOpen: true,
  noSniff: true,
  originAgentCluster: true,
  permittedCrossDomainPolicies: { permittedPolicies: "none" },
  referrerPolicy: { policy: "strict-origin-when-cross-origin" },
  xssFilter: true
};

/**
 * Development-specific security relaxations
 */
const developmentSecurityConfig = (req, res, next) => {
  if (process.env.NODE_ENV === 'development' || process.env.NODE_ENV === 'test') {
    // More permissive CORS in development
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Headers', '*');
    res.header('Access-Control-Allow-Methods', '*');
    
    // Skip some security headers for local development
    helmet({
      contentSecurityPolicy: false,
      hsts: false
    })(req, res, next);
  } else {
    // Apply full security in production
    helmet(helmetOptions)(req, res, next);
  }
};

/**
 * Security middleware that applies:
 * 1. CORS with environment-specific configuration
 * 2. Helmet security headers
 * 3. Additional security headers
 */
const securityMiddleware = [
  // Apply CORS
  cors(corsOptions),
  
  // Apply security headers (Helmet)
  developmentSecurityConfig,
  
  // Additional custom security headers
  (req, res, next) => {
    // X-Content-Type-Options: prevent MIME type sniffing
    res.setHeader('X-Content-Type-Options', 'nosniff');
    
    // X-Frame-Options: prevent clickjacking
    res.setHeader('X-Frame-Options', 'SAMEORIGIN');
    
    // X-XSS-Protection: enable XSS filter
    res.setHeader('X-XSS-Protection', '1; mode=block');
    
    // Strict-Transport-Security (already handled by helmet if enabled)
    if (process.env.NODE_ENV === 'production') {
      res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains; preload');
    }
    
    // Referrer-Policy
    res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
    
    // Permissions-Policy (formerly Feature-Policy)
    res.setHeader('Permissions-Policy', 
      'camera=(), microphone=(), geolocation=(), payment=()'
    );
    
    // X-Permitted-Cross-Domain-Policies
    res.setHeader('X-Permitted-Cross-Domain-Policies', 'none');
    
    // X-Download-Options (IE specific)
    res.setHeader('X-Download-Options', 'noopen');
    
    // Cache-Control for API responses
    if (req.path.startsWith('/api/')) {
      res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
      res.setHeader('Pragma', 'no-cache');
      res.setHeader('Expires', '0');
    }
    
    next();
  }
];

/**
 * Request ID middleware for tracing
 */
const requestIdMiddleware = (req, res, next) => {
  const requestId = req.headers['x-request-id'] || 
                   `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  
  req.id = requestId;
  res.setHeader('X-Request-ID', requestId);
  next();
};

/**
 * Security middleware for production environment only
 */
const productionSecurityMiddleware = [
  // Force HTTPS in production
  (req, res, next) => {
    if (process.env.NODE_ENV === 'production' && req.headers['x-forwarded-proto'] !== 'https') {
      return res.redirect(301, `https://${req.headers.host}${req.url}`);
    }
    next();
  },
  
  // Rate limiting headers
  (req, res, next) => {
    res.setHeader('X-RateLimit-Policy', '100;w=900;comment="Standard API rate limit"');
    next();
  }
];

module.exports = {
  corsOptions,
  helmetOptions,
  securityMiddleware,
  productionSecurityMiddleware,
  requestIdMiddleware,
  developmentSecurityConfig
};