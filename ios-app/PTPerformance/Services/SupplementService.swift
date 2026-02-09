import Foundation

/// Service for supplement stack management, logging, and compliance tracking
@MainActor
final class SupplementService: ObservableObject {
    static let shared = SupplementService()

    // MARK: - Published State

    /// Supplement catalog (master list)
    @Published private(set) var catalog: [CatalogSupplement] = []

    /// Pre-built supplement stacks
    @Published private(set) var stacks: [SupplementStack] = []

    /// User's active supplement routine
    @Published private(set) var routines: [SupplementRoutine] = []

    /// Today's scheduled doses
    @Published private(set) var todayDoses: [TodaySupplementDose] = []

    /// Recent supplement logs
    @Published private(set) var recentLogs: [SupplementLogEntry] = []

    /// Compliance data
    @Published private(set) var todayCompliance: SupplementCompliance?
    @Published private(set) var weeklyCompliance: WeeklySupplementCompliance?
    @Published private(set) var analytics: SupplementAnalytics?

    /// Legacy support - user's supplements (from original Supplement model)
    @Published private(set) var supplements: [Supplement] = []
    @Published private(set) var todaySchedule: [ScheduledSupplement] = []

    /// AI recommendations
    @Published private(set) var aiRecommendations: SupplementRecommendationResponse?

    /// Loading states
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingCatalog = false
    @Published private(set) var isLoadingRecommendations = false
    @Published private(set) var isSyncing = false
    @Published private(set) var error: Error?

    private let supabase = PTSupabaseClient.shared
    private let edgeFunctionUrl = "ai-supplement-recommendation"

    private init() {}

    // MARK: - Fetch Catalog & Stacks

    /// Fetches the supplement catalog from the database
    func fetchCatalog() async {
        isLoadingCatalog = true
        error = nil

        do {
            let results: [CatalogSupplement] = try await supabase.client
                .from("supplements")
                .select()
                .eq("is_verified", value: true)
                .order("name")
                .execute()
                .value

            self.catalog = results
            DebugLogger.shared.info("SupplementService", "Fetched \(results.count) catalog supplements")
        } catch {
            // Fallback to demo data
            self.catalog = CatalogSupplement.demoSupplements
            DebugLogger.shared.warning("SupplementService", "Using demo catalog: \(error.localizedDescription)")
        }

        isLoadingCatalog = false
    }

    /// Fetches pre-built supplement stacks
    func fetchStacks() async {
        do {
            let results: [SupplementStack] = try await supabase.client
                .from("supplement_stacks")
                .select("*, items:supplement_stack_items(*)")
                .order("name")
                .execute()
                .value

            self.stacks = results
            DebugLogger.shared.info("SupplementService", "Fetched \(results.count) supplement stacks")
        } catch {
            // Fallback to demo stacks
            self.stacks = SupplementStack.demoStacks
            DebugLogger.shared.warning("SupplementService", "Using demo stacks: \(error.localizedDescription)")
        }
    }

    // MARK: - User Routine Management

    /// Fetches the user's supplement routine
    func fetchRoutines() async {
        isLoading = true
        error = nil

        do {
            guard let patientId = try await getPatientId() else {
                // Use demo data for unauthenticated users
                self.routines = SupplementRoutine.demoRoutines
                generateTodayDoses()
                isLoading = false
                return
            }

            // Note: Only select columns that exist in the supplements table
            // The 'brand' column may not exist in all database versions
            let results: [SupplementRoutine] = try await supabase.client
                .from("patient_supplement_routines")
                .select("*, supplement:supplements(id, name, category)")
                .eq("patient_id", value: patientId.uuidString)
                .eq("is_active", value: true)
                .order("timing")
                .execute()
                .value

            self.routines = results

            // Generate today's schedule
            generateTodayDoses()

            // Fetch today's logs to mark taken doses
            await fetchTodayLogs()

            DebugLogger.shared.info("SupplementService", "Fetched \(results.count) active routines")
        } catch {
            self.error = error
            // Fallback to demo routines
            self.routines = SupplementRoutine.demoRoutines
            generateTodayDoses()
            DebugLogger.shared.warning("SupplementService", "Using demo routines: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Adds a supplement to the user's routine
    func addToRoutine(
        supplementId: UUID,
        supplementName: String,
        brand: String?,
        category: SupplementCatalogCategory,
        dosage: String,
        timing: SupplementTiming,
        frequency: SupplementFrequency = .daily,
        withFood: Bool = false,
        notes: String? = nil
    ) async throws {
        guard let patientId = try await getPatientId() else {
            throw SupplementServiceError.noPatientId
        }

        // Database schema (patient_supplement_routines):
        // dose (NUMERIC), dose_unit (TEXT), timing (supplement_timing_type), days_of_week (INTEGER[])
        // is_active, start_date, end_date, notes
        // NO: dosage, frequency, with_food columns
        struct RoutineInsert: Encodable {
            let id: UUID
            let patient_id: UUID
            let supplement_id: UUID
            let dose: Double
            let dose_unit: String
            let timing: String
            let days_of_week: [Int]?
            let notes: String?
            let is_active: Bool
            let start_date: String
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Parse dosage string to extract number and unit (e.g., "500mg" -> 500, "mg")
        let (doseValue, doseUnit) = parseDosage(dosage)

        // Map frequency to days_of_week array
        let daysOfWeek: [Int]? = frequency == .daily ? [0, 1, 2, 3, 4, 5, 6] : nil

        let insert = RoutineInsert(
            id: UUID(),
            patient_id: patientId,
            supplement_id: supplementId,
            dose: doseValue,
            dose_unit: doseUnit,
            timing: timing.rawValue,
            days_of_week: daysOfWeek,
            notes: notes,
            is_active: true,
            start_date: dateFormatter.string(from: Date())
        )

        try await supabase.client
            .from("patient_supplement_routines")
            .insert(insert)
            .execute()

        DebugLogger.shared.success("SupplementService", "Added \(supplementName) to routine")

        await fetchRoutines()
    }

    /// Adds a stack to the user's routine
    func addStackToRoutine(_ stack: SupplementStack) async throws {
        for item in stack.items where !item.isOptional {
            try await addToRoutine(
                supplementId: item.supplementId,
                supplementName: item.supplementName,
                brand: nil,
                category: .other,
                dosage: item.dosage,
                timing: item.timing,
                notes: item.notes
            )
        }

        DebugLogger.shared.success("SupplementService", "Added stack '\(stack.name)' to routine")
    }

    /// Removes a supplement from the user's routine (soft delete)
    func removeFromRoutine(_ routineId: UUID) async throws {
        struct RoutineDeactivate: Encodable {
            let is_active: Bool
            let end_date: String
        }

        let update = RoutineDeactivate(
            is_active: false,
            end_date: ISO8601DateFormatter().string(from: Date())
        )

        try await supabase.client
            .from("patient_supplement_routines")
            .update(update)
            .eq("id", value: routineId.uuidString)
            .execute()

        DebugLogger.shared.info("SupplementService", "Removed routine \(routineId)")

        await fetchRoutines()
    }

    /// Updates a routine item
    /// Database schema: dose, dose_unit, timing, days_of_week, notes, is_active, start_date, end_date
    func updateRoutine(
        _ routineId: UUID,
        dosage: String? = nil,
        timing: SupplementTiming? = nil,
        frequency: SupplementFrequency? = nil,
        withFood: Bool? = nil,
        notes: String? = nil
    ) async throws {
        // Database schema (patient_supplement_routines):
        // dose, dose_unit, timing, days_of_week, is_active, start_date, end_date, notes
        // NO: dosage, frequency, with_food columns
        struct RoutineUpdate: Encodable {
            var dose: Double?
            var dose_unit: String?
            var timing: String?
            var days_of_week: [Int]?
            var notes: String?
        }

        // Parse dosage if provided
        var doseValue: Double?
        var doseUnit: String?
        if let dosage = dosage {
            let parsed = parseDosage(dosage)
            doseValue = parsed.0
            doseUnit = parsed.1
        }

        // Map frequency to days_of_week if provided
        var daysOfWeek: [Int]?
        if let frequency = frequency {
            switch frequency {
            case .daily:
                daysOfWeek = [0, 1, 2, 3, 4, 5, 6]
            case .weekly:
                daysOfWeek = [0] // Sunday only
            default:
                daysOfWeek = nil
            }
        }

        let update = RoutineUpdate(
            dose: doseValue,
            dose_unit: doseUnit,
            timing: timing?.rawValue,
            days_of_week: daysOfWeek,
            notes: notes
        )

        // Only update if at least one field is non-nil
        guard dosage != nil || timing != nil || frequency != nil || notes != nil else { return }

        try await supabase.client
            .from("patient_supplement_routines")
            .update(update)
            .eq("id", value: routineId.uuidString)
            .execute()

        await fetchRoutines()
    }

    // MARK: - Logging Supplements

    /// Logs that a supplement was taken
    func logSupplement(
        dose: TodaySupplementDose,
        perceivedEffect: PerceivedEffect? = nil,
        sideEffects: [String]? = nil,
        notes: String? = nil
    ) async throws {
        guard let patientId = try await getPatientId() else {
            throw SupplementServiceError.noPatientId
        }

        // Database schema (patient_supplement_logs):
        // id, patient_id, supplement_id, dose_amount, dose_unit, taken_at, timing, with_food, notes
        // NO: supplement_name, dosage, routine_id, skipped, perceived_effect, side_effects
        struct LogInsert: Encodable {
            let id: UUID
            let patient_id: UUID
            let supplement_id: UUID
            let dose_amount: Double
            let dose_unit: String
            let taken_at: String
            let timing: String
            let with_food: Bool
            let notes: String?
        }

        let logId = UUID()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]

        // Parse dosage to get dose_amount and dose_unit
        let (doseAmount, doseUnit) = parseDosage(dose.dosage)

        // Combine notes with perceived effect and side effects if present
        var combinedNotes = notes ?? ""
        if let effect = perceivedEffect {
            combinedNotes += combinedNotes.isEmpty ? "Effect: \(effect.rawValue)" : " | Effect: \(effect.rawValue)"
        }
        if let effects = sideEffects, !effects.isEmpty {
            combinedNotes += combinedNotes.isEmpty ? "Side effects: \(effects.joined(separator: ", "))" : " | Side effects: \(effects.joined(separator: ", "))"
        }

        let insert = LogInsert(
            id: logId,
            patient_id: patientId,
            supplement_id: dose.supplementId,
            dose_amount: doseAmount,
            dose_unit: doseUnit,
            taken_at: dateFormatter.string(from: Date()),
            timing: dose.timing.rawValue,
            with_food: dose.withFood,
            notes: combinedNotes.isEmpty ? nil : combinedNotes
        )

        try await supabase.client
            .from("patient_supplement_logs")
            .insert(insert)
            .execute()

        // Update local state
        if let index = todayDoses.firstIndex(where: { $0.id == dose.id }) {
            todayDoses[index].isTaken = true
            todayDoses[index].takenAt = Date()
            todayDoses[index].logId = logId
        }

        DebugLogger.shared.success("SupplementService", "Logged \(dose.supplementName)")

        // Recalculate compliance
        await calculateTodayCompliance()
    }

    /// Marks a supplement as skipped
    /// Note: Database schema doesn't have a "skipped" field, so we log with dose_amount = 0
    /// and include skip reason in notes
    func skipSupplement(dose: TodaySupplementDose, reason: String?) async throws {
        guard let patientId = try await getPatientId() else {
            throw SupplementServiceError.noPatientId
        }

        // Database schema (patient_supplement_logs):
        // id, patient_id, supplement_id, dose_amount, dose_unit, taken_at, timing, with_food, notes
        // NO: skipped, skip_reason columns - use notes field and dose_amount = 0 to indicate skip
        struct LogInsert: Encodable {
            let id: UUID
            let patient_id: UUID
            let supplement_id: UUID
            let dose_amount: Double
            let dose_unit: String
            let taken_at: String
            let timing: String
            let with_food: Bool
            let notes: String?
        }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]

        // Parse dosage to get unit (amount will be 0 for skipped)
        let (_, doseUnit) = parseDosage(dose.dosage)

        // Use notes to indicate skip and reason
        let skipNote: String
        if let reason = reason {
            skipNote = "[SKIPPED] \(reason)"
        } else {
            skipNote = "[SKIPPED]"
        }

        let insert = LogInsert(
            id: UUID(),
            patient_id: patientId,
            supplement_id: dose.supplementId,
            dose_amount: 0, // 0 indicates skipped
            dose_unit: doseUnit,
            taken_at: dateFormatter.string(from: Date()),
            timing: dose.timing.rawValue,
            with_food: dose.withFood,
            notes: skipNote
        )

        try await supabase.client
            .from("patient_supplement_logs")
            .insert(insert)
            .execute()

        // Update local state
        if let index = todayDoses.firstIndex(where: { $0.id == dose.id }) {
            todayDoses[index].isTaken = true // Mark as handled
            todayDoses[index].takenAt = Date()
        }

        DebugLogger.shared.info("SupplementService", "Skipped \(dose.supplementName)")

        await calculateTodayCompliance()
    }

    /// Undoes a logged supplement
    func undoLog(_ logId: UUID) async throws {
        try await supabase.client
            .from("patient_supplement_logs")
            .delete()
            .eq("id", value: logId.uuidString)
            .execute()

        // Update local state
        if let index = todayDoses.firstIndex(where: { $0.logId == logId }) {
            todayDoses[index].isTaken = false
            todayDoses[index].takenAt = nil
            todayDoses[index].logId = nil
        }

        DebugLogger.shared.info("SupplementService", "Undid log \(logId)")

        await calculateTodayCompliance()
    }

    // MARK: - Fetch Logs

    /// Fetches today's logs to mark taken supplements
    private func fetchTodayLogs() async {
        do {
            guard let patientId = try await getPatientId() else { return }

            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                return
            }

            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime]

            let logs: [SupplementLogEntry] = try await supabase.client
                .from("patient_supplement_logs")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .gte("taken_at", value: dateFormatter.string(from: startOfDay))
                .lt("taken_at", value: dateFormatter.string(from: endOfDay))
                .execute()
                .value

            // Mark doses as taken based on logs
            for log in logs where !log.skipped {
                if let index = todayDoses.firstIndex(where: {
                    $0.supplementId == log.supplementId && $0.timing == log.timing && !$0.isTaken
                }) {
                    todayDoses[index].isTaken = true
                    todayDoses[index].takenAt = log.takenAt
                    todayDoses[index].logId = log.id
                }
            }

            self.recentLogs = logs
        } catch {
            DebugLogger.shared.warning("SupplementService", "Failed to fetch today's logs: \(error)")
        }
    }

    /// Fetches log history for a date range
    func fetchLogHistory(days: Int = 30) async -> [SupplementLogEntry] {
        do {
            guard let patientId = try await getPatientId() else { return [] }

            guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else {
                return []
            }
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime]

            let logs: [SupplementLogEntry] = try await supabase.client
                .from("patient_supplement_logs")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .gte("taken_at", value: dateFormatter.string(from: startDate))
                .order("taken_at", ascending: false)
                .execute()
                .value

            return logs
        } catch {
            DebugLogger.shared.error("SupplementService", "Failed to fetch log history: \(error)")
            return []
        }
    }

    // MARK: - Compliance Analytics

    /// Calculates today's compliance metrics
    func calculateTodayCompliance() async {
        let taken = todayDoses.filter { $0.isTaken && $0.logId != nil }.count
        let planned = todayDoses.count
        let skipped = recentLogs.filter { $0.skipped }.count

        let rate = planned > 0 ? Double(taken) / Double(planned) : 0

        // Calculate streak (simplified - would need historical data for accurate streak)
        let streak = taken == planned ? 1 : 0

        todayCompliance = SupplementCompliance(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            plannedCount: planned,
            takenCount: taken,
            skippedCount: skipped,
            complianceRate: rate,
            streakDays: streak
        )
    }

    /// Fetches weekly compliance data
    func fetchWeeklyCompliance() async {
        do {
            guard let patientId = try await getPatientId() else { return }

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            guard let weekStart = calendar.date(byAdding: .day, value: -6, to: today) else { return }

            // Fetch daily compliance records for the week
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            let compliance: [SupplementCompliance] = try await supabase.client
                .from("supplement_compliance")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .gte("date", value: dateFormatter.string(from: weekStart))
                .order("date", ascending: true)
                .execute()
                .value

            weeklyCompliance = WeeklySupplementCompliance(
                weekStartDate: weekStart,
                dailyCompliance: compliance
            )
        } catch {
            DebugLogger.shared.warning("SupplementService", "Failed to fetch weekly compliance: \(error)")
        }
    }

    /// Fetches overall supplement analytics
    func fetchAnalytics() async {
        do {
            guard let patientId = try await getPatientId() else { return }

            let response: SupplementAnalytics = try await supabase.client
                .from("supplement_analytics")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .single()
                .execute()
                .value

            self.analytics = response
        } catch {
            // Generate basic analytics from local data
            let weeklyRate = todayCompliance?.complianceRate ?? 0

            self.analytics = SupplementAnalytics(
                totalSupplements: routines.count,
                activeRoutines: routines.filter { $0.isActive }.count,
                weeklyComplianceRate: weeklyRate,
                monthlyComplianceRate: weeklyRate,
                currentStreak: todayCompliance?.streakDays ?? 0,
                longestStreak: 0,
                topCategories: [],
                mostConsistent: [],
                leastConsistent: []
            )
        }
    }

    // MARK: - Today's Schedule Generation

    /// Generates today's scheduled doses from routines
    private func generateTodayDoses() {
        var doses: [TodaySupplementDose] = []
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        // Check if it's a training day (simplified - could integrate with workout schedule)
        let isTrainingDay = true // Default to true for now

        for routine in routines where routine.isActive {
            // Check frequency
            let shouldSchedule: Bool
            switch routine.frequency {
            case .daily, .twiceDaily, .threeTimesDaily:
                shouldSchedule = true
            case .trainingDaysOnly:
                shouldSchedule = isTrainingDay
            case .weekly:
                // Check if it's the right day of week (assume Sunday)
                shouldSchedule = calendar.component(.weekday, from: now) == 1
            case .asNeeded:
                shouldSchedule = false // User manually logs
            }

            guard shouldSchedule else { continue }

            // Determine number of doses based on frequency
            let timings: [SupplementTiming]
            switch routine.frequency {
            case .twiceDaily:
                timings = [.morning, .evening]
            case .threeTimesDaily:
                timings = [.morning, .withMeal, .evening]
            default:
                timings = [routine.timing]
            }

            for timing in timings {
                var scheduledComponents = calendar.dateComponents([.year, .month, .day], from: today)
                scheduledComponents.hour = timing.approximateHour
                scheduledComponents.minute = 0
                let scheduledTime = calendar.date(from: scheduledComponents) ?? now

                let dose = TodaySupplementDose(
                    id: UUID(),
                    routineId: routine.id,
                    supplementId: routine.supplementId,
                    supplementName: routine.supplement?.name ?? "Unknown",
                    brand: routine.supplement?.brand,
                    category: routine.supplement?.category ?? .other,
                    dosage: routine.dosage,
                    timing: timing,
                    scheduledTime: scheduledTime,
                    withFood: routine.withFood,
                    isTaken: false,
                    takenAt: nil,
                    logId: nil
                )

                doses.append(dose)
            }
        }

        // Sort by scheduled time
        todayDoses = doses.sorted { $0.scheduledTime < $1.scheduledTime }
    }

    // MARK: - Legacy Support (Original Supplement model)

    /// Fetches user's supplements (legacy model)
    func fetchSupplements() async {
        isLoading = true
        error = nil

        do {
            guard let patientId = try await getPatientId() else {
                isLoading = false
                return
            }

            let results: [Supplement] = try await supabase.client
                .from("supplements")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .eq("is_active", value: true)
                .order("name")
                .execute()
                .value

            self.supplements = results
            generateLegacyTodaySchedule()
        } catch {
            self.error = error
            DebugLogger.shared.error("SupplementService", "Failed to fetch supplements: \(error)")
        }

        isLoading = false
    }

    func addSupplement(_ supplement: Supplement) async throws {
        try await supabase.client
            .from("supplements")
            .insert(supplement)
            .execute()

        await fetchSupplements()
    }

    func updateSupplement(_ supplement: Supplement) async throws {
        try await supabase.client
            .from("supplements")
            .update(supplement)
            .eq("id", value: supplement.id.uuidString)
            .execute()

        await fetchSupplements()
    }

    func deleteSupplement(_ id: UUID) async throws {
        try await supabase.client
            .from("supplements")
            .update(["is_active": false])
            .eq("id", value: id.uuidString)
            .execute()

        await fetchSupplements()
    }

    func logSupplementTaken(_ supplement: Supplement, notes: String? = nil) async throws {
        guard let patientId = try await getPatientId() else { return }

        let log = SupplementLog(
            id: UUID(),
            supplementId: supplement.id,
            patientId: patientId,
            takenAt: Date(),
            dosage: supplement.dosage,
            notes: notes
        )

        try await supabase.client
            .from("patient_supplement_logs")
            .insert(log)
            .execute()

        // Update today's schedule
        if let index = todaySchedule.firstIndex(where: { $0.supplement.id == supplement.id && !$0.taken }) {
            var updated = todaySchedule[index]
            updated = ScheduledSupplement(
                id: updated.id,
                supplement: updated.supplement,
                scheduledTime: updated.scheduledTime,
                taken: true,
                takenAt: Date()
            )
            todaySchedule[index] = updated
        }
    }

    private func generateLegacyTodaySchedule() {
        var schedule: [ScheduledSupplement] = []
        let now = Date()

        for supplement in supplements {
            for timeOfDay in supplement.timeOfDay {
                let scheduledTime = timeForTimeOfDay(timeOfDay, on: now)

                let scheduled = ScheduledSupplement(
                    id: UUID(),
                    supplement: supplement,
                    scheduledTime: scheduledTime,
                    taken: false,
                    takenAt: nil
                )
                schedule.append(scheduled)
            }
        }

        todaySchedule = schedule.sorted { $0.scheduledTime < $1.scheduledTime }
    }

    private func timeForTimeOfDay(_ timeOfDay: TimeOfDay, on date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)

        switch timeOfDay {
        case .morning:
            components.hour = 7
        case .afternoon:
            components.hour = 12
        case .evening:
            components.hour = 18
        case .night:
            components.hour = 22
        case .beforeBed:
            components.hour = 21
        case .preWorkout:
            components.hour = 6
        case .postWorkout:
            components.hour = 8
        case .withMeals:
            components.hour = 12
        }

        return calendar.date(from: components) ?? date
    }

    // MARK: - AI Recommendations

    /// Fetches AI-powered supplement recommendations based on patient data
    func getAIRecommendations() async {
        isLoadingRecommendations = true
        error = nil

        do {
            guard let patientId = try await getPatientId() else {
                error = SupplementServiceError.noPatientId
                isLoadingRecommendations = false
                return
            }

            let requestBody: [String: Any] = ["patient_id": patientId.uuidString]
            let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

            let response: SupplementRecommendationResponse = try await supabase.client.functions
                .invoke(
                    edgeFunctionUrl,
                    options: .init(body: bodyData)
                )

            self.aiRecommendations = response
            DebugLogger.shared.info("SupplementService", "Fetched \(response.recommendations.count) AI recommendations (cached: \(response.cached))")
        } catch {
            self.error = error
            DebugLogger.shared.error("SupplementService", "Failed to fetch AI recommendations: \(error)")
        }

        isLoadingRecommendations = false
    }

    /// Clears cached recommendations to force a fresh AI analysis
    func refreshAIRecommendations() async {
        aiRecommendations = nil
        await getAIRecommendations()
    }

    /// Adds a recommended supplement to the user's stack
    func addRecommendedSupplement(_ recommendation: AISupplementRecommendation) async throws {
        guard let patientId = try await getPatientId() else {
            throw SupplementServiceError.noPatientId
        }

        // Map AI recommendation category to SupplementCategory
        let category = mapCategoryFromString(recommendation.category)

        // Parse timing from recommendation
        let timeOfDay = parseTimingFromString(recommendation.timing)

        let supplement = Supplement(
            id: UUID(),
            patientId: patientId,
            name: recommendation.name,
            brand: recommendation.brand,
            category: category,
            dosage: recommendation.dosage,
            frequency: .daily,
            timeOfDay: timeOfDay,
            withFood: recommendation.timing.lowercased().contains("meal") || recommendation.timing.lowercased().contains("food"),
            notes: recommendation.rationale,
            momentousProductId: recommendation.purchaseUrl != nil ? recommendation.name.lowercased().replacingOccurrences(of: " ", with: "_") : nil,
            isActive: true,
            createdAt: Date()
        )

        try await addSupplement(supplement)
    }

    private func mapCategoryFromString(_ string: String) -> SupplementCategory {
        switch string.lowercased() {
        case "protein": return .protein
        case "creatine", "performance": return .creatine
        case "vitamins": return .vitamins
        case "minerals": return .minerals
        case "omega3", "essential_fatty_acids": return .omega3
        case "preworkout": return .preworkout
        case "recovery": return .recovery
        case "sleep": return .sleep
        case "adaptogens", "cognitive", "hormonal_support": return .adaptogens
        default: return .other
        }
    }

    private func parseTimingFromString(_ timing: String) -> [TimeOfDay] {
        let lower = timing.lowercased()
        var times: [TimeOfDay] = []

        if lower.contains("morning") || lower.contains("am") {
            times.append(.morning)
        }
        if lower.contains("pre-workout") || lower.contains("before exercise") {
            times.append(.preWorkout)
        }
        if lower.contains("post-workout") || lower.contains("after exercise") {
            times.append(.postWorkout)
        }
        if lower.contains("evening") || lower.contains("bed") || lower.contains("night") {
            times.append(.beforeBed)
        }
        if lower.contains("meal") || lower.contains("food") {
            times.append(.withMeals)
        }

        // Default to morning if no timing parsed
        if times.isEmpty {
            times.append(.morning)
        }

        return times
    }

    // MARK: - Helpers

    /// Parses a dosage string like "500mg" into (500.0, "mg")
    private func parseDosage(_ dosage: String) -> (Double, String) {
        // Extract numeric part and unit from strings like "500mg", "1000 mg", "2g", "5000 IU"
        let trimmed = dosage.trimmingCharacters(in: .whitespaces)

        var numberPart = ""
        var unitPart = ""
        var foundNumber = false

        for char in trimmed {
            if char.isNumber || char == "." {
                numberPart.append(char)
                foundNumber = true
            } else if foundNumber {
                unitPart.append(char)
            }
        }

        let value = Double(numberPart) ?? 0
        let unit = unitPart.trimmingCharacters(in: .whitespaces)

        return (value, unit.isEmpty ? "mg" : unit)
    }

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
        DebugLogger.shared.warning("SupplementService", "No authenticated user, using demo patient")
        return UUID(uuidString: "00000000-0000-0000-0000-000000000001")
    }
}

// MARK: - Errors

enum SupplementServiceError: LocalizedError {
    case noPatientId
    case invalidResponse
    case networkError(Error)
    case routineNotFound
    case supplementNotFound

    var errorDescription: String? {
        switch self {
        case .noPatientId:
            return "Unable to identify patient. Please ensure you are logged in."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .routineNotFound:
            return "The supplement routine was not found."
        case .supplementNotFound:
            return "The supplement was not found in the catalog."
        }
    }
}
