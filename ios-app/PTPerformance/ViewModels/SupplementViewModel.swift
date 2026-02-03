import SwiftUI

@MainActor
final class SupplementViewModel: ObservableObject {
    @Published var supplements: [Supplement] = []
    @Published var todaySchedule: [ScheduledSupplement] = []
    @Published var isLoading = false
    @Published var error: String?

    // Add supplement form
    @Published var showingAddSheet = false
    @Published var newName: String = ""
    @Published var newBrand: String = ""
    @Published var newCategory: SupplementCategory = .vitamins
    @Published var newDosage: String = ""
    @Published var newFrequency: SupplementFrequency = .daily
    @Published var newTimeOfDay: Set<TimeOfDay> = [.morning]
    @Published var newWithFood: Bool = false
    @Published var newNotes: String = ""

    private let service = SupplementService.shared

    func loadData() async {
        isLoading = true
        error = nil
        await service.fetchSupplements()
        supplements = service.supplements
        todaySchedule = service.todaySchedule
        if let serviceError = service.error {
            error = serviceError.localizedDescription
        }
        isLoading = false
    }

    func addSupplement() async {
        guard !newName.isEmpty, !newDosage.isEmpty else {
            error = "Name and dosage are required"
            return
        }

        guard let patientId = await getPatientId() else {
            error = "Unable to get patient ID"
            return
        }

        let supplement = Supplement(
            id: UUID(),
            patientId: patientId,
            name: newName,
            brand: newBrand.isEmpty ? nil : newBrand,
            category: newCategory,
            dosage: newDosage,
            frequency: newFrequency,
            timeOfDay: Array(newTimeOfDay),
            withFood: newWithFood,
            notes: newNotes.isEmpty ? nil : newNotes,
            momentousProductId: nil,
            isActive: true,
            createdAt: Date()
        )

        do {
            try await service.addSupplement(supplement)
            resetForm()
            showingAddSheet = false
            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteSupplement(_ supplement: Supplement) async {
        do {
            try await service.deleteSupplement(supplement.id)
            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func markTaken(_ scheduled: ScheduledSupplement) async {
        do {
            try await service.logSupplementTaken(scheduled.supplement)
            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func resetForm() {
        newName = ""
        newBrand = ""
        newCategory = .vitamins
        newDosage = ""
        newFrequency = .daily
        newTimeOfDay = [.morning]
        newWithFood = false
        newNotes = ""
    }

    private func getPatientId() async -> UUID? {
        guard let userId = PTSupabaseClient.shared.client.auth.currentUser?.id else { return nil }

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

    // MARK: - Computed Properties

    var pendingToday: [ScheduledSupplement] {
        todaySchedule.filter { !$0.taken }
    }

    var takenToday: [ScheduledSupplement] {
        todaySchedule.filter { $0.taken }
    }

    var completionRate: Double {
        guard !todaySchedule.isEmpty else { return 0 }
        return Double(takenToday.count) / Double(todaySchedule.count)
    }

    var supplementsByCategory: [(SupplementCategory, [Supplement])] {
        let grouped = Dictionary(grouping: supplements, by: { $0.category })
        return grouped.sorted { $0.key.displayName < $1.key.displayName }
    }
}
