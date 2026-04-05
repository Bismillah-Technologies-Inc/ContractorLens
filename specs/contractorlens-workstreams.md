# ContractorLens — Workstreams, Dependencies & Task Index

**Source:** `agents/output/contractorlens-tech-plan.md`
**Extracted:** April 5, 2026

---

## 1. The 8 Workstreams

### WS1: Backend Core (Weeks 1–8)
**Agent:** Backend Lead | **Complexity:** Very Complex
Auth wiring, estimates CRUD, projects CRUD, S3 PDF storage, enhanced estimates, chat WebSocket, Stripe subscriptions, background jobs, user registration. The backbone of the API layer.

### WS2: iOS Backend Integration (Weeks 1–7)
**Agent:** iOS Lead | **Complexity:** Complex
Auth flow, API client layer, estimate generation flow, project sync, chat integration, subscription UI, PDF download/share. Connects the existing iOS app to the backend.

### WS3: Chat System (Weeks 3–7)
**Agent:** AI Integration Specialist | **Complexity:** Very Complex
Gemini prompt engineering, estimate modification parser, chat session persistence. Runs in parallel with WS1.6 and WS2.5 — handles the Gemini conversation logic.

### WS4: Stripe Integration (Weeks 3–7)
**Agent:** Payments Specialist | **Complexity:** Complex
Stripe product/price setup, backend Stripe service, iOS Stripe integration. End-to-end subscription billing.

### WS5: Database Migrations + Seeding (Weeks 1–8)
**Agent:** Database Engineer | **Complexity:** Medium
New tables (Users, Subscriptions, EstimateStatusHistory, ChatSessions), seed data verification, indexes/functions, migration runner.

### WS6: Infrastructure (Weeks 1–5)
**Agent:** Infrastructure Engineer | **Complexity:** Complex
Terraform updates (S3, CloudFront, ECR), CI/CD pipeline (GitHub Actions → ECS), environment strategy (dev/staging/prod), monitoring & alerting.

### WS7: Testing + QA (Weeks 1–14, Continuous)
**Agent:** QA Lead | **Complexity:** Complex
Backend unit tests, backend integration tests, iOS unit tests, iOS UI tests, load testing, end-to-end testing. Runs continuously alongside all workstreams.

### WS8: Customer Portal (Weeks 3–13)
**Agent:** Web Developer | **Complexity:** Complex
Separate Next.js web app for contractors' clients: estimate view, approval flow with digital signature, invoice view, magic-link auth.

---

## 2. Dependency Graph

```
WS5.1 (DB Migrations) ──→ WS1.1 (Auth Wiring) ──→ WS1.2 (Estimates CRUD) ──→ WS1.3 (Projects CRUD)
                                   │                        │
                                   ▼                        ▼
WS2.1 (iOS Auth) ───────→ WS2.2 (API Client) ────→ WS2.3 (Estimate Flow)
                                   │                        │
                                   ▼                        ▼
                           WS1.6 (Chat WS) ───────→ WS2.5 (iOS Chat)
                                   │
                                   ▼
                           WS3.1 (Gemini Prompts) ──→ WS3.2 (Modification Parser)
                                                           │
                                                           ▼
                                                   WS3.3 (Session Persistence)

WS1.4 (S3 Setup) ───────→ WS1.5 (Enhanced Estimate) ──→ WS1.4 (PDF Storage)

WS4.1 (Stripe Setup) ───→ WS4.2 (Backend Stripe) ────→ WS4.3 (iOS Stripe)
                                │
                                └─────────────────────→ WS1.7 (Sub Endpoints)

WS5.1 (Migrations) ─────→ WS1.2 (Estimates CRUD)  [MUST FINISH FIRST]
WS5.2 (Seed Review) ────→ WS1.2 (Estimates CRUD)  [MUST FINISH FIRST]

WS6.1 (Terraform) ──────→ WS6.2 (CI/CD) ──────────→ WS6.3 (Environments)
                                                       │
                                                       ▼
                                                 WS6.4 (Monitoring)

WS7 (Testing) runs continuously alongside all workstreams
```

---

## 3. Critical Path

```
WS5.1 (DB Migrations)
  → WS1.1 (Auth Wiring)
    → WS1.2 (Estimates CRUD)
      → WS2.2 (API Client)
        → WS2.3 (Estimate Flow)
          → WS7.5 (Load Testing)
            → Launch
```

**Estimated critical path duration:** 10 weeks minimum

### Parallel Tracks (can start immediately, no code dependencies)

| Track | Why Independent |
|-------|----------------|
| WS6 (Infrastructure) | Terraform + CI/CD, no code dependencies |
| WS5.1 (DB Migrations) | Pure SQL, no code dependencies |
| WS4.1 (Stripe Setup) | Stripe dashboard config |
| WS3.1 (Gemini Prompts) | Prompt engineering, independent of backend |
| WS8.1 (Portal Scaffold) | Separate Next.js app |

---

## 4. All 39 Tasks

### WS1: Backend Core

| # | Task | Dependencies |
|---|------|-------------|
| 1.1 | Wire Auth Middleware to All Routes | — |
| 1.2 | Complete Estimates CRUD | WS1.1, WS5.1, WS5.2 |
| 1.3 | Projects CRUD | WS1.2 |
| 1.4 | S3 PDF Storage | — |
| 1.5 | Enhanced Estimate Endpoint | WS1.4 |
| 1.6 | Chat WebSocket Endpoint | WS1.1 |
| 1.7 | Subscription/Stripe Endpoints | WS4.2 |
| 1.8 | Background Jobs | WS1.2 |
| 1.9 | User Registration & Profile | WS1.1 |

### WS2: iOS Backend Integration

| # | Task | Dependencies |
|---|------|-------------|
| 2.1 | Auth Flow (Firebase SDK) | — |
| 2.2 | API Client Layer | WS2.1, WS1.1 |
| 2.3 | Estimate Generation Flow | WS2.2, WS1.2 |
| 2.4 | Project Sync | WS2.2, WS1.3 |
| 2.5 | Chat Integration (WebSocket) | WS2.2, WS1.6, WS3.1 |
| 2.6 | Subscription UI | WS2.2, WS4.2 |
| 2.7 | PDF Download & Share | WS1.4 |

### WS3: Chat System

| # | Task | Dependencies |
|---|------|-------------|
| 3.1 | Gemini Chat Prompt Engineering | — |
| 3.2 | Estimate Modification Parser | WS3.1, WS1.2 |
| 3.3 | Chat Session Persistence | WS3.2, WS5.1 |

### WS4: Stripe Integration

| # | Task | Dependencies |
|---|------|-------------|
| 4.1 | Stripe Product/Price Setup | — |
| 4.2 | Backend Stripe Service | WS4.1, WS1.1 |
| 4.3 | iOS Stripe Integration | WS4.2, WS2.2 |

### WS5: Database Migrations + Seeding

| # | Task | Dependencies |
|---|------|-------------|
| 5.1 | Create Migration V3 — Users + Subscriptions | — |
| 5.2 | Verify and Complete Seed Data | — |
| 5.3 | Create Migration V4 — Indexes + Functions | WS5.1 |
| 5.4 | Migration Runner | — |

### WS6: Infrastructure

| # | Task | Dependencies |
|---|------|-------------|
| 6.1 | Terraform Updates (S3, CloudFront, ECR) | — |
| 6.2 | CI/CD Pipeline (GitHub Actions) | WS6.1 |
| 6.3 | Environment Strategy (dev/staging/prod) | WS6.2 |
| 6.4 | Monitoring & Alerting | WS6.3 |

### WS7: Testing + QA

| # | Task | Dependencies |
|---|------|-------------|
| 7.1 | Backend Unit Tests | WS1.2 |
| 7.2 | Backend Integration Tests | WS1.2, WS1.6 |
| 7.3 | iOS Unit Tests | WS2.2 |
| 7.4 | iOS UI Tests | WS2.3 |
| 7.5 | Load Testing | WS1.2, WS7.1 |
| 7.6 | End-to-End Testing | WS2.3, WS1.6, WS4.3 |

### WS8: Customer Portal

| # | Task | Dependencies |
|---|------|-------------|
| 8.1 | Portal Scaffold (Next.js) | — |
| 8.2 | Estimate View | WS8.1, WS1.2 |
| 8.3 | Approval Flow (Digital Signature) | WS8.2 |
| 8.4 | Invoice View | WS8.3, WS4.2 |
| 8.5 | Auth + Access Control (Magic Links) | WS8.1 |

---

## Quick Reference: Tasks with No Dependencies (Can Start Day 1)

- WS1.1, WS1.4, WS2.1, WS3.1, WS4.1, WS5.1, WS5.2, WS5.4, WS6.1, WS8.1
