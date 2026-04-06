import Foundation

struct Invoice: Codable, Identifiable {
    let id: UUID
    let estimateId: UUID?
    let clientId: UUID?
    let userId: String
    let invoiceNumber: String?
    let status: InvoiceStatus
    let amountDue: Double
    let amountPaid: Double
    let dueDate: Date?
    let paidAt: Date?
    let lineItems: [LineItem]
    let createdAt: Date
    let updatedAt: Date
    
    enum InvoiceStatus: String, Codable {
        case draft = "draft"
        case sent = "sent"
        case paid = "paid"
        case overdue = "overdue"
        case void = "void"
    }
    
    struct LineItem: Codable {
        let description: String
        let quantity: Double
        let unit: String
        let unitPrice: Double
        let total: Double
        
        enum CodingKeys: String, CodingKey {
            case description
            case quantity
            case unit
            case unitPrice = "unit_price"
            case total
        }
    }
    
    struct Create: Codable {
        let estimateId: UUID?
        let clientId: UUID?
        let invoiceNumber: String?
        let amountDue: Double
        let dueDate: Date?
        let lineItems: [LineItem]
    }
    
    struct Update: Codable {
        let status: InvoiceStatus?
        let amountPaid: Double?
        let paidAt: Date?
        let dueDate: Date?
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "invoice_id"
        case estimateId = "estimate_id"
        case clientId = "client_id"
        case userId = "user_id"
        case invoiceNumber = "invoice_number"
        case status
        case amountDue = "amount_due"
        case amountPaid = "amount_paid"
        case dueDate = "due_date"
        case paidAt = "paid_at"
        case lineItems = "line_items"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}