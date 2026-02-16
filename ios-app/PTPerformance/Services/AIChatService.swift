//
//  AIChatService.swift
//  PTPerformance
//
//  Build 77 - AI Helper MVP
//  ACP-1024 - Added pinned messages, search, quick actions
//

import SwiftUI
import Supabase

struct ChatMessage: Identifiable, Codable, Equatable {
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

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

/// Quick action chip that can appear below AI responses
struct ChatQuickAction: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let icon: String
    let prompt: String
}

/// Service for AI-powered chat interactions with athletes
///
/// Provides conversational AI assistance for workout-related questions,
/// exercise guidance, and personalized recommendations. Messages are
/// persisted to the database for conversation continuity.
///
/// - Note: Uses the `ai-chat-completion` edge function for AI responses
///
/// ## Usage Example
/// ```swift
/// let chatService = AIChatService.shared
/// let response = try await chatService.sendMessage("How should I warm up?")
/// print(response.content)
/// ```
@MainActor
class AIChatService: ObservableObject {

    /// Shared singleton instance
    static let shared = AIChatService()

    /// Array of messages in the current chat session
    @Published var messages: [ChatMessage] = []

    /// Indicates whether a message is currently being processed
    @Published var isLoading: Bool = false

    /// The unique identifier for the current chat session
    @Published var currentSessionId: UUID?

    /// Set of pinned message IDs persisted locally
    @Published var pinnedMessageIds: Set<UUID> = []

    /// Current search query for filtering messages
    @Published var searchQuery: String = ""

    /// Quick actions generated from the latest AI response
    @Published var latestQuickActions: [ChatQuickAction] = []

    private let supabase = PTSupabaseClient.shared

    /// UserDefaults key for pinned messages
    private let pinnedMessagesKey = "ai_chat_pinned_messages"

    init() {
        loadPinnedMessages()
    }

    // MARK: - Pinned Messages

    /// Messages that have been pinned/bookmarked by the user
    var pinnedMessages: [ChatMessage] {
        messages.filter { pinnedMessageIds.contains($0.id) }
    }

