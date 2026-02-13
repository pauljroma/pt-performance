import SwiftUI

@MainActor
final class AICoachViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var messages: [AICoachMessage] = []
    @Published var insights: [CoachingInsight] = []
    @Published var suggestedQuestions: [String] = []
    @Published var todayFocus: String = ""
    @Published var weeklyPriorities: [String] = []
    @Published var dataSummary: DataSummary?
    @Published var proactiveAlerts: [String] = []

    @Published var inputMessage: String = ""
    @Published var isLoading = false
    @Published var isTyping = false
    @Published var error: String?

    // MARK: - Private Properties

    private let service = AICoachService.shared

    /// Timeout duration for AI requests in seconds
    private let aiRequestTimeout: TimeInterval = 30

    /// Task for tracking the current AI request (for timeout handling)
    private var currentRequestTask: Task<Void, Never>?

    // MARK: - Initialization

    init() {
        // Add welcome message
        messages = [
            AICoachMessage(
                role: .coach,
                content: "Hi! I'm your AI Performance Coach. I have access to your complete health picture - training, sleep, recovery, labs, and more. Ask me anything, or let me share some personalized insights.",
                suggestedQuestions: defaultQuestions
            )
        ]
        suggestedQuestions = defaultQuestions
    }

    private let defaultQuestions: [String] = [
        "How is my recovery looking?",
        "What should I focus on today?",
        "Am I training too hard?",
        "How can I improve my sleep?"
    ]

    // MARK: - Public Methods

    /// Loads initial proactive insights
    func loadInitialInsights() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        await service.getProactiveInsights()

        if let response = service.currentResponse {
            insights = response.insights
            todayFocus = response.todayFocus
            weeklyPriorities = response.weeklyPriorities
            dataSummary = response.dataSummary
            proactiveAlerts = response.proactiveAlerts
            suggestedQuestions = response.followUpQuestions.isEmpty ? defaultQuestions : response.followUpQuestions

            // Add greeting message if we have proactive content
            if messages.count == 1 {
                let greetingMessage = AICoachMessage(
                    role: .coach,
                    content: response.primaryMessage,
                    insights: response.insights.filter { $0.priority == .high },
                    suggestedQuestions: response.followUpQuestions
                )
                messages.append(greetingMessage)
            }

            // Haptic feedback for high priority alerts or insights
            if !proactiveAlerts.isEmpty || insights.contains(where: { $0.priority == .high }) {
                HapticFeedback.warning()
            } else {
                HapticFeedback.success()
            }
        }

        if let serviceError = service.error {
            ErrorLogger.shared.logError(serviceError, context: "AICoachViewModel.loadInitialInsights")
            error = "Unable to load AI Coach insights. Please try again."
            HapticFeedback.error()
        }
    }

    /// Sends a message to the AI coach
    func sendMessage() async {
        let trimmedMessage = inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }

        // Cancel any existing request
        currentRequestTask?.cancel()

        // Add user message with haptic feedback
        let userMessage = AICoachMessage(
            role: .user,
            content: trimmedMessage
        )
        messages.append(userMessage)
        HapticFeedback.light() // Feedback for message sent

        // Clear input and show typing
        inputMessage = ""
        isTyping = true
        error = nil

        // Create a task with timeout handling
        let requestTask = Task<UnifiedCoachResponse?, Never> {
            // Race between the actual request and timeout
            return await withTaskGroup(of: UnifiedCoachResponse?.self) { group in
                // Add the actual request
                group.addTask {
                    return await self.service.askCoach(question: trimmedMessage)
                }

                // Add timeout task
                group.addTask {
                    try? await Task.sleep(nanoseconds: UInt64(self.aiRequestTimeout * 1_000_000_000))
                    return nil  // Timeout returns nil
                }

                // Return the first result (either success or timeout)
                if let result = await group.next() {
                    group.cancelAll()  // Cancel the other task
                    return result
                }
                return nil
            }
        }

        let response = await requestTask.value

        // Ensure we're not cancelled before updating UI
        guard !Task.isCancelled else {
            isTyping = false
            return
        }

        isTyping = false

        if let response = response {
            // Add coach response with success haptic
            let coachMessage = AICoachMessage(
                role: .coach,
                content: response.primaryMessage,
                insights: response.insights.filter { $0.priority == .high },
                suggestedQuestions: response.followUpQuestions
            )
            messages.append(coachMessage)
            HapticFeedback.success() // Response received successfully

            // Update state
            insights = response.insights
            todayFocus = response.todayFocus
            weeklyPriorities = response.weeklyPriorities
            dataSummary = response.dataSummary
            proactiveAlerts = response.proactiveAlerts
            suggestedQuestions = response.followUpQuestions.isEmpty ? defaultQuestions : response.followUpQuestions

            // Haptic for high-priority alerts
            if !response.proactiveAlerts.isEmpty || response.insights.contains(where: { $0.priority == .high }) {
                HapticFeedback.warning()
            }
        } else {
            // Add error/timeout message with error haptic
            let isTimeout = service.error == nil
            let errorContent = isTimeout
                ? "The request is taking longer than expected. Please try again."
                : "I apologize, but I encountered an issue while analyzing your data. Please try again in a moment."

            let errorMessage = AICoachMessage(
                role: .coach,
                content: errorContent
            )
            messages.append(errorMessage)
            HapticFeedback.error() // Error feedback

            if let serviceError = service.error {
                ErrorLogger.shared.logError(serviceError, context: "AICoachViewModel.sendMessage")
                error = "Unable to get a response from AI Coach. Please try again."
            } else if isTimeout {
                DebugLogger.shared.log("AI Coach request timed out after \(Int(aiRequestTimeout)) seconds", level: .warning)
                error = "Request timed out. Please try again."
            }
        }
    }

    /// Sends a suggested question
    func askQuestion(_ question: String) async {
        inputMessage = question
        await sendMessage()
    }

    /// Refreshes proactive insights
    func refreshInsights() async {
        await loadInitialInsights()
    }

    // MARK: - Computed Properties

    /// High priority insights only
    var highPriorityInsights: [CoachingInsight] {
        insights.filter { $0.priority == .high }
    }

    /// Insights grouped by category
    var insightsByCategory: [(CoachingCategory, [CoachingInsight])] {
        let grouped = Dictionary(grouping: insights, by: { $0.category })
        return grouped.sorted { $0.key.rawValue < $1.key.rawValue }
    }

    /// Whether there are any alerts
    var hasAlerts: Bool {
        !proactiveAlerts.isEmpty
    }

    /// Number of unread insights (high priority)
    var unreadInsightCount: Int {
        highPriorityInsights.count
    }
}
