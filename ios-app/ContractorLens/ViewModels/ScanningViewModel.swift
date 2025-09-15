import Foundation
import SwiftUI
import Combine
import ARKit

@MainActor
class ScanningViewModel: ObservableObject {
    @Published var scanState: ScanState = .idle
    @Published var roomData: Room?
    @Published var errorMessage: String?
    @Published var scanProgress: Double = 0.0
    
    private let roomScanner: RoomScanner
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.roomScanner = RoomScanner()
        setupBindings()
    }
    
    private func setupBindings() {
        roomScanner.$scanningState
            .sink { [weak self] scanningState in
                switch scanningState {
                case .notStarted:
                    self?.scanState = .idle
                case .scanning:
                    self?.scanState = .scanning
                case .completed:
                    self?.scanState = .completed
                case .error(let message):
                    self?.scanState = .error
                    self?.errorMessage = message
                }
            }
            .store(in: &cancellables)
        
        roomScanner.$errorMessage
            .sink { [weak self] errorMessage in
                self?.errorMessage = errorMessage
            }
            .store(in: &cancellables)
        
        roomScanner.$scanProgress
            .sink { [weak self] progress in
                self?.scanProgress = Double(progress)
            }
            .store(in: &cancellables)
    }
    
    func startScanning() {
        guard scanState == .idle || scanState == .error else { return }
        
        errorMessage = nil
        roomScanner.startCapture()
    }
    
    func stopScanning() {
        guard scanState == .scanning else { return }
        
        roomScanner.stopCapture()
    }
    
    func resetScan() {
        roomScanner.reset()
        scanState = .idle
        roomData = nil
        errorMessage = nil
        scanProgress = 0.0
    }
    
    var canStartScanning: Bool {
        scanState == .idle || scanState == .error
    }
    
    var canStopScanning: Bool {
        scanState == .scanning
    }
    
    var hasResults: Bool {
        scanState == .completed && roomData != nil
    }
    
    func processScan() {
        // This is a placeholder for what would be a network request
        // to send the scan data to the backend.
        
        // For now, we'll just use the dummy data from the RoomScanner.
        // In a real app, you would now send this `scanResult` to your backend.
        // For this example, we'll just move to the results view.
        
        // TODO: Implement networking call to submit scan data
    }
    
    var scanButtonTitle: String {
        switch scanState {
        case .idle, .error:
            return "Start Room Scan"
        case .scanning:
            return "Stop Scanning"
        case .completed:
            return "Scan Complete"
        }
    }
    
    var scanButtonColor: Color {
        switch scanState {
        case .idle, .error:
            return .blue
        case .scanning:
            return .red
        case .completed:
            return .green
        }
    }
}

enum ScanState {
    case idle
    case scanning
    case completed
    case error
    
    var description: String {
        switch self {
        case .idle:
            return "Ready to scan"
        case .scanning:
            return "Scanning room..."
        case .completed:
            return "Scan complete"
        case .error:
            return "Scan error"
        }
    }
}