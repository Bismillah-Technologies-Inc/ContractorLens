import SwiftUI
import SwiftData

@main
struct ContractorLensApp: App {
    @StateObject private var authService = AuthService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
        }
        .modelContainer(for: [Project.self, Room.self])
    }
}