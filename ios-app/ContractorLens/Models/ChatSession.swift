import Foundation

struct ChatSession: Codable, Identifiable {
    let id: UUID
    let estimateId: UUID?
    let userId: String
    let title: String?
    let messages: [ChatMessage]?
    let lastMessageAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    struct Create: Codable {
        let estimateId: UUID?
        let title: String?
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "session_id"
        case estimateId = "estimate_id"
        case userId = "user_id"
        case title
        case messages
        case lastMessageAt = "last_message_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}