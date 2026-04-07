
import Foundation
import Combine
import RoomPlan
import OSLog

@MainActor
class AssemblyEngineService: ObservableObject {
    
    @Published var lastEstimate: Estimate?
    @Published var error: ServiceError?
    
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.contractorlens.app", category: "AssemblyEngineService")

    enum ServiceError: LocalizedError, Identifiable {
        case networkError(String)
        case serverError(Int, String)
        case decodingError(String)
        case invalidData(String)
        
        var id: String { localizedDescription }
        
        var errorDescription: String? {
            switch self {
            case .networkError(let message):
                return "Network Error: \(message)"
            case .serverError(let code, let message):
                return "Server Error (\(code)): \(message)"
            case .decodingError(let message):
                return "Failed to process server response: \(message)"
            case .invalidData(let message):
                return "Invalid data provided: \(message)"
            }
        }
    }
    
    func generateEnhancedEstimate(
        scanPackage: ScanPackage,
        roomType: RoomType,
        userPreferences: UserPreferences,
        location: LocationData
    ) -> AnyPublisher<Estimate, ServiceError> {
        
        let urlString = "\(Configuration.baseURL)/analysis/enhanced-estimate"
        guard let url = URL(string: urlString) else {
            self.logger.error("Invalid URL: \(urlString)")
            return Fail(error: ServiceError.invalidData("The server URL is invalid."))
                .eraseToAnyPublisher()
        }
        
        self.logger.info("Starting enhanced estimate generation for project: \(scanPackage.projectName)")
        
        let requestPayload: EnhancedEstimateRequest
        do {
            requestPayload = try translateScanPackage(scanPackage, roomType: roomType, userPreferences: userPreferences, location: location)
        } catch let error as ServiceError {
            self.logger.error("Failed to translate ScanPackage: \(error.localizedDescription)")
            return Fail(error: error).eraseToAnyPublisher()
        } catch {
            self.logger.error("An unexpected error occurred during payload creation: \(error.localizedDescription)")
            return Fail(error: ServiceError.invalidData("Could not prepare data for the server.")).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(requestPayload)
        } catch {
            self.logger.error("Failed to encode request payload: \(error.localizedDescription)")
            return Fail(error: ServiceError.invalidData("Failed to encode request data.")).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ServiceError.networkError("Invalid response from server.")
                }
                
                self.logger.info("Received HTTP status code: \(httpResponse.statusCode)")
                
                if (200..<300).contains(httpResponse.statusCode) {
                    return data
                } else {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "No error message"
                    self.logger.error("Server returned error: \(httpResponse.statusCode) - \(errorMessage)")
                    throw ServiceError.serverError(httpResponse.statusCode, errorMessage)
                }
            }
            .decode(type: Estimate.self, decoder: JSONDecoder())
            .mapError { error -> ServiceError in
                if let serviceError = error as? ServiceError {
                    return serviceError
                } else if let decodingError = error as? DecodingError {
                    self.logger.error("Decoding error: \(decodingError.localizedDescription)")
                    return .decodingError(decodingError.localizedDescription)
                } else {
                    self.logger.error("Network request failed: \(error.localizedDescription)")
                    return .networkError(error.localizedDescription)
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private func translateScanPackage(
        _ scanPackage: ScanPackage,
        roomType: RoomType,
        userPreferences: UserPreferences,
        location: LocationData
    ) throws -> EnhancedEstimateRequest {
        
        // 1. Prepare Frames
        let framePayloads = scanPackage.capturedFrames.map {
            FramePayload(
                timestamp: ISO8601DateFormatter().string(from: Date()), // Ideally use actual capture time if available
                imageData: $0.base64EncodedString(),
                lightingConditions: nil // Capture lighting if available in metadata
            )
        }
        
        guard !framePayloads.isEmpty else {
            throw ServiceError.invalidData("Scan package contains no image frames.")
        }
        
        // 2. Prepare Dimensions & Takeoff Data
        let dimensions = calculateDimensions(from: scanPackage.capturedRoom)
        let totalArea = dimensions.length * dimensions.width // Simple floor area approximation
        
        let dimensionsPayload = RoomDimensionsPayload(
            length: dimensions.length,
            width: dimensions.width,
            height: dimensions.height,
            totalArea: totalArea
        )
        
        // 3. Prepare EnhancedScanData (Nested Object)
        let enhancedScanData = EnhancedScanData(
            scanId: scanPackage.id.uuidString,
            roomType: roomType.rawValue,
            dimensions: dimensionsPayload,
            frames: framePayloads,
            takeoffData: nil // TODO: Populate from RoomPlan surface data if needed for higher precision
        )
        
        // 4. Construct Final Request
        // Map "qualityTier" (good/better/best) to "finishLevel" as expected by backend
        return EnhancedEstimateRequest(
            enhancedScanData: enhancedScanData,
            finishLevel: userPreferences.qualityTier,
            zipCode: location.zipCode,
            fallbackToBasic: true
        )
    }

    private func calculateDimensions(from room: CapturedRoom) -> (length: Double, width: Double, height: Double) {
        let allSurfaces = room.walls + room.floors
        guard !allSurfaces.isEmpty else { return (0, 0, 0) }

        var minPoint = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
        var maxPoint = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)

        for surface in allSurfaces {
            let transform = surface.transform
            let dimensions = surface.dimensions

            let halfDimensions = dimensions / 2.0
            let center = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)

            minPoint.x = min(minPoint.x, center.x - halfDimensions.x)
            minPoint.y = min(minPoint.y, center.y - halfDimensions.y)
            minPoint.z = min(minPoint.z, center.z - halfDimensions.z)

            maxPoint.x = max(maxPoint.x, center.x + halfDimensions.x)
            maxPoint.y = max(maxPoint.y, center.y + halfDimensions.y)
            maxPoint.z = max(maxPoint.z, center.z + halfDimensions.z)
        }

        let size = maxPoint - minPoint
        return (length: Double(size.x), width: Double(size.z), height: Double(size.y))
    }
}
