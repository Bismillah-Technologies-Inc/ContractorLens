import Foundation
import ARKit
import UIKit
import CoreImage
import simd

@available(iOS 16.0, *)
@MainActor
class ARFrameCaptureService: NSObject, ObservableObject {
    // MARK: - Properties
    private var arSession: ARSession?
    private var lastCameraTransform: simd_float4x4?
    private var lastCaptureTime: TimeInterval = 0
    private var ciContext: CIContext
    
    // Configuration
    private let minimumCaptureInterval: TimeInterval = 0.5  // Minimum 0.5 seconds between captures
    private let movementThreshold: Float = 0.1  // Minimum camera movement to trigger capture
    private let qualityThreshold: Double = 0.6  // Minimum quality score to accept frame
    
    // MARK: - Initialization
    override init() {
        // Create CIContext for image processing with optimal performance
        let options = [CIContextOption.useSoftwareRenderer: false] as [CIContextOption: Any]
        self.ciContext = CIContext(options: options)
        
        super.init()
        setupMemoryManagement()
    }
    
    deinit {
        cleanupMemoryManagement()
    }
    
    // MARK: - AR Session Management
    func configure(with arSession: ARSession) {
        self.arSession = arSession
        arSession.delegate = self
    }
    
    func startCapture() {
        guard let arSession = arSession else {
            print("❌ ARFrameCaptureService: ARSession not configured")
            return
        }
        
        // Ensure AR session is running with proper configuration
        if arSession.configuration == nil {
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal, .vertical]
            configuration.environmentTexturing = .automatic
            
            if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                configuration.sceneReconstruction = .mesh
            }
            
            arSession.run(configuration)
        }
        
        print("✅ ARFrameCaptureService: Started frame capture")
    }
    
    func stopCapture() {
        arSession?.pause()
        lastCameraTransform = nil
        lastCaptureTime = 0
        print("🛑 ARFrameCaptureService: Stopped frame capture")
    }
    
    // MARK: - Intelligent Frame Capture
    func shouldCaptureFrame() -> Bool {
        let currentTime = CACurrentMediaTime()
        
        // Check minimum time interval
        guard currentTime - lastCaptureTime >= minimumCaptureInterval else {
            return false
        }
        
        // Check camera movement if we have a previous transform
        if let lastTransform = lastCameraTransform,
           let currentFrame = arSession?.currentFrame {
            
            let currentTransform = currentFrame.camera.transform
            let movement = distanceBetweenTransforms(lastTransform, currentTransform)
            
            // Not enough movement
            if movement < movementThreshold {
                return false
            }
        }
        
        return true
    }
    
    func captureFrame() -> EnhancedProcessedFrame? {
        // Check memory usage before proceeding
        guard checkMemoryUsage() else {
            print("❌ ARFrameCaptureService: Memory usage too high, skipping frame capture")
            return nil
        }
        
        guard let currentFrame = arSession?.currentFrame else {
            print("❌ ARFrameCaptureService: No current AR frame available")
            return nil
        }
        
        // Check if we should capture this frame
        guard shouldCaptureFrame() else {
            return nil
        }
        
        do {
            let enhancedFrame = try processARFrame(currentFrame)
            
            // Update memory usage
            updateMemoryUsage(enhancedFrame)
            
            // Check for frame redundancy
            if isFrameRedundant(enhancedFrame) {
                print("⚠️ ARFrameCaptureService: Frame is redundant, skipping")
                return nil
            }
            
            // Apply intelligent frame selection
            if shouldSelectFrame(enhancedFrame) {
                print("✅ ARFrameCaptureService: Frame selected for Gemini analysis (score: \(frameScores[enhancedFrame.id] ?? 0.0))")
                
                // Add to recent frames history
                addFrameToRecentHistory(enhancedFrame)
                
                // Update tracking variables
                lastCameraTransform = currentFrame.camera.transform
                lastCaptureTime = CACurrentMediaTime()
                
                return enhancedFrame
            } else {
                print("⚠️ ARFrameCaptureService: Frame not selected (lower priority)")
                return nil
            }
            
        } catch {
            print("❌ ARFrameCaptureService: Failed to process AR frame: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Frame Processing
    private func processARFrame(_ frame: ARFrame) throws -> EnhancedProcessedFrame {
        // Convert CVPixelBuffer to CIImage
        let pixelBuffer = frame.capturedImage
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Apply image orientation correction if needed
        ciImage = ciImage.oriented(.right)  // Adjust based on device orientation
        
        // Create CGImage from CIImage
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            throw FrameProcessingError.imageConversionFailed
        }
        
        // Create UIImage and convert to PNG data (lossless)
        let uiImage = UIImage(cgImage: cgImage)
        guard let pngData = uiImage.pngData() else {
            throw FrameProcessingError.pngConversionFailed
        }
        
        // Calculate image quality metrics
        let quality = calculateImageQuality(uiImage)
        
        // Create frame metadata
        let metadata = createFrameMetadata(from: frame)
        
        // Create processing metadata
        let originalSize = uiImage.size.width * uiImage.size.height * 4  // Rough estimate
        let processingMetadata = ProcessingMetadata(
            originalSize: Int(originalSize),
            compressedSize: pngData.count,
            compressionRatio: Double(pngData.count) / originalSize
        )
        
        return EnhancedProcessedFrame(
            imageData: pngData,
            timestamp: Date(),
            metadata: metadata,
            quality: quality,
            mimeType: "image/png",
            processingMetadata: processingMetadata
        )
    }
    
    // MARK: - Quality Assessment
    private func calculateImageQuality(_ image: UIImage) -> FrameQuality {
        // Calculate sharpness using Laplacian variance
        let sharpness = calculateSharpness(image)
        
        // Calculate brightness
        let brightness = calculateBrightness(image)
        
        // Calculate contrast
        let contrast = calculateContrast(image)
        
        return FrameQuality(
            sharpness: sharpness,
            brightness: brightness,
            contrast: contrast
        )
    }
    
    private func calculateSharpness(_ image: UIImage) -> Double {
        guard let cgImage = image.cgImage else { return 0.0 }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var rawData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Calculate Laplacian variance for sharpness
        var sum: Double = 0
        var sumSquared: Double = 0
        var pixelCount = 0
        
        for y in 1..<height-1 {
            for x in 1..<width-1 {
                let centerIndex = (y * width + x) * bytesPerPixel
                let topIndex = ((y-1) * width + x) * bytesPerPixel
                let bottomIndex = ((y+1) * width + x) * bytesPerPixel
                let leftIndex = (y * width + (x-1)) * bytesPerPixel
                let rightIndex = (y * width + (x+1)) * bytesPerPixel
                
                // Convert to grayscale and calculate Laplacian
                let centerGray = Double(rawData[centerIndex]) * 0.299 +
                                Double(rawData[centerIndex + 1]) * 0.587 +
                                Double(rawData[centerIndex + 2]) * 0.114
                
                let topGray = Double(rawData[topIndex]) * 0.299 +
                             Double(rawData[topIndex + 1]) * 0.587 +
                             Double(rawData[topIndex + 2]) * 0.114
                
                let bottomGray = Double(rawData[bottomIndex]) * 0.299 +
                                Double(rawData[bottomIndex + 1]) * 0.587 +
                                Double(rawData[bottomIndex + 2]) * 0.114
                
                let leftGray = Double(rawData[leftIndex]) * 0.299 +
                              Double(rawData[leftIndex + 1]) * 0.587 +
                              Double(rawData[leftIndex + 2]) * 0.114
                
                let rightGray = Double(rawData[rightIndex]) * 0.299 +
                               Double(rawData[rightIndex + 1]) * 0.587 +
                               Double(rawData[rightIndex + 2]) * 0.114
                
                // Laplacian operator
                let laplacian = -4 * centerGray + topGray + bottomGray + leftGray + rightGray
                
                sum += laplacian
                sumSquared += laplacian * laplacian
                pixelCount += 1
            }
        }
        
        if pixelCount == 0 { return 0.0 }
        
        let mean = sum / Double(pixelCount)
        let variance = (sumSquared / Double(pixelCount)) - (mean * mean)
        
        // Normalize variance to 0-1 range (rough approximation)
        let normalizedSharpness = min(variance / 10000.0, 1.0)
        return normalizedSharpness
    }
    
    private func calculateBrightness(_ image: UIImage) -> Double {
        guard let cgImage = image.cgImage else { return 0.0 }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        var rawData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var totalBrightness: Double = 0
        var pixelCount = 0
        
        for i in stride(from: 0, to: rawData.count, by: bytesPerPixel) {
            let r = Double(rawData[i])
            let g = Double(rawData[i + 1])
            let b = Double(rawData[i + 2])
            
            // Calculate perceived brightness
            let brightness = (r * 0.299 + g * 0.587 + b * 0.114) / 255.0
            totalBrightness += brightness
            pixelCount += 1
        }
        
        return pixelCount > 0 ? totalBrightness / Double(pixelCount) : 0.0
    }
    
    private func calculateContrast(_ image: UIImage) -> Double {
        guard let cgImage = image.cgImage else { return 0.0 }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        var rawData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var minBrightness: Double = 1.0
        var maxBrightness: Double = 0.0
        
        for i in stride(from: 0, to: rawData.count, by: bytesPerPixel) {
            let r = Double(rawData[i])
            let g = Double(rawData[i + 1])
            let b = Double(rawData[i + 2])
            
            let brightness = (r * 0.299 + g * 0.587 + b * 0.114) / 255.0
            minBrightness = min(minBrightness, brightness)
            maxBrightness = max(maxBrightness, brightness)
        }
        
        return maxBrightness - minBrightness
    }
    
    // MARK: - Metadata Creation
    private func createFrameMetadata(from frame: ARFrame) -> FrameMetadata {
        let depthAvailable = frame.sceneDepth != nil
        
        return FrameMetadata(
            cameraTransform: frame.camera.transform,
            trackingState: frame.camera.trackingState,
            lightingEstimate: frame.lightEstimate,
            cameraIntrinsics: frame.camera.intrinsics,
            depthAvailable: depthAvailable,
            frameTimestamp: frame.timestamp
        )
    }
    
    // MARK: - Frame Deduplication
    private var recentFrames: [EnhancedProcessedFrame] = []
    private let maxRecentFrames = 10  // Keep track of last 10 frames for comparison
    private let similarityThreshold: Double = 0.85  // Similarity threshold (0-1)
    
    func isFrameRedundant(_ newFrame: EnhancedProcessedFrame) -> Bool {
        // If we don't have enough recent frames, it's not redundant
        guard recentFrames.count >= 3 else { return false }
        
        // Compare with recent frames
        for recentFrame in recentFrames.suffix(3) {  // Check last 3 frames
            if calculateFrameSimilarity(newFrame, recentFrame) > similarityThreshold {
                return true
            }
        }
        
        return false
    }
    
    private func calculateFrameSimilarity(_ frame1: EnhancedProcessedFrame, _ frame2: EnhancedProcessedFrame) -> Double {
        // Simple similarity based on camera position and orientation
        guard let metadata1 = frame1.metadata, let metadata2 = frame2.metadata else {
            return 0.0
        }
        
        // Calculate position similarity
        let position1 = metadata1.cameraTransform.matrix.columns.3
        let position2 = metadata2.cameraTransform.matrix.columns.3
        
        let positionDistance = distanceBetweenPositions(position1, position2)
        let maxPositionDistance = 1.0  // 1 meter threshold
        let positionSimilarity = max(0.0, 1.0 - (positionDistance / maxPositionDistance))
        
        // Calculate orientation similarity (simplified)
        let orientationSimilarity = calculateOrientationSimilarity(
            metadata1.cameraTransform.matrix,
            metadata2.cameraTransform.matrix
        )
        
        // Combined similarity (weighted average)
        return (positionSimilarity * 0.6) + (orientationSimilarity * 0.4)
    }
    
    private func distanceBetweenPositions(_ pos1: SIMD4<Float>, _ pos2: SIMD4<Float>) -> Double {
        let dx = Double(pos1.x - pos2.x)
        let dy = Double(pos1.y - pos2.y)
        let dz = Double(pos1.z - pos2.z)
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
    
    private func calculateOrientationSimilarity(_ transform1: simd_float4x4, _ transform2: simd_float4x4) -> Double {
        // Extract forward vectors from transforms
        let forward1 = -transform1.columns.2  // Negative Z is forward in camera space
        let forward2 = -transform2.columns.2
        
        // Calculate dot product for angle similarity
        let dotProduct = Double(
            forward1.x * forward2.x +
            forward1.y * forward2.y +
            forward1.z * forward2.z
        )
        
        // Convert to similarity score (1.0 = identical, 0.0 = opposite)
        return (dotProduct + 1.0) / 2.0
    }
    
    func addFrameToRecentHistory(_ frame: EnhancedProcessedFrame) {
        recentFrames.append(frame)
        
        // Keep only the most recent frames
        if recentFrames.count > maxRecentFrames {
            recentFrames.removeFirst()
        }
    }
    
    func clearFrameHistory() {
        recentFrames.removeAll()
    }
    
    // MARK: - Intelligent Frame Selection
    private var selectedFrames: [EnhancedProcessedFrame] = []
    private let maxSelectedFrames = 15  // Maximum frames to send to Gemini
    private var frameScores: [UUID: Double] = [:]
    
    func shouldSelectFrame(_ frame: EnhancedProcessedFrame) -> Bool {
        // Calculate frame score based on multiple factors
        let score = calculateFrameScore(frame)
        
        // Store the score
        frameScores[frame.id] = score
        
        // If we haven't reached the maximum, always select
        if selectedFrames.count < maxSelectedFrames {
            selectedFrames.append(frame)
            return true
        }
        
        // Find the lowest scoring frame
        guard let lowestScoreFrame = selectedFrames.min(by: { (frameScores[$0.id] ?? 0) < (frameScores[$1.id] ?? 0) }) else {
            return false
        }
        
        let lowestScore = frameScores[lowestScoreFrame.id] ?? 0
        
        // Replace if new frame has higher score
        if score > lowestScore {
            if let index = selectedFrames.firstIndex(where: { $0.id == lowestScoreFrame.id }) {
                selectedFrames[index] = frame
                frameScores.removeValue(forKey: lowestScoreFrame.id)
                return true
            }
        }
        
        return false
    }
    
    private func calculateFrameScore(_ frame: EnhancedProcessedFrame) -> Double {
        var score: Double = 0.0
        
        // Quality score (40% weight)
        if let quality = frame.quality {
            score += quality.overall * 0.4
        }
        
        // Uniqueness score (30% weight)
        let uniquenessScore = calculateFrameUniqueness(frame)
        score += uniquenessScore * 0.3
        
        // Information density score (20% weight)
        let infoScore = calculateInformationDensity(frame)
        score += infoScore * 0.2
        
        // Recency bonus (10% weight) - prefer more recent frames
        let ageInSeconds = Date().timeIntervalSince(frame.timestamp)
        let recencyScore = max(0.0, 1.0 - (ageInSeconds / 30.0))  // Decay over 30 seconds
        score += recencyScore * 0.1
        
        return score
    }
    
    private func calculateFrameUniqueness(_ frame: EnhancedProcessedFrame) -> Double {
        guard let frameMetadata = frame.metadata else { return 0.5 }
        
        var uniquenessScore = 1.0
        
        // Compare with selected frames
        for selectedFrame in selectedFrames {
            guard let selectedMetadata = selectedFrame.metadata else { continue }
            
            // Position uniqueness
            let positionDistance = distanceBetweenPositions(
                frameMetadata.cameraTransform.matrix.columns.3,
                selectedMetadata.cameraTransform.matrix.columns.3
            )
            
            // Reduce uniqueness score based on proximity
            if positionDistance < 0.5 {  // Within 0.5 meters
                uniquenessScore *= 0.7
            } else if positionDistance < 1.0 {  // Within 1 meter
                uniquenessScore *= 0.85
            }
            
            // Orientation uniqueness
            let orientationSimilarity = calculateOrientationSimilarity(
                frameMetadata.cameraTransform.matrix,
                selectedMetadata.cameraTransform.matrix
            )
            
            if orientationSimilarity > 0.9 {  // Very similar orientation
                uniquenessScore *= 0.8
            }
        }
        
        return uniquenessScore
    }
    
    private func calculateInformationDensity(_ frame: EnhancedProcessedFrame) -> Double {
        // Estimate information density based on various factors
        
        var densityScore = 0.5  // Base score
        
        // Quality contributes to information density
        if let quality = frame.quality {
            if quality.sharpness > 0.7 {
                densityScore += 0.2  // Sharp images have more detail
            }
            if quality.contrast > 0.6 {
                densityScore += 0.1  // High contrast shows more features
            }
        }
        
        // Lighting affects information density
        if let metadata = frame.metadata,
           let lighting = metadata.lightingEstimate,
           lighting > 500 {  // Good lighting
            densityScore += 0.1
        }
        
        // Tracking state affects reliability
        if let metadata = frame.metadata,
           metadata.trackingState == "normal" {
            densityScore += 0.1
        }
        
        return min(densityScore, 1.0)
    }
    
    func getSelectedFrames() -> [EnhancedProcessedFrame] {
        // Sort by score (highest first) and return top frames
        return selectedFrames.sorted { (frameScores[$0.id] ?? 0) > (frameScores[$1.id] ?? 0) }
    }
    
    func clearSelectedFrames() {
        selectedFrames.removeAll()
        frameScores.removeAll()
    }
    
    // MARK: - Memory Management
    private var memoryWarningObserver: NSObjectProtocol?
    private var totalMemoryUsed: Int = 0
    private let maxMemoryUsage: Int = 50 * 1024 * 1024  // 50MB limit
    
    private func setupMemoryManagement() {
        // Register for memory warnings
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }
    
    private func cleanupMemoryManagement() {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
            memoryWarningObserver = nil
        }
    }
    
    private func handleMemoryWarning() {
        print("⚠️ ARFrameCaptureService: Memory warning received, cleaning up")
        
        // Aggressive cleanup on memory warning
        clearFrameHistory()
        clearSelectedFrames()
        
        // Force garbage collection hints
        totalMemoryUsed = 0
    }
    
    private func checkMemoryUsage() -> Bool {
        // Estimate memory usage
        let frameMemory = selectedFrames.reduce(0) { $0 + $1.imageData.count }
        let historyMemory = recentFrames.reduce(0) { $0 + $1.imageData.count }
        totalMemoryUsed = frameMemory + historyMemory
        
        if totalMemoryUsed > maxMemoryUsage {
            print("⚠️ ARFrameCaptureService: Memory usage high (\(totalMemoryUsed) bytes), triggering cleanup")
            performMemoryCleanup()
            return false  // Don't capture new frames
        }
        
        return true
    }
    
    private func performMemoryCleanup() {
        // Remove oldest frames from history
        if recentFrames.count > 5 {
            recentFrames.removeFirst(recentFrames.count - 5)
        }
        
        // Remove lowest scoring frames if we have too many
        if selectedFrames.count > 8 {
            let sortedFrames = selectedFrames.sorted { (frameScores[$0.id] ?? 0) < (frameScores[$1.id] ?? 0) }
            let framesToRemove = sortedFrames.prefix(selectedFrames.count - 8)
            
            for frame in framesToRemove {
                if let index = selectedFrames.firstIndex(where: { $0.id == frame.id }) {
                    selectedFrames.remove(at: index)
                    frameScores.removeValue(forKey: frame.id)
                }
            }
        }
    }
    
    private func updateMemoryUsage(_ frame: EnhancedProcessedFrame) {
        totalMemoryUsed += frame.imageData.count
    }
}

// MARK: - ARSession Delegate
@available(iOS 16.0, *)
extension ARFrameCaptureService: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Optional: Could trigger capture based on frame updates
        // For now, capture is triggered manually by the coordinator
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("❌ ARFrameCaptureService: AR session failed: \(error.localizedDescription)")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("⚠️ ARFrameCaptureService: AR session interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("✅ ARFrameCaptureService: AR session interruption ended")
    }
}

// MARK: - Error Types
enum FrameProcessingError: Error {
    case imageConversionFailed
    case pngConversionFailed
    case qualityAssessmentFailed
    case metadataCreationFailed
}

// MARK: - Extensions
extension ARCamera.TrackingState {
    var description: String {
        switch self {
        case .notAvailable:
            return "notAvailable"
        case .limited(let reason):
            return "limited(\(reason.rawValue))"
        case .normal:
            return "normal"
        @unknown default:
            return "unknown"
        }
    }
}