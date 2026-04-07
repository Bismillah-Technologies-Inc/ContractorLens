import Foundation
import Combine
import RoomPlan

class ScanningService: ObservableObject {
    @Published var isScanning = false
    @Published var isModelReadyForExport = false
    @Published var capturedRoom: CapturedRoom?
    @Published var currentInstruction: String?
    @Published var errorMessage: String?
    @Published var scanProgress: Double = 0.0
    @Published var scanState: ScanState = .idle

    private var roomCaptureView: RoomCaptureView?

    func setup(with roomCaptureView: RoomCaptureView) {
        self.roomCaptureView = roomCaptureView
    }

    func startScanning() {
        guard !isScanning else { return }
        print("🔵 ScanningService: Start scanning requested.")

        self.isScanning = true
        self.scanState = .scanning

        let configuration = RoomCaptureSession.Configuration()
        roomCaptureView?.captureSession.run(configuration: configuration)
    }

    func stopScanning() {
        guard isScanning else { return }
        print("🔵 ScanningService: Stop scanning requested.")
        isScanning = false
        roomCaptureView?.captureSession.stop()
    }

    func resetScan() {
        isModelReadyForExport = false
        capturedRoom = nil
        currentInstruction = nil
        errorMessage = nil
        scanProgress = 0.0
        self.scanState = .idle
        print("🔵 ScanningService: Scan state reset.")
    }

    func retryScan() {
        resetScan()
        startScanning()
    }
}

enum ScanState: Equatable {
    static func == (lhs: ScanState, rhs: ScanState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.scanning, .scanning),
             (.completed, .completed):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }

    case idle
    case scanning
    case completed
    case failed(Error)

    var description: String {
        switch self {
        case .idle:
            return "Ready to scan"
        case .scanning:
            return "Scanning room..."
        case .completed:
            return "Scan complete"
        case .failed(let error):
            return "Scan Failed: \(error.localizedDescription)"
        }
    }
}
