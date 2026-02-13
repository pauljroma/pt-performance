//
//  ModeStatusCardViewModel.swift
//  PTPerformance
//
//  ACP-MODE: ViewModel for loading mode-specific status card data
//  Provides data for RehabModeStatusCard, StrengthModeStatusCard, and PerformanceModeStatusCard
//

import SwiftUI
import Combine

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

    // MARK: - Data Loading

    /// Load all mode-specific data for the given patient
    /// - Parameter patientId: The patient UUID to load data for
    func loadData(for patientId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        // Load data based on current mode
        switch modeService.currentMode {
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
        // Load pain data
        // In production, this would fetch from PainTrackingService
        // For now, use placeholder data to demonstrate the UI

        do {
            // Load deload recommendation (using shared service instance)
            try await deloadService.fetchRecommendation(patientId: patientId)
            if let recommendation = deloadService.recommendation {
                deloadUrgency = recommendation.urgency
            }

            // Reset other rehab data (would be loaded from services in production)
            todayPainScore = nil
            previousPainScore = nil
            activePainRegions = []
            hasActiveAlerts = false
            alertCount = 0

            DebugLogger.shared.log("[ModeStatusCardVM] Rehab data loaded", level: .diagnostic)
        } catch {
            DebugLogger.shared.log("[ModeStatusCardVM] Failed to load rehab data: \(error)", level: .warning)
        }
    }

    // MARK: - Strength Data

    private func loadStrengthData(for patientId: UUID) async {
        do {
            // Load big lifts and streak in parallel
            async let summariesTask = BigLiftsService.shared.fetchBigLiftsSummary(patientId: patientId)
            async let streakTask = StreakTrackingService.shared.getCombinedStreak(for: patientId)

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
                    unit: "lbs"
                )
            }

            // Calculate volume trend (placeholder - would use volume analytics service)
            volumeTrend = .unknown

            // Use streak result
            if let streak = streak {
                strengthStreak = streak.currentStreak
            }

            // Reset PR data (would be loaded from PR tracking service)
            recentPRs = []

            DebugLogger.shared.log("[ModeStatusCardVM] Strength data loaded: total=\(estimatedTotal ?? 0)", level: .diagnostic)
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
                    readinessScore = max(0, 100 - (fatigue.fatigueScore ?? 5) * 10)
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
            performanceStatusData = .empty
        }
    }

    // MARK: - Refresh

    /// Refresh data for the current mode
    /// - Parameter patientId: The patient UUID to refresh data for
    func refresh(for patientId: UUID) async {
        await loadData(for: patientId)
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

    var formattedACWR: String {
        String(format: "%.2f", acwrValue)
    }

    var formattedReadiness: String {
        String(format: "%.0f", readinessScore)
    }

    var hasData: Bool {
        acwrValue > 0 || readinessScore > 0
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
        case 0.8...1.3:
            return .optimal
        case 1.3...1.5:
            return .caution
        case 1.5...:
            return .danger
        default:
            return .unknown
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
