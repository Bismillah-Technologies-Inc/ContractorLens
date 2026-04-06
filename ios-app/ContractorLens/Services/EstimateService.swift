import Foundation
import Combine

class EstimateService: ObservableObject {
    @Published var isLoading = false
    @Published var error: ServiceError?
    @Published var errorMessage: String?
    
    private let baseURL: URL
    private let session = URLSession.shared
    
    init(baseURL: URL? = nil) {
        #if DEBUG
        self.baseURL = baseURL ?? URL(string: "http://localhost:3000")!
        #else
        self.baseURL = baseURL ?? URL(string: "https://api.contractorlens.app")!
        #endif
    }
    
    enum ServiceError: LocalizedError, Identifiable {
        case networkError(String)
        case serverError(Int, String)
        case decodingError
        case invalidRequest
        case unauthorized
        case notFound
        case validationFailed(String)
        
        var id: String { localizedDescription }
        
        var errorDescription: String? {
            switch self {
            case .networkError(let message):
                return "Network Error: \(message)"
            case .serverError(let code, let message):
                return "Server Error (\(code)): \(message)"
            case .decodingError:
                return "Failed to process server response"
            case .invalidRequest:
                return "Invalid request data"
            case .unauthorized:
                return "You need to sign in to perform this action"
            case .notFound:
                return "Estimate not found"
            case .validationFailed(let details):
                return "Validation failed: \(details)"
            }
        }
    }
    
    // MARK: - Public API Methods
    
    func createEstimate(projectId: String, rooms: [RoomData], notes: String? = nil) async throws -> Estimate {
        guard let url = URL(string: "\(baseURL)/estimates") else {
            throw ServiceError.invalidRequest
        }
        
        let requestBody = CreateEstimateRequest(projectId: projectId, rooms: rooms, notes: notes)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw ServiceError.invalidRequest
        }
        
        return try await performRequest(request, responseType: Estimate.self)
    }
    
    func getEstimate(id: String) async throws -> Estimate {
        guard let url = URL(string: "\(baseURL)/estimates/\(id)") else {
            throw ServiceError.invalidRequest
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        return try await performRequest(request, responseType: Estimate.self)
    }
    
    func calculateEstimate(id: String) async throws -> CalculatedEstimate {
        guard let url = URL(string: "\(baseURL)/estimates/\(id)/calculate") else {
            throw ServiceError.invalidRequest
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Empty body for calculation trigger
        request.httpBody = try JSONEncoder().encode([:])
        
        return try await performRequest(request, responseType: CalculatedEstimate.self)
    }
    
    func updateStatus(id: String, status: EstimateStatus) async throws {
        guard let url = URL(string: "\(baseURL)/estimates/\(id)/status") else {
            throw ServiceError.invalidRequest
        }
        
        let requestBody = UpdateEstimateStatusRequest(status: status.rawValue)
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw ServiceError.invalidRequest
        }
        
        // This endpoint returns no content on success
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.networkError("Invalid response")
        }
        
        guard httpResponse.statusCode < 400 else {
            let errorMessage = await extractErrorMessage(from: response, statusCode: httpResponse.statusCode)
            throw mapHTTPError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
    }
    
    func getEstimatesForProject(projectId: String) async throws -> [Estimate] {
        guard let url = URL(string: "\(baseURL)/estimates/project/\(projectId)") else {
            throw ServiceError.invalidRequest
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        return try await performRequest(request, responseType: [Estimate].self)
    }
    
    // MARK: - Private Helper Methods
    
    private func performRequest<T: Decodable>(_ request: URLRequest, responseType: T.Type) async throws -> T {
        isLoading = true
        defer { isLoading = false }
        
        error = nil
        errorMessage = nil
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.networkError("Invalid response")
        }
        
        guard httpResponse.statusCode < 400 else {
            let errorMessage = extractErrorMessage(from: data)
            throw mapHTTPError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            if error is DecodingError {
                throw ServiceError.decodingError
            }
            throw ServiceError.networkError(error.localizedDescription)
        }
    }
    
    private func extractErrorMessage(from data: Data) -> String {
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            return errorResponse.message
        }
        
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = jsonObject["message"] as? String {
            return message
        }
        
        return String(data: data, encoding: .utf8) ?? "Unknown error"
    }
    
    private func extractErrorMessage(from response: URLResponse, statusCode: Int) async -> String {
        return "HTTP \(statusCode)"
    }
    
    private func mapHTTPError(statusCode: Int, message: String) -> ServiceError {
        switch statusCode {
        case 400:
            return .validationFailed(message)
        case 401, 403:
            return .unauthorized
        case 404:
            return .notFound
        case 422:
            return .validationFailed(message)
        case 500...599:
            return .serverError(statusCode, message)
        default:
            return .serverError(statusCode, message)
        }
    }
}

// MARK: - Error Response Model

struct ErrorResponse: Codable {
    let message: String
    let code: String?
    let details: [String]?
    
    enum CodingKeys: String, CodingKey {
        case message, code, details
    }
}

// MARK: - Mock Data for Preview/Testing

extension EstimateService {
    static var mock: EstimateService {
        let service = EstimateService()
        return service
    }
    
    func getMockEstimate() -> Estimate {
        return Estimate(
            estimateId: "est_12345",
            projectId: "proj_67890",
            createdBy: "user_123",
            createdAt: Date(),
            updatedAt: Date(),
            status: "draft",
            totalAmount: 12500.00,
            rawRoomData: nil,
            calculatedComponents: nil,
            notes: "Initial estimate for kitchen remodel"
        )
    }
    
    func getMockCalculatedEstimate() -> CalculatedEstimate {
        let breakdown = CalculationBreakdown(
            materialCost: 5500.00,
            laborCost: 4200.00,
            equipmentCost: 800.00,
            subcontractorCost: 1200.00,
            markup: 600.00,
            tax: 450.00,
            profitMargin: 0.20,
            overhead: 0.15
        )
        
        let materialComponent = CalculationComponent(
            id: "comp_1",
            type: "material",
            category: "Flooring",
            description: "Hardwood flooring",
            quantity: 350.0,
            unit: "sq ft",
            unitCost: 8.50,
            totalCost: 2975.00,
            calculationDetails: CalculationDetails(
                assemblyId: "asm_floor_1",
                csiDivision: "09 60 00",
                materialSpecs: MaterialSpecs(
                    brand: "Bruce",
                    model: "Prestige",
                    color: "Natural",
                    finish: "Satin",
                    size: "3/4\" x 3 1/4\"",
                    grade: "Select",
                    manufacturer: "Bruce Hardwood Floors"
                ),
                laborDetails: nil,
                equipmentDetails: nil
            )
        )
        
        let laborComponent = CalculationComponent(
            id: "comp_2",
            type: "labor",
            category: "Installation",
            description: "Hardwood floor installation",
            quantity: 350.0,
            unit: "sq ft",
            unitCost: 3.50,
            totalCost: 1225.00,
            calculationDetails: CalculationDetails(
                assemblyId: "asm_floor_1",
                csiDivision: "09 60 00",
                materialSpecs: nil,
                laborDetails: LaborCalculationDetails(
                    hoursPerUnit: 0.25,
                    crewSize: 2,
                    skillLevel: "Journeyman",
                    laborRate: 35.00,
                    overtimeFactor: nil
                ),
                equipmentDetails: nil
            )
        )
        
        return CalculatedEstimate(
            estimateId: "est_12345",
            calculationId: "calc_67890",
            calculatedAt: Date(),
            totalAmount: 12500.00,
            breakdown: breakdown,
            components: [materialComponent, laborComponent]
        )
    }
}