import SwiftUI

/// ViewModel for Supplement Catalog View
@MainActor
final class SupplementCatalogViewModel: ObservableObject {
    @Published var catalog: [CatalogSupplement] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: SupplementCatalogCategory?
    @Published var selectedEvidenceLevel: EvidenceRating?
    @Published var isLoading = false
    @Published var error: String?

    private let service = SupplementService.shared

    var filteredCatalog: [CatalogSupplement] {
        var results = catalog

        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            results = results.filter {
                $0.name.lowercased().contains(searchLower) ||
                ($0.brand?.lowercased().contains(searchLower) ?? false) ||
                $0.benefits.contains { $0.lowercased().contains(searchLower) }
            }
        }

        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }

        if let level = selectedEvidenceLevel {
            results = results.filter { $0.evidenceRating == level }
        }

        return results
    }

    var catalogByCategory: [(SupplementCatalogCategory, [CatalogSupplement])] {
        let grouped = Dictionary(grouping: filteredCatalog, by: { $0.category })
        return grouped.sorted { $0.key.displayName < $1.key.displayName }
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

    func addToRoutine(_ supplement: CatalogSupplement) async {
        do {
            try await service.addToRoutine(
                supplementId: supplement.id,
                supplementName: supplement.name,
                brand: supplement.brand,
                category: supplement.category,
                dosage: supplement.dosageRange,
                timing: supplement.timing.first ?? .morning,
                frequency: .daily,
                withFood: supplement.timing.contains(.withMeal),
                notes: nil
            )
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// EvidenceLevel is defined in Supplement.swift
