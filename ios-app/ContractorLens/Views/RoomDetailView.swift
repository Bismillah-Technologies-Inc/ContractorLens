import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers

struct RoomDetailView: View {
    var room: Room
    @Environment(\.modelContext) private var modelContext
    @State private var scopeDescription: String
    @State private var roomName: String
    @State private var isEditingScope = false
    @State private var isEditingName = false
    @State private var showingShareSheet = false
    @State private var pdfData: Data?
    @State private var estimate: Estimate?
    @State private var showingScopePrompt = false
    @State private var showingEditEstimate = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    init(room: Room) {
        self.room = room
        _scopeDescription = State(initialValue: room.scopeDescription)
        _roomName = State(initialValue: room.name)
    }
    
    var body: some View {
        List {
            Section(header: Text("Room Info")) {
                if isEditingName {
                    TextField("Room Name", text: $roomName)
                        .textFieldStyle(.roundedBorder)
                    Button("Save Name") {
                        room.name = roomName
                        saveRoom()
                        isEditingName = false
                    }
                } else {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(room.name.isEmpty ? "Unnamed Room" : room.name)
                            .foregroundColor(room.name.isEmpty ? .secondary : .primary)
                        Button(action: { isEditingName = true }) {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Section(header: Text("Measurements")) {
                LabeledContent("Dimensions", value: String(format: "%.1f × %.1f ft", room.floorArea.squareRoot(), room.floorArea.squareRoot()))
                LabeledContent("Floor Area", value: String(format: "%.0f sq ft", room.floorArea))
                LabeledContent("Wall Area", value: String(format: "%.0f sq ft", room.wallArea))
                LabeledContent("Ceiling Height", value: String(format: "%.1f ft", room.ceilingHeight))
                LabeledContent("Doors", value: "\(room.doorCount)")
                LabeledContent("Windows", value: "\(room.windowCount)")
            }
            
            Section(header: Text("Scope of Work")) {
                if isEditingScope {
                    TextEditor(text: $scopeDescription)
                        .frame(minHeight: 100)
                    Button("Save Scope") {
                        room.scopeDescription = scopeDescription
                        saveRoom()
                        isEditingScope = false
                    }
                } else {
                    Text(room.scopeDescription.isEmpty ? "Tap to add scope description" : room.scopeDescription)
                        .foregroundColor(room.scopeDescription.isEmpty ? .secondary : .primary)
                        .onTapGesture {
                            isEditingScope = true
                        }
                }
            }
            
            if let scanResult = room.getScanResult() {
                Section(header: Text("Scan Details")) {
                    LabeledContent("Room Type", value: scanResult.roomType.displayName)
                    LabeledContent("Scan Duration", value: String(format: "%.1f seconds", scanResult.metadata.duration))
                    LabeledContent("Frames Captured", value: "\(scanResult.metadata.frameCount)")
                }
            }
            
            Section(header: Text("Estimate")) {
                if let currentEstimate = room.getEstimate() {
                    LabeledContent("Total", value: String(format: "$%.2f", currentEstimate.grandTotal))
                    LabeledContent("Materials", value: String(format: "$%.2f", currentEstimate.materialTotal))
                    LabeledContent("Labor", value: String(format: "$%.2f", currentEstimate.laborTotal))
                    HStack {
                        Button("Share PDF") {
                            generatePDF()
                        }
                        Spacer()
                        Button("Edit Estimate") {
                            showingEditEstimate = true
                        }
                    }
                } else {
                    Button("Generate Estimate") {
                        generateEstimate()
                    }
                    .disabled(room.scopeDescription.isEmpty)
                }
            }
        }
        .navigationTitle(room.name.isEmpty ? "Room" : room.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isEditingScope.toggle() }) {
                    Label(isEditingScope ? "Done" : "Edit", systemImage: isEditingScope ? "checkmark" : "pencil")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdfData = pdfData {
                ShareSheet(activityItems: [pdfData])
            }
        }
        .sheet(isPresented: $showingEditEstimate) {
            EstimateEditView(room: room)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .onAppear {
            estimate = room.getEstimate()
        }
        .onChange(of: showingEditEstimate) { newValue in
            if !newValue {
                estimate = room.getEstimate()
            }
        }
    }
    
    private func saveRoom() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func generateEstimate() {
        guard !room.scopeDescription.isEmpty else {
            errorMessage = "Please enter a scope description first."
            showError = true
            return
        }
        
        let engine = DeterministicEstimateEngine()
        guard let newEstimate = engine.generateEstimate(for: room, scope: room.scopeDescription) else {
            errorMessage = "Could not generate estimate for scope: \(room.scopeDescription)"
            showError = true
            return
        }
        
        // Store estimate in room
        room.setEstimate(newEstimate)
        saveRoom()
        
        estimate = newEstimate
        generatePDF()
    }
    
    private func generatePDF() {
        let currentEstimate = estimate ?? room.getEstimate()
        guard let estimate = currentEstimate,
              let project = room.project else {
            errorMessage = "Missing estimate or project data."
            showError = true
            return
        }
        
        guard let data = PDFGenerator.generateEstimatePDF(from: estimate, project: project, room: room) else {
            errorMessage = "Failed to generate PDF."
            showError = true
            return
        }
        
        pdfData = data
        showingShareSheet = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let room = Room(name: "Kitchen", scopeDescription: "Full kitchen remodel")
    return NavigationView {
        RoomDetailView(room: room)
    }
    .modelContainer(for: Room.self, inMemory: true)
}