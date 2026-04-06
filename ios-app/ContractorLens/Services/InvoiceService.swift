import Foundation
import Combine

class InvoiceService: ObservableObject {
    private let apiClient: APIClient
    
    init(apiClient: APIClient = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    // MARK: - Invoice Operations
    
    func createInvoice(_ request: Invoice.Create) async throws -> Invoice {
        return try await apiClient.request(
            path: "invoices",
            method: .post,
            body: request
        )
    }
    
    func getInvoices(
        status: Invoice.InvoiceStatus? = nil,
        page: Int = 1,
        limit: Int = 20
    ) async throws -> [Invoice] {
        var queryParameters = [
            "page": String(page),
            "limit": String(limit)
        ]
        
        if let status = status {
            queryParameters["status"] = status.rawValue
        }
        
        return try await apiClient.request(
            path: "invoices",
            queryParameters: queryParameters
        )
    }
    
    func getInvoice(id: UUID) async throws -> Invoice {
        return try await apiClient.request(
            path: "invoices/\(id.uuidString)"
        )
    }
    
    func updateInvoiceStatus(id: UUID, status: Invoice.InvoiceStatus) async throws -> Invoice {
        let request = Invoice.Update(status: status)
        return try await apiClient.request(
            path: "invoices/\(id.uuidString)/status",
            method: .patch,
            body: request
        )
    }
    
    func updateInvoicePayment(id: UUID, amountPaid: Double) async throws -> Invoice {
        var request = Invoice.Update()
        request.amountPaid = amountPaid
        request.paidAt = Date()
        
        // If amount paid equals or exceeds amount due, mark as paid
        let invoice = try await getInvoice(id: id)
        if amountPaid >= invoice.amountDue - invoice.amountPaid {
            request.status = .paid
        }
        
        return try await apiClient.request(
            path: "invoices/\(id.uuidString)",
            method: .put,
            body: request
        )
    }
    
    // MARK: - Invoice Generation
    
    func generateInvoiceFromEstimate(estimateId: UUID, clientId: UUID? = nil) async throws -> Invoice {
        struct GenerateRequest: Codable {
            let estimateId: UUID
            let clientId: UUID?
        }
        
        let request = GenerateRequest(estimateId: estimateId, clientId: clientId)
        return try await apiClient.request(
            path: "invoices/generate",
            method: .post,
            body: request
        )
    }
    
    // MARK: - PDF and Email
    
    func generateInvoicePDF(invoiceId: UUID) async throws -> Data {
        struct PDFResponse: Codable {
            let pdfData: String // Base64 encoded PDF
        }
        
        let response: PDFResponse = try await apiClient.request(
            path: "invoices/\(invoiceId.uuidString)/pdf"
        )
        
        guard let data = Data(base64Encoded: response.pdfData) else {
            throw APIClient.APIError.decodingError(NSError(domain: "InvoiceService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode PDF data"]))
        }
        
        return data
    }
    
    func sendInvoiceEmail(invoiceId: UUID, recipientEmail: String) async throws {
        struct SendRequest: Codable {
            let recipientEmail: String
        }
        
        let request = SendRequest(recipientEmail: recipientEmail)
        try await apiClient.request(
            path: "invoices/\(invoiceId.uuidString)/send",
            method: .post,
            body: request
        )
    }
    
    // MARK: - Financial Summary
    
    func getRevenueSummary(startDate: Date, endDate: Date) async throws -> RevenueSummary {
        let formatter = ISO8601DateFormatter()
        let queryParameters = [
            "startDate": formatter.string(from: startDate),
            "endDate": formatter.string(from: endDate)
        ]
        
        return try await apiClient.request(
            path: "invoices/summary",
            queryParameters: queryParameters
        )
    }
    
    struct RevenueSummary: Codable {
        let totalRevenue: Double
        let paidInvoices: Int
        let pendingInvoices: Int
        let overdueInvoices: Int
        let averagePaymentTime: Double // Days
    }
}