# ContractorLens — Full Product Specification

**Version:** 2.1 (Definitive Build Spec)
**Date:** April 5, 2026
**Status:** Ready for coding agents
**Changelog:** Replaced cabinet-specific detail sections (3.3-3.7) with system-wide Level 5 Estimation architecture — professional-grade estimate granularity, CSI MasterFormat integration, specialized calculation engines (Quantity, Labor, Catalog), relational data integrity, and AI-to-estimate pipeline

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Scan Flow (iOS App)](#2-scan-flow-ios-app)
3. [Estimate Flow](#3-estimate-flow)
   - 3.1 Calculation Pipeline
   - 3.2 Assembly Engine (Core Calculation)
   - 3.3 Professional-Grade Estimate Granularity (Level 5 Estimation)
   - 3.4 Material Quantity Calculation
   - 3.5 Cost Calculation
   - 3.6 Line Item Structure
   - 3.7 CSI Division Organization
4. [PDF Output](#4-pdf-output)
5. [Backend Architecture](#5-backend-architecture)
6. [Customer Portal](#6-customer-portal)
7. [Admin Portal](#7-admin-portal)
8. [Pricing Data Flow](#8-pricing-data-flow)
9. [Data Models (Complete Reference)](#9-data-models-complete-reference)
10. [API Contracts](#10-api-contracts)
11. [Stripe Integration](#11-stripe-integration)
12. [Open Questions](#12-open-questions)

---

## 1. Executive Summary

ContractorLens is a mobile-first estimating platform for residential contractors. A contractor scans a room with an iPhone/iPad (LiDAR + RoomPlan), the system identifies materials and conditions via AI (Gemini), calculates material quantities and labor hours using a deterministic Assembly Engine, and produces a professional PDF estimate — all in under 5 minutes from scan to quote.

**Core Value Proposition:**
- 10x faster than manual estimating (5 min vs 45-60 min)
- 95%+ measurement accuracy via LiDAR (vs 80-85% tape measure)
- Professional PDF output that wins more bids
- Works on-site, in basements, with or without cell signal (offline-capable)

**Target Users:** Solo to mid-size residential contractors (remodelers, painters, flooring, GCs)
**Platform:** iOS (primary), Web portal (client-facing), Backend API (Node.js/Express + PostgreSQL)

---

## 2. Scan Flow (iOS App)

### 2.1 User Journey: Open App → Scan Complete

```
1. Open App → Project List View
2. Tap "+" → Create Project (name + optional client name)
3. Project Detail View → Tap "Scan Room"
4. Room Type Selection → Pick: Kitchen, Bathroom, Living Room, Bedroom, etc.
5. AR Scan Initiated → RoomPlan captures spatial data (10-60 seconds)
6. User walks room with iPhone/iPad → LiDAR maps walls, doors, windows, openings
7. Tap "Done" → Scan Processing
8. Results View → Review detected surfaces, dimensions, measurements
9. Optional: Add Manual Context (notes, special conditions)
10. Tap "Generate Estimate" → Estimate Calculation
```

### 2.2 RoomPlan Capture Details

**What RoomPlan captures automatically:**
- Walls: area (sq ft), height, position in 3D space
- Floors: area (sq ft), type detection
- Ceilings: area (sq ft), height
- Doors: width, height, type (standard, sliding, pocket)
- Windows: width, height, type (standard, bay, picture)
- Openings: archways, pass-throughs
- 3D mesh of the room (spatial data)

**What RoomPlan does NOT capture (requires manual input):**
- Current material condition (good/fair/poor)
- Specific material types (tile vs hardwood vs carpet)
- Moisture concerns, ventilation adequacy
- Accessibility issues (tight spaces, stairs)
- Utility locations (plumbing, electrical, HVAC)
- Structural considerations (load-bearing walls, etc.)

### 2.3 RoomScanResult Data Model (iOS)

```swift
struct RoomScanResult: Codable {
    let id: UUID
    let roomType: RoomType
    let scanDate: Date
    let capturedRoom: CapturedRoom  // RoomPlan's native object
    let processedData: ProcessedRoomData
    let snapshots: [ScanSnapshot]   // Photos captured during scan
    let manualNotes: String?
}

struct ProcessedRoomData: Codable {
    let walls: [WallData]
    let floors: [FloorData]
    let ceilings: [CeilingData]
    let doors: [DoorData]
    let windows: [WindowData]
    let openings: [OpeningData]
    let totalArea: Double           // sq ft
    let dimensions: RoomDimensions
}

struct RoomDimensions: Codable {
    let length: Double  // feet
    let width: Double   // feet
    let height: Double  // feet (ceiling height)
    let totalArea: Double // sq ft
}

struct WallData: Codable {
    let id: UUID
    let area: Double       // sq ft
    let height: Double     // feet
    let width: Double      // feet
    let type: String?      // "standard", "partition", "load-bearing"
}

struct FloorData: Codable {
    let id: UUID
    let area: Double       // sq ft
    let type: String?      // "hardwood", "tile", "carpet", "concrete"
}

struct CeilingData: Codable {
    let id: UUID
    let area: Double       // sq ft
    let height: Double     // feet
    let type: String?      // "standard", "vaulted", "cathedral", "drop"
}

enum RoomType: String, Codable, CaseIterable {
    case kitchen, bathroom, livingRoom, bedroom
    case diningRoom, office, laundryRoom, other
    
    var displayName: String { /* human-readable name */ }
}
```

### 2.4 Takeoff Data Format (Sent to Backend)

The iOS app converts RoomPlan output into a standardized "takeoff" JSON structure:

```json
{
  "scan_id": "uuid-v4",
  "room_type": "kitchen",
  "dimensions": {
    "length": 12.5,
    "width": 10.0,
    "height": 9.0,
    "total_area": 125.0
  },
  "takeoff_data": {
    "walls": [
      { "area": 90.0, "height": 9.0, "type": "standard" },
      { "area": 75.0, "height": 9.0, "type": "standard" }
    ],
    "floors": [
      { "area": 125.0, "type": "hardwood" }
    ],
    "ceilings": [
      { "area": 125.0, "type": "standard" }
    ],
    "kitchens": [
      { "area": 125.0 }
    ]
  },
  "surfaces_detected": [
    { "type": "floor", "area": 125.0 },
    { "type": "wall", "area": 165.0 },
    { "type": "ceiling", "area": 125.0 }
  ],
  "frames": [
    {
      "timestamp": "2026-04-05T14:30:00Z",
      "imageData": "<base64-encoded-jpeg>",
      "mimeType": "image/jpeg",
      "lighting_conditions": "good"
    }
  ],
  "start_time": 1712329800
}
```

### 2.5 Scanning State Machine

```
idle → scanning → processing → completed
                  ↘ error (retryable)
```

States:
- `.idle` — Ready to scan, "Start Room Scan" button
- `.scanning` — RoomPlan active, "Stop Scanning" button (red)
- `.processing` — Converting RoomPlan data, spinner
- `.completed` — Results ready, "Generate Estimate" button
- `.error` — Error message, "Retry" button

### 2.6 Device Requirements

- **Minimum:** iPhone/iPad with A12 Bionic chip (iPhone XS and later)
- **Recommended:** iPhone 12 Pro or later / iPad Pro (2020+) with LiDAR
- **OS:** iOS 16.0+
- **RoomPlan availability:** Requires LiDAR-equipped device; graceful degradation on non-LiDAR devices (manual measurement input)

---

## 3. Estimate Flow

### 3.1 Calculation Pipeline

```
Takeoff Data (from scan)
    ↓
Match to Assemblies (by room_type + job_type)
    ↓
For each Assembly → Get AssemblyItems (components)
    ↓
For each Component:
    ├── Material: QuantityCalculator → ProductCatalog → LocationCost → Total
    └── Labor: LaborCalculator → Hours × HourlyRate → Total
    ↓
Apply Complexity Modifiers (from Gemini AI analysis)
    ↓
Sum Subtotal
    ↓
Apply Markup (contractor-configurable, default 25%)
    ↓
Apply Tax (contractor-configurable, default 8%)
    ↓
Organize by CSI Divisions
    ↓
Return Estimate with Line Items
```

### 3.2 Assembly Engine (Core Calculation)

**Input:**
```javascript
{
  takeoffData: { walls: [...], floors: [...], ceilings: [...] },
  jobType: "kitchen" | "bathroom" | "room" | "flooring" | "wall" | "ceiling" | "exterior",
  finishLevel: "good" | "better" | "best",
  zipCode: "60614",
  userSettings: {
    hourly_rate: 50,          // $/hr
    markup_percentage: 25,     // %
    tax_rate: 0.08            // 8%
  }
}
```

**Assembly Matching Logic:**
- `jobType = "kitchen"` → loads assemblies: `kitchen_cabinets`, `kitchen_countertops`, `kitchen_flooring`, `kitchen_backsplash`, `kitchen_paint`
- `jobType = "bathroom"` → loads: `bathroom_vanity`, `bathroom_flooring`, `bathroom_tile_shower`, `bathroom_paint`, `bathroom_fixtures`
- `jobType = "room"` → loads: `room_flooring`, `room_walls`, `room_ceiling`, `room_paint`
- `jobType = "flooring"` → loads: `flooring_base` (material + labor)
- `jobType = "wall"` → loads: `wall_paint`, `wall_texture`
- `jobType = "ceiling"` → loads: `ceiling_paint`, `ceiling_texture`

**Assembly-to-Takeoff Matching:**
```javascript
// For each assembly, determine the takeoff quantity:
matchTakeoffToAssembly(takeoffData, assembly) {
  switch (assembly.category) {
    case "flooring": return takeoffData.floors[0]?.area
    case "walls": return takeoffData.walls.reduce((sum, w) => sum + w.area, 0)
    case "ceiling": return takeoffData.ceilings[0]?.area
    case "paint": return takeoffData.walls.reduce((sum, w) => sum + w.area, 0)
    case "kitchen": return takeoffData.kitchens[0]?.area || takeoffData.floors[0]?.area
    case "bathroom": return takeoffData.bathrooms[0]?.area || takeoffData.floors[0]?.area
  }
}
```

### 3.3 Professional-Grade Estimate Granularity (Level 5 Estimation)

The Assembly Engine produces Level 5 estimates — the professional-grade standard recognized by estimators, GCs, and industry bodies. Every estimate is defensible, auditable, and organized by CSI MasterFormat divisions.

#### 3.3.1 The Standard: Level 5 Estimation

- **Professional-grade, defensible, auditable data** — every number traceable to source variables
- **CSI MasterFormat Integration** — estimates organized by official industry divisions, recognizable to any professional estimator
- **Granular Specificity** — exact manufacturers, model numbers, task-specific labor breakdowns
- **Dynamic Accuracy** — real-time calculations for material waste, breakage, and localized production rates

#### 3.3.2 Core System Architecture

**Attribute I: Relational Data Integrity**

- High-granularity relational database (PostgreSQL)
- Version-controlled schema (migration-led, e.g., `V2__add_professional_estimate_tables.sql`)
- Specialized tables: `Trades`, `MaterialSpecifications`, `LaborTasks`, `WasteFactors`, `WorkSequences`
- Every line item mapped to: trade ID, manufacturer, model number

**Attribute II: Specialized Calculation Engines**

Single Responsibility service architecture — NOT generic "Assembly" logic:

- **Quantity Engine**: base quantity + cut-waste + breakage variables. Calculates exact material needs including waste factors per material type (e.g., 10% for hardwood flooring, 15% for diagonal tile, 5% for drywall).
- **Labor Engine**: total hours based on production rates, room difficulty, crew sizing. NOT flat fees — hours calculated from `base_hours × production_rate × difficulty_modifier × crew_size`.
- **Product Catalog Service**: detailed material specs (manufacturer, technical specs, model numbers, CSI codes). Provides the data that Quantity and Labor engines consume.

**Attribute III: Orchestrated Assembly Logic**

The Assembly Engine is the "Brain" — orchestrator, not calculator:

- Calls specialized services (Quantity, Labor, Catalog) to synthesize rich line items
- **CSI-Driven Organization**: auto-groups output into standard industry divisions (e.g., Division 09 - Finishes, Division 06 - Wood & Plastics)
- Output is immediately recognizable to any professional estimator or GC
- Each line item carries full provenance: which engine calculated it, from what inputs

**Attribute IV: Professional Data Seeding**

Pre-populated library of:

- Standardized trade lists (mapped to CSI divisions)
- Accurate labor task rates (from RSMeans / Craftsman Book data)
- Comprehensive material specification sets (manufacturer, model, specs, waste factors)
- Location cost modifiers (City Cost Index by metro area)

**Attribute V: Granular iOS UI**

- Nested Swift Codable models for deeply nested JSON responses
- `EstimateResultsView`: high-level summary with ability to "drill down" into labor and material logic for every line item
- Expandable reporting per line item — contractor sees the same data a professional estimator would

#### 3.3.3 Scope of Capability (Market-Ready Requirements)

| Feature | Requirement |
|---|---|
| Material Detail | Manufacturer, Model, Waste Factor % |
| Labor Detail | Task Description, Production Rate, Total Hours |
| Organization | CSI MasterFormat Divisions |
| Auditability | Every total traceable to base variables (Qty + Waste) |

#### 3.3.4 How AI Identification Feeds This System

```
AI identifies from scan: material type, condition, dimensions, quantity
    ↓
Feeds into MaterialSpecifications table (manufacturer, model, specs)
    ↓
Quantity Engine calculates: base qty + waste + breakage
    ↓
Labor Engine calculates: hours × production rate × difficulty modifier
    ↓
Assembly Engine orchestrates all of it
    ↓
Output: professional-grade line item organized by CSI division
```

This is system-wide standard — applies to ALL materials, ALL assemblies, ALL labor. Not tied to any single trade or room type.

### 3.4 Material Quantity Calculation

```javascript
// Formula:
total_quantity = base_quantity × assembly_quantity × (1 + waste_factor)

// Example: 125 sq ft kitchen floor, hardwood flooring assembly
// Component: "3/4 in. x 5 in. Oak Hardwood Flooring"
// assembly_quantity: 1.0 (1 sq ft of flooring per 1 sq ft of floor)
// waste_factor: 0.10 (10% waste for cuts and fitting)
// total_quantity = 125 × 1.0 × 1.10 = 137.5 sq ft
```

### 3.5 Cost Calculation

```javascript
// Material cost:
material_cost = total_quantity × localized_unit_cost

// Localized cost hierarchy:
// 1. RetailPrices table (Home Depot, Lowes real-time prices) — if fresh (< 7 days)
// 2. Items.national_average_cost × LocationCostModifiers.material_modifier
// 3. Fallback: Items.national_average_cost (modifier = 1.0)

// Labor cost:
labor_hours = base_hours × quantity × complexity_modifier × room_type_modifier
labor_cost = labor_hours × user_hourly_rate

// Complexity modifiers (from Gemini AI analysis):
// - Accessibility: "challenging" → 1.15x, "very_difficult" → 1.30x
// - Moisture concerns: 1.10x
// - Multiple utilities: 1.05x + (num_utilities × 0.02x)
// - Structural considerations: 1.10x
// - Cap: 1.50x maximum

// Subtotal:
subtotal = Σ(material_costs + labor_costs)

// Markup:
markup = subtotal × (markup_percentage / 100)

// Tax:
tax = (subtotal + markup) × tax_rate

// Grand Total:
grand_total = subtotal + markup + tax
```

### 3.6 Line Item Structure

```json
{
  "line_items": [
    {
      "item_id": "uuid",
      "csi_code": "09 30 00",
      "description": "3/4 in. x 5 in. Oak Hardwood Flooring - Material",
      "quantity": 137.5,
      "unit": "sq ft",
      "unit_cost": 6.95,
      "total_cost": 955.63,
      "type": "material",
      "category": "flooring",
      "manufacturer": "Bruce",
      "model_number": "A63765",
      "specifications": {
        "size_dimensions": "3/4\" x 5\"",
        "material": "Red Oak",
        "finish": "Satin"
      },
      "quantity_details": {
        "base_quantity": 125.0,
        "waste_factor": 0.10,
        "waste_quantity": 12.5,
        "total_quantity": 137.5
      }
    },
    {
      "item_id": "uuid",
      "csi_code": "09 30 00",
      "description": "Hardwood Flooring Installation - Labor",
      "quantity": 37.5,
      "unit": "hours",
      "unit_cost": 50.00,
      "total_cost": 1875.00,
      "type": "labor",
      "category": "flooring",
      "labor_details": {
        "base_hours": 30.0,
        "complexity_adjustment": 7.5,
        "total_hours": 37.5,
        "hourly_rate": 50.00
      }
    }
  ],
  "grandTotal": 4289.44,
  "subtotal": 3574.53,
  "markup": 893.63,
  "tax": 357.45,
  "metadata": {
    "totalLaborHours": 75.5,
    "finishLevel": "better",
    "location": {
      "metro_name": "Chicago-Naperville-Elgin",
      "state_code": "IL",
      "material_modifier": 1.087,
      "labor_modifier": 1.169
    },
    "calculationDate": "2026-04-05T14:30:00Z",
    "engineVersion": "2.0"
  }
}
```

### 3.7 CSI Division Organization

Estimates are organized by CSI (Construction Specifications Institute) divisions:

| CSI Code | Division | Example Items |
|----------|----------|---------------|
| 03 00 00 | Concrete | Foundations, slabs |
| 06 00 00 | Wood & Plastics | Framing, cabinets, trim |
| 07 00 00 | Thermal & Moisture | Insulation, vapor barriers |
| 09 00 00 | Finishes | Flooring, drywall, paint |
| 15 00 00 | Mechanical | HVAC modifications |
| 22 00 00 | Plumbing | Fixtures, piping |
| 26 00 00 | Electrical | Wiring, outlets, fixtures |

---

## 4. PDF Output

### 4.1 PDF Structure

```
┌─────────────────────────────────────────────────┐
│ CONTRACTOR HEADER                                │
│ Contractor Name / Logo                           │
│ License # / Address / Phone / Email              │
├─────────────────────────────────────────────────┤
│ ESTIMATE SUMMARY                                 │
│ Client: John Smith                               │
│ Project: Kitchen Remodel                         │
│ Date: April 5, 2026                              │
│ Estimate #: EST-2026-0042                        │
│ Valid Until: May 5, 2026                         │
├─────────────────────────────────────────────────┤
│ ROOM DETAILS                                     │
│ Room Type: Kitchen                               │
│ Dimensions: 12.5' × 10.0' × 9.0' (125 sq ft)   │
│ Finish Level: Better                             │
├─────────────────────────────────────────────────┤
│ CSI DIVISION: 09 - FINISHES                      │
│ ┌─────────────────────────────────────────────┐ │
│ │ Item              Qty    Unit   $/Unit  Total│ │
│ │ Oak Hardwood      137.5  sq ft  $6.95   $956│ │
│ │ Hardwood Install  37.5   hrs    $50.00  $1875│ │
│ │ Drywall Repair    25.0   sq ft  $2.50   $63 │ │
│ │ Paint - Walls     165.0  sq ft  $0.85   $140│ │
│ └─────────────────────────────────────────────┘ │
│ Division Subtotal: $3,034.00                     │
├─────────────────────────────────────────────────┤
│ CSI DIVISION: 06 - WOOD & PLASTICS               │
│ ...                                              │
├─────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────┐ │
│ │ SUBTOTAL:              $3,574.53            │ │
│ │ Markup (25%):          $893.63              │ │
│ │ Tax (8%):              $357.45              │ │
│ │ ─────────────────────────────────────────── │ │
│ │ GRAND TOTAL:           $4,825.61            │ │
│ └─────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────┤
│ TERMS & CONDITIONS                               │
│ • This estimate is valid for 30 days             │
│ • Payment: 30% deposit, 40% midpoint, 30% final │
│ • Change orders subject to additional charges    │
│ • Warranty: 1 year labor, manufacturer material  │
├─────────────────────────────────────────────────┤
│ ACCEPTANCE                                       │
│ Client Signature: _________________ Date: _____  │
│ Contractor Signature: _____________ Date: _____  │
└─────────────────────────────────────────────────┘
```

### 4.2 PDF Generation (iOS)

Generated using `UIGraphicsPDFRenderer` + `CoreGraphics` (see `PDFGenerator.swift`).

**Key layout parameters:**
- Page: 8.5" × 11" (US Letter)
- Margins: 0.75" all sides
- Header: Contractor logo + info (top 1.5")
- Body: CSI divisions with line items in tables
- Footer: Terms + signature lines
- Color scheme: Dark blue headers (#1a365d), alternating row backgrounds

### 4.3 PDF Data Contract

```json
{
  "pdf_request": {
    "estimate_id": "uuid",
    "contractor_info": {
      "name": "Windy City Construction",
      "license_number": "IL-GC-104285",
      "address": "123 Main St, Chicago, IL 60614",
      "phone": "(312) 555-0142",
      "email": "info@windycityconstruction.com",
      "logo_url": "https://..."
    },
    "client_info": {
      "name": "John Smith",
      "email": "john@example.com",
      "address": "456 Oak Ave, Chicago, IL 60614"
    },
    "project_info": {
      "name": "Kitchen Remodel",
      "room_type": "kitchen",
      "dimensions": "12.5' × 10.0' × 9.0'",
      "total_area": 125.0,
      "finish_level": "better"
    },
    "estimate_data": { /* full estimate object from Assembly Engine */ },
    "terms": "Custom terms text...",
    "valid_days": 30
  }
}
```

---

## 5. Backend Architecture

### 5.1 Technology Stack

| Component | Technology |
|-----------|-----------|
| Runtime | Node.js 20+ |
| Framework | Express.js |
| Database | PostgreSQL 15+ (with JSONB) |
| Auth | Firebase Authentication |
| File Storage | Firebase Storage / Google Cloud Storage |
| AI Analysis | Google Gemini 1.5 Pro |
| Payments | Stripe |
| Hosting | Google Cloud Run |
| ORM | Raw pg driver (no ORM) |

### 5.2 API Endpoints

#### Estimates API

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/estimates` | Create estimate from takeoff data |
| `GET` | `/api/v1/estimates` | List user's estimates (paginated) |
| `GET` | `/api/v1/estimates/:id` | Get estimate details |
| `PUT` | `/api/v1/estimates/:id/status` | Update status (draft→approved→invoiced) |
| `DELETE` | `/api/v1/estimates/:id` | Delete draft estimate |

#### Enhanced Analysis API

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/analysis/enhanced-estimate` | AI-enhanced estimate (AR + Gemini) |
| `POST` | `/api/v1/analysis/room-analysis` | Analyze images without estimate |
| `GET` | `/api/v1/analysis/health` | Gemini service health check |
| `GET` | `/api/v1/analysis/capabilities` | Service capabilities |

#### System API

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | System health check |
| `GET` | `/api/v1` | API documentation |

### 5.3 Request/Response Shapes

#### POST /api/v1/estimates

**Request:**
```json
{
  "takeoffData": {
    "walls": [{ "area": 90.0, "height": 9.0 }],
    "floors": [{ "area": 125.0, "type": "hardwood" }],
    "ceilings": [{ "area": 125.0 }],
    "kitchens": [{ "area": 125.0 }]
  },
  "jobType": "kitchen",
  "finishLevel": "better",
  "zipCode": "60614",
  "projectId": "optional-uuid",
  "notes": "Optional notes"
}
```

**Response (201):**
```json
{
  "estimateId": "uuid",
  "status": "draft",
  "createdAt": "2026-04-05T14:30:00Z",
  "lineItems": [...],
  "csiDivisions": [...],
  "subtotal": 3574.53,
  "markup": 893.63,
  "tax": 357.45,
  "grandTotal": 4825.61,
  "metadata": { ... }
}
```

#### POST /api/v1/analysis/enhanced-estimate

**Request:**
```json
{
  "enhancedScanData": {
    "scan_id": "uuid",
    "room_type": "kitchen",
    "takeoff_data": { ... },
    "dimensions": { "length": 12.5, "width": 10.0, "height": 9.0, "total_area": 125.0 },
    "frames": [
      { "timestamp": "ISO8601", "imageData": "<base64>", "mimeType": "image/jpeg" }
    ]
  },
  "finishLevel": "better",
  "zipCode": "60614",
  "projectId": "optional-uuid",
  "fallbackToBasic": true
}
```

**Response (201):** Same as basic estimate + `ai_analysis` object containing:
```json
{
  "ai_analysis": {
    "room_analysis": {
      "room_type": "kitchen",
      "dimensions_validated": true,
      "surfaces": {
        "walls": { "primary_material": "drywall", "condition": "good", "repair_needed": false },
        "flooring": { "current_material": "tile", "condition": "fair", "removal_required": true },
        "ceiling": { "material": "drywall", "condition": "good", "height_standard": true }
      },
      "complexity_factors": {
        "accessibility": "standard",
        "utilities_present": ["electrical", "plumbing"],
        "moisture_concerns": false,
        "ventilation_adequate": true,
        "structural_considerations": []
      },
      "assembly_recommendations": {
        "suggested_assemblies": ["kitchen_cabinets", "kitchen_countertops", "kitchen_flooring"],
        "finish_level_recommendation": "better"
      }
    }
  }
}
```

### 5.4 Authentication Flow

```
1. Contractor signs up / logs in via Firebase Auth (email/password or Google)
2. Firebase returns ID token (JWT)
3. iOS app includes token in Authorization header: "Bearer <firebase-id-token>"
4. Backend middleware verifies token with Firebase Admin SDK
5. req.user.uid = Firebase UID (used as user_id across all tables)
```

**Middleware:** `authenticate` function in `/middleware/auth.js`
```javascript
// Verifies Firebase ID token from Authorization header
// Sets req.user = { uid, email, email_verified }
```

### 5.5 Database Tables (PostgreSQL Schema)

**Core Tables:**

| Table | Purpose |
|-------|---------|
| `Items` | Individual materials and labor items with costs |
| `Assemblies` | Grouped items (e.g., "kitchen flooring" = flooring material + labor) |
| `AssemblyItems` | Junction: which items belong to which assemblies, with quantities |
| `Trades` | CSI divisions and trade categories |
| `LocationCostModifiers` | Geographic cost multipliers (CCI data) |
| `RetailPrices` | Real-time retail prices (Home Depot, Lowes) |
| `UserFinishPreferences` | User's default quality tier preferences |
| `Projects` | Container for estimates |
| `estimates` | Calculated estimates with full JSONB data |
| `enhanced_estimates` | AI-enhanced estimates with Gemini analysis |

**Key relationships:**
```
Items ──1:N──> AssemblyItems <──N:1── Assemblies
Items ──N:1──> Trades
Items ──1:N──> RetailPrices (per location)
LocationCostModifiers ──1:N──> RetailPrices
Projects ──1:N──> estimates
```

### 5.6 Stripe Integration (Planned)

**Subscription Plans:**

| Plan | Price | Users | Estimates/mo | Features |
|------|-------|-------|--------------|----------|
| Starter | $49/mo | 1 | 50 | Basic assemblies, PDF export |
| Pro | $99/mo | 3 | 200 | All assemblies, AI analysis, client portal |
| Pro Plus | $149/mo | 5 | 500 | Everything + priority support |
| Enterprise | $299/mo | 10 | Unlimited | Custom assemblies, API access, white-label |

**Stripe flow:**
```
1. Contractor selects plan → iOS app calls POST /api/v1/subscriptions/create
2. Backend creates Stripe Customer + Subscription
3. Backend returns Stripe checkout URL or payment intent
4. On success → webhook updates subscription status in Firestore
5. iOS app polls or receives subscription status
```

**Webhook events to handle:**
- `checkout.session.completed`
- `invoice.paid`
- `invoice.payment_failed`
- `customer.subscription.updated`
- `customer.subscription.deleted`

---

## 6. Customer Portal

### 6.1 Overview

The Customer Portal is a web application (React/Next.js) where clients can:
- View estimates shared by their contractor
- Review line items by CSI division
- Accept or decline the estimate
- Provide digital signature
- (Future) Make payments via Stripe
- (Future) View project status updates

### 6.2 Authentication Flow

```
1. Contractor sends estimate to client (email with secure link)
2. Link contains: https://portal.contractorlens.com/estimate/{estimate_id}?token={secure_token}
3. Client clicks link → no account required (token-based auth)
4. Client views estimate details
5. To accept: client provides name + digital signature + date
6. System records acceptance with timestamp
```

### 6.3 Portal Pages

**Estimate View Page:**
- Contractor header (name, license, contact)
- Project summary (room type, dimensions, finish level)
- Line items organized by CSI division
- Subtotal / Markup / Tax / Grand Total
- Terms & conditions
- Accept / Decline buttons
- Digital signature pad

**Post-Acceptance:**
- Confirmation page with acceptance details
- Option to download PDF
- (Future) Payment page with Stripe integration

### 6.4 Data Contract

The portal receives estimate data from the API:
```json
{
  "estimate": { /* full estimate object */ },
  "contractor": {
    "name": "...",
    "company": "...",
    "license_number": "...",
    "contact": { "phone": "...", "email": "..." }
  },
  "client": {
    "name": "John Smith",
    "email": "john@example.com"
  },
  "acceptance": {
    "status": "pending" | "accepted" | "declined",
    "signature_data": null,
    "accepted_at": null
  }
}
```

---

## 7. Admin Portal

### 7.1 Overview

The Admin Portal (for Mirza / ContractorLens admin) provides:

**Contractor Management:**
- List all contractors (paginated)
- View contractor details (subscription, estimates count, status)
- Activate / deactivate contractor accounts
- View contractor's estimates and usage

**Subscription Monitoring:**
- Active subscriptions by plan tier
- MRR / ARR metrics
- Churn tracking
- Failed payments alert

**Pricing Data Management:**
- Manage `Items` catalog (CRUD)
- Manage `Assemblies` and `AssemblyItems`
- Update `LocationCostModifiers` (CCI data)
- Trigger retail price scraping jobs
- View data freshness (last scraped timestamps)

**System Health:**
- API health status
- Gemini service status
- Database metrics
- Error logs

### 7.2 Admin Authentication

- Admin role stored in Firebase Custom Claims (`admin: true`)
- Admin middleware checks `req.user.admin === true`
- Separate admin routes under `/api/v1/admin/*`

---

## 8. Pricing Data Flow

### 8.1 Cost Hierarchy

```
Priority 1: RetailPrices (real-time scraped) — if < 7 days old
    ↓ (if not available)
Priority 2: Items.national_average_cost × LocationCostModifier
    ↓ (if no location modifier)
Priority 3: Items.national_average_cost (national average)
```

### 8.2 Data Sources

**Source 1: RSMeans / Craftsman Book (National Averages)**
- `Items.national_average_cost` — seeded from industry cost databases
- Updated quarterly
- Covers materials and labor rates

**Source 2: City Cost Index (CCI)**
- `LocationCostModifiers` — multipliers by metro area
- `material_modifier` and `labor_modifier` separate
- Based on RSMeans CCI data
- Example: Chicago materials = 1.087x, labor = 1.169x national average

**Source 3: Retail Scraping (Home Depot, Lowes)**
- `RetailPrices` — real-time prices per SKU per location
- Scraped periodically (weekly target)
- Takes precedence over national averages when fresh (< 7 days)
- Falls back to national average if stale

### 8.3 Unit Conversions

All internal calculations use:
- **Area:** square feet (sq ft)
- **Volume:** cubic feet
- **Length:** linear feet
- **Weight:** pounds
- **Time:** hours

Conversion factors stored in `Items.unit` field. The `quantityCalculator` handles:
- Board feet → square feet (for lumber)
- Gallons → square feet (for paint, coverage rate = 350 sq ft/gallon)
- Boxes → square feet (for tile, with box size)

### 8.4 PostgreSQL Cost Calculation Function

```sql
-- get_localized_item_cost(item_id, location_id) → DECIMAL
-- 1. Check RetailPrices (fresh < 7 days) → return retail_price
-- 2. Fallback: Items.national_average_cost × LocationCostModifiers.material_modifier (or labor_modifier)
-- 3. Final fallback: national_average_cost
```

### 8.5 Assembly Data (Seeded)

**Assemblies table (seeded):**
- `kitchen_cabinets` (CSI 06 04 00) — cabinets + installation labor
- `kitchen_countertops` (CSI 06 40 00) — countertop material + fabrication + install labor
- `kitchen_flooring` (CSI 09 30 00) — flooring material + installation labor
- `kitchen_backsplash` (CSI 09 30 00) — tile + grout + installation labor
- `kitchen_paint` (CSI 09 10 00) — paint + primer + labor
- `bathroom_vanity` (CSI 06 04 00) — vanity + countertop + labor
- `bathroom_flooring` (CSI 09 30 00) — tile + labor
- `bathroom_tile_shower` (CSI 09 30 00) — tile + waterproofing + labor
- `bathroom_paint` (CSI 09 10 00) — moisture-resistant paint + labor
- `bathroom_fixtures` (CSI 22 40 00) — toilet, faucet, accessories
- `room_flooring` (CSI 09 30 00) — generic room flooring
- `room_walls` (CSI 09 29 00) — drywall repair + texture
- `room_ceiling` (CSI 09 29 00) — ceiling texture/repair
- `room_paint` (CSI 09 10 00) — generic room paint
- `flooring_base` (CSI 09 30 00) — standalone flooring
- `wall_paint` (CSI 09 10 00) — standalone wall paint
- `ceiling_paint` (CSI 09 10 00) — standalone ceiling paint
- `exterior_paint` (CSI 09 10 00) — exterior paint + prep labor
- `texture_wall` (CSI 09 29 00) — wall texturing
- `texture_ceiling` (CSI 09 29 00) — ceiling texturing

---

## 9. Data Models (Complete Reference)

### 9.1 Items Table

```sql
CREATE TABLE Items (
    item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    csi_code VARCHAR(20) NOT NULL,          -- "09 30 00"
    category VARCHAR(100) NOT NULL,          -- "flooring", "paint", etc.
    subcategory VARCHAR(100),                -- "hardwall", "hardwood", etc.
    description TEXT NOT NULL,               -- "3/4 in. x 5 in. Oak Hardwood Flooring"
    unit VARCHAR(20) NOT NULL,               -- "sq ft", "linear ft", "hours"
    item_type VARCHAR(20) NOT NULL,          -- "material" or "labor"
    quality_tier VARCHAR(20),                -- "good", "better", "best"
    national_average_cost DECIMAL(10,2),     -- base cost (material or labor rate)
    waste_factor DECIMAL(5,4) DEFAULT 0.0,   -- 0.10 = 10% waste
    base_hours DECIMAL(8,2),                 -- labor: base hours per unit
    manufacturer VARCHAR(100),
    model_number VARCHAR(100),
    specifications JSONB,                    -- { size_dimensions, material, finish, ... }
    trade_id UUID REFERENCES Trades(trade_id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### 9.2 Assemblies Table

```sql
CREATE TABLE Assemblies (
    assembly_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assembly_name VARCHAR(100) NOT NULL,     -- "kitchen_cabinets"
    category VARCHAR(100) NOT NULL,          -- "kitchen", "bathroom", "flooring"
    csi_division VARCHAR(20),                -- "06 04 00"
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### 9.3 AssemblyItems Table (Junction)

```sql
CREATE TABLE AssemblyItems (
    assembly_id UUID REFERENCES Assemblies(assembly_id),
    item_id UUID REFERENCES Items(item_id),
    quantity DECIMAL(10,4) NOT NULL,         -- multiplier per unit of assembly
    PRIMARY KEY (assembly_id, item_id)
);
```

### 9.4 LocationCostModifiers Table

```sql
CREATE TABLE LocationCostModifiers (
    location_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metro_name VARCHAR(100) NOT NULL,        -- "Chicago-Naperville-Elgin"
    state_code CHAR(2) NOT NULL,             -- "IL"
    zip_code_range VARCHAR(20),              -- "60601-60699"
    material_modifier DECIMAL(4,3) NOT NULL, -- 1.087
    labor_modifier DECIMAL(4,3) NOT NULL,    -- 1.169
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE
);
```

### 9.5 Estimates Table

```sql
CREATE TABLE estimates (
    estimate_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,           -- Firebase UID
    project_id UUID REFERENCES Projects(project_id),
    job_type VARCHAR(50) NOT NULL,           -- "kitchen", "bathroom", etc.
    finish_level VARCHAR(20) NOT NULL,       -- "good", "better", "best"
    takeoff_data JSONB NOT NULL,             -- raw scan data
    estimate_data JSONB NOT NULL,            -- full calculated estimate
    location_data JSONB,                     -- location info used
    notes TEXT,
    grand_total DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'draft',      -- draft, approved, invoiced, archived
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### 9.6 Projects Table

```sql
CREATE TABLE Projects (
    project_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,
    project_name VARCHAR(200) NOT NULL,
    description TEXT,
    location_id UUID REFERENCES LocationCostModifiers(location_id),
    address TEXT,
    zip_code VARCHAR(10),
    status VARCHAR(20) DEFAULT 'active',     -- active, completed, archived
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

---

## 10. API Contracts

### 10.1 Authentication

All authenticated endpoints require:
```
Authorization: Bearer <firebase-id-token>
Content-Type: application/json
```

### 10.2 Error Response Format

```json
{
  "error": "Human-readable error message",
  "code": "MACHINE_READABLE_CODE",
  "details": [ /* Joi validation details, optional */ ]
}
```

Error codes: `VALIDATION_FAILED`, `CALCULATION_FAILED`, `INTERNAL_ERROR`, `NOT_FOUND`, `RETRIEVAL_FAILED`, `UPDATE_FAILED`, `DELETE_FAILED`, `ANALYSIS_FAILED`, `CANNOT_DELETE`, `INVALID_ID`, `INVALID_STATUS`

### 10.3 Pagination Format

```json
{
  "estimates": [...],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 42,
    "totalPages": 5,
    "hasNext": true,
    "hasPrev": false
  }
}
```

---

## 11. Stripe Integration

### 11.1 Subscription Lifecycle

```
Contractor signs up → Free trial (14 days)
    ↓
Selects plan → Stripe Checkout session
    ↓
Payment success → Stripe webhook → Activate subscription
    ↓
Monthly billing → Stripe invoices → webhook on payment success/failure
    ↓
Cancellation → Stripe webhook → Deactivate features → Archive account
```

### 11.2 Key Stripe Objects

- **Customer:** 1:1 with Firebase user
- **Price:** One per plan tier (monthly)
- **Subscription:** Links customer to price, tracks status
- **Checkout Session:** One-time payment flow
- **Webhook Endpoint:** `/api/v1/webhooks/stripe`

### 11.3 Subscription Tiers (Stripe Price IDs)

| Tier | Monthly Price | Stripe Price ID (placeholder) |
|------|--------------|-------------------------------|
| Starter | $49 | `price_starter_monthly` |
| Pro | $99 | `price_pro_monthly` |
| Pro Plus | $149 | `price_proplus_monthly` |
| Enterprise | $299 | `price_enterprise_monthly` |

### 11.4 Webhook Handling

```javascript
// POST /api/v1/webhooks/stripe
// Verify Stripe signature header
// Route by event type:
// - checkout.session.completed → activate subscription
// - invoice.paid → extend subscription period
// - invoice.payment_failed → flag account, notify contractor
// - customer.subscription.updated → sync plan changes
// - customer.subscription.deleted → deactivate account
```

---

## 12. Open Questions

### Technical

1. **RoomPlan fallback for non-LiDAR devices:** Should we support manual room dimension entry as a fallback, or require LiDAR? Current code has `RoomCaptureSession.isSupported` check but no fallback UI.

2. **Offline capability:** The iOS app currently assumes backend connectivity for estimate calculation. Should we implement offline estimation with cached assembly data? This would require shipping the assemblies + items SQLite database with the app.

3. **Image storage:** Currently, scan images (frames) are sent as base64 in the API request. For production, should we upload to Cloud Storage first and pass URLs instead? This impacts the enhanced estimate flow.

4. **Gemini model version:** The code references `gemini-1.5-pro` but the mind map mentions `Gemini 2.0`. Which model should be the default?

5. **Web app for contractors:** The architecture mentions a React/Next.js web app for contractors (not just clients). Is this in scope for MVP, or iOS-only with client portal web app?

### Business

6. **Pricing model confirmation:** The ChatGPT history shows multiple pricing models ($49-299, $75-350, $99-299). The current database schema doesn't have subscription tables. Which pricing structure is final?

7. **Retail price scraping:** Home Depot and Lowes have terms of service against scraping. Should we use a third-party API (like PriceAPI) instead, or is this a future enhancement?

8. **Geographic coverage:** The seeded data has Chicago metro. Should we pre-seed all 50 states, or launch Chicago-only and expand?

9. **Customer portal auth:** The spec uses token-based auth (no account required for clients). Should clients be able to create accounts to view historical estimates?

10. **Digital signature legal compliance:** Should we integrate DocuSign or similar for legally binding signatures, or is a simple drawn signature sufficient?

---

## Appendix A: Key File Paths

### iOS App
- Room scanning: `/ios-app/ContractorLens/AR/RoomScanner.swift`
- Scan service: `/ios-app/ContractorLens/Services/ScanningService.swift`
- Estimate engine: `/ios-app/ContractorLens/Services/DeterministicEstimateEngine.swift`
- PDF generation: `/ios-app/ContractorLens/Services/PDFGenerator.swift`
- Models: `/ios-app/ContractorLens/Models/` (Room.swift, Surface.swift, Estimate.swift, Assembly.swift, Measurement.swift)
- Trade assemblies: `/ios-app/ContractorLens/Resources/trade-assemblies.json`
- Measurement rules: `/ios-app/ContractorLens/Resources/measurement-rules.json`

### Backend
- Server entry: `/backend/src/server.js`
- Estimates routes: `/backend/src/routes/estimates.js`
- Analysis routes: `/backend/src/routes/analysis.js`
- Assembly engine: `/backend/src/services/assemblyEngine.js`
- Gemini integration: `/backend/src/services/geminiIntegration.js`
- Quantity calculator: `/backend/src/services/quantityCalculator.js`
- Labor calculator: `/backend/src/services/laborCalculator.js`
- Product catalog: `/backend/src/services/productCatalog.js`
- Auth middleware: `/backend/src/middleware/auth.js`
- DB config: `/backend/src/config/database.js`

### Database
- Schema: `/database/schemas/schema.sql`
- Assembly seeds: `/database/seeds/assemblies.sql`
- Item seeds: `/database/seeds/items.sql`

### ChatGPT Exports (Key Files)
- Vision breakdown: `/data/chatgpt-exports-phase2/extracted/chatgpt-export-markdown-project-entrepreneurship-part-01/ChatGPT-ContractorLens_Vision_Breakdown.md`
- System architecture: `/data/chatgpt-exports-phase2/extracted/chatgpt-export-markdown-part-15/ChatGPT-ContractorLens_System_Architecture.md`
- Architecture v2: `/data/chatgpt-exports-phase2/extracted/chatgpt-export-markdown-part-14/ChatGPT-Contractor_Lens_Architecture.md`
- Reset doc (schema/API contracts): `/data/chatgpt-exports-phase2/extracted/chatgpt-export-markdown-part-02/ChatGPT-Contractor_Lens_Reset.md`
- App summary: `/data/chatgpt-exports-phase2/extracted/chatgpt-export-markdown-part-07/ChatGPT-ContractorLens_app_summary.md`
- MVP plan: `/data/chatgpt-exports-phase2/extracted/chatgpt-export-markdown-project-entrepreneurship-part-01/ChatGPT-ContractorLens_MVP_Plan.md`
- Market validation: `/data/chatgpt-exports-phase2/extracted/chatgpt-export-markdown-project-entrepreneurship-part-01/ChatGPT-ContractorLens_Market_Validation.md`

---

## Appendix B: Calculation Examples

### Example 1: Kitchen Remodel — Level 5 Estimate (Full Breakdown)

**Input (from scan):**
- Room: Kitchen, 12.5' × 10.0', 9' ceiling
- Floor area: 125 sq ft
- Wall area: 165 sq ft (minus doors/windows)
- Ceiling area: 125 sq ft
- ZIP: 60614 (Chicago)
- Finish level: Better

**AI Identification feeds the system:**
- Flooring: hardwood (existing, removal required)
- Walls: drywall, good condition, standard repair
- Ceiling: drywall, good condition
- Backsplash: tile, 35 sq ft area identified

**Assemblies matched:** `kitchen_flooring`, `kitchen_paint`, `kitchen_backsplash`

**Calculation — each line item traceable to base variables:**

**CSI 09 30 00 — Flooring (Hardwood):**

| Component | Base Qty | Waste % | Total Qty | Unit | Rate | Cost |
|-----------|----------|---------|-----------|------|------|------|
| Oak Hardwood (Bruce A63765) | 125.0 | 10% | 137.5 | sq ft | $6.95 | $955.63 |
| Hardwood Installation Labor | — | — | 37.5 | hrs | $50.00 | $1,875.00 |
| Old Flooring Removal | 125.0 | 5% | 131.3 | sq ft | $1.85 | $242.88 |
| **Division Subtotal** | | | | | | **$3,073.51** |

*Labor calculation: 30.0 base hrs × 1.25 complexity (Chicago) = 37.5 hrs*

**CSI 09 10 00 — Paint:**

| Component | Base Qty | Waste % | Total Qty | Unit | Rate | Cost |
|-----------|----------|---------|-----------|------|------|------|
| Paint — Walls (Sherwin-Williams SW7029) | 165.0 | 5% | 173.3 | sq ft | $0.85 | $147.28 |
| Primer (walls) | 165.0 | 5% | 173.3 | sq ft | $0.42 | $72.77 |
| Painting Labor — Walls | — | — | 22.0 | hrs | $45.00 | $990.00 |
| Paint — Ceiling (SW7029) | 125.0 | 3% | 128.8 | sq ft | $0.85 | $109.44 |
| Painting Labor — Ceiling | — | — | 10.0 | hrs | $45.00 | $450.00 |
| **Division Subtotal** | | | | | | **$1,769.49** |

*Labor calculation: Walls = 18.0 base hrs × 1.22 complexity; Ceiling = 8.0 base hrs × 1.25 complexity*

**CSI 09 30 00 — Backsplash:**

| Component | Base Qty | Waste % | Total Qty | Unit | Rate | Cost |
|-----------|----------|---------|-----------|------|------|------|
| Ceramic Tile (Daltile R0131) | 35.0 | 15% | 40.3 | sq ft | $4.50 | $181.13 |
| Thinset Mortar | 35.0 | 5% | 36.8 | sq ft | $0.65 | $23.89 |
| Grout | 35.0 | 5% | 36.8 | sq ft | $0.35 | $12.87 |
| Tile Installation Labor | — | — | 18.0 | hrs | $50.00 | $900.00 |
| **Division Subtotal** | | | | | | **$1,117.89** |

*Labor calculation: 15.0 base hrs × 1.20 complexity (tile work, backsplash height)*

**Full Estimate Summary:**

| CSI Division | Subtotal |
|--------------|----------|
| 09 30 00 — Flooring | $3,073.51 |
| 09 10 00 — Paint | $1,769.49 |
| 09 30 00 — Backsplash | $1,117.89 |
| **Subtotal** | **$5,960.89** |
| Markup (25%) | $1,490.22 |
| Tax (8%) | $596.09 |
| **Grand Total** | **$8,047.20** |

*Every total traceable: Material = base qty × (1 + waste%) × unit cost. Labor = base hrs × complexity modifier × hourly rate.*

### Example 2: Audit Trail — Tracing a Single Line Item

**Line Item:** Oak Hardwood Flooring — Material

```
Traceback:
  Total Cost: $955.63
    ← Quantity: 137.5 sq ft × Unit Cost: $6.95/sq ft
    ← 137.5 = 125.0 (base from scan) × 1.10 (waste factor)
    ← 125.0 = takeoff_data.floors[0].area (LiDAR measurement)
    ← 1.10 = WasteFactors.hardwood_flooring (10% for cuts/fitting)
    ← $6.95 = ProductCatalog (Bruce A63765) × LocationCostModifier(1.087 Chicago)
    ← National avg: $6.39/sq ft × 1.087 (CCI material modifier)
    ← CSI Code: 09 30 00 (Finishes — Flooring)
    ← Trade ID: flooring_trade_001
    ← Manufacturer: Bruce | Model: A63765
```

This audit trail is available for every single line item in every estimate. A GC, auditor, or client can trace any number back to its source variables.

---

*This document is the definitive build specification for ContractorLens. Coding agents should reference this spec for implementation details. For questions or clarifications, consult the ChatGPT export files listed in Appendix A.*
