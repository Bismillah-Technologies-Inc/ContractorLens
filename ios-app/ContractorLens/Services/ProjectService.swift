import Foundation
import Combine

class ProjectService: ObservableObject {
    private let apiClient: APIClient
    
    init(apiClient: APIClient = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    // MARK: - Project CRUD
    
    func createProject(_ request: Project.Create) async throws -> Project {
        return try await apiClient.request(
            path: "projects",
            method: .post,
            body: request
        )
    }
    
    func getProjects(page: Int = 1, limit: Int = 20) async throws -> [Project] {
        let queryParameters = [
            "page": String(page),
            "limit": String(limit)
        ]
        
        return try await apiClient.request(
            path: "projects",
            queryParameters: queryParameters
        )
    }
    
    func getProject(id: UUID) async throws -> Project {
        return try await apiClient.request(
            path: "projects/\(id.uuidString)"
        )
    }
    
    func updateProject(id: UUID, request: Project.Update) async throws -> Project {
        return try await apiClient.request(
            path: "projects/\(id.uuidString)",
            method: .put,
            body: request
        )
    }
    
    func deleteProject(id: UUID) async throws {
        try await apiClient.request(
            path: "projects/\(id.uuidString)",
            method: .delete
        )
    }
    
    // MARK: - Convenience Methods
    
    func archiveProject(_ project: Project) async throws -> Project {
        var updateRequest = Project.Update()
        updateRequest.status = .archived
        return try await updateProject(id: project.id, request: updateRequest)
    }
    
    func completeProject(_ project: Project) async throws -> Project {
        var updateRequest = Project.Update()
        updateRequest.status = .completed
        return try await updateProject(id: project.id, request: updateRequest)
    }
    
    func assignClient(projectId: UUID, clientId: UUID) async throws -> Project {
        var updateRequest = Project.Update()
        updateRequest.clientId = clientId
        return try await updateProject(id: projectId, request: updateRequest)
    }
}