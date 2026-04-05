
import SwiftUI
import RoomPlan
import UIKit

@available(iOS 16.0, *)
struct ScanningView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var scanningService = ScanningService()
    
    // This will be updated by the Coordinator
    @State private var scanCompleted = false
    @State private var scanResult: RoomScanResult? = nil
    
    // Optional closure to handle scan result externally
    var onScanCompleted: ((RoomScanResult) -> Void)? = nil

    var body: some View {
        ZStack {
            RoomCaptureViewRepresentable(scanningService: scanningService) {
                // This closure is called when the scan is complete
                self.scanCompleted = true
                // The service now holds the final result
                self.scanResult = scanningService.completeScan()
            }
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Spacer()
                    Button("Done") {
                        // Manually stop the session if the user taps Done
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
        .onChange(of: scanCompleted) { completed in
            if completed, let result = scanResult {
                if let onScanCompleted = onScanCompleted {
                    onScanCompleted(result)
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $scanCompleted) {
            if onScanCompleted == nil {
                if let result = scanResult {
                    EstimateResultsView(scanResult: result)
                } else {
                    Text("Scan processing failed. Please try again.")
                }
            }
        }
    }
    
    private func startScan() {
        // The scanning service now manages the RoomScanner
        _ = scanningService.startNewScan(roomType: .other) 
    }
}


@available(iOS 16.0, *)
struct RoomCaptureViewRepresentable: UIViewRepresentable {
    let scanningService: ScanningService
    var onScanCompleted: () -> Void
    
    func makeUIView(context: Context) -> RoomCaptureView {
        let roomCaptureView = RoomCaptureView(frame: .zero)
        
        // Use the session from the scanningService's RoomScanner
        roomCaptureView.captureSession = scanningService.roomScanner.session!
        
        // The coordinator will handle receiving data from the session.
        scanningService.roomScanner.session?.delegate = context.coordinator
        
        // Pass a reference to the view to the coordinator for snapshots
        context.coordinator.captureView = roomCaptureView
        context.coordinator.startSnapshotTimer()
        
        return roomCaptureView
    }
    
    func updateUIView(_ uiView: RoomCaptureView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, RoomCaptureSessionDelegate {
        var parent: RoomCaptureViewRepresentable
        var captureView: RoomCaptureView?
        var timer: Timer?

        init(_ parent: RoomCaptureViewRepresentable) {
            self.parent = parent
        }

        // MARK: - Snapshot Logic
        
        func startSnapshotTimer() {
            // Take a snapshot every 2 seconds
            timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                self?.takeSnapshot()
            }
        }

        func stopSnapshotTimer() {
            timer?.invalidate()
            timer = nil
        }

        @objc func takeSnapshot() {
            guard let view = captureView else { return }

            let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
            let image = renderer.image { ctx in
                view.layer.render(in: ctx.cgContext)
            }

            if let jpegData = image.jpegData(compressionQuality: 0.7) {
                print("📸 Snapshot captured, size: \(jpegData.count) bytes")
                // Pass the captured frame to the scanning service
                parent.scanningService.addCapturedFrame(imageData: jpegData)
            }
        }
        
        // MARK: - RoomCaptureSessionDelegate
        
        func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
            stopSnapshotTimer()
            
            if let error = error {
                print("❌ Error ending capture session: \(error.localizedDescription)")
                // Handle the error state appropriately
                return
            }
            
            // The RoomScanner instance (delegate) will also receive this call and store the final room data.
            // We just need to signal back to the SwiftUI view that we are done.
            parent.onScanCompleted()
        }
    }
}
