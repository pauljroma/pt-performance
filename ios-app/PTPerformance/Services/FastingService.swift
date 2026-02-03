import Foundation

// MARK: - Workout Recommendation Models

/// Workout modification based on fasting state
struct WorkoutModification: Codable, Identifiable {
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
    let modifications: [WorkoutModification]
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

/// Service for intermittent fasting tracking
@MainActor
final class FastingService: ObservableObject {
    static let shared = FastingService()

    @Published private(set) var currentFast: FastingLog?
    @Published private(set) var fastingHistory: [FastingLog] = []
    @Published private(set) var stats: FastingStats?
    @Published private(set) var eatingWindowRecommendation: EatingWindowRecommendation?
    @Published private(set) var workoutRecommendation: FastingWorkoutRecommendation?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    private let supabase = PTSupabaseClient.shared

    private init() {}

    // MARK: - Fetch Data

    func fetchFastingData() async {
        isLoading = true
        error = nil

        do {
            guard let patientId = try await getPatientId() else { return }

            // Fetch history
            let logs: [FastingLog] = try await supabase.client
                .from("fasting_logs")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .order("start_time", ascending: false)
                .limit(50)
                .execute()
                .value

            self.fastingHistory = logs
            self.currentFast = logs.first(where: { $0.isActive })

            // Calculate stats
            calculateStats()
        } catch {
            self.error = error
            DebugLogger.shared.error("FastingService", "Failed to fetch fasting data: \(error)")
        }

        isLoading = false
    }

    // MARK: - Start/End Fast

    func startFast(type: FastingType) async throws {
        guard let patientId = try await getPatientId() else {
            throw NSError(domain: "FastingService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No patient ID found"])
        }

        let fast = FastingLog(
            id: UUID(),
            patientId: patientId,
            fastingType: type,
            startTime: Date(),
            endTime: nil,
            targetHours: type.targetHours,
            actualHours: nil,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        try await supabase.client
            .from("fasting_logs")
            .insert(fast)
            .execute()

        currentFast = fast
        await fetchFastingData()
    }

    func endFast(breakfastFood: String? = nil, energyLevel: Int? = nil, notes: String? = nil) async throws {
        guard let fast = currentFast else { return }

        let endTime = Date()
        let actualHours = endTime.timeIntervalSince(fast.startTime) / 3600

        struct FastingUpdate: Encodable {
            let end_time: String
            let actual_hours: Double
            let breakfast_food: String?
            let energy_level: Int?
            let notes: String?
        }

        let update = FastingUpdate(
            end_time: ISO8601DateFormatter().string(from: endTime),
            actual_hours: actualHours,
            breakfast_food: breakfastFood,
            energy_level: energyLevel,
            notes: notes
        )

        try await supabase.client
            .from("fasting_logs")
            .update(update)
            .eq("id", value: fast.id.uuidString)
            .execute()

        currentFast = nil
        await fetchFastingData()
    }

    // MARK: - Recommendations

    func generateEatingWindowRecommendation(trainingTime: Date?) async {
        // AI-based eating window recommendation
        let suggestedStart: Date
        let suggestedEnd: Date
        let reason: String

        if let training = trainingTime {
            // Eating window around training
            suggestedStart = Calendar.current.date(byAdding: .hour, value: -2, to: training) ?? training
            suggestedEnd = Calendar.current.date(byAdding: .hour, value: 6, to: training) ?? training
            reason = "Optimized around your training at \(training.formatted(date: .omitted, time: .shortened))"
        } else {
            // Default 12-8 PM window
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 12
            suggestedStart = calendar.date(from: components) ?? Date()
            components.hour = 20
            suggestedEnd = calendar.date(from: components) ?? Date()
            reason = "Standard 8-hour eating window for your schedule"
        }

        eatingWindowRecommendation = EatingWindowRecommendation(
            id: UUID(),
            suggestedStart: suggestedStart,
            suggestedEnd: suggestedEnd,
            reason: reason,
            trainingTime: trainingTime
        )
    }

    // MARK: - Stats

    private func calculateStats() {
        let completedFasts = fastingHistory.filter { $0.endTime != nil }
        let totalFasts = fastingHistory.count
        let completedCount = completedFasts.count

        let averageHours = completedFasts.isEmpty ? 0 :
            completedFasts.compactMap { $0.actualHours }.reduce(0, +) / Double(completedFasts.count)

        let longestFast = completedFasts.compactMap { $0.actualHours }.max() ?? 0

        // Calculate streaks (consecutive days with completed fasts)
        var currentStreak = 0
        var bestStreak = 0
        var tempStreak = 0

        let calendar = Calendar.current
        let sortedByDate = completedFasts.sorted { $0.startTime > $1.startTime }
        var lastDate: Date?

        for fast in sortedByDate {
            if let last = lastDate {
                let daysDiff = calendar.dateComponents([.day], from: fast.startTime, to: last).day ?? 0
                if daysDiff <= 1 {
                    tempStreak += 1
                } else {
                    bestStreak = max(bestStreak, tempStreak)
                    tempStreak = 1
                }
            } else {
                tempStreak = 1
            }
            lastDate = fast.startTime
        }
        bestStreak = max(bestStreak, tempStreak)

        // Current streak is from today backwards
        if let mostRecent = sortedByDate.first,
           calendar.isDateInToday(mostRecent.startTime) || calendar.isDateInYesterday(mostRecent.startTime) {
            currentStreak = tempStreak
        }

        stats = FastingStats(
            totalFasts: totalFasts,
            completedFasts: completedCount,
            averageHours: averageHours,
            longestFast: longestFast,
            currentStreak: currentStreak,
            bestStreak: bestStreak
        )
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
        guard let fast = currentFast else {
            // Not fasting, generate a default "fed state" recommendation
            workoutRecommendation = createFedStateRecommendation()
            return
        }

        let fastingHours = Date().timeIntervalSince(fast.startTime) / 3600

        let fastingState = FastingStateResponse(
            isFasting: true,
            startedAt: ISO8601DateFormatter().string(from: fast.startTime),
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
        var modifications: [WorkoutModification] = []
        var performanceNotes: [String] = []
        var electrolyteRecs: [String] = []
        var workoutAllowed = true
        var workoutRecommended = true
        var alternativeSuggestion: String? = nil

        // Build warnings and modifications based on fasting duration
        if hours >= 12 && hours < 16 {
            warnings = ["Stay hydrated with electrolytes"]
            modifications = [
                WorkoutModification(
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
                WorkoutModification(
                    type: "volume",
                    originalValue: "100%",
                    modifiedValue: "70-80%",
                    rationale: "Extended fast reduces muscle protein synthesis response. Reduce sets by 20-30%."
                ),
                WorkoutModification(
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
                WorkoutModification(
                    type: "exercise_swap",
                    originalValue: "Intense workout",
                    modifiedValue: "Light activity",
                    rationale: "Extended fasting significantly impairs high-intensity performance. Recommend mobility, yoga, or walking only."
                ),
                WorkoutModification(
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
            electrolyteRecs = electrolyteRecs + ["If symptoms occur, break fast immediately with salted food"]
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
                WorkoutModification(
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
        guard let userId = supabase.client.auth.currentUser?.id else { return nil }

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

        return patients.first?.id
    }
}
