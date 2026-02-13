import SwiftUI

@MainActor
final class HealthCoachViewModel: ObservableObject {
    @Published var healthScore: HealthScore?
    @Published var scoreHistory: [HealthScore] = []
    @Published var insights: [HealthInsight] = []
    @Published var messages: [HealthCoachMessage] = []
    @Published var isLoading = false
    @Published var error: String?

    // Chat
    @Published var inputMessage: String = ""
    @Published var isTyping = false

    private let service = HealthScoreService.shared

    init() {
        // Add welcome message
        messages = [
            HealthCoachMessage(
                id: UUID(),
                role: .assistant,
                content: "Hi! I'm your AI Health Coach. I analyze your training, recovery, nutrition, and labs to give you personalized insights. How can I help you today?",
                timestamp: Date(),
                category: .general
            )
        ]
    }

    func loadData() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        await service.fetchHealthScore()
        healthScore = service.currentScore
        scoreHistory = service.scoreHistory
        insights = service.insights
        if let serviceError = service.error {
            ErrorLogger.shared.logError(serviceError, context: "HealthCoachViewModel.loadData")
            error = "Unable to load your health data. Please try again."
        }
    }

    /// Retry loading data after an error
    func retryLoad() async {
        await loadData()
    }

    func calculateScore() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        await service.calculateTodayScore()
        healthScore = service.currentScore
        insights = service.insights
        if let serviceError = service.error {
            ErrorLogger.shared.logError(serviceError, context: "HealthCoachViewModel.calculateScore")
            error = "Unable to calculate your health score. Please try again."
        }
    }

    func sendMessage() async {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = HealthCoachMessage(
            id: UUID(),
            role: .user,
            content: inputMessage,
            timestamp: Date(),
            category: nil
        )
        messages.append(userMessage)
        HapticFeedback.light() // Feedback for message sent

        let query = inputMessage
        inputMessage = ""
        isTyping = true
        defer { isTyping = false }

        let response = await service.sendMessage(query)
        messages.append(response)
        HapticFeedback.success() // Feedback for response received
    }

    func askQuickQuestion(_ question: String) async {
        inputMessage = question
        await sendMessage()
    }

    // MARK: - Computed Properties

    var overallScore: Int {
        healthScore?.overallScore ?? 0
    }

    var scoreColor: Color {
        switch overallScore {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }

    var scoreDescription: String {
        switch overallScore {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        default: return "Needs Attention"
        }
    }

    var highPriorityInsights: [HealthInsight] {
        insights.filter { $0.priority == .high }
    }

    var scoreTrend: ScoreTrend {
        guard scoreHistory.count >= 2 else { return .stable }
        let recent = scoreHistory.prefix(7).map { $0.overallScore }
        let avg = Double(recent.reduce(0, +)) / Double(recent.count)
        let current = Double(overallScore)

        if current > avg + 5 { return .improving }
        if current < avg - 5 { return .declining }
        return .stable
    }
}
