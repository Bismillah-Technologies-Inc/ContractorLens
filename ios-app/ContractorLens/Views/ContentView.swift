import SwiftUI

struct ContentView: View {
    @StateObject private var arService = ARService()
    @State private var showingCreateNewProject = false
    @State private var showingScanningView = false
    @State private var newProjectName: String?

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: ContractorLensTheme.Spacing.xl) {
                    HeaderView()
                    
                    ActionButtonsView(
                        showingCreateNewProject: $showingCreateNewProject
                    )
                    
                    FeaturesOverviewView()
                    
                    Spacer(minLength: ContractorLensTheme.Spacing.xl)
                }
                .padding(ContractorLensTheme.Spacing.md)
            }
            .background(ContractorLensTheme.Colors.background)
            .navigationTitle("ContractorLens")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCreateNewProject) {
                CreateNewProjectView(isPresented: $showingCreateNewProject) { projectName in
                    self.newProjectName = projectName
                    self.showingScanningView = true
                }
            }
            .fullScreenCover(isPresented: $showingScanningView) {
                // We will pass the project name to the ScanningView later
                ScanningView()
            }
        }
        .environmentObject(arService)
        .contractorLensStyle()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("ContractorLens main screen")
    }
}

struct ActionButtonsView: View {
    @Binding var showingCreateNewProject: Bool
    
    var body: some View {
        VStack(spacing: ContractorLensTheme.Spacing.md) {
            ActionCardView(
                icon: "camera.viewfinder",
                title: "Scan Space",
                description: "Use AR to capture a 3D model of a room",
                action: {
                    showingCreateNewProject = true
                }
            )
            
            ActionCardView(
                icon: "square.and.arrow.down",
                title: "Upload Plan",
                description: "Import a floor plan or architectural drawing",
                action: {
                    // Future functionality
                }
            )
            .opacity(0.5) // Indicate it's not yet implemented
        }
    }
}

struct ActionCardView: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ContractorLensTheme.Spacing.lg) {
                Image(systemName: icon)
                    .font(.system(size: ContractorLensTheme.IconSize.large, weight: .medium))
                    .foregroundColor(ContractorLensTheme.Colors.primary)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(ContractorLensTheme.Typography.headline)
                        .foregroundColor(ContractorLensTheme.Colors.textPrimary)
                    
                    Text(description)
                        .font(ContractorLensTheme.Typography.caption1)
                        .foregroundColor(ContractorLensTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: ContractorLensTheme.IconSize.small, weight: .medium))
                    .foregroundColor(ContractorLensTheme.Colors.textSecondary)
            }
            .padding(ContractorLensTheme.Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(ContractorLensTheme.Colors.surface)
            .cornerRadius(ContractorLensTheme.CornerRadius.lg)
            .shadow(color: ContractorLensTheme.Shadow.smallShadow.color,
                    radius: ContractorLensTheme.Shadow.smallShadow.radius,
                    x: ContractorLensTheme.Shadow.smallShadow.x,
                    y: ContractorLensTheme.Shadow.smallShadow.y)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HeaderView: View {
    var body: some View {
        VStack(spacing: ContractorLensTheme.Spacing.lg) {
            // Professional logo/icon with animation
            ZStack {
                Circle()
                    .fill(ContractorLensTheme.Colors.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "viewfinder.circle.fill")
                    .font(.system(size: ContractorLensTheme.IconSize.hero, weight: .medium))
                    .foregroundColor(ContractorLensTheme.Colors.primary)
            }
            .shadow(
                color: ContractorLensTheme.Shadow.mediumShadow.color,
                radius: ContractorLensTheme.Shadow.mediumShadow.radius,
                x: ContractorLensTheme.Shadow.mediumShadow.x,
                y: ContractorLensTheme.Shadow.mediumShadow.y
            )
            
            VStack(spacing: ContractorLensTheme.Spacing.sm) {
                Text("ContractorLens")
                    .font(ContractorLensTheme.Typography.largeTitle)
                    .foregroundColor(ContractorLensTheme.Colors.textPrimary)
                
                Text("Professional AR Construction Estimates")
                    .font(ContractorLensTheme.Typography.subheadline)
                    .foregroundColor(ContractorLensTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                // Professional tagline
                HStack(spacing: ContractorLensTheme.Spacing.xs) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(ContractorLensTheme.Colors.success)
                        .font(.system(size: ContractorLensTheme.IconSize.small))
                    
                    Text("Accurate • Fast • Professional")
                        .font(ContractorLensTheme.Typography.caption1)
                        .foregroundColor(ContractorLensTheme.Colors.textSecondary)
                }
                .padding(.top, ContractorLensTheme.Spacing.xs)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("ContractorLens. Professional AR Construction Estimates. Accurate, Fast, Professional.")
    }
}

struct RecentScanView: View {
    let room: Room
    
    var body: some View {
        VStack(alignment: .leading, spacing: ContractorLensTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: ContractorLensTheme.Spacing.xs) {
                    Text("Recent Scan")
                        .font(ContractorLensTheme.Typography.headline)
                        .foregroundColor(ContractorLensTheme.Colors.textPrimary)
                    
                    Text("Tap to view estimate details")
                        .font(ContractorLensTheme.Typography.caption1)
                        .foregroundColor(ContractorLensTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: ContractorLensTheme.IconSize.medium))
                    .foregroundColor(ContractorLensTheme.Colors.success)
            }
            
            // Room metrics with professional styling
            HStack(spacing: ContractorLensTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: ContractorLensTheme.Spacing.xs) {
                    Text("Dimensions")
                        .font(ContractorLensTheme.Typography.caption1)
                        .foregroundColor(ContractorLensTheme.Colors.textSecondary)
                        .textCase(.uppercase)
                    
                    Text("\(room.dimensions.length, specifier: "%.1f") × \(room.dimensions.width, specifier: "%.1f") ft")
                        .font(ContractorLensTheme.Typography.subheadline)
                        .foregroundColor(ContractorLensTheme.Colors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: ContractorLensTheme.Spacing.xs) {
                    Text("Area")
                        .font(ContractorLensTheme.Typography.caption1)
                        .foregroundColor(ContractorLensTheme.Colors.textSecondary)
                        .textCase(.uppercase)
                    
                    Text("\(room.dimensions.area, specifier: "%.0f") sq ft")
                        .font(ContractorLensTheme.Typography.subheadline)
                        .foregroundColor(ContractorLensTheme.Colors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: ContractorLensTheme.Spacing.xs) {
                    Text("Status")
                        .font(ContractorLensTheme.Typography.caption1)
                        .foregroundColor(ContractorLensTheme.Colors.textSecondary)
                        .textCase(.uppercase)
                    
                    Text("Complete")
                        .font(ContractorLensTheme.Typography.caption1)
                        .fontWeight(.medium)
                        .foregroundColor(ContractorLensTheme.Colors.success)
                        .padding(.horizontal, ContractorLensTheme.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(ContractorLensTheme.Colors.success.opacity(0.1))
                        .cornerRadius(ContractorLensTheme.CornerRadius.sm)
                }
            }
            
            NavigationLink(destination: ResultsView(room: room)) {
                HStack {
                    Text("View Estimate Details")
                        .font(ContractorLensTheme.Typography.subheadline)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: ContractorLensTheme.IconSize.small))
                }
                .foregroundColor(ContractorLensTheme.Colors.primary)
                .padding(.top, ContractorLensTheme.Spacing.sm)
            }
        }
        .padding(ContractorLensTheme.Spacing.lg)
        .professionalCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: "Recent scan completed. Room dimensions %.1f by %.1f feet. Total area %.0f square feet.", room.dimensions.length, room.dimensions.width, room.dimensions.area))
        .accessibilityHint("Tap to view detailed estimate")
    }
}

struct FeaturesOverviewView: View {
    private let features = [
        (icon: "viewfinder", title: "AR Scanning", description: "Advanced room scanning with RoomPlan"),
        (icon: "cpu", title: "AI Analysis", description: "Google Gemini material identification"),
        (icon: "dollarsign.circle", title: "Cost Estimates", description: "Location-aware professional pricing"),
        (icon: "square.and.arrow.up", title: "Export Ready", description: "PDF/CSV reports for client use")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: ContractorLensTheme.Spacing.md) {
            Text("Why ContractorLens?")
                .font(ContractorLensTheme.Typography.headline)
                .foregroundColor(ContractorLensTheme.Colors.textPrimary)
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: ContractorLensTheme.Spacing.sm),
                    GridItem(.flexible(), spacing: ContractorLensTheme.Spacing.sm)
                ],
                spacing: ContractorLensTheme.Spacing.md
            ) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    FeatureCardView(
                        icon: feature.icon,
                        title: feature.title,
                        description: feature.description
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(feature.title). \(feature.description)")
                }
            }
        }
    }
}

struct FeatureCardView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: ContractorLensTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: ContractorLensTheme.IconSize.large, weight: .medium))
                .foregroundColor(ContractorLensTheme.Colors.primary)
                .frame(height: 40)
            
            VStack(spacing: ContractorLensTheme.Spacing.xs) {
                Text(title)
                    .font(ContractorLensTheme.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(ContractorLensTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(ContractorLensTheme.Typography.caption1)
                    .foregroundColor(ContractorLensTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(ContractorLensTheme.Spacing.md)
        .surfaceBackground()
        .overlay(
            RoundedRectangle(cornerRadius: ContractorLensTheme.CornerRadius.md)
                .stroke(ContractorLensTheme.Colors.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    ContentView()
}

struct CreateNewProjectView: View {
    @Binding var isPresented: Bool
    @State private var projectName: String = ""
    
    // Action to be performed when project is created
    var onCreate: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Name Your Project")
                    .font(ContractorLensTheme.Typography.title1)
                    .fontWeight(.bold)
                
                TextField("e.g., Kitchen Remodel", text: $projectName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationBarTitle("Create New Project", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Create") {
                    onCreate(projectName)
                    isPresented = false
                }
                .disabled(projectName.isEmpty)
            )
        }
    }
}