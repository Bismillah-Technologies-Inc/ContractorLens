import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    var project: Project
    @Environment(\.modelContext) private var modelContext
    @State private var showingScanningView = false
    @State private var newRoomName = ""
    @State private var presentingScanningForRoom: UUID?
    @State private var showingProjectEstimate = false
    
    var body: some View {
        List {
            Section(header: Text("Project Info")) {
                LabeledContent("Client", value: project.clientName ?? "Not specified")
                LabeledContent("Created", value: project.createdAt.formatted(date: .abbreviated, time: .omitted))
                LabeledContent("Rooms", value: "\(project.rooms.count)")
            }
            
            Section(header: Text("Rooms")) {
                ForEach(project.rooms) { room in
                    NavigationLink(destination: RoomDetailView(room: room)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(room.name.isEmpty ? "Unnamed Room" : room.name)
                                .font(.headline)
                            if !room.scopeDescription.isEmpty {
                                Text(room.scopeDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Text(String(format: "%.0f sq ft", room.floorArea))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteRooms)
            }
        }
        .navigationTitle(project.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: { showingProjectEstimate = true }) {
                        Label("Estimate", systemImage: "doc.text")
                    }
                    Button(action: { showingScanningView = true }) {
                        Label("Scan Room", systemImage: "camera.viewfinder")
                    }
                }
            }
        }
        .sheet(isPresented: $showingScanningView) {
            RoomNameInputView(isPresented: $showingScanningView) { roomName in
                startScanning(roomName: roomName)
            }
        }
        .sheet(item: $presentingScanningForRoom) { roomID in
            ScanningView { scanResult in
                updateRoom(with: scanResult, roomID: roomID)
            }
        }
        .sheet(isPresented: $showingProjectEstimate) {
            ProjectEstimateView(project: project)
        }
    }
    
    private func startScanning(roomName: String) {
        let room = Room(name: roomName)
        room.project = project
        modelContext.insert(room)
        presentingScanningForRoom = room.id
    }
    
    private func updateRoom(with scanResult: RoomScanResult, roomID: UUID) {
        guard let room = project.rooms.first(where: { $0.id == roomID }) else { return }
        room.setScanResult(scanResult)
        if room.name.isEmpty {
            room.name = scanResult.roomType.displayName
        }
        // Clear the presenting state
        presentingScanningForRoom = nil
    }
    
    private func deleteRooms(at offsets: IndexSet) {
        for index in offsets {
            let room = project.rooms[index]
            modelContext.delete(room)
        }
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

#Preview {
    let project = Project(name: "Test Project")
    return NavigationView {
        ProjectDetailView(project: project)
    }
    .modelContainer(for: Project.self, inMemory: true)
}