import Foundation

struct Client: Codable, Identifiable {
    let id: UUID
    let contractorUserId: String
    let name: String
    let email: String?
    let phone: String?
    let address: String?
    let createdAt: Date
    let updatedAt: Date
    
    struct Create: Codable {
        let name: String
        let email: String?
        let phone: String?
        let address: String?
    }
    
    struct Update: Codable {
        let name: String?
        let email: String?
        let phone: String?
        let address: String?
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "client_id"
        case contractorUserId = "contractor_user_id"
        case name
        case email
        case phone
        case address
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}