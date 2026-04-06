
import Foundation

struct Estimate: Identifiable, Codable {
    let estimateId: String
    let projectId: String
    let createdBy: String
    let createdAt: Date
    let updatedAt: Date
    let status: String
    let totalAmount: Double?
    let rawRoomData: String?  // JSON string of room data
    let calculatedComponents: String?  // JSON string of calculated components
    let notes: String?
    
    var id: String { estimateId }
    
    enum CodingKeys: String, CodingKey {
        case estimateId = "estimate_id"
        case projectId = "project_id"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case status = "status"
        case totalAmount = "total_amount"
        case rawRoomData = "raw_room_data"
        case calculatedComponents = "calculated_components"
        case notes = "notes"
    }
    
    init(
        estimateId: String,
        projectId: String,
        createdBy: String,
        createdAt: Date,
        updatedAt: Date,
        status: String,
        totalAmount: Double? = nil,
        rawRoomData: String? = nil,
        calculatedComponents: String? = nil,
        notes: String? = nil
    ) {
        self.estimateId = estimateId
        self.projectId = projectId
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.status = status
        self.totalAmount = totalAmount
        self.rawRoomData = rawRoomData
        self.calculatedComponents = calculatedComponents
        self.notes = notes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        estimateId = try container.decode(String.self, forKey: .estimateId)
        projectId = try container.decode(String.self, forKey: .projectId)
        createdBy = try container.decode(String.self, forKey: .createdBy)
        
        // Handle date parsing
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        createdAt = dateFormatter.date(from: createdAtString) ?? Date()
        updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()
        
        status = try container.decode(String.self, forKey: .status)
        totalAmount = try container.decodeIfPresent(Double.self, forKey: .totalAmount)
        rawRoomData = try container.decodeIfPresent(String.self, forKey: .rawRoomData)
        calculatedComponents = try container.decodeIfPresent(String.self, forKey: .calculatedComponents)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(estimateId, forKey: .estimateId)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(createdBy, forKey: .createdBy)
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
        
        try container.encode(status, forKey: .status)
        try container.encode(totalAmount, forKey: .totalAmount)
        try container.encode(rawRoomData, forKey: .rawRoomData)
        try container.encode(calculatedComponents, forKey: .calculatedComponents)
        try container.encode(notes, forKey: .notes)
    }
}

// MARK: - Request models

struct CreateEstimateRequest: Codable {
    let projectId: String
    let rooms: [RoomData]
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case rooms = "rooms"
        case notes = "notes"
    }
}

struct UpdateEstimateStatusRequest: Codable {
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case status = "status"
    }
}
