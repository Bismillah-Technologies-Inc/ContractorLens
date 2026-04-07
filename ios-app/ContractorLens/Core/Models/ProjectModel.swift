import Foundation
import SwiftData

@Model
final class Project {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var clientName: String?
    @Relationship(deleteRule: .cascade, inverse: \Room.project) var rooms: [Room]
    
    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), clientName: String? = nil) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.clientName = clientName
        self.rooms = []
    }
}

@Model
final class Room {
    @Attribute(.unique) var id: UUID
    var name: String
    var scopeDescription: String
    var scanDataJSON: Data?  // JSON encoded RoomScanResult
    var estimateJSON: Data?  // JSON encoded Estimate
    var floorArea: Double
    var wallArea: Double
    var ceilingHeight: Double
    var doorCount: Int
    var windowCount: Int
    var capturedImagesJSON: Data?  // JSON encoded [Data] (JPEG data)
    var project: Project?
    
    init(id: UUID = UUID(), 
         name: String = "", 
         scopeDescription: String = "",
         scanData: RoomScanResult? = nil,
         estimate: Estimate? = nil,
         floorArea: Double = 0,
         wallArea: Double = 0,
         ceilingHeight: Double = 0,
         doorCount: Int = 0,
         windowCount: Int = 0,
         capturedImages: [Data]? = nil) {
        self.id = id
        self.name = name
        self.scopeDescription = scopeDescription
        self.floorArea = floorArea
        self.wallArea = wallArea
        self.ceilingHeight = ceilingHeight
        self.doorCount = doorCount
        self.windowCount = windowCount
        
        if let scanData = scanData {
            self.scanDataJSON = try? JSONEncoder().encode(scanData)
        } else {
            self.scanDataJSON = nil
        }
        
        if let estimate = estimate {
            self.estimateJSON = try? JSONEncoder().encode(estimate)
        } else {
            self.estimateJSON = nil
        }
        
        if let capturedImages = capturedImages {
            self.capturedImagesJSON = try? JSONEncoder().encode(capturedImages)
        } else {
            self.capturedImagesJSON = nil
        }
    }
    
    // Helper to decode scan data
    func getScanResult() -> RoomScanResult? {
        guard let data = scanDataJSON else { return nil }
        return try? JSONDecoder().decode(RoomScanResult.self, from: data)
    }
    
    // Helper to encode scan data
    func setScanResult(_ scanResult: RoomScanResult) {
        scanDataJSON = try? JSONEncoder().encode(scanResult)
        // Update derived fields
        floorArea = scanResult.dimensions.area
        wallArea = scanResult.surfaces.filter { $0.type == .wall }.reduce(0) { $0 + $1.area }
        ceilingHeight = scanResult.dimensions.height
        doorCount = scanResult.surfaces.filter { $0.type == .door }.count
        windowCount = scanResult.surfaces.filter { $0.type == .window }.count
    }
    
    // Helper to get estimate
    func getEstimate() -> Estimate? {
        guard let data = estimateJSON else { return nil }
        return try? JSONDecoder().decode(Estimate.self, from: data)
    }
    
    // Helper to set estimate
    func setEstimate(_ estimate: Estimate) {
        estimateJSON = try? JSONEncoder().encode(estimate)
    }
    
    // Helper to get captured images
    func getCapturedImages() -> [Data]? {
        guard let data = capturedImagesJSON else { return nil }
        return try? JSONDecoder().decode([Data].self, from: data)
    }
    
    // Helper to set captured images
    func setCapturedImages(_ images: [Data]) {
        capturedImagesJSON = try? JSONEncoder().encode(images)
    }
}