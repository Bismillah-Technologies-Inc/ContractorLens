import SwiftUI
import RoomPlan
import UIKit
import ARKit

@available(iOS 16.0, *)
struct ScanningView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var scanningService = ScanningService()
    
    // This will be updated by the Coordinator
    @State private var scanCompleted = false
    @State private var scanResult: RoomScanResult? = nil

    var body: some View {
        ZStack {
            RoomCaptureViewRepresentable(scanningService: scanningService) {
                // This closure is called when the scan is complete
                self.scanCompleted = true
                // The service now holds the final result
                if #available(iOS 17.0, *) {
                    self.scanResult = scanningService.completeScan()
                }
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
        .sheet(isPresented: $scanCompleted) {
            if let result = scanResult {
                // Present the estimate results view upon completion
                EstimateResultsView(scanResult: result)
            } else {
                // Fallback for safety
                Text("Scan processing failed. Please try again.")
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
        
        // The scanning service will handle session setup
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
        var arSession: ARSession?
        var lastCameraTransform: simd_float4x4?
        var lastCaptureTime: TimeInterval = 0
        
        init(_ parent: RoomCaptureViewRepresentable) {
            self.parent = parent
            super.init()
            setupARSession()
        }
        
        private func setupARSession() {
            arSession = ARSession()
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal, .vertical]
            configuration.environmentTexturing = .automatic
            
            if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                configuration.sceneReconstruction = .mesh
            }
            
            arSession?.run(configuration)
        }

        // MARK: - Enhanced Snapshot Logic
        
        func startSnapshotTimer() {
            // Use adaptive timing instead of fixed 2-second intervals
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.captureIntelligentFrame()
                }
            }
        }

        func stopSnapshotTimer() {
            timer?.invalidate()
            timer = nil
            arSession?.pause()
        }

        @MainActor
        func captureIntelligentFrame() {
            guard let arSession = arSession,
                  let currentFrame = arSession.currentFrame else {
                // Fallback to old method if AR session not available
                takeSnapshot()
                return
            }
            
            // Check if we should capture this frame (adaptive timing)
            let currentTime = CACurrentMediaTime()
            guard currentTime - lastCaptureTime >= 0.5 else { return }
            
            // Check camera movement
            if let lastTransform = lastCameraTransform {
                let currentTransform = currentFrame.camera.transform
                let movement = distanceBetweenTransforms(lastTransform, currentTransform)
                if movement < 0.1 { return } // Not enough movement
            }
            
            // Process AR frame to PNG
            let ciImage = CIImage(cvPixelBuffer: currentFrame.capturedImage)
            let context = CIContext()
            
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                takeSnapshot() // Fallback
                return
            }
            
            let uiImage = UIImage(cgImage: cgImage)
            guard let pngData = uiImage.pngData() else {
                takeSnapshot() // Fallback
                return
            }
            
            print("📸 Coordinator: Enhanced capture (\(pngData.count) bytes)")
            
            // Update tracking
            lastCameraTransform = currentFrame.camera.transform
            lastCaptureTime = currentTime
            
            // Pass the captured frame to the scanning service
            parent.scanningService.addCapturedFrame(imageData: pngData)
        }
        
        // Fallback method for when AR session is not available
        @MainActor
        @objc func takeSnapshot() {
            guard let view = captureView else { return }

            let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
            let image = renderer.image { ctx in
                view.layer.render(in: ctx.cgContext)
            }

            if let jpegData = image.jpegData(compressionQuality: 0.7) {
                print("📸 Coordinator: Fallback snapshot captured, size: \(jpegData.count) bytes")
                // Pass the captured frame to the scanning service
                parent.scanningService.addCapturedFrame(imageData: jpegData)
            }
        }
        
        private func distanceBetweenTransforms(_ transform1: simd_float4x4, _ transform2: simd_float4x4) -> Float {
            let translation1 = transform1.columns.3
            let translation2 = transform2.columns.3
            
            let dx = translation1.x - translation2.x
            let dy = translation1.y - translation2.y
            let dz = translation1.z - translation2.z
            
            return sqrt(dx*dx + dy*dy + dz*dz)
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
