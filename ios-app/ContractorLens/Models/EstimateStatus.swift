import Foundation

enum EstimateStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case sent = "sent"
    case accepted = "accepted"
    case rejected = "rejected"
    case archived = "archived"
    
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .sent: return "Sent"
        case .accepted: return "Accepted"
        case .rejected: return "Rejected"
        case .archived: return "Archived"
        }
    }
    
    var isEditable: Bool {
        switch self {
        case .draft: return true
        case .sent: return true // Can be updated before acceptance
        default: return false
        }
    }
    
    var canCalculate: Bool {
        switch self {
        case .draft, .sent: return true
        default: return false
        }
    }
    
    var canSend: Bool {
        switch self {
        case .draft: return true
        default: return false
        }
    }
    
    var canAccept: Bool {
        switch self {
        case .sent: return true
        default: return false
        }
    }
}