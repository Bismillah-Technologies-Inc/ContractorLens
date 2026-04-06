import Foundation

struct RoomScan: Codable, Identifiable {
    let id: UUID
    let projectId: UUID
    let userId: String
    let scanData: ScanData
    let analysisResult: AnalysisResult?
    let status: ScanStatus
    let createdAt: Date
    
    struct ScanData: Codable {
        let roomType: String
        let dimensions: RoomDimensions
        let surfaces: [SurfaceData]
        let images: [String] // Base64 encoded images
        let metadata: ScanMetadata
        
        struct RoomDimensions: Codable {
            let length: Double
            let width: Double
            let height: Double
        }
        
        struct SurfaceData: Codable {
            let type: String // "wall", "floor", "ceiling", "door", "window"
            let area: Double
            let material: String?
            let condition: String?
        }
        
        struct ScanMetadata: Codable {
            let scanDate: Date
            let deviceModel: String?
            let iosVersion: String?
            let appVersion: String?
        }
    }
    
    struct AnalysisResult: Codable {
        let geminiAnalysis: GeminiAnalysis?
        let estimatedCost: Double?
        let materialSuggestions: [MaterialSuggestion]
        let confidenceScore: Double
        
        struct GeminiAnalysis: Codable {
            let surfaces: [AnalyzedSurface]
            let materials: [AnalyzedMaterial]
            let recommendations: [String]
        }
        
        struct AnalyzedSurface: Codable {
            let type: String
            let area: Double
            let condition: String
            let needsReplacement: Bool
        }
        
        struct AnalyzedMaterial: Codable {
            let name: String
            let confidence: Double
            let estimatedCost: Double?
        }
        
        struct MaterialSuggestion: Codable {
            let itemId: UUID
            let name: String
            let quantity: Double
            let unit: String
            let estimatedCost: Double
        }
    }
    
    enum ScanStatus: String, Codable {
        case pending = "pending"
        case processing = "processing"
        case analyzed = "analyzed"
        case failed = "failed"
    }
    
    struct Create: Codable {
        let projectId: UUID
        let scanData: ScanData
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "room_scan_id"
        case projectId = "project_id"
        case userId = "user_id"
        case scanData = "scan_data"
        case analysisResult = "analysis_result"
        case status
        case createdAt = "created_at"
    }
}