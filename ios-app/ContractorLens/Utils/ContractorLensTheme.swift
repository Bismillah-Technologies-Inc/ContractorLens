import SwiftUI
import UIKit

// MARK: - Professional Theme System
public struct ContractorLensTheme {
    // MARK: - Color Palette
    public struct Colors {
        // Professional primary colors
        public static let primary = Color(red: 0.2, green: 0.4, blue: 0.8)        // Professional blue
        public static let primaryDark = Color(red: 0.15, green: 0.3, blue: 0.6)   // Darker blue for pressed states
        static let secondary = Color(red: 0.3, green: 0.6, blue: 0.3)      // Success green
        static let accent = Color(red: 0.9, green: 0.5, blue: 0.1)         // Warning orange
        
        // Semantic colors
        static let success = Color(red: 0.0, green: 0.7, blue: 0.0)
        static let warning = Color(red: 0.9, green: 0.6, blue: 0.0)
        static let error = Color(red: 0.8, green: 0.2, blue: 0.2)
        static let info = Color(red: 0.2, green: 0.6, blue: 0.9)
        
        // Background colors
        static let background = Color(.systemBackground)
        static let surface = Color(.systemGray6)
        static let surfaceSecondary = Color(.systemGray5)
        static let overlay = Color.black.opacity(0.5)
        
        // Text colors
        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let textTertiary = Color(.tertiaryLabel)
        
        // Quality tier colors
        static let qualityGood = Color.orange.opacity(0.8)
        static let qualityBetter = Color.blue.opacity(0.8)
        static let qualityBest = Color.green.opacity(0.8)
        
        // Professional estimate colors
        static let estimateMaterials = Color(red: 0.4, green: 0.6, blue: 0.8)
        static let estimateLabor = Color(red: 0.6, green: 0.4, blue: 0.8)
        static let estimateTax = Color(red: 0.8, green: 0.4, blue: 0.4)
        static let estimateOverhead = Color(red: 0.5, green: 0.5, blue: 0.5)
    }
    
    // MARK: - Typography
    public struct Typography {
        // Professional fonts
        public static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
        public static let title1 = Font.system(.title, design: .rounded, weight: .semibold)
        public static let title2 = Font.system(.title2, design: .rounded, weight: .semibold)
        public static let headline = Font.system(.title3, design: .default, weight: .semibold)
        public static let subheadline = Font.system(.body, design: .default, weight: .medium)
        public static let body = Font.system(.body, design: .default)
        public static let callout = Font.system(.callout, design: .default)
        public static let footnote = Font.system(.footnote, design: .default)
        public static let caption1 = Font.system(.caption, design: .default)
        public static let caption2 = Font.system(.caption2, design: .default)
        
        // Professional estimate typography
        public static let estimateTitle = Font.system(.title, design: .rounded, weight: .bold)
        public static let estimateTotal = Font.system(.largeTitle, design: .rounded, weight: .heavy)
        public static let estimateSubtitle = Font.system(.subheadline, design: .default, weight: .medium)
        public static let lineItemTitle = Font.system(.body, design: .default, weight: .medium)
        public static let lineItemDetail = Font.system(.caption, design: .monospaced)
        public static let csiCode = Font.system(.caption2, design: .monospaced, weight: .medium)
    }
    
    // MARK: - Spacing
    public struct Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    public struct CornerRadius {
        public static let sm: CGFloat = 6
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
    }
    
    // MARK: - Shadows
    public struct Shadow {
        public static let light = Color.black.opacity(0.05)
        public static let medium = Color.black.opacity(0.1)
        public static let heavy = Color.black.opacity(0.2)
        
        public static let smallShadow = (color: light, radius: 2.0, x: 0.0, y: 1.0)
        public static let mediumShadow = (color: medium, radius: 8.0, x: 0.0, y: 4.0)
        public static let largeShadow = (color: heavy, radius: 16.0, x: 0.0, y: 8.0)
    }
    
    // MARK: - Animation
    public struct Animation {
        public static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        public static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
        public static let bouncy = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
    }
    
    // MARK: - Icon Sizes
    struct IconSize {
        static let small: CGFloat = 16
        static let medium: CGFloat = 24
        static let large: CGFloat = 32
        static let xlarge: CGFloat = 48
        static let hero: CGFloat = 80
    }
}

// MARK: - Professional Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ContractorLensTheme.Typography.subheadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ContractorLensTheme.Spacing.md)
            .background(
                isEnabled ?
                (configuration.isPressed ? ContractorLensTheme.Colors.primaryDark : ContractorLensTheme.Colors.primary) :
                Color.gray.opacity(0.5)
            )
            .cornerRadius(ContractorLensTheme.CornerRadius.md)
            .shadow(
                color: ContractorLensTheme.Shadow.mediumShadow.color,
                radius: ContractorLensTheme.Shadow.mediumShadow.radius,
                x: ContractorLensTheme.Shadow.mediumShadow.x,
                y: ContractorLensTheme.Shadow.mediumShadow.y
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(ContractorLensTheme.Animation.quick, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ContractorLensTheme.Typography.subheadline)
            .foregroundColor(ContractorLensTheme.Colors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ContractorLensTheme.Spacing.md)
            .background(ContractorLensTheme.Colors.surface)
            .cornerRadius(ContractorLensTheme.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: ContractorLensTheme.CornerRadius.md)
                    .stroke(ContractorLensTheme.Colors.primary, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(ContractorLensTheme.Animation.quick, value: configuration.isPressed)
    }
}

