import SwiftUI
import RoomPlan

@available(iOS 17.0, *)
struct ScanDetailView: View {
    let scan: ScanPackage

    // Correctly calculate areas using the documented `floors` and `walls` properties for iOS 17.
    private var floorArea: Double {
        scan.capturedRoom.floors.reduce(0) { $0 + $1.dimensions.area() }
    }
    
    private var wallArea: Double {
        scan.capturedRoom.walls.reduce(0) { $0 + $1.dimensions.area() }
    }
    
    // Correct date formatter
    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: scan.timestamp)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SummarySection(scan: scan, totalWallArea: wallArea, totalFloorArea: floorArea)
                
                SurfaceSection(title: "Walls", surfaces: scan.capturedRoom.walls)
                SurfaceSection(title: "Floors", surfaces: scan.capturedRoom.floors)
                SurfaceSection(title: "Windows", surfaces: scan.capturedRoom.windows)
                SurfaceSection(title: "Doors", surfaces: scan.capturedRoom.doors)
                
                ImageGallerySection(scan: scan)
            }
            .padding()
        }
        .navigationTitle(Text("Scan from \(formattedTimestamp)"))
        .background(Color(.systemGroupedBackground))
    }
}

@available(iOS 17.0, *)
private struct SummarySection: View {
    let scan: ScanPackage
    let totalWallArea: Double
    let totalFloorArea: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overall Summary").font(.title2).bold()
            SummaryRow(label: "Total Floor Area", value: "\(String(format: "%.1f", totalFloorArea)) sq ft")
            SummaryRow(label: "Total Wall Area", value: "\(String(format: "%.1f", totalWallArea)) sq ft")
            SummaryRow(label: "Total Windows", value: "\(scan.capturedRoom.windows.count)")
            SummaryRow(label: "Total Doors", value: "\(scan.capturedRoom.doors.count)")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

@available(iOS 17.0, *)
private struct SurfaceSection: View {
    let title: String
    let surfaces: [CapturedRoom.Surface]
    
    var body: some View {
        if !surfaces.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(title).font(.title2).bold()
                ForEach(Array(surfaces.enumerated()), id: \.offset) { index, surface in
                    VStack(alignment: .leading) {
                        Text("\(title.singularized) \(index + 1)").font(.headline)
                        SummaryRow(label: "Width", value: "\(String(format: "%.2f", surface.dimensions.x)) ft")
                        SummaryRow(label: "Height", value: "\(String(format: "%.2f", surface.dimensions.y)) ft")
                        SummaryRow(label: "Area", value: "\(String(format: "%.1f", surface.dimensions.area())) sq ft")
                    }
                    .padding(.bottom, 4)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

private struct ImageGallerySection: View {
    let scan: ScanPackage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Captured Images (\(scan.capturedFrames.count))").font(.title2).bold()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(scan.capturedFrames, id: \.self) { imageData in
                        if let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 150, height: 150)
                                .clipped()
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}



// MARK: - Helpers

extension SIMD3 where Scalar == Float {
    func area() -> Double {
        return Double(self.x * self.y)
    }
}

extension String {
    var singularized: String {
        if self.hasSuffix("s") {
            return String(self.dropLast())
        }
        return self
    }
}