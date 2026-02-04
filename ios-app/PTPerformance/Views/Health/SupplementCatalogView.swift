import SwiftUI

/// Supplement Catalog View - Browse supplements with evidence ratings
struct SupplementCatalogView: View {
    @StateObject private var viewModel = SupplementViewModel()
    @Environment(\.colorScheme) private var colorScheme

    @State private var searchText = ""
    @State private var selectedCategory: SupplementCatalogCategory?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingCatalog && viewModel.catalog.isEmpty {
                    ProgressView("Loading catalog...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.catalog.isEmpty {
                    emptyView
                } else {
                    catalogList
                }
            }
            .navigationTitle("Supplement Catalog")
            .searchable(text: $searchText, prompt: "Search supplements")
            .task {
                await viewModel.loadCatalog()
            }
        }
    }

    private var filteredCatalog: [CatalogSupplement] {
        var results = viewModel.catalog

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

    private var catalogList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                // Category Filter
                categoryFilterSection

                // Supplements List
                ForEach(filteredCatalog) { supplement in
                    CatalogSupplementCard(supplement: supplement) {
                        Task {
                            await viewModel.addToRoutine(supplement)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                FilterChip(
                    label: "All",
                    color: .modusCyan,
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(SupplementCatalogCategory.allCases) { category in
                    FilterChip(
                        label: category.displayName,
                        color: .modusCyan,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var emptyView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "pills")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No supplements found")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Catalog Supplement Card

private struct CatalogSupplementCard: View {
    let supplement: CatalogSupplement
    let onAddToRoutine: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(supplement.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if let brand = supplement.brand {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: supplement.category.icon)
                    .font(.title2)
                    .foregroundColor(.modusCyan)
            }

            // Benefits
            if !supplement.benefits.isEmpty {
                Text(supplement.benefits.prefix(3).joined(separator: " • "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Dosage
            Text("Recommended: \(supplement.dosageRange)")
                .font(.caption)
                .foregroundColor(.modusCyan)

            // Add Button
            Button(action: onAddToRoutine) {
                Text("Add to Routine")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.modusCyan)
                    .cornerRadius(CornerRadius.md)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }
}

// FilterChip is defined in Components/FilterChip.swift

#if DEBUG
struct SupplementCatalogView_Previews: PreviewProvider {
    static var previews: some View {
        SupplementCatalogView()
    }
}
#endif
