//
//  ModeStatusCardViewModel.swift
//  PTPerformance
//
//  ACP-MODE: ViewModel for loading mode-specific status card data
//  Provides data for RehabModeStatusCard, StrengthModeStatusCard, and PerformanceModeStatusCard
//

import SwiftUI

/// ViewModel for loading mode-specific status card data
/// Supports Rehab, Strength, and Performance modes with appropriate metrics
@MainActor
class ModeStatusCardViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var errorMessage: String?

    // Rehab Mode Data
    @Published var todayPainScore: Int?
    @Published var previousPainScore: Int?
    @Published var activePainRegions: [PainLocation] = []
    @Published var hasActiveAlerts = false
    @Published var alertCount = 0
    @Published var deloadUrgency: DeloadUrgency?

    // Strength Mode Data
    @Published var estimatedTotal: Double?
    @Published var topLifts: [TopLiftInfo] = []
    @Published var recentPRs: [RecentPRInfo] = []
    @Published var volumeTrend: VolumeTrend = .unknown
    @Published var strengthStreak = 0

    // Performance Mode Data
    @Published var performanceStatusData: PerformanceStatusData = .empty

    // MARK: - Services

    private let modeService = ModeService.shared
    private let deloadService = DeloadRecommendationService.shared
    /// ReadinessService is instantiated fresh rather than using a singleton because:
    /// 1. It's @MainActor isolated with @Published properties for UI state management
    /// 2. Each ViewModel instance needs its own loading/error state
    /// 3. The service uses dependency injection (PTSupabaseClient.shared) internally
    private let readinessService = ReadinessService()
    private let volumeAnalyticsService = VolumeAnalyticsService()

    // MARK: - Data Loading

    /// Load all mode-specific data for the given patient
    /// - Parameters:
    ///   - patientId: The patient UUID to load data for
    ///   - mode: The patient's actual mode. Falls back to `modeService.currentMode` when nil.
    func loadData(for patientId: UUID, mode: Mode? = nil) async {
        isLoading = true
        defer { isLoading = false }

        let activeMode = mode ?? modeService.currentMode

        // Load data based on the patient's active mode
        switch activeMode {
        case .rehab:
            await loadRehabData(for: patientId)
        case .strength:
            await loadStrengthData(for: patientId)
        case .performance:
            await loadPerformanceData(for: patientId)
        }
    }

    // MARK: - Rehab Data

    private func loadRehabData(for patientId: UUID) async {
        // Pain scores require PainTrackingService (not yet available)
        // Keep nil/empty for honesty rather than faking data
        todayPainScore = nil
        previousPainScore = nil
        activePainRegions = []

        do {
            // Load deload recommendation (using shared service instance)
            try await deloadService.fetchRecommendation(patientId: patientId)
            if let recommendation = deloadService.recommendation {
                deloadUrgency = recommendation.urgency

                // Derive alert state from deload urgency:
                // recommended/required urgency levels indicate actionable alerts
                switch recommendation.urgency {
                case .recommended:
                    hasActiveAlerts = true
                    alertCount = 1
                case .required:
                    hasActiveAlerts = true
                    alertCount = 1
                case .none, .suggested:
                    hasActiveAlerts = false
                    alertCount = 0
                }
            } else {
                deloadUrgency = nil
                hasActiveAlerts = false
                alertCount = 0
            }

            DebugLogger.shared.log("[ModeStatusCardVM] Rehab data loaded (alerts=\(alertCount))", level: .diagnostic)
        } catch is CancellationError {
            DebugLogger.shared.log("[ModeStatusCardVM] Rehab load cancelled, will retry", level: .diagnostic)
        } catch {
            DebugLogger.shared.log("[ModeStatusCardVM] Failed to load rehab data: \(error)", level: .warning)
            hasActiveAlerts = false
            alertCount = 0
        }
    }

    // MARK: - Strength Data

    private func loadStrengthData(for patientId: UUID) async {
        do {
            // Load big lifts, streak, and volume data in parallel
            async let summariesTask = BigLiftsService.shared.fetchBigLiftsSummary(patientId: patientId)
            async let streakTask = StreakTrackingService.shared.getCombinedStreak(for: patientId)
            async let volumeTask = volumeAnalyticsService.fetchVolumeTimeSeries(
                patientId: patientId.uuidString,
                period: .month
            )

            let summaries = try await summariesTask
            let streak = try await streakTask

            // Calculate estimated total from core lifts
            let coreLifts = summaries.filter { ["Bench Press", "Squat", "Deadlift"].contains($0.exerciseName) }
            estimatedTotal = coreLifts.isEmpty ? nil : coreLifts.reduce(0) { $0 + $1.estimated1rm }

            // Convert to TopLiftInfo for display
            topLifts = coreLifts.map { lift in
                TopLiftInfo(
                    exerciseName: lift.exerciseName,
                    weight: lift.estimated1rm,
                    unit: lift.loadUnit
                )
            }

            // Calculate volume trend by comparing the last two weekly data points
            do {
                let volumeDataPoints = try await volumeTask
                volumeTrend = Self.deriveVolumeTrend(from: volumeDataPoints)
            } catch {
                DebugLogger.shared.log("[ModeStatusCardVM] Volume trend fetch failed, falling back to .unknown: \(error)", level: .warning)
                volumeTrend = .unknown
            }

            // Use streak result
            if let streak = streak {
                strengthStreak = streak.currentStreak
            }

            // Derive recent PRs from BigLiftSummary lastPrDate (within last 7 days)
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            recentPRs = summaries.compactMap { lift -> RecentPRInfo? in
                guard let prDate = lift.lastPrDate, prDate > sevenDaysAgo else { return nil }
                return RecentPRInfo(
                    exerciseName: lift.exerciseName,
                    weight: lift.currentMaxWeight,
                    unit: lift.loadUnit,
                    date: prDate,
                    improvement: lift.improvementPct30d
                )
            }

            DebugLogger.shared.log("[ModeStatusCardVM] Strength data loaded: total=\(estimatedTotal ?? 0), recentPRs=\(recentPRs.count)", level: .diagnostic)
        } catch is CancellationError {
            DebugLogger.shared.log("[ModeStatusCardVM] Strength load cancelled, will retry", level: .diagnostic)
        } catch {
            DebugLogger.shared.log("[ModeStatusCardVM] Failed to load strength data: \(error)", level: .warning)
            // Reset to defaults on error
            estimatedTotal = nil
            topLifts = []
            recentPRs = []
            volumeTrend = .unknown
            strengthStreak = 0
        }
    }

    // MARK: - Volume Trend Calculation

    /// Derive a volume trend by comparing the last two weekly data points
    /// - Parameter dataPoints: Weekly volume data points sorted chronologically
    /// - Returns: The derived VolumeTrend
    private static func deriveVolumeTrend(from dataPoints: [VolumeDataPoint]) -> VolumeTrend {
        // Need at least 2 weeks of data to compare
        guard dataPoints.count >= 2 else { return .unknown }

        let currentWeek = dataPoints[dataPoints.count - 1].totalVolume
        let previousWeek = dataPoints[dataPoints.count - 2].totalVolume

        guard previousWeek > 0 else { return .unknown }

        let percentChange = ((currentWeek - previousWeek) / previousWeek) * 100

        // Treat changes within +/-threshold as stable
        if abs(percentChange) < VolumeTrendThreshold.stablePercent {
            return .stable
        } else if percentChange > 0 {
            return .up(percentage: percentChange)
        } else {
            return .down(percentage: abs(percentChange))
        }
    }

    // MARK: - Performance Data

    private func loadPerformanceData(for patientId: UUID) async {
        do {
            // Load fatigue/ACWR data and readiness in parallel
            let fatigueService = FatigueTrackingService.shared

            // Fetch fatigue and readiness in parallel
            async let fatigueTask: Void = fatigueService.fetchCurrentFatigue(patientId: patientId)
            async let readinessTask: DailyReadiness? = {
                do {
                    return try await readinessService.getTodayReadiness(for: patientId)
                } catch {
                    DebugLogger.shared.log("[ModeStatusCardVM] Failed to load readiness: \(error)", level: .warning)
                    return nil
                }
            }()

            // Wait for both
            try await fatigueTask
            let todayReadiness = await readinessTask

            if let fatigue = fatigueService.currentFatigue {
                let acwr = fatigue.acuteChronicRatio ?? 1.0

                // Calculate readiness score from parallel-fetched data
                var readinessScore: Double = 0
                if let todayReadiness = todayReadiness,
                   let score = todayReadiness.readinessScore {
                    readinessScore = score
                } else {
                    DebugLogger.shared.log("[ModeStatusCardVM] Readiness data not available, falling back to fatigue-based calculation", level: .diagnostic)
                    readinessScore = max(0, 100 - fatigue.fatigueScore * 10)
                }

                performanceStatusData = PerformanceStatusData(
                    acwrValue: acwr,
                    readinessScore: readinessScore,
                    trainingRecommendation: ACWRStatus.status(for: acwr).recommendation,
                    lastUpdated: Date()
                )

                DebugLogger.shared.log("[ModeStatusCardVM] Performance data loaded: ACWR=\(acwr), readiness=\(readinessScore)", level: .diagnostic)
            } else {
                // No fatigue data available, use empty state
                performanceStatusData = .empty
                DebugLogger.shared.log("[ModeStatusCardVM] No fatigue data available, using empty state", level: .diagnostic)
            }
        } catch {
            DebugLogger.shared.log("[ModeStatusCardVM] Failed to load performance data: \(error)", level: .warning)
            if error is CancellationError { return }
            performanceStatusData = .empty
        }
    }

    // MARK: - Refresh

    /// Refresh data for the current mode
    /// - Parameters:
    ///   - patientId: The patient UUID to refresh data for
    ///   - mode: The patient's actual mode. Falls back to `modeService.currentMode` when nil.
    func refresh(for patientId: UUID, mode: Mode? = nil) async {
        await loadData(for: patientId, mode: mode)
    }
}

// MARK: - Supporting Types

/// Weekly volume comparison trend
enum VolumeTrend {
    case up(percentage: Double)
    case down(percentage: Double)
    case stable
    case unknown

    var icon: String {
        switch self {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return .blue
        case .unknown: return .secondary
        }
    }

    var isUnknown: Bool {
        if case .unknown = self { return true }
        return false
    }
}

/// Information about a top lift
struct TopLiftInfo: Identifiable {
    let exerciseName: String
    let weight: Double
    let unit: String

    var id: String {
        "\(exerciseName)-\(weight)"
    }
}

/// Information about a recent personal record
struct RecentPRInfo: Identifiable {
    let exerciseName: String
    let weight: Double
    let unit: String
    let date: Date
    let improvement: Double?

    var id: String {
        "\(exerciseName)-\(date.timeIntervalSince1970)"
    }
}

/// Performance mode status data
struct PerformanceStatusData {
    let acwrValue: Double
    let readinessScore: Double
    let trainingRecommendation: String
    let lastUpdated: Date?

    /// Whether real data was loaded (as opposed to the empty placeholder).
    /// Uses `lastUpdated` as a sentinel: empty state has nil, real data always sets a date.
    /// This avoids treating a legitimate readinessScore of 0 as "no data".
    var hasData: Bool {
        lastUpdated != nil
    }

    var formattedACWR: String {
        String(format: "%.2f", acwrValue)
    }

    var formattedReadiness: String {
        String(format: "%.0f", readinessScore)
    }

    static let empty = PerformanceStatusData(
        acwrValue: 0,
        readinessScore: 0,
        trainingRecommendation: "",
        lastUpdated: nil
    )
}

/// ACWR (Acute:Chronic Workload Ratio) status categories
enum ACWRStatus: String, CaseIterable {
    case undertraining = "Undertraining"
    case optimal = "Optimal"
    case caution = "Caution"
    case danger = "Danger"
    case unknown = "Unknown"

    /// Initialize from ACWR value
    static func status(for value: Double) -> ACWRStatus {
        switch value {
        case ..<0.8:
            return .undertraining
        case 0.8..<1.3:
            return .optimal
        case 1.3..<1.5:
            return .caution
        case 1.5...:
            return .danger
        default:
            return .unknown
        }
    }

    /// Color associated with this ACWR status
    var color: Color {
        switch self {
        case .undertraining: return .blue
        case .optimal: return .green
        case .caution: return .orange
        case .danger: return .red
        case .unknown: return .secondary
        }
    }

    /// SF Symbol icon associated with this ACWR status
    var icon: String {
        switch self {
        case .undertraining: return "arrow.down.circle"
        case .optimal: return "checkmark.circle.fill"
        case .caution: return "exclamationmark.triangle"
        case .danger: return "xmark.octagon.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    var recommendation: String {
        switch self {
        case .undertraining: return "Consider increasing training load"
        case .optimal: return "Training load is well balanced"
        case .caution: return "Monitor fatigue levels closely"
        case .danger: return "Consider reducing training load"
        case .unknown: return "Insufficient data for recommendation"
        }
    }
}
