import SwiftUI

struct RegisterView: View {
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Name", text: $displayName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: register) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Register")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .disabled(isLoading || email.isEmpty || password.isEmpty || displayName.isEmpty)
        }
        .padding()
        .navigationTitle("Create Account")
    }
    
    private func register() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.signUp(email: email, password: password, displayName: displayName)
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

#Preview {
    RegisterView()
}
