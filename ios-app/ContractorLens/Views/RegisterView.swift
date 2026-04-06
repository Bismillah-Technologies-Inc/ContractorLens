import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var showingError = false
    @State private var isRegistering = false
    @State private var passwordStrength: PasswordStrength = .weak
    
    enum PasswordStrength: Int {
        case weak = 0
        case medium = 1
        case strong = 2
        
        var color: Color {
            switch self {
            case .weak: return ContractorLensTheme.Colors.error
            case .medium: return ContractorLensTheme.Colors.warning
            case .strong: return ContractorLensTheme.Colors.success
            }
        }
        
        var description: String {
            switch self {
            case .weak: return "Weak"
            case .medium: return "Medium"
            case .strong: return "Strong"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ContractorLensTheme.Spacing.xl) {
                    // Header
                    HeaderView()
                    
                    // Form
                    VStack(spacing: ContractorLensTheme.Spacing.lg) {
                        DisplayNameField(displayName: $displayName)
                        EmailField(email: $email)
                        
                        PasswordFields(
                            password: $password,
                            confirmPassword: $confirmPassword,
                            passwordStrength: passwordStrength
                        )
                        
                        PasswordStrengthIndicator(strength: passwordStrength)
                        
                        TermsAgreementView()
                        
                        if authService.error != nil {
                            ErrorView(error: authService.error!)
                        }
                        
                        RegisterButton(
                            email: email,
                            password: password,
                            confirmPassword: confirmPassword,
                            displayName: displayName,
                            isRegistering: isRegistering,
                            authService: authService,
                            onRegister: performRegistration
                        )
                        
                        LoginLink(dismiss: dismiss)
                    }
                    .padding(ContractorLensTheme.Spacing.lg)
                    .surfaceBackground()
                    .cornerRadius(ContractorLensTheme.CornerRadius.lg)
                    
                    Spacer()
                }
                .padding(ContractorLensTheme.Spacing.lg)
            }
            .background(ContractorLensTheme.Colors.background)
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .contractorLensStyle()
            .onChange(of: password) { newValue in
                updatePasswordStrength(newValue)
            }
        }
    }
    
    private func updatePasswordStrength(_ password: String) {
        let strength: Int
        
        if password.count >= 12 && containsUpperAndLower(password) && containsNumbers(password) && containsSpecialChars(password) {
            strength = 2
        } else if password.count >= 8 && containsUpperAndLower(password) && containsNumbers(password) {
            strength = 1
        } else {
            strength = 0
        }
        
        passwordStrength = PasswordStrength(rawValue: strength) ?? .weak
    }
    
    private func containsUpperAndLower(_ string: String) -> Bool {
        let upper = string.rangeOfCharacter(from: .uppercaseLetters)
        let lower = string.rangeOfCharacter(from: .lowercaseLetters)
        return upper != nil && lower != nil
    }
    
    private func containsNumbers(_ string: String) -> Bool {
        return string.rangeOfCharacter(from: .decimalDigits) != nil
    }
    
    private func containsSpecialChars(_ string: String) -> Bool {
        let specialChars = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
        return string.rangeOfCharacter(from: specialChars) != nil
    }
    
    private func performRegistration() async {
        guard validateForm() else { return }
        
        isRegistering = true
        defer { isRegistering = false }
        
        do {
            let _ = try await authService.signUp(
                email: email,
                password: password,
                displayName: displayName
            )
            dismiss()
        } catch {
            showingError = true
        }
    }
    
    private func validateForm() -> Bool {
        guard !email.isEmpty,
              !password.isEmpty,
              !confirmPassword.isEmpty,
              password == confirmPassword,
              password.count >= 6 else {
            return false
        }
        
        return true
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
                
                Image(systemName: "person.badge.plus.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(ContractorLensTheme.Colors.primary)
            }
            
            VStack(spacing: ContractorLensTheme.Spacing.sm) {
                Text("Create Account")
                    .font(ContractorLensTheme.Typography.largeTitle)
                    .foregroundColor(ContractorLensTheme.Colors.textPrimary)
                
                Text("Join ContractorLens for professional construction estimates")
                    .font(ContractorLensTheme.Typography.body)
                    .foregroundColor(ContractorLensTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, ContractorLensTheme.Spacing.xl)
    }
}

private struct DisplayNameField: View {
    @Binding var displayName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: ContractorLensTheme.Spacing.sm) {
            Text("Full Name")
                .font(ContractorLensTheme.Typography.subheadline)
                .foregroundColor(ContractorLensTheme.Colors.textPrimary)
            
            TextField("John Smith", text: $displayName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.words)
        }
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

private struct PasswordFields: View {
    @Binding var password: String
    @Binding var confirmPassword: String
    let passwordStrength: RegisterView.PasswordStrength
    
    @State private var isPasswordSecure = true
    @State private var isConfirmPasswordSecure = true
    
    var body: some View {
        VStack(spacing: ContractorLensTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: ContractorLensTheme.Spacing.sm) {
                HStack {
                    Text("Password")
                        .font(ContractorLensTheme.Typography.subheadline)
                        .foregroundColor(ContractorLensTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Button(action: { isPasswordSecure.toggle() }) {
                        Image(systemName: isPasswordSecure ? "eye" : "eye.slash")
                            .foregroundColor(ContractorLensTheme.Colors.textSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if isPasswordSecure {
                    SecureField("••••••••", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    TextField("••••••••", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                if !password.isEmpty {
                    Text("At least 6 characters")
                        .font(ContractorLensTheme.Typography.caption2)
                        .foregroundColor(password.count >= 6 ? 
                                          ContractorLensTheme.Colors.success : 
                                          ContractorLensTheme.Colors.textSecondary)
                }
            }
            
            VStack(alignment: .leading, spacing: ContractorLensTheme.Spacing.sm) {
                HStack {
                    Text("Confirm Password")
                        .font(ContractorLensTheme.Typography.subheadline)
                        .foregroundColor(ContractorLensTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Button(action: { isConfirmPasswordSecure.toggle() }) {
                        Image(systemName: isConfirmPasswordSecure ? "eye" : "eye.slash")
                            .foregroundColor(ContractorLensTheme.Colors.textSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if isConfirmPasswordSecure {
                    SecureField("••••••••", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    TextField("••••••••", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                if !password.isEmpty && !confirmPassword.isEmpty {
                    Text(password == confirmPassword ? "Passwords match" : "Passwords don't match")
                        .font(ContractorLensTheme.Typography.caption2)
                        .foregroundColor(password == confirmPassword ? 
                                          ContractorLensTheme.Colors.success : 
                                          ContractorLensTheme.Colors.error)
                }
            }
        }
    }
}

private struct PasswordStrengthIndicator: View {
    let strength: RegisterView.PasswordStrength
    
    var body: some View {
        VStack(alignment: .leading, spacing: ContractorLensTheme.Spacing.xs) {
            HStack {
                Text("Password Strength")
                    .font(ContractorLensTheme.Typography.caption1)
                    .foregroundColor(ContractorLensTheme.Colors.textSecondary)
                
                Spacer()
                
                Text(strength.description)
                    .font(ContractorLensTheme.Typography.caption1)
                    .foregroundColor(strength.color)
            }
            
            HStack(spacing: 2) {
                ForEach(0..<3) { index in
                    Rectangle()
                        .fill(index <= strength.rawValue ? strength.color : ContractorLensTheme.Colors.surface)
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }
        }
    }
}

private struct TermsAgreementView: View {
    @State private var agreedToTerms = false
    
    var body: some View {
        HStack(alignment: .top, spacing: ContractorLensTheme.Spacing.sm) {
            Button(action: { agreedToTerms.toggle() }) {
                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                    .foregroundColor(agreedToTerms ? 
                                      ContractorLensTheme.Colors.primary : 
                                      ContractorLensTheme.Colors.textSecondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("I agree to the Terms of Service and Privacy Policy")
                .font(ContractorLensTheme.Typography.caption1)
                .foregroundColor(ContractorLensTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
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

private struct RegisterButton: View {
    let email: String
    let password: String
    let confirmPassword: String
    let displayName: String
    let isRegistering: Bool
    let authService: AuthService
    let onRegister: () async -> Void
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
    
    var body: some View {
        Button(action: {
            Task {
                await onRegister()
            }
        }) {
            if isRegistering || authService.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ContractorLensTheme.Spacing.md)
            } else {
                Text("Create Account")
                    .font(ContractorLensTheme.Typography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ContractorLensTheme.Spacing.md)
            }
        }
        .disabled(!isFormValid || isRegistering || authService.isLoading)
        .background(
            !isFormValid || isRegistering || authService.isLoading
            ? ContractorLensTheme.Colors.primary.opacity(0.5)
            : ContractorLensTheme.Colors.primary
        )
        .cornerRadius(ContractorLensTheme.CornerRadius.md)
        .buttonStyle(PlainButtonStyle())
    }
}

private struct LoginLink: View {
    let dismiss: DismissAction
    
    var body: some View {
        HStack {
            Text("Already have an account?")
                .font(ContractorLensTheme.Typography.caption1)
                .foregroundColor(ContractorLensTheme.Colors.textSecondary)
            
            Button(action: {
                dismiss()
            }) {
                Text("Sign In")
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
struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RegisterView()
                .environmentObject(AuthService.previewUnauthenticated)
                .previewDisplayName("Unauthenticated")
            
            RegisterView()
                .environmentObject(AuthService.previewAuthenticated)
                .previewDisplayName("Authenticated (shouldn't show)")
        }
    }
}
#endif