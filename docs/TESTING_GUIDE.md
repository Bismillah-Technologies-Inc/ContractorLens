# ContractorLens Testing Guide

## 🧪 **Overview**

Comprehensive testing strategy for ContractorLens, covering unit tests, integration tests, end-to-end tests, and performance testing across all components of the AR-powered construction estimation platform.

---

## 📊 **Testing Strategy**

### **Test Pyramid**
```
End-to-End Tests (10%)
    ↗ Integration Tests (20%)
        ↗ Unit Tests (70%)
```

### **Testing Types**
- **Unit Tests**: Individual functions, classes, and modules
- **Integration Tests**: Component interactions and API endpoints
- **End-to-End Tests**: Complete user workflows
- **Performance Tests**: Load testing and benchmarking
- **Security Tests**: Vulnerability assessment and penetration testing

---

## 🧩 **Unit Testing**

### **Backend Unit Tests**

#### **Jest Configuration**
```javascript
// backend/jest.config.js
module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/__tests__/**/*.test.js', '**/?(*.)+(spec|test).js'],
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/server.js',
    '!src/**/*.test.js'
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  },
  setupFilesAfterEnv: ['<rootDir>/tests/setup.js'],
  testTimeout: 10000
};
```

#### **Assembly Engine Tests**
```javascript
// backend/tests/unit/assemblyEngine.test.js
const { AssemblyEngine } = require('../../src/services/assemblyEngine');

describe('AssemblyEngine', () => {
  let engine;
  let mockDb;
  let mockLocationService;

  beforeEach(() => {
    mockDb = {
      getAssembly: jest.fn(),
      getLocationModifier: jest.fn()
    };
    mockLocationService = {
      getModifier: jest.fn()
    };
    engine = new AssemblyEngine(mockDb, mockLocationService);
  });

  describe('calculateCost', () => {
    it('should calculate cost for hardwood flooring', async () => {
      // Arrange
      const analysis = {
        materials: [{
          surface: 'floor',
          material: 'hardwood',
          condition: 'good',
          confidence: 0.9
        }],
        complexity: {
          accessibility: 'standard',
          obstacles: [],
          specialConditions: []
        }
      };

      const roomData = {
        dimensions: { length: 12, width: 10, height: 8 },
        area: 120
      };

      mockDb.getAssembly.mockResolvedValue({
        materialCost: 8.50,
        laborRate: 45.00,
        productionRate: 8.0
      });

      mockLocationService.getModifier.mockResolvedValue({
        laborModifier: 1.15,
        materialModifier: 1.10
      });

      // Act
      const result = await engine.calculateCost(analysis, roomData, {
        qualityTier: 'better',
        location: 'New York, NY'
      });

      // Assert
      expect(result.totalCost).toBeGreaterThan(0);
      expect(result.lineItems).toHaveLength(1);
      expect(mockDb.getAssembly).toHaveBeenCalledWith('hardwood', 'better');
    });

    it('should handle complex room configurations', async () => {
      // Test with vaulted ceilings, difficult access, etc.
    });

    it('should apply location modifiers correctly', async () => {
      // Test location-based pricing adjustments
    });

    it('should validate input parameters', async () => {
      // Test error handling for invalid inputs
    });
  });
});
```

#### **API Route Tests**
```javascript
// backend/tests/unit/routes/estimates.test.js
const request = require('supertest');
const express = require('express');
const estimatesRouter = require('../../../src/routes/estimates');

describe('Estimates API', () => {
  let app;
  let mockAssemblyEngine;

  beforeEach(() => {
    app = express();
    app.use(express.json());

    mockAssemblyEngine = {
      calculateCost: jest.fn()
    };

    // Mock middleware
    app.use((req, res, next) => {
      req.user = { id: 'test-user-id' };
      next();
    });

    app.use('/api/estimates', estimatesRouter(mockAssemblyEngine));
  });

  describe('POST /api/estimates', () => {
    it('should create estimate successfully', async () => {
      // Arrange
      const estimateRequest = {
        scanId: '550e8400-e29b-41d4-a716-446655440000',
        qualityTier: 'better',
        location: 'New York, NY'
      };

      mockAssemblyEngine.calculateCost.mockResolvedValue({
        totalCost: 15420.50,
        lineItems: [],
        breakdown: { materials: 8920, labor: 4850, equipment: 1250 }
      });

      // Act
      const response = await request(app)
        .post('/api/estimates')
        .send(estimateRequest);

      // Assert
      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.estimate.totalCost).toBe(15420.50);
    });

    it('should validate required parameters', async () => {
      const response = await request(app)
        .post('/api/estimates')
        .send({});

      expect(response.status).toBe(400);
      expect(response.body.error).toContain('scanId is required');
    });

    it('should handle service errors gracefully', async () => {
      mockAssemblyEngine.calculateCost.mockRejectedValue(
        new Error('Calculation failed')
      );

      const response = await request(app)
        .post('/api/estimates')
        .send({ scanId: 'test-id', qualityTier: 'better' });

      expect(response.status).toBe(500);
      expect(response.body.error).toContain('Internal server error');
    });
  });
});
```

