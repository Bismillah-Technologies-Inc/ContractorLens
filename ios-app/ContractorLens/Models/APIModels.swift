
import Foundation

// MARK: - API Request Payloads

// MARK: - API Request Payloads

/// The main request body for the `enhanced-estimate` endpoint.
/// Matches backend expectation: { "enhancedScanData": { ... }, "finishLevel": "...", "zipCode": "..." }
struct EnhancedEstimateRequest: Codable {
    let enhancedScanData: EnhancedScanData
    let finishLevel: String
    let zipCode: String
    let fallbackToBasic: Bool
}

/// The nested object containing all scan-related data.
/// Backend expects snake_case keys (e.g. "scan_id", "room_type").
struct EnhancedScanData: Codable {
    let scanId: String
    let roomType: String
    let dimensions: RoomDimensionsPayload
    let frames: [FramePayload]
    // Optional takeoff data if we have pre-calculated areas
    let takeoffData: TakeoffDataPayload?
    
    enum CodingKeys: String, CodingKey {
        case scanId = "scan_id"
        case roomType = "room_type"
        case dimensions
        case frames
        case takeoffData = "takeoff_data"
    }
}

struct TakeoffDataPayload: Codable {
    // Flexible dictionary to hold "walls", "floors" etc.
    // Simplifying to generic [String: [SurfacePayload]] for flexibility
    // But for strict Codable, we might need specific keys if known.
    // Based on backend README: walls: [{area: ...}], floors: [{area: ...}]
    let walls: [SurfaceArea]
    let floors: [SurfaceArea]
    let ceilings: [SurfaceArea]
}

struct SurfaceArea: Codable {
    let area: Double
    let type: String? // e.g. "drywall", "hardwood"
}

/// Represents a single image frame sent to the backend.
struct FramePayload: Codable {
    let timestamp: String // ISO 8601
    let imageData: String // Base64
    let mimeType: String = "image/jpeg"
    let lightingConditions: String?
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case imageData
        case mimeType
        case lightingConditions = "lighting_conditions"
    }
}

/// Represents the room's physical dimensions.
/// Backend expects "total_area" as well.
struct RoomDimensionsPayload: Codable {
    let length: Double
    let width: Double
    let height: Double
    let totalArea: Double
    
    enum CodingKeys: String, CodingKey {
        case length, width, height
        case totalArea = "total_area"
    }
}

struct LocationPayload: Codable {
    let zip: String
}

struct UserPreferencesPayload: Codable {
    let qualityTier: String
    let budget: Double?
}
