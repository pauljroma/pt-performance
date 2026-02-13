//
//  StrengthModeDashboardViewModel.swift
//  PTPerformance
//
//  ViewModel for the Strength Mode Dashboard
//  Aggregates big lifts, PRs, volume, streaks, and progression suggestions
//

import SwiftUI

// MARK: - Supporting Models

/// Weekly volume data for strength dashboard
struct WeeklyVolumeData: Equatable {
    let weekStart: Date
    let totalVolume: Double
    let sessionCount: Int
    let averageVolumePerSession: Double

    /// Formatted total volume string
    var formattedTotal: String {
        if totalVolume >= 1000 {
            return String(format: "%.1fK lbs", totalVolume / 1000)
        } else {
            return String(format: "%.0f lbs", totalVolume)
        }
    }

    /// Formatted average volume string
    var formattedAverage: String {
        String(format: "%.0f lbs/session", averageVolumePerSession)
    }

    static let empty = WeeklyVolumeData(
        weekStart: Date(),
        totalVolume: 0,
        sessionCount: 0,
        averageVolumePerSession: 0
    )
}

/// ViewModel for the Strength Mode Dashboard
///
/// Manages state and data loading for the strength-focused dashboard,
/// aggregating big lifts data, personal records, weekly volume,
/// current streak, and AI-powered progression suggestions.
///
/// ## Usage Example
/// ```swift
/// @StateObject private var viewModel = StrengthModeDashboardViewModel()
///
/// var body: some View {
///     StrengthDashboardView()
///         .task {
///             await viewModel.loadDashboardData()
///         }
/// }
/// ```
@MainActor
class StrengthModeDashboardViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Big lifts summary data (squat, bench, deadlift, etc.)
    @Published var bigLifts: [BigLiftSummary] = []

    /// Recent personal records from the last 30 days
    @Published var recentPRs: [PersonalRecord] = []

    /// Weekly volume totals
    @Published var weeklyVolume: WeeklyVolumeData = .empty

    /// Current workout streak (consecutive days)
    @Published var currentStreak: Int = 0

    /// AI-powered progression suggestions for exercises
    @Published var progressionSuggestions: [ProgressionSuggestion] = []

    /// Loading state indicator
    @Published var isLoading = false

    /// Error message for display to user
    @Published var errorMessage: String?

    /// Whether the error alert should be shown
    @Published var showError = false

    // MARK: - Private Properties

    private let bigLiftsService: BigLiftsService
    private let streakService: StreakTrackingService
    private let progressionService: ProgressiveOverloadAIService
    private let volumeService: VolumeAnalyticsService
    private let supabase: PTSupabaseClient
    private let errorLogger = ErrorLogger.shared
    private let logger = DebugLogger.shared

    /// Track if initial data has been loaded
    private var hasLoadedInitialData = false

    // MARK: - Computed Properties

    /// Current patient ID from authentication
    var patientId: String? {
        supabase.userId
    }

    /// Current patient UUID
    var patientUUID: UUID? {
        guard let id = patientId else { return nil }
        return UUID(uuidString: id)
    }

    /// Whether the dashboard has no data
    var isEmpty: Bool {
        bigLifts.isEmpty && !isLoading
    }

    /// Total PRs across all big lifts
    var totalPRCount: Int {
        bigLifts.reduce(0) { $0 + $1.prCount }
    }

    /// Number of lifts that have improved in the last 30 days
    var improvingLiftsCount: Int {
        bigLifts.filter { $0.isImproving }.count
    }

    /// SBD (Squat/Bench/Deadlift) total using estimated 1RMs
    var sbdTotal: Double {
        calculateSBDTotal()
    }

    /// Formatted SBD total string
    var formattedSBDTotal: String {
        String(format: "%.0f lbs", sbdTotal)
    }

    /// Core lifts only (Squat, Bench, Deadlift)
    var coreLifts: [BigLiftSummary] {
        let coreNames = [
            BigLift.squat.rawValue,
            BigLift.benchPress.rawValue,
            BigLift.deadlift.rawValue
        ]
        return bigLifts.filter { coreNames.contains($0.exerciseName) }
    }

    /// Accessory lifts (OHP, Row, etc.)
    var accessoryLifts: [BigLiftSummary] {
        let coreNames = [
            BigLift.squat.rawValue,
            BigLift.benchPress.rawValue,
            BigLift.deadlift.rawValue
        ]
        return bigLifts.filter { !coreNames.contains($0.exerciseName) }
    }

    /// Whether there are any progression suggestions available
    var hasSuggestions: Bool {
        !progressionSuggestions.isEmpty
    }

    /// Whether streak is at risk (no activity today)
    var isStreakAtRisk: Bool {
        currentStreak > 0 && !hasActivityToday
    }

    /// Track if user has logged activity today
    @Published private(set) var hasActivityToday: Bool = false

    // MARK: - Initialization

    /// Initialize with default services
    init(
        bigLiftsService: BigLiftsService = .shared,
        streakService: StreakTrackingService = .shared,
        progressionService: ProgressiveOverloadAIService = .shared,
        volumeService: VolumeAnalyticsService = VolumeAnalyticsService(),
        supabase: PTSupabaseClient = .shared
    ) {
        self.bigLiftsService = bigLiftsService
        self.streakService = streakService
        self.progressionService = progressionService
        self.volumeService = volumeService
        self.supabase = supabase
    }

    // MARK: - Public Methods

    /// Load all dashboard data
    ///
    /// Fetches big lifts, PRs, volume, streak, and progression suggestions
    /// in parallel where possible for optimal performance.
    func loadDashboardData() async {
        // Prevent duplicate fetches
        guard !hasLoadedInitialData else {
            logger.info("STRENGTH_DASHBOARD", "Skipping reload - data already loaded")
            return
        }

        guard let patientId = patientId, let patientUUID = patientUUID else {
            errorMessage = "Please sign in to view your strength dashboard."
            showError = true
            errorLogger.logError(AppError.notAuthenticated, context: "StrengthModeDashboardViewModel.loadDashboardData")
            return
        }

        isLoading = true
        hasLoadedInitialData = true
        defer { isLoading = false }

        logger.info("STRENGTH_DASHBOARD", "Loading dashboard for patient: \(patientId)")

        // Load each component individually to prevent one failure from stopping others
        await withTaskGroup(of: Void.self) { group in
            // Fetch big lifts
            group.addTask { @MainActor in
                await self.fetchBigLifts(patientId: patientUUID)
            }

            // Fetch streak data
            group.addTask { @MainActor in
                await self.fetchStreakData(patientId: patientUUID)
            }

            // Fetch weekly volume
            group.addTask { @MainActor in
                await self.fetchWeeklyVolume(patientId: patientId)
            }

            // Fetch recent PRs
            group.addTask { @MainActor in
                await self.fetchRecentPRs(patientId: patientId)
            }
        }

        // Fetch progression suggestions after we have big lifts data
        await fetchProgressionSuggestions(patientId: patientUUID)

        logger.success("STRENGTH_DASHBOARD", "Dashboard load complete")
    }

    /// Refresh all dashboard data (pull-to-refresh)
    func refreshData() async {
        hasLoadedInitialData = false
        await loadDashboardData()
    }

    /// Force refresh without checking cache flag
    func forceRefresh() async {
        hasLoadedInitialData = false
        errorMessage = nil
        showError = false
        await loadDashboardData()
    }

    /// Retry loading after an error
    func retryLoad() async {
        errorMessage = nil
        showError = false
        hasLoadedInitialData = false
        await loadDashboardData()
    }

    /// Clear error state
    func clearError() {
        errorMessage = nil
        showError = false
    }

    // MARK: - 1RM Calculations

    /// Calculate estimated 1RM using the Epley formula
    ///
    /// Epley Formula: weight * (1 + reps/30)
    /// Optionally adjusts for RPE if provided.
    ///
    /// - Parameters:
    ///   - weight: The weight lifted (in lbs)
    ///   - reps: Number of repetitions performed
    ///   - rpe: Optional Rate of Perceived Exertion (0-10 scale)
    /// - Returns: Estimated one-rep max
    func calculateEstimated1RM(weight: Double, reps: Int, rpe: Double? = nil) -> Double {
        guard reps > 0 else { return weight }

        // Epley formula: weight * (1 + reps/30)
        var estimated1RM = weight * (1.0 + Double(reps) / 30.0)

        // Adjust for RPE if provided (RPE 10 = true max, lower RPE means more in tank)
        if let rpe = rpe, rpe > 0 && rpe < 10 {
            // Estimate reps in reserve based on RPE (10 - RPE = RIR)
            let repsInReserve = 10.0 - rpe
            // Adjust 1RM estimate upward based on RIR
            let adjustmentFactor = 1.0 + (repsInReserve * 0.033)
            estimated1RM *= adjustmentFactor
        }

        return estimated1RM
    }

    /// Calculate SBD (Squat/Bench/Deadlift) total
    ///
    /// Uses estimated 1RMs from the big lifts data for the three
    /// powerlifting competition lifts.
    ///
    /// - Returns: Combined SBD total in pounds
    func calculateSBDTotal() -> Double {
        let coreNames = [
            BigLift.squat.rawValue,
            BigLift.benchPress.rawValue,
            BigLift.deadlift.rawValue
        ]

        return bigLifts
            .filter { coreNames.contains($0.exerciseName) }
            .reduce(0) { $0 + $1.estimated1rm }
    }

    // MARK: - Helper Methods

    /// Get the icon name for a lift
    func iconName(for exerciseName: String) -> String {
        if let lift = BigLift.allCases.first(where: { $0.rawValue == exerciseName }) {
            return lift.iconName
        }
        return "dumbbell.fill"
    }

    /// Check if an exercise is a core lift (SBD)
    func isCoreLift(_ exerciseName: String) -> Bool {
        let coreNames = [
            BigLift.squat.rawValue,
            BigLift.benchPress.rawValue,
            BigLift.deadlift.rawValue
        ]
        return coreNames.contains(exerciseName)
    }

    /// Get suggestion for a specific exercise
    func suggestion(for exerciseName: String) -> ProgressionSuggestion? {
        // Find a suggestion that matches this exercise
        // This is a simplified lookup - in practice, suggestions are tied to exercise template IDs
        progressionSuggestions.first
    }

    // MARK: - Private Data Fetching Methods

    /// Fetch big lifts summary data
    private func fetchBigLifts(patientId: UUID) async {
        do {
            let summaries = try await bigLiftsService.fetchBigLiftsSummary(patientId: patientId)
            bigLifts = summaries
            logger.success("STRENGTH_DASHBOARD", "Fetched \(summaries.count) big lifts")
        } catch {
            errorLogger.logError(error, context: "StrengthModeDashboardViewModel.fetchBigLifts", metadata: [
                "patient_id": patientId.uuidString
            ])
            logger.error("STRENGTH_DASHBOARD", "Error fetching big lifts: \(error.localizedDescription)")
        }
    }

    /// Fetch streak data
    private func fetchStreakData(patientId: UUID) async {
        do {
            // Fetch workout streak
            if let workoutStreak = try await streakService.fetchStreak(for: patientId, type: .workout) {
                currentStreak = workoutStreak.currentStreak
            } else if let combinedStreak = try await streakService.getCombinedStreak(for: patientId) {
                currentStreak = combinedStreak.currentStreak
            }

            // Check if activity was logged today
            hasActivityToday = await streakService.hasActivityToday(for: patientId)

            logger.success("STRENGTH_DASHBOARD", "Fetched streak: \(currentStreak) days")
        } catch {
            errorLogger.logError(error, context: "StrengthModeDashboardViewModel.fetchStreakData", metadata: [
                "patient_id": patientId.uuidString
            ])
            logger.error("STRENGTH_DASHBOARD", "Error fetching streak: \(error.localizedDescription)")
        }
    }

    /// Fetch weekly volume data
    private func fetchWeeklyVolume(patientId: String) async {
        do {
            let chartData = try await volumeService.calculateVolumeData(for: patientId, period: .week)

            // Get current week's data
            let calendar = Calendar.current
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()

            let currentWeekVolume = chartData.dataPoints
                .filter { calendar.isDate($0.date, equalTo: weekStart, toGranularity: .weekOfYear) }
                .reduce(0.0) { $0 + $1.totalVolume }

            let sessionCount = chartData.dataPoints
                .filter { calendar.isDate($0.date, equalTo: weekStart, toGranularity: .weekOfYear) }
                .reduce(0) { $0 + $1.sessionCount }

            weeklyVolume = WeeklyVolumeData(
                weekStart: weekStart,
                totalVolume: currentWeekVolume > 0 ? currentWeekVolume : chartData.totalVolume,
                sessionCount: sessionCount > 0 ? sessionCount : chartData.dataPoints.count,
                averageVolumePerSession: sessionCount > 0 ? currentWeekVolume / Double(sessionCount) : chartData.averageVolume
            )

            logger.success("STRENGTH_DASHBOARD", "Fetched weekly volume: \(weeklyVolume.formattedTotal)")
        } catch {
            errorLogger.logError(error, context: "StrengthModeDashboardViewModel.fetchWeeklyVolume", metadata: [
                "patient_id": patientId
            ])
            logger.error("STRENGTH_DASHBOARD", "Error fetching weekly volume: \(error.localizedDescription)")
        }
    }

    /// Fetch recent personal records from the last 30 days
    private func fetchRecentPRs(patientId: String) async {
        // Build PRs from big lifts data that have recent PR dates
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        recentPRs = bigLifts.compactMap { lift -> PersonalRecord? in
            guard let prDate = lift.lastPrDate, prDate > thirtyDaysAgo else { return nil }

            return PersonalRecord(
                exerciseId: lift.id,
                exerciseName: lift.exerciseName,
                recordType: .maxWeight,
                value: lift.currentMaxWeight,
                achievedDate: prDate,
                previousRecord: lift.improvementPct30d.map { pct in
                    // Calculate previous value from improvement percentage
                    lift.currentMaxWeight / (1 + pct / 100)
                }
            )
        }

        logger.success("STRENGTH_DASHBOARD", "Found \(recentPRs.count) recent PRs")
    }

    /// Fetch AI-powered progression suggestions
    private func fetchProgressionSuggestions(patientId: UUID) async {
        // Only fetch suggestions if we have big lifts data
        guard !bigLifts.isEmpty else {
            logger.info("STRENGTH_DASHBOARD", "Skipping progression suggestions - no big lifts data")
            return
        }

        // Generate local suggestions based on recent performance
        // This is a fallback when we don't have specific exercise template IDs
        var suggestions: [ProgressionSuggestion] = []

        for lift in bigLifts.prefix(3) { // Limit to top 3 lifts for performance
            // Create a sample performance entry from the big lift data
            let performance = ExercisePerformance(
                date: lift.lastPerformed ?? Date(),
                load: lift.currentMaxWeight,
                reps: [5], // Assume 5-rep set for strength training
                rpe: 7.5  // Default moderate RPE
            )

            // Generate local suggestion using the ProgressiveOverloadAIService
            let suggestion = progressionService.generateLocalSuggestion(
                recentPerformance: [performance],
                targetReps: 5,
                deloadActive: false
            )

            suggestions.append(suggestion)
        }

        progressionSuggestions = suggestions
        logger.success("STRENGTH_DASHBOARD", "Generated \(suggestions.count) progression suggestions")
    }
}

// MARK: - Preview Support

#if DEBUG
extension StrengthModeDashboardViewModel {
    /// Create a preview view model with sample data
    static var preview: StrengthModeDashboardViewModel {
        let viewModel = StrengthModeDashboardViewModel()
        viewModel.bigLifts = BigLiftSummary.sampleArray
        viewModel.currentStreak = 12
        viewModel.weeklyVolume = WeeklyVolumeData(
            weekStart: Date(),
            totalVolume: 45000,
            sessionCount: 4,
            averageVolumePerSession: 11250
        )
        viewModel.recentPRs = [PersonalRecord.sample]
        viewModel.progressionSuggestions = [ProgressionSuggestion.sample]
        viewModel.hasActivityToday = true
        return viewModel
    }

    /// Create an empty preview view model
    static var emptyPreview: StrengthModeDashboardViewModel {
        let viewModel = StrengthModeDashboardViewModel()
        return viewModel
    }

    /// Create a loading preview view model
    static var loadingPreview: StrengthModeDashboardViewModel {
        let viewModel = StrengthModeDashboardViewModel()
        viewModel.isLoading = true
        return viewModel
    }

    /// Create an error preview view model
    static var errorPreview: StrengthModeDashboardViewModel {
        let viewModel = StrengthModeDashboardViewModel()
        viewModel.errorMessage = "Unable to load strength data. Please try again."
        viewModel.showError = true
        return viewModel
    }
}
#endif
