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
        }

        if let serviceError = service.error {
            error = serviceError.localizedDescription
        }

        isLoading = false
    }

    /// Sends a message to the AI coach
    func sendMessage() async {
        let trimmedMessage = inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }

        // Add user message
        let userMessage = AICoachMessage(
            role: .user,
            content: trimmedMessage
        )
        messages.append(userMessage)

        // Clear input and show typing
        inputMessage = ""
        isTyping = true
        error = nil

        // Get response from AI
        if let response = await service.askCoach(question: trimmedMessage) {
            // Add coach response
            let coachMessage = AICoachMessage(
                role: .coach,
                content: response.primaryMessage,
                insights: response.insights.filter { $0.priority == .high },
                suggestedQuestions: response.followUpQuestions
            )
            messages.append(coachMessage)

            // Update state
            insights = response.insights
            todayFocus = response.todayFocus
            weeklyPriorities = response.weeklyPriorities
            dataSummary = response.dataSummary
            proactiveAlerts = response.proactiveAlerts
            suggestedQuestions = response.followUpQuestions.isEmpty ? defaultQuestions : response.followUpQuestions
        } else {
            // Add error message
            let errorMessage = AICoachMessage(
                role: .coach,
                content: "I apologize, but I encountered an issue while analyzing your data. Please try again in a moment."
            )
            messages.append(errorMessage)

            if let serviceError = service.error {
                error = serviceError.localizedDescription
            }
        }

        isTyping = false
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
