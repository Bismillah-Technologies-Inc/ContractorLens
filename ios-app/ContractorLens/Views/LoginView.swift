import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var showingError = false
    @State private var isLoggingIn = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ContractorLensTheme.Spacing.xl) {
                    // Header
                    HeaderView()
                    
                    // Form
                    VStack(spacing: ContractorLensTheme.Spacing.lg) {
                        EmailField(email: $email)
                        PasswordField(password: $password)
                        
                        if authService.error != nil {
                            ErrorView(error: authService.error!)
                        }
                        
                        LoginButton(
                            email: email,
                            password: password,
                            isLoggingIn: isLoggingIn,
                            authService: authService,
                            onLogin: performLogin
                        )
                        
                        ForgotPasswordLink()
                        
                        RegisterLink(dismiss: dismiss)
                    }
                    .padding(ContractorLensTheme.Spacing.lg)
                    .surfaceBackground()
                    .cornerRadius(ContractorLensTheme.CornerRadius.lg)
                    
                    Spacer()
                }
                .padding(ContractorLensTheme.Spacing.lg)
            }
            .background(ContractorLensTheme.Colors.background)
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .contractorLensStyle()
        }
    }
    
    private func performLogin() async {
        guard !email.isEmpty && !password.isEmpty else { return }
        
        isLoggingIn = true
        defer { isLoggingIn = false }
        
        do {
            let _ = try await authService.signIn(email: email, password: password)
            dismiss()
        } catch {
            showingError = true
        }
    }
}

// MARK: - Subviews

private struct HeaderView: View {
    var body: some View {
        VStack(spacing: ContractorLensTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(ContractorLensTheme.Colors.primary.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(ContractorLensTheme.Colors.primary)
            }
            
            VStack(spacing: ContractorLensTheme.Spacing.sm) {
                Text("Welcome Back")
                    .font(ContractorLensTheme.Typography.largeTitle)
                    .foregroundColor(ContractorLensTheme.Colors.textPrimary)
                
                Text("Sign in to access your projects and estimates")
                    .font(ContractorLensTheme.Typography.body)
                    .foregroundColor(ContractorLensTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, ContractorLensTheme.Spacing.xl)
    }
}

private struct EmailField: View {
    @Binding var email: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: ContractorLensTheme.Spacing.sm) {
            Text("Email Address")
                .font(ContractorLensTheme.Typography.subheadline)
                .foregroundColor(ContractorLensTheme.Colors.textPrimary)
            
            TextField("you@example.com", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
    }
}

private struct PasswordField: View {
    @Binding var password: String
    @State private var isSecure = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: ContractorLensTheme.Spacing.sm) {
            HStack {
                Text("Password")
                    .font(ContractorLensTheme.Typography.subheadline)
                    .foregroundColor(ContractorLensTheme.Colors.textPrimary)
                
                Spacer()
                
                Button(action: { isSecure.toggle() }) {
                    Image(systemName: isSecure ? "eye" : "eye.slash")
                        .foregroundColor(ContractorLensTheme.Colors.textSecondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if isSecure {
                SecureField("••••••••", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                TextField("••••••••", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
}

private struct ErrorView: View {
    let error: AuthError
    
    var body: some View {
        HStack(spacing: ContractorLensTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(ContractorLensTheme.Colors.error)
            
            Text(error.localizedDescription)
                .font(ContractorLensTheme.Typography.caption1)
                .foregroundColor(ContractorLensTheme.Colors.error)
            
            Spacer()
        }
        .padding(ContractorLensTheme.Spacing.md)
        .background(ContractorLensTheme.Colors.error.opacity(0.1))
        .cornerRadius(ContractorLensTheme.CornerRadius.md)
    }
}

private struct LoginButton: View {
    let email: String
    let password: String
    let isLoggingIn: Bool
    let authService: AuthService
    let onLogin: () async -> Void
    
    var body: some View {
        Button(action: {
            Task {
                await onLogin()
            }
        }) {
            if isLoggingIn || authService.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ContractorLensTheme.Spacing.md)
            } else {
                Text("Sign In")
                    .font(ContractorLensTheme.Typography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ContractorLensTheme.Spacing.md)
            }
        }
        .disabled(email.isEmpty || password.isEmpty || isLoggingIn || authService.isLoading)
        .background(
            email.isEmpty || password.isEmpty || isLoggingIn || authService.isLoading
            ? ContractorLensTheme.Colors.primary.opacity(0.5)
            : ContractorLensTheme.Colors.primary
        )
        .cornerRadius(ContractorLensTheme.CornerRadius.md)
        .buttonStyle(PlainButtonStyle())
    }
}

private struct ForgotPasswordLink: View {
    var body: some View {
        Button(action: {
            // TODO: Implement forgot password flow
        }) {
            Text("Forgot Password?")
                .font(ContractorLensTheme.Typography.caption1)
                .foregroundColor(ContractorLensTheme.Colors.primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct RegisterLink: View {
    let dismiss: DismissAction
    
    var body: some View {
        HStack {
            Text("Don't have an account?")
                .font(ContractorLensTheme.Typography.caption1)
                .foregroundColor(ContractorLensTheme.Colors.textSecondary)
            
            Button(action: {
                // Show register view
            }) {
                Text("Sign Up")
                    .font(ContractorLensTheme.Typography.caption1)
                    .fontWeight(.semibold)
                    .foregroundColor(ContractorLensTheme.Colors.primary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.top, ContractorLensTheme.Spacing.sm)
    }
}

// MARK: - Previews

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView()
                .environmentObject(AuthService.previewUnauthenticated)
                .previewDisplayName("Unauthenticated")
            
            LoginView()
                .environmentObject(AuthService.previewAuthenticated)
                .previewDisplayName("Authenticated (shouldn't show)")
        }
    }
}
#endif