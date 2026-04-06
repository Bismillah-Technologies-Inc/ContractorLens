
import Foundation

struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let sessionId: UUID
    let role: MessageRole
    let content: String
    let metadata: ChatMetadata?
    let createdAt: Date
    
    enum MessageRole: String, Codable {
        case user = "user"
        case assistant = "assistant"
        case system = "system"
    }
    
    struct ChatMetadata: Codable {
        let updatedEstimate: Bool?
        let modifications: [String]?
        let confidence: Double?
        
        enum CodingKeys: String, CodingKey {
            case updatedEstimate = "updatedEstimate"
            case modifications
            case confidence
        }
    }
    
    struct Create: Codable {
        let sessionId: UUID
        let content: String
        let role: MessageRole
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "message_id"
        case sessionId = "session_id"
        case role
        case content
        case metadata
        case createdAt = "created_at"
    }
}
