import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers

struct ProjectEstimateView: View {
    let project: Project
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var pdfData: Data?
    @State private var errorMessage: String?
    @State private var showError = false
    
    private var roomsWithEstimates: [(room: Room, estimate: Estimate)] {
        project.rooms.compactMap { room in
            guard let estimate = room.getEstimate() else { return nil }
            return (room: room, estimate: estimate)
        }
    }
    
    private var totalMaterial: Double {
        roomsWithEstimates.reduce(0) { $0 + $1.estimate.materialTotal }
    }
    
    private var totalLabor: Double {
        roomsWithEstimates.reduce(0) { $0 + $1.estimate.laborTotal }
    }
    
    private var grandTotal: Double {
        roomsWithEstimates.reduce(0) { $0 + $1.estimate.grandTotal }
    }
    
    var body: some View {
        NavigationView {
            List {
                if roomsWithEstimates.isEmpty {
                    ContentUnavailableView(
                        "No Estimates",
                        systemImage: "doc.text",
                        description: Text("Generate estimates for individual rooms first.")
                    )
                } else {
                    Section(header: Text("Room Estimates")) {
                        ForEach(roomsWithEstimates, id: \.room.id) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.room.name.isEmpty ? "Unnamed Room" : item.room.name)
                                    .font(.headline)
                                Text(item.room.scopeDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                HStack {
                                    Text("Total:")
                                    Spacer()
                                    Text(String(format: "$%.2f", item.estimate.grandTotal))
                                        .fontWeight(.semibold)
                                }
                                .font(.caption)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Section(header: Text("Project Total")) {
                        LabeledContent("Material", value: String(format: "$%.2f", totalMaterial))
                        LabeledContent("Labor", value: String(format: "$%.2f", totalLabor))
                        LabeledContent("Grand Total", value: String(format: "$%.2f", grandTotal))
                    }
                    
                    Section {
                        Button("Generate Project PDF") {
                            generateProjectPDF()
                        }
                    }
                }
            }
            .navigationTitle("Project Estimate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let pdfData = pdfData {
                    ShareSheet(activityItems: [pdfData])
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }
    
    private func generateProjectPDF() {
        guard !roomsWithEstimates.isEmpty else {
            errorMessage = "No room estimates available."
            showError = true
            return
        }
        
        guard let data = PDFGenerator.generateProjectEstimatePDF(for: project, roomsWithEstimates: roomsWithEstimates) else {
            errorMessage = "Failed to generate project PDF."
            showError = true
            return
        }
        
        pdfData = data
        showingShareSheet = true
    }
}

// MARK: - PDF Generator Extension

extension PDFGenerator {
    static func generateProjectEstimatePDF(for project: Project, roomsWithEstimates: [(room: Room, estimate: Estimate)]) -> Data? {
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11.0 * 72.0
        let margin = 0.5 * 72.0
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Title
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let title = "Project Estimate"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            let titleSize = title.size(withAttributes: titleAttributes)
            title.draw(at: CGPoint(x: margin, y: pageHeight - margin - titleSize.height), withAttributes: titleAttributes)
            
            // Project info
            let projectFont = UIFont.systemFont(ofSize: 12)
            var yPosition = pageHeight - margin - titleSize.height - 30
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .shortest
            
            let projectInfo = """
            Project: \(project.name)
            Client: \(project.clientName ?? "N/A")
            Date: \(dateFormatter.string(from: Date()))
            Rooms: \(roomsWithEstimates.count)
            """
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            
            let infoAttributes: [NSAttributedString.Key: Any] = [
                .font: projectFont,
                .foregroundColor: UIColor.darkGray,
                .paragraphStyle: paragraphStyle
            ]
            
            projectInfo.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: infoAttributes)
            yPosition -= 80
            
            // Grand total
            let totalFont = UIFont.boldSystemFont(ofSize: 18)
            let grandTotal = roomsWithEstimates.reduce(0) { $0 + $1.estimate.grandTotal }
            let totalString = String(format: "Project Total: $%.2f", grandTotal)
            let totalAttributes: [NSAttributedString.Key: Any] = [
                .font: totalFont,
                .foregroundColor: UIColor.black
            ]
            totalString.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: totalAttributes)
            yPosition -= 30
            
            // Room breakdowns
            for item in roomsWithEstimates {
                if yPosition < margin + 200 {
                    context.beginPage()
                    yPosition = pageHeight - margin
                }
                
                let roomFont = UIFont.boldSystemFont(ofSize: 14)
                let roomName = item.room.name.isEmpty ? "Unnamed Room" : item.room.name
                let roomString = "\(roomName) - \(item.room.scopeDescription)"
                roomString.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: [.font: roomFont])
                yPosition -= 20
                
                // Room totals
                let roomTotalFont = UIFont.systemFont(ofSize: 12)
                let roomTotals = "Material: \(String(format: "$%.2f", item.estimate.materialTotal)) | Labor: \(String(format: "$%.2f", item.estimate.laborTotal)) | Total: \(String(format: "$%.2f", item.estimate.grandTotal))"
                roomTotals.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: [.font: roomTotalFont])
                yPosition -= 30
                
                // Line items (optional, could be omitted for brevity)
                // For now, we'll just show a few line items per room
                let lineItemFont = UIFont.systemFont(ofSize: 10)
                for division in item.estimate.csiDivisions.prefix(2) { // limit to first 2 divisions
                    for lineItem in division.lineItems.prefix(3) { // limit to first 3 items per division
                        if yPosition < margin + 50 {
                            context.beginPage()
                            yPosition = pageHeight - margin
                        }
                        let lineString = "  - \(lineItem.description): \(String(format: "$%.2f", lineItem.totalCost))"
                        lineString.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: [.font: lineItemFont])
                        yPosition -= 14
                    }
                }
                yPosition -= 20
            }
            
            // Footer
            let footerFont = UIFont.italicSystemFont(ofSize: 10)
            let footer = "Generated by ContractorLens"
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: footerFont,
                .foregroundColor: UIColor.gray
            ]
            footer.draw(at: CGPoint(x: margin, y: margin), withAttributes: footerAttributes)
        }
        
        return data
    }
}