import SwiftUI
import SwiftData

struct RoomScanningView: View {
    let roomID: UUID
    @Environment(\.modelContext) private var modelContext
    @Query private var rooms: [Room]
    @State private var scanCompleted = false
    @State private var scanResult: RoomScanResult?
    @State private var showingResults = false
    
    private var room: Room? {
        rooms.first { $0.id == roomID }
    }
    
    var body: some View {
        ScanningView(onScanCompleted: { result in
            self.scanResult = result
            self.scanCompleted = true
            updateRoom(with: result)
        })
        .sheet(isPresented: $scanCompleted) {
            if let result = scanResult {
                EstimateResultsView(scanResult: result)
            }
        }
    }
    
    private func updateRoom(with scanResult: RoomScanResult) {
        guard let room = room else { return }
        room.setScanResult(scanResult)
        // Also update room name if empty
        if room.name.isEmpty {
            room.name = scanResult.roomType.displayName
        }
        // Save is automatic with SwiftData
    }
}

// Wrapper to adapt existing ScanningView to our closure
struct ScanningView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var scanningService = ScanningService()
    var onScanCompleted: (RoomScanResult) -> Void
    
    @State private var scanCompleted = false
    @State private var scanResult: RoomScanResult? = nil

    var body: some View {
        ZStack {
            RoomCaptureViewRepresentable(scanningService: scanningService) {
                self.scanCompleted = true
                if let result = scanningService.completeScan() {
                    self.scanResult = result
                    onScanCompleted(result)
                }
            }
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Spacer()
                    Button("Done") {
                        scanningService.stopCurrentScan()
                        dismiss()
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                Spacer()
            }
        }
        .onAppear(perform: startScan)
    }
    
    private func startScan() {
        _ = scanningService.startNewScan(roomType: .other)
    }
}