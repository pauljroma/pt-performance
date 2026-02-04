import SwiftUI

/// ViewModel for Supplement Dashboard View
@MainActor
final class SupplementDashboardViewModel: ObservableObject {
    @Published var todayChecklist: [SupplementChecklistItem] = []
    @Published var myStack: [RoutineSupplement] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedSupplementForLog: RoutineSupplement?

    private let service = SupplementService.shared

    // MARK: - Computed Properties

    var completedCount: Int {
        todayChecklist.filter { $0.isTaken }.count
    }

    var totalCount: Int {
        todayChecklist.count
    }

    var complianceProgress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var currentStreak: Int {
        service.todayCompliance?.streakDays ?? 0
    }

    var bestStreak: Int {
        service.analytics?.longestStreak ?? currentStreak
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        error = nil

        await service.fetchRoutines()
        await service.calculateTodayCompliance()

        // Build checklist from today's doses
        todayChecklist = service.todayDoses.map { dose in
            SupplementChecklistItem(
                id: dose.id,
                supplement: RoutineSupplement(
                    id: dose.supplementId,
                    name: dose.supplementName,
                    brand: dose.brand,
                    category: dose.category,
                    dosage: Dosage(amount: Double(dose.dosage.filter { $0.isNumber || $0 == "." }) ?? 0, unit: .mg),
                    timing: dose.timing,
                    days: nil,
                    withFood: dose.withFood,
                    reminderEnabled: false
                ),
                timing: dose.timing,
                dosage: dose.dosage,
                isTaken: dose.isTaken,
                takenAt: dose.takenAt,
                logId: dose.logId
            )
        }

        // Build my stack from routines
        myStack = service.routines.filter { $0.isActive }.compactMap { routine in
            guard let supplement = routine.supplement else { return nil }
            return RoutineSupplement(
                id: routine.id,
                name: supplement.name,
                brand: supplement.brand,
                category: supplement.category,
                dosage: Dosage(amount: Double(routine.dosage.filter { $0.isNumber || $0 == "." }) ?? 0, unit: .mg),
                timing: routine.timing,
                days: nil,
                withFood: routine.withFood,
                reminderEnabled: false
            )
        }

        if let serviceError = service.error {
            error = serviceError.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Actions

    func toggleItem(_ item: SupplementChecklistItem) {
        guard let index = todayChecklist.firstIndex(where: { $0.id == item.id }) else { return }

        Task { [weak self] in
            guard let self else { return }
            if let dose = service.todayDoses.first(where: { $0.id == item.id }) {
                if item.isTaken {
                    if let logId = item.logId {
                        do {
                            try await service.undoLog(logId)
                        } catch {
                            self.error = error.localizedDescription
                        }
                    }
                } else {
                    do {
                        try await service.logSupplement(dose: dose)
                    } catch {
                        self.error = error.localizedDescription
                    }
                }
                await loadData()
            }
        }
    }

    func markAllAsTaken() {
        Task { [weak self] in
            guard let self else { return }
            for dose in service.todayDoses where !dose.isTaken {
                do {
                    try await service.logSupplement(dose: dose)
                } catch {
                    self.error = error.localizedDescription
                }
            }
            await loadData()
        }
    }

    func saveLog(_ log: SupplementLogEntry) async {
        // Log already saved through toggleItem
        await loadData()
    }
}

/// Checklist item for supplement dashboard
struct SupplementChecklistItem: Identifiable, Hashable {
    let id: UUID
    let supplement: RoutineSupplement
    let timing: SupplementTiming
    let dosage: String
    var isTaken: Bool
    var takenAt: Date?
    var logId: UUID?

    static func == (lhs: SupplementChecklistItem, rhs: SupplementChecklistItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