### **iOS Unit Tests**

#### **XCTest Configuration**
```swift
// ios-app/ContractorLensTests/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>BNDL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
```

#### **ViewModel Tests**
```swift
// ios-app/ContractorLensTests/ViewModels/ScanningViewModelTests.swift
import XCTest
@testable import ContractorLens

class ScanningViewModelTests: XCTestCase {
    var viewModel: ScanningViewModel!
    var mockAPIService: MockAPIService!
    var mockScanProcessingService: MockScanProcessingService!

    override func setUp() {
        super.setUp()
        mockAPIService = MockAPIService()
        mockScanProcessingService = MockScanProcessingService()
        viewModel = ScanningViewModel(
            apiService: mockAPIService,
            scanProcessingService: mockScanProcessingService
        )
    }

    override func tearDown() {
        viewModel = nil
        mockAPIService = nil
        mockScanProcessingService = nil
        super.tearDown()
    }

    func testStartScanningSuccess() async throws {
        // Arrange
        let expectedScanId = UUID()
        mockScanProcessingService.startScanResult = .success(expectedScanId)

        // Act
        await viewModel.startScanning(roomType: .kitchen)

        // Assert
        XCTAssertEqual(viewModel.scanId, expectedScanId)
        XCTAssertEqual(viewModel.scanningState, .scanning)
        XCTAssertNil(viewModel.error)
    }

    func testStartScanningFailure() async throws {
        // Arrange
        let expectedError = ScanningError.cameraUnavailable
        mockScanProcessingService.startScanResult = .failure(expectedError)

        // Act
        await viewModel.startScanning(roomType: .kitchen)

        // Assert
        XCTAssertNil(viewModel.scanId)
        XCTAssertEqual(viewModel.scanningState, .idle)
        XCTAssertEqual(viewModel.error as? ScanningError, expectedError)
    }

    func testProcessFrameHighQuality() async throws {
        // Arrange
        let mockFrame = MockARFrame()
        mockFrame.qualityScore = 0.85
        mockScanProcessingService.shouldCaptureFrame = true

        // Act
        await viewModel.processFrame(mockFrame)

        // Assert
        XCTAssertEqual(mockScanProcessingService.capturedFrames.count, 1)
        XCTAssertEqual(viewModel.capturedFramesCount, 1)
    }

    func testProcessFrameLowQuality() async throws {
        // Arrange
        let mockFrame = MockARFrame()
        mockFrame.qualityScore = 0.3
        mockScanProcessingService.shouldCaptureFrame = false

        // Act
        await viewModel.processFrame(mockFrame)

        // Assert
        XCTAssertEqual(mockScanProcessingService.capturedFrames.count, 0)
        XCTAssertEqual(viewModel.capturedFramesCount, 0)
    }
}
```

#### **Service Tests**
```swift
// ios-app/ContractorLensTests/Services/APIServiceTests.swift
import XCTest
@testable import ContractorLens

class APIServiceTests: XCTestCase {
    var apiService: APIService!
    var mockURLSession: MockURLSession!

    override func setUp() {
        super.setUp()
        mockURLSession = MockURLSession()
        apiService = APIService(session: mockURLSession)
    }

    override func tearDown() {
        apiService = nil
        mockURLSession = nil
        super.tearDown()
    }

    func testSubmitEstimateSuccess() async throws {
        // Arrange
        let estimateRequest = EstimateRequest(
            scanId: UUID(),
            qualityTier: .better,
            location: "New York, NY"
        )

        let expectedResponse = EstimateResponse(
            estimateId: UUID(),
            totalCost: 15420.50,
            lineItems: [],
            createdAt: Date()
        )

        mockURLSession.data = try JSONEncoder().encode(expectedResponse)
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "https://api.contractorlens.com/estimates")!,
            statusCode: 201,
            httpVersion: nil,
            headerFields: nil
        )

        // Act
        let response = try await apiService.submitEstimate(estimateRequest)

        // Assert
        XCTAssertEqual(response.totalCost, expectedResponse.totalCost)
        XCTAssertEqual(response.estimateId, expectedResponse.estimateId)
    }

    func testSubmitEstimateNetworkError() async throws {
        // Arrange
        let estimateRequest = EstimateRequest(
            scanId: UUID(),
            qualityTier: .better,
            location: "New York, NY"
        )

        mockURLSession.error = URLError(.notConnectedToInternet)

        // Act & Assert
        do {
            _ = try await apiService.submitEstimate(estimateRequest)
            XCTFail("Expected network error")
        } catch let error as APIError {
            XCTAssertEqual(error, .networkError)
        }
    }

    func testSubmitEstimateServerError() async throws {
        // Arrange
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "https://api.contractorlens.com/estimates")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )

        // Act & Assert
        do {
            _ = try await apiService.submitEstimate(EstimateRequest(
                scanId: UUID(),
                qualityTier: .better,
                location: "New York, NY"
            ))
            XCTFail("Expected server error")
        } catch let error as APIError {
            XCTAssertEqual(error, .serverError(500))
        }
    }
}
```

