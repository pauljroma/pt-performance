import SwiftUI
import Combine

/// ViewModel for the AR60 Readiness Score display
/// Provides computed properties and actions for the X2Index Command Center UI
@MainActor
final class ReadinessScoreViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var currentScore: AR60ReadinessScore?
    @Published private(set) var scoreHistory: [AR60ReadinessScore] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var error: String?

    // Detail view state
    @Published var selectedContributor: ReadinessContributor?
    @Published var showingContributorDetail = false

    // MARK: - Dependencies

    private let service: ReadinessScoreService
    private let supabase = PTSupabaseClient.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(service: ReadinessScoreService = .shared) {
        self.service = service
        setupBindings()
    }

    deinit {
        cancellables.removeAll()
    }

    private func setupBindings() {
        // Sync with service state
        service.$currentScore
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentScore)

        service.$scoreHistory
            .receive(on: DispatchQueue.main)
            .assign(to: &$scoreHistory)

        service.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if !loading {
                    self?.isRefreshing = false
                }
                self?.isLoading = loading
            }
            .store(in: &cancellables)

        service.$error
            .receive(on: DispatchQueue.main)
            .compactMap { $0?.localizedDescription }
            .assign(to: &$error)
    }

    // MARK: - Computed Properties

    /// Primary score value for display
    var scoreValue: Int {
        currentScore?.score ?? 0
    }

    /// Formatted score string
    var formattedScore: String {
        currentScore?.formattedScore ?? "--"
    }

    /// Score color based on category
    var scoreColor: Color {
        currentScore?.scoreColor ?? .secondary
    }

    /// Score gradient for backgrounds
    var scoreGradient: LinearGradient {
        let baseColor = scoreColor
        return LinearGradient(
            colors: [baseColor.opacity(0.8), baseColor.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Category display name
    var categoryName: String {
        currentScore?.category.rawValue ?? "Unknown"
    }

    /// Category icon
    var categoryIcon: String {
        currentScore?.category.icon ?? "questionmark.circle"
    }

    /// Training recommendation text
    var recommendation: String {
        currentScore?.category.recommendation ?? "Complete a readiness check-in"
    }

    /// Trend icon for display
    var trendIcon: String {
        currentScore?.trend.icon ?? "minus"
    }

    /// Trend display name
    var trendName: String {
        currentScore?.trend.displayName ?? "Unknown"
    }

    /// Trend color
    var trendColor: Color {
        currentScore?.trend.color ?? .secondary
    }

    /// Confidence level display
    var confidenceLevel: AR60ConfidenceLevel {
        currentScore?.confidenceLevel ?? .insufficient
    }

    /// Confidence percentage string
    var confidencePercentage: String {
        guard let score = currentScore else { return "--%"}
        return String(format: "%.0f%%", score.confidence * 100)
    }

    /// Confidence description for PT
    var confidenceDescription: String {
        confidenceLevel.description
    }

    /// Whether there are uncertainty warnings
    var hasUncertainty: Bool {
        currentScore?.requiresCaution ?? true
    }

    /// Uncertainty warning message
    var uncertaintyMessage: String? {
        guard let score = currentScore, score.requiresCaution else { return nil }

        if score.uncertaintyFlag {
            return "Some data may be stale or conflicting"
        } else if score.confidence < 0.5 {
            return "Limited data available for assessment"
        }

        return nil
    }

    /// Top positive contributors
    var topContributors: [ReadinessContributor] {
        currentScore?.topContributors ?? []
    }

    /// Limiting factors
    var limitingFactors: [ReadinessContributor] {
        currentScore?.limitingFactors ?? []
    }

    /// Critical alerts
    var criticalAlerts: [ReadinessContributor] {
        currentScore?.criticalAlerts ?? []
    }

    /// All contributors sorted by weight
    var allContributors: [ReadinessContributor] {
        (currentScore?.contributors ?? []).sorted { $0.weight > $1.weight }
    }

    /// Whether there are any critical alerts
    var hasCriticalAlerts: Bool {
        !criticalAlerts.isEmpty
    }

    /// Last update time formatted
    var lastUpdatedText: String {
        guard let timestamp = currentScore?.timestamp else {
            return "Not yet calculated"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    /// Time since last update in minutes
    var minutesSinceUpdate: Int {
        guard let timestamp = currentScore?.timestamp else { return 0 }
        return Int(Date().timeIntervalSince(timestamp) / 60)
    }

    /// Whether score needs refresh (>30 min old)
    var needsRefresh: Bool {
        minutesSinceUpdate > 30 || currentScore == nil
    }

    /// Intensity multiplier for training adjustments
    var suggestedIntensity: String {
        let multiplier = currentScore?.category.intensityMultiplier ?? 1.0
        return String(format: "%.0f%%", multiplier * 100)
    }

    // MARK: - Score Display Helpers

    /// Score ring progress (0-1)
    var scoreProgress: Double {
        Double(scoreValue) / 100.0
    }

    /// Score ring color
    var scoreRingColor: Color {
        scoreColor
    }

    /// Background color for score card
    var scoreCardBackground: Color {
        scoreColor.opacity(0.1)
    }

    /// Whether to show the score (vs loading/error state)
    var shouldShowScore: Bool {
        !isLoading && error == nil && currentScore != nil
    }

    // MARK: - History Properties

    /// Recent score trend data points
    var trendDataPoints: [(date: Date, score: Int)] {
        scoreHistory.map { ($0.timestamp, $0.score) }
    }

    /// Average score over history period
    var averageScore: Int {
        guard !scoreHistory.isEmpty else { return 0 }
        return scoreHistory.reduce(0) { $0 + $1.score } / scoreHistory.count
    }

    /// Score change from first historical to current
    var scoreChange: Int? {
        guard let current = currentScore?.score,
              let oldest = scoreHistory.last?.score else { return nil }
        return current - oldest
    }

    /// Formatted score change string
    var scoreChangeText: String {
        guard let change = scoreChange else { return "--" }
        let prefix = change >= 0 ? "+" : ""
        return "\(prefix)\(change)"
    }

    // MARK: - Actions

    /// Load the current readiness score
    func loadReadinessScore() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        guard let athleteId = await getCurrentAthleteId() else {
            error = "Unable to identify athlete"
            isLoading = false
            return
        }

        do {
            _ = try await service.calculateReadinessScore(for: athleteId)
            await service.loadScoreHistory(for: athleteId, days: 7)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    /// Refresh the score (pull-to-refresh)
    func refreshScore() async {
        isRefreshing = true
        await service.refreshScore()
    }

    /// Get detailed information for a contributor
    func getContributorDetails(_ contributor: ReadinessContributor) -> ContributorDetailInfo {
        ContributorDetailInfo(
            contributor: contributor,
            isTopContributor: topContributors.contains { $0.id == contributor.id },
            isLimitingFactor: limitingFactors.contains { $0.id == contributor.id }
        )
    }

    /// Show detail sheet for a contributor
    func showContributorDetail(_ contributor: ReadinessContributor) {
        selectedContributor = contributor
        showingContributorDetail = true
    }

    /// Dismiss contributor detail sheet
    func dismissContributorDetail() {
        showingContributorDetail = false
        selectedContributor = nil
    }

    /// Clear error state
    func clearError() {
        error = nil
    }

    // MARK: - Private Helpers

    private func getCurrentAthleteId() async -> UUID? {
        guard let userId = supabase.client.auth.currentUser?.id else { return nil }

        struct PatientRow: Decodable {
            let id: UUID
        }

        do {
            let patients: [PatientRow] = try await supabase.client
                .from("patients")
                .select("id")
                .eq("user_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            return patients.first?.id
        } catch {
            return nil
        }
    }
}

// MARK: - Contributor Detail Info

/// Detailed information about a contributor for display
struct ContributorDetailInfo {
    let contributor: ReadinessContributor
    let isTopContributor: Bool
    let isLimitingFactor: Bool

    var roleDescription: String {
        if isTopContributor {
            return "This is helping your readiness score"
        } else if isLimitingFactor {
            return "This is limiting your readiness"
        } else {
            return "Contributing to your overall score"
        }
    }

    var actionSuggestion: String? {
        guard isLimitingFactor else { return nil }

        switch contributor.domain {
        case .sleep:
            return "Try to get 7-9 hours of quality sleep"
        case .recovery:
            return "Consider adding a recovery session today"
        case .stress:
            return "Practice stress management techniques"
        case .soreness:
            return "Focus on mobility and light stretching"
        case .nutrition:
            return "Check your fasting and supplement compliance"
        case .training:
            return "You may need a deload or rest day"
        case .biomarkers:
            return "Review your latest lab results"
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension ReadinessScoreViewModel {
    /// Create a preview view model with sample data
    static var preview: ReadinessScoreViewModel {
        let vm = ReadinessScoreViewModel()
        vm.currentScore = AR60ReadinessScore.sample
        return vm
    }

    /// Create a preview view model with low confidence
    static var lowConfidencePreview: ReadinessScoreViewModel {
        let vm = ReadinessScoreViewModel()
        vm.currentScore = AR60ReadinessScore.lowConfidenceSample
        return vm
    }

    /// Create a preview view model with critical alerts
    static var criticalPreview: ReadinessScoreViewModel {
        let vm = ReadinessScoreViewModel()
        vm.currentScore = AR60ReadinessScore.criticalSample
        return vm
    }

    /// Create a preview view model in loading state
    static var loadingPreview: ReadinessScoreViewModel {
        let vm = ReadinessScoreViewModel()
        vm.isLoading = true
        return vm
    }

    /// Create a preview view model with error
    static var errorPreview: ReadinessScoreViewModel {
        let vm = ReadinessScoreViewModel()
        vm.error = "Failed to load readiness data"
        return vm
    }

    /// Set score directly for previews
    func setPreviewScore(_ score: AR60ReadinessScore) {
        self.currentScore = score
    }

    /// Set loading state for previews
    func setPreviewLoading(_ loading: Bool) {
        self.isLoading = loading
    }

    /// Set error for previews
    func setPreviewError(_ errorMessage: String?) {
        self.error = errorMessage
    }
}
#endif

// MARK: - Design Token Extensions

extension ReadinessScoreViewModel {
    /// Standard spacing for score displays
    var displaySpacing: CGFloat { DesignTokens.spacingMedium }

    /// Corner radius for score cards
    var cardCornerRadius: CGFloat { DesignTokens.cornerRadiusLarge }

    /// Animation duration for score changes
    var scoreAnimationDuration: Double { DesignTokens.animationDurationNormal }

    /// Icon size for contributor icons
    var contributorIconSize: CGFloat { DesignTokens.iconSizeMedium }
}
