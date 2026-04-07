import Foundation
import Combine

@MainActor
class EstimateViewModel: ObservableObject {
    @Published var currentEstimate: Estimate?
    @Published var isLoading = false
    @Published var error: Error?

    private var cancellables = Set<AnyCancellable>()

    func generateEstimateWithGeminiAnalysis(from scanResult: RoomScanResult) {
        isLoading = true
        error = nil
        currentEstimate = nil

        // In a real app, you would send the scanResult to your backend here.
        // The backend would perform the Gemini analysis and return the structured estimate.

        // For now, we will simulate this process and use mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // Simulate network delay
            let mockEstimate = Estimate(
                subtotal: 1020.0,
                materialTotal: 1020.0,
                laborTotal: 975.0,
                markupAmount: 255.0,
                taxAmount: 125.0,
                grandTotal: 12500.0,
                csiDivisions: [
                    CSIDivision(
                        csiCode: "09 30 00",
                        divisionName: "Flooring",
                        totalCost: 1995.0,
                        laborHours: 15.0,
                        lineItems: [
                            LineItem(
                                itemId: "flooring_001",
                                csiCode: "09 30 00",
                                description: "Hardwood Flooring Installation",
                                quantity: 120.0,
                                unit: "SF",
                                unitCost: 8.50,
                                totalCost: 1020.0,
                                type: "material",
                                manufacturer: "OakWood Co",
                                modelNumber: "HW-123",
                                specifications: nil,
                                quantityDetails: nil,
                                laborDetails: nil
                            ),
                            LineItem(
                                itemId: "labor_001",
                                csiCode: "09 30 00",
                                description: "Flooring Installation Labor",
                                quantity: 15.0,
                                unit: "hours",
                                unitCost: 65.0,
                                totalCost: 975.0,
                                type: "labor",
                                manufacturer: nil,
                                modelNumber: nil,
                                specifications: nil,
                                quantityDetails: nil,
                                laborDetails: LaborDetails(
                                    baseHours: 12.0,
                                    totalHours: 15.0,
                                    skillLevel: "skilled"
                                )
                            )
                        ]
                    )
                ],
                metadata: EstimateMetadata(
                    totalLaborHours: 15.0,
                    finishLevel: "good",
                    calculationDate: ISO8601DateFormatter().string(from: Date()),
                    engineVersion: "2.0"
                )
            )
            self.currentEstimate = mockEstimate
            self.isLoading = false
        }
    }

    func clearError() {
        error = nil
    }

    func retry(with scanResult: RoomScanResult) {
        error = nil
        generateEstimateWithGeminiAnalysis(from: scanResult)
    }

    var hasError: Bool {
        return error != nil
    }
}