### **ML Service Unit Tests**
```javascript
// ml-services/gemini-service/tests/analyzer.test.js
const { GeminiAnalyzer } = require('../analyzer');

describe('GeminiAnalyzer', () => {
  let analyzer;
  let mockGeminiClient;

  beforeEach(() => {
    mockGeminiClient = {
      analyze: jest.fn()
    };
    analyzer = new GeminiAnalyzer(mockGeminiClient);
  });

  describe('analyzeMaterials', () => {
    it('should analyze materials successfully', async () => {
      // Arrange
      const enhancedFrames = [
        {
          imageData: Buffer.from('fake-image-data'),
          metadata: {
            cameraTransform: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
            trackingState: 'normal',
            qualityMetrics: { sharpness: 0.8, brightness: 0.7 }
          }
        }
      ];

      const roomContext = {
        roomType: 'kitchen',
        dimensions: { length: 12, width: 10, height: 8 }
      };

      const mockGeminiResponse = {
        materials: [
          {
            surface: 'floor',
            material: 'hardwood',
            condition: 'good',
            confidence: 0.9
          }
        ]
      };

      mockGeminiClient.analyze.mockResolvedValue(mockGeminiResponse);

      // Act
      const result = await analyzer.analyzeMaterials(enhancedFrames, roomContext);

      // Assert
      expect(result.materials).toHaveLength(1);
      expect(result.materials[0].material).toBe('hardwood');
      expect(mockGeminiClient.analyze).toHaveBeenCalledWith(
        enhancedFrames,
        expect.objectContaining({
          roomType: 'kitchen',
          prompt: expect.stringContaining('construction estimator')
        })
      );
    });

    it('should handle Gemini API errors', async () => {
      mockGeminiClient.analyze.mockRejectedValue(
        new Error('Gemini API rate limit exceeded')
      );

      await expect(
        analyzer.analyzeMaterials([], {})
      ).rejects.toThrow('Gemini API rate limit exceeded');
    });

    it('should validate frame quality', async () => {
      const lowQualityFrames = [
        {
          imageData: Buffer.from('fake-image-data'),
          metadata: {
            qualityMetrics: { sharpness: 0.2, brightness: 0.3 }
          }
        }
      ];

      await expect(
        analyzer.analyzeMaterials(lowQualityFrames, {})
      ).rejects.toThrow('Frame quality too low');
    });
  });
});
```

---

## 🔗 **Integration Testing**

### **Backend Integration Tests**
```javascript
// backend/tests/integration/estimates.integration.test.js
const { createTestApp } = require('../helpers/testApp');
const { createTestDatabase } = require('../helpers/testDatabase');

describe('Estimates API Integration', () => {
  let app;
  let db;
  let testUser;

  beforeAll(async () => {
    db = await createTestDatabase();
    app = createTestApp(db);

    // Create test user
    testUser = await db.users.create({
      email: 'test@example.com',
      password: 'password123'
    });
  });

  afterAll(async () => {
    await db.close();
  });

  beforeEach(async () => {
    // Clean up test data
    await db.estimates.deleteMany({});
    await db.scans.deleteMany({});
  });

  describe('POST /api/estimates', () => {
    it('should create complete estimate from scan', async () => {
      // Arrange
      const scan = await db.scans.create({
        userId: testUser.id,
        roomType: 'kitchen',
        dimensions: { length: 12, width: 10, height: 8 },
        status: 'completed'
      });

      const estimateRequest = {
        scanId: scan.id,
        qualityTier: 'better',
        location: 'New York, NY'
      };

      // Act
      const response = await request(app)
        .post('/api/estimates')
        .set('Authorization', `Bearer ${testUser.token}`)
        .send(estimateRequest);

      // Assert
      expect(response.status).toBe(201);
      expect(response.body.estimate).toMatchObject({
        totalCost: expect.any(Number),
        lineItems: expect.any(Array),
        qualityTier: 'better'
      });

      // Verify database state
      const savedEstimate = await db.estimates.findById(response.body.estimate.id);
      expect(savedEstimate).toBeTruthy();
      expect(savedEstimate.totalCost).toBe(response.body.estimate.totalCost);
    });

    it('should handle concurrent estimate requests', async () => {
      // Test race conditions and database locking
    });

    it('should integrate with Gemini service', async () => {
      // Test end-to-end with mock Gemini service
    });
  });

  describe('Database Integration', () => {
    it('should handle database connection failures', async () => {
      // Test database resilience
    });

    it('should rollback transactions on errors', async () => {
      // Test transaction integrity
    });
  });
});
```

