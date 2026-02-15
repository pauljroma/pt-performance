import Foundation
import Combine

/// Service for managing fasting tracker operations (ACP-1001, ACP-1002, ACP-1004)
/// Handles CRUD operations for fasting_logs, protocol management, streak calculation, and analytics
@MainActor
final class FastingTrackerService: ObservableObject {
    static let shared = FastingTrackerService()

    // MARK: - Published Properties

    @Published private(set) var currentFast: FastingLog?
    @Published private(set) var fastingHistory: [FastingLog] = []
    @Published private(set) var stats: FastingStats?
    @Published private(set) var currentProtocol: FastingProtocolType = .sixteen8
    @Published private(set) var customFastingHours: Int = 16
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    // Streak tracking
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var bestStreak: Int = 0

    private let supabase = PTSupabaseClient.shared
    private var timerCancellable: AnyCancellable?

    // MARK: - Initialization

    private init() {
        // Load saved protocol preference
        loadProtocolPreference()
    }

    // MARK: - Protocol Management

    func setProtocol(_ protocol_: FastingProtocolType, customHours: Int? = nil) {
        currentProtocol = protocol_
        if let hours = customHours {
            customFastingHours = hours
        }
        saveProtocolPreference()
    }

    private func loadProtocolPreference() {
        if let savedProtocol = UserDefaults.standard.string(forKey: "fastingProtocol"),
           let protocol_ = FastingProtocolType(rawValue: savedProtocol) {
            currentProtocol = protocol_
        }
        customFastingHours = UserDefaults.standard.integer(forKey: "customFastingHours")
        if customFastingHours == 0 {
            customFastingHours = 16
        }
    }

    private func saveProtocolPreference() {
        UserDefaults.standard.set(currentProtocol.rawValue, forKey: "fastingProtocol")
        UserDefaults.standard.set(customFastingHours, forKey: "customFastingHours")
    }

    // MARK: - Fetch Data

    func fetchFastingData() async {
        isLoading = true
        error = nil

        do {
            guard let patientId = try await getPatientId() else {
                isLoading = false
                return
            }

            // Fetch history using DBFastingLog for safe decoding
            let dbLogs: [DBFastingLog] = try await supabase.client
                .from("fasting_logs")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .order("started_at", ascending: false)
                .limit(100)
                .execute()
                .value

            // Convert to app's FastingLog model
            let logs = dbLogs.map { $0.toFastingLog() }
            self.fastingHistory = logs
            self.currentFast = logs.first(where: { $0.isActive })

            // Calculate stats and streaks
            calculateStats()
            calculateStreaks()
        } catch {
            self.error = error
            DebugLogger.shared.error("FastingTrackerService", "Failed to fetch fasting data: \(error)")
        }

        isLoading = false
    }

    // MARK: - Start/End Fast

    func startFast(type: FastingType? = nil) async throws {
        DebugLogger.shared.info("FastingTrackerService", "Attempting to start fast...")

        // Check for existing active fast first
        if currentFast != nil {
            DebugLogger.shared.warning("FastingTrackerService", "Cannot start fast: a fast is already active")
            throw FastingError.fastAlreadyActive
        }

        let patientId: UUID
        do {
            guard let fetchedPatientId = try await getPatientId() else {
                DebugLogger.shared.error("FastingTrackerService", "Failed to start fast: no patient ID available")
                throw FastingError.noPatientId
            }
            patientId = fetchedPatientId
        } catch let error as FastingError {
            throw error
        } catch {
            DebugLogger.shared.error("FastingTrackerService", "Failed to get patient ID: \(error)")
            throw FastingError.unknown(error)
        }

        // Convert current protocol to FastingType
        let fastingType = type ?? convertProtocolToType(currentProtocol)
        let targetHours = type?.targetHours ?? (currentProtocol == .custom ? customFastingHours : currentProtocol.fastingHours)

        let now = Date()

        let fast = FastingLog(
            id: UUID(),
            patientId: patientId,
            protocolType: fastingType.rawValue,
            startedAt: now,
            endedAt: nil,
            plannedHours: targetHours,
            actualHours: nil,
            completed: false,
            notes: nil,
            createdAt: now,
            updatedAt: nil
        )

        DebugLogger.shared.info("FastingTrackerService", "Inserting fast record for patient: \(patientId), type: \(fastingType.displayName)")

        do {
            try await supabase.client
                .from("fasting_logs")
                .insert(fast)
                .execute()
        } catch {
            DebugLogger.shared.error("FastingTrackerService", "Database insert failed: \(error)")
            ErrorLogger.shared.logDatabaseError(error, table: "fasting_logs")
            throw FastingError.unknown(error)
        }

        currentFast = fast
        await fetchFastingData()

        HapticFeedback.success()
        DebugLogger.shared.success("FastingTrackerService", "Started \(fastingType.displayName) fast successfully")
    }

    func endFast(notes: String? = nil) async throws {
        guard let fast = currentFast else {
            DebugLogger.shared.warning("FastingTrackerService", "Cannot end fast: no active fast")
            throw FastingError.noActiveFast
        }

        let endTime = Date()
        let actualHours = endTime.timeIntervalSince(fast.startedAt) / 3600

        DebugLogger.shared.info("FastingTrackerService", "Ending fast: \(String(format: "%.1f", actualHours)) hours, target: \(fast.plannedHours) hours")

        // Note: The DB table does not have a "completed" column — the column is
        // derived/computed server-side. Sending "completed" caused a trigger
        // error referencing the removed "was_broken_early" column.
        struct FastingUpdate: Encodable {
            let ended_at: String
            let actual_hours: Double
            let notes: String?
        }

        let update = FastingUpdate(
            ended_at: ISO8601DateFormatter().string(from: endTime),
            actual_hours: actualHours,
            notes: notes
        )

        do {
            try await supabase.client
                .from("fasting_logs")
                .update(update)
                .eq("id", value: fast.id.uuidString)
                .execute()
        } catch {
            DebugLogger.shared.error("FastingTrackerService", "Database update failed when ending fast: \(error)")
            ErrorLogger.shared.logDatabaseError(error, table: "fasting_logs")
            throw FastingError.unknown(error)
        }

        currentFast = nil
        await fetchFastingData()

        HapticFeedback.success()
        DebugLogger.shared.success("FastingTrackerService", "Ended fast after \(String(format: "%.1f", actualHours)) hours")
    }

    func cancelFast() async throws {
        guard let fast = currentFast else {
            DebugLogger.shared.warning("FastingTrackerService", "Cannot cancel fast: no active fast")
            throw FastingError.noActiveFast
        }

        DebugLogger.shared.info("FastingTrackerService", "Cancelling fast: \(fast.id)")

        do {
            try await supabase.client
                .from("fasting_logs")
                .delete()
                .eq("id", value: fast.id.uuidString)
                .execute()
        } catch {
            DebugLogger.shared.error("FastingTrackerService", "Database delete failed when cancelling fast: \(error)")
            ErrorLogger.shared.logDatabaseError(error, table: "fasting_logs")
            throw FastingError.unknown(error)
        }

        currentFast = nil
        await fetchFastingData()

        DebugLogger.shared.success("FastingTrackerService", "Cancelled fast successfully")
    }

    // MARK: - Delete Fast

    func deleteFast(_ fast: FastingLog) async throws {
        DebugLogger.shared.info("FastingTrackerService", "Deleting fast: \(fast.id)")

        do {
            try await supabase.client
                .from("fasting_logs")
                .delete()
                .eq("id", value: fast.id.uuidString)
                .execute()
        } catch {
            DebugLogger.shared.error("FastingTrackerService", "Database delete failed: \(error)")
            ErrorLogger.shared.logDatabaseError(error, table: "fasting_logs")
            throw FastingError.unknown(error)
        }

        await fetchFastingData()
        DebugLogger.shared.success("FastingTrackerService", "Deleted fast successfully")
    }

    // MARK: - Stats Calculation

    private func calculateStats() {
        let completedFasts = fastingHistory.filter { $0.endTime != nil }
        let totalFasts = fastingHistory.count
        let completedCount = completedFasts.count

        let averageHours = completedFasts.isEmpty ? 0 :
            completedFasts.compactMap { $0.actualHours }.reduce(0, +) / Double(completedFasts.count)

        let longestFast = completedFasts.compactMap { $0.actualHours }.max() ?? 0

        stats = FastingStats(
            totalFasts: totalFasts,
            completedFasts: completedCount,
            averageHours: averageHours,
            longestFast: longestFast,
            currentStreak: currentStreak,
            bestStreak: bestStreak
        )
    }

    private func calculateStreaks() {
        let calendar = Calendar.current
        let completedFasts = fastingHistory.filter { $0.endTime != nil }
            .sorted { $0.startTime > $1.startTime }

        var streak = 0
        var maxStreak = 0
        var currentDate = Date()

        // Group fasts by day
        var fastsByDay: [Date: [FastingLog]] = [:]
        for fast in completedFasts {
            let day = calendar.startOfDay(for: fast.startTime)
            fastsByDay[day, default: []].append(fast)
        }

        // Calculate current streak (consecutive days from today/yesterday)
        while true {
            let dayStart = calendar.startOfDay(for: currentDate)
            if let fasts = fastsByDay[dayStart], !fasts.isEmpty {
                // Check if any fast reached at least 90% of goal
                let successfulFast = fasts.first { fast in
                    guard let actual = fast.actualHours else { return false }
                    return actual >= Double(fast.targetHours) * 0.9
                }
                if successfulFast != nil {
                    streak += 1
                    maxStreak = max(maxStreak, streak)
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                } else {
                    break
                }
            } else if calendar.isDateInToday(currentDate) {
                // Today doesn't count against streak if no fast yet
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }

        currentStreak = streak

        // Calculate best streak (scan all history)
        var tempStreak = 0
        var lastDate: Date?

        for fast in completedFasts {
            guard let actual = fast.actualHours, actual >= Double(fast.targetHours) * 0.9 else {
                continue
            }

            let fastDay = calendar.startOfDay(for: fast.startTime)

            if let last = lastDate {
                let daysDiff = calendar.dateComponents([.day], from: fastDay, to: last).day ?? 0
                if daysDiff <= 1 {
                    tempStreak += 1
                } else {
                    maxStreak = max(maxStreak, tempStreak)
                    tempStreak = 1
                }
            } else {
                tempStreak = 1
            }
            lastDate = fastDay
        }
        maxStreak = max(maxStreak, tempStreak)

        bestStreak = maxStreak
    }

    // MARK: - Analytics

    func weeklyStats() -> (completed: Int, average: Double, compliance: Double) {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let weeklyFasts = fastingHistory.filter { $0.startTime >= weekAgo }
        let completedWeekly = weeklyFasts.filter { $0.endTime != nil }
        let successfulWeekly = completedWeekly.filter { fast in
            guard let actual = fast.actualHours else { return false }
            return actual >= Double(fast.targetHours) * 0.9
        }

        let avgHours = completedWeekly.isEmpty ? 0 :
            completedWeekly.compactMap { $0.actualHours }.reduce(0, +) / Double(completedWeekly.count)

        let compliance = weeklyFasts.isEmpty ? 0 :
            Double(successfulWeekly.count) / Double(max(weeklyFasts.count, 7))

        return (successfulWeekly.count, avgHours, compliance)
    }

    func monthlyStats() -> (completed: Int, average: Double, compliance: Double, longest: Double) {
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()

        let monthlyFasts = fastingHistory.filter { $0.startTime >= monthAgo }
        let completedMonthly = monthlyFasts.filter { $0.endTime != nil }
        let successfulMonthly = completedMonthly.filter { fast in
            guard let actual = fast.actualHours else { return false }
            return actual >= Double(fast.targetHours) * 0.9
        }

        let avgHours = completedMonthly.isEmpty ? 0 :
            completedMonthly.compactMap { $0.actualHours }.reduce(0, +) / Double(completedMonthly.count)

        let compliance = monthlyFasts.isEmpty ? 0 :
            Double(successfulMonthly.count) / Double(max(monthlyFasts.count, 1))

        let longest = completedMonthly.compactMap { $0.actualHours }.max() ?? 0

        return (successfulMonthly.count, avgHours, compliance, longest)
    }

    func fastingLog(for date: Date) -> FastingLog? {
        let calendar = Calendar.current
        return fastingHistory.first { fast in
            calendar.isDate(fast.startTime, inSameDayAs: date)
        }
    }

    // MARK: - Helpers

    /// Demo patient ID for unauthenticated testing
    private let demoPatientId = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()

    private func getPatientId() async throws -> UUID? {
        // Check for authenticated user first
        if let userId = supabase.client.auth.currentUser?.id {
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

                if let patientId = patients.first?.id {
                    return patientId
                }

                DebugLogger.shared.warning("FastingTrackerService", "No patient record found for authenticated user: \(userId)")
            } catch {
                DebugLogger.shared.error("FastingTrackerService", "Failed to fetch patient ID: \(error)")
                throw error
            }
        }

        // Fallback to demo patient for unauthenticated users (demo mode)
        DebugLogger.shared.warning("FastingTrackerService", "No authenticated user, using demo patient")
        return demoPatientId
    }

    private func convertProtocolToType(_ protocol_: FastingProtocolType) -> FastingType {
        switch protocol_ {
        case .sixteen8: return .intermittent
        case .eighteen6: return .intermittent
        case .twenty4: return .intermittent
        case .omad: return .extended
        case .fiveTwo: return .extended
        case .custom: return .custom
        }
    }
}

// NOTE: FastingError is defined in FastingService.swift
