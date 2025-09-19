
import Foundation

/// Provides a centralized way to manage environment-specific configurations.
enum Configuration {
    
    /// The base URL for the ContractorLens backend API.
    static var baseURL: String = {
        #if DEBUG
        // Use the local server for debug builds.
        return "http://localhost:3000/api/v1"
        #else
        // Use the production server for release (Beta/App Store) builds.
        // TODO: Replace with your actual production Cloud Run URL.
        return "https://your-production-url.a.run.app/api/v1"
        #endif
    }()
    
    /// A flag indicating if the app is running in a production environment.
    static var isProduction: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }
}