### **Database Integration Tests**
```javascript
// backend/tests/integration/database.integration.test.js
const { createTestDatabase } = require('../helpers/testDatabase');

describe('Database Integration', () => {
  let db;

  beforeAll(async () => {
    db = await createTestDatabase();
  });

  afterAll(async () => {
    await db.close();
  });

  describe('Estimates Table', () => {
    it('should create and retrieve estimates', async () => {
      // Arrange
      const estimateData = {
        userId: 'test-user-id',
        scanId: 'test-scan-id',
        totalCost: 15420.50,
        roomType: 'kitchen',
        qualityTier: 'better'
      };

      // Act
      const created = await db.estimates.create(estimateData);
      const retrieved = await db.estimates.findById(created.id);

      // Assert
      expect(retrieved.id).toBe(created.id);
      expect(retrieved.totalCost).toBe(15420.50);
      expect(retrieved.roomType).toBe('kitchen');
    });

    it('should handle complex queries', async () => {
      // Test filtering, sorting, pagination
      await db.estimates.createMany([
        { userId: 'user1', totalCost: 10000, createdAt: new Date('2024-01-01') },
        { userId: 'user1', totalCost: 20000, createdAt: new Date('2024-01-02') },
        { userId: 'user2', totalCost: 15000, createdAt: new Date('2024-01-01') }
      ]);

      const results = await db.estimates.find({
        userId: 'user1',
        totalCost: { $gte: 15000 }
      }).sort({ createdAt: -1 });

      expect(results).toHaveLength(1);
      expect(results[0].totalCost).toBe(20000);
    });

    it('should enforce foreign key constraints', async () => {
      await expect(
        db.estimates.create({
          userId: 'non-existent-user',
          scanId: 'test-scan-id',
          totalCost: 1000
        })
      ).rejects.toThrow('foreign key constraint');
    });
  });

  describe('Performance', () => {
    it('should handle bulk operations efficiently', async () => {
      const startTime = Date.now();

      // Create 1000 estimates
      const estimates = Array.from({ length: 1000 }, (_, i) => ({
        userId: `user${i % 10}`,
        scanId: `scan${i}`,
        totalCost: Math.random() * 50000,
        roomType: ['kitchen', 'bathroom', 'living_room'][i % 3]
      }));

      await db.estimates.createMany(estimates);

      const endTime = Date.now();
      const duration = endTime - startTime;

      // Should complete within reasonable time
      expect(duration).toBeLessThan(5000); // 5 seconds
    });
  });
});
```

### **API Integration Tests**
```javascript
// backend/tests/integration/api.integration.test.js
const { createTestApp } = require('../helpers/testApp');
const { createTestDatabase } = require('../helpers/testDatabase');

describe('API Integration Tests', () => {
  let app;
  let db;
  let authenticatedRequest;

  beforeAll(async () => {
    db = await createTestDatabase();
    app = createTestApp(db);

    // Create authenticated request helper
    authenticatedRequest = (token) => {
      const req = request(app);
      if (token) req.set('Authorization', `Bearer ${token}`);
      return req;
    };
  });

  describe('Authentication Flow', () => {
    it('should complete full authentication flow', async () => {
      // Register user
      const registerResponse = await authenticatedRequest()
        .post('/api/auth/register')
        .send({
          email: 'test@example.com',
          password: 'password123',
          company: 'Test Construction'
        });

      expect(registerResponse.status).toBe(201);
      expect(registerResponse.body.token).toBeDefined();

      // Login with registered user
      const loginResponse = await authenticatedRequest()
        .post('/api/auth/login')
        .send({
          email: 'test@example.com',
          password: 'password123'
        });

      expect(loginResponse.status).toBe(200);
      expect(loginResponse.body.token).toBeDefined();

      const token = loginResponse.body.token;

      // Access protected endpoint
      const profileResponse = await authenticatedRequest(token)
        .get('/api/auth/profile');

      expect(profileResponse.status).toBe(200);
      expect(profileResponse.body.user.email).toBe('test@example.com');
    });
  });

  describe('Scan to Estimate Flow', () => {
    let userToken;
    let scanId;

    beforeAll(async () => {
      // Create and authenticate user
      const user = await db.users.create({
        email: 'scan-test@example.com',
        password: 'password123'
      });
      userToken = user.token;
    });

    it('should complete scan to estimate workflow', async () => {
      // 1. Initialize scan
      const scanResponse = await authenticatedRequest(userToken)
        .post('/api/scans')
        .send({
          roomType: 'kitchen',
          deviceInfo: {
            model: 'iPhone 15 Pro',
            iosVersion: '17.0'
          }
        });

      expect(scanResponse.status).toBe(201);
      scanId = scanResponse.body.scanId;

      // 2. Upload frames (mock)
      const framesResponse = await authenticatedRequest(userToken)
        .post(`/api/scans/${scanId}/frames`)
        .send({
          frames: [
            {
              frameId: 'frame1',
              timestamp: new Date().toISOString(),
              imageData: 'base64-encoded-image-data',
              metadata: {
                qualityMetrics: { sharpness: 0.8, brightness: 0.7 }
              }
            }
          ]
        });

      expect(framesResponse.status).toBe(200);

      // 3. Trigger analysis
      const analysisResponse = await authenticatedRequest(userToken)
        .post(`/api/scans/${scanId}/analyze`);

      expect(analysisResponse.status).toBe(200);

      // 4. Wait for completion (in real scenario)
      // await waitForScanCompletion(scanId);

      // 5. Create estimate
      const estimateResponse = await authenticatedRequest(userToken)
        .post('/api/estimates')
        .send({
          scanId: scanId,
          qualityTier: 'better',
          location: 'New York, NY'
        });

      expect(estimateResponse.status).toBe(201);
      expect(estimateResponse.body.estimate.totalCost).toBeGreaterThan(0);
    });
  });
});
```

