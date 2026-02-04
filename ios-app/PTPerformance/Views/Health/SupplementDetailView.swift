import SwiftUI

/// Supplement Detail View - View supplement details and add to routine
struct SupplementDetailView: View {
    @StateObject private var viewModel = SupplementViewModel()
    @Environment(\.dismiss) private var dismiss

    let supplementId: UUID

    @State private var showingAddSheet = false

    init(supplementId: UUID) {
        self.supplementId = supplementId
    }

    private var supplement: CatalogSupplement? {
        viewModel.catalog.first { $0.id == supplementId }
    }

    var body: some View {
        ScrollView {
            if let supplement = supplement {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Header
                    headerSection(supplement)

                    // Benefits
                    benefitsSection(supplement)

                    // Dosage Info
                    dosageSection(supplement)

                    // Timing
                    timingSection(supplement)

                    // Add to Routine Button
                    addToRoutineButton(supplement)
                }
                .padding()
            } else {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(supplement?.name ?? "Supplement")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadCatalog()
        }
    }

    private func headerSection(_ supplement: CatalogSupplement) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(supplement.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.modusDeepTeal)

                if let brand = supplement.brand {
                    Text(brand)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(Color.modusCyan.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: supplement.category.icon)
                    .font(.title2)
                    .foregroundColor(.modusCyan)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private func benefitsSection(_ supplement: CatalogSupplement) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Benefits")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            ForEach(supplement.benefits, id: \.self) { benefit in
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.modusTealAccent)
                        .font(.caption)

                    Text(benefit)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private func dosageSection(_ supplement: CatalogSupplement) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Recommended Dosage")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            Text(supplement.dosageRange)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private func timingSection(_ supplement: CatalogSupplement) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Best Time to Take")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            HStack {
                ForEach(supplement.timing) { timing in
                    Label(timing.displayName, systemImage: timing.icon)
                        .font(.caption)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background(Color.modusCyan.opacity(0.15))
                        .foregroundColor(.modusCyan)
                        .cornerRadius(CornerRadius.sm)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private func addToRoutineButton(_ supplement: CatalogSupplement) -> some View {
        Button {
            Task {
                await viewModel.addToRoutine(supplement)
                dismiss()
            }
        } label: {
            Text("Add to My Routine")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.modusCyan)
                .cornerRadius(CornerRadius.lg)
        }
    }
}

#if DEBUG
struct SupplementDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SupplementDetailView(supplementId: UUID())
        }
    }
}
#endif
