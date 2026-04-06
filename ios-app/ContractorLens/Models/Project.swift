import Foundation

struct Project: Codable, Identifiable {
    let id: UUID
    let userId: String
    let name: String
    let description: String?
    let address: String?
    let zipCode: String?
    let status: ProjectStatus
    let createdAt: Date
    let updatedAt: Date
    
    enum ProjectStatus: String, Codable {
        case active = "active"
        case completed = "completed"
        case archived = "archived"
        case draft = "draft"
    }
    
    struct Create: Codable {
        let name: String
        let description: String?
        let address: String?
        let zipCode: String?
        let clientId: UUID?
    }
    
    struct Update: Codable {
        let name: String?
        let description: String?
        let address: String?
        let zipCode: String?
        let status: ProjectStatus?
        let clientId: UUID?
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "project_id"
        case userId = "user_id"
        case name = "project_name"
        case description
        case address
        case zipCode = "zip_code"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}