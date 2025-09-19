
import Foundation
import RoomPlan

/// A codable package containing all the data from a single room scan session.
struct ScanPackage: Codable {
    let id: UUID
    let projectName: String
    let timestamp: Date
    
    /// The raw `CapturedRoom` object from the RoomPlan session.
    /// This object contains the 3D model, dimensions, and surface information.
    let capturedRoom: CapturedRoom
    
    /// An array of still image frames captured during the scan for AI analysis.
    let capturedFrames: [Data]
    
    /// The status of this scan package, indicating whether it's pending upload.
    var status: Status = .pendingUpload
    
    enum Status: String, Codable {
        case pendingUpload
        case uploaded
        case failed
    }
    
    init(projectName: String, capturedRoom: CapturedRoom, capturedFrames: [Data]) {
        self.id = UUID()
        self.projectName = projectName
        self.timestamp = Date()
        self.capturedRoom = capturedRoom
        self.capturedFrames = capturedFrames
    }
}

// MARK: - Hashable Conformance
extension ScanPackage: Hashable {
    static func == (lhs: ScanPackage, rhs: ScanPackage) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
