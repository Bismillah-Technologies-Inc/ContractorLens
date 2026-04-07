# ContractorLens API Reference

## 📋 **Overview**

The ContractorLens API provides comprehensive endpoints for AR-powered construction cost estimation. The API follows RESTful principles and supports JSON data interchange.

**Base URL:** `https://api.contractorlens.com/v1`  
**Authentication:** Bearer Token (JWT)  
**Rate Limit:** 100 requests per minute  

---

## 🔐 **Authentication**

### **POST /auth/login**
Authenticate user and receive JWT token.

**Request:**
```json
{
  "email": "contractor@example.com",
  "password": "secure_password"
}
```

**Response:**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 3600,
  "user": {
    "id": "uuid",
    "email": "contractor@example.com",
    "company": "ABC Construction",
    "license": "CA123456"
  }
}
```

### **POST /auth/refresh**
Refresh JWT token before expiration.

**Headers:**
```
Authorization: Bearer <current_token>
```

**Response:**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 3600
}
```

---

## 📊 **Scan Management**

### **POST /scans**
Initialize a new room scan session.

**Request:**
```json
{
  "roomType": "kitchen",
  "deviceInfo": {
    "model": "iPhone 16 Pro",
    "iosVersion": "18.5",
    "hasLidar": true
  },
  "location": {
    "latitude": 40.7128,
    "longitude": -74.0060,
    "address": "123 Main St, New York, NY"
  }
}
```

**Response:**
```json
{
  "success": true,
  "scanId": "550e8400-e29b-41d4-a716-446655440000",
  "sessionToken": "scan_session_abc123",
  "expiresAt": "2024-01-15T10:30:00Z",
  "configuration": {
    "maxFrames": 100,
    "qualityThreshold": 0.7,
    "captureInterval": 0.5
  }
}
```

### **POST /scans/{scanId}/frames**
Upload enhanced AR frame data for analysis.

**Request:**
```json
{
  "frames": [
    {
      "frameId": "frame_001",
      "timestamp": "2024-01-15T10:15:30.123Z",
      "imageData": "iVBORw0KGgoAAAANSUhEUgAA...",
      "mimeType": "image/png",
      "metadata": {
        "cameraTransform": [1.0, 0.0, 0.0, 0.0, ...],
        "trackingState": "normal",
        "lightingEstimate": 0.8,
        "cameraIntrinsics": [1.0, 0.0, 0.0, ...],
        "qualityMetrics": {
          "sharpness": 0.85,
          "brightness": 0.75,
          "contrast": 0.80,
          "motionBlur": 0.05,
          "overall": 0.82
        }
      }
    }
  ],
  "roomDimensions": {
    "length": 12.5,
    "width": 10.0,
    "height": 8.0,
    "area": 125.0
  }
}
```

**Response:**
```json
{
  "success": true,
  "framesAccepted": 1,
  "processingStatus": "queued",
  "estimatedProcessingTime": 30
}
```

### **GET /scans/{scanId}/status**
Check the processing status of a scan.

**Response:**
```json
{
  "scanId": "550e8400-e29b-41d4-a716-446655440000",
  "status": "processing",
  "progress": {
    "framesProcessed": 15,
    "totalFrames": 25,
    "currentStage": "gemini_analysis",
    "estimatedCompletion": "2024-01-15T10:16:00Z"
  },
  "results": null
}
```

### **GET /scans/{scanId}/results**
Retrieve completed scan analysis results.

**Response:**
```json
{
  "scanId": "550e8400-e29b-41d4-a716-446655440000",
  "status": "completed",
  "completedAt": "2024-01-15T10:15:45Z",
  "analysis": {
    "materials": [
      {
        "surface": "floor",
        "material": "solid_hardwood",
        "species": "oak",
        "condition": "good",
        "confidence": 0.92,
        "recommendedTier": "better",
        "notes": "3/4\" solid hardwood with minor wear"
      },
      {
        "surface": "walls",
        "material": "drywall",
        "condition": "excellent",
        "confidence": 0.98,
        "recommendedTier": "good",
        "notes": "Standard drywall with paint"
      }
    ],
    "complexity": {
      "accessibility": "standard",
      "obstacles": [],
      "specialConditions": ["vaulted_ceiling"]
    },
    "qualityTier": "better",
    "confidence": 0.89
  }
}
```

---

## 💰 **Estimate Generation**

### **POST /estimates**
Generate a construction cost estimate from scan analysis.

**Request:**
```json
{
  "scanId": "550e8400-e29b-41d4-a716-446655440000",
  "options": {
    "qualityTier": "better",
    "location": "New York, NY",
    "markup": 0.15,
    "taxRate": 0.0875,
    "includeContingency": true,
    "contingencyPercentage": 0.05
  }
}
```

**Response:**
```json
{
  "success": true,
  "estimateId": "550e8400-e29b-41d4-a716-446655440001",
  "createdAt": "2024-01-15T10:16:00Z",
  "totalCost": 15420.50,
  "breakdown": {
    "materials": 8920.00,
    "labor": 4850.00,
    "equipment": 1250.00,
    "overhead": 1400.25,
    "profit": 1000.25
  },
  "lineItems": [
    {
      "id": "line_001",
      "csiCode": "06 10 00",
      "description": "Rough Carpentry",
      "category": "structural",
      "quantity": 120.5,
      "unit": "SF",
      "unitCost": 8.50,
      "totalCost": 1024.25,
      "productionRate": 5.5,
      "laborHours": 21.9
    },
    {
      "id": "line_002",
      "csiCode": "09 30 00",
      "description": "Hardwood Flooring Installation",
      "category": "finishes",
      "quantity": 125.0,
      "unit": "SF",
      "unitCost": 12.75,
      "totalCost": 1593.75,
      "productionRate": 8.0,
      "laborHours": 15.6
    }
  ],
  "modifiers": {
    "location": {
      "city": "New York",
      "state": "NY",
      "laborModifier": 1.25,
      "materialModifier": 1.15
    },
    "complexity": {
      "multiplier": 1.0,
      "factors": []
    }
  },
  "qualityTier": "better",
  "markup": 0.15,
  "taxRate": 0.0875,
  "contingency": 771.03,
  "expiresAt": "2024-01-22T10:16:00Z"
}
```

### **GET /estimates/{estimateId}**
Retrieve detailed estimate information.

**Response:** Same as POST /estimates response above.

### **PUT /estimates/{estimateId}**
Update estimate parameters and recalculate costs.

**Request:**
```json
{
  "options": {
    "qualityTier": "best",
    "markup": 0.18,
    "includeContingency": false
  }
}
```

**Response:** Updated estimate object.

### **DELETE /estimates/{estimateId}**
Delete an estimate (soft delete).

**Response:**
```json
{
  "success": true,
  "message": "Estimate deleted successfully"
}
```

### **GET /estimates**
List user's estimates with pagination.

**Query Parameters:**
- `page=1` - Page number (default: 1)
- `limit=20` - Items per page (default: 20)
- `status=draft` - Filter by status
- `sortBy=createdAt` - Sort field
- `sortOrder=desc` - Sort order

**Response:**
```json
{
  "success": true,
  "estimates": [
    {
      "estimateId": "550e8400-e29b-41d4-a716-446655440001",
      "createdAt": "2024-01-15T10:16:00Z",
      "roomType": "kitchen",
      "totalCost": 15420.50,
      "status": "completed",
      "qualityTier": "better"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "totalPages": 3
  }
}
```

---

## 📋 **Materials & Assemblies**

### **GET /materials**
List available construction materials and assemblies.

**Query Parameters:**
- `category=flooring` - Filter by category
- `qualityTier=better` - Filter by quality tier
- `search=hardwood` - Search materials

**Response:**
```json
{
  "success": true,
  "materials": [
    {
      "id": "mat_001",
      "code": "FLR-HWD-OAK",
      "name": "Solid Hardwood Flooring - Oak",
      "category": "flooring",
      "description": "3/4\" solid oak hardwood flooring",
      "unit": "SF",
      "tiers": {
        "good": {
          "materialCost": 8.50,
          "laborRate": 45.00,
          "productionRate": 8.0,
          "equipmentRate": 5.00
        },
        "better": {
          "materialCost": 12.75,
          "laborRate": 50.00,
          "productionRate": 7.5,
          "equipmentRate": 6.00
        },
        "best": {
          "materialCost": 18.00,
          "laborRate": 55.00,
          "productionRate": 6.5,
          "equipmentRate": 7.00
        }
      },
      "specifications": {
        "thickness": "3/4\"",
        "width": "3-1/4\"",
        "length": "Random",
        "finish": "UV Cured",
        "warranty": "25 years"
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "totalPages": 8
  }
}
```

### **GET /materials/{materialId}**
Get detailed information about a specific material.

**Response:** Detailed material object with specifications and pricing.

### **GET /assemblies**
List construction assemblies (CSI codes).

**Response:**
```json
{
  "success": true,
  "assemblies": [
    {
      "id": "asm_001",
      "csiCode": "06 10 00",
      "name": "Rough Carpentry",
      "description": "Structural framing and rough carpentry work",
      "category": "structural",
      "productionRate": 5.5,
      "laborRate": 45.00,
      "equipmentRate": 5.00,
      "overheadRate": 0.15,
      "profitRate": 0.10
    }
  ]
}
```

---

## 📍 **Location Services**

### **GET /locations/modifiers**
Get location-based cost modifiers for pricing.

**Query Parameters:**
- `zipCode=10001` - ZIP code for location
- `city=New York&state=NY` - City and state

**Response:**
```json
{
  "success": true,
  "location": {
    "zipCode": "10001",
    "city": "New York",
    "state": "NY",
    "county": "New York",
    "region": "Northeast",
    "modifiers": {
      "laborModifier": 1.25,
      "materialModifier": 1.15,
      "overallModifier": 1.20
    },
    "lastUpdated": "2024-01-01T00:00:00Z"
  },
  "nearbyLocations": [
    {
      "zipCode": "10002",
      "city": "New York",
      "state": "NY",
      "distance": 2.5,
      "modifiers": {
        "laborModifier": 1.23,
        "materialModifier": 1.14,
        "overallModifier": 1.18
      }
    }
  ]
}
```

### **GET /locations/search**
Search for locations by address or coordinates.

**Query Parameters:**
- `query=New York, NY` - Address search
- `latitude=40.7128&longitude=-74.0060` - Coordinate search

---

## 📄 **Export & Reporting**

### **GET /estimates/{estimateId}/pdf**
Generate professional PDF estimate document.

**Query Parameters:**
- `template=professional` - PDF template (professional/simple)
- `includeBreakdown=true` - Include detailed line items
- `includeSpecs=true` - Include material specifications

**Response:** PDF file download.

### **GET /estimates/{estimateId}/csv**
Export estimate data as CSV.

**Response:** CSV file with line items and cost breakdown.

### **POST /estimates/{estimateId}/share**
Generate shareable estimate link.

**Request:**
```json
{
  "expiresIn": 604800,
  "password": "optional_password",
  "permissions": {
    "viewBreakdown": true,
    "downloadPdf": true,
    "editEstimate": false
  }
}
```

**Response:**
```json
{
  "success": true,
  "shareUrl": "https://estimate.contractorlens.com/s/abc123def",
  "expiresAt": "2024-01-22T10:16:00Z",
  "passwordProtected": false
}
```

---

## 🔧 **Webhooks**

### **POST /webhooks/scans**
Configure webhooks for scan completion notifications.

**Request:**
```json
{
  "url": "https://your-app.com/webhooks/scan-completed",
  "events": ["scan.completed", "scan.failed"],
  "secret": "your_webhook_secret"
}
```

### **Webhook Payload**
```json
{
  "event": "scan.completed",
  "timestamp": "2024-01-15T10:16:00Z",
  "data": {
    "scanId": "550e8400-e29b-41d4-a716-446655440000",
    "status": "completed",
    "results": {
      // Full scan results object
    }
  },
  "signature": "sha256=abc123..."
}
```

---

## 📊 **Analytics & Metrics**

### **GET /analytics/estimates**
Get estimate generation analytics.

**Query Parameters:**
- `startDate=2024-01-01` - Start date
- `endDate=2024-01-31` - End date
- `groupBy=day` - Grouping (day/week/month)

**Response:**
```json
{
  "success": true,
  "analytics": {
    "totalEstimates": 1250,
    "averageCost": 18500.50,
    "mostPopularRoomType": "kitchen",
    "conversionRate": 0.85,
    "timeSeries": [
      {
        "date": "2024-01-15",
        "estimates": 45,
        "totalValue": 825000.00,
        "averageCost": 18333.33
      }
    ]
  }
}
```

### **GET /analytics/materials**
Get material usage analytics.

**Response:**
```json
{
  "success": true,
  "analytics": {
    "mostUsedMaterials": [
      {
        "material": "solid_hardwood",
        "usageCount": 450,
        "totalValue": 1250000.00
      }
    ],
    "qualityTierDistribution": {
      "good": 0.35,
      "better": 0.50,
      "best": 0.15
    }
  }
}
```

---

## ⚠️ **Error Handling**

### **Standard Error Response**
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request parameters",
    "details": {
      "field": "qualityTier",
      "issue": "Must be one of: good, better, best"
    },
    "timestamp": "2024-01-15T10:16:00Z",
    "requestId": "req_abc123"
  }
}
```

### **Common Error Codes**
- `VALIDATION_ERROR` - Invalid request parameters
- `AUTHENTICATION_ERROR` - Invalid or missing authentication
- `AUTHORIZATION_ERROR` - Insufficient permissions
- `RESOURCE_NOT_FOUND` - Requested resource doesn't exist
- `RATE_LIMIT_EXCEEDED` - Too many requests
- `INTERNAL_ERROR` - Server error
- `SERVICE_UNAVAILABLE` - External service unavailable

---

## 📏 **Rate Limiting**

### **Rate Limit Headers**
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1642249200
X-RateLimit-Retry-After: 60
```

### **Rate Limit Response**
```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests",
    "details": {
      "limit": 100,
      "remaining": 0,
      "reset": 1642249200,
      "retryAfter": 60
    }
  }
}
```

---

## 🔒 **Security**

### **API Key Authentication**
```bash
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     https://api.contractorlens.com/v1/estimates
```

### **Request Signing**
For sensitive operations, requests must be signed:
```javascript
const signature = crypto
  .createHmac('sha256', secretKey)
  .update(requestBody)
  .digest('hex');

headers['X-Signature'] = signature;
```

### **Data Encryption**
- All data transmitted over HTTPS
- Sensitive scan data encrypted at rest
- End-to-end encryption for mobile app communication

---

## 📚 **SDKs & Libraries**

### **JavaScript SDK**
```javascript
import { ContractorLens } from 'contractor-lens-sdk';

const client = new ContractorLens({
  apiKey: 'your_api_key',
  baseUrl: 'https://api.contractorlens.com/v1'
});

// Create estimate
const estimate = await client.estimates.create({
  scanId: 'scan_123',
  qualityTier: 'better'
});

console.log(`Total cost: $${estimate.totalCost}`);
```

### **Swift SDK (iOS)**
```swift
import ContractorLensSDK

let client = ContractorLensClient(apiKey: "your_api_key")

// Upload scan data
let scan = try await client.scans.create(roomType: .kitchen)
let frame = EnhancedProcessedFrame(/* frame data */)

try await client.scans.uploadFrame(scanId: scan.id, frame: frame)

// Generate estimate
let estimate = try await client.estimates.create(
    scanId: scan.id,
    options: EstimateOptions(qualityTier: .better)
)
```

---

## 🎯 **Best Practices**

### **Efficient API Usage**
1. **Batch Operations**: Upload multiple frames in single request
2. **Caching**: Cache materials and location data
3. **Webhooks**: Use webhooks for async operations
4. **Pagination**: Use appropriate page sizes
5. **Error Handling**: Implement comprehensive error handling

### **Performance Optimization**
1. **Image Compression**: Compress frames before upload
2. **Selective Upload**: Only upload high-quality frames
3. **Background Processing**: Use webhooks for long operations
4. **Connection Reuse**: Reuse HTTP connections
5. **Rate Limiting**: Respect API rate limits

### **Security Best Practices**
1. **Token Management**: Rotate tokens regularly
2. **Request Signing**: Sign sensitive requests
3. **Data Validation**: Validate all input data
4. **Error Handling**: Don't expose sensitive information in errors
5. **HTTPS Only**: Always use HTTPS

---

**For additional support, visit our [Developer Portal](https://developers.contractorlens.com) or contact [support@contractorlens.com](mailto:support@contractorlens.com).**