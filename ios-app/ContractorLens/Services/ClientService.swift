import Foundation
import Combine

class ClientService: ObservableObject {
    private let apiClient: APIClient
    
    init(apiClient: APIClient = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    // MARK: - Client CRUD
    
    func createClient(_ request: Client.Create) async throws -> Client {
        return try await apiClient.request(
            path: "clients",
            method: .post,
            body: request
        )
    }
    
    func getClients(page: Int = 1, limit: Int = 20) async throws -> [Client] {
        let queryParameters = [
            "page": String(page),
            "limit": String(limit)
        ]
        
        return try await apiClient.request(
            path: "clients",
            queryParameters: queryParameters
        )
    }
    
    func getClient(id: UUID) async throws -> Client {
        return try await apiClient.request(
            path: "clients/\(id.uuidString)"
        )
    }
    
    func updateClient(id: UUID, request: Client.Update) async throws -> Client {
        return try await apiClient.request(
            path: "clients/\(id.uuidString)",
            method: .put,
            body: request
        )
    }
    
    // MARK: - Search and Filtering
    
    func searchClients(query: String, page: Int = 1, limit: Int = 20) async throws -> [Client] {
        let queryParameters = [
            "q": query,
            "page": String(page),
            "limit": String(limit)
        ]
        
        return try await apiClient.request(
            path: "clients/search",
            queryParameters: queryParameters
        )
    }
    
    // MARK: - Client Relationships
    
    func getProjectsForClient(clientId: UUID, page: Int = 1, limit: Int = 20) async throws -> [Project] {
        let queryParameters = [
            "page": String(page),
            "limit": String(limit)
        ]
        
        return try await apiClient.request(
            path: "clients/\(clientId.uuidString)/projects",
            queryParameters: queryParameters
        )
    }
    
    func getInvoicesForClient(clientId: UUID, page: Int = 1, limit: Int = 20) async throws -> [Invoice] {
        let queryParameters = [
            "page": String(page),
            "limit": String(limit)
        ]
        
        return try await apiClient.request(
            path: "clients/\(clientId.uuidString)/invoices",
            queryParameters: queryParameters
        )
    }
}