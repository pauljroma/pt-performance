import SwiftUI

/// ACP-901, ACP-902, ACP-903: ViewModel for Recovery Tracking UI
/// Manages state for recovery dashboard, timer logic, stats calculations, and training recommendations
@MainActor
final class RecoveryTrackingViewModel: ObservableObject {

    // MARK: - Static Formatters
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    // MARK: - Published State

    @Published var recentSessions: [RecoverySession] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var healthKitPermissionNeeded: Bool = false

    // Sheet/Navigation State
    @Published var showingLogSheet: Bool = false
    @Published var showingTimer: Bool = false
    @Published var showWorkoutPicker: Bool = false
    @Published var selectedSessionType: RecoverySessionType?
    @Published var timerConfig: TimerConfiguration?

    // Streak State
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var hasRecoveredToday: Bool = false

    // Recovery Status State
    @Published var recoveryScore: Int = 0
    @Published var recoveryStatus: RecoveryStatus = .moderate
    @Published var sleepHours: Double = 0.0
    @Published var hrvValue: Int = 0
    @Published var sorenessLevel: SorenessLevel = .none
    @Published var trainingRecommendation: TrainingRecommendation?

    // Low Recovery Alert State
    @Published var showLowRecoveryAlert: Bool = false

    // Weekly Trend Data
    @Published var weeklyTrendData: [DailyRecoveryTrend] = []

    // Recovery Methods Logged Today
    @Published var recoveryMethodsLoggedToday: Set<RecoveryMethod> = []

    // MARK: - Dependencies

    private let recoveryService: RecoveryService
    private let streakService: StreakTrackingService

    // MARK: - Initialization

    init(
        recoveryService: RecoveryService,
        streakService: StreakTrackingService
    ) {
        self.recoveryService = recoveryService
        self.streakService = streakService
    }

    /// Convenience initializer using shared instances
    convenience init() {
        self.init(
            recoveryService: RecoveryService.shared,
            streakService: StreakTrackingService.shared
        )
    }

    // MARK: - Computed Properties

    /// Weekly statistics for the dashboard
    var weeklyStats: WeeklyRecoveryStats {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weeklySessions = recentSessions.filter { $0.loggedAt >= weekAgo }

        let totalMinutes = weeklySessions.reduce(0) { $0 + $1.durationMinutes }

        // Find most used protocol
        let protocolCounts = weeklySessions.safeGrouped(by: { $0.protocolType })
        let favoriteType = protocolCounts.max(by: { $0.value.count < $1.value.count })?.key

        return WeeklyRecoveryStats(
            sessions: weeklySessions.count,
            totalMinutes: totalMinutes,
            favoriteType: favoriteType
        )
    }

    /// Weekly breakdown by recovery type
    var weeklyBreakdown: [RecoveryTypeBreakdown] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weeklySessions = recentSessions.filter { $0.loggedAt >= weekAgo }

        let grouped = weeklySessions.safeGrouped(by: { $0.protocolType })

        return grouped.map { type, sessions in
            RecoveryTypeBreakdown(
                type: type,
                count: sessions.count,
                totalMinutes: sessions.reduce(0) { $0 + $1.durationMinutes }
            )
        }.sorted { $0.count > $1.count }
    }

    /// Streak message based on current streak
    var streakMessage: String {
        if currentStreak == 0 {
            return "Start your streak today!"
        } else if currentStreak == 1 {
            return "Keep it going tomorrow!"
        } else if currentStreak < 7 {
            return "Building momentum!"
        } else if currentStreak < 14 {
            return "One week strong!"
        } else if currentStreak < 30 {
            return "Impressive consistency!"
        } else {
            return "Recovery champion!"
        }
    }

    /// Formatted recovery score for display
    var formattedRecoveryScore: String {
        "\(recoveryScore)%"
    }

    /// Sleep status indicator
    var sleepStatus: MetricStatus {
        if sleepHours >= 7.0 {
            return .good
        } else if sleepHours >= 6.0 {
            return .moderate
        } else {
            return .poor
        }
    }

    /// HRV status indicator
    var hrvStatus: MetricStatus {
        if hrvValue >= 50 {
            return .good
        } else if hrvValue >= 35 {
            return .moderate
        } else {
            return .poor
        }
    }

    /// Soreness status indicator
    var sorenessStatus: MetricStatus {
        switch sorenessLevel {
        case .none, .low:
            return .good
        case .moderate:
            return .moderate
        case .high, .severe:
            return .poor
        }
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        error = nil

        // Fetch recent sessions
        await recoveryService.fetchSessions(days: 30)
        recentSessions = recoveryService.sessions

        // Check for service errors
        if let serviceError = recoveryService.error {
            self.error = "Unable to load recovery data. Please try again."
            DebugLogger.shared.error("RecoveryTrackingViewModel", "Failed to load data: \(serviceError)")
        }

        // Calculate streak data
        await calculateStreakData()

        // Check if recovered today
        hasRecoveredToday = recentSessions.contains { session in
            Calendar.current.isDateInToday(session.loggedAt)
        }

        // Calculate recovery status and score
        await calculateRecoveryStatus()

        // Generate training recommendation
        generateTrainingRecommendation()

        // Calculate weekly trend
        calculateWeeklyTrend()

        // Check for low recovery alert
        checkLowRecoveryAlert()

        isLoading = false
    }

    private func calculateStreakData() async {
        let calendar = Calendar.current
        var streak = 0
        var maxStreak = 0
        var currentDate = calendar.startOfDay(for: Date())

        // Check today first
        let todaySessions = recentSessions.filter { calendar.isDateInToday($0.loggedAt) }
        if !todaySessions.isEmpty {
            streak = 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }

        // Go backwards checking each day
        while true {
            let daySessions = recentSessions.filter {
                calendar.isDate($0.loggedAt, inSameDayAs: currentDate)
            }

            if daySessions.isEmpty {
                break
            }

            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }

        currentStreak = streak

        // Calculate longest streak (look through all sessions)
        // Avoid Set with Date values — iOS 26 beta crashes on Date value witnesses.
        // Use manual deduplication instead.
        var seenDays = [Date]()
        for session in recentSessions {
            let day = calendar.startOfDay(for: session.loggedAt)
            if !seenDays.contains(where: { calendar.isDate($0, inSameDayAs: day) }) {
                seenDays.append(day)
            }
        }
        let sortedDates = seenDays.sorted()

        guard sortedDates.count > 1 else {
            longestStreak = max(sortedDates.isEmpty ? 0 : 1, streak)
            return
        }

        var tempStreak = 1
        for i in 1..<sortedDates.count {
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: sortedDates[i - 1]),
               calendar.isDate(sortedDates[i], inSameDayAs: nextDay) {
                tempStreak += 1
                maxStreak = max(maxStreak, tempStreak)
            } else {
                tempStreak = 1
            }
        }

        longestStreak = max(maxStreak, streak)
    }

    private func calculateRecoveryStatus() async {
        // Fetch health data from HealthKit for recovery score calculation
        let healthKitService = HealthKitService.shared

        // Check if HealthKit is authorized
        let isAuthorized = healthKitService.isAuthorized || healthKitService.checkAuthorizationStatus()

        if !isAuthorized {
            healthKitPermissionNeeded = true
        }

        // Try to fetch actual HealthKit data
        do {
            // Fetch sleep data
            if let sleepData = try await healthKitService.fetchSleepData(for: Date()) {
                sleepHours = sleepData.totalHours
                healthKitPermissionNeeded = false
            } else {
                // Fallback to default if no data
                sleepHours = 7.0
            }

            // Fetch HRV data
            if let hrv = try await healthKitService.fetchHRV(for: Date()) {
                hrvValue = Int(hrv)
                healthKitPermissionNeeded = false
            } else {
                // Fallback to default if no data
                hrvValue = 50
            }
        } catch HealthKitError.notAuthorized {
            // HealthKit not authorized - prompt user
            healthKitPermissionNeeded = true
            DebugLogger.shared.log("[RecoveryTrackingViewModel] HealthKit not authorized", level: .warning)
            sleepHours = 7.0
            hrvValue = 50
        } catch {
            // HealthKit not available - use sensible defaults
            DebugLogger.shared.log("[RecoveryTrackingViewModel] HealthKit data unavailable: \(error.localizedDescription)", level: .warning)
            sleepHours = 7.0
            hrvValue = 50
        }

        // Soreness is user-reported, defaults to none if not set
        // In future, this could be persisted from user input

        // Calculate composite recovery score
        let sleepScore = min(100, (sleepHours / 8.0) * 100)
        let hrvScore = min(100, (Double(hrvValue) / 70.0) * 100)
        let sorenessScore: Double
        switch sorenessLevel {
        case .none: sorenessScore = 100
        case .low: sorenessScore = 85
        case .moderate: sorenessScore = 60
        case .high: sorenessScore = 35
        case .severe: sorenessScore = 10
        }

        // Weighted average: Sleep 40%, HRV 35%, Soreness 25%
        let score = (sleepScore * 0.40) + (hrvScore * 0.35) + (sorenessScore * 0.25)

        // Animate score changes for smooth UI transition
        withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
            recoveryScore = Int(score)
            recoveryStatus = RecoveryStatus.from(score: recoveryScore)
        }
    }

    private func generateTrainingRecommendation() {
        trainingRecommendation = TrainingRecommendation.generate(
            recoveryScore: recoveryScore,
            recoveryStatus: recoveryStatus,
            sleepHours: sleepHours,
            hrvValue: hrvValue,
            sorenessLevel: sorenessLevel
        )
    }

    private func calculateWeeklyTrend() {
        let calendar = Calendar.current
        var trends: [DailyRecoveryTrend] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else {
                continue
            }

            let dayName = Self.dayFormatter.string(from: date)

            // Find sessions logged on this specific day
            let daySessions = recentSessions.filter {
                calendar.isDate($0.loggedAt, inSameDayAs: date)
            }

            let hasSessionData = !daySessions.isEmpty

            // Calculate score from actual session data for this day
            let score: Int
            if hasSessionData {
                // Score based on number and duration of recovery sessions that day
                let totalMinutes = daySessions.reduce(0) { $0 + $1.durationMinutes }
                let sessionCount = daySessions.count
                // Base score from session activity: more sessions and longer durations = higher score
                let minuteScore = min(40, totalMinutes * 2) // Up to 40 points for duration
                let countScore = min(30, sessionCount * 15)  // Up to 30 points for multiple sessions
                score = min(100, max(0, 30 + minuteScore + countScore)) // Base 30 + activity bonuses
            } else {
                // No session data for this day - score is 0 to indicate no data
                score = 0
            }

            let status = RecoveryStatus.from(score: score)
            let workoutIntensity = TrainingIntensity.recommended(for: score)

            trends.append(DailyRecoveryTrend(
                date: date,
                dayName: dayName,
                score: score,
                status: status,
                recommendedIntensity: workoutIntensity,
                workoutCompleted: hasSessionData
            ))
        }

        weeklyTrendData = trends
    }

    private func checkLowRecoveryAlert() {
        if recoveryScore < 50 && !hasRecoveredToday {
            showLowRecoveryAlert = true
        }
    }

    // MARK: - Quick Log Actions

    func startQuickLog(for type: RecoveryProtocolType) {
        let sessionType = type.toSessionType
        selectedSessionType = sessionType

        // For quick logs, go directly to timer
        timerConfig = TimerConfiguration(
            sessionType: sessionType,
            duration: sessionType.defaultDuration * 60,
            temperature: nil
        )
        showingTimer = true
    }

    func showAllSessionTypes() {
        selectedSessionType = nil
        showingLogSheet = true
    }

    // MARK: - Recovery Method Logging

    func logRecoveryMethod(_ method: RecoveryMethod) {
        HapticFeedback.medium()
        recoveryMethodsLoggedToday.insert(method)

        // Map recovery method to protocol type if applicable
        if let protocolType = method.toProtocolType {
            startQuickLog(for: protocolType)
        } else {
            // For methods without a timer (stretching, compression, sleep), just log
            Task { [weak self] in
                // In production, would save to backend
                await self?.loadData()
            }
        }
    }

    // MARK: - Training Adjustment Actions

    func adjustWorkout() {
        HapticFeedback.medium()
        showLowRecoveryAlert = false
        // In production, this would navigate to workout adjustment screen
        // or modify today's scheduled workout
    }

    func trainAnyway() {
        HapticFeedback.light()
        showLowRecoveryAlert = false
        // User proceeds with original workout
    }

    func startTodaysWorkout() {
        HapticFeedback.medium()
        showWorkoutPicker = true
    }

    // MARK: - Session Management

    func saveSession(_ input: RecoverySessionInput) async {
        // Validate duration before attempting to save
        guard input.duration > 0 else {
            self.error = "Session duration must be at least 1 second. Please try again."
            HapticFeedback.error()
            return
        }

        isLoading = true

        do {
            try await recoveryService.logSession(
                protocolType: input.protocolType,
                durationSeconds: input.duration,
                temperature: input.temperature,
                perceivedEffort: input.perceivedEffort,
                notes: input.notes
            )

            // Record streak activity
            if let patientId = await getPatientId() {
                do {
                    try await streakService.recordActivity(
                        for: patientId,
                        workoutCompleted: false,
                        armCareCompleted: false
                    )
                } catch {
                    ErrorLogger.shared.logError(error, context: "RecoveryTrackingViewModel.recordStreakActivity")
                }
            }

            await loadData()
            HapticFeedback.success()
        } catch let sessionError as RecoverySessionError {
            // Handle specific recovery session errors with user-friendly messages
            self.error = sessionError.errorDescription
            HapticFeedback.error()
            DebugLogger.shared.error("RecoveryTrackingViewModel", "Failed to save session: \(sessionError)")
        } catch {
            // Handle database constraint violations with user-friendly message
            let errorString = error.localizedDescription
            if errorString.contains("duration_minutes_check") {
                self.error = "Session duration is invalid. Please ensure your session is at least 1 minute long."
            } else {
                self.error = "Failed to save session. Please check your connection and try again."
            }
            HapticFeedback.error()
            DebugLogger.shared.error("RecoveryTrackingViewModel", "Failed to save session: \(error)")
        }

        isLoading = false
    }

    func completeTimerSession(duration: Int, notes: String) async {
        guard let config = timerConfig else { return }

        // Validate duration before attempting to save
        guard duration > 0 else {
            self.error = "Session duration must be at least 1 second. Please try again."
            HapticFeedback.error()
            showingTimer = false
            timerConfig = nil
            return
        }

        let input = RecoverySessionInput(
            sessionType: config.sessionType,
            duration: duration,
            temperature: config.temperature,
            perceivedEffort: 5, // Default effort, user can edit later
            notes: notes.isEmpty ? nil : notes
        )

        await saveSession(input)
        showingTimer = false
        timerConfig = nil
    }

    func cancelTimer() {
        showingTimer = false
        timerConfig = nil
    }

    // MARK: - Helpers

    private func getPatientId() async -> UUID? {
        guard let userId = PTSupabaseClient.shared.client.auth.currentUser?.id else {
            return nil
        }

        struct PatientRow: Decodable {
            let id: UUID
        }

        do {
            let patients: [PatientRow] = try await PTSupabaseClient.shared.client
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

// MARK: - Supporting Types

struct WeeklyRecoveryStats {
    let sessions: Int
    let totalMinutes: Int
    let favoriteType: RecoveryProtocolType?
}

struct RecoveryTypeBreakdown {
    let type: RecoveryProtocolType
    let count: Int
    let totalMinutes: Int
}

struct TimerConfiguration {
    let sessionType: RecoverySessionType
    let duration: Int // seconds
    let temperature: Double?
}

// MARK: - Recovery Status Enum

enum RecoveryStatus: String, CaseIterable {
    case fullyRecovered = "fully_recovered"
    case readyToTrain = "ready_to_train"
    case moderate = "moderate"
    case needsRest = "needs_rest"
    case critical = "critical"

    var displayName: String {
        switch self {
        case .fullyRecovered: return "FULLY RECOVERED"
        case .readyToTrain: return "READY TO TRAIN"
        case .moderate: return "MODERATE RECOVERY"
        case .needsRest: return "NEEDS REST"
        case .critical: return "CRITICAL - REST DAY"
        }
    }

    var color: Color {
        switch self {
        case .fullyRecovered: return .green
        case .readyToTrain: return .modusTealAccent
        case .moderate: return .yellow
        case .needsRest: return .orange
        case .critical: return .red
        }
    }

    var icon: String {
        switch self {
        case .fullyRecovered: return "battery.100"
        case .readyToTrain: return "battery.75"
        case .moderate: return "battery.50"
        case .needsRest: return "battery.25"
        case .critical: return "battery.0"
        }
    }

    static func from(score: Int) -> RecoveryStatus {
        switch score {
        case 90...100: return .fullyRecovered
        case 70..<90: return .readyToTrain
        case 50..<70: return .moderate
        case 30..<50: return .needsRest
        default: return .critical
        }
    }
}

// MARK: - Soreness Level Enum

enum SorenessLevel: String, CaseIterable {
    case none = "none"
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case severe = "severe"

    var displayName: String {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .severe: return "Severe"
        }
    }
}

// MARK: - Metric Status Enum

enum MetricStatus {
    case good
    case moderate
    case poor

    var icon: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .moderate: return "minus.circle.fill"
        case .poor: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .good: return .green
        case .moderate: return .yellow
        case .poor: return .red
        }
    }
}

// MARK: - Recovery Method Enum

enum RecoveryMethod: String, CaseIterable, Identifiable {
    case coldPlunge = "cold_plunge"
    case sauna = "sauna"
    case yoga = "yoga"
    case massage = "massage"
    case stretching = "stretching"
    case compression = "compression"
    case sleep = "sleep"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .coldPlunge: return "Cold"
        case .sauna: return "Sauna"
        case .yoga: return "Yoga"
        case .massage: return "Mass"
        case .stretching: return "Stretch"
        case .compression: return "Comp"
        case .sleep: return "Sleep"
        }
    }

    var fullName: String {
        switch self {
        case .coldPlunge: return "Cold Plunge"
        case .sauna: return "Sauna"
        case .yoga: return "Yoga"
        case .massage: return "Massage"
        case .stretching: return "Stretching"
        case .compression: return "Compression"
        case .sleep: return "Extra Sleep"
        }
    }

    var icon: String {
        switch self {
        case .coldPlunge: return "snowflake"
        case .sauna: return "flame.fill"
        case .yoga: return "figure.yoga"
        case .massage: return "hand.raised.fill"
        case .stretching: return "figure.flexibility"
        case .compression: return "arrow.down.and.line.horizontal.and.arrow.up"
        case .sleep: return "bed.double.fill"
        }
    }

    var color: Color {
        switch self {
        case .coldPlunge: return .cyan
        case .sauna: return .orange
        case .yoga: return .purple
        case .massage: return .pink
        case .stretching: return .green
        case .compression: return .blue
        case .sleep: return .indigo
        }
    }

    /// Maps to RecoveryProtocolType if applicable
    var toProtocolType: RecoveryProtocolType? {
        switch self {
        case .coldPlunge: return .coldPlunge
        case .sauna: return .saunaTraditional
        case .yoga, .massage, .stretching, .compression, .sleep: return nil
        }
    }
}

// MARK: - Training Intensity Enum

enum TrainingIntensity: String, CaseIterable {
    case heavy = "heavy"
    case moderate = "moderate"
    case light = "light"
    case rest = "rest"

    var displayName: String {
        switch self {
        case .heavy: return "Heavy"
        case .moderate: return "Moderate"
        case .light: return "Light"
        case .rest: return "Rest"
        }
    }

    var icon: String {
        switch self {
        case .heavy: return "flame.fill"
        case .moderate: return "bolt.fill"
        case .light: return "leaf.fill"
        case .rest: return "moon.fill"
        }
    }

    var color: Color {
        switch self {
        case .heavy: return .red
        case .moderate: return .orange
        case .light: return .green
        case .rest: return .blue
        }
    }

    static func recommended(for score: Int) -> TrainingIntensity {
        switch score {
        case 80...100: return .heavy
        case 60..<80: return .moderate
        case 40..<60: return .light
        default: return .rest
        }
    }
}

// MARK: - Training Recommendation

struct TrainingRecommendation {
    let headline: String
    let description: String
    let intensity: TrainingIntensity
    let alternativeActivities: [String]
    let icon: String

    static func generate(
        recoveryScore: Int,
        recoveryStatus: RecoveryStatus,
        sleepHours: Double,
        hrvValue: Int,
        sorenessLevel: SorenessLevel
    ) -> TrainingRecommendation {
        switch recoveryStatus {
        case .fullyRecovered:
            return TrainingRecommendation(
                headline: "Peak performance day",
                description: "All systems go! Great day for PR attempts or high-intensity work.",
                intensity: .heavy,
                alternativeActivities: ["Max effort lifts", "High-intensity intervals", "Competition prep"],
                icon: "bolt.circle.fill"
            )

        case .readyToTrain:
            return TrainingRecommendation(
                headline: "Good day for intensity work",
                description: "Recovery looks solid. You can push hard today.",
                intensity: .heavy,
                alternativeActivities: ["Strength training", "Moderate cardio", "Skill work"],
                icon: "checkmark.circle.fill"
            )

        case .moderate:
            return TrainingRecommendation(
                headline: "Moderate intensity recommended",
                description: "Consider reducing volume or intensity by 10-20%.",
                intensity: .moderate,
                alternativeActivities: ["Technique work", "Moderate lifts", "Zone 2 cardio"],
                icon: "arrow.left.arrow.right.circle.fill"
            )

        case .needsRest:
            let hrvNote = hrvValue < 40 ? "HRV down significantly" : ""
            let sleepNote = sleepHours < 6 ? "poor sleep" : ""
            let notes = [hrvNote, sleepNote].filter { !$0.isEmpty }.joined(separator: ", ")

            return TrainingRecommendation(
                headline: "Swap today's heavy work",
                description: "Your recovery is low\(notes.isEmpty ? "" : " (\(notes))"). Focus on light movement.",
                intensity: .light,
                alternativeActivities: ["Light mobility work", "20-min zone 2 cardio", "Extra recovery focus"],
                icon: "exclamationmark.triangle.fill"
            )

        case .critical:
            return TrainingRecommendation(
                headline: "Rest day strongly recommended",
                description: "Your body needs recovery. Skip training today.",
                intensity: .rest,
                alternativeActivities: ["Complete rest", "Light stretching", "Sleep focus", "Hydration"],
                icon: "moon.circle.fill"
            )
        }
    }
}

// MARK: - Daily Recovery Trend

struct DailyRecoveryTrend: Identifiable {
    var id: String { "\(date.timeIntervalSince1970)-\(score)" }
    let date: Date
    let dayName: String
    let score: Int
    let status: RecoveryStatus
    let recommendedIntensity: TrainingIntensity
    let workoutCompleted: Bool

    var scorePercentage: Double {
        Double(score) / 100.0
    }
}

// MARK: - RecoveryProtocolType Extension

extension RecoveryProtocolType {
    /// Converts RecoveryProtocolType to RecoverySessionType for the UI
    var toSessionType: RecoverySessionType {
        switch self {
        case .saunaTraditional: return .traditionalSauna
        case .saunaInfrared: return .infraredSauna
        case .saunaSteam: return .steamRoom
        case .coldPlunge: return .coldPlunge
        case .coldShower: return .coldShower
        case .iceBath: return .iceBath
        case .contrast: return .contrastTherapy
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension RecoveryTrackingViewModel {
    static var preview: RecoveryTrackingViewModel {
        let viewModel = RecoveryTrackingViewModel()
        viewModel.currentStreak = 5
        viewModel.longestStreak = 12
        viewModel.hasRecoveredToday = true
        viewModel.recoveryScore = 78
        viewModel.recoveryStatus = .readyToTrain
        viewModel.sleepHours = 7.2
        viewModel.hrvValue = 58
        viewModel.sorenessLevel = .low
        viewModel.trainingRecommendation = TrainingRecommendation.generate(
            recoveryScore: 78,
            recoveryStatus: .readyToTrain,
            sleepHours: 7.2,
            hrvValue: 58,
            sorenessLevel: .low
        )
        return viewModel
    }

    static var lowRecoveryPreview: RecoveryTrackingViewModel {
        let viewModel = RecoveryTrackingViewModel()
        viewModel.recoveryScore = 45
        viewModel.recoveryStatus = .needsRest
        viewModel.sleepHours = 5.2
        viewModel.hrvValue = 32
        viewModel.sorenessLevel = .high
        viewModel.showLowRecoveryAlert = true
        viewModel.trainingRecommendation = TrainingRecommendation.generate(
            recoveryScore: 45,
            recoveryStatus: .needsRest,
            sleepHours: 5.2,
            hrvValue: 32,
            sorenessLevel: .high
        )
        return viewModel
    }
}
#endif
