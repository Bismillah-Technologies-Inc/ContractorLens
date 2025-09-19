
import SwiftUI
import RoomPlan
import UIKit
import ARKit
import AVFoundation
import CoreImage
import simd

@available(iOS 17.0, *)
struct ScanningView: View {
    @StateObject private var scanningService = ScanningService()
    @Environment(\.dismiss) private var dismiss
    
    let projectName: String
    let onScanComplete: (ScanPackage) -> Void

    var body: some View {
        ZStack {
            RoomCaptureViewRepresentable(scanningService: scanningService, projectName: projectName, onScanComplete: onScanComplete)
                .ignoresSafeArea()

            VStack {
                if let instruction = scanningService.currentInstruction {
                    InstructionView(text: instruction)
                }
                Spacer()
                ScanControlsView(
                    scanState: scanningService.scanState,
                    onStopScan: { scanningService.stopScanning() },
                    onReset: { scanningService.resetScan() }
                )
            }
        }
        .navigationTitle("Scanning: \(projectName)")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { scanningService.stopScanning() }
        .onChange(of: scanningService.scanState) { newState in
            if case .completed = newState {
                dismiss()
            }
        }
        .alert("Scan Failed", isPresented: .constant(scanningService.scanState.isFailed), actions: {
            Button("Retry") { scanningService.retryScan() }
            Button("Cancel", role: .cancel) { dismiss() }
        }, message: {
            Text(scanningService.scanState.errorDescription)
        })
    }
}

@available(iOS 17.0, *)
struct RoomCaptureViewRepresentable: UIViewRepresentable {
    @ObservedObject var scanningService: ScanningService
    let projectName: String
    let onScanComplete: (ScanPackage) -> Void

    func makeUIView(context: Context) -> RoomCaptureView {
        let roomCaptureView = RoomCaptureView(frame: .zero)
        roomCaptureView.captureSession.delegate = context.coordinator
        scanningService.setup(with: roomCaptureView)
        // Start the scan here to ensure it only happens once.
        scanningService.startScanning()
        return roomCaptureView
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {}

    func makeCoordinator() -> RoomCaptureCoordinator {
        RoomCaptureCoordinator(scanningService: scanningService, projectName: projectName, onScanComplete: onScanComplete)
    }
}

@available(iOS 17.0, *)
class RoomCaptureCoordinator: NSObject, RoomCaptureSessionDelegate, RoomCaptureViewDelegate, NSCoding {
    var scanningService: ScanningService
    let projectName: String
    let onScanComplete: @escaping (ScanPackage) -> Void
    
    private var finalRoom: CapturedRoom?
    private var capturedFrames: [Data] = []
    private let ciContext = CIContext()
    
    private var frameCaptureTimer: Timer?
    private weak var arSession: ARSession?
    private let maxFramesToCapture = 20
    private let frameCaptureInterval: TimeInterval = 2.0

    init(scanningService: ScanningService, projectName: String, onScanComplete: @escaping (ScanPackage) -> Void) {
        self.scanningService = scanningService
        self.projectName = projectName
        self.onScanComplete = onScanComplete
        super.init()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func encode(with coder: NSCoder) {}

    private func startFrameCapture(arSession: ARSession) {
        self.arSession = arSession
        frameCaptureTimer?.invalidate()
        frameCaptureTimer = Timer.scheduledTimer(withTimeInterval: frameCaptureInterval, repeats: true) { [weak self] _ in
            self?.captureFrame()
        }
    }

    private func stopFrameCapture() {
        frameCaptureTimer?.invalidate()
        frameCaptureTimer = nil
    }

    private func captureFrame() {
        guard let frame = arSession?.currentFrame, capturedFrames.count < maxFramesToCapture else {
            frameCaptureTimer?.invalidate()
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            guard let imageData = self.processARFrameToJPEG(frame) else { return }
            DispatchQueue.main.async {
                self.capturedFrames.append(imageData)
            }
        }
    }

    private func processARFrameToJPEG(_ frame: ARFrame) -> Data? {
        let pixelBuffer = frame.capturedImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.8)
    }

    func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) { self.finalRoom = room }
    func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) { self.finalRoom = room }
    func captureSession(_ session: RoomCaptureSession, didChange room: CapturedRoom) { self.finalRoom = room }
    func captureSession(_ session: RoomCaptureSession, didRemove room: CapturedRoom) { self.finalRoom = nil }
    
    func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction) {
        DispatchQueue.main.async { self.scanningService.currentInstruction = instruction.description }
    }

    func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
        stopFrameCapture()
        DispatchQueue.main.async {
            self.scanningService.isScanning = false
            if let error = error { 
                self.scanningService.scanState = .failed(error); return 
            }
            guard let finalRoom = self.finalRoom else { 
                let missingDataError = NSError(domain: "ContractorLens", code: -1, userInfo: [NSLocalizedDescriptionKey: "Scan completed but final room data is missing."])
                self.scanningService.scanState = .failed(missingDataError); return
            }
            
            let scanPackage = ScanPackage(projectName: self.projectName, capturedRoom: finalRoom, capturedFrames: self.capturedFrames)
            self.onScanComplete(scanPackage)
            self.scanningService.scanState = .completed
        }
    }

    func captureSession(_ session: RoomCaptureSession, didFailWith error: Error) {
        stopFrameCapture()
        DispatchQueue.main.async {
            self.scanningService.isScanning = false
            self.scanningService.scanState = .failed(error)
        }
    }
    
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool { 
        startFrameCapture(arSession: roomDataForProcessing.arSession)
        return true 
    }
    func captureView(didPresent processedResult: CapturedRoom, error: Error?) { self.finalRoom = processedResult }
}

struct InstructionView: View {
    let text: String
    var body: some View {
        if !text.isEmpty {
            Text(text)
                .font(.headline).foregroundColor(.white).padding()
                .background(Color.black.opacity(0.6)).cornerRadius(12)
                .padding(.horizontal).multilineTextAlignment(.center)
                .transition(.opacity.animation(.easeInOut))
        }
    }
}

struct ScanControlsView: View {
    var scanState: ScanState
    var onStopScan: () -> Void
    var onReset: () -> Void

    var body: some View {
        HStack {
            Button(action: onStopScan) {
                Text("Done").fontWeight(.bold).frame(maxWidth: .infinity).padding()
                    .background(scanState == .scanning ? Color.blue : Color.gray)
                    .foregroundColor(.white).cornerRadius(12)
            }.disabled(scanState != .scanning)

            Button(action: onReset) {
                Text("Reset").fontWeight(.bold).frame(maxWidth: .infinity).padding()
                    .background(Color.gray).foregroundColor(.white).cornerRadius(12)
            }.disabled(scanState == .scanning)
        }.padding()
    }
}

extension ScanState {
    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }
    var errorDescription: String {
        if case .failed(let error) = self { return error.localizedDescription }
        return ""
    }
}

@available(iOS 17.0, *)
extension RoomCaptureSession.Instruction {
    var description: String {
        switch self {
        case .moveCloseToWall: return "Move closer to a wall."
        case .moveAwayFromWall: return "Move away from the wall."
        case .slowDown: return "Move more slowly."
        case .turnOnLight: return "Turn on more lights."
        case .normal: return ""
        case .lowTexture: return "Point at a wall with more texture."
        @unknown default: return "Scanning..."
        }
    }
}