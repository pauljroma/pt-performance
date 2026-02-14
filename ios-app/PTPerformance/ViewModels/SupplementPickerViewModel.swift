import SwiftUI

/// ViewModel for Supplement Picker View
@MainActor
final class SupplementPickerViewModel: ObservableObject {
    @Published var catalog: [CatalogSupplement] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: SupplementCatalogCategory?
    @Published var isLoading = false
    @Published var error: String?

    private let service = SupplementService.shared

    /// Supplements available for selection (alias for catalog)
    var supplements: [Supplement] {
        // Convert CatalogSupplement to Supplement for picker compatibility
        catalog.map { catalogItem in
            Supplement(
                id: catalogItem.id,
                patientId: UUID(), // Placeholder
                name: catalogItem.name,
                brand: catalogItem.brand,
                category: SupplementMappingUtils.mapCatalogToSupplementCategory(catalogItem.category),
                dosage: catalogItem.dosageRange,
                frequency: SupplementFrequency.daily,
                timeOfDay: catalogItem.timing.compactMap { SupplementMappingUtils.mapTimingToTimeOfDay($0) },
                withFood: catalogItem.timing.contains(.withMeal),
                notes: catalogItem.description,
                momentousProductId: Optional<String>.none,
                isActive: true,
                createdAt: catalogItem.createdAt
            )
        }
    }

    var filteredCatalog: [CatalogSupplement] {
        var results = catalog

        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            results = results.filter {
                $0.name.lowercased().contains(searchLower) ||
                ($0.brand?.lowercased().contains(searchLower) ?? false)
            }
        }

        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }

        return results
    }

    func loadData() async {
        isLoading = true
        error = nil

        await service.fetchCatalog()
        catalog = service.catalog

        if let serviceError = service.error {
            error = serviceError.localizedDescription
        }

        isLoading = false
    }

    /// Alias for loadData for backward compatibility
    func loadSupplements() async {
        await loadData()
    }

}
