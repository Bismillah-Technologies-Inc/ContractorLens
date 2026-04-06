import Foundation

import Foundation

// RoomData is a simplified version of Room for API communication
struct RoomData: Codable, Identifiable {
    let id: String
    let roomType: String
    let dimensions: RoomDimensions
    let surfaces: [Surface]
    let windows: [WindowData]?
    let doors: [DoorData]?
    let fixtures: [FixtureData]?
    let scanData: ScanData?
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        roomType: String,
        dimensions: RoomDimensions,
        surfaces: [Surface] = [],
        windows: [WindowData]? = nil,
        doors: [DoorData]? = nil,
        fixtures: [FixtureData]? = nil,
        scanData: ScanData? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.roomType = roomType
        self.dimensions = dimensions
        self.surfaces = surfaces
        self.windows = windows
        self.doors = doors
        self.fixtures = fixtures
        self.scanData = scanData
        self.createdAt = createdAt
    }
}

struct WindowData: Codable {
    let id: String
    let width: Double
    let height: Double
    let type: String  // "casement", "doubleHung", "sliding", "picture", "bay"
    let material: String?  // "wood", "vinyl", "aluminum", "fiberglass"
    let glassType: String?  // "single", "double", "triple", "lowE"
    let hasTrim: Bool?
    
    init(
        id: String = UUID().uuidString,
        width: Double,
        height: Double,
        type: String,
        material: String? = nil,
        glassType: String? = nil,
        hasTrim: Bool? = nil
    ) {
        self.id = id
        self.width = width
        self.height = height
        self.type = type
        self.material = material
        self.glassType = glassType
        self.hasTrim = hasTrim
    }
    
    var area: Double {
        width * height
    }
}

struct DoorData: Codable {
    let id: String
    let width: Double
    let height: Double
    let type: String  // "interior", "exterior", "pocket", "sliding", "french"
    let material: String?  // "wood", "metal", "fiberglass", "glass"
    let style: String?  // "panel", "flush", "louver", "bifold"
    let hasHardware: Bool?
    
    init(
        id: String = UUID().uuidString,
        width: Double,
        height: Double,
        type: String,
        material: String? = nil,
        style: String? = nil,
        hasHardware: Bool? = nil
    ) {
        self.id = id
        self.width = width
        self.height = height
        self.type = type
        self.material = material
        self.style = style
        self.hasHardware = hasHardware
    }
    
    var area: Double {
        width * height
    }
}

struct FixtureData: Codable {
    let id: String
    let type: String  // "sink", "toilet", "shower", "bathtub", "vanity", "cabinet"
    let subtype: String?  // "dropIn", "undermount", "wallHung", "floorStanding"
    let material: String?  // "porcelain", "ceramic", "fiberglass", "acrylic", "stone"
    let brand: String?
    let model: String?
    let dimensions: FixtureDimensions?
    
    init(
        id: String = UUID().uuidString,
        type: String,
        subtype: String? = nil,
        material: String? = nil,
        brand: String? = nil,
        model: String? = nil,
        dimensions: FixtureDimensions? = nil
    ) {
        self.id = id
        self.type = type
        self.subtype = subtype
        self.material = material
        self.brand = brand
        self.model = model
        self.dimensions = dimensions
    }
}

struct FixtureDimensions: Codable {
    let width: Double?
    let depth: Double?
    let height: Double?
    
    init(width: Double? = nil, depth: Double? = nil, height: Double? = nil) {
        self.width = width
        self.depth = depth
        self.height = height
    }
}

struct ScanData: Codable {
    let scanId: String
    let arSessionData: Data?
    let meshData: Data?
    let quality: String
    let captureDate: Date
    let deviceModel: String
    
    init(
        scanId: String = UUID().uuidString,
        arSessionData: Data? = nil,
        meshData: Data? = nil,
        quality: String = "standard",
        captureDate: Date = Date(),
        deviceModel: String = UIDevice.current.model
    ) {
        self.scanId = scanId
        self.arSessionData = arSessionData
        self.meshData = meshData
        self.quality = quality
        self.captureDate = captureDate
        self.deviceModel = deviceModel
    }
}

// Extension to convert from existing Room model
extension Room {
    func toRoomData() -> RoomData {
        return RoomData(
            id: self.id.uuidString,
            roomType: "unknown", // Default type since Room model doesn't have roomType
            dimensions: self.dimensions,
            surfaces: self.surfaces
        )
    }
}

// Extension to convert from RoomScanResult
extension RoomScanResult {
    func toRoomData() -> RoomData {
        return RoomData(
            id: self.scanId.uuidString,
            roomType: self.roomType.rawValue,
            dimensions: self.dimensions,
            surfaces: self.surfaces,
            scanData: ScanData(
                scanId: self.scanId.uuidString,
                quality: "standard",
                captureDate: Date() // Use current date since scan time not in metadata
            )
        )
    }
}