//
//  TrendAnalysisViewModel.swift
//  PTPerformance
//
//  Created for M8 - Historical Trend Analysis Feature
//  ViewModel for trend analysis view
//

import SwiftUI
import Combine

/// ViewModel for the main trend analysis view
@MainActor
class TrendAnalysisViewModel: ObservableObject {

    // MARK: - Static Formatters
    private static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    // MARK: - Published Properties

    @Published var selectedMetric: TrendMetricType = .sessionAdherence
    @Published var selectedTimeRange: TrendTimeRange = .thirtyDays
    @Published var showMovingAverage = true
    @Published var currentAnalysis: TrendAnalysis?
    @Published var isLoading = false
    @Published var error: Error?

    // Export
    @Published var showExportSheet = false
    @Published var exportData: URL?

    // MARK: - Properties

    let patientId: UUID
    private let service = TrendAnalysisService.shared
    private var loadTask: Task<Void, Never>?

    // MARK: - Initialization

    init(patientId: UUID) {
        self.patientId = patientId
    }

    deinit {
        // Cancel any in-progress load task to prevent memory leaks
        loadTask?.cancel()
        loadTask = nil
    }

    // MARK: - Public Methods

    /// Load analysis for current selections
    func loadAnalysis() async {
        loadTask?.cancel()

        loadTask = Task {
            isLoading = true
            error = nil
            defer { isLoading = false }

            do {
                currentAnalysis = try await service.analyzeTrend(
                    patientId: patientId,
                    metric: selectedMetric,
                    range: selectedTimeRange
                )
            } catch {
                if !Task.isCancelled {
                    self.error = error
                }
            }
        }

        await loadTask?.value
    }

    /// Refresh current analysis
    func refresh() async {
        service.clearCache()
        await loadAnalysis()
    }

    /// Export analysis data to CSV
    func exportData(_ analysis: TrendAnalysis) {
        let data = service.exportTrendData(analysis: analysis)

        // Create temporary file
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "\(analysis.metricType.displayName.replacingOccurrences(of: " ", with: "_"))_\(analysis.timeRange.shortName)_\(formattedDate()).csv"
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            exportData = fileURL
            showExportSheet = true
        } catch {
            self.error = error
        }
    }

    // MARK: - Private Methods

    private func formattedDate() -> String {
        Self.isoDateFormatter.string(from: Date())
    }
}

// MARK: - Shared ViewModel for Global Access

/// Shared view model for accessing trend analysis across the app
@MainActor
class TrendAnalysisSharedViewModel: ObservableObject {

    // MARK: - Singleton

    static let shared = TrendAnalysisSharedViewModel()

    // MARK: - Published Properties

    @Published var recentAnalyses: [TrendAnalysis] = []
    @Published var topInsights: [TrendInsight] = []
    @Published var isLoading = false

    // MARK: - Properties

    private var patientId: UUID?
    private let service = TrendAnalysisService.shared
    private let cacheValidityDuration: TimeInterval = 600  // 10 minutes
    private var lastRefresh: Date?

    // MARK: - Initialization

    private init() {}

    // MARK: - Configuration

    /// Configure with patient ID (call on login)
    func configure(patientId: UUID) {
        self.patientId = patientId
    }

    /// Clear data (call on logout)
    func clearData() {
        patientId = nil
        recentAnalyses = []
        topInsights = []
        lastRefresh = nil
        service.clearCache()
    }

    // MARK: - Data Loading

    /// Load summary analyses for dashboard display
    func loadDashboardData(forceRefresh: Bool = false) async {
        guard let patientId = patientId else { return }

        // Check cache
        if !forceRefresh,
           let lastRefresh = lastRefresh,
           Date().timeIntervalSince(lastRefresh) < cacheValidityDuration,
           !recentAnalyses.isEmpty {
            return
        }

        isLoading = true
        defer { isLoading = false }

        // Load key metrics
        let metricsToLoad: [TrendMetricType] = [
            .sessionAdherence,
            .painLevel,
            .workloadVolume,
            .recoveryScore
        ]

        var analyses: [TrendAnalysis] = []

        for metric in metricsToLoad {
            do {
                let analysis = try await service.analyzeTrend(
                    patientId: patientId,
                    metric: metric,
                    range: .thirtyDays
                )
                analyses.append(analysis)
            } catch {
                // Skip metrics without data
                continue
            }
        }

        recentAnalyses = analyses

        // Load insights
        do {
            topInsights = try await service.generatePatientInsights(patientId: patientId)
        } catch {
            topInsights = []
        }

        lastRefresh = Date()
    }

    /// Get quick summary for a specific metric
    func getQuickSummary(for metric: TrendMetricType) -> TrendSummary? {
        recentAnalyses.first { $0.metricType == metric }?.summary
    }

    /// Check if there are any critical insights
    var hasCriticalInsights: Bool {
        topInsights.contains { $0.severity == .critical || $0.severity == .warning }
    }

    /// Number of positive achievements
    var achievementCount: Int {
        topInsights.filter { $0.severity == .positive }.count
    }
}

// MARK: - Dashboard Integration Helpers

extension TrendAnalysisSharedViewModel {

    /// Get trending metrics summary for Today hub
    var trendingSummary: String {
        guard !recentAnalyses.isEmpty else {
            return "Complete sessions to see trends"
        }

        let improving = recentAnalyses.filter { $0.summary.direction == .improving }.count
        let declining = recentAnalyses.filter { $0.summary.direction == .declining }.count

        if improving > declining {
            return "\(improving) metrics improving"
        } else if declining > improving {
            return "\(declining) metrics need attention"
        } else {
            return "Performance is stable"
        }
    }

    /// Get adherence trend for quick display
    var adherenceTrend: (value: Double, direction: TrendDirection)? {
        guard let analysis = recentAnalyses.first(where: { $0.metricType == .sessionAdherence }) else {
            return nil
        }
        return (analysis.summary.endValue, analysis.summary.direction)
    }

    /// Get pain trend for quick display
    var painTrend: (value: Double, direction: TrendDirection)? {
        guard let analysis = recentAnalyses.first(where: { $0.metricType == .painLevel }) else {
            return nil
        }
        return (analysis.summary.endValue, analysis.summary.direction)
    }
}

// MARK: - Environment Key

private struct TrendAnalysisViewModelKey: EnvironmentKey {
    @MainActor static var defaultValue: TrendAnalysisSharedViewModel {
        .shared
    }
}

extension EnvironmentValues {
    var trendAnalysisViewModel: TrendAnalysisSharedViewModel {
        get { self[TrendAnalysisViewModelKey.self] }
        set { self[TrendAnalysisViewModelKey.self] = newValue }
    }
}

// MARK: - Tab Badge Manager Extension

extension TrendAnalysisSharedViewModel {

    /// Badge value for analytics tab
    var analyticsBadge: Int? {
        let criticalCount = topInsights.filter { $0.severity == .critical }.count
        return criticalCount > 0 ? criticalCount : nil
    }

    /// Whether to show notification dot on analytics
    var showAnalyticsNotification: Bool {
        hasCriticalInsights || achievementCount > 0
    }
}

// MARK: - Widget Data Provider

extension TrendAnalysisSharedViewModel {

    /// Data for widget display
    func getWidgetData() -> WidgetTrendData? {
        guard let adherenceAnalysis = recentAnalyses.first(where: { $0.metricType == .sessionAdherence }) else {
            return nil
        }

        return WidgetTrendData(
            adherenceValue: adherenceAnalysis.summary.endValue,
            adherenceChange: adherenceAnalysis.summary.percentChange,
            direction: adherenceAnalysis.summary.direction,
            sparklineData: adherenceAnalysis.dataPoints.suffix(7).map { Int($0.value) },
            lastUpdated: Date()
        )
    }
}

/// Data structure for widget display
struct WidgetTrendData {
    let adherenceValue: Double
    let adherenceChange: Double
    let direction: TrendDirection
    let sparklineData: [Int]
    let lastUpdated: Date

    var formattedAdherence: String {
        String(format: "%.0f%%", adherenceValue)
    }

    var formattedChange: String {
        let sign = adherenceChange >= 0 ? "+" : ""
        return String(format: "%@%.0f%%", sign, adherenceChange)
    }
}