---

## 🌐 **End-to-End Testing**

### **E2E Test Setup**
```javascript
// backend/tests/e2e/setup.js
const { createTestApp } = require('../helpers/testApp');
const { createTestDatabase } = require('../helpers/testDatabase');
const puppeteer = require('puppeteer');

global.testApp = null;
global.testDb = null;
global.browser = null;

beforeAll(async () => {
  // Start test application
  testDb = await createTestDatabase();
  testApp = createTestApp(testDb);

  // Start browser for E2E tests
  browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
});

afterAll(async () => {
  if (browser) await browser.close();
  if (testDb) await testDb.close();
});
```

### **Complete User Workflow Test**
```javascript
// backend/tests/e2e/scan-to-estimate.e2e.test.js
describe('Scan to Estimate E2E', () => {
  let page;
  let testUser;

  beforeAll(async () => {
    page = await browser.newPage();

    // Create test user
    testUser = await testDb.users.create({
      email: 'e2e-test@example.com',
      password: 'password123'
    });
  });

  afterAll(async () => {
    if (page) await page.close();
  });

  it('should complete full scan to estimate workflow', async () => {
    // 1. Navigate to application
    await page.goto('http://localhost:3000');

    // 2. Login
    await page.type('#email', testUser.email);
    await page.type('#password', 'password123');
    await page.click('#login-button');

    // Wait for dashboard
    await page.waitForSelector('.dashboard');

    // 3. Start new scan
    await page.click('#new-scan-button');
    await page.select('#room-type', 'kitchen');
    await page.click('#start-scan-button');

    // 4. Simulate AR scanning (mock camera access)
    await page.evaluate(() => {
      // Mock AR session and frame capture
      window.mockARSession = {
        frames: [
          {
            imageData: 'mock-image-data',
            metadata: {
              qualityMetrics: { sharpness: 0.8, brightness: 0.7 }
            }
          }
        ]
      };
    });

    // Trigger frame capture
    await page.click('#capture-frames-button');

    // 5. Wait for analysis completion
    await page.waitForSelector('.analysis-complete', { timeout: 30000 });

    // 6. Review and adjust estimate
    await page.select('#quality-tier', 'better');
    await page.type('#location', 'New York, NY');
    await page.click('#calculate-estimate-button');

    // 7. Verify estimate results
    await page.waitForSelector('.estimate-results');
    const totalCost = await page.$eval('.total-cost', el => el.textContent);

    expect(parseFloat(totalCost.replace('$', ''))).toBeGreaterThan(0);

    // 8. Export estimate
    await page.click('#export-pdf-button');

    // Verify PDF download
    const downloadPath = await waitForDownload(page);
    expect(downloadPath).toContain('.pdf');
  });

  it('should handle error scenarios gracefully', async () => {
    // Test network errors, invalid inputs, etc.
  });

  it('should work on mobile viewport', async () => {
    // Test responsive design
    await page.setViewport({ width: 375, height: 667 }); // iPhone SE
    // Repeat workflow test
  });
});
```

### **Mobile E2E Tests**
```swift
// ios-app/ContractorLensUITests/ScanToEstimateUITests.swift
import XCTest

class ScanToEstimateUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testCompleteScanToEstimateFlow() {
        // 1. Login
        let emailField = app.textFields["email"]
        emailField.tap()
        emailField.typeText("test@example.com")

        let passwordField = app.secureTextFields["password"]
        passwordField.tap()
        passwordField.typeText("password123")

        app.buttons["Login"].tap()

        // Wait for dashboard
        XCTAssertTrue(app.staticTexts["Welcome"].waitForExistence(timeout: 5))

        // 2. Start new scan
        app.buttons["New Scan"].tap()

        let roomTypePicker = app.pickers["roomType"]
        roomTypePicker.pickerWheels.element.adjust(toPickerWheelValue: "Kitchen")

        app.buttons["Start Scanning"].tap()

        // 3. Simulate AR scanning
        // Note: In real tests, this would require camera mocking
        app.buttons["Mock Frame Capture"].tap()

        // 4. Wait for analysis
        XCTAssertTrue(app.staticTexts["Analysis Complete"].waitForExistence(timeout: 30))

        // 5. Configure estimate
        let qualityTierPicker = app.pickers["qualityTier"]
        qualityTierPicker.pickerWheels.element.adjust(toPickerWheelValue: "Better")

        let locationField = app.textFields["location"]
        locationField.tap()
        locationField.typeText("New York, NY")

        app.buttons["Calculate Estimate"].tap()

        // 6. Verify results
        XCTAssertTrue(app.staticTexts["Estimate Complete"].waitForExistence(timeout: 10))

        let totalCostLabel = app.staticTexts.matching(identifier: "totalCost").firstMatch
        XCTAssertTrue(totalCostLabel.exists)

        // Extract and validate cost
        let costText = totalCostLabel.label.replacingOccurrences(of: "$", with: "")
        let cost = Double(costText) ?? 0
        XCTAssertGreaterThan(cost, 0)

        // 7. Export functionality
        app.buttons["Export PDF"].tap()
        XCTAssertTrue(app.alerts["Export Success"].waitForExistence(timeout: 5))
    }

    func testErrorHandling() {
        // Test network errors, invalid inputs, etc.
        app.buttons["New Scan"].tap()

        // Simulate network error
        app.buttons["Trigger Network Error"].tap()

        XCTAssertTrue(app.alerts["Network Error"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.alerts["Network Error"].buttons["Retry"].exists)
    }

    func testAccessibility() {
        // Test VoiceOver and other accessibility features
        app.buttons["New Scan"].tap()

        // Verify accessibility labels
        XCTAssertTrue(app.buttons["Start Scanning"].isAccessibilityElement)
        XCTAssertEqual(app.buttons["Start Scanning"].accessibilityLabel, "Start room scanning")
    }
}
```

---

## ⚡ **Performance Testing**

### **Load Testing**
```javascript
// backend/tests/performance/load.test.js
const autocannon = require('autocannon');
const { createTestApp } = require('../helpers/testApp');

describe('Performance Tests', () => {
  let app;
  let server;

  beforeAll(async () => {
    app = createTestApp();
    server = app.listen(0);
  });

  afterAll(async () => {
    if (server) server.close();
  });

  it('should handle 100 concurrent estimate requests', async () => {
    const url = `http://localhost:${server.address().port}/api/estimates`;

    const result = await autocannon({
      url,
      connections: 100,
      duration: 10,
      headers: {
        'Authorization': 'Bearer test-token',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        scanId: 'test-scan-id',
        qualityTier: 'better',
        location: 'New York, NY'
      })
    });

    // Analyze results
    expect(result.requests.average).toBeGreaterThan(50); // 50 RPS
    expect(result.latency.p99).toBeLessThan(1000); // 99th percentile < 1s
    expect(result.non2xx).toBe(0); // No errors
  });

  it('should handle database load', async () => {
    // Test database performance under load
  });

  it('should handle memory usage', async () => {
    // Monitor memory consumption
  });
});
```

### **Memory Leak Testing**
```javascript
// backend/tests/performance/memory.test.js
const memwatch = require('memwatch-next');

describe('Memory Leak Tests', () => {
  let hd;

  beforeAll(() => {
    hd = new memwatch.HeapDiff();
  });

  it('should not leak memory during estimate calculations', async () => {
    // Perform multiple estimate calculations
    for (let i = 0; i < 1000; i++) {
      await calculateEstimate({
        scanId: `scan-${i}`,
        qualityTier: 'better',
        location: 'New York, NY'
      });
    }

    // Check for memory leaks
    const diff = hd.end();
    const growth = diff.change.size_bytes;

    expect(growth).toBeLessThan(10 * 1024 * 1024); // Less than 10MB growth
  });
});
```

### **Database Performance Testing**
```sql
-- performance/benchmarking_suite.sql

-- Test query performance
EXPLAIN ANALYZE
SELECT e.*, array_agg(li.description) as line_items
FROM estimates e
LEFT JOIN line_items li ON e.id = li.estimate_id
WHERE e.user_id = $1
  AND e.created_at >= $2
GROUP BY e.id
ORDER BY e.created_at DESC
LIMIT 20;

-- Test bulk insert performance
INSERT INTO estimates (user_id, scan_id, total_cost, room_type, quality_tier)
SELECT
  'user_' || generate_series(1, 1000),
  'scan_' || generate_series(1, 1000),
  random() * 50000,
  (ARRAY['kitchen', 'bathroom', 'living_room'])[floor(random() * 3 + 1)],
  (ARRAY['good', 'better', 'best'])[floor(random() * 3 + 1)];

-- Test concurrent access
-- (Run multiple instances of the above queries simultaneously)
```

---

## 🔒 **Security Testing**

### **API Security Tests**
```javascript
// backend/tests/security/api.security.test.js
const jwt = require('jsonwebtoken');

describe('API Security Tests', () => {
  it('should reject invalid JWT tokens', async () => {
    const response = await request(app)
      .get('/api/estimates')
      .set('Authorization', 'Bearer invalid-token');

    expect(response.status).toBe(401);
  });

  it('should reject expired JWT tokens', async () => {
    const expiredToken = jwt.sign(
      { userId: 'test-user', exp: Math.floor(Date.now() / 1000) - 3600 },
      process.env.JWT_SECRET
    );

    const response = await request(app)
      .get('/api/estimates')
      .set('Authorization', `Bearer ${expiredToken}`);

    expect(response.status).toBe(401);
  });

  it('should prevent SQL injection', async () => {
    const maliciousInput = "'; DROP TABLE estimates; --";

    const response = await request(app)
      .post('/api/estimates')
      .set('Authorization', `Bearer ${validToken}`)
      .send({
        scanId: maliciousInput,
        qualityTier: 'better'
      });

    expect(response.status).toBe(400);
    // Verify table still exists
    const tableExists = await db.query(`
      SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'estimates'
      )
    `);
    expect(tableExists.rows[0].exists).toBe(true);
  });

  it('should rate limit requests', async () => {
    // Make multiple rapid requests
    const requests = Array.from({ length: 150 }, () =>
      request(app)
        .get('/api/estimates')
        .set('Authorization', `Bearer ${validToken}`)
    );

    const responses = await Promise.all(requests);

    // Some requests should be rate limited
    const rateLimited = responses.filter(r => r.status === 429);
    expect(rateLimited.length).toBeGreaterThan(0);
  });
});
```

### **Input Validation Tests**
```javascript
// backend/tests/security/validation.test.js
const Joi = require('joi');

describe('Input Validation Tests', () => {
  const estimateSchema = Joi.object({
    scanId: Joi.string().uuid().required(),
    qualityTier: Joi.string().valid('good', 'better', 'best').required(),
    location: Joi.string().min(5).max(100).required(),
    markup: Joi.number().min(0).max(0.5).default(0.15)
  });

  it('should validate estimate request schema', () => {
    const validRequest = {
      scanId: '550e8400-e29b-41d4-a716-446655440000',
      qualityTier: 'better',
      location: 'New York, NY',
      markup: 0.15
    };

    const { error } = estimateSchema.validate(validRequest);
    expect(error).toBeUndefined();
  });

  it('should reject invalid quality tier', () => {
    const invalidRequest = {
      scanId: '550e8400-e29b-41d4-a716-446655440000',
      qualityTier: 'invalid',
      location: 'New York, NY'
    };

    const { error } = estimateSchema.validate(invalidRequest);
    expect(error).toBeDefined();
    expect(error.details[0].message).toContain('qualityTier');
  });

  it('should sanitize HTML input', () => {
    const maliciousInput = '<script>alert("xss")</script>New York, NY';

    const sanitized = sanitizeHtml(maliciousInput);
    expect(sanitized).not.toContain('<script>');
    expect(sanitized).toContain('New York, NY');
  });

  it('should validate file uploads', () => {
    // Test image upload validation
    const validImage = {
      mimetype: 'image/png',
      size: 1024 * 1024 // 1MB
    };

    const invalidImage = {
      mimetype: 'text/plain',
      size: 100 * 1024 * 1024 // 100MB
    };

    expect(validateImageUpload(validImage)).toBe(true);
    expect(validateImageUpload(invalidImage)).toBe(false);
  });
});
```

---

## 📊 **Test Reporting & CI/CD**

### **Test Results Aggregation**
```javascript
// scripts/test-report.js
const fs = require('fs');
const path = require('path');

function generateTestReport(results) {
  const report = {
    timestamp: new Date().toISOString(),
    summary: {
      total: results.numTotalTests,
      passed: results.numPassedTests,
      failed: results.numFailedTests,
      coverage: results.coverageMap ? calculateCoverage(results.coverageMap) : null
    },
    details: results.testResults.map(result => ({
      file: path.relative(process.cwd(), result.testFilePath),
      duration: result.duration,
      tests: result.testResults.map(test => ({
        name: test.fullName,
        status: test.status,
        duration: test.duration,
        error: test.failureMessages?.join('\n')
      }))
    }))
  };

  fs.writeFileSync(
    'test-results.json',
    JSON.stringify(report, null, 2)
  );

  return report;
}

function calculateCoverage(coverageMap) {
  const files = Object.values(coverageMap);
  const totals = files.reduce((acc, file) => ({
    statements: acc.statements + file.s,
    branches: acc.branches + file.b,
    functions: acc.functions + file.f,
    lines: acc.lines + file.l
  }), { statements: 0, branches: 0, functions: 0, lines: 0 });

  return {
    statements: totals.statements / files.length,
    branches: totals.branches / files.length,
    functions: totals.functions / files.length,
    lines: totals.lines / files.length
  };
}
```

### **CI/CD Pipeline**
```yaml
# .github/workflows/test.yml
name: Test Suite

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18, 20]

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run linting
        run: npm run lint

      - name: Run unit tests
        run: npm run test:unit

      - name: Run integration tests
        run: npm run test:integration

      - name: Generate coverage report
        run: npm run test:coverage

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/lcov.info

  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Start test environment
        run: docker-compose -f docker-compose.test.yml up -d

      - name: Run E2E tests
        run: npm run test:e2e

      - name: Stop test environment
        run: docker-compose -f docker-compose.test.yml down

  ios-test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '15.0'

      - name: Install dependencies
        run: cd ios-app && pod install

      - name: Run iOS tests
        run: cd ios-app && xcodebuild test -project ContractorLens.xcodeproj -scheme ContractorLens -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run security audit
        run: npm audit --audit-level high

      - name: Run SAST
        uses: github/super-linter/slim@v5
        env:
          DEFAULT_BRANCH: main
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run performance tests
        run: npm run test:performance

      - name: Upload performance results
        uses: actions/upload-artifact@v3
        with:
          name: performance-results
          path: performance-results.json
```

---

## 📈 **Test Metrics & Quality Gates**

### **Quality Gates**
```javascript
// scripts/quality-gates.js
const fs = require('fs');

function checkQualityGates() {
  const testResults = JSON.parse(fs.readFileSync('test-results.json'));
  const coverage = JSON.parse(fs.readFileSync('coverage/coverage-summary.json'));

  const gates = {
    unitTestCoverage: 80,
    integrationTestPassRate: 95,
    performanceRegression: 5, // Max 5% degradation
    securityVulnerabilities: 0
  };

  // Check unit test coverage
  if (coverage.total.lines.pct < gates.unitTestCoverage) {
    throw new Error(`Unit test coverage ${coverage.total.lines.pct}% is below required ${gates.unitTestCoverage}%`);
  }

  // Check integration test pass rate
  const integrationPassRate = (testResults.summary.passed / testResults.summary.total) * 100;
  if (integrationPassRate < gates.integrationTestPassRate) {
    throw new Error(`Integration test pass rate ${integrationPassRate}% is below required ${gates.integrationTestPassRate}%`);
  }

  console.log('✅ All quality gates passed');
}

checkQualityGates();
```

### **Test Analytics Dashboard**
```javascript
// scripts/test-analytics.js
const { MongoClient } = require('mongodb');

async function storeTestAnalytics(results) {
  const client = new MongoClient(process.env.TEST_ANALYTICS_DB_URL);

  try {
    await client.connect();
    const db = client.db('test-analytics');

    await db.collection('test-runs').insertOne({
      timestamp: new Date(),
      branch: process.env.GITHUB_REF,
      commit: process.env.GITHUB_SHA,
      results: {
        total: results.numTotalTests,
        passed: results.numPassedTests,
        failed: results.numFailedTests,
        duration: results.duration
      },
      coverage: results.coverageMap,
      performance: results.performanceMetrics
    });

  } finally {
    await client.close();
  }
}

// Generate trend analysis
async function analyzeTrends() {
  // Analyze test results over time
  // Identify flaky tests
  // Performance regression detection
  // Coverage trend analysis
}
```

---

**This comprehensive testing strategy ensures ContractorLens maintains high quality, performance, and reliability across all components of the AR-powered construction estimation platform.**