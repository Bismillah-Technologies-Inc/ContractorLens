import Foundation

/// A service responsible for persisting and retrieving `Project` objects from local storage.
class ProjectPersistenceService {
    
    private let fileManager = FileManager.default
    private var storageURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    enum PersistenceError: Error {
        case directoryCreationError(Error)
        case serializationError(Error)
        case writeError(Error)
        case deserializationError(Error)
        case fileNotFound
    }

    init() {
        // Use a "Projects" directory instead of "PendingScans"
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        storageURL = documentsDirectory.appendingPathComponent("Projects")
        
        // Configure the encoder and decoder once
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
        
        try? createStorageDirectoryIfNeeded()
    }

    private func createStorageDirectoryIfNeeded() throws {
        guard !fileManager.fileExists(atPath: storageURL.path) else { return }
        do {
            try fileManager.createDirectory(at: storageURL, withIntermediateDirectories: true, attributes: nil)
            print("✅ ProjectPersistenceService: Created storage directory at \(storageURL.path)")
        } catch {
            throw PersistenceError.directoryCreationError(error)
        }
    }

    /// Saves a `Project` to a file in the storage directory.
    func save(project: Project) throws {
        let fileURL = storageURL.appendingPathComponent("\(project.id.uuidString).json")
        do {
            let data = try encoder.encode(project)
            try data.write(to: fileURL, options: .atomic)
            print("✅ ProjectPersistenceService: Successfully saved project \(project.name)")
        } catch {
            throw PersistenceError.writeError(error)
        }
    }

    /// Loads all saved `Project` objects.
    func loadProjects() -> [Project] {
        var projects: [Project] = []
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: storageURL, includingPropertiesForKeys: nil)
            for url in fileURLs where url.pathExtension == "json" {
                do {
                    let data = try Data(contentsOf: url)
                    let project = try decoder.decode(Project.self, from: data)
                    projects.append(project)
                } catch {
                    print("⚠️ ProjectPersistenceService: Failed to load or decode project at \(url.path): \(error)")
                }
            }
        } catch {
            print("⚠️ ProjectPersistenceService: Failed to read contents of storage directory: \(error)")
        }
        print("🔵 ProjectPersistenceService: Loaded \(projects.count) projects.")
        return projects.sorted { $0.lastModified > $1.lastModified } // Return most recent first
    }

    /// Deletes a `Project` file.
    func delete(project: Project) throws {
        let fileURL = storageURL.appendingPathComponent("\(project.id.uuidString).json")
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw PersistenceError.fileNotFound
        }
        try fileManager.removeItem(at: fileURL)
        print("🗑️ ProjectPersistenceService: Deleted project \(project.name)")
    }
}