# ContractorLens Development Guide

## 🚀 **Getting Started**

Welcome to ContractorLens development! This guide will help you set up your development environment and start contributing to our AR-powered construction estimation platform.

---

## 🛠️ **Prerequisites**

### **System Requirements**
- **macOS**: 13.0+ (for iOS development)
- **Xcode**: 15.0+ with iOS 17.0+ SDK
- **Node.js**: 18.0+ with npm 9.0+
- **Docker**: 24.0+ with Docker Compose
- **PostgreSQL**: 15.0+ (via Docker)
- **Git**: 2.30+

### **Hardware Requirements**
- **RAM**: 16GB minimum, 32GB recommended
- **Storage**: 50GB free space
- **Processor**: Intel/Apple Silicon with virtualization support

---

## 📦 **Local Development Setup**

### **1. Clone and Initialize**
```bash
# Clone the repository
git clone https://github.com/mirzaik-wcc/ContractorLens.git
cd ContractorLens

# Initialize submodules (if any)
git submodule update --init --recursive

# Copy environment template
cp .env.example .env
```

### **2. Environment Configuration**
```bash
# Edit .env with your credentials
nano .env

# Required environment variables
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://postgres:local_dev_pw@localhost:5432/contractorlens
GEMINI_API_KEY=your_gemini_api_key_here
FIREBASE_CONFIG='{"apiKey":"...","authDomain":"..."}'
JWT_SECRET=your_jwt_secret_here
REDIS_URL=redis://localhost:6379
```

### **3. Docker Infrastructure**
```bash
# Start all services
docker-compose up -d

# Or start individual services
docker-compose up postgres redis -d

# Verify services are running
docker-compose ps
```

### **4. Backend Setup**
```bash
cd backend

# Install dependencies
npm install

# Run database migrations
npm run migrate

# Seed development data
npm run seed

# Start development server
npm run dev
```

### **5. ML Service Setup**
```bash
cd ml-services/gemini-service

# Install dependencies
npm install

# Start service
npm start
```

### **6. iOS App Setup**
```bash
cd ios-app

# Install CocoaPods dependencies (if applicable)
pod install

# Open in Xcode
open ContractorLens.xcodeproj

# Or use Xcode command line
xcodebuild -project ContractorLens.xcodeproj -scheme ContractorLens -sdk iphonesimulator
```

---

## 🏗️ **Project Structure**

```
ContractorLens/
├── ios-app/                          # iOS SwiftUI application
│   ├── ContractorLens/
│   │   ├── Views/                   # SwiftUI views
│   │   │   ├── ScanningView.swift   # AR scanning interface
│   │   │   ├── EstimateResultsView.swift # Results display
│   │   │   └── SettingsView.swift   # App settings
│   │   ├── ViewModels/              # MVVM view models
│   │   │   ├── ScanningViewModel.swift
│   │   │   └── EstimateViewModel.swift
│   │   ├── Services/                # Business logic services
│   │   │   ├── APIService.swift     # Network layer
│   │   │   └── ScanProcessingService.swift
│   │   ├── AR/                     # RoomPlan integration
│   │   │   ├── RoomScanner.swift    # Core scanning logic
│   │   │   └── ARFrameCaptureService.swift # Enhanced capture
│   │   ├── Models/                 # Data structures
│   │   │   ├── Estimate.swift
│   │   │   └── ScanData.swift
│   │   └── Utils/                  # Utilities
│   └── ContractorLens.xcodeproj/   # Xcode project
├── backend/                         # Node.js API server
│   ├── src/
│   │   ├── server.js               # Express server setup
│   │   ├── config/                 # Configuration files
│   │   ├── middleware/             # Express middleware
│   │   ├── routes/                 # API route handlers
│   │   │   ├── estimates.js        # Estimate endpoints
│   │   │   ├── scans.js           # Scan management
│   │   │   └── materials.js       # Material data
│   │   ├── services/              # Business logic
│   │   │   ├── assemblyEngine.js  # Cost calculation engine
│   │   │   ├── geminiIntegration.js # AI service integration
│   │   │   └── locationService.js # Geographic pricing
│   │   └── utils/                 # Utility functions
│   ├── tests/                     # Test files
│   │   ├── unit/                  # Unit tests
│   │   ├── integration/           # Integration tests
│   │   └── fixtures/              # Test data
│   └── package.json
├── ml-services/                    # AI analysis services
│   └── gemini-service/
│       ├── analyzer.js            # Gemini analysis logic
│       ├── prompts/               # AI prompt templates
│       ├── preprocessing/         # Image preprocessing
│       └── tests/                 # Service tests
├── database/                       # Database schemas and seeds
│   ├── schemas/                   # SQL schema files
│   ├── migrations/                # Database migrations
│   ├── seeds/                     # Seed data
│   └── performance/               # Performance optimizations
├── docs/                          # Documentation
├── scripts/                       # Development scripts
└── docker-compose.yml             # Local development stack
```

