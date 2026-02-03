import Foundation

/// Service for intermittent fasting tracking
@MainActor
final class FastingService: ObservableObject {
    static let shared = FastingService()

    @Published private(set) var currentFast: FastingLog?
    @Published private(set) var fastingHistory: [FastingLog] = []
    @Published private(set) var stats: FastingStats?
    @Published private(set) var eatingWindowRecommendation: EatingWindowRecommendation?
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
