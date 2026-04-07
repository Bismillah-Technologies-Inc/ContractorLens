# GEMINI.md

## Project Overview

This repository contains the source code for **ContractorLens**, a construction cost estimation tool. The project is composed of three main components:

1.  **Backend:** A Node.js/Express application that provides a RESTful API for managing estimates. It features a deterministic "Assembly Engine" for cost calculations based on structured data from a PostgreSQL database.
2.  **iOS App:** A SwiftUI-based mobile application that allows users to scan rooms using AR (Augmented Reality) to create 3D models and capture takeoff data. It is built with native Apple frameworks and has no third-party dependencies.
3.  **Gemini ML Service:** A Node.js service that acts as a "digital surveyor." It uses Google's Gemini model to analyze images from the AR scans and identify materials and building elements (e.g., "120 SF of drywall," "2 windows"). This service does **not** perform cost estimation; its sole output is a structured JSON list of observed elements.

The overall architecture is designed to separate concerns: the iOS app handles data capture, the Gemini service performs visual analysis to identify *what* needs to be estimated, and the backend's Assembly Engine deterministically calculates the final cost.

## Architecture and Data Flow

The core workflow is implemented with a high degree of correctness, adhering to the best practices of each platform. The architecture is now an offline-first, project-based system that ensures data integrity and a smooth user experience.

1.  **iOS: Project Management**:
    *   The app launches to the `ContentView`, which displays a list of saved `Projects`.
    *   Users can create new projects or select an existing one to view its details.

2.  **iOS: Scanning & Data Capture**:
    *   From the `ProjectDetailView`, the user initiates a scan.
    *   The `ScanningView` is presented, which uses a `UIViewRepresentable` to correctly bridge the UIKit-based `RoomCaptureView` into the modern **SwiftUI** interface.
    *   All session management is handled by `RoomCaptureCoordinator`, which serves as the single delegate for the `RoomPlan` session and its underlying `ARSession`.
    *   During the scan, the coordinator intelligently captures high-quality still image frames on a background thread to be used for AI analysis.

3.  **iOS: Offline Caching**:
    *   Upon scan completion, the `RoomCaptureCoordinator` bundles the `CapturedRoom` 3D model data and the captured image stills into a `ScanPackage` object.
    *   This package is added to the current `Project` object, which is then saved to the device's local storage via the `ProjectPersistenceService`.
    *   This offline-first approach prevents data loss and allows the user to complete scans without an active internet connection.

4.  **iOS: Viewing Results**:
    *   The user can navigate from the project list to a `ProjectDetailView` to see all scans for a project.
    *   Tapping a scan opens the `ScanDetailView`, which presents a detailed, contractor-focused report including individual dimensions for each wall, floor, door, and window, as well as a gallery of the captured images.

5.  **Backend & ML Service: Analysis (Conceptual)**:
    *   In a future step, a mechanism will be added to upload the saved `ScanPackage` files to the backend.
    *   The backend will then use the `Gemini ML Service` to analyze the images and the `Assembly Engine` to generate a cost estimate.

## Strategic Position & Implementation Status

### Competitive Landscape

A full analysis of the competitive landscape is available in `docs/COMPETITIVE_AND_TECHNICAL_ANALYSIS.md`. The key takeaways are:
*   Our core "Scan-to-Estimate" workflow is a significant differentiator. Competitors like **Handoff AI** focus on generating project documents from text prompts, not on creating the initial estimate from a 3D scan.
*   The user experience of the **Canvas** app provides a strong model for improving our own scanning workflow with more detailed user guidance.

### Technology Implementation Status

*   **Current State (Level 2):** The system is currently implemented to a **Level 2** granularity. It successfully generates a detailed, line-item estimate based on the Assembly Engine pattern. The current implementation has been verified to be correct and adheres to platform-specific best practices.
*   **Future State (Level 5):** The database schema and calculation logic are foundational. The system does not yet support advanced professional features. A detailed plan to implement these professional-grade features is documented in **`docs/ESTIMATE_GRANULARITY_ROADMAP.md`**.
*   **RoomPlan API Gaps:** Our app correctly uses the core `RoomPlan` API, but does not yet implement advanced features like multi-room scanning or custom 3D asset substitution. These are documented as future opportunities in the analysis file.

## Building and Running

The entire ContractorLens application can be run using Docker Compose.

### Prerequisites

*   Docker and Docker Compose
*   Node.js and npm (for running services individually)
*   An environment file (`.env`) with the necessary credentials for Firebase and Gemini. An example is provided in `.env.example`.

### Running with Docker Compose

To run the entire application, use the following command from the project root:

```bash
docker-compose up -d
```

This will start the following services:

*   `postgres`: The PostgreSQL database.
*   `backend`: The main backend application.
*   `gemini-service`: The Gemini ML service.
*   `nginx`: An Nginx reverse proxy.

### Running Services Individually

#### Backend

To run the backend service individually:

```bash
cd backend
npm install
npm run dev
```

The backend will be available at `http://localhost:3000`.

#### Gemini ML Service

To run the Gemini ML service individually:

```bash
cd ml-services/gemini-service
npm install
npm start
```

The Gemini service will be available at `http://localhost:3001`.

### Testing

#### Backend

To run the backend tests:

```bash
cd backend
node tests/unit.test.js
```

#### Gemini ML Service

To run the Gemini ML service tests:

```bash
cd ml-services/gemini-service
npm test
```
