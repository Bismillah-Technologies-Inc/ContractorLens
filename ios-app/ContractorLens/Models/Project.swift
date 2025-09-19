
import Foundation

struct Project: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var lastModified: Date
    var scans: [ScanPackage]
    var coverImage: Data? // Changed to a stored property
    
    init(name: String, scans: [ScanPackage] = []) {
        self.id = UUID()
        self.name = name
        self.scans = scans
        self.lastModified = Date()
        self.coverImage = nil
    }
    
    // Conformance to Hashable based on ID
    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
