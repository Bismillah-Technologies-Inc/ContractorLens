import Foundation
import Combine
import SwiftUI

// MARK: - Auth Models

enum AuthError: LocalizedError, Identifiable {
    case invalidCredentials
    case networkError(String)
    case emailAlreadyInUse
    case weakPassword
    case unknown(Error)
    case tokenRefreshFailed
    
    var id: String { localizedDescription }
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .emailAlreadyInUse:
            return "Email already in use"
        case .weakPassword:
            return "Password is too weak"
        case .unknown(let error):
            return "An error occurred: \(error.localizedDescription)"
        case .tokenRefreshFailed:
            return "Failed to refresh authentication token"
        }
    }
}

struct FirebaseUser {
    let uid: String
    let email: String?
    let displayName: String?
    var isEmailVerified: Bool
    
    init(uid: String, email: String? = nil, displayName: String? = nil, isEmailVerified: Bool = false) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.isEmailVerified = isEmailVerified
    }
}

// MARK: - AuthService

class AuthService: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: FirebaseUser?
    @Published var isLoading: Bool = false
    @Published var error: AuthError?
    
    static let shared = AuthService()
    
    private let keychain = KeychainManager.shared
    private var authStateListener: Any? = nil
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Load saved auth state
        loadPersistedAuthState()
        
        // Start listening for auth state changes
        startAuthStateListener()
    }
    
    deinit {
        stopAuthStateListener()
    }
    
    // MARK: - Public API
    
    func signIn(email: String, password: String) async throws -> FirebaseUser {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // In production, this would call Firebase Auth
            // For now, simulate authentication
            guard email.isValidEmail && password.count >= 6 else {
                throw AuthError.invalidCredentials
            }
            
            // Create mock user for development
            let user = FirebaseUser(
                uid: UUID().uuidString,
                email: email,
                displayName: email.components(separatedBy: "@").first?.capitalized,
                isEmailVerified: true
            )
            
            // Save authentication state
            await MainActor.run {
                self.isAuthenticated = true
                self.currentUser = user
                self.error = nil
            }
            
            // Persist to Keychain
            try persistAuthState(user: user)
            
            return user
            
        } catch let authError as AuthError {
            await MainActor.run {
                self.error = authError
            }
            throw authError
        } catch {
            let authError = AuthError.unknown(error)
            await MainActor.run {
                self.error = authError
            }
            throw authError
        }
    }
    
    func signUp(email: String, password: String, displayName: String) async throws -> FirebaseUser {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Validate inputs
            guard email.isValidEmail else {
                throw AuthError.invalidCredentials
            }
            
            guard password.count >= 6 else {
                throw AuthError.weakPassword
            }
            
            // Simulate network delay
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Create mock user for development
            let user = FirebaseUser(
                uid: UUID().uuidString,
                email: email,
                displayName: displayName.isEmpty ? email.components(separatedBy: "@").first?.capitalized : displayName,
                isEmailVerified: false
            )
            
            // Save authentication state
            await MainActor.run {
                self.isAuthenticated = true
                self.currentUser = user
                self.error = nil
            }
            
            // Persist to Keychain
            try persistAuthState(user: user)
            
            // Register with backend API
            try await registerWithBackend(email: email, displayName: displayName, firebaseUID: user.uid)
            
            return user
            
        } catch let authError as AuthError {
            await MainActor.run {
                self.error = authError
            }
            throw authError
        } catch {
            let authError = AuthError.unknown(error)
            await MainActor.run {
                self.error = authError
            }
            throw authError
        }
    }
    
    func signOut() throws {
        // Clear local auth state
        isAuthenticated = false
        currentUser = nil
        
        // Clear Keychain
        try keychain.delete(forKey: "auth_user_id")
        try keychain.delete(forKey: "auth_user_email")
        try keychain.delete(forKey: "auth_user_display_name")
        
        // Clear auth token
        try keychain.delete(forKey: "auth_token")
        
        // Stop listening for auth state changes
        stopAuthStateListener()
        
        // Restart listener for next sign in
        startAuthStateListener()
    }
    
    func currentToken() async throws -> String {
        // Check for existing valid token
        if let token = try? keychain.get(forKey: "auth_token"),
           !token.isEmpty {
            // TODO: In production, check token expiration and refresh if needed
            return token
        }
        
        // No token found or expired
        throw AuthError.tokenRefreshFailed
    }
    
    // MARK: - Auth State Management
    
    func startAuthStateListener() {
        // In production, this would set up Firebase Auth state listener
        // For now, we'll simulate by checking persisted state periodically
        authStateListener = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkAuthState()
            }
    }
    
    func stopAuthStateListener() {
        if let listener = authStateListener {
            // In production, remove Firebase Auth state listener
            // For Timer, invalidate it
            if let timer = listener as? Timer {
                timer.invalidate()
            }
        }
        authStateListener = nil
    }
    
    func loadPersistedAuthState() {
        do {
            if let userId = try? keychain.get(forKey: "auth_user_id"),
               let email = try? keychain.get(forKey: "auth_user_email") {
                
                let displayName = try? keychain.get(forKey: "auth_user_display_name")
                
                let user = FirebaseUser(
                    uid: userId,
                    email: email,
                    displayName: displayName,
                    isEmailVerified: true
                )
                
                // Restore auth state
                isAuthenticated = true
                currentUser = user
            }
        } catch {
            // If we can't load auth state, user is not authenticated
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    private func checkAuthState() {
        // In production, this would verify token validity with Firebase
        // For now, just check if we have persisted state
        if !keychain.exists(forKey: "auth_user_id") {
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    // MARK: - Private Methods
    
    private func persistAuthState(user: FirebaseUser) throws {
        try keychain.save(user.uid, forKey: "auth_user_id")
        if let email = user.email {
            try keychain.save(email, forKey: "auth_user_email")
        }
        if let displayName = user.displayName {
            try keychain.save(displayName, forKey: "auth_user_display_name")
        }
        
        // Generate mock token for development
        let mockToken = "mock_token_\(user.uid)_\(Date().timeIntervalSince1970)"
        try keychain.save(mockToken, forKey: "auth_token")
    }
    
    private func registerWithBackend(email: String, displayName: String, firebaseUID: String) async throws {
        // In production, this would call the backend API
        // POST /api/v1/auth/register with user data
        // For now, simulate API call
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
        
        print("Registered user with backend: email=\(email), displayName=\(displayName), uid=\(firebaseUID)")
    }
    
    // MARK: - Token Refresh
    
    func refreshToken() async throws -> String {
        guard isAuthenticated, let user = currentUser else {
            throw AuthError.tokenRefreshFailed
        }
        
        // In production, this would call Firebase to refresh token
        // For now, generate new mock token
        let newToken = "refreshed_token_\(user.uid)_\(Date().timeIntervalSince1970)"
        try keychain.save(newToken, forKey: "auth_token")
        
        return newToken
    }
    
    // MARK: - Clear All Data
    
    func clearAllAuthData() throws {
        try signOut()
        try keychain.clearAll()
    }
}

// MARK: - Helper Extensions

extension String {
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPredicate.evaluate(with: self)
    }
}

// MARK: - Preview Support

#if DEBUG
extension AuthService {
    static var previewAuthenticated: AuthService {
        let service = AuthService.shared
        service.isAuthenticated = true
        service.currentUser = FirebaseUser(
            uid: "preview_user_123",
            email: "preview@example.com",
            displayName: "Preview User",
            isEmailVerified: true
        )
        return service
    }
    
    static var previewUnauthenticated: AuthService {
        let service = AuthService.shared
        service.isAuthenticated = false
        service.currentUser = nil
        return service
    }
}
#endif