---

## 🧪 **Testing Strategy**

### **Backend Testing**
```bash
cd backend

# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run specific test file
npm test -- tests/unit/assemblyEngine.test.js

# Run integration tests
npm run test:integration

# Watch mode for development
npm run test:watch
```

### **iOS Testing**
```bash
cd ios-app

# Run unit tests
xcodebuild test -project ContractorLens.xcodeproj -scheme ContractorLens -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run UI tests
xcodebuild test -project ContractorLens.xcodeproj -scheme ContractorLensUITests -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Test on physical device
xcodebuild test -project ContractorLens.xcodeproj -scheme ContractorLens -destination 'platform=iOS,name=iPhone'
```

### **ML Service Testing**
```bash
cd ml-services/gemini-service

# Run unit tests
npm test

# Run with coverage
npm run test:coverage

# Test with mock Gemini API
npm run test:mock
```

### **End-to-End Testing**
```bash
# Start test environment
docker-compose -f docker-compose.test.yml up -d

# Run E2E tests
npm run test:e2e

# Test with real iOS device
# (Requires physical device connected)
npm run test:e2e:ios
```

---

## 🔧 **Development Workflows**

### **Feature Development**
```bash
# Create feature branch
git checkout -b feature/enhanced-ar-capture

# Make changes...
# Add tests...
# Update documentation...

# Commit changes
git add .
git commit -m "feat: enhance AR frame capture with quality validation

- Add intelligent frame capture algorithm
- Implement quality metrics (sharpness, brightness, contrast)
- Add PNG lossless compression for Gemini analysis
- Include camera intrinsics and tracking state metadata

Closes #123"

# Push branch
git push origin feature/enhanced-ar-capture

# Create pull request
# (Use GitHub web interface or GitHub CLI)
gh pr create --title "Enhanced AR Frame Capture" --body "Implementation of intelligent frame capture with quality validation..."
```

### **Bug Fixes**
```bash
# Create bug fix branch
git checkout -b fix/scan-processing-crash

# Reproduce the issue...
# Fix the bug...
# Add regression test...

# Commit with conventional format
git commit -m "fix: prevent crash in scan processing service

- Add null check for ARFrame.capturedImage
- Handle camera permission denied gracefully
- Add error recovery for frame capture failures

Fixes #456"
```

### **Code Review Process**
```bash
# Fetch latest changes
git fetch origin

# Checkout PR branch
git checkout feature/enhanced-scanning

# Review code changes
git diff main..HEAD

# Run tests
npm test

# Build and verify
npm run build

# Add review comments
# (Use GitHub web interface or CLI)
gh pr review --approve --body "LGTM! Great implementation of the enhanced scanning feature."
```

---

## 📝 **Code Standards**

### **Swift (iOS)**
```swift
// Good: Clear naming, proper error handling
class ScanningService: ObservableObject {
    private let apiService: APIService
    private let frameCaptureService: ARFrameCaptureService

    func startNewScan(roomType: RoomType) async throws -> UUID {
        guard let device = AVCaptureDevice.default(for: .video) else {
            throw ScanningError.cameraUnavailable
        }

        let scanId = UUID()
        try await frameCaptureService.configure(for: scanId)
        return scanId
    }
}

// Bad: Unclear naming, poor error handling
class ScanSvc {
    func startScan(type: Int) -> String? {
        // No error handling
        return UUID().uuidString
    }
}
```

