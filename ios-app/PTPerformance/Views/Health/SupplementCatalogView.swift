// DARK MODE: See ModeThemeModifier.swift for central theme control
import SwiftUI

/// Supplement Catalog View - Browse supplements with evidence ratings
struct SupplementCatalogView: View {
    @StateObject private var viewModel = SupplementCatalogViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.catalog.isEmpty {
                    ProgressView("Loading catalog...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.catalog.isEmpty {
                    emptyView
                } else {
                    catalogList
                }
            }
            .navigationTitle("Supplement Catalog")
            .searchable(text: $viewModel.searchText, prompt: "Search supplements")
            .task {
                await viewModel.loadData()
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }

    private var catalogList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                // Category Filter
                categoryFilterSection

                // Supplements List - show filtered empty state if no matches
                if viewModel.filteredCatalog.isEmpty && (!viewModel.searchText.isEmpty || viewModel.selectedCategory != nil) {
                    filteredEmptyView
                } else {
                    ForEach(viewModel.filteredCatalog) { supplement in
                        CatalogSupplementCard(supplement: supplement) {
                            Task {
                                await viewModel.addToRoutine(supplement)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var filteredEmptyView: some View {
        ContentUnavailableView {
            Label("No Supplements Found", systemImage: "magnifyingglass")
        } description: {
            if !viewModel.searchText.isEmpty {
                Text("No supplements match '\(viewModel.searchText)'. Try different keywords or clear your search.")
            } else if let category = viewModel.selectedCategory {
                Text("No supplements in the \(category.displayName) category yet.")
            }
        } actions: {
            Button("Clear Filters") {
                viewModel.searchText = ""
                viewModel.selectedCategory = nil
            }
            .buttonStyle(.bordered)
        }
        .padding(.top, Spacing.xl)
    }

    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                FilterChip(
                    label: "All",
                    color: .modusCyan,
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    viewModel.selectedCategory = nil
                }

                ForEach(SupplementCatalogCategory.allCases) { category in
                    FilterChip(
                        label: category.displayName,
                        color: .modusCyan,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label("No Supplements Available", systemImage: "pills")
        } description: {
            Text("The supplement catalog is currently empty. Check back later for evidence-based supplement recommendations.")
        } actions: {
            Button {
                Task {
                    await viewModel.loadData()
                }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
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
                    .frame(minHeight: 44)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.modusCyan)
                    .cornerRadius(CornerRadius.md)
            }
            .accessibilityLabel("Add \(supplement.name) to routine")
            .accessibilityHint("Double tap to add this supplement to your daily routine")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(supplement.name)\(supplement.brand.map { ", \($0)" } ?? ""), \(supplement.category.displayName). Recommended: \(supplement.dosageRange)")
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
