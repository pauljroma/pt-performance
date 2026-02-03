import SwiftUI

/// ViewModel for displaying readiness trends and statistics
/// Manages state for the readiness dashboard with trend charts and statistics
@MainActor
class ReadinessDashboardViewModel: ObservableObject {
    // MARK: - Dependencies
    private let readinessService: ReadinessService
    private let patientId: UUID

    // MARK: - Data State
    @Published var trendData: [DailyReadiness] = []
    @Published var currentScore: Double?
    @Published var averageScore: Double?
    @Published var minScore: Double?
    @Published var maxScore: Double?

    // MARK: - UI State
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var selectedPeriod: TrendPeriod = .week

    // MARK: - Period Selection
    enum TrendPeriod: String, CaseIterable, Identifiable {
        case week = "7 Days"
        case month = "30 Days"

        var id: String { rawValue }

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            }
        }
    }

    // MARK: - Computed Properties

    /// Current readiness category based on most recent score
    var currentCategory: ReadinessCategory? {
        guard let score = currentScore else { return nil }
        return ReadinessCategory.category(for: score)
    }

    /// Training recommendation based on current readiness
    var currentRecommendation: String {
        currentCategory?.recommendation ?? "Submit today's readiness check-in"
    }

    /// Color for current readiness category
    var categoryColor: Color {
        currentCategory?.color ?? .gray
    }

    /// Whether we have any data to display
    var hasData: Bool {
        !trendData.isEmpty
    }

    /// Chart-ready data points with dates and scores
    var chartData: [ChartDataPoint] {
        trendData.compactMap { entry in
            guard let score = entry.readinessScore else { return nil }
            return ChartDataPoint(
                date: entry.date,
                score: score,
                category: ReadinessCategory.category(for: score)
            )
        }.sorted { $0.date < $1.date }
    }

    /// Formatted current score text
    var currentScoreText: String {
        guard let score = currentScore else { return "--" }
        return String(format: "%.1f", score)
    }

    /// Formatted average score text
    var averageScoreText: String {
        guard let score = averageScore else { return "--" }
        return String(format: "%.1f", score)
    }

    /// Formatted min score text
    var minScoreText: String {
        guard let score = minScore else { return "--" }
        return String(format: "%.1f", score)
    }

    /// Formatted max score text
    var maxScoreText: String {
        guard let score = maxScore else { return "--" }
        return String(format: "%.1f", score)
    }

    /// Trend direction indicator based on recent data
    var trendDirection: TrendDirection {
        guard chartData.count >= 2 else { return .neutral }

        // Compare most recent score to average of previous scores
        let recentScore = chartData.last?.score ?? 0
        let previousScores = chartData.dropLast().map { $0.score }

        guard !previousScores.isEmpty else { return .neutral }

        let previousAverage = previousScores.reduce(0, +) / Double(previousScores.count)
        let difference = recentScore - previousAverage

        if difference > 5 {
            return .improving
        } else if difference < -5 {
            return .declining
        } else {
            return .neutral
        }
    }

    enum TrendDirection {
        case improving
        case declining
        case neutral

        var icon: String {
            switch self {
            case .improving: return "arrow.up.right"
            case .declining: return "arrow.down.right"
            case .neutral: return "arrow.right"
            }
        }

        var color: Color {
            switch self {
            case .improving: return .green
            case .declining: return .orange
            case .neutral: return .gray
            }
        }

        var description: String {
            switch self {
            case .improving: return "Improving"
            case .declining: return "Declining"
            case .neutral: return "Stable"
            }
        }
    }

    // MARK: - Initialization

    init(
        patientId: UUID,
        readinessService: ReadinessService = ReadinessService()
    ) {
        self.patientId = patientId
        self.readinessService = readinessService
    }

    // MARK: - Load Trend Data

    /// Load readiness trend data for the selected period
    func loadTrendData() async {
        isLoading = true
        showError = false
        errorMessage = ""

        do {
            // Fetch recent readiness entries
            // Note: ReadinessService expects String but model uses UUID
            trendData = try await readinessService.fetchRecentReadiness(
                for: patientId,
                limit: selectedPeriod.days
            )

            // Calculate statistics
            calculateStatistics()

            // Get current score (most recent entry)
            currentScore = trendData.first?.readinessScore

        } catch {
            errorMessage = "We couldn't load your readiness history. Please check your connection and try again."
            showError = true
        }

        isLoading = false
    }

    // MARK: - Calculate Statistics

    /// Calculate min, max, and average readiness scores
    private func calculateStatistics() {
        let scores = trendData.compactMap { $0.readinessScore }

        guard !scores.isEmpty else {
            averageScore = nil
            minScore = nil
            maxScore = nil
            return
        }

        averageScore = scores.reduce(0, +) / Double(scores.count)
        minScore = scores.min()
        maxScore = scores.max()
    }

    // MARK: - Refresh

    /// Refresh trend data (for pull-to-refresh)
    func refresh() async {
        await loadTrendData()
    }

    // MARK: - Period Change

    /// Change the trend period and reload data
    /// - Parameter period: The new period to display
    func changePeriod(_ period: TrendPeriod) async {
        selectedPeriod = period
        await loadTrendData()
    }

    // MARK: - Data Point Selection

    /// Get detailed information for a specific data point
    /// - Parameter dataPoint: The chart data point
    /// - Returns: Detailed readiness info string
    func detailsForDataPoint(_ dataPoint: ChartDataPoint) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        return """
        \(formatter.string(from: dataPoint.date))
        Score: \(String(format: "%.1f", dataPoint.score))
        Category: \(dataPoint.category.displayName)
        """
    }
}

// MARK: - Supporting Types

/// Chart data point with date, score, and category
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let score: Double
    let category: ReadinessCategory

    /// Formatted date for chart labels (e.g., "Jan 3")
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    /// Formatted date for tooltips (e.g., "Jan 3, 2026")
    var formattedDateLong: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Formatted score text
    var formattedScore: String {
        String(format: "%.1f", score)
    }
}

// MARK: - Preview Support

extension ReadinessDashboardViewModel {
    /// Preview instance with mock data
    static var preview: ReadinessDashboardViewModel {
        let vm = ReadinessDashboardViewModel(
            patientId: UUID(),
            readinessService: ReadinessService()
        )

        // Mock statistics
        vm.currentScore = 85.0
        vm.averageScore = 82.5
        vm.minScore = 65.0
        vm.maxScore = 92.0

        // Mock trend data (7 days)
        let calendar = Calendar.current
        let daysArray = Array(0..<7).reversed()
        vm.trendData = daysArray.map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            let baseScore = 82.5 + Double.random(in: -10...10)

            return DailyReadiness(
                id: UUID(),
                patientId: vm.patientId,
                date: date,
                sleepHours: Double.random(in: 6...9),
                sorenessLevel: Int.random(in: 3...7),
                energyLevel: Int.random(in: 5...9),
                stressLevel: Int.random(in: 3...7),
                readinessScore: baseScore,
                notes: nil,
                createdAt: date,
                updatedAt: date
            )
        }

        return vm
    }
}

