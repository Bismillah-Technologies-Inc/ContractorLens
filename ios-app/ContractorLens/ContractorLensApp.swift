import SwiftUI
import SwiftData

@main
struct ContractorLensApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Project.self, Room.self])
    }
}