### **JavaScript/TypeScript (Backend)**
```javascript
// Good: Async/await, proper error handling, clear naming
class AssemblyEngine {
    async calculateCost(analysis, roomData, options = {}) {
        try {
            const materials = await this.validateMaterials(analysis.materials);
            const locationModifier = await this.getLocationModifier(options.location);
            const baseCosts = this.calculateBaseCosts(materials, roomData);

            return this.applyModifiers(baseCosts, locationModifier, options);
        } catch (error) {
            this.logger.error('Cost calculation failed', { error, analysis, roomData });
            throw new CalculationError('Failed to calculate construction costs', error);
        }
    }
}

// Bad: Callbacks, unclear naming, no error handling
function calcCost(analysis, room, opts, callback) {
    getMaterials((err, mats) => {
        if (err) return callback(err);
        // No validation, error handling, or clear structure
        callback(null, mats.reduce((sum, m) => sum + m.cost, 0));
    });
}
```

### **Commit Message Format**
```bash
# Format: type(scope): description

# Types:
# feat: New feature
# fix: Bug fix
# docs: Documentation
# style: Code style changes
# refactor: Code refactoring
# test: Testing
# chore: Maintenance

# Examples:
feat(ios): add enhanced AR frame capture
fix(backend): resolve memory leak in scan processing
docs(api): update estimate endpoint documentation
test(ml): add unit tests for Gemini integration
refactor(database): optimize query performance
```

---

## 🔍 **Debugging & Troubleshooting**

### **iOS Debugging**
```swift
// Add debug logging
class ScanningViewModel: ObservableObject {
    func startScanning() {
        #if DEBUG
        print("🔍 Starting scan with room type: \(roomType)")
        print("📱 Device: \(UIDevice.current.model)")
        print("📷 Camera available: \(AVCaptureDevice.default(for: .video) != nil)")
        #endif

        // Scanning logic...
    }
}

// Use breakpoints in Xcode
// 1. Click line number in gutter
// 2. Run with breakpoints enabled
// 3. Inspect variables in debug console
```

### **Backend Debugging**
```javascript
// Add debug logging with context
const logger = require('./logger');

class AssemblyEngine {
    async calculateCost(analysis, roomData) {
        logger.debug('Starting cost calculation', {
            roomType: roomData.roomType,
            materialCount: analysis.materials?.length,
            qualityTier: analysis.recommendedTier
        });

        try {
            // Calculation logic...
            logger.info('Cost calculation completed', {
                totalCost: result.totalCost,
                duration: Date.now() - startTime
            });
        } catch (error) {
            logger.error('Cost calculation failed', {
                error: error.message,
                stack: error.stack,
                input: { analysis, roomData }
            });
            throw error;
        }
    }
}
```

### **Network Debugging**
```bash
# Monitor API calls
curl -v http://localhost:3000/api/estimates \
  -H "Content-Type: application/json" \
  -d '{"scanId":"test-scan-id"}'

# Check service connectivity
docker-compose exec backend curl -f http://gemini:3001/health

# View network traffic
# Use Charles Proxy or mitmproxy for detailed inspection
```

### **Database Debugging**
```sql
-- Enable query logging
SET log_statement = 'all';
SET log_duration = 'on';

-- Analyze slow queries
EXPLAIN ANALYZE
SELECT * FROM estimates
WHERE created_at >= '2024-01-01'
ORDER BY total_cost DESC
LIMIT 10;

-- Check connection pool status
SELECT * FROM pg_stat_activity
WHERE datname = 'contractorlens';

-- Monitor table sizes
SELECT schemaname, tablename,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

---

## 🚀 **Performance Optimization**

### **iOS Performance**
```swift
// Optimize AR frame processing
class ARFrameCaptureService {
    private let processingQueue = DispatchQueue(
        label: "com.contractorlens.frameprocessing",
        qos: .userInitiated,
        attributes: .concurrent
    )

    func processFrame(_ frame: ARFrame) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.validateQuality(frame)
            }
            group.addTask {
                await self.extractMetadata(frame)
            }
            group.addTask {
                await self.compressImage(frame)
            }
        }
    }
}

