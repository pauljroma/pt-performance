import SwiftUI

/// ViewModel for Supplement Log View
@MainActor
final class SupplementLogViewModel: ObservableObject {
    @Published var recentLogs: [SupplementLogEntry] = []
    @Published var availableSupplements: [Supplement] = []
    @Published var isLoading = false
    @Published var error: String?

    private let service = SupplementService.shared

    func loadData() async {
        isLoading = true
        error = nil

        // Fetch recent logs from service
        recentLogs = service.recentLogs

        isLoading = false
    }

    func loadSupplements() async {
        await service.fetchCatalog()
        // Convert catalog items to Supplement for compatibility
        availableSupplements = service.catalog.map { catalogItem in
            Supplement(
                id: catalogItem.id,
                patientId: UUID(),
                name: catalogItem.name,
                brand: catalogItem.brand,
                category: SupplementMappingUtils.mapCatalogToSupplementCategory(catalogItem.category),
                dosage: catalogItem.dosageRange,
                frequency: .daily,
                timeOfDay: catalogItem.timing.compactMap { SupplementMappingUtils.mapTimingToTimeOfDay($0) },
                withFood: catalogItem.timing.contains(.withMeal),
                notes: catalogItem.description,
                momentousProductId: nil,
                isActive: true,
                createdAt: catalogItem.createdAt
            )
        }
    }

    func deleteLog(_ log: SupplementLogEntry) async {
        do {
            try await service.undoLog(log.id)
            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
