
import SwiftUI

struct ResultsView: View {
    let estimate: Estimate
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    summaryHeader
                    
                    ForEach(estimate.csiDivisions) { division in
                        CSIDivisionView(division: division)
                    }
                }
                .padding()
            }
            .navigationTitle("Estimate Results")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estimate Summary")
                .font(.title3).bold()
            
            SummaryRow(label: "Grand Total", value: estimate.grandTotal.formattedCurrency, isTotal: true)
            Divider()
            SummaryRow(label: "Subtotal", value: estimate.subtotal.formattedCurrency)
            SummaryRow(label: "Material Total", value: estimate.materialTotal.formattedCurrency)
            SummaryRow(label: "Labor Total", value: estimate.laborTotal.formattedCurrency)
            SummaryRow(label: "Markup (".appendingFormat("%.1f%%", estimate.markupAmount / estimate.subtotal * 100).appending(")"), value: estimate.markupAmount.formattedCurrency)
            SummaryRow(label: "Tax", value: estimate.taxAmount.formattedCurrency)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct CSIDivisionView: View {
    let division: CSIDivision
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(division.csiCode) - \(division.divisionName)")
                    .font(.headline)
                Spacer()
                Text(division.totalCost.formattedCurrency)
                    .font(.headline)
            }
            .padding(.bottom, 4)
            
            ForEach(division.lineItems) { item in
                LineItemRow(item: item)
                Divider()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct LineItemRow: View {
    let item: LineItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.description)
                    .font(.subheadline).fontWeight(.medium)
                Spacer()
                Text(item.totalCost.formattedCurrency)
                    .font(.subheadline).fontWeight(.semibold)
            }
            
            HStack {
                Text("\(item.quantity.formattedMeasurement) \(item.unit) @ \(item.unitCost.formattedCurrency)/\(item.unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(item.type.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    var isTotal: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(isTotal ? .headline : .subheadline)
                .foregroundColor(isTotal ? .primary : .secondary)
            Spacer()
            Text(value)
                .font(isTotal ? .headline : .subheadline)
                .fontWeight(isTotal ? .bold : .regular)
        }
    }
}


/*
#Preview {
    ResultsView(estimate: MockEstimateGenerator.generate())
}
*/