// Memory management
class MemoryManager {
    private var frameBuffer: [EnhancedProcessedFrame] = []
    private let maxBufferSize = 20

    func addFrame(_ frame: EnhancedProcessedFrame) {
        frameBuffer.append(frame)

        // Automatic cleanup
        if frameBuffer.count > maxBufferSize {
            frameBuffer.removeFirst(frameBuffer.count - maxBufferSize)
        }
    }
}
```

### **Backend Performance**
```javascript
// Optimize database queries
class EstimateRepository {
    async getEstimatesWithDetails(userId, options = {}) {
        const { limit = 20, offset = 0 } = options;

        // Use single query with JOINs instead of multiple queries
        const query = `
            SELECT e.*,
                   json_agg(json_build_object(
                       'id', li.id,
                       'description', li.description,
                       'cost', li.total_cost
                   )) as line_items
            FROM estimates e
            LEFT JOIN line_items li ON e.id = li.estimate_id
            WHERE e.user_id = $1
            GROUP BY e.id
            ORDER BY e.created_at DESC
            LIMIT $2 OFFSET $3
        `;

        return await this.db.query(query, [userId, limit, offset]);
    }
}

// Implement caching
const cache = require('redis').createClient();

class CacheManager {
    async getEstimates(userId) {
        const cacheKey = `estimates:${userId}`;

        // Try cache first
        const cached = await cache.get(cacheKey);
        if (cached) {
            return JSON.parse(cached);
        }

        // Fetch from database
        const estimates = await this.repository.getEstimates(userId);

        // Cache for 5 minutes
        await cache.setex(cacheKey, 300, JSON.stringify(estimates));

        return estimates;
    }
}
```

### **Database Optimization**
```sql
-- Create indexes for performance
CREATE INDEX CONCURRENTLY idx_estimates_user_created
ON estimates (user_id, created_at DESC);

CREATE INDEX CONCURRENTLY idx_scans_status_created
ON scans (status, created_at DESC);

-- Optimize table structure
ALTER TABLE estimates
ADD COLUMN search_vector tsvector
GENERATED ALWAYS AS (
    to_tsvector('english',
        coalesce(room_type, '') || ' ' ||
        coalesce(description, '')
    ) STORED;

CREATE INDEX idx_estimates_search
ON estimates USING gin(search_vector);

-- Partition large tables
CREATE TABLE estimates_y2024 PARTITION OF estimates
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
```

---

## 🔒 **Security Best Practices**

### **API Security**
```javascript
// Input validation
const Joi = require('joi');

const estimateSchema = Joi.object({
    scanId: Joi.string().uuid().required(),
    qualityTier: Joi.string().valid('good', 'better', 'best').required(),
    location: Joi.string().min(5).max(100).required(),
    markup: Joi.number().min(0).max(0.5).default(0.15)
});

// Rate limiting
const rateLimit = require('express-rate-limit');

const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: 'Too many requests from this IP, please try again later.'
});

// Authentication middleware
const authenticate = (req, res, next) => {
    const token = req.header('Authorization')?.replace('Bearer ', '');

    if (!token) {
        return res.status(401).json({ error: 'Access denied. No token provided.' });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded;
        next();
    } catch (error) {
        res.status(400).json({ error: 'Invalid token.' });
    }
};
```

### **iOS Security**
```swift
// Secure data storage
class SecureStorage {
    private let keychain = Keychain(service: "com.contractorlens.app")

    func storeToken(_ token: String) throws {
        try keychain.set(token, key: "authToken")
    }

    func getToken() throws -> String? {
        try keychain.get("authToken")
    }

    func clearToken() throws {
        try keychain.remove("authToken")
    }
}

// Certificate pinning
class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession,
                   didReceive challenge: URLAuthenticationChallenge,
                   completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Validate certificate against known public key
        if validateCertificate(serverTrust) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
```

---

## 📊 **Monitoring & Logging**

### **Application Logging**
```javascript
// Structured logging
const winston = require('winston');

const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    defaultMeta: { service: 'contractor-lens-backend' },
    transports: [
        new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
        new winston.transports.File({ filename: 'logs/combined.log' }),
        new winston.transports.Console({
            format: winston.format.combine(
                winston.format.colorize(),
                winston.format.simple()
            )
        })
    ]
});

// Usage
logger.info('Estimate calculation completed', {
    estimateId: '123',
    totalCost: 15420.50,
    duration: 1250,
    userId: 'user_456'
});

logger.error('Database connection failed', {
    error: error.message,
    stack: error.stack,
    connectionString: sanitizedConnectionString
});
```

### **Performance Monitoring**
```javascript
// Response time monitoring
const responseTime = require('response-time');

app.use(responseTime((req, res, time) => {
    logger.info('Request completed', {
        method: req.method,
        url: req.url,
        status: res.statusCode,
        responseTime: time,
        userAgent: req.get('User-Agent'),
        ip: req.ip
    });
}));

// Memory usage monitoring
setInterval(() => {
    const memUsage = process.memoryUsage();
    logger.info('Memory usage', {
        rss: Math.round(memUsage.rss / 1024 / 1024),
        heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024),
        heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024),
        external: Math.round(memUsage.external / 1024 / 1024)
    });
}, 30000);
```

### **Error Tracking**
```javascript
// Global error handler
process.on('uncaughtException', (error) => {
    logger.error('Uncaught Exception', {
        error: error.message,
        stack: error.stack,
        timestamp: new Date().toISOString()
    });

    // Perform cleanup
    // ...

    process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
    logger.error('Unhandled Rejection', {
        reason: reason,
        promise: promise,
        timestamp: new Date().toISOString()
    });
});
```

---

## 🤝 **Contributing Guidelines**

### **Pull Request Process**
1. **Fork** the repository
2. **Create** a feature branch from `main`
3. **Make** your changes with tests
4. **Test** thoroughly (unit, integration, e2e)
5. **Update** documentation if needed
6. **Commit** with conventional format
7. **Push** your branch
8. **Create** a pull request with:
   - Clear title and description
   - Reference to related issues
   - Screenshots for UI changes
   - Test results

### **Code Review Checklist**
- [ ] **Functionality**: Does the code work as expected?
- [ ] **Tests**: Are there adequate tests covering the changes?
- [ ] **Documentation**: Is documentation updated?
- [ ] **Performance**: Does the code perform well?
- [ ] **Security**: Are there any security concerns?
- [ ] **Style**: Does the code follow project conventions?
- [ ] **Dependencies**: Are new dependencies necessary and appropriate?

### **Issue Reporting**
```markdown
## Bug Report

**Description:**
Brief description of the issue

**Steps to Reproduce:**
1. Step 1
2. Step 2
3. Step 3

**Expected Behavior:**
What should happen

**Actual Behavior:**
What actually happens

**Environment:**
- OS: [e.g., macOS 13.0]
- Browser/Device: [e.g., iPhone 15 Pro]
- Version: [e.g., v1.2.3]

**Additional Context:**
Any other relevant information, logs, screenshots
```

---

## 📚 **Additional Resources**

### **Learning Resources**
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Google Gemini AI Documentation](https://ai.google.dev/docs)

### **Development Tools**
- [Xcode](https://developer.apple.com/xcode/) - iOS development
- [Visual Studio Code](https://code.visualstudio.com/) - Backend development
- [Postman](https://www.postman.com/) - API testing
- [Docker Desktop](https://www.docker.com/products/docker-desktop) - Container development
- [pgAdmin](https://www.pgadmin.org/) - Database management

### **Community & Support**
- [GitHub Issues](https://github.com/mirzaik-wcc/ContractorLens/issues) - Bug reports and feature requests
- [GitHub Discussions](https://github.com/mirzaik-wcc/ContractorLens/discussions) - General discussion
- [Slack Community](https://contractorlens.slack.com) - Real-time chat (invite required)

---

**Happy coding! 🎉 If you have questions, don't hesitate to ask in our [GitHub Discussions](https://github.com/mirzaik-wcc/ContractorLens/discussions) or reach out to the development team.**