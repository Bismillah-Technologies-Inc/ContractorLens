import SwiftUI

extension View {
    func contractorLensStyle() -> some View {
        self
            .background(ContractorLensTheme.Colors.background)
            .cornerRadius(ContractorLensTheme.CornerRadius.md)
    }

    func professionalCard() -> some View {
        self
            .padding(ContractorLensTheme.Spacing.lg)
            .background(ContractorLensTheme.Colors.surface)
            .cornerRadius(ContractorLensTheme.CornerRadius.lg)
            .shadow(
                color: ContractorLensTheme.Shadow.mediumShadow.color,
                radius: ContractorLensTheme.Shadow.mediumShadow.radius,
                x: ContractorLensTheme.Shadow.mediumShadow.x,
                y: ContractorLensTheme.Shadow.mediumShadow.y
            )
    }

    func surfaceBackground() -> some View {
        self
            .background(ContractorLensTheme.Colors.surface)
            .cornerRadius(ContractorLensTheme.CornerRadius.md)
    }
}