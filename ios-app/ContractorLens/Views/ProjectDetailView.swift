import SwiftUI
import Combine

struct ProjectDetailView: View {
    @Binding var project: Project
    @State private var showingScanningView = false

    // States for managing the estimation process
    @StateObject private var assemblyService = AssemblyEngineService()
    @State private var estimationState: EstimationState = .idle
    @State private var progress: Double = 0.0
    @State private var errorMessage: String?
    @State private var generatedEstimate: Estimate? // Holds the successful estimate
    @State private var cancellables = Set<AnyCancellable>()

    enum EstimationState {
        case idle, processing, success, failed
    }

    var body: some View {
        VStack {
            if project.scans.isEmpty {
                emptyStateView
            } else {
                scanListView
            }
        }
        .navigationTitle(project.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingScanningView = true }) {
                    Label("Start New Scan", systemImage: "plus")
                }
            }
        }
        .fullScreenCover(isPresented: $showingScanningView) {
            // onDismiss
        } content: {
            ScanningView(projectName: project.name) { scanPackage in
                project.scans.insert(scanPackage, at: 0)
                project.lastModified = Date()
                // If there is no cover image, set the first frame of this scan as the cover image
                if project.coverImage == nil, let firstFrame = scanPackage.capturedFrames.first {
                    project.coverImage = firstFrame
                }
                let persistence = ProjectPersistenceService()
                try? persistence.save(project: project)
            }
        }
        .sheet(isPresented: .constant(estimationState == .processing)) {
            ScanProcessingView(progress: $progress)
        }
        .sheet(item: $generatedEstimate) { estimate in
            ResultsView(estimate: estimate)
        }
        .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") { errorMessage = nil; estimationState = .idle }
        }, message: {
            Text(errorMessage ?? "An unknown error occurred.")
        })
    }

    private var scanListView: some View {
        List {
            Section(header: Text("Scans")) {
                ForEach(project.scans, id: \.id) { scan in
                    scanRow(for: scan)
                }
            }
        }
    }

    private func scanRow(for scan: ScanPackage) -> some View {
        HStack {
            NavigationLink(destination: ScanDetailView(scan: scan)) {
                HStack {
                    if let imageData = scan.capturedFrames.first, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable().aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60).clipped().cornerRadius(8)
                    } else {
                        Image(systemName: "camera.fill")
                            .frame(width: 60, height: 60).background(Color.gray.opacity(0.2)).cornerRadius(8)
                    }

                    VStack(alignment: .leading) {
                        Text("Scan from \(scan.timestamp, style: .time)")
                        Text("\(scan.capturedFrames.count) images").font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
            Button(action: { startEstimateGeneration(for: scan) }) {
                Text("Generate Estimate")
                    .font(.caption)
                    .padding(8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle()) // Prevents the whole row from being a button
        }
        .padding(.vertical, 4)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "camera.macro")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            Text("No Scans Yet")
                .font(.title2).bold()
            Text("Tap the '+' button to start your first scan for this project.")
                .font(.body).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal)
            Spacer()
            Spacer()
        }
    }

    private func startEstimateGeneration(for scan: ScanPackage) {
        // TODO: Build UI for the user to select these values.
        let selectedRoomType = RoomType.livingRoom
        let currentUserPrefs = UserPreferences.defaultPreferences
        let jobLocation = LocationData.defaultLocation

        estimationState = .processing
        progress = 0.1

        assemblyService.generateEnhancedEstimate(
            scanPackage: scan,
            roomType: selectedRoomType,
            userPreferences: currentUserPrefs,
            location: jobLocation
        )
        .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                self.estimationState = .success
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.estimationState = .failed
            }
        }, receiveValue: { estimate in
            self.progress = 1.0
            self.estimationState = .idle
            self.generatedEstimate = estimate // Trigger the results sheet
        })
        .store(in: &cancellables)
    }
}

struct RoomNameInputView: View {
    @Binding var isPresented: Bool
    @State private var roomName = ""
    var onSubmit: (String) -> Void

    var body: some View {
        NavigationView {
            Form {
                TextField("Room Name (e.g., Kitchen)", text: $roomName)
            }
            .navigationTitle("New Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Scan") {
                        onSubmit(roomName)
                        isPresented = false
                    }
                    .disabled(roomName.isEmpty)
                }
            }
        }
    }
}
