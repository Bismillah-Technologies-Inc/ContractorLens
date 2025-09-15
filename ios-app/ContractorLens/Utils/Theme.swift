import SwiftUI

struct ContractorLensTheme {
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    struct Colors {
        static let background = Color.white
        static let surface = Color.gray.opacity(0.1)
        static let primary = Color.blue
        static let textPrimary = Color.black
        static let textSecondary = Color.gray
        static let success = Color.green
    }

    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold)
        static let title1 = Font.system(size: 28, weight: .bold)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let caption1 = Font.system(size: 12, weight: .regular)
    }

    struct IconSize {
        static let hero: CGFloat = 48
        static let large: CGFloat = 24
        static let medium: CGFloat = 20
        static let small: CGFloat = 16
    }

    struct CornerRadius {
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
    }

    struct Shadow {
        struct ShadowConfig {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }

        static let smallShadow = ShadowConfig(
            color: Color.black.opacity(0.1),
            radius: 2,
            x: 0,
            y: 1
        )

        static let mediumShadow = ShadowConfig(
            color: Color.black.opacity(0.15),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}