import SwiftUI
import SwiftData
import FirebaseCore

@main
struct ContractorLensApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Project.self, Room.self])
    }
}