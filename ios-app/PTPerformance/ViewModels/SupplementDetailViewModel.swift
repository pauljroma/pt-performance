import SwiftUI

/// ViewModel for Supplement Detail View
@MainActor
final class SupplementDetailViewModel: ObservableObject {
    @Published var supplement: CatalogSupplement?
    @Published var isInRoutine = false
    @Published var isLoading = false
    @Published var error: String?

    private let service = SupplementService.shared

    func loadSupplement(_ supplementId: UUID) async {
        isLoading = true
        error = nil

        await service.fetchCatalog()
        supplement = service.catalog.first { $0.id == supplementId }

        // Check if in routine
        isInRoutine = service.routines.contains { $0.supplementId == supplementId && $0.isActive }

        isLoading = false
    }

    func addToRoutine(dosage: String, timing: SupplementTiming, withFood: Bool, notes: String?) async {
        guard let supplement = supplement else { return }

        do {
            try await service.addToRoutine(
                supplementId: supplement.id,
                supplementName: supplement.name,
                brand: supplement.brand,
                category: supplement.category,
                dosage: dosage,
                timing: timing,
                frequency: .daily,
                withFood: withFood,
                notes: notes
            )
            isInRoutine = true
        } catch {
            self.error = error.localizedDescription
        }
    }

    func removeFromRoutine() async {
        guard let supplement = supplement,
              let routine = service.routines.first(where: { $0.supplementId == supplement.id && $0.isActive }) else { return }

        do {
            try await service.removeFromRoutine(routine.id)
            isInRoutine = false
        } catch {
            self.error = error.localizedDescription
        }
    }
}
