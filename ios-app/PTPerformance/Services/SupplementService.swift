import Foundation

/// Service for supplement stack management
@MainActor
final class SupplementService: ObservableObject {
    static let shared = SupplementService()

    @Published private(set) var supplements: [Supplement] = []
    @Published private(set) var todaySchedule: [ScheduledSupplement] = []
    @Published private(set) var recentLogs: [SupplementLog] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    private let supabase = PTSupabaseClient.shared

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
