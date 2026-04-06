import Foundation
import FirebaseAuth
import Combine

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    private init() {
        startAuthStateListener()
    }
    
    func startAuthStateListener() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    struct RegisterRequest: Encodable {
        let displayName: String
    }
    
    struct EmptyResponse: Decodable {}
    
    func signUp(email: String, password: String, displayName: String) async throws {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        
        let changeRequest = authResult.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()
        
        let requestBody = RegisterRequest(displayName: displayName)
        let _: EmptyResponse = try await APIClient.shared.post(path: "/api/v1/auth/register", body: requestBody)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    func currentToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw APIError.unauthorized
        }
        return try await user.getIDToken()
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
