# ContractorLens AI Assistant Instructions

## Project Overview

ContractorLens creates accurate construction estimates by combining:
1. RoomPlan API (iOS) for precise room measurements
2. Gemini Vision (ML) for material identification ONLY
3. Deterministic Assembly Engine for cost calculations

### Critical Components

#### 1. iOS App (`ios-app/ContractorLens/`)
- Uses RoomPlan for room scanning (`AR/RoomScanner.swift`)
- Implements MVVM pattern (`ViewModels/EstimateViewModel.swift`)
- SwiftUI views for UI (`Views/ScanningView.swift`, `Views/EstimateResultsView.swift`)
- Network layer in `Services/APIService.swift`

#### 2. Backend (`backend/`)
- Node.js Express API (`src/server.js`)
- Assembly Engine calculates costs (`src/services/assemblyEngine.js`)
- PostgreSQL for estimates/assemblies
- Docker containerized (`Dockerfile`, `docker-compose.yml`)

#### 3. ML Service (`ml-services/gemini-service/`)
- Node.js Gemini Vision integration (`analyzer.js`)
- Material analysis ONLY - no cost calculations
- Room condition assessment (`prompts/room_analysis.txt`)
- Docker containerized (`Dockerfile`)

### Core Principles

1. **Strict Service Boundaries**
   ```
   iOS App:        Measurement capture ONLY
   ML Service:     Material identification ONLY
   Backend:        ALL cost calculations
   ```

2. **Data Flow**
   ```javascript
   // Premium Flow
   ScanningView.swift → analyzer.js → assemblyEngine.js → EstimateResults.swift
                                     ↑
   // Basic Flow      Manual Takeoff → assemblyEngine.js
   ```

3. **Cost Calculation Logic** (`backend/src/services/assemblyEngine.js`)
   ```javascript
   function calculateCost(assembly, area) {
     // 1. Check retail prices (< 7 days old)
     if (hasValidRetailPrice(assembly)) {
       return calculateFromRetail(assembly, area);
     }
     
     // 2. Use national average × location modifier
     const basePrice = getNationalAverage(assembly);
     const modifier = getLocationModifier(assembly.location);
     
     // 3. Apply production rates
     const laborHours = area / assembly.productionRate;
     
     // 4. Add markup & tax
     return applyMarkupAndTax(basePrice * modifier * laborHours);
   }
   ```

## Integration Points & API Contracts

### 1. iOS → Backend Contract
```swift
// EstimateRequestPayload.swift
struct EstimateRequestPayload: Codable {
    let scanId: String
    let roomType: String
    let dimensions: RoomDimensions
    let surfaces: [Surface]
    let capturedImages: [CapturedImage]
}

// APIService.swift
func submitEstimate(_ payload: EstimateRequestPayload) async throws -> Estimate {
    let url = URL(string: "\(baseURL)/api/v1/estimates")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(payload)
    // ... error handling omitted
}
```

### 2. Backend → ML Service Contract
```javascript
// backend/src/services/geminiIntegration.js
async function analyzeMaterials(scanData) {
  const response = await fetch('http://ml-service:3001/analyze', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      scan_id: scanData.scanId,
      room_type: scanData.roomType,
      frames: scanData.capturedImages.map(img => ({
        timestamp: img.timestamp,
        imageData: img.base64Data
      }))
    })
  });
  return await response.json();
}
```

## Local Development Setup

### 1. Prerequisites
```bash
# Required versions
node -v  # v18.x or higher
npm -v   # v9.x or higher
python -v # v3.11 or higher
xcode-select --version  # Xcode 15 or higher
```

### 2. Environment Configuration
```bash
# 1. Clone and setup
git clone https://github.com/mirzaik-wcc/ContractorLens.git
cd ContractorLens
cp .env.example .env

# 2. Add required keys to .env
GEMINI_API_KEY=your_key_here
FIREBASE_CONFIG='{...}'
POSTGRES_PASSWORD=local_dev_pw
```

### 3. Start Services
```bash
# Start everything
docker-compose up -d

# Or start individual services
cd backend && npm run dev  # Backend on :3000
cd ml-services/gemini-service && npm start  # ML on :3001
# iOS app: Open ContractorLens.xcodeproj in Xcode
```

### 4. Verify Setup
```bash
# Health checks
curl http://localhost:3000/health  # Backend
curl http://localhost:3001/health  # ML Service

# Run test suites
cd backend && npm test
cd ml-services/gemini-service && npm test
```

## Data Structures & Schemas

### 1. Assembly Engine Input/Output
```typescript
// Input Format (POST /api/v1/estimates)
interface EstimateRequest {
  scan_id: string;
  room_type: "kitchen" | "bathroom" | "living_room" | "bedroom" | "dining_room";
  dimensions: {
    length: number;  // feet
    width: number;   // feet
    height: number;  // feet
  };
  surfaces: Array<{
    type: "floor" | "wall" | "ceiling";
    area: number;    // square feet
    material?: string;
    condition?: "excellent" | "good" | "fair" | "poor";
  }>;
}

// Output Format (Estimate Response)
interface EstimateResponse {
  estimate_id: string;
  created_at: string;  // ISO-8601
  total_cost: number;
  room_details: {
    type: string;
    dimensions: { length: number; width: number; height: number };
    square_footage: number;
  };
  line_items: Array<{
    assembly_id: string;
    description: string;
    quantity: number;
    unit: string;
    unit_cost: number;
    total_cost: number;
    breakdown: {
      materials: number;
      labor: number;
      equipment: number;
      overhead: number;
      profit: number;
    };
  }>;
}
```

### 2. Database Schema (Key Tables)
```sql
-- database/schemas/schema.sql

-- Core estimate data
CREATE TABLE estimates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    room_type VARCHAR(50) NOT NULL,
    total_cost DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    metadata JSONB
);

-- Predefined construction assemblies
CREATE TABLE assemblies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(20) UNIQUE NOT NULL,
    description TEXT NOT NULL,
    unit VARCHAR(10) NOT NULL,
    production_rate DECIMAL(10,6) NOT NULL,
    base_cost DECIMAL(10,2) NOT NULL,
    last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (production_rate > 0)
);

-- Location-specific cost modifiers
CREATE TABLE location_modifiers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    zip_code VARCHAR(10) NOT NULL UNIQUE,
    labor_modifier DECIMAL(4,3) NOT NULL,
    material_modifier DECIMAL(4,3) NOT NULL,
    last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (labor_modifier BETWEEN 0.5 AND 2.0),
    CHECK (material_modifier BETWEEN 0.5 AND 2.0)
);
```

### 3. Migration Patterns
```sql
-- database/migrations/V2__add_professional_estimate_tables.sql

-- 1. Add new tables with version prefix
CREATE TABLE v2_estimates ( ... );

-- 2. Migrate data if needed
INSERT INTO v2_estimates 
SELECT * FROM estimates;

-- 3. Rename tables
ALTER TABLE estimates RENAME TO estimates_old;
ALTER TABLE v2_estimates RENAME TO estimates;

-- 4. Cleanup after verifying
DROP TABLE estimates_old;
```

## Project-Specific Patterns

### 1. Assembly Engine Mathematics
```javascript
// backend/src/services/assemblyEngine.js

// Cost Calculation Flow
function calculateTotalCost(surfaces, laborModifier, materialModifier) {
  return surfaces.reduce((total, surface) => {
    const assembly = getAssemblyForSurface(surface);
    
    // 1. Calculate base costs
    const materialCost = assembly.materialCost * surface.area * materialModifier;
    const laborHours = surface.area / assembly.productionRate;
    const laborCost = assembly.laborRate * laborHours * laborModifier;
    
    // 2. Apply condition adjustments
    const conditionMultiplier = getConditionMultiplier(surface.condition);
    const adjustedLabor = laborCost * conditionMultiplier;
    
    // 3. Add overhead and profit
    const subtotal = materialCost + adjustedLabor;
    const overhead = subtotal * OVERHEAD_RATE;
    const profit = (subtotal + overhead) * PROFIT_RATE;
    
    return total + subtotal + overhead + profit;
  }, 0);
}

// Production Rate Calculations
const STANDARD_CONDITIONS = {
  room_height: 8,    // feet
  accessibility: 1,  // standard access
  complexity: 1      // basic rectangular room
};

function adjustProductionRate(baseRate, conditions) {
  let rate = baseRate;
  
  // Height adjustment (exponential penalty above 8ft)
  if (conditions.room_height > STANDARD_CONDITIONS.room_height) {
    rate *= Math.pow(0.9, conditions.room_height - STANDARD_CONDITIONS.room_height);
  }
  
  // Accessibility penalty
  rate *= Math.pow(0.8, conditions.accessibility - STANDARD_CONDITIONS.accessibility);
  
  // Complexity penalty
  rate *= Math.pow(0.85, conditions.complexity - STANDARD_CONDITIONS.complexity);
  
  return rate;
}
```

### 2. Material Analysis Prompts
```javascript
// ml-services/gemini-service/prompts/room_analysis.txt

You are a professional construction estimator analyzing room conditions.
Focus ONLY on:
1. Material identification
2. Current condition assessment
3. Installation complexity factors

DO NOT:
- Suggest costs or pricing
- Recommend specific products
- Make assumptions about labor requirements

Example Response:
{
  "surfaces": {
    "floor": {
      "material": "solid_hardwood",
      "species": "oak",
      "condition": "fair",
      "pattern": "straight_lay"
    },
    "walls": {
      "material": "drywall",
      "condition": "good",
      "texture": "orange_peel"
    }
  },
  "complexity_factors": {
    "accessibility": "standard",
    "obstacles_present": ["built_in_cabinets", "window_seats"],
    "special_conditions": ["vaulted_ceiling"]
  }
}
```

### 3. Database Operations
```sql
-- 1. Adding new assembly (database/seeds/assemblies.sql)
INSERT INTO assemblies (
    code, description, unit, production_rate, base_cost
) VALUES (
    'FLR-HWD-OAK', 
    'Hardwood Flooring - Oak 3/4" Solid',
    'SF',           -- Square Feet
    5.5,           -- Production rate: 5.5 SF per labor hour
    12.75          -- Base cost per SF (material only)
);

-- 2. Validate assembly (database/seeds/validate_assemblies.sql)
DO $$
BEGIN
    -- Check production rates are within expected ranges
    IF EXISTS (
        SELECT 1 FROM assemblies 
        WHERE production_rate < 0.1 OR production_rate > 100
    ) THEN
        RAISE EXCEPTION 'Invalid production rate detected';
    END IF;
    
    -- Verify all required related records exist
    IF EXISTS (
        SELECT a.id FROM assemblies a
        LEFT JOIN assembly_items ai ON a.id = ai.assembly_id
        WHERE ai.id IS NULL
    ) THEN
        RAISE EXCEPTION 'Assembly missing required items';
    END IF;
END $$;
```

## iOS App Architecture

### MVVM Pattern Implementation
- Views (`Views/`): SwiftUI views for UI presentation
- ViewModels (`ViewModels/`): ObservableObject classes for business logic
- Models (`Models/`): Codable structs for data structures
- AR (`AR/`): RoomPlan integration logic
- Services (`Services/`): Network and utility services

### Multi-Room Scanning Strategy
1. "Scan-and-Queue" Approach:
   - User scans Room A → Quick save to queue
   - Prompt for next room → Scan Room B → Queue
   - Once complete → Use StructureBuilder to stitch rooms
   - Send CapturedStructure to backend

2. Pre-Scan Requirements:
   - Turn on all lights
   - Open all interior doors
   - Make sure window corners are visible
   - Clean camera lens

3. Room Pattern Guidance:
   - Floor first → Up walls → Across ceiling
   - Move sideways systematically
   - Maintain consistent distance

## Important Files for Context
- `docs/ESTIMATE_GRANULARITY_ROADMAP.md` - Estimation system evolution
- `docs/COMPETITIVE_AND_TECHNICAL_ANALYSIS.md` - Technical decisions
- `backend/CLAUDE.md` - Backend architecture details
- `ml-services/CLAUDE.md` - ML service integration patterns
- `ios-app/ContractorLens/AR/RoomScanner.swift` - Core scanning logic
- `ios-app/ContractorLens/Views/ScanningView.swift` - Scanning UI