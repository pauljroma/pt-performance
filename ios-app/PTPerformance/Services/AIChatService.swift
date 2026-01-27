//
//  AIChatService.swift
//  PTPerformance
//
//  Build 77 - AI Helper MVP
//

import Foundation
import SwiftUI
import Supabase

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let sessionId: UUID?
    let role: String  // "user" or "assistant"
    let content: String
    let tokensUsed: Int?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case role
        case content
        case tokensUsed = "tokens_used"
        case createdAt = "created_at"
    }
}

class AIChatService: ObservableObject {
    static let shared = AIChatService()

    @Published var messages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    @Published var currentSessionId: UUID?

    private let supabase = PTSupabaseClient.shared

    // MARK: - Send Message

    func sendMessage(_ text: String) async throws -> ChatMessage {
        isLoading = true
        defer { isLoading = false }

        let athleteId = PTSupabaseClient.shared.userId ?? ""

        // Call AI chat completion Edge Function
        let requestBody = [
            "athlete_id": athleteId,
            "message": text,
            "session_id": currentSessionId?.uuidString as Any
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

        let responseData: Data = try await supabase.client.functions.invoke(
            "ai-chat-completion",
            options: FunctionInvokeOptions(body: bodyData)
        ) { data, _ in
            data
        }

        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let messageText = json["message"] as? String,
              let sessionIdString = json["session_id"] as? String,
              let sessionId = UUID(uuidString: sessionIdString) else {
            throw NSError(domain: "AIChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        // Update session ID
        await MainActor.run {
            self.currentSessionId = sessionId
        }

        // Create assistant message
        let assistantMessage = ChatMessage(
            id: UUID(),
            sessionId: sessionId,
            role: "assistant",
            content: messageText,
            tokensUsed: json["tokens_used"] as? Int,
            createdAt: Date()
        )

        // Add messages to local array
        await MainActor.run {
            // Add user message
            self.messages.append(ChatMessage(
                id: UUID(),
                sessionId: sessionId,
                role: "user",
                content: text,
                tokensUsed: nil,
                createdAt: Date()
            ))

            // Add assistant message
            self.messages.append(assistantMessage)
        }

        return assistantMessage
    }

    // MARK: - Load History

    func loadHistory() async {
        do {
            let athleteId = PTSupabaseClient.shared.userId.flatMap { UUID(uuidString: $0) } ?? UUID()

            // Get latest session
            let sessionResponse = try await supabase.client
                .from("ai_chat_sessions")
                .select("id")
                .eq("athlete_id", value: athleteId.uuidString)
                .order("started_at", ascending: false)
                .limit(1)
                .execute()

            let sessions = try JSONDecoder().decode([[String: String]].self, from: sessionResponse.data)

            guard let sessionId = sessions.first?["id"],
                  let uuid = UUID(uuidString: sessionId) else {
                return
            }

            await MainActor.run {
                self.currentSessionId = uuid
            }

            // Load messages
            let messagesResponse = try await supabase.client
                .from("ai_chat_messages")
                .select()
                .eq("session_id", value: sessionId)
                .order("created_at", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let loadedMessages = try decoder.decode([ChatMessage].self, from: messagesResponse.data)

            await MainActor.run {
                self.messages = loadedMessages
            }
        } catch {
            #if DEBUG
            print("❌ Failed to load chat history: \(error)")
            #endif
        }
    }

    // MARK: - New Session

    func startNewSession() {
        currentSessionId = nil
        messages = []
    }
}
