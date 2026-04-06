import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showRegister = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("ContractorLens")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
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
                
                Button(action: login) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                
                NavigationLink("Don't have an account? Register", destination: RegisterView(), isActive: $showRegister)
                    .padding(.top)
            }
            .padding()
        }
    }
    
    private func login() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

#Preview {
    LoginView()
}
