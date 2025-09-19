
import Foundation

// MARK: - API Request Payloads

/// The main request body for the `enhanced-estimate` endpoint.
struct EnhancedEstimateRequest: Codable {
    let frames: [FramePayload]
    let roomType: String
    let dimensions: RoomDimensionsPayload
    let location: LocationPayload
    let userPreferences: UserPreferencesPayload
}

/// Represents a single image frame sent to the backend.
struct FramePayload: Codable {
    let imageData: String // Base64 encoded image data
    let timestamp: String // ISO 8601 timestamp
    let mimeType: String = "image/jpeg"
}

/// Represents the room's physical dimensions.
struct RoomDimensionsPayload: Codable {
    let length: Double
    let width: Double
    let height: Double
}

/// Represents the job site location.
struct LocationPayload: Codable {
    let zip: String
}

/// Represents the user's desired quality and budget settings.
struct UserPreferencesPayload: Codable {
    let qualityTier: String
    let budget: Double? // Optional budget
}
