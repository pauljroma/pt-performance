import Foundation

// MARK: - Workout Recommendation Models

/// Workout modification based on fasting state (distinct from adaptive training WorkoutModification)
struct FastingWorkoutModification: Codable, Identifiable {
    var id: String { "\(type)_\(rationale.prefix(20))" }
    let type: String
    let originalValue: String
    let modifiedValue: String
    let rationale: String

    enum CodingKeys: String, CodingKey {
        case type
        case originalValue = "original_value"
        case modifiedValue = "modified_value"
        case rationale
    }
}

/// Nutrition timing recommendations
struct NutritionTiming: Codable {
    let recommendation: String
    let preWorkout: String?
    let intraWorkout: String?
    let postWorkout: String
    let timingNotes: String

    enum CodingKeys: String, CodingKey {
        case recommendation
        case preWorkout = "pre_workout"
        case intraWorkout = "intra_workout"
        case postWorkout = "post_workout"
        case timingNotes = "timing_notes"
    }
}

/// Fasting state from edge function
struct FastingStateResponse: Codable {
    let isFasting: Bool
    let startedAt: String?
    let fastingHours: Double
    let protocolType: String?
    let plannedHours: Double?

    enum CodingKeys: String, CodingKey {
        case isFasting = "is_fasting"
        case startedAt = "started_at"
        case fastingHours = "fasting_hours"
        case protocolType = "protocol_type"
        case plannedHours = "planned_hours"
    }
}

/// Complete workout recommendation based on fasting state
struct FastingWorkoutRecommendation: Codable, Identifiable {
    let optimizationId: String
    let fastingState: FastingStateResponse
    let workoutAllowed: Bool
    let workoutRecommended: Bool
    let modifications: [FastingWorkoutModification]
    let nutritionTiming: NutritionTiming
    let safetyWarnings: [String]
    let performanceNotes: [String]
    let electrolyteRecommendations: [String]
    let alternativeWorkoutSuggestion: String?
    let disclaimer: String

    var id: String { optimizationId }

    enum CodingKeys: String, CodingKey {
        case optimizationId = "optimization_id"
        case fastingState = "fasting_state"
        case workoutAllowed = "workout_allowed"
        case workoutRecommended = "workout_recommended"
        case modifications
        case nutritionTiming = "nutrition_timing"
        case safetyWarnings = "safety_warnings"
        case performanceNotes = "performance_notes"
        case electrolyteRecommendations = "electrolyte_recommendations"
        case alternativeWorkoutSuggestion = "alternative_workout_suggestion"
        case disclaimer
    }

    /// Computed intensity modifier (0.0 - 1.0) based on fasting hours
    var intensityModifier: Double {
        let hours = fastingState.fastingHours
        if hours < 12 {
            return 1.0
        } else if hours < 16 {
            return 0.95 // 5% reduction
        } else if hours < 20 {
            return 0.85 // 15% reduction
        } else if hours < 24 {
            return 0.75 // 25% reduction
        } else {
            return 0.65 // 35% reduction
        }
    }

    /// Recommended workout types based on fasting state
    var recommendedWorkoutTypes: [String] {
        let hours = fastingState.fastingHours
        if hours < 12 {
            return ["Strength Training", "HIIT", "Cardio", "All Types"]
        } else if hours < 16 {
            return ["Strength Training", "Moderate Cardio", "Zone 2 Cardio"]
        } else if hours < 20 {
            return ["Light Strength", "Zone 2 Cardio", "Walking", "Yoga"]
        } else {
            return ["Walking", "Yoga", "Mobility", "Stretching"]
        }
    }

    /// Whether this is considered an extended fast (16h+)
    var isExtendedFast: Bool {
        fastingState.fastingHours >= 16
    }

    /// Intensity percentage for display
    var intensityPercentage: Int {
        Int(intensityModifier * 100)
    }
}

// MARK: - Fasting Service

/// Service for intermittent fasting tracking and management
/// Connects UI to Supabase backend for fasting logs, protocols, streaks, and goals
@MainActor
final class FastingService: ObservableObject {
    static let shared = FastingService()

    // MARK: - Published Properties

    @Published private(set) var activeFast: FastingLog?
    @Published private(set) var recentFasts: [FastingLog] = []
    @Published private(set) var protocols: [FastingProtocol] = []
    @Published private(set) var currentStreak: FastingStreak?
    @Published private(set) var currentGoal: FastingGoal?
    @Published private(set) var weeklyStats: FastingWeeklyStats?
    @Published private(set) var eatingWindowRecommendation: EatingWindowRecommendation?
    @Published private(set) var workoutRecommendation: FastingWorkoutRecommendation?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared

    /// Demo patient ID for unauthenticated testing
    private let demoPatientId = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()

    private init() {}

    // MARK: - Fetch All Data

    /// Fetches all fasting-related data for the current patient
    func fetchAllData() async {
        isLoading = true
        error = nil

        do {
            guard let patientId = try await getPatientId() else {
                DebugLogger.shared.warning("FastingService", "No patient ID found")
                isLoading = false
                return
            }

            // Fetch data in parallel
            async let fetchedProtocols = fetchProtocols()
            async let fetchedHistory = fetchFastingHistory(patientId: patientId)
            async let fetchedStreak = fetchStreak(patientId: patientId)
            async let fetchedGoal = fetchGoal(patientId: patientId)

            // Await all results
            self.protocols = await fetchedProtocols
            self.recentFasts = await fetchedHistory
            self.currentStreak = await fetchedStreak
            self.currentGoal = await fetchedGoal

            // Set active fast if any
            self.activeFast = recentFasts.first(where: { $0.isActive })

            // Calculate weekly stats
            self.weeklyStats = calculateWeeklyStats()

            DebugLogger.shared.success("FastingService", "Fetched all fasting data")
        } catch {
            self.error = error
            DebugLogger.shared.error("FastingService", "Failed to fetch fasting data: \(error)")
        }

        isLoading = false
    }

    // MARK: - Fetch Protocols

    /// Fetches available fasting protocols
    func fetchProtocols() async -> [FastingProtocol] {
        do {
            let results: [FastingProtocol] = try await supabase.client
                .from("fasting_protocols")
                .select()
                .eq("is_active", value: true)
                .order("fasting_hours", ascending: true)
                .execute()
                .value

            return results
        } catch {
            DebugLogger.shared.error("FastingService", "Failed to fetch protocols: \(error)")
            return []
        }
    }

    // MARK: - Fetch Fasting History

    /// Fetches recent fasting logs for a patient
    private func fetchFastingHistory(patientId: UUID, limit: Int = 50) async -> [FastingLog] {
        do {
            let results: [FastingLog] = try await supabase.client
                .from("fasting_logs")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .order("started_at", ascending: false)
                .limit(limit)
                .execute()
                .value

            return results
        } catch {
            DebugLogger.shared.error("FastingService", "Failed to fetch fasting history: \(error)")
            return []
        }
    }

    /// Fetches fasting logs for a specific date range
    func fetchFastingHistory(days: Int = 30) async {
        isLoading = true
        error = nil

        do {
            guard let patientId = try await getPatientId() else { return }

            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

            let results: [FastingLog] = try await supabase.client
                .from("fasting_logs")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .gte("started_at", value: ISO8601DateFormatter().string(from: startDate))
                .order("started_at", ascending: false)
                .execute()
                .value

            self.recentFasts = results
            self.activeFast = results.first(where: { $0.isActive })
            self.weeklyStats = calculateWeeklyStats()
        } catch {
            self.error = error
            DebugLogger.shared.error("FastingService", "Failed to fetch fasting history: \(error)")
        }

        isLoading = false
    }

    // MARK: - Fetch Streak

    /// Fetches current fasting streak for a patient
    private func fetchStreak(patientId: UUID) async -> FastingStreak? {
        do {
            let results: [FastingStreak] = try await supabase.client
                .from("fasting_streaks")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .limit(1)
                .execute()
                .value

            return results.first
        } catch {
            DebugLogger.shared.error("FastingService", "Failed to fetch streak: \(error)")
            return nil
        }
    }

    /// Updates the streak after completing a fast
    func updateStreak() async {
        guard let patientId = try? await getPatientId() else { return }
        self.currentStreak = await fetchStreak(patientId: patientId)
    }

    // MARK: - Fetch Goal

    /// Fetches active fasting goal for a patient
    private func fetchGoal(patientId: UUID) async -> FastingGoal? {
        do {
            let results: [FastingGoal] = try await supabase.client
                .from("fasting_goals")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .eq("is_active", value: true)
                .limit(1)
                .execute()
                .value

            return results.first
        } catch {
            DebugLogger.shared.error("FastingService", "Failed to fetch goal: \(error)")
            return nil
        }
    }

    // MARK: - Start Fast

    /// Starts a new fasting session
    /// - Parameters:
    ///   - type: The type of fast to start
    ///   - targetHours: Custom target hours (uses type default if nil)
    /// - Returns: The created FastingLog
    @discardableResult
    func startFast(
        type: FastingType,
        targetHours: Int? = nil
    ) async throws -> FastingLog {
        DebugLogger.shared.info("FastingService", "Attempting to start \(type.displayName) fast...")

        // Check for existing active fast first
        if activeFast != nil {
            DebugLogger.shared.warning("FastingService", "Cannot start fast: a fast is already active")
            throw FastingError.fastAlreadyActive
        }

        let patientId: UUID
        do {
            guard let fetchedPatientId = try await getPatientId() else {
                DebugLogger.shared.error("FastingService", "Failed to start fast: no patient ID available")
                throw FastingError.noPatientId
            }
            patientId = fetchedPatientId
        } catch let error as FastingError {
            throw error
        } catch {
            DebugLogger.shared.error("FastingService", "Failed to get patient ID: \(error)")
            throw FastingError.unknown(error)
        }

        let now = Date()
        let hours = targetHours ?? type.targetHours

        let fast = FastingLog(
            id: UUID(),
            patientId: patientId,
            protocolType: type.rawValue,
            startedAt: now,
            endedAt: nil,
            plannedHours: hours,
            actualHours: nil,
            completed: false,
            notes: nil,
            createdAt: now,
            updatedAt: nil
        )

        DebugLogger.shared.info("FastingService", "Inserting fast record for patient: \(patientId), type: \(type.displayName)")

        do {
            try await supabase.client
                .from("fasting_logs")
                .insert(fast)
                .execute()
        } catch {
            DebugLogger.shared.error("FastingService", "Database insert failed: \(error)")
            ErrorLogger.shared.logDatabaseError(error, table: "fasting_logs")
            throw FastingError.unknown(error)
        }

        self.activeFast = fast
        DebugLogger.shared.success("FastingService", "Started \(type.displayName) fast successfully")

        // Refresh data
        await fetchFastingHistory()
        return fast
    }

    // MARK: - End Fast

    /// Ends the current active fast
    /// - Parameters:
    ///   - energyLevel: Optional energy level (1-10)
    ///   - notes: Optional notes about the fast (can include food used to break fast)
    /// - Returns: FastCompletionResult with completion details
    @discardableResult
    func endFast(
        energyLevel: Int? = nil,
        notes: String? = nil
    ) async throws -> FastCompletionResult {
        guard let fast = activeFast else {
            DebugLogger.shared.warning("FastingService", "Cannot end fast: no active fast")
            throw FastingError.noActiveFast
        }

        let endTime = Date()
        let actualHours = endTime.timeIntervalSince(fast.startedAt) / 3600
        let wasCompleted = actualHours >= Double(fast.targetHours)
        let wasBrokenEarly = !wasCompleted

        DebugLogger.shared.info("FastingService", "Ending fast: \(String(format: "%.1f", actualHours)) hours, target: \(fast.targetHours) hours")

        struct FastingUpdate: Encodable {
            let ended_at: String
            let actual_hours: Double
            let completed: Bool
            let notes: String?
        }

        let update = FastingUpdate(
            ended_at: ISO8601DateFormatter().string(from: endTime),
            actual_hours: actualHours,
            completed: wasCompleted,
            notes: notes
        )

        do {
            try await supabase.client
                .from("fasting_logs")
                .update(update)
                .eq("id", value: fast.id.uuidString)
                .execute()
        } catch {
            DebugLogger.shared.error("FastingService", "Database update failed when ending fast: \(error)")
            ErrorLogger.shared.logDatabaseError(error, table: "fasting_logs")
            throw FastingError.unknown(error)
        }

        self.activeFast = nil

        // Update streak
        await updateStreak()
        await fetchFastingHistory()

        // Check for personal best
        let isPersonalBest = actualHours > (currentStreak?.totalHoursFasted ?? 0) / max(1, Double(currentStreak?.totalFasts ?? 1))

        DebugLogger.shared.success("FastingService", "Ended fast: \(String(format: "%.1f", actualHours))h (target: \(fast.targetHours)h)")

        return FastCompletionResult(
            fastId: fast.id,
            wasCompleted: wasCompleted,
            actualHours: actualHours,
            targetHours: fast.targetHours,
            streakUpdated: true,
            newStreakCount: currentStreak?.currentStreak,
            isPersonalBest: isPersonalBest
        )
    }

    // MARK: - Break Fast Early

    /// Breaks the current fast early (before target is reached)
    /// - Parameters:
    ///   - reason: Optional reason for breaking early
    /// - Returns: FastCompletionResult with completion details
    @discardableResult
    func breakFastEarly(reason: String? = nil) async throws -> FastCompletionResult {
        let notes: String
        if let reason = reason {
            notes = "Ended early: \(reason)"
        } else {
            notes = "Ended early"
        }
        return try await endFast(notes: notes)
    }

    // MARK: - Set Goal

    /// Sets or updates the fasting goal for the current patient
    /// - Parameters:
    ///   - weeklyTarget: Number of fasts per week
    ///   - hoursPerFast: Target hours per fast
    ///   - preferredProtocol: Optional preferred fasting protocol
    ///   - targetStreak: Optional target streak to achieve
    func setGoal(
        weeklyTarget: Int,
        hoursPerFast: Int,
        preferredProtocol: FastingType? = nil,
        targetStreak: Int? = nil
    ) async throws {
        guard let patientId = try await getPatientId() else {
            throw FastingError.noPatientId
        }

        // Deactivate existing goals
        if let existingGoal = currentGoal {
            struct GoalDeactivate: Encodable {
                let is_active: Bool
                let updated_at: String
            }

            try await supabase.client
                .from("fasting_goals")
                .update(GoalDeactivate(is_active: false, updated_at: ISO8601DateFormatter().string(from: Date())))
                .eq("id", value: existingGoal.id.uuidString)
                .execute()
        }

        // Create new goal
        let goal = FastingGoal(
            id: UUID(),
            patientId: patientId,
            weeklyFastTarget: weeklyTarget,
            targetHoursPerFast: hoursPerFast,
            preferredProtocol: preferredProtocol,
            targetStreak: targetStreak,
            notes: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: nil
        )

        try await supabase.client
            .from("fasting_goals")
            .insert(goal)
            .execute()

        self.currentGoal = goal
        DebugLogger.shared.success("FastingService", "Set goal: \(weeklyTarget)x per week, \(hoursPerFast)h per fast")
    }

    // MARK: - Weekly Stats

    /// Calculates weekly fasting statistics from recent fasts
    private func calculateWeeklyStats() -> FastingWeeklyStats {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return .empty()
        }

        let thisWeekFasts = recentFasts.filter { fast in
            fast.startTime >= weekStart
        }

        // A fast is "completed" if it has ended (endTime is set)
        let completedFasts = thisWeekFasts.filter { $0.endTime != nil }
        let totalHours = completedFasts.compactMap { $0.actualHours }.reduce(0, +)
        let fastDurations = completedFasts.compactMap { $0.actualHours }

        // Calculate compliance rate
        let targetFasts = currentGoal?.weeklyFastTarget ?? 5
        let complianceRate = targetFasts > 0 ? min(Double(completedFasts.count) / Double(targetFasts), 1.0) : 0

        // Group fasts by day
        var fastsPerDay: [Date: Int] = [:]
        for fast in thisWeekFasts {
            let dayStart = calendar.startOfDay(for: fast.startTime)
            fastsPerDay[dayStart, default: 0] += 1
        }

        return FastingWeeklyStats(
            weekStartDate: weekStart,
            totalFasts: thisWeekFasts.count,
            completedFasts: completedFasts.count,
            totalHoursFasted: totalHours,
            averageFastDuration: fastDurations.isEmpty ? 0 : totalHours / Double(fastDurations.count),
            longestFast: fastDurations.max() ?? 0,
            shortestFast: fastDurations.min() ?? 0,
            complianceRate: complianceRate,
            fastsPerDay: fastsPerDay
        )
    }

    /// Returns the current weekly statistics
    func getWeeklyStats() -> FastingWeeklyStats {
        return weeklyStats ?? .empty()
    }

    // MARK: - Compliance Rate

    /// Calculates the compliance rate for a given period
    /// - Parameter days: Number of days to calculate compliance for
    /// - Returns: Compliance rate as a percentage (0-100)
    func getComplianceRate(days: Int = 7) -> Double {
        guard let goal = currentGoal else { return 0 }

        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        // Count fasts that were completed (have an end time)
        let periodFasts = recentFasts.filter { fast in
            fast.startTime >= startDate && fast.endTime != nil
        }

        let expectedFasts = (goal.weeklyFastTarget * days) / 7
        guard expectedFasts > 0 else { return 0 }

        return min(Double(periodFasts.count) / Double(expectedFasts) * 100, 100)
    }

    // MARK: - Eating Window Recommendations

    /// Generates eating window recommendation based on training schedule
    /// - Parameter trainingTime: Optional training time to optimize around
    func generateEatingWindowRecommendation(trainingTime: Date?) async {
        let suggestedStart: Date
        let suggestedEnd: Date
        let reason: String
        let confidence: Double

        if let training = trainingTime {
            // Eating window around training
            suggestedStart = Calendar.current.date(byAdding: .hour, value: -2, to: training) ?? training
            suggestedEnd = Calendar.current.date(byAdding: .hour, value: 6, to: training) ?? training
            reason = "Optimized around your training at \(training.formatted(date: .omitted, time: .shortened))"
            confidence = 0.85
        } else {
            // Default 12-8 PM window
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 12
            suggestedStart = calendar.date(from: components) ?? Date()
            components.hour = 20
            suggestedEnd = calendar.date(from: components) ?? Date()
            reason = "Standard 8-hour eating window for your schedule"
            confidence = 0.7
        }

        eatingWindowRecommendation = EatingWindowRecommendation(
            id: UUID(),
            suggestedStart: suggestedStart,
            suggestedEnd: suggestedEnd,
            reason: reason,
            trainingTime: trainingTime,
            confidence: confidence
        )
    }

    // MARK: - Current Phase

    /// Returns the current fasting phase based on elapsed hours
    func getCurrentPhase() -> FastingPhase {
        guard let fast = activeFast else { return .fed }
        return FastingPhase.fromHours(fast.elapsedHours)
    }

    // MARK: - Workout Recommendation

    /// Fetch workout recommendation based on current fasting state
    /// - Parameter workoutId: The workout ID to optimize for
    func getWorkoutRecommendation(workoutId: UUID) async {
        guard let patientId = try? await getPatientId() else {
            DebugLogger.shared.error("FastingService", "No patient ID found for workout recommendation")
            return
        }

        do {
            struct RequestBody: Encodable {
                let patient_id: String
                let workout_id: String
            }

            let body = RequestBody(
                patient_id: patientId.uuidString,
                workout_id: workoutId.uuidString
            )

            let response: FastingWorkoutRecommendation = try await supabase.client.functions
                .invoke(
                    "fasting-workout-optimizer",
                    options: .init(body: body)
                )

            self.workoutRecommendation = response
            DebugLogger.shared.info("FastingService", "Fetched workout recommendation: \(response.intensityPercentage)% intensity")
        } catch {
            self.error = error
            DebugLogger.shared.error("FastingService", "Failed to fetch workout recommendation: \(error)")
        }
    }

    /// Generate a local workout recommendation based on current fast (no edge function call)
    /// Use this when no specific workout is selected
    func generateLocalWorkoutRecommendation() async {
        guard let fast = activeFast else {
            // Not fasting, generate a default "fed state" recommendation
            workoutRecommendation = createFedStateRecommendation()
            return
        }

        let fastingHours = Date().timeIntervalSince(fast.startedAt) / 3600

        let fastingState = FastingStateResponse(
            isFasting: true,
            startedAt: ISO8601DateFormatter().string(from: fast.startedAt),
            fastingHours: fastingHours,
            protocolType: fast.fastingType.rawValue,
            plannedHours: Double(fast.targetHours)
        )

        workoutRecommendation = createLocalRecommendation(from: fastingState)
    }

    private func createFedStateRecommendation() -> FastingWorkoutRecommendation {
        let fastingState = FastingStateResponse(
            isFasting: false,
            startedAt: nil,
            fastingHours: 0,
            protocolType: nil,
            plannedHours: nil
        )

        let nutritionTiming = NutritionTiming(
            recommendation: "Normal fed state - follow standard pre/post workout nutrition.",
            preWorkout: "Light carbs + protein 1-2 hours before if desired",
            intraWorkout: "Water or electrolytes as needed",
            postWorkout: "Protein + carbs within 2 hours",
            timingNotes: "No special timing needed in fed state."
        )

        return FastingWorkoutRecommendation(
            optimizationId: UUID().uuidString,
            fastingState: fastingState,
            workoutAllowed: true,
            workoutRecommended: true,
            modifications: [],
            nutritionTiming: nutritionTiming,
            safetyWarnings: [],
            performanceNotes: ["You are in a fed state - train at full capacity"],
            electrolyteRecommendations: ["Standard hydration with water is sufficient"],
            alternativeWorkoutSuggestion: nil,
            disclaimer: "These recommendations are general guidelines. Listen to your body and adjust as needed."
        )
    }

    private func createLocalRecommendation(from fastingState: FastingStateResponse) -> FastingWorkoutRecommendation {
        let hours = fastingState.fastingHours

        var warnings: [String] = []
        var modifications: [FastingWorkoutModification] = []
        var performanceNotes: [String] = []
        var electrolyteRecs: [String] = []
        var workoutAllowed = true
        var workoutRecommended = true
        var alternativeSuggestion: String? = nil

        // Build warnings and modifications based on fasting duration
        if hours >= 12 && hours < 16 {
            warnings = ["Stay hydrated with electrolytes"]
            modifications = [
                FastingWorkoutModification(
                    type: "intensity",
                    originalValue: "100%",
                    modifiedValue: "95%",
                    rationale: "Light fasting state - consider slightly lower peak intensity"
                )
            ]
            performanceNotes = [
                "Expect 5-10% reduction in peak power output",
                "Glycogen stores moderately depleted"
            ]
            electrolyteRecs = [
                "Add electrolytes to water: sodium (500-1000mg), potassium, magnesium",
                "Consider LMNT, Nuun, or DIY electrolyte mix"
            ]
        } else if hours >= 16 && hours < 20 {
            warnings = [
                "Glycogen stores are depleted - expect reduced performance on later sets",
                "Consider BCAAs or EAAs intra-workout if strict fast is not required",
                "Break fast within 1-2 hours post-workout for optimal muscle protein synthesis"
            ]
            modifications = [
                FastingWorkoutModification(
                    type: "volume",
                    originalValue: "100%",
                    modifiedValue: "70-80%",
                    rationale: "Extended fast reduces muscle protein synthesis response. Reduce sets by 20-30%."
                ),
                FastingWorkoutModification(
                    type: "intensity",
                    originalValue: "100%",
                    modifiedValue: "85%",
                    rationale: "Keep intensity moderate. Quality over quantity when fasted."
                )
            ]
            performanceNotes = [
                "Expect 10-20% reduction in strength and power",
                "Fat oxidation significantly elevated - good for fat loss goals",
                "Glycogen substantially depleted - high-rep sets will suffer"
            ]
            electrolyteRecs = [
                "Electrolytes are essential: sodium (1000-2000mg), potassium (500-1000mg), magnesium (200-400mg)",
                "Use sugar-free electrolyte supplements",
                "Watch for signs of electrolyte imbalance"
            ]
        } else if hours >= 20 && hours < 24 {
            warnings = [
                "Extended fasting impairs strength and power output by 15-25%",
                "High cortisol during extended fast + intense exercise = muscle breakdown",
                "Consider breaking fast before any intense exercise",
                "Walking, stretching, and mobility work are ideal"
            ]
            modifications = [
                FastingWorkoutModification(
                    type: "exercise_swap",
                    originalValue: "Intense workout",
                    modifiedValue: "Light activity",
                    rationale: "Extended fasting significantly impairs high-intensity performance. Recommend mobility, yoga, or walking only."
                ),
                FastingWorkoutModification(
                    type: "duration",
                    originalValue: "As planned",
                    modifiedValue: "30 min max light activity",
                    rationale: "Minimize metabolic stress during extended fast to preserve lean mass."
                )
            ]
            performanceNotes = [
                "Expect 20-30%+ reduction in all performance metrics",
                "Cognitive function may be impaired - focus on safety",
                "Muscle protein breakdown elevated - not ideal for muscle building"
            ]
            electrolyteRecs += ["If symptoms occur, break fast immediately with salted food"]
            alternativeSuggestion = "Consider: 20-30 minute walk, gentle yoga/mobility, or break your fast 2-3 hours before training."
        } else if hours >= 24 {
            workoutAllowed = false
            workoutRecommended = false
            warnings = [
                "Extended fasting (24+ hours) + intense exercise is not recommended",
                "Risk of hypoglycemia, excessive muscle breakdown, and injury",
                "If continuing fast for health reasons, limit to gentle walking only",
                "Break fast with protein and carbs 2-3 hours before any planned intense workout"
            ]
            modifications = [
                FastingWorkoutModification(
                    type: "timing",
                    originalValue: "Train now",
                    modifiedValue: "Break fast first",
                    rationale: "Very extended fasting is not compatible with intense training. Break fast before workout or limit to very light walking."
                )
            ]
            performanceNotes = ["Training not recommended at this fasting duration"]
            alternativeSuggestion = "Break fast 2-3 hours before any planned intense workout, or limit activity to gentle walking."
        }

        let nutritionTiming = buildNutritionTiming(hours: hours)

        return FastingWorkoutRecommendation(
            optimizationId: UUID().uuidString,
            fastingState: fastingState,
            workoutAllowed: workoutAllowed,
            workoutRecommended: workoutRecommended,
            modifications: modifications,
            nutritionTiming: nutritionTiming,
            safetyWarnings: warnings,
            performanceNotes: performanceNotes,
            electrolyteRecommendations: electrolyteRecs,
            alternativeWorkoutSuggestion: alternativeSuggestion,
            disclaimer: "FASTING & EXERCISE DISCLAIMER: Individual responses to fasted exercise vary significantly. These recommendations are general guidelines. If you experience dizziness, extreme fatigue, nausea, or other concerning symptoms, stop exercise immediately and consume food."
        )
    }

    private func buildNutritionTiming(hours: Double) -> NutritionTiming {
        if hours < 12 {
            return NutritionTiming(
                recommendation: "Normal fed state - follow standard pre/post workout nutrition.",
                preWorkout: "Light carbs + protein 1-2 hours before if desired",
                intraWorkout: "Water or electrolytes as needed",
                postWorkout: "Protein + carbs within 2 hours",
                timingNotes: "No special timing needed in fed state."
            )
        } else if hours < 16 {
            return NutritionTiming(
                recommendation: "Light fasted state - consider breaking fast post-workout.",
                preWorkout: nil,
                intraWorkout: "Electrolytes (sodium, potassium, magnesium) strongly recommended",
                postWorkout: "Break fast with 30-40g protein + moderate carbs within 30 minutes",
                timingNotes: "Post-workout is an excellent time to break your fast - enhanced nutrient partitioning."
            )
        } else if hours < 20 {
            return NutritionTiming(
                recommendation: "Extended fasted state - plan your fast-breaking meal carefully.",
                preWorkout: "Consider BCAAs or EAAs (5-10g) if muscle preservation is priority",
                intraWorkout: "Essential: Electrolytes with sodium (1000mg+), potassium, magnesium",
                postWorkout: "Break fast immediately with protein shake (40g) + simple carbs, then full meal in 1-2 hours",
                timingNotes: "The post-workout window becomes crucial after extended fasting. Prioritize fast-digesting protein."
            )
        }

        return NutritionTiming(
            recommendation: "Very extended fast - strongly recommend breaking fast before intense exercise.",
            preWorkout: "Recommended: Break fast 2-3 hours before with light protein + carbs",
            intraWorkout: "If fasting continues: electrolytes essential, watch for hypoglycemia symptoms",
            postWorkout: "If continuing fast: very light activity only. Otherwise: full balanced meal.",
            timingNotes: "Extended fasting + intense exercise is not recommended. If you must train, eat first or limit to gentle movement."
        )
    }

    // MARK: - Helpers

    private func getPatientId() async throws -> UUID? {
        // Check for authenticated user first
        if let userId = supabase.client.auth.currentUser?.id {
            struct PatientRow: Decodable {
                let id: UUID
            }

            let patients: [PatientRow] = try await supabase.client
                .from("patients")
                .select("id")
                .eq("user_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            if let patientId = patients.first?.id {
                return patientId
            }
        }

        // Fallback to demo patient for unauthenticated users (demo mode)
        DebugLogger.shared.warning("FastingService", "No authenticated user, using demo patient")
        return demoPatientId
    }
}

// MARK: - Fasting Errors

enum FastingError: LocalizedError {
    case noPatientId
    case fastAlreadyActive
    case noActiveFast
    case invalidFastingType
    case networkError
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .noPatientId:
            return "No patient ID found. Please sign in."
        case .fastAlreadyActive:
            return "A fast is already active. End it before starting a new one."
        case .noActiveFast:
            return "No active fast to end."
        case .invalidFastingType:
            return "Invalid fasting type selected."
        case .networkError:
            return "Network error. Please check your connection."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
