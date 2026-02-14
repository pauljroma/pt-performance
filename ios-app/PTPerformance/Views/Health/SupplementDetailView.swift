// DARK MODE: See ModeThemeModifier.swift for central theme control
import SwiftUI

/// Supplement Detail View - View supplement details and add to routine
struct SupplementDetailView: View {
    @StateObject private var viewModel = SupplementDetailViewModel()
    @StateObject private var interactionService = SupplementInteractionService.shared
    @Environment(\.dismiss) private var dismiss

    let supplementId: UUID

    init(supplementId: UUID) {
        self.supplementId = supplementId
    }

    @State private var isAddingToRoutine = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        ScrollView {
            if let supplement = viewModel.supplement {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Header
                    headerSection(supplement)

                    // Benefits
                    benefitsSection(supplement)

                    // Dosage Info
                    dosageSection(supplement)

                    // Timing
                    timingSection(supplement)

                    // Interactions
                    interactionsSection(supplement)

                    // Add/Remove from Routine Button
                    if viewModel.isInRoutine {
                        removeFromRoutineButton(supplement)
                    } else {
                        addToRoutineButton(supplement)
                    }
                }
                .padding()
            } else if viewModel.isLoading {
                VStack(spacing: Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading supplement details...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Loading supplement details")
            } else {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                        .accessibilityHidden(true)

                    Text("Supplement Not Found")
                        .font(.headline)
                        .foregroundColor(.modusDeepTeal)

                    Text("This supplement may have been removed from the catalog.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Go Back") { dismiss() }
                        .buttonStyle(.bordered)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .combine)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.supplement?.name ?? "Supplement")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSupplement(supplementId)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
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
            .accessibilityHidden(true)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(supplement.name)\(supplement.brand.map { ", by \($0)" } ?? ""), \(supplement.category.displayName) supplement")
    }

    private func benefitsSection(_ supplement: CatalogSupplement) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Benefits")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)
                .accessibilityAddTraits(.isHeader)

            ForEach(supplement.benefits, id: \.self) { benefit in
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.modusTealAccent)
                        .font(.caption)
                        .accessibilityHidden(true)

                    Text(benefit)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(benefit)
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
                .accessibilityAddTraits(.isHeader)

            Text(supplement.dosageRange)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Recommended dosage: \(supplement.dosageRange)")
    }

    private func timingSection(_ supplement: CatalogSupplement) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Best Time to Take")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)
                .accessibilityAddTraits(.isHeader)

            HStack {
                ForEach(supplement.timing) { timing in
                    Label(timing.displayName, systemImage: timing.icon)
                        .font(.caption)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.modusCyan.opacity(0.15))
                        .foregroundColor(.modusCyan)
                        .cornerRadius(CornerRadius.sm)
                        .accessibilityLabel(timing.displayName)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Best time to take: \(supplement.timing.map { $0.displayName }.joined(separator: ", "))")
    }

    /// Interactions section: shows known interactions for this supplement with
    /// other supplements in the user's routine or configured medications.
    private func interactionsSection(_ supplement: CatalogSupplement) -> some View {
        let relevantInteractions = interactionService.interactions.filter { interaction in
            interaction.supplement1.lowercased() == supplement.name.lowercased()
            || interaction.supplement2.lowercased() == supplement.name.lowercased()
        }

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Interactions")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)
                .accessibilityAddTraits(.isHeader)

            if interactionService.isChecking {
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Checking interactions...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, Spacing.sm)
            } else if relevantInteractions.isEmpty {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                        .accessibilityHidden(true)

                    Text("No known interactions with your current routine")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("No known interactions with your current routine")
            } else {
                ForEach(relevantInteractions) { interaction in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Circle()
                            .fill(interactionSeverityColor(interaction.severity))
                            .frame(width: 10, height: 10)
                            .padding(.top, 5)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: Spacing.xs) {
                                Text(interactionPartnerName(for: supplement.name, in: interaction))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)

                                Text("(\(interaction.severity.displayName))")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(interactionSeverityColor(interaction.severity))
                            }

                            Text(interaction.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(3)

                            if !interaction.recommendation.isEmpty {
                                Text(interaction.recommendation)
                                    .font(.caption)
                                    .foregroundColor(.modusCyan)
                                    .italic()
                                    .padding(.top, 2)
                            }
                        }
                    }
                    .padding(.vertical, Spacing.xxs)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(interaction.severity.displayName) interaction with \(interactionPartnerName(for: supplement.name, in: interaction)): \(interaction.description)")
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    /// Returns the name of the other supplement in an interaction pair.
    private func interactionPartnerName(for supplementName: String, in interaction: SupplementInteraction) -> String {
        if interaction.supplement1.lowercased() == supplementName.lowercased() {
            return interaction.supplement2
        }
        return interaction.supplement1
    }

    /// Maps interaction severity to a display color.
    private func interactionSeverityColor(_ severity: SupplementInteraction.Severity) -> Color {
        switch severity {
        case .critical: return .red
        case .major: return .orange
        case .moderate: return .yellow
        case .minor: return .green
        }
    }

    private func addToRoutineButton(_ supplement: CatalogSupplement) -> some View {
        Button {
            isAddingToRoutine = true
            HapticFeedback.medium()
            Task {
                await viewModel.addToRoutine(
                    dosage: supplement.dosageRange,
                    timing: supplement.timing.first ?? .morning,
                    withFood: supplement.timing.contains(.withMeal),
                    notes: nil
                )

                if let error = viewModel.error {
                    isAddingToRoutine = false
                    errorMessage = error
                    showingError = true
                    HapticFeedback.error()
                } else {
                    isAddingToRoutine = false
                    HapticFeedback.success()
                }
            }
        } label: {
            HStack {
                if isAddingToRoutine {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Add to My Routine")
                        .font(.headline)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .padding()
            .background(
                isAddingToRoutine
                    ? Color.modusCyan.opacity(0.7)
                    : Color.modusCyan
            )
            .cornerRadius(CornerRadius.lg)
        }
        .disabled(isAddingToRoutine)
        .accessibilityLabel("Add \(supplement.name) to my routine")
        .accessibilityHint(isAddingToRoutine ? "Adding supplement, please wait" : "Double tap to add this supplement to your daily routine")
    }

    private func removeFromRoutineButton(_ supplement: CatalogSupplement) -> some View {
        Button {
            Task {
                await viewModel.removeFromRoutine()
                HapticFeedback.success()
            }
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("In My Routine")
                    .font(.headline)
            }
            .foregroundColor(.modusTealAccent)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .padding()
            .background(Color.modusTealAccent.opacity(0.15))
            .cornerRadius(CornerRadius.lg)
        }
        .accessibilityLabel("\(supplement.name) is in your routine")
        .accessibilityHint("Double tap to remove from your routine")
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
