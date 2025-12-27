//
//  AIChatService.swift
//  PTPerformance
//
//  Build 77 - AI Helper MVP
//

import Foundation
import SwiftUI

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

    private let supabase = SupabaseManager.shared

    // MARK: - Send Message

    func sendMessage(_ text: String) async throws -> ChatMessage {
        isLoading = true
        defer { isLoading = false }

        let athleteId = await SupabaseManager.shared.currentAthlete?.id.uuidString ?? ""

        // Call AI chat completion Edge Function
        let response = try await supabase.functions.invoke(
            "ai-chat-completion",
            body: [
                "athlete_id": athleteId,
                "message": text,
                "session_id": currentSessionId?.uuidString as Any
            ]
        )

        // Parse response
        guard let data = response.data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
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
            let athleteId = await SupabaseManager.shared.currentAthlete?.id ?? UUID()

            // Get latest session
            let sessionQuery = supabase.database
                .from("ai_chat_sessions")
                .select("id")
                .eq("athlete_id", value: athleteId.uuidString)
                .order("started_at", ascending: false)
                .limit(1)

            let sessionResponse: [[String: Any]] = try await sessionQuery.execute().value

            guard let sessionId = sessionResponse.first?["id"] as? String,
                  let uuid = UUID(uuidString: sessionId) else {
                return
            }

            await MainActor.run {
                self.currentSessionId = uuid
            }

            // Load messages
            let messagesQuery = supabase.database
                .from("ai_chat_messages")
                .select()
                .eq("session_id", value: sessionId)
                .order("created_at", ascending: true)

            let loadedMessages: [ChatMessage] = try await messagesQuery.execute().value

            await MainActor.run {
                self.messages = loadedMessages
            }
        } catch {
            print("❌ Failed to load chat history: \(error)")
        }
    }

    // MARK: - New Session

    func startNewSession() {
        currentSessionId = nil
        messages = []
    }
}
