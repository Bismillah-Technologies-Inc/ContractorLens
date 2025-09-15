import Foundation

struct MockEstimateGenerator {
    static func generate() -> Estimate {
        let csiDivisions = [
            CSIDivision(csiCode: "09 00 00", divisionName: "Finishes", totalCost: 1000.0, laborHours: 20.0, lineItems: [
                LineItem(itemId: "1", csiCode: "09 91 00", description: "Painting", quantity: 200.0, unit: "SF", unitCost: 2.0, totalCost: 400.0, type: "material", manufacturer: "Behr", modelNumber: "P100", specifications: nil, quantityDetails: nil, laborDetails: nil),
                LineItem(itemId: "2", csiCode: "09 68 00", description: "Carpet", quantity: 100.0, unit: "SF", unitCost: 6.0, totalCost: 600.0, type: "material", manufacturer: "Shaw", modelNumber: "C100", specifications: nil, quantityDetails: nil, laborDetails: nil)
            ])
        ]
        let metadata = EstimateMetadata(totalLaborHours: 20.0, finishLevel: "Good", calculationDate: "2025-09-15", engineVersion: "1.0")
        
        return Estimate(subtotal: 1000.0, materialTotal: 800.0, laborTotal: 200.0, markupAmount: 100.0, taxAmount: 80.0, grandTotal: 1180.0, csiDivisions: csiDivisions, metadata: metadata)
    }
}