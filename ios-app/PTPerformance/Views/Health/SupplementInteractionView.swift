// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  SupplementInteractionView.swift
//  PTPerformance
//
//  ACP-441: Supplement Interaction Checker View
//  Allows users to check their supplement stack and medications
//  for potential interactions, safety warnings, and timing recommendations.
//

import SwiftUI

/// Main view for the Supplement Interaction Checker.
///
/// Features:
/// - Input section for supplements (auto-populated from routine) and medications
/// - Prominent "Check Interactions" button
/// - Results section with overall safety badge, interaction cards sorted by severity,
///   collapsible safety warnings, and timing recommendations
/// - Loading, empty, and error states
struct SupplementInteractionView: View {

    // MARK: - Properties

    @ObservedObject private var interactionService = SupplementInteractionService.shared
    @ObservedObject private var supplementService = SupplementService.shared
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    /// User-entered supplement names for checking
    @State private var supplementNames: [String] = []

    /// User-entered medication names
    @State private var medicationNames: [String] = []

    /// Text field for adding a new supplement
    @State private var newSupplementText = ""

    /// Text field for adding a new medication
    @State private var newMedicationText = ""

    /// Whether results have been loaded (to distinguish empty state from initial state)
    @State private var hasChecked = false

    /// Whether safety warnings section is expanded
    @State private var showSafetyWarnings = false

    /// Whether timing section is expanded
    @State private var showTimingRecommendations = false

    /// The last successful result for display
    @State private var lastResult: InteractionCheckResult?

    /// Whether the view has performed initial load of routine supplements
    @State private var hasLoadedRoutine = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.lg) {
                // Input Section
                inputSection

                // Check Button
                checkButton

                // Results Section
                if interactionService.isChecking {
                    loadingSection
                } else if let errorMessage = interactionService.error {
                    errorSection(errorMessage)
                } else if hasChecked {
                    resultsSection
                }

                // Disclaimer
                if hasChecked, let result = lastResult {
                    disclaimerSection(result.disclaimer)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Interaction Checker")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadRoutineSupplements()
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Supplements input
            supplementsInputSection

            // Medications input
            medicationsInputSection
        }
    }

    /// Section for managing supplement names to check
    private var supplementsInputSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label {
                Text("Your Supplements")
                    .font(.headline)
                    .foregroundColor(.primary)
            } icon: {
                Image(systemName: "pills.fill")
                    .foregroundColor(.modusCyan)
            }
            .accessibilityAddTraits(.isHeader)

            if supplementNames.isEmpty {
                Text("Add supplements from your routine or enter manually")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Pill chips for current supplements
            supplementChipsView

            // Add supplement input
            HStack(spacing: Spacing.xs) {
                TextField("Add supplement...", text: $newSupplementText)
                    .textFieldStyle(.roundedBorder)
                    .font(.subheadline)
                    .submitLabel(.done)
                    .onSubmit { addSupplement() }
                    .accessibilityLabel("Enter supplement name")

                Button {
                    addSupplement()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.modusCyan)
                }
                .disabled(newSupplementText.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Add supplement")
                .accessibilityHint("Adds the entered supplement to the check list")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    /// Flow layout of supplement pill chips
    private var supplementChipsView: some View {
        FlowLayout(spacing: Spacing.xs) {
            ForEach(supplementNames, id: \.self) { name in
                supplementChip(name: name, isSupp: true)
            }
        }
    }

    /// Section for managing medication names
    private var medicationsInputSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label {
                Text("Medications")
                    .font(.headline)
                    .foregroundColor(.primary)
            } icon: {
                Image(systemName: "cross.case.fill")
                    .foregroundColor(.orange)
            }
            .accessibilityAddTraits(.isHeader)

            Text("Optional - add any medications to check for interactions")
                .font(.caption)
                .foregroundColor(.secondary)

            // Pill chips for current medications
            if !medicationNames.isEmpty {
                FlowLayout(spacing: Spacing.xs) {
                    ForEach(medicationNames, id: \.self) { name in
                        supplementChip(name: name, isSupp: false)
                    }
                }
            }

            // Add medication input
            HStack(spacing: Spacing.xs) {
                TextField("Add medication...", text: $newMedicationText)
                    .textFieldStyle(.roundedBorder)
                    .font(.subheadline)
                    .submitLabel(.done)
                    .onSubmit { addMedication() }
                    .accessibilityLabel("Enter medication name")

                Button {
                    addMedication()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                }
                .disabled(newMedicationText.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Add medication")
                .accessibilityHint("Adds the entered medication to the check list")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    /// Pill chip with delete button for a supplement or medication name
    private func supplementChip(name: String, isSupp: Bool) -> some View {
        HStack(spacing: Spacing.xxs) {
            Text(name)
                .font(.caption)
                .fontWeight(.medium)

            Button {
                withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                    if isSupp {
                        supplementNames.removeAll { $0 == name }
                    } else {
                        medicationNames.removeAll { $0 == name }
                    }
                }
                HapticFeedback.light()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Remove \(name)")
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(isSupp ? Color.modusCyan.opacity(0.12) : Color.orange.opacity(0.12))
        .foregroundColor(isSupp ? .modusCyan : .orange)
        .cornerRadius(CornerRadius.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(isSupp ? "supplement" : "medication")")
        .accessibilityHint("Double tap to remove")
    }

    // MARK: - Check Button

    private var checkButton: some View {
        Button {
            HapticFeedback.medium()
            Task { await performCheck() }
        } label: {
            HStack(spacing: Spacing.sm) {
                if interactionService.isChecking {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "shield.checkered")
                        .font(.headline)
                }

                Text(interactionService.isChecking ? "Checking..." : "Check Interactions")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .padding(.vertical, Spacing.sm)
            .background(
                supplementNames.isEmpty || interactionService.isChecking
                    ? Color.modusCyan.opacity(0.5)
                    : Color.modusCyan
            )
            .cornerRadius(CornerRadius.lg)
        }
        .disabled(supplementNames.isEmpty || interactionService.isChecking)
        .accessibilityLabel("Check interactions")
        .accessibilityHint(
            supplementNames.isEmpty
                ? "Add at least one supplement first"
                : "Checks \(supplementNames.count) supplements and \(medicationNames.count) medications for interactions"
        )
    }

    // MARK: - Loading Section

    private var loadingSection: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Analyzing your supplement stack...")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Checking for interactions, safety warnings, and timing conflicts")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Checking supplement interactions, please wait")
    }

    // MARK: - Error Section

    private func errorSection(_ message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
                .accessibilityHidden(true)

            Text("Unable to Check Interactions")
                .font(.headline)
                .foregroundColor(.primary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                HapticFeedback.medium()
                Task { await performCheck() }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .tint(.modusCyan)
            .accessibilityLabel("Retry interaction check")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Results Section

    @ViewBuilder
    private var resultsSection: some View {
        if let result = lastResult {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Overall safety rating badge
                overallSafetyBadge(result.overallRating)

                // Summary text
                if !result.summary.isEmpty {
                    Text(result.summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Interactions list (or empty state)
                if result.interactions.isEmpty && result.safetyWarnings.isEmpty {
                    noInteractionsView
                } else {
                    // Interaction cards sorted by severity
                    if !result.interactions.isEmpty {
                        interactionsListSection(result.interactions)
                    }

                    // Safety warnings (collapsible)
                    if !result.safetyWarnings.isEmpty {
                        safetyWarningsSection(result.safetyWarnings)
                    }
                }

                // Timing recommendations (collapsible)
                if !result.timingRecommendations.isEmpty {
                    timingRecommendationsSection(result.timingRecommendations)
                }
            }
        }
    }

    /// Overall safety rating badge with color coding
    private func overallSafetyBadge(_ rating: SafetyRating) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: safetyIcon(for: rating))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(safetyColor(for: rating))

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Overall Safety")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(rating.displayName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(safetyColor(for: rating))
            }

            Spacer()

            // Safety indicator circle
            Circle()
                .fill(safetyColor(for: rating))
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)
        }
        .padding()
        .background(safetyColor(for: rating).opacity(colorScheme == .dark ? 0.12 : 0.06))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(safetyColor(for: rating).opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(CornerRadius.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Overall safety rating: \(rating.displayName)")
    }

    /// Empty state when no interactions found
    private var noInteractionsView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
                .accessibilityHidden(true)

            Text("No Interactions Found")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Your supplement combination appears safe. Follow the timing recommendations below for optimal absorption.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No interactions found. Your supplement combination appears safe.")
    }

    private var sortedInteractions: [SupplementInteraction] {
        (lastResult?.interactions ?? []).sorted { $0.severity > $1.severity }
    }

    /// List of interaction cards sorted by severity
    private func interactionsListSection(_ interactions: [SupplementInteraction]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label {
                Text("Interactions (\(interactions.count))")
                    .font(.headline)
                    .foregroundColor(.primary)
            } icon: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.modusCyan)
            }
            .accessibilityAddTraits(.isHeader)

            ForEach(sortedInteractions) { interaction in
                InteractionResultCard(interaction: interaction)
            }
        }
    }

    /// Collapsible safety warnings section
    private func safetyWarningsSection(_ warnings: [SafetyWarning]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                    showSafetyWarnings.toggle()
                }
                HapticFeedback.selectionChanged()
            } label: {
                HStack {
                    Label {
                        Text("Safety Warnings (\(warnings.count))")
                            .font(.headline)
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "exclamationmark.shield.fill")
                            .foregroundColor(.orange)
                    }

                    Spacer()

                    Image(systemName: showSafetyWarnings ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityLabel("Safety warnings, \(warnings.count) items")
            .accessibilityHint(showSafetyWarnings ? "Collapse section" : "Expand to view safety warnings")

            if showSafetyWarnings {
                ForEach(warnings) { warning in
                    SafetyWarningCard(warning: warning)
                }
                .transition(.opacity)
            }
        }
    }

    /// Collapsible timing recommendations section
    private func timingRecommendationsSection(_ recommendations: [String]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                    showTimingRecommendations.toggle()
                }
                HapticFeedback.selectionChanged()
            } label: {
                HStack {
                    Label {
                        Text("Timing Recommendations")
                            .font(.headline)
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                    }

                    Spacer()

                    Image(systemName: showTimingRecommendations ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityLabel("Timing recommendations")
            .accessibilityHint(showTimingRecommendations ? "Collapse section" : "Expand to view timing advice")

            if showTimingRecommendations {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            // Detect sub-items (indented with "  - ")
                            if recommendation.hasPrefix("  - ") {
                                Image(systemName: "arrow.turn.down.right")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, Spacing.md)
                                    .accessibilityHidden(true)

                                Text(recommendation.trimmingCharacters(in: CharacterSet(charactersIn: " -")))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .accessibilityHidden(true)

                                Text(recommendation)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.md)
                .transition(.opacity)
            }
        }
    }

    /// Disclaimer footer
    private func disclaimerSection(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Disclaimer: \(text)")
    }

    // MARK: - Helper Methods

    /// Load supplement names from the user's current routine
    private func loadRoutineSupplements() async {
        guard !hasLoadedRoutine else { return }
        hasLoadedRoutine = true

        // Ensure routines are fetched
        if supplementService.routines.isEmpty {
            await supplementService.fetchRoutines()
        }

        // Extract supplement names from active routines
        let routineNames = supplementService.routines
            .filter { $0.isActive }
            .compactMap { $0.supplement?.name }

        if !routineNames.isEmpty {
            supplementNames = routineNames
        }
    }

    /// Add a supplement from the text field
    private func addSupplement() {
        let trimmed = newSupplementText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard !supplementNames.contains(where: { $0.lowercased() == trimmed.lowercased() }) else {
            newSupplementText = ""
            return
        }

        withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
            supplementNames.append(trimmed)
        }
        newSupplementText = ""
        HapticFeedback.light()
    }

    /// Add a medication from the text field
    private func addMedication() {
        let trimmed = newMedicationText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard !medicationNames.contains(where: { $0.lowercased() == trimmed.lowercased() }) else {
            newMedicationText = ""
            return
        }

        withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
            medicationNames.append(trimmed)
        }
        newMedicationText = ""
        HapticFeedback.light()
    }

    /// Perform the interaction check
    private func performCheck() async {
        do {
            let result = try await interactionService.checkInteractions(
                supplements: supplementNames,
                medications: medicationNames.isEmpty ? nil : medicationNames
            )
            lastResult = result
            hasChecked = true

            // Auto-expand safety warnings if there are critical/major interactions
            if result.interactions.contains(where: { $0.severity == .critical || $0.severity == .major }) {
                showSafetyWarnings = true
            }

            // Always show timing recommendations
            showTimingRecommendations = true

            HapticFeedback.formSubmission(success: true)
        } catch {
            hasChecked = true
            HapticFeedback.formSubmission(success: false)
        }
    }

    /// Get the SF Symbol icon for a safety rating
    private func safetyIcon(for rating: SafetyRating) -> String {
        switch rating {
        case .safe: return "checkmark.shield.fill"
        case .caution: return "exclamationmark.shield.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .danger: return "xmark.shield.fill"
        }
    }

    /// Get the color for a safety rating
    private func safetyColor(for rating: SafetyRating) -> Color {
        switch rating {
        case .safe: return .green
        case .caution: return .yellow
        case .warning: return .orange
        case .danger: return .red
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Interaction Checker - Input") {
    NavigationStack {
        SupplementInteractionView()
    }
}

#Preview("Interaction Checker - With Results") {
    NavigationStack {
        SupplementInteractionResultsPreview()
    }
}

/// Helper view that shows the interaction view pre-populated with sample results
private struct SupplementInteractionResultsPreview: View {
    @State private var service = SupplementInteractionService.preview

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Simulated overall safety badge
                overallSafetyBadge

                // Summary
                Text("1 dangerous interaction(s) found that require immediate attention. 1 major interaction(s) require medical consultation.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Interaction cards
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label {
                        Text("Interactions (4)")
                            .font(.headline)
                    } icon: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.modusCyan)
                    }

                    ForEach(SupplementInteraction.sampleInteractions) { interaction in
                        InteractionResultCard(interaction: interaction)
                    }
                }

                // Safety warnings
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label {
                        Text("Safety Warnings (3)")
                            .font(.headline)
                    } icon: {
                        Image(systemName: "exclamationmark.shield.fill")
                            .foregroundColor(.orange)
                    }

                    ForEach(SafetyWarning.sampleWarnings) { warning in
                        SafetyWarningCard(warning: warning)
                    }
                }

                // Timing
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label {
                        Text("Timing Recommendations")
                            .font(.headline)
                    } icon: {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        timingRow("Take iron on an empty stomach with Vitamin C for best absorption.")
                        timingRow("Take fat-soluble vitamins (D, A, E, K) with meals containing healthy fats.")
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.md)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Interaction Checker")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var overallSafetyBadge: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Overall Safety")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Warning")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }

            Spacer()

            Circle()
                .fill(.orange)
                .frame(width: 12, height: 12)
        }
        .padding()
        .background(Color.orange.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(CornerRadius.lg)
    }

    private func timingRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.caption)
                .foregroundColor(.blue)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}
#endif