    /// Filtered messages based on current search query
    var filteredMessages: [ChatMessage] {
        guard !searchQuery.isEmpty else { return messages }
        return messages.filter {
            $0.content.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    /// Toggle pinned status for a message
    func togglePin(for messageId: UUID) {
        if pinnedMessageIds.contains(messageId) {
            pinnedMessageIds.remove(messageId)
        } else {
            pinnedMessageIds.insert(messageId)
        }
        savePinnedMessages()
    }

    /// Check if a message is pinned
    func isPinned(_ messageId: UUID) -> Bool {
        pinnedMessageIds.contains(messageId)
    }

    private func loadPinnedMessages() {
        if let data = UserDefaults.standard.data(forKey: pinnedMessagesKey),
           let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            pinnedMessageIds = ids
        }
    }

    private func savePinnedMessages() {
        if let data = try? JSONEncoder().encode(pinnedMessageIds) {
            UserDefaults.standard.set(data, forKey: pinnedMessagesKey)
        }
    }

    // MARK: - Quick Actions

    /// Generates contextual quick actions based on AI response content
    func generateQuickActions(for responseContent: String) -> [ChatQuickAction] {
        var actions: [ChatQuickAction] = []

        let lowerContent = responseContent.lowercased()

        // Always offer "Tell me more"
        actions.append(ChatQuickAction(
            title: "Tell me more",
            icon: "text.bubble",
            prompt: "Can you tell me more about that?"
        ))

        // Context-specific actions
        if lowerContent.contains("exercise") || lowerContent.contains("workout") || lowerContent.contains("squat") || lowerContent.contains("press") || lowerContent.contains("deadlift") {
            actions.append(ChatQuickAction(
                title: "Show me how",
                icon: "figure.strengthtraining.traditional",
                prompt: "Can you show me the proper form and technique for this exercise?"
            ))
            actions.append(ChatQuickAction(
                title: "Log this workout",
                icon: "checkmark.circle",
                prompt: "Help me log this workout to track my progress."
            ))
        }

        if lowerContent.contains("recovery") || lowerContent.contains("rest") || lowerContent.contains("sleep") {
            actions.append(ChatQuickAction(
                title: "Recovery tips",
                icon: "heart.fill",
                prompt: "What are your top recovery recommendations for me right now?"
            ))
        }

        if lowerContent.contains("pain") || lowerContent.contains("sore") || lowerContent.contains("injury") {
            actions.append(ChatQuickAction(
                title: "Alternative exercises",
                icon: "arrow.triangle.swap",
                prompt: "What alternative exercises can I do to avoid aggravating this?"
            ))
        }

        if lowerContent.contains("nutrition") || lowerContent.contains("diet") || lowerContent.contains("protein") || lowerContent.contains("calories") {
            actions.append(ChatQuickAction(
                title: "Meal suggestions",
                icon: "leaf.fill",
                prompt: "Can you suggest specific meals or snacks for my goals?"
            ))
        }

        // Limit to 4 actions max
        return Array(actions.prefix(4))
    }

    // ACP-1023: Follow-up suggestions from the last AI response
    @Published var followUpSuggestions: [String] = []

    // MARK: - Send Message

    /// Sends a message to the AI assistant and receives a response
    ///
    /// This method calls the AI chat completion edge function, which processes
    /// the message using Claude and returns a contextual response. Both the
    /// user message and assistant response are added to the local messages array.
    /// ACP-1023: Now passes user context for personalized responses and surfaces follow-up suggestions.
    ///
    /// - Parameter text: The message text to send to the AI assistant
    ///
    /// - Returns: The `ChatMessage` containing the AI assistant's response
    ///
    /// - Throws: `NSError` if the response is invalid or the request fails
    ///
    /// - Example:
    ///   ```swift
    ///   let response = try await chatService.sendMessage("What exercises help with shoulder mobility?")
    ///   print(response.content) // AI's response about shoulder exercises
    ///   ```
    func sendMessage(_ text: String) async throws -> ChatMessage {
        isLoading = true
        defer { isLoading = false }

        // Add user message immediately for responsive feel
        let userMessage = ChatMessage(
            id: UUID(),
            sessionId: currentSessionId,
            role: "user",
            content: text,
            tokensUsed: nil,
            createdAt: Date()
        )
        self.messages.append(userMessage)

        guard let athleteId = PTSupabaseClient.shared.userId, !athleteId.isEmpty else {
            throw AIChatError.notAuthenticated
        }

        // ACP-1023: Build request with user context for personalized responses
        var requestBody: [String: Any] = [
            "athlete_id": athleteId,
            "message": text,
            "session_id": currentSessionId?.uuidString as Any
        ]

        // ACP-1023: Gather lightweight user context
        let userContext = await gatherUserContext(athleteId: athleteId)
        if !userContext.isEmpty {
            requestBody["user_context"] = userContext
        }

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
        self.currentSessionId = sessionId

        // ACP-1023: Extract follow-up suggestions from the response
        if let suggestions = json["follow_up_suggestions"] as? [String], !suggestions.isEmpty {
            self.followUpSuggestions = suggestions
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

        // Add assistant message
        self.messages.append(assistantMessage)

        // Generate quick actions for this response
        self.latestQuickActions = generateQuickActions(for: messageText)

        return assistantMessage
    }

    // MARK: - Load History

    /// Loads the chat history for the current athlete
    ///
    /// Fetches the most recent chat session and its messages from the database.
    /// Updates the `currentSessionId` and `messages` properties with the loaded data.
    ///
    /// - Note: This method fails silently on error, logging the failure in debug builds
    func loadHistory() async {
        do {
            guard let userIdString = PTSupabaseClient.shared.userId,
                  let athleteId = UUID(uuidString: userIdString) else {
                return // Silently return if not authenticated - loadHistory is non-throwing
            }

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

            self.currentSessionId = uuid

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

            self.messages = loadedMessages
        } catch {
            DebugLogger.shared.error("AIChatService", "Failed to load chat history: \(error.localizedDescription)")
        }
    }

    // MARK: - User Context (ACP-1023)

    /// Gathers lightweight user context to send with chat requests
    /// This enables the edge function to provide more personalized responses
    /// Fix 7: Uses async let for parallel database queries instead of sequential
    private func gatherUserContext(athleteId: String) async -> [String: Any] {
        var context: [String: Any] = [:]

        // Model types declared outside of do block for clarity
        struct WorkoutRow: Decodable {
            let name: String?
        }
        struct ReadinessRow: Decodable {
            let readinessScore: Int?
            enum CodingKeys: String, CodingKey {
                case readinessScore = "readiness_score"
            }
        }
        struct GoalRow: Decodable {
            let title: String
        }

        do {
            // Fix 7: Parallelize the 3 independent database queries with async let
            async let workouts: [WorkoutRow] = supabase.client
                .from("manual_sessions")
                .select("name")
                .eq("patient_id", value: athleteId)
                .eq("completed", value: true)
                .order("completed_at", ascending: false)
                .limit(3)
                .execute()
                .value

            async let readiness: [ReadinessRow] = supabase.client
                .from("daily_readiness")
                .select("readiness_score")
                .eq("patient_id", value: athleteId)
                .order("date", ascending: false)
                .limit(1)
                .execute()
                .value

            async let goals: [GoalRow] = supabase.client
                .from("patient_goals")
                .select("title")
                .eq("patient_id", value: athleteId)
                .eq("status", value: "active")
                .limit(3)
                .execute()
                .value

            let (w, r, g) = try await (workouts, readiness, goals)

            let workoutNames = w.compactMap { $0.name }
            if !workoutNames.isEmpty {
                context["recent_workouts"] = workoutNames
            }

            if let score = r.first?.readinessScore {
                context["readiness_score"] = score
            }

            let goalTitles = g.map { $0.title }
            if !goalTitles.isEmpty {
                context["goals"] = goalTitles
            }
        } catch {
            DebugLogger.shared.warning("AIChatService", "Failed to gather user context: \(error.localizedDescription)")
            // Non-fatal: the edge function will still work without client context
        }

        return context
    }

    // MARK: - New Session

    /// Starts a new chat session
    ///
    /// Clears the current session ID and all messages, allowing a fresh
    /// conversation to begin. The next message sent will create a new
    /// session in the database.
    func startNewSession() {
        currentSessionId = nil
        messages = []
        latestQuickActions = []
        followUpSuggestions = []
        searchQuery = ""
    }
}

enum AIChatError: LocalizedError {
    case notAuthenticated
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Unable to identify user. Please ensure you are logged in."
        case .invalidResponse:
            return "Received an invalid response from the AI assistant."
        }
    }
}
