import Foundation

/// Service for supplement stack management
@MainActor
final class SupplementService: ObservableObject {
    static let shared = SupplementService()

    @Published private(set) var supplements: [Supplement] = []
    @Published private(set) var todaySchedule: [ScheduledSupplement] = []
    @Published private(set) var recentLogs: [SupplementLog] = []
    @Published private(set) var aiRecommendations: SupplementRecommendationResponse?
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingRecommendations = false
    @Published private(set) var error: Error?

    private let supabase = PTSupabaseClient.shared
    private let edgeFunctionUrl = "ai-supplement-recommendation"

    private init() {}

    // MARK: - Fetch Data

    func fetchSupplements() async {
        isLoading = true
        error = nil

        do {
            guard let patientId = try await getPatientId() else { return }

            let results: [Supplement] = try await supabase.client
                .from("supplements")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .eq("is_active", value: true)
                .order("name")
                .execute()
                .value

            self.supplements = results
            generateTodaySchedule()
        } catch {
            self.error = error
            DebugLogger.shared.error("SupplementService", "Failed to fetch supplements: \(error)")
        }

        isLoading = false
    }

    // MARK: - Add/Update/Delete

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

    // MARK: - Log Taking Supplement

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
            .from("supplement_logs")
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

    // MARK: - Schedule Generation

    private func generateTodaySchedule() {
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

// MARK: - Errors

enum SupplementServiceError: LocalizedError {
    case noPatientId
    case invalidResponse
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .noPatientId:
            return "Unable to identify patient. Please ensure you are logged in."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
