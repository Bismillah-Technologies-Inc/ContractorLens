import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum APIError: Error, LocalizedError {
    case unauthorized
    case notFound
    case validationFailed(String)
    case serverError
    case networkError(Error)
    case decodingError(Error)
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Unauthorized access"
        case .notFound: return "Resource not found"
        case .validationFailed(let details): return "Validation failed: \(details)"
        case .serverError: return "Internal server error"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .decodingError(let error): return "Decoding error: \(error.localizedDescription)"
        case .invalidURL: return "Invalid URL"
        }
    }
}

class APIClient {
    static let shared = APIClient()
    
    private let baseURL: URL
    
    private init() {
        #if DEBUG
        self.baseURL = URL(string: "http://localhost:3000")!
        #else
        self.baseURL = URL(string: "https://api.contractorlens.app")!
        #endif
    }
    
    func request<T: Decodable>(
        method: HTTPMethod,
        path: String,
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let token = try await AuthService.shared.currentToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 400, 422:
            let errorMsg = String(data: data, encoding: .utf8) ?? "Validation failed"
            throw APIError.validationFailed(errorMsg)
        default:
            throw APIError.serverError
        }
    }
    
    func get<T: Decodable>(path: String) async throws -> T {
        return try await request(method: .get, path: path)
    }
    
    func post<T: Decodable>(path: String, body: Encodable) async throws -> T {
        return try await request(method: .post, path: path, body: body)
    }
    
    func put<T: Decodable>(path: String, body: Encodable) async throws -> T {
        return try await request(method: .put, path: path, body: body)
    }
    
    func delete(path: String) async throws {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.delete.rawValue
        
        let token = try await AuthService.shared.currentToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw APIError.serverError
        }
    }
}
