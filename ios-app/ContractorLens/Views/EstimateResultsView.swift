import SwiftUI

/// A view that displays the detailed cost estimate or a confirmation of the saved scan.
struct EstimateResultsView: View {
    
    // The estimate data, if available.
    let estimate: Estimate?
    // The scan result, for context.
    let scanResult: RoomScanResult?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if let estimate = estimate {
                    EstimateDetailView(estimate: estimate)
                } else {
                    // Fallback to "Scan Saved" if no estimate is passed (offline mode)
                    ScanSavedView()
                }
            }
            .navigationTitle(estimate != nil ? "Estimate Details" : "Scan Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Subviews

struct ScanSavedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            VStack(spacing: 12) {
                Text("Scan Saved Successfully")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Your scan data has been saved to the device.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Spacer()
            Spacer()
        }
        .padding()
    }
}

struct EstimateDetailView: View {
    let estimate: Estimate
    
    var body: some View {
        List {
            // Header Section
            Section {
                HStack {
                    Text("Grand Total")
                        .font(.headline)
                    Spacer()
                    Text(formatCurrency(estimate.grandTotal))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                MetadataRow(label: "Finish Level", value: estimate.metadata.finishLevel.capitalized)
                MetadataRow(label: "Total Labor Hours", value: String(format: "%.1f hrs", estimate.metadata.totalLaborHours))
            }
            
            // CSI Divisions
            ForEach(estimate.csiDivisions) { division in
                Section(header: Text("\(division.csiCode) - \(division.divisionName)")) {
                    DisclosureGroup {
                        ForEach(division.lineItems) { item in
                            LineItemRow(item: item)
                        }
                    } label: {
                        HStack {
                            Text("Division Total")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatCurrency(division.totalCost))
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

struct MetadataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct LineItemRow: View {
    let item: LineItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.description)
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "$%.2f", item.totalCost))
            }
            
            HStack {
                Text("\(String(format: "%.2f", item.quantity)) \(item.unit)")
                Spacer()
                Text("\(item.type.capitalized)")
                    .font(.caption)
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            if let specs = item.specifications {
                Text("\(item.manufacturer ?? "") \(specs.modelNumber ?? "")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    EstimateResultsView(estimate: nil, scanResult: nil)
}