# GEMINI.md

## Project Overview

This repository contains the source code for **ContractorLens**, a construction cost estimation tool. The project is composed of three main components:

1.  **Backend:** A Node.js/Express application that provides a RESTful API for managing estimates. It features a deterministic "Assembly Engine" for cost calculations based on structured data from a PostgreSQL database.
2.  **iOS App:** A SwiftUI-based mobile application that allows users to scan rooms using AR (Augmented Reality) to create 3D models and capture takeoff data. It is built with native Apple frameworks and has no third-party dependencies.
3.  **Gemini ML Service:** A Node.js service that acts as a "digital surveyor." It uses Google's Gemini model to analyze images from the AR scans and identify materials and building elements (e.g., "120 SF of drywall," "2 windows"). This service does **not** perform cost estimation; its sole output is a structured JSON list of observed elements.

The overall architecture is designed to separate concerns: the iOS app handles data capture, the Gemini service performs visual analysis to identify *what* needs to be estimated, and the backend's Assembly Engine deterministically calculates the final cost.

## Architecture and Data Flow

The core workflow is implemented with a high degree of correctness, adhering to the best practices of each platform.

1.  **iOS: Scanning & Data Capture:**
    *   The user initiates a scan, which is managed by the `RoomScanner.swift` class. This class correctly implements the `RoomCaptureSessionDelegate` pattern to receive data from Apple's **RoomPlan** framework.
    *   The `ScanningView.swift` uses a `UIViewRepresentable` to correctly bridge the UIKit-based `RoomCaptureView` into the modern **SwiftUI** interface.
    *   The entire UI is built with SwiftUI and follows the MVVM (Model-View-ViewModel) pattern. ViewModels (`@ObservableObject`) use `@Published` properties and the `@MainActor` attribute to ensure thread-safe, reactive UI updates.

2.  **iOS to Backend: API Request:**
    *   Upon scan completion, the `EstimateViewModel.swift` creates a `Codable` Swift struct (`EstimateRequestPayload`). This struct is encoded into a JSON payload, ensuring a type-safe and accurate data contract with the backend.
    *   The payload, containing key image frames (as Base64 strings) and room dimensions, is sent to the **Backend**'s `/generate` endpoint.

3.  **Backend & ML Service: Analysis:**
    *   The **Backend**'s main `server.js` file acts as an orchestrator. It uses a standard middleware pattern (e.g., `helmet`, `cors`, custom auth) in the correct order.
    *   The request is forwarded to the **Gemini ML Service**.
    *   The `analyzer.js` in the ML service correctly uses the `@google/generative-ai` library to create a multimodal request, combining the text-based prompt with the image data.
    *   The ML service returns a structured JSON object to the Backend, containing a list of identified construction assemblies and their quantities (e.g., `[{ "assemblyName": "Ceramic Tile Flooring", "quantity": 120, "unit": "SF" }]`).

4.  **Backend: Estimate Calculation:**
    *   The **Assembly Engine** (`assemblyEngine.js`) receives the structured list from the ML service.
    *   Database connections are managed efficiently and correctly via a single, shared connection pool configured in `config/database.js`, following `node-postgres` best practices.
    *   For each item in the list, the engine queries the PostgreSQL database to find the corresponding assembly and its constituent line items (materials, labor).
    *   The engine calculates the cost for each line item, applies a location-based cost modifier, groups the items by trade, and prepares the final estimate.

5.  **Backend to iOS: API Response:**
    *   The final, detailed estimate is sent back to the iOS app as a single JSON object.
    *   The iOS app's `APIService` decodes this JSON back into its `Codable` `Estimate` structs, and the `EstimateResultsView.swift` reactively updates to display the results.

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
