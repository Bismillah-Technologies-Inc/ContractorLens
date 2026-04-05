import SwiftUI
import SwiftData

struct EstimateEditView: View {
    var room: Room
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var estimate: Estimate
    @State private var markupPercentage: Double
    @State private var showingAddLineItem = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    init(room: Room) {
        self.room = room
        if let existingEstimate = room.getEstimate() {
            _estimate = State(initialValue: existingEstimate)
            _markupPercentage = State(initialValue: existingEstimate.metadata.finishLevel == "standard" ? 0.5 : 0.0)
        } else {
            // Create a placeholder estimate (should not happen)
            let placeholder = Estimate(
                subtotal: 0,
                materialTotal: 0,
                laborTotal: 0,
                markupAmount: 0,
                taxAmount: 0,
                grandTotal: 0,
                csiDivisions: [],
                metadata: EstimateMetadata(totalLaborHours: 0, finishLevel: "standard", calculationDate: "", engineVersion: "1.0")
            )
            _estimate = State(initialValue: placeholder)
            _markupPercentage = State(initialValue: 0.5)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Markup")) {
                    HStack {
                        Text("Markup Percentage")
                        Spacer()
                        TextField("", value: $markupPercentage, format: .percent)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    Button("Apply Markup to All") {
                        applyMarkupToAll()
                    }
                }
                
                ForEach(estimate.csiDivisions) { division in
                    Section(header: Text("\(division.csiCode) - \(division.divisionName)")) {
                        ForEach(division.lineItems) { item in
                            LineItemEditRow(item: item) { updatedItem in
                                updateLineItem(updatedItem)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Add Custom Line Item") {
                        showingAddLineItem = true
                    }
                }
                
                Section(header: Text("Summary")) {
                    LabeledContent("Subtotal", value: String(format: "$%.2f", estimate.subtotal))
                    LabeledContent("Markup", value: String(format: "$%.2f", estimate.markupAmount))
                    LabeledContent("Tax", value: String(format: "$%.2f", estimate.taxAmount))
                    LabeledContent("Grand Total", value: String(format: "$%.2f", estimate.grandTotal))
                }
            }
            .navigationTitle("Edit Estimate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEstimate()
                    }
                }
            }
            .sheet(isPresented: $showingAddLineItem) {
                AddLineItemView { newItem in
                    addLineItem(newItem)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }
    
    private func updateLineItem(_ updatedItem: LineItem) {
        // Find and replace the line item in the estimate
        for i in 0..<estimate.csiDivisions.count {
            for j in 0..<estimate.csiDivisions[i].lineItems.count {
                if estimate.csiDivisions[i].lineItems[j].id == updatedItem.id {
                    estimate.csiDivisions[i].lineItems[j] = updatedItem
                    recalculateTotals()
                    return
                }
            }
        }
    }
    
    private func addLineItem(_ item: LineItem) {
        // Add to a new division or existing division
        let divisionName = "Custom"
        if let index = estimate.csiDivisions.firstIndex(where: { $0.divisionName == divisionName }) {
            estimate.csiDivisions[index].lineItems.append(item)
        } else {
            let newDivision = CSIDivision(
                csiCode: "99",
                divisionName: divisionName,
                totalCost: item.totalCost,
                laborHours: item.laborDetails?.totalHours ?? 0,
                lineItems: [item]
            )
            estimate.csiDivisions.append(newDivision)
        }
        recalculateTotals()
    }
    
    private func applyMarkupToAll() {
        // Recalculate markup for each line item based on new percentage
        // This is a simplified approach: we just update the markup amount and grand total
        let subtotal = estimate.subtotal
        let newMarkupAmount = subtotal * markupPercentage
        estimate = Estimate(
            subtotal: subtotal,
            materialTotal: estimate.materialTotal,
            laborTotal: estimate.laborTotal,
            markupAmount: newMarkupAmount,
            taxAmount: estimate.taxAmount,
            grandTotal: subtotal + newMarkupAmount + estimate.taxAmount,
            csiDivisions: estimate.csiDivisions,
            metadata: EstimateMetadata(
                totalLaborHours: estimate.metadata.totalLaborHours,
                finishLevel: markupPercentage == 0.5 ? "standard" : "custom",
                calculationDate: estimate.metadata.calculationDate,
                engineVersion: estimate.metadata.engineVersion
            )
        )
    }
    
    private func recalculateTotals() {
        var materialTotal: Double = 0
        var laborTotal: Double = 0
        var totalHours: Double = 0
        
        for division in estimate.csiDivisions {
            for item in division.lineItems {
                // Assuming each line item's totalCost includes both material and labor
                // For simplicity, we'll split based on unit cost and labor details
                // This is a rough approximation
                let materialCost = item.quantity * item.unitCost
                let laborHours = item.laborDetails?.totalHours ?? 0
                let laborCost = laborHours * (item.laborDetails?.skillLevel == "high" ? 85 : 65)
                materialTotal += materialCost
                laborTotal += laborCost
                totalHours += laborHours
            }
        }
        
        let subtotal = materialTotal + laborTotal
        let markupAmount = subtotal * markupPercentage
        let taxAmount = 0.0
        let grandTotal = subtotal + markupAmount + taxAmount
        
        estimate = Estimate(
            subtotal: subtotal,
            materialTotal: materialTotal,
            laborTotal: laborTotal,
            markupAmount: markupAmount,
            taxAmount: taxAmount,
            grandTotal: grandTotal,
            csiDivisions: estimate.csiDivisions,
            metadata: EstimateMetadata(
                totalLaborHours: totalHours,
                finishLevel: markupPercentage == 0.5 ? "standard" : "custom",
                calculationDate: estimate.metadata.calculationDate,
                engineVersion: estimate.metadata.engineVersion
            )
        )
    }
    
    private func saveEstimate() {
        room.setEstimate(estimate)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save estimate: \(error.localizedDescription)"
            showError = true
        }
    }
}

struct LineItemEditRow: View {
    let item: LineItem
    var onUpdate: (LineItem) -> Void
    
    @State private var isEnabled: Bool = true
    @State private var quantity: Double
    @State private var unitCost: Double
    
    init(item: LineItem, onUpdate: @escaping (LineItem) -> Void) {
        self.item = item
        self.onUpdate = onUpdate
        _quantity = State(initialValue: item.quantity)
        _unitCost = State(initialValue: item.unitCost)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                Text(item.description)
                    .font(.headline)
                Spacer()
                Text(String(format: "$%.2f", item.totalCost))
                    .foregroundColor(.secondary)
            }
            
            if isEnabled {
                HStack {
                    Text("Qty:")
                    TextField("", value: $quantity, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text(item.unit)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Unit Cost:")
                    TextField("", value: $unitCost, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                .font(.caption)
                .onChange(of: quantity) { _ in updateItem() }
                .onChange(of: unitCost) { _ in updateItem() }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func updateItem() {
        guard isEnabled else {
            // If disabled, set quantity to zero
            var updatedItem = item
            updatedItem = LineItem(
                itemId: item.itemId,
                csiCode: item.csiCode,
                description: item.description,
                quantity: 0,
                unit: item.unit,
                unitCost: item.unitCost,
                totalCost: 0,
                type: item.type,
                manufacturer: item.manufacturer,
                modelNumber: item.modelNumber,
                specifications: item.specifications,
                quantityDetails: item.quantityDetails,
                laborDetails: item.laborDetails
            )
            onUpdate(updatedItem)
            return
        }
        
        let newTotalCost = quantity * unitCost
        var updatedItem = item
        updatedItem = LineItem(
            itemId: item.itemId,
            csiCode: item.csiCode,
            description: item.description,
            quantity: quantity,
            unit: item.unit,
            unitCost: unitCost,
            totalCost: newTotalCost,
            type: item.type,
            manufacturer: item.manufacturer,
            modelNumber: item.modelNumber,
            specifications: item.specifications,
            quantityDetails: QuantityDetails(baseQuantity: quantity, totalQuantity: quantity),
            laborDetails: item.laborDetails
        )
        onUpdate(updatedItem)
    }
}

struct AddLineItemView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var description = ""
    @State private var quantity: Double = 1
    @State private var unit = "each"
    @State private var unitCost: Double = 0
    @State private var laborHours: Double = 0
    @State private var laborRate: Double = 65
    var onAdd: (LineItem) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Line Item Details")) {
                    TextField("Description", text: $description)
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Unit")
                        Spacer()
                        TextField("e.g., each, sq ft", text: $unit)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Unit Cost")
                        Spacer()
                        TextField("", value: $unitCost, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
                
                Section(header: Text("Labor (Optional)")) {
                    HStack {
                        Text("Labor Hours")
                        Spacer()
                        TextField("", value: $laborHours, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Labor Rate")
                        Spacer()
                        TextField("", value: $laborRate, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
            }
            .navigationTitle("Add Line Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let newItem = createLineItem()
                        onAdd(newItem)
                        dismiss()
                    }
                    .disabled(description.isEmpty)
                }
            }
        }
    }
    
    private func createLineItem() -> LineItem {
        let totalCost = quantity * unitCost + laborHours * laborRate
        return LineItem(
            itemId: UUID().uuidString,
            csiCode: "99",
            description: description,
            quantity: quantity,
            unit: unit,
            unitCost: unitCost,
            totalCost: totalCost,
            type: "custom",
            manufacturer: nil,
            modelNumber: nil,
            specifications: nil,
            quantityDetails: QuantityDetails(baseQuantity: quantity, totalQuantity: quantity),
            laborDetails: LaborDetails(baseHours: laborHours, totalHours: laborHours, skillLevel: nil)
        )
    }
}