import Foundation
import Combine

class ChatService: ObservableObject {
    private let apiClient: APIClient
    
    init(apiClient: APIClient = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    // MARK: - Chat Session Operations
    
    func createChatSession(_ request: ChatSession.Create) async throws -> ChatSession {
        return try await apiClient.request(
            path: "chat/sessions",
            method: .post,
            body: request
        )
    }
    
    func getChatSessions(
        estimateId: UUID? = nil,
        page: Int = 1,
        limit: Int = 20
    ) async throws -> [ChatSession] {
        var queryParameters = [
            "page": String(page),
            "limit": String(limit)
        ]
        
        if let estimateId = estimateId {
            queryParameters["estimateId"] = estimateId.uuidString
        }
        
        return try await apiClient.request(
            path: "chat/sessions",
            queryParameters: queryParameters
        )
    }
    
    func getChatSession(id: UUID) async throws -> ChatSession {
        return try await apiClient.request(
            path: "chat/sessions/\(id.uuidString)"
        )
    }
    
    func deleteChatSession(id: UUID) async throws {
        try await apiClient.request(
            path: "chat/sessions/\(id.uuidString)",
            method: .delete
        )
    }
    
    // MARK: - Message Operations
    
    func sendMessage(
        sessionId: UUID,
        content: String,
        metadata: ChatMessage.ChatMetadata? = nil
    ) async throws -> ChatMessage {
        let request = ChatMessage.Create(
            sessionId: sessionId,
            content: content,
            role: .user
        )
        
        return try await apiClient.request(
            path: "chat/sessions/\(sessionId.uuidString)/messages",
            method: .post,
            body: request
        )
    }
    
    func getMessages(
        sessionId: UUID,
        page: Int = 1,
        limit: Int = 50,
        before: Date? = nil
    ) async throws -> [ChatMessage] {
        var queryParameters = [
            "page": String(page),
            "limit": String(limit)
        ]
        
        if let before = before {
            let formatter = ISO8601DateFormatter()
            queryParameters["before"] = formatter.string(from: before)
        }
        
        return try await apiClient.request(
            path: "chat/sessions/\(sessionId.uuidString)/messages",
            queryParameters: queryParameters
        )
    }
    
    // MARK: - Chat with AI
    
    func chatWithEstimateAI(
        sessionId: UUID,
        message: String,
        estimateModifications: [String]? = nil
    ) async throws -> ChatMessage {
        var metadata: ChatMessage.ChatMetadata? = nil
        if let modifications = estimateModifications {
            metadata = ChatMessage.ChatMetadata(
                updatedEstimate: !modifications.isEmpty,
                modifications: modifications,
                confidence: nil
            )
        }
        
        let userMessage = try await sendMessage(
            sessionId: sessionId,
            content: message,
            metadata: metadata
        )
        
        // Get AI response
        struct AIResponse: Codable {
            let message: ChatMessage
        }
        
        let response: AIResponse = try await apiClient.request(
            path: "chat/sessions/\(sessionId.uuidString)/respond",
            method: .post,
            body: ["messageId": userMessage.id.uuidString]
        )
        
        return response.message
    }
    
    func streamChatResponse(
        sessionId: UUID,
        message: String
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // For now, we'll implement this with a simple delay
                    // In production, this would use WebSockets or Server-Sent Events
                    let request = ChatMessage.Create(
                        sessionId: sessionId,
                        content: message,
                        role: .user
                    )
                    
                    let _: ChatMessage = try await apiClient.request(
                        path: "chat/sessions/\(sessionId.uuidString)/stream",
                        method: .post,
                        body: request
                    )
                    
                    // Simulate streaming response
                    let simulatedResponse = ["Thinking", "...", "Here's my analysis:", "Based on your room dimensions..."]
                    for word in simulatedResponse {
                        try await Task.sleep(nanoseconds: 500_000_000)
                        continuation.yield(word + " ")
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Session Management
    
    func updateSessionTitle(sessionId: UUID, title: String) async throws -> ChatSession {
        struct TitleUpdate: Codable {
            let title: String
        }
        
        let request = TitleUpdate(title: title)
        return try await apiClient.request(
            path: "chat/sessions/\(sessionId.uuidString)/title",
            method: .put,
            body: request
        )
    }
    
    func markAsRead(sessionId: UUID) async throws {
        try await apiClient.request(
            path: "chat/sessions/\(sessionId.uuidString)/read",
            method: .post
        )
    }
}