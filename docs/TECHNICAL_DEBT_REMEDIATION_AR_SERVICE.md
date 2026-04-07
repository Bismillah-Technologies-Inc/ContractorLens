
# Technical Debt Remediation: AR Session Management & Offline Caching

**Date:** 2025-09-16

## 1. Summary

This document outlines the remediation of a critical architectural flaw in the iOS application's Augmented Reality (AR) module. The primary issue was a conflict between multiple AR session managers that caused rendering failures and crashes. The fix involved consolidating AR logic into a single coordinator, removing the conflicting code, and implementing a robust offline-caching mechanism to prevent data loss.

## 2. Identified Issues

The application suffered from several critical issues:

1.  **Conflicting AR Sessions**: The app was simultaneously running two separate `ARSession` instances. One was correctly managed by the `RoomPlan` framework's `RoomCaptureView`, while a second, conflicting session was being managed by a legacy `ARService`.
2.  **Rendering Crashes**: During the scan, the UI would go black and become unresponsive. Logs revealed repeated `[CAMetalLayer nextDrawable] returning nil because allocation failed` errors, indicating the rendering engine was not receiving a video feed.
3.  **Lack of Offline Support**: The previous architecture attempted to send scan data to a backend immediately upon completion. This would result in a crash or data loss if a network connection was unavailable.
4.  **Misplaced Feature Logic**: The logic for capturing still images for Gemini analysis was located in the incorrect, conflicting `ARFrameCaptureService` and was therefore non-functional.

## 3. Analysis and Diagnosis

The root cause of the instability and crashes was a resource conflict. A device's camera and AR sensors can only be controlled by one `ARSession` at a time. By instantiating a separate `ARService` in addition to the `RoomCaptureView`'s own session, the app created a race condition where the two sessions fought for control. This starved the `RoomCaptureView` of the data it needed to render, causing the Metal layer to fail and the app to crash.

The architecture violated Apple's recommended design pattern for `RoomPlan`, which encapsulates all session management within the `RoomCaptureView` and its delegates.

## 4. Implemented Solution

A three-phase plan was executed to resolve these issues and improve the app's robustness.

### Phase 1: Remove the Conflicting AR Session

The top priority was to eliminate the source of the conflict.

-   **Removed `ARService` Instantiation**: The `@StateObject private var arService = ARService()` line and the associated `.environmentObject(arService)` modifier were removed from `ContentView.swift`.
-   **Deleted `ARService.swift`**: The file `ios-app/ContractorLens/Services/ARService.swift` was deleted from the project, as it was entirely redundant and harmful.

### Phase 2: Consolidate AR Logic into a Single Coordinator

All AR-related logic was centralized into the correct delegate, `RoomCaptureCoordinator`.

-   **Merged Frame Capture Logic**: The intelligent frame-capture and image-processing methods from the old `ARFrameCaptureService.swift` were moved directly into `RoomCaptureCoordinator` in `ScanningView.swift`.
-   **Enabled Frame Updates**: The coordinator was made an `ARSessionDelegate`, and its delegate was set on the `RoomCaptureView`'s underlying `arSession`. This enabled it to receive live `ARFrame` updates during the scan.
-   **Deleted `ARFrameCaptureService.swift`**: With its useful logic migrated, this file was deleted.

### Phase 3: Implement Offline Caching and Data Persistence

To prevent data loss and crashes when the network is unavailable, an offline-first persistence layer was added.

-   **Created `ScanPackage` Model**: A new `Codable` struct, `ScanPackage`, was created in `Models/ScanPackage.swift`. This struct acts as a container for all data from a scan session, including the `CapturedRoom` 3D model and the array of `Data` for the captured image stills.
-   **Created `ScanPersistenceService`**: A new service, `ScanPersistenceService.swift`, was created to handle the saving and loading of `ScanPackage` objects to the device's local file system as JSON files.
-   **Updated Post-Scan Workflow**: When a scan now finishes, the `RoomCaptureCoordinator` bundles the data into a `ScanPackage` and uses the `ScanPersistenceService` to save it to disk instead of attempting a network call.
-   **Adapted UI for Offline State**: `EstimateResultsView.swift` was refactored to no longer require a live network estimate. It now displays a simple confirmation that the scan was saved successfully, ensuring a smooth user experience without crashes.

## 5. Final Architecture

The new, corrected data flow is as follows:

1.  The user initiates a scan from `ContentView`.
2.  `ScanningView` is presented, containing the `RoomCaptureView`.
3.  The `RoomCaptureCoordinator` manages the single, unified `RoomPlan` session, capturing both the 3D model and the image stills for Gemini.
4.  When the scan is complete, the coordinator bundles the data into a `ScanPackage`.
5.  The `ScanPersistenceService` saves the package to the device's local storage.
6.  The UI dismisses the scanning view and shows a confirmation, ensuring no data is lost.

This architecture is now stable, robust, and correctly aligned with Apple's frameworks.
