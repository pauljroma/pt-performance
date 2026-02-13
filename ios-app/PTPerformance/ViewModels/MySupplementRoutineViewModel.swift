import SwiftUI

/// ViewModel for My Supplement Routine View
@MainActor
final class MySupplementRoutineViewModel: ObservableObject {
    @Published var routineItems: [RoutineSupplement] = []
    @Published var isLoading = false
    @Published var error: String?

    private let service = SupplementService.shared

    // MARK: - Computed Properties

    var totalSupplements: Int {
        routineItems.count
    }

    var activeTimes: Int {
        Set(routineItems.compactMap { $0.timing }).count
    }

    // MARK: - Items by Timing

    func items(for timing: SupplementTiming) -> [RoutineSupplement] {
        routineItems.filter { $0.timing == timing }
    }

    // MARK: - Data Loading

    func loadRoutine() async {
        isLoading = true
        error = nil

        await service.fetchRoutines()

        // Convert routines to RoutineSupplement for UI
        routineItems = service.routines.filter { $0.isActive }.compactMap { routine in
            RoutineSupplement(
                id: routine.id,
                name: routine.supplement?.name ?? "Unknown",
                brand: routine.supplement?.brand,
                category: routine.supplement?.category ?? .other,
                dosage: parseDosage(routine.dosage),
                timing: routine.timing,
                days: Weekday.allCases, // Default to all days
                withFood: routine.withFood,
                reminderEnabled: true
            )
        }

        if let serviceError = service.error {
            error = serviceError.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Mutations

    func addToRoutine(_ supplement: RoutineSupplement) async {
        do {
            try await service.addToRoutine(
                supplementId: supplement.id,
                supplementName: supplement.name,
                brand: supplement.brand,
                category: supplement.category,
                dosage: supplement.dosage?.displayString ?? "1 serving",
                timing: supplement.timing ?? .morning,
                frequency: .daily,
                withFood: supplement.withFood,
                notes: nil
            )
            await loadRoutine()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateRoutineSupplement(_ supplement: RoutineSupplement) async {
        do {
            try await service.updateRoutine(
                supplement.id,
                dosage: supplement.dosage?.displayString,
                timing: supplement.timing,
                frequency: nil,
                withFood: supplement.withFood,
                notes: nil
            )
            await loadRoutine()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteItems(at offsets: IndexSet, for timing: SupplementTiming) async {
        let timingItems = items(for: timing)
        for offset in offsets {
            guard offset < timingItems.count else { continue }
            let item = timingItems[offset]
            do {
                try await service.removeFromRoutine(item.id)
            } catch {
                self.error = error.localizedDescription
            }
        }
        await loadRoutine()
    }

    func moveItems(from source: IndexSet, to destination: Int, for timing: SupplementTiming) {
        // Reorder items locally - would need server-side support for persistence
        var timingItems = items(for: timing)
        timingItems.move(fromOffsets: source, toOffset: destination)

        // Update the main list with reordered items
        let otherItems = routineItems.filter { $0.timing != timing }
        routineItems = otherItems + timingItems
    }

    // MARK: - Helpers

    private func parseDosage(_ dosageString: String) -> Dosage? {
        // Parse dosage string like "5g" or "500mg" into Dosage struct
        let pattern = #"^([\d.]+)\s*(\w+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: dosageString, range: NSRange(dosageString.startIndex..., in: dosageString)) else {
            return Dosage(amount: 1, unit: .serving)
        }

        guard let amountRange = Range(match.range(at: 1), in: dosageString),
              let unitRange = Range(match.range(at: 2), in: dosageString),
              let amount = Double(dosageString[amountRange]) else {
            return Dosage(amount: 1, unit: .serving)
        }

        let unitString = String(dosageString[unitRange]).lowercased()
        let unit = DosageUnit.allCases.first { $0.rawValue.lowercased() == unitString } ?? .mg

        return Dosage(amount: amount, unit: unit)
    }
}