struct CompactButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ContractorLensTheme.Typography.footnote)
            .foregroundColor(ContractorLensTheme.Colors.primary)
            .padding(.horizontal, ContractorLensTheme.Spacing.sm)
            .padding(.vertical, ContractorLensTheme.Spacing.xs)
            .background(ContractorLensTheme.Colors.primary.opacity(0.1))
            .cornerRadius(ContractorLensTheme.CornerRadius.sm)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(ContractorLensTheme.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Professional Card Style
struct ProfessionalCardModifier: ViewModifier {
    let elevation: CGFloat
    
    init(elevation: CGFloat = 1.0) {
        self.elevation = elevation
    }
    
    func body(content: Content) -> some View {
        content
            .background(ContractorLensTheme.Colors.background)
            .cornerRadius(ContractorLensTheme.CornerRadius.lg)
            .shadow(
                color: ContractorLensTheme.Shadow.mediumShadow.color.opacity(elevation),
                radius: ContractorLensTheme.Shadow.mediumShadow.radius * elevation,
                x: ContractorLensTheme.Shadow.mediumShadow.x,
                y: ContractorLensTheme.Shadow.mediumShadow.y * elevation
            )
    }
}

// MARK: - Surface Background Style
struct SurfaceBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(ContractorLensTheme.Colors.surface)
            .cornerRadius(ContractorLensTheme.CornerRadius.md)
    }
}

// MARK: - Professional Status Badge
struct QualityTierBadge: View {
    let tier: String
    let isSelected: Bool
    
    private var tierColor: Color {
        switch tier.lowercased() {
        case "good": return ContractorLensTheme.Colors.qualityGood
        case "better": return ContractorLensTheme.Colors.qualityBetter
        case "best": return ContractorLensTheme.Colors.qualityBest
        default: return ContractorLensTheme.Colors.textSecondary
        }
    }
    
    var body: some View {
        Text(tier.capitalized)
            .font(ContractorLensTheme.Typography.caption1)
            .fontWeight(.medium)
            .foregroundColor(isSelected ? .white : tierColor)
            .padding(.horizontal, ContractorLensTheme.Spacing.sm)
            .padding(.vertical, ContractorLensTheme.Spacing.xs)
            .background(
                isSelected ? tierColor : tierColor.opacity(0.2)
            )
            .cornerRadius(ContractorLensTheme.CornerRadius.sm)
    }
}

// MARK: - View Extensions
extension View {
    func professionalCard(elevation: CGFloat = 1.0) -> some View {
        modifier(ProfessionalCardModifier(elevation: elevation))
    }
    
    func surfaceBackground() -> some View {
        modifier(SurfaceBackgroundModifier())
    }
    
    func contractorLensStyle() -> some View {
        self
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .preferredColorScheme(.none)
    }
}

// MARK: - Accessibility Helpers
struct AccessibilityInfo {
    static func estimateLabel(total: Double, roomType: String, accuracy: String) -> String {
        return "Construction estimate for \(roomType). Total cost \(spokenCurrency(total)). Accuracy rating \(accuracy)."
    }
    
    static func lineItemLabel(description: String, quantity: Double, unit: String, unitCost: Double, totalCost: Double) -> String {
        return "\(description). Quantity \(Int(quantity)) \(unit). Unit cost \(spokenCurrency(unitCost)). Total \(spokenCurrency(totalCost))."
    }
    
    private static func spokenCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        
        let dollars = Int(amount)
        let cents = Int((amount - Double(dollars)) * 100)
        
        let dollarsText = formatter.string(from: NSNumber(value: dollars)) ?? "\(dollars)"
        
        if cents == 0 {
            return "\(dollarsText) dollars"
        } else {
            let centsText = formatter.string(from: NSNumber(value: cents)) ?? "\(cents)"
            return "\(dollarsText) dollars and \(centsText) cents"
        }
    }
}

// MARK: - Professional Loading View
struct ProfessionalLoadingView: View {
    @State private var animationPhase = 0
    let title: String
    let subtitle: String
    let steps: [String]
    
    var body: some View {
        VStack(spacing: ContractorLensTheme.Spacing.xl) {
            // Loading animation
            ZStack {
                Circle()
                    .stroke(ContractorLensTheme.Colors.surface, lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [ContractorLensTheme.Colors.primary, ContractorLensTheme.Colors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(Double(animationPhase) * 360 / 8))
                    .animation(
                        .linear(duration: 2.0).repeatForever(autoreverses: false),
                        value: animationPhase
                    )
                
                Image(systemName: "viewfinder")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(ContractorLensTheme.Colors.primary)
            }
            .onAppear {
                animationPhase = 1
            }
            
            // Loading content
            VStack(spacing: ContractorLensTheme.Spacing.md) {
                Text(title)
                    .font(ContractorLensTheme.Typography.headline)
                    .foregroundColor(ContractorLensTheme.Colors.textPrimary)
                
                Text(subtitle)
                    .font(ContractorLensTheme.Typography.subheadline)
                    .foregroundColor(ContractorLensTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Processing steps
            VStack(alignment: .leading, spacing: ContractorLensTheme.Spacing.sm) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: ContractorLensTheme.Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(ContractorLensTheme.Colors.success)
                            .font(.system(size: ContractorLensTheme.IconSize.small))
                        
                        Text(step)
                            .font(ContractorLensTheme.Typography.footnote)
                            .foregroundColor(ContractorLensTheme.Colors.textSecondary)
                    }
                    .opacity(0.6)
                    .animation(
                        ContractorLensTheme.Animation.smooth.delay(Double(index) * 0.5),
                        value: animationPhase
                    )
                }
            }
        }
        .padding(ContractorLensTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityHint("Please wait while your estimate is being generated")
    }
}
