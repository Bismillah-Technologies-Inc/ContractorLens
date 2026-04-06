import Foundation
import Combine

class RoomScanService: ObservableObject {
    private let apiClient: APIClient
    
    init(apiClient: APIClient = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    // MARK: - Room Scan Operations
    
    func uploadRoomScan(projectId: UUID, scanData: RoomScan.ScanData) async throws -> RoomScan {
        let request = RoomScan.Create(projectId: projectId, scanData: scanData)
        return try await apiClient.request(
            path: "rooms/scan",
            method: .post,
            body: request
        )
    }
    
    func getRoomScansForProject(projectId: UUID, page: Int = 1, limit: Int = 20) async throws -> [RoomScan] {
        let queryParameters = [
            "page": String(page),
            "limit": String(limit)
        ]
        
        return try await apiClient.request(
            path: "rooms/project/\(projectId.uuidString)",
            queryParameters: queryParameters
        )
    }
    
    func getRoomScan(id: UUID) async throws -> RoomScan {
        return try await apiClient.request(
            path: "rooms/scan/\(id.uuidString)"
        )
    }
    
    func getRoomScanAnalysis(id: UUID) async throws -> RoomScan.AnalysisResult {
        return try await apiClient.request(
            path: "rooms/scan/\(id.uuidString)/analysis"
        )
    }
    
    func deleteRoomScan(id: UUID) async throws {
        try await apiClient.request(
            path: "rooms/scan/\(id.uuidString)",
            method: .delete
        )
    }
    
    // MARK: - Gemini Integration
    
    func requestGeminiAnalysis(scanId: UUID) async throws -> RoomScan {
        return try await apiClient.request(
            path: "rooms/scan/\(scanId.uuidString)/analyze",
            method: .post
        )
    }
    
    func getProcessingStatus(scanId: UUID) async throws -> RoomScan.ScanStatus {
        struct StatusResponse: Codable {
            let status: RoomScan.ScanStatus
        }
        
        let response: StatusResponse = try await apiClient.request(
            path: "rooms/scan/\(scanId.uuidString)/status"
        )
        
        return response.status
    }
    
    // MARK: - File Upload Helpers
    
    func prepareScanData(
        roomType: String,
        dimensions: RoomScan.ScanData.RoomDimensions,
        surfaces: [RoomScan.ScanData.SurfaceData],
        images: [Data], // JPEG/PNG image data
        metadata: RoomScan.ScanData.ScanMetadata
    ) -> RoomScan.ScanData {
        let base64Images = images.map { $0.base64EncodedString() }
        
        return RoomScan.ScanData(
            roomType: roomType,
            dimensions: dimensions,
            surfaces: surfaces,
            images: base64Images,
            metadata: metadata
        )
    }
}