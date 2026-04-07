# ContractorLens — Full Technical Plan

**Version:** 1.0
**Date:** April 5, 2026
**Purpose:** Definitive build plan from current state to shipped product
**Source Spec:** `agents/output/contractorlens-full-spec.md`

---

## Table of Contents

1. [Codebase Assessment](#1-codebase-assessment)
2. [Modify Existing vs. Start Fresh (Decision Matrix)](#2-modify-existing-vs-start-fresh)
3. [Full Tech Stack Definition](#3-full-tech-stack-definition)
4. [Architecture Overview](#4-architecture-overview)
5. [Database Schema (Complete)](#5-database-schema-complete)
6. [API Endpoint List](#6-api-endpoint-list)
7. [Build Plan with Workstreams](#7-build-plan-with-workstreams)

---

## 1. Codebase Assessment

### 1.1 iOS App (`/ios-app/ContractorLens/`)

| Component | Status | Verdict | Notes |
|-----------|--------|---------|-------|
| `ContractorLensApp.swift` | Partial | **Needs modification** | Uses SwiftData (correct), but no auth flow, no backend connectivity |
| `AR/RoomScanner.swift` | Working | **Keep as-is** | Solid RoomPlan integration, delegate pattern, state management. Production-ready. |
| `AR/ARCoordinator.swift` | Partial | **Needs modification** | Frame capture works, but no Gemini integration for real-time analysis |
| `ScanningService.swift` | Partial | **Needs modification** | RoomPlan capture works, but `completeScan()` returns hardcoded room type, frame processing is stubbed |
| `ScanningViewModel.swift` | Working | **Keep as-is** | Clean state machine, proper Combine bindings |
| `DeterministicEstimateEngine.swift` | Removed | **Needs rewrite (old scope — removed, will be rebuilt as specialized engines per new spec)** | Deleted from working tree. Old simple scope engine didn't match Level 5 estimation architecture. |
| `AssemblyEngineService.swift` | Skeleton | **Needs rewrite** | Mixes mock data with real API calls. Combine-based networking is correct pattern but URLs are localhost, no auth headers, mock fallbacks dominate |
| `ChatViewModel.swift` | Mock | **Needs rewrite** | Entirely hardcoded responses. Pattern-matching "blue paint" / "add outlet" — needs real Gemini backend integration |
| `ChatView.swift` | Good | **Keep as-is** | Clean SwiftUI chat UI. Works well. Just needs real ViewModel behind it. |
| `PDFGenerator.swift` | Removed | **Needs rewrite (old scope)** | Deleted from working tree. Will be rebuilt to new spec. |
| `EstimateResultsView.swift` | Good | **Keep as-is** | V2 estimate display with CSI divisions, expandable line items. Matches spec. |
| `ProjectListView.swift` | Working | **Keep as-is** | SwiftData CRUD, clean navigation. Production-ready. |
| `ProjectDetailView.swift` | Refactored | **Keep as-is (refactored)** | Extracted from monolithic ContentView |
| `ContentView.swift` | Minimal | **Keep as-is** | Just routes to ProjectListView |
| `ContentView_Old.swift` | Stale | **Keep as reference** | Old monolithic ContentView preserved for reference |
| Data Models (`Models/*.swift`) | Good | **Keep as-is** | `Estimate`, `CSIDivision`, `LineItem`, `RoomScanResult`, `RoomType` all match spec |
| `Core/Models/ProjectModel.swift` | Good | **Keep as-is** | SwiftData `@Model` classes for Project and Room. Clean JSON encoding/decoding helpers. |
| `UserPreferences.swift` | Exists | **Needs modification** | Basic structure exists, needs quality tier and location preferences |

**Views Refactoring (April 5, 2026):** The monolithic `ContentView.swift` has been broken into separate, focused view files:
- `EstimateEditView.swift` — Estimate editing interface
- `ProjectDetailView.swift` — Project detail with room list
- `ProjectEstimateView.swift` — Project-level estimate display
- `ProjectListView.swift` — Main project list (already existed, updated)
- `RoomDetailView.swift` — Room detail view
- `RoomScanningView.swift` — Room scanning entry point
- `Core/Models/ProjectModel.swift` — Extracted SwiftData models
- `Resources/measurement-rules.json`, `trade-assemblies.json` — Extracted configuration

**iOS Summary:** ~70% of the iOS app is salvageable. The RoomPlan scanning, PDF generation, project management, and estimate display are solid. The main gaps are: (1) backend connectivity, (2) real chat/Gemini integration, (3) auth flow. Views are now refactored into clean separate files.

### 1.2 Backend (`/backend/src/`)

| Component | Status | Verdict | Notes |
|-----------|--------|---------|-------|
| `server.js` | Skeleton | **Needs rewrite** | Express app with routes wired, CORS, helmet. Good structure but no auth middleware on routes, no Stripe, no WebSocket |
| `config/database.js` | Working | **Keep as-is** | Standard pg Pool config. Production-ready. |
| `config/firebase.js` | Working | **Keep as-is** | Firebase Admin SDK init. Production-ready. |
| `middleware/auth.js` | Working | **Keep as-is** | Firebase token verification. Clean implementation. |
| `middleware/metrics.js` | Exists | **Needs modification** | Basic Prometheus metrics. Needs request timing, error tracking |
| `routes/estimates.js` | Partial | **Needs rewrite** | POST `/` and GET `/:id` work for basic estimates. Missing: list, update status, delete. No auth middleware applied. |
| `routes/analysis.js` | Partial | **Needs modification** | Enhanced estimate and room analysis endpoints exist. Need auth, error handling hardening. |
| `services/assemblyEngine.js` | Good | **Keep as core** | Solid assembly expansion, CSI grouping, quantity/labor/cost pipeline. 153 lines of real logic. |
| `services/quantityCalculator.js` | Good | **Keep as-is** | 350+ lines of material-specific quantity calculations. Comprehensive. |
| `services/laborCalculator.js` | Good | **Keep as-is** | 400+ lines of labor production rates. Well-structured. |
| `services/productCatalog.js` | Good | **Keep as-is** | Item lookup, quality tier filtering, CSI code resolution. |
| `services/geminiIntegration.js` | Partial | **Needs modification** | Gemini 1.5 Pro integration exists. Works for image analysis. Needs: chat/modification endpoint, better error handling. |
| `performance/caching.js` | Exists | **Needs modification** | In-memory LRU cache. Good start, needs Redis for production multi-instance. |
| `performance/optimizedAssemblyEngine.js` | Exists | **Needs review** | Caching layer over assembly engine. Keep if working. |
| `performance/optimizedRoutes.js` | Exists | **Needs review** | Route-level caching. Merge into main routes. |
| `performance/productionMonitoring.js` | Exists | **Needs modification** | Health checks, uptime monitoring. Good foundation. |
| `performance/geminiOptimization.js` | Exists | **Needs modification** | Batch processing, frame optimization. Useful for production. |
| `performance/loadTesting.js` | Exists | **Keep as-is** | k6 load test scripts. Good to have. |

**Backend Summary:** ~50% salvageable. Core calculation engines (assembly, quantity, labor, catalog) are solid. Auth middleware works. The main gaps are: (1) auth not applied to routes, (2) no Stripe integration, (3) no WebSocket for chat, (4) no project/estimate CRUD endpoints, (5) no user management.

### 1.3 Database (`/database/`)

| Component | Status | Verdict | Notes |
|-----------|--------|---------|-------|
| `schemas/schema.sql` | Good | **Keep as-is** | Core tables: Items, Assemblies, AssemblyItems, LocationCostModifiers, RetailPrices, UserFinishPreferences, Projects, estimates, enhanced_estimates. Well-normalized. |
| `schemas/indexes.sql` | Excellent | **Keep as-is** | 30+ performance indexes. Production-grade. |
| `migrations/V2__add_professional_estimate_tables.sql` | Good | **Keep as-is** | Trades, MaterialSpecifications, LaborTasks, WasteFactors, WorkSequences tables. |
| `seeds/items.sql` | Good | **Keep as-is** | Kitchen + bathroom materials across good/better/best tiers. Real CSI codes. |
| `seeds/assemblies.sql` | Good | **Keep as-is** | Kitchen Economy/Standard/Premium + Bathroom packages. |
| `seeds/assembly_items.sql` | Exists | **Needs review** | Junction table data. Verify completeness. |
| `seeds/labor_tasks.sql` | Exists | **Needs review** | Labor production rates. |
| `seeds/location_modifiers.sql` | Exists | **Needs review** | Geographic cost data. |
| `seeds/material_specifications.sql` | Exists | **Needs review** | Product specs. |
| `seeds/trades.sql` | Exists | **Needs review** | CSI division data. |
| `performance/*.sql` | Good | **Keep as-is** | Query optimization, connection tuning, benchmarking. |

**Database Summary:** ~85% ready. Schema is well-designed, indexed, and seeded. The V2 migration adds professional granularity. Main gap: no `users` table (relies on Firebase), no `subscriptions` table for Stripe.

### 1.4 Infrastructure (`/infrastructure/`)

| Component | Status | Verdict | Notes |
|-----------|--------|---------|-------|
| `terraform/main.tf` | Good | **Keep as base, needs modification** | Full AWS stack: VPC, RDS PostgreSQL, ECS Fargate, ALB, CloudWatch, SSM Parameter Store. Solid foundation. |
| `terraform/variables.tf` | Exists | **Needs modification** | Needs Stripe, QuickBooks variables |
| `terraform/outputs.tf` | Exists | **Review** | Output definitions |
| `docker-compose.yml` | Good | **Keep as-is** | Local dev: postgres, backend, gemini-service, nginx. Well-configured. |

**Infrastructure Summary:** ~70% ready. AWS Terraform is production-grade for the backend. Needs: S3 for file storage, CloudFront for CDN, CI/CD pipeline definition.

### 1.5 ML Services (`/ml-services/gemini-service/`)

| Component | Status | Verdict | Notes |
|-----------|--------|---------|-------|
| `analyzer.js` | Good | **Keep as-is** | Gemini 1.5 Pro image analysis, material detection, condition assessment |
| `package.json` | Good | **Keep as-is** | Clean dependencies |
| `Dockerfile` | Exists | **Keep as-is** | Containerized service |

**ML Summary:** ~80% ready. Gemini analysis service works. Needs: chat/conversation endpoint for estimate modifications.

---

## 2. Modify Existing vs. Start Fresh

### Decision Matrix

| Component | Decision | Reasoning |
|-----------|----------|-----------|
| **iOS App** | **Modify existing** | RoomPlan scanning (RoomScanner.swift) is production-ready. PDF generation works. Project management with SwiftData works. The UI layer (ChatView, EstimateResultsView, ProjectListView) is clean SwiftUI. Only the networking/chat layer needs rewriting. A full rewrite would waste 70% working code. |
| **Backend API** | **Modify existing** | Core calculation engines (assemblyEngine, quantityCalculator, laborCalculator, productCatalog) are 400+ lines of real, tested logic. Auth middleware works. The Express skeleton just needs routes + middleware wired up correctly. Rewrite would lose the calculation pipeline. |
| **Database** | **Modify existing** | Schema is well-normalized, indexed, and seeded. V2 migration already adds professional granularity. Just needs: subscriptions table, minor adjustments. No reason to rewrite. |
| **Pricing Layer** | **Modify existing** | Quantity calculator (350+ lines), labor calculator (400+ lines), product catalog are all solid. Assembly engine correctly expands assemblies into line items. Just needs real pricing API integrations (Craftsman, Ferguson, ABC Supply) added as data sources. |
| **iOS Scanning** | **Keep as-is** | RoomPlan integration is clean, delegate pattern works, state machine is correct. |
| **Chat System** | **Needs rewrite (iOS + backend)** | iOS ChatViewModel is entirely mock. Backend has no chat endpoint. This needs to be built from scratch, but the ChatView UI is good. |
| **Stripe Integration** | **Doesn't exist** | Needs to be built from scratch on backend + iOS. |
| **Customer Portal** | **Doesn't exist** | Needs to be built from scratch (web app). |
| **Admin Portal** | **Doesn't exist** | Needs to be built from scratch (web app). |

---

## 3. Full Tech Stack Definition

### iOS App

| Layer | Technology | Details |
|-------|-----------|---------|
| Language | Swift 5.9+ | |
| UI Framework | SwiftUI | iOS 16+ minimum (RoomPlan requirement) |
| Minimum iOS | iOS 16.0 | RoomPlan requires iPhone 12 Pro+ or iPad Pro (2020+) with LiDAR |
| Scanning | RoomPlan (`import RoomPlan`) | Apple's native room scanning framework |
| AR Sessions | ARKit (`import ARKit`) | For frame capture during RoomPlan sessions |
| Local Storage | SwiftData (`import SwiftData`) | `@Model` classes for Project, Room |
| State Management | ObservableObject + `@Published` | ViewModels: ScanningViewModel, ChatViewModel, EstimateViewModel |
| Navigation | SwiftUI NavigationStack | ProjectList → ProjectDetail → RoomScan → Estimate |
| PDF Generation | PDFKit + UIGraphicsPDFRenderer | Native iOS PDF generation (PDFGenerator.swift) |
| Networking | URLSession + Combine | AssemblyEngineService pattern (needs rewrite with auth) |
| AI Integration | Backend-mediated Gemini | iOS sends frames → Backend calls Gemini → Returns analysis |
| Auth | Firebase Auth SDK | Email/password + Google sign-in |
| Charts | Swift Charts (iOS 16+) | For estimate breakdowns |
| Dependencies (Swift PM) | None currently | May add: Kingfisher (image caching), Lottie (animations) |

### Backend API

| Layer | Technology | Details |
|-------|-----------|---------|
| Runtime | Node.js 20+ | |
| Framework | Express.js | |
| Language | JavaScript (CommonJS) | |
| Database Driver | `pg` (node-postgres) | Raw SQL, no ORM |
| Auth | Firebase Admin SDK | `firebase-admin` v12+ |
| AI | Google Gemini 1.5 Pro | `@google/generative-ai` v0.21+ |
| Payments | Stripe | `stripe` v14+ |
| File Storage | AWS S3 | `@aws-sdk/client-s3` |
| Validation | Joi | Request validation |
| Caching | In-memory LRU → Redis | `ioredis` for production |
| Rate Limiting | `express-rate-limit` | API protection |
| WebSocket | `ws` (WebSocket) | For real-time chat |
| Task Queue | BullMQ | Background jobs (email, webhooks) |
| Email | SendGrid | `@sendgrid/mail` |
| Logging | Winston | Structured logging |
| API Style | REST | JSON request/response |

### Database

| Layer | Technology | Details |
|-------|-----------|---------|
| Database | PostgreSQL 15+ | With JSONB for flexible estimate storage |
| Schema Management | SQL migration files | `migrations/` directory, numbered V1, V2, etc. |
| Seeding | SQL seed files | `seeds/` directory |
| Connection Pooling | pg Pool (built-in) | 20 connections, 30s idle timeout |

### Infrastructure

| Layer | Technology | Details |
|-------|-----------|---------|
| Cloud Provider | AWS | |
| Container Orchestration | ECS Fargate | Auto-scaling 1-5 instances |
| Database Hosting | RDS PostgreSQL | gp3 storage, 30-day backup |
| File Storage | S3 | Estimate PDFs, scan images |
| CDN | CloudFront | Static assets, PDF delivery |
| Load Balancer | ALB | HTTP/HTTPS |
| DNS | Route 53 | `api.contractorlens.app` |
| Secrets | AWS SSM Parameter Store | Encrypted secure strings |
| IaC | Terraform | Full infrastructure as code |
| CI/CD | GitHub Actions | Build → Test → Deploy to ECS |
| Monitoring | CloudWatch + Datadog | Metrics, logs, alerts |
| Container Registry | ECR | Docker image storage |

---

## 4. Architecture Overview

### High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        iOS App (SwiftUI)                         │
│  ┌──────────┐  ┌───────────┐  ┌──────────┐  ┌───────────────┐  │
│  │ RoomPlan │  │ Scanning  │  │ Estimate │  │  Chat View    │  │
│  │ Scanner  │→ │ Service   │→ │ Display  │← │  (Gemini)     │  │
│  └──────────┘  └───────────┘  └──────────┘  └───────────────┘  │
│       │              │              │               │            │
│  ┌──────────┐  ┌───────────┐  ┌──────────┐  ┌───────────────┐  │
│  │ AR       │  │ SwiftData │  │ PDF      │  │  Auth         │  │
│  │ Frames   │  │ (Local)   │  │ Generator│  │  (Firebase)   │  │
│  └──────────┘  └───────────┘  └──────────┘  └───────────────┘  │
└──────────────────────────┬───────────────────────────────────────┘
                           │ HTTPS + Firebase Auth Token
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│                    AWS Cloud (Terraform)                          │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │                    ALB (Load Balancer)                     │   │
│  └──────────────────────────┬────────────────────────────────┘   │
│                             ▼                                    │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │              ECS Fargate (Node.js/Express)                │   │
│  │  ┌──────────┐  ┌───────────┐  ┌──────────┐  ┌─────────┐ │   │
│  │  │ Auth     │  │ Estimates │  │ Analysis │  │ Chat    │ │   │
│  │  │Middleware│  │ Routes    │  │ Routes   │  │ WS      │ │   │
│  │  └──────────┘  └───────────┘  └──────────┘  └─────────┘ │   │
│  │  ┌──────────┐  ┌───────────┐  ┌──────────┐  ┌─────────┐ │   │
│  │  │ Assembly │  │ Quantity  │  │ Labor    │  │ Product │ │   │
│  │  │ Engine   │  │ Calculator│  │ Calculator│  │ Catalog │ │   │
│  │  └──────────┘  └───────────┘  └──────────┘  └─────────┘ │   │
│  └──────────────────────────┬────────────────────────────────┘   │
│                             │                                    │
│         ┌───────────────────┼───────────────────┐                │
│         ▼                   ▼                   ▼                │
│  ┌────────────┐    ┌──────────────┐    ┌──────────────┐         │
│  │ RDS        │    │ S3           │    │ Gemini API   │         │
│  │ PostgreSQL │    │ (PDFs/Images)│    │ (1.5 Pro)    │         │
│  └────────────┘    └──────────────┘    └──────────────┘         │
│                                                                  │
│  ┌────────────┐    ┌──────────────┐    ┌──────────────┐         │
│  │ Stripe     │    │ SendGrid     │    │ Firebase     │         │
│  │ (Payments) │    │ (Email)      │    │ (Auth)       │         │
│  └────────────┘    └──────────────┘    └──────────────┘         │
└──────────────────────────────────────────────────────────────────┘
```

### Data Flow: Scan → Estimate

```
1. iOS: User scans room with RoomPlan
   └→ RoomScanner captures walls, floors, doors, windows
   └→ ARCoordinator captures JPEG frames during scan

2. iOS: ScanningService.completeScan()
   └→ Creates RoomScanResult (dimensions + surfaces + frames)
   └→ Stores locally in SwiftData (Room.scanDataJSON)

3. iOS: User taps "Generate Estimate"
   └→ POST /api/v1/estimates with takeoffData
   └→ Auth header: Bearer <firebase-id-token>

4. Backend: estimates.js route handler
   └→ authenticate middleware verifies Firebase token
   └→ assemblyEngine.generateEstimate(takeoffData, jobType, finishLevel, zipCode)
       ├→ quantityCalculator.computeQuantities(assembly, takeoffData)
       ├→ laborCalculator.computeLabor(assemblyItems, takeoffData)
       ├→ productCatalog.resolveItems(assemblyItems, qualityTier)
       └→ Location cost modifiers applied by zipCode

5. Backend: Returns EstimateResponse
   └→ lineItems[], csiDivisions[], grandTotal, metadata

6. iOS: Displays EstimateResultsView
   └→ User can review, edit, chat to modify
   └→ PDFGenerator.generateEstimatePDF() → share/print
```

### Data Flow: Chat Modification

```
1. iOS: User opens ChatView on an estimate
   └→ ChatViewModel connects to backend via WebSocket

2. iOS: User types "Upgrade countertops to granite"
   └→ WS message: { type: "chat", estimateId, message }

3. Backend: Chat handler
   └→ Sends estimate context + user message to Gemini 1.5 Pro
   └→ Gemini returns structured modification
   └→ Assembly engine recalculates affected line items
   └→ WS message back: { type: "chat", response, updatedEstimate }

4. iOS: ChatViewModel receives response
   └→ Appends AI message to chat
   └→ Updates estimate display
```

---

## 5. Database Schema (Complete)

### 5.1 Existing Tables (Keep)

```sql
-- Schema: contractorlens

-- USERS: Firebase Auth handles auth; this table stores app-specific data
CREATE TABLE contractorlens.Users (
    user_id UUID PRIMARY KEY,  -- Firebase UID
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(100),
    company_name VARCHAR(200),
    default_quality_tier VARCHAR(20) DEFAULT 'better',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ITEMS: Individual materials and labor items
CREATE TABLE contractorlens.Items (
    item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    csi_code VARCHAR(20) NOT NULL,
    description VARCHAR(500) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    category VARCHAR(50) NOT NULL,
    subcategory VARCHAR(50),
    quantity_per_unit DECIMAL(10,6),
    quality_tier VARCHAR(20) CHECK (quality_tier IN ('good','better','best')),
    item_type VARCHAR(20) CHECK (item_type IN ('material','labor','equipment')),
    national_average_cost DECIMAL(10,2),
    trade_id UUID REFERENCES Trades(trade_id),
    manufacturer VARCHAR(100),
    model_number VARCHAR(50),
    detailed_description TEXT,
    installation_notes TEXT
);

-- ASSEMBLIES: Grouped renovation packages
CREATE TABLE contractorlens.Assemblies (
    assembly_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL,
    csi_code VARCHAR(20),
    base_unit VARCHAR(20) NOT NULL
);

-- ASSEMBLYITEMS: Junction table (which items in which assemblies)
CREATE TABLE contractorlens.AssemblyItems (
    assembly_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assembly_id UUID REFERENCES Assemblies(assembly_id) ON DELETE CASCADE,
    item_id UUID REFERENCES Items(item_id),
    quantity DECIMAL(10,4) NOT NULL,
    notes TEXT
);

-- TRADES: CSI divisions
CREATE TABLE contractorlens.Trades (
    trade_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    csi_division VARCHAR(10) NOT NULL,
    division_name VARCHAR(100) NOT NULL,
    trade_name VARCHAR(100) NOT NULL,
    sort_order INTEGER,
    typical_crew_size INTEGER,
    base_hourly_rate DECIMAL(6,2)
);

-- LOCATIONCOSTMODIFIERS: Geographic cost multipliers
CREATE TABLE contractorlens.LocationCostModifiers (
    location_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    zip_code VARCHAR(10),
    metro_name VARCHAR(100),
    state_code VARCHAR(2),
    material_modifier DECIMAL(5,3) DEFAULT 1.000,
    labor_modifier DECIMAL(5,3) DEFAULT 1.000,
    effective_date DATE NOT NULL,
    expiry_date DATE,
    cci_index DECIMAL(6,3),
    zip_code_range VARCHAR(20)
);

-- RETAILPRICES: Real-time retail pricing
CREATE TABLE contractorlens.RetailPrices (
    retail_price_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id UUID REFERENCES Items(item_id),
    location_id UUID REFERENCES LocationCostModifiers(location_id),
    retailer VARCHAR(50),
    retail_price DECIMAL(10,2),
    effective_date DATE,
    expiry_date DATE,
    last_scraped TIMESTAMP,
    source_url TEXT
);

-- USERFINISHPREFERENCES: User quality defaults
CREATE TABLE contractorlens.UserFinishPreferences (
    preference_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES Users(user_id),
    category VARCHAR(50),
    preferred_quality_tier VARCHAR(20),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- PROJECTS: Project container
CREATE TABLE contractorlens.Projects (
    project_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES Users(user_id),
    name VARCHAR(200) NOT NULL,
    client_name VARCHAR(200),
    status VARCHAR(20) DEFAULT 'active',
    location_id UUID REFERENCES LocationCostModifiers(location_id),
    zip_code VARCHAR(10),
    created_at TIMESTAMP DEFAULT NOW()
);

-- ESTIMATES: Calculated estimates (JSONB for flexibility)
CREATE TABLE contractorlens.estimates (
    estimate_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES Projects(project_id),
    user_id UUID REFERENCES Users(user_id),
    status VARCHAR(20) DEFAULT 'draft',
    job_type VARCHAR(50),
    finish_level VARCHAR(20),
    zip_code VARCHAR(10),
    takeoff_data JSONB,
    line_items JSONB,
    csi_divisions JSONB,
    subtotal DECIMAL(12,2),
    markup_amount DECIMAL(12,2),
    tax_amount DECIMAL(12,2),
    grand_total DECIMAL(12,2),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ENHANCED_ESTIMATES: AI-enhanced with Gemini analysis
CREATE TABLE contractorlens.enhanced_estimates (
    enhanced_estimate_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    estimate_id UUID REFERENCES estimates(estimate_id),
    ai_analysis JSONB,
    gemini_confidence DECIMAL(5,4),
    room_analysis JSONB,
    assembly_recommendations JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- MATERIALSPECIFICATIONS: Detailed product data
CREATE TABLE contractorlens.MaterialSpecifications (
    spec_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id UUID REFERENCES Items(item_id),
    manufacturer VARCHAR(100),
    model_number VARCHAR(50),
    brand_name VARCHAR(100),
    color_finish VARCHAR(50),
    size_dimensions VARCHAR(100),
    weight DECIMAL(8,2),
    warranty_years INTEGER,
    energy_rating VARCHAR(20),
    compliance_codes TEXT[]
);

-- LABORTASKS: Detailed labor production rates
CREATE TABLE contractorlens.LaborTasks (
    task_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id UUID REFERENCES Items(item_id),
    task_name VARCHAR(200),
    task_description TEXT,
    base_production_rate DECIMAL(10,6),
    crew_size INTEGER DEFAULT 1,
    skill_level VARCHAR(20) CHECK (skill_level IN ('apprentice','journeyman','master')),
    setup_time_hours DECIMAL(4,2),
    cleanup_time_hours DECIMAL(4,2),
    difficulty_multiplier DECIMAL(3,2) DEFAULT 1.0
);

-- WASTEFACTORS: Material waste percentages
CREATE TABLE contractorlens.WasteFactors (
    waste_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id UUID REFERENCES Items(item_id),
    material_type VARCHAR(50),
    base_waste_percentage DECIMAL(5,2),
    cut_waste_percentage DECIMAL(5,2),
    breakage_percentage DECIMAL(5,2),
    pattern_match_percentage DECIMAL(5,2)
);

-- WORKSEQUENCES: Trade dependency logic
CREATE TABLE contractorlens.WorkSequences (
    sequence_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    predecessor_trade_id UUID REFERENCES Trades(trade_id),
    successor_trade_id UUID REFERENCES Trades(trade_id),
    dependency_type VARCHAR(20) CHECK (dependency_type IN ('must_complete','can_overlap')),
    lag_days INTEGER DEFAULT 0
);
```

### 5.2 New Tables (Need to Create)

```sql
-- SUBSCRIPTIONS: Stripe subscription tracking
CREATE TABLE contractorlens.Subscriptions (
    subscription_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES Users(user_id),
    stripe_customer_id VARCHAR(100),
    stripe_subscription_id VARCHAR(100) UNIQUE,
    plan_tier VARCHAR(20) CHECK (plan_tier IN ('starter','pro','pro_plus','enterprise')),
    status VARCHAR(20) DEFAULT 'active',
    current_period_start TIMESTAMP,
    current_period_end TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ESTIMATE_STATUS_HISTORY: Track status transitions
CREATE TABLE contractorlens.EstimateStatusHistory (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    estimate_id UUID REFERENCES estimates(estimate_id),
    from_status VARCHAR(20),
    to_status VARCHAR(20),
    changed_by UUID REFERENCES Users(user_id),
    changed_at TIMESTAMP DEFAULT NOW(),
    notes TEXT
);

-- CHAT_SESSIONS: Chat conversation history
CREATE TABLE contractorlens.ChatSessions (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    estimate_id UUID REFERENCES estimates(estimate_id),
    user_id UUID REFERENCES Users(user_id),
    messages JSONB,  -- Array of {role, content, timestamp}
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### 5.3 Key Indexes (Already Exist in `schemas/indexes.sql`)

All existing indexes are kept. Add these new ones:

```sql
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_subscriptions_user ON Subscriptions(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_subscriptions_stripe ON Subscriptions(stripe_subscription_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_estimates_status ON estimates(status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_estimates_user_status ON estimates(user_id, status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_chat_sessions_estimate ON ChatSessions(estimate_id);
```

### 5.4 Entity Relationship Diagram

```
Users (1) ────── (∞) Projects
Users (1) ────── (∞) Subscriptions
Users (1) ────── (∞) UserFinishPreferences
Users (1) ────── (∞) estimates

Projects (1) ─── (∞) estimates

estimates (1) ── (∞) enhanced_estimates
estimates (1) ── (∞) EstimateStatusHistory
estimates (1) ── (∞) ChatSessions

Trades (1) ───── (∞) Items
Items (∞) ────── (∞) AssemblyItems (∞) ────── (1) Assemblies
Items (1) ────── (∞) RetailPrices
Items (1) ────── (∞) MaterialSpecifications
Items (1) ────── (∞) LaborTasks
Items (1) ────── (∞) WasteFactors

LocationCostModifiers (1) ── (∞) RetailPrices
Trades (1) ──── (∞) WorkSequences (predecessor)
Trades (1) ──── (∞) WorkSequences (successor)
```

---

## 6. API Endpoint List

### 6.1 Authentication

All endpoints except `/health`, `/api/v1`, and `/api/v1/auth/*` require:
```
Authorization: Bearer <firebase-id-token>
```

### 6.2 System Endpoints

| Method | Path | Description | Auth | Request | Response |
|--------|------|-------------|------|---------|----------|
| `GET` | `/health` | Health check | No | — | `{ status, uptime, timestamp }` |
| `GET` | `/api/v1` | API info | No | — | `{ version, endpoints }` |

### 6.3 Auth Endpoints

| Method | Path | Description | Auth | Request | Response |
|--------|------|-------------|------|---------|----------|
| `POST` | `/api/v1/auth/register` | Register user profile | Yes | `{ displayName, companyName? }` | `{ user }` |
| `GET` | `/api/v1/auth/profile` | Get user profile | Yes | — | `{ user, preferences }` |
| `PUT` | `/api/v1/auth/profile` | Update profile | Yes | `{ displayName?, companyName?, defaultQualityTier? }` | `{ user }` |

### 6.4 Estimates Endpoints

| Method | Path | Description | Auth | Request | Response |
|--------|------|-------------|------|---------|----------|
| `POST` | `/api/v1/estimates` | Create estimate from takeoff | Yes | See 6.4.1 | See 6.4.2 |
| `GET` | `/api/v1/estimates` | List user's estimates | Yes | Query: `?page=1&limit=20&status=draft` | `{ estimates[], pagination }` |
| `GET` | `/api/v1/estimates/:id` | Get estimate details | Yes | — | `{ estimate, enhancedAnalysis? }` |
| `PUT` | `/api/v1/estimates/:id/status` | Update status | Yes | `{ status: "approved"\|"invoiced" }` | `{ estimate }` |
| `DELETE` | `/api/v1/estimates/:id` | Delete draft | Yes | — | `{ success }` |
| `GET` | `/api/v1/estimates/:id/pdf` | Download PDF | Yes | — | PDF binary |

#### 6.4.1 POST /api/v1/estimates — Request

```json
{
  "takeoffData": {
    "walls": [{ "area": 90.0, "height": 9.0, "material": "drywall" }],
    "floors": [{ "area": 125.0, "type": "hardwood" }],
    "ceilings": [{ "area": 125.0, "height": 9.0 }],
    "kitchens": [{ "area": 125.0, "cabinetLinearFeet": 22.0 }],
    "doors": [{ "width": 3.0, "height": 7.0, "type": "standard" }],
    "windows": [{ "width": 4.0, "height": 5.0, "type": "standard" }]
  },
  "jobType": "kitchen",
  "finishLevel": "better",
  "zipCode": "60614",
  "projectId": "optional-uuid",
  "notes": "Optional notes"
}
```

#### 6.4.2 POST /api/v1/estimates — Response (201)

```json
{
  "estimateId": "uuid",
  "status": "draft",
  "createdAt": "2026-04-05T14:30:00Z",
  "lineItems": [
    {
      "itemId": "uuid",
      "csiCode": "09 65 00",
      "description": "Luxury Vinyl Plank Flooring",
      "quantity": 131.25,
      "unit": "SF",
      "unitCost": 3.50,
      "totalCost": 459.38,
      "type": "labor",
      "quantityDetails": { "baseQuantity": 125.0, "totalQuantity": 131.25 },
      "laborDetails": { "baseHours": 2.5, "totalHours": 2.63 }
    }
  ],
  "csiDivisions": [
    {
      "csiCode": "09 65 00",
      "divisionName": "Flooring",
      "totalCost": 1245.67,
      "laborHours": 8.5,
      "lineItems": [...]
    }
  ],
  "subtotal": 3574.53,
  "markup": 893.63,
  "tax": 357.45,
  "grandTotal": 4825.61,
  "metadata": {
    "totalLaborHours": 42.5,
    "finishLevel": "better",
    "calculationDate": "2026-04-05T14:30:00Z",
    "engineVersion": "2.0"
  }
}
```

### 6.5 Analysis Endpoints

| Method | Path | Description | Auth | Request | Response |
|--------|------|-------------|------|---------|----------|
| `POST` | `/api/v1/analysis/enhanced-estimate` | AI-enhanced estimate | Yes | `{ enhancedScanData, finishLevel, zipCode, projectId? }` | Estimate + `ai_analysis` |
| `POST` | `/api/v1/analysis/room-analysis` | Analyze images only | Yes | `{ images[], roomContext }` | `{ surfaces, materials, confidence }` |
| `GET` | `/api/v1/analysis/health` | Gemini service health | No | — | `{ status, model }` |

### 6.6 Projects Endpoints (New)

| Method | Path | Description | Auth | Request | Response |
|--------|------|-------------|------|---------|----------|
| `POST` | `/api/v1/projects` | Create project | Yes | `{ name, clientName? }` | `{ project }` |
| `GET` | `/api/v1/projects` | List projects | Yes | Query: `?page=1&limit=20` | `{ projects[], pagination }` |
| `GET` | `/api/v1/projects/:id` | Get project + rooms | Yes | — | `{ project, rooms[] }` |
| `PUT` | `/api/v1/projects/:id` | Update project | Yes | `{ name?, clientName?, status? }` | `{ project }` |
| `DELETE` | `/api/v1/projects/:id` | Delete project | Yes | — | `{ success }` |

### 6.7 Chat Endpoints (New)

| Method | Path | Description | Auth | Protocol |
|--------|------|-------------|------|----------|
| `WS` | `/api/v1/chat/:estimateId` | Real-time chat for estimate modification | Yes (query token) | WebSocket |

**WebSocket Messages (Client → Server):**
```json
{ "type": "chat", "message": "Upgrade countertops to granite", "estimateId": "uuid" }
{ "type": "ping" }
```

**WebSocket Messages (Server → Client):**
```json
{ "type": "chat", "message": "I've updated the countertops to granite...", "updatedEstimate": { ... } }
{ "type": "typing" }
{ "type": "error", "message": "..." }
```

### 6.8 Subscriptions Endpoints (New)

| Method | Path | Description | Auth | Request | Response |
|--------|------|-------------|------|---------|----------|
| `POST` | `/api/v1/subscriptions/create` | Create subscription | Yes | `{ planTier }` | `{ checkoutUrl }` |
| `GET` | `/api/v1/subscriptions/current` | Get current sub | Yes | — | `{ subscription }` |
| `POST` | `/api/v1/subscriptions/portal` | Stripe customer portal | Yes | — | `{ portalUrl }` |
| `POST` | `/api/v1/subscriptions/webhook` | Stripe webhook | Stripe sig | Stripe event | `{ received }` |

### 6.9 Pricing Endpoints (New)

| Method | Path | Description | Auth | Request | Response |
|--------|------|-------------|------|---------|----------|
| `GET` | `/api/v1/pricing/refresh/:itemId` | Refresh item price | Yes | — | `{ itemId, newPrice, source, updatedAt }` |
| `POST` | `/api/v1/pricing/bulk-refresh` | Bulk price refresh | Yes | `{ itemIds[] }` | `{ results[] }` |

---

## 7. Build Plan with Workstreams

### Overview

**Total estimated duration:** 10-14 weeks (with parallel workstreams)
**Team:** Gastown Polecat agents (Tech Lead, iOS, Backend, Database, Infra)

### Workstream Map

```
Week:  1    2    3    4    5    6    7    8    9    10   11   12   13   14
       ├────────────────────────────────────────────────────────────────┤
WS1:   ████████████████████████████████  Backend Core + Auth + Estimates
       ├────────────────────────────────────────────────────────────┤
WS2:   ████████████████████████████  iOS Backend Integration
       ├────────────────────────────────────────────────────┤
WS3:            ████████████████████████████  Chat System (iOS + Backend)
       ├──────────────────────────────────────────┤
WS4:            ██████████████████████████  Stripe Integration
       ├──────────────────────────────────────────────────────────┤
WS5:   ████████████████████████████████████████████  Database Migrations + Seeding
       ├──────────────────────┤
WS6:   ████████████████████  Infrastructure (Terraform + CI/CD)
       ├──────────────────────────────────────────────────────────────────┤
WS7:   ████████████████████████████████████████████████████████████  Testing + QA
       ├──────────────────────────────────────────────────────────────────┤
WS8:            ██████████████████████████████████████████████████  Customer Portal
```

---

### WS1: Backend Core (Weeks 1-8)

**Agent:** Backend Lead
**Complexity:** Very Complex

#### Task 1.1: Wire Auth Middleware to All Routes (Simple, Week 1)
- Apply `authenticate` middleware to `/api/v1/estimates/*`, `/api/v1/analysis/*`
- Add `requireSubscription` middleware for premium endpoints
- **Files:** `src/server.js`, `src/middleware/auth.js`

#### Task 1.2: Complete Estimates CRUD (Complex, Weeks 1-2)
- Implement `POST /api/v1/estimates` — wire existing assemblyEngine
- Implement `GET /api/v1/estimates` — list with pagination, filtering by status
- Implement `GET /api/v1/estimates/:id` — full detail with enhanced analysis
- Implement `PUT /api/v1/estimates/:id/status` — status transitions with history
- Implement `DELETE /api/v1/estimates/:id` — draft-only deletion
- Add request validation with Joi
- **Files:** `src/routes/estimates.js` (rewrite), new `src/routes/projects.js`

#### Task 1.3: Projects CRUD (Medium, Week 2-3)
- `POST/GET/PUT/DELETE /api/v1/projects`
- Sync with Firebase user ID
- Include rooms and estimate counts
- **Files:** new `src/routes/projects.js`

#### Task 1.4: S3 PDF Storage (Medium, Week 3)
- Configure S3 client (`@aws-sdk/client-s3`)
- Generate PDF on estimate creation (server-side using PDFKit)
- Upload to S3, return signed URL
- Cache PDF URL in estimate metadata
- **Files:** new `src/services/pdfGenerator.js`, new `src/services/storage.js`

#### Task 1.5: Enhanced Estimate Endpoint (Complex, Weeks 3-4)
- Harden existing `/api/v1/analysis/enhanced-estimate`
- Add auth, validation, error handling
- Integrate with assemblyEngine for AI-boosted estimates
- Fallback chain: Gemini → basic assembly engine
- **Files:** `src/routes/analysis.js` (modify), `src/services/geminiIntegration.js` (modify)

#### Task 1.6: Chat WebSocket Endpoint (Very Complex, Weeks 4-6)
- Set up WebSocket server alongside Express
- Auth via query parameter token
- Chat session management (create, resume, history)
- Gemini conversation with estimate context
- Structured response parsing (modification commands)
- Assembly engine recalculation on modifications
- Persist chat sessions to DB
- **Files:** new `src/services/chatHandler.js`, new `src/routes/chat.js`

#### Task 1.7: Subscription/Stripe Endpoints (Complex, Weeks 5-7)
- Stripe SDK integration
- Customer creation/management
- Subscription lifecycle (create, upgrade, downgrade, cancel)
- Webhook handler for async events
- Feature gating middleware
- **Files:** new `src/routes/subscriptions.js`, new `src/services/stripeService.js`

#### Task 1.8: Background Jobs (Medium, Week 7-8)
- BullMQ worker for price refresh scraping
- Email notifications (estimate created, status changed)
- Webhook delivery for integrations
- **Files:** new `src/workers/`, new `src/services/emailService.js`

#### Task 1.9: User Registration & Profile (Simple, Week 2)
- `POST /api/v1/auth/register` — create Users row on first Firebase login
- `GET/PUT /api/v1/auth/profile`
- **Files:** new `src/routes/auth.js`

---

### WS2: iOS Backend Integration (Weeks 1-7)

**Agent:** iOS Lead
**Complexity:** Complex

#### Task 2.1: Auth Flow (Simple, Week 1)
- Integrate Firebase Auth SDK (email/password + Google)
- Store ID token, auto-refresh
- Add auth state to App root (ContentView routing)
- Login/Register views
- **Files:** new `Views/LoginView.swift`, `Services/AuthService.swift`

#### Task 2.2: API Client Layer (Medium, Weeks 1-2)
- Rewrite `AssemblyEngineService.swift` as proper API client
- Base URL config (dev/staging/prod)
- Auth header injection
- Error handling, retry logic
- Combine-based request/response pattern
- **Files:** `Services/AssemblyEngineService.swift` (rewrite), new `Services/APIClient.swift`

#### Task 2.3: Estimate Generation Flow (Complex, Weeks 2-4)
- After scan, send takeoffData to `POST /api/v1/estimates`
- Handle loading states, errors, retries
- Parse response into existing `Estimate` model
- Store estimate JSON in SwiftData Room
- **Files:** `ViewModels/EstimateViewModel.swift` (rewrite), `Views/EstimateResultsView.swift` (modify)

#### Task 2.4: Project Sync (Medium, Weeks 3-4)
- Sync local SwiftData projects with backend
- Conflict resolution (local vs remote)
- Offline support: queue operations, sync when online
- **Files:** new `Services/ProjectSyncService.swift`

#### Task 2.5: Chat Integration (Complex, Weeks 4-6)
- Replace `ChatViewModel.swift` with real WebSocket client
- Connect to `WS /api/v1/chat/:estimateId`
- Handle typing indicators, responses, estimate updates
- Parse Gemini-structured responses into estimate modifications
- **Files:** `ViewModels/ChatViewModel.swift` (rewrite), new `Services/ChatWebSocketService.swift`

#### Task 2.6: Subscription UI (Medium, Weeks 5-7)
- Plan selection view
- Stripe Checkout integration (SFSafariViewController)
- Subscription management screen
- Feature gating in UI
- **Files:** new `Views/SubscriptionView.swift`, `ViewModels/SubscriptionViewModel.swift`

#### Task 2.7: PDF Download & Share (Simple, Week 6)
- Download PDF from signed URL
- Share sheet integration
- Cache PDF locally
- **Files:** `Services/PDFGenerator.swift` (modify to support both local + server PDF)

---

### WS3: Chat System (Weeks 3-7)

**Agent:** AI Integration Specialist
**Complexity:** Very Complex

*This workstream runs in parallel with WS1.1.6 and WS2.5 — handles the Gemini conversation logic.*

#### Task 3.1: Gemini Chat Prompt Engineering (Complex, Weeks 3-5)
- Design system prompt with estimate context schema
- Input: estimate JSON + user message
- Output: structured JSON with modifications + natural language response
- Handle edge cases (ambiguous requests, out-of-scope requests)
- **Files:** new `prompts/chat-system.txt`, `src/services/geminiChat.js`

#### Task 3.2: Estimate Modification Parser (Complex, Weeks 4-6)
- Parse Gemini's structured response into assembly engine commands
- Types: update item, add item, remove item, change quality tier, change quantity
- Recalculate affected line items + totals
- Validate modifications (no negative costs, valid CSI codes)
- **Files:** new `src/services/estimateModifier.js`

#### Task 3.3: Chat Session Persistence (Medium, Weeks 5-6)
- Store chat history in ChatSessions table
- Resume previous conversations
- Context window management (last N messages + estimate snapshot)
- **Files:** new `src/services/chatSessionStore.js`

---

### WS4: Stripe Integration (Weeks 3-7)

**Agent:** Payments Specialist
**Complexity:** Complex

#### Task 4.1: Stripe Product/Price Setup (Simple, Week 3)
- Create products in Stripe dashboard
- Define price IDs for Starter/Pro/ProPlus/Enterprise
- Configure webhook endpoint
- **Files:** `stripe-config.json`

#### Task 4.2: Backend Stripe Service (Complex, Weeks 4-6)
- Customer creation/lookup
- Checkout session creation
- Subscription management (create, update, cancel)
- Webhook event handling
- Feature gating middleware
- **Files:** `src/services/stripeService.js`, `src/routes/subscriptions.js`

#### Task 4.3: iOS Stripe Integration (Medium, Weeks 5-7)
- Stripe iOS SDK for Checkout
- Subscription status display
- Plan upgrade/downgrade flow
- Receipt/invoice viewing
- **Files:** iOS `Services/StripeService.swift`, `Views/SubscriptionView.swift`

---

### WS5: Database Migrations + Seeding (Weeks 1-8)

**Agent:** Database Engineer
**Complexity:** Medium

#### Task 5.1: Create Migration V3 — Users + Subscriptions (Simple, Week 1)
- Users table (if not relying on Firebase-only)
- Subscriptions table
- EstimateStatusHistory table
- ChatSessions table
- **Files:** new `database/migrations/V3__add_user_and_subscription_tables.sql`

#### Task 5.2: Verify and Complete Seed Data (Medium, Weeks 1-3)
- Review `seeds/assembly_items.sql` — ensure all assemblies have items
- Review `seeds/labor_tasks.sql` — verify production rates
- Review `seeds/location_modifiers.sql` — ensure geographic coverage
- Add any missing trades from V2 migration
- **Files:** `database/seeds/*.sql` (review + complete)

#### Task 5.3: Create Migration V4 — Indexes + Functions (Simple, Week 4)
- Add new indexes for subscriptions, chat sessions
- Create `calculate_estimate_cost()` PostgreSQL function
- Create `get_assembly_items()` helper function
- **Files:** new `database/migrations/V4__add_new_indexes_and_functions.sql`

#### Task 5.4: Migration Runner (Simple, Week 2)
- Build or integrate a migration runner into backend startup
- Track applied migrations in `schema_migrations` table
- **Files:** new `src/services/migrationRunner.js`

---

### WS6: Infrastructure (Weeks 1-5)

**Agent:** Infrastructure Engineer
**Complexity:** Complex

#### Task 6.1: Terraform Updates (Medium, Weeks 1-3)
- Add S3 bucket for PDFs + images
- Add CloudFront distribution
- Add ECR repository for Docker images
- Update ECS task definition with new env vars (Stripe, S3)
- **Files:** `infrastructure/terraform/main.tf` (modify), new `s3.tf`, `cloudfront.tf`

#### Task 6.2: CI/CD Pipeline (Complex, Weeks 2-4)
- GitHub Actions workflow:
  - Build + test on PR
  - Build Docker image on merge to main
  - Push to ECR
  - Deploy to ECS Fargate
  - Run database migrations
- **Files:** new `.github/workflows/deploy.yml`

#### Task 6.3: Environment Strategy (Medium, Weeks 3-5)
- Dev: docker-compose (local)
- Staging: ECS + RDS (smaller instances)
- Production: ECS + RDS (auto-scaling)
- Separate Stripe keys per environment
- **Files:** new `infrastructure/terraform/staging.tfvars`, `production.tfvars`

#### Task 6.4: Monitoring & Alerting (Medium, Week 4-5)
- CloudWatch dashboards
- Datadog integration
- Error rate alerts
- Response time alerts
- **Files:** new `infrastructure/terraform/cloudwatch.tf`

---

### WS7: Testing + QA (Weeks 1-14, Continuous)

**Agent:** QA Lead
**Complexity:** Complex

#### Task 7.1: Backend Unit Tests (Medium, Weeks 3-6)
- Assembly engine tests
- Quantity calculator tests
- Labor calculator tests
- Estimate modification tests
- **Files:** new `backend/tests/unit/`

#### Task 7.2: Backend Integration Tests (Complex, Weeks 5-8)
- API endpoint tests (supertest)
- Auth flow tests
- Stripe webhook tests
- Database integration tests
- **Files:** new `backend/tests/integration/`

#### Task 7.3: iOS Unit Tests (Medium, Weeks 4-7)
- ViewModel tests
- Estimate model tests
- API client tests
- **Files:** new `ios-app/ContractorLensTests/`

#### Task 7.4: iOS UI Tests (Medium, Weeks 6-9)
- Scan flow tests
- Estimate generation flow
- Chat interaction tests
- **Files:** new `ios-app/ContractorLensUITests/`

#### Task 7.5: Load Testing (Simple, Weeks 8-10)
- k6 scripts for API endpoints
- 100 concurrent users target
- <500ms p95 response time
- **Files:** `backend/src/performance/loadTesting.js` (update)

#### Task 7.6: End-to-End Testing (Complex, Weeks 9-12)
- Full scan → estimate → PDF flow
- Chat modification flow
- Subscription flow
- **Files:** new `e2e/`

---

### WS8: Customer Portal (Weeks 3-13)

**Agent:** Web Developer
**Complexity:** Complex

*Note: The customer portal is a separate web app for contractors' clients to view estimates.*

#### Task 8.1: Portal Scaffold (Simple, Week 3)
- Next.js app setup
- Tailwind CSS
- Firebase Auth (same project)
- **Files:** new `portal/` directory

#### Task 8.2: Estimate View (Complex, Weeks 4-7)
- Read-only estimate display
- CSI division breakdown
- Line item details
- PDF download
- **Files:** new `portal/src/app/estimates/[id]/`

#### Task 8.3: Approval Flow (Medium, Weeks 7-9)
- Approve/reject estimate
- Digital signature
- Status webhook to backend
- **Files:** new `portal/src/app/estimates/[id]/approve`

#### Task 8.4: Invoice View (Medium, Weeks 9-11)
- Stripe invoice display
- Payment status
- Payment link
- **Files:** new `portal/src/app/invoices/`

#### Task 8.5: Auth + Access Control (Simple, Weeks 10-12)
- Magic link access (no account needed for clients)
- Estimate-specific access tokens
- **Files:** new `portal/src/app/access/`

---

### Dependencies Graph

```
WS1.1 (Auth Wiring) ──────→ WS1.2 (Estimates CRUD) ──→ WS1.3 (Projects CRUD)
                                    │                         │
                                    ▼                         ▼
WS2.1 (iOS Auth) ──────→ WS2.2 (API Client) ──────→ WS2.3 (Estimate Flow)
                                    │                         │
                                    ▼                         ▼
                            WS1.6 (Chat WS) ────────→ WS2.5 (iOS Chat)
                                    │
                                    ▼
                            WS3.1 (Gemini Prompts) ──→ WS3.2 (Modification Parser)
                                                            │
                                                            ▼
                                                    WS3.3 (Session Persistence)

WS1.4 (S3 Setup) ──────→ WS1.5 (Enhanced Estimate) ──→ WS1.4 (PDF Storage)

WS4.1 (Stripe Setup) ──→ WS4.2 (Backend Stripe) ────→ WS4.3 (iOS Stripe)
                                │
                                └──────────────────────→ WS1.7 (Sub Endpoints)

WS5.1 (Migrations) ────→ WS1.2 (Estimates CRUD)  [MUST FINISH FIRST]
WS5.2 (Seed Review) ───→ WS1.2 (Estimates CRUD)  [MUST FINISH FIRST]

WS6.1 (Terraform) ─────→ WS6.2 (CI/CD) ──────────→ WS6.3 (Environments)
                                                        │
                                                        ▼
                                                  WS6.4 (Monitoring)

WS7 (Testing) runs continuously alongside all workstreams
```

---

### Critical Path

```
WS5.1 (DB Migrations) → WS1.1 (Auth Wiring) → WS1.2 (Estimates CRUD) → WS2.2 (API Client) → WS2.3 (Estimate Flow) → WS7.5 (Load Testing) → Launch
```

**Estimated critical path duration:** 10 weeks minimum

### Parallel Tracks (can start immediately)

1. **WS6 (Infrastructure)** — Terraform updates, CI/CD, no code dependencies
2. **WS5.1 (DB Migrations)** — just SQL, no code dependencies  
3. **WS4.1 (Stripe Setup)** — Stripe dashboard config, independent
4. **WS3.1 (Gemini Prompts)** — prompt engineering, independent of backend code
5. **WS8.1 (Portal Scaffold)** — separate Next.js app, independent

### Launch Checklist

- [ ] All WS1 tasks complete (backend API)
- [ ] WS2 tasks complete (iOS integration)
- [ ] WS4 tasks complete (Stripe payments)
- [ ] WS6.2 complete (CI/CD pipeline)
- [ ] WS7.5 pass (load testing: <500ms p95, 100 concurrent)
- [ ] WS7.6 pass (end-to-end testing)
- [ ] App Store submission ready
- [ ] Production RDS + ECS deployed via Terraform
- [ ] Stripe products live in production
- [ ] Monitoring + alerting configured
- [ ] Backup + disaster recovery tested

---

### Complexity Ratings Summary

| Task | Complexity | Duration |
|------|-----------|----------|
| WS1.1 Auth Wiring | Simple | 1 week |
| WS1.2 Estimates CRUD | Complex | 2 weeks |
| WS1.3 Projects CRUD | Medium | 1.5 weeks |
| WS1.4 S3 PDF Storage | Medium | 1 week |
| WS1.5 Enhanced Estimate | Complex | 1.5 weeks |
| WS1.6 Chat WebSocket | Very Complex | 2 weeks |
| WS1.7 Stripe Subscriptions | Complex | 2 weeks |
| WS1.8 Background Jobs | Medium | 1 week |
| WS1.9 User Registration | Simple | 0.5 weeks |
| WS2.1 iOS Auth | Simple | 1 week |
| WS2.2 API Client | Medium | 1.5 weeks |
| WS2.3 Estimate Flow | Complex | 2 weeks |
| WS2.4 Project Sync | Medium | 1.5 weeks |
| WS2.5 iOS Chat | Complex | 2 weeks |
| WS2.6 Subscription UI | Medium | 1.5 weeks |
| WS2.7 PDF Download | Simple | 0.5 weeks |
| WS3.1 Gemini Prompts | Complex | 2 weeks |
| WS3.2 Modification Parser | Complex | 2 weeks |
| WS3.3 Session Persistence | Medium | 1 week |
| WS4.1 Stripe Setup | Simple | 0.5 weeks |
| WS4.2 Backend Stripe | Complex | 2 weeks |
| WS4.3 iOS Stripe | Medium | 1.5 weeks |
| WS5.1 DB Migrations | Simple | 0.5 weeks |
| WS5.2 Seed Data | Medium | 1.5 weeks |
| WS5.3 Indexes + Functions | Simple | 0.5 weeks |
| WS5.4 Migration Runner | Simple | 0.5 weeks |
| WS6.1 Terraform | Medium | 1.5 weeks |
| WS6.2 CI/CD | Complex | 2 weeks |
| WS6.3 Environments | Medium | 1.5 weeks |
| WS6.4 Monitoring | Medium | 1 week |
| WS7.1 Backend Unit | Medium | 2 weeks |
| WS7.2 Backend Integration | Complex | 2 weeks |
| WS7.3 iOS Unit | Medium | 1.5 weeks |
| WS7.4 iOS UI | Medium | 1.5 weeks |
| WS7.5 Load Testing | Simple | 1 week |
| WS7.6 E2E Testing | Complex | 2 weeks |
| WS8.1 Portal Scaffold | Simple | 0.5 weeks |
| WS8.2 Estimate View | Complex | 2 weeks |
| WS8.3 Approval Flow | Medium | 1.5 weeks |
| WS8.4 Invoice View | Medium | 1.5 weeks |
| WS8.5 Auth + Access | Simple | 1 week |

---

*This plan is the execution document for Gastown Polecat agents. Each task is scoped to be assignable to a single agent with clear deliverables and file paths. Dependencies are explicit. Parallel tracks maximize throughput.*
