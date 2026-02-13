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

    /// State for delete confirmation dialog
    @Published var logToDelete: SupplementLogEntry?
    @Published var showDeleteConfirmation = false

    /// Request deletion with confirmation
    func requestDelete(_ log: SupplementLogEntry) {
        logToDelete = log
        showDeleteConfirmation = true
    }

    /// Confirm and execute deletion
    func confirmDelete() async {
        guard let log = logToDelete else { return }

        do {
            try await service.undoLog(log.id)
            DebugLogger.shared.log("Deleted supplement log: \(log.id)", level: .success)
            await loadData()
        } catch {
            DebugLogger.shared.log("Failed to delete supplement log \(log.id): \(error.localizedDescription)", level: .error)
            self.error = "Failed to delete log. Please try again."
        }

        logToDelete = nil
    }

    /// Cancel deletion
    func cancelDelete() {
        logToDelete = nil
        showDeleteConfirmation = false
    }
}
