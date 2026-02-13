//
//  RTSCriteriaChecklistView.swift
//  PTPerformance
//
//  Milestone criteria checklist for a phase in Return-to-Sport protocols
//  Displays grouped criteria with pass/fail status and test results
//

import SwiftUI

// MARK: - RTS Criteria Checklist View

/// Milestone criteria checklist for a phase
struct RTSCriteriaChecklistView: View {
    let phaseId: UUID
    let protocolId: UUID
    @StateObject private var viewModel = RTSTestingViewModel()

    @State private var selectedCriterion: RTSMilestoneCriterion?
    @State private var showTestRecordingSheet = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.criteria.isEmpty {
                loadingView
            } else if viewModel.criteria.isEmpty {
                emptyStateView
            } else {
                contentView
            }
        }
        .navigationTitle("Phase Criteria")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showTestRecordingSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("Record new test")
            }
        }
        .sheet(isPresented: $showTestRecordingSheet) {
            if let criterion = selectedCriterion ?? viewModel.criteria.first(where: { !$0.isPassed }) {
                NavigationStack {
                    RTSTestRecordingView(
                        criterion: criterion,
                        protocolId: protocolId
                    )
                }
            }
        }
        .refreshable {
            await viewModel.loadCriteria(phaseId: phaseId, protocolId: protocolId)
        }
        .task {
            await viewModel.loadCriteria(phaseId: phaseId, protocolId: protocolId)
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Progress summary card
                progressSummaryCard

                // Grouped criteria by category
                ForEach(RTSCriterionCategory.allCases, id: \.self) { category in
                    let categoryCriteria = viewModel.criteria.filter { $0.category == category }

                    if !categoryCriteria.isEmpty {
                        criteriaSection(for: category, criteria: categoryCriteria)
                    }
                }
            }
            .padding(.vertical, Spacing.md)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Progress Summary Card

    private var progressSummaryCard: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Overall Progress")
                        .font(.headline)

                    Text("\(viewModel.passedCount) of \(viewModel.totalCount) criteria passed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Percentage
                Text("\(viewModel.progressPercentage)%")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(viewModel.progressColor)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(viewModel.progressColor)
                        .frame(width: geometry.size.width * viewModel.progressFraction)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.progressFraction)
                }
            }
            .frame(height: 12)

            // Required criteria status
            if viewModel.requiredCount > 0 {
                HStack {
                    Image(systemName: viewModel.allRequiredPassed ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(viewModel.allRequiredPassed ? .green : .orange)

                    Text(viewModel.allRequiredPassed
                        ? "All required criteria met"
                        : "\(viewModel.requiredPassedCount) of \(viewModel.requiredCount) required criteria met"
                    )
                    .font(.subheadline)
                    .foregroundColor(viewModel.allRequiredPassed ? .green : .orange)

                    Spacer()
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Overall progress: \(viewModel.passedCount) of \(viewModel.totalCount) criteria passed, \(viewModel.progressPercentage) percent complete")
    }

    // MARK: - Criteria Section

    private func criteriaSection(for category: RTSCriterionCategory, criteria: [RTSMilestoneCriterion]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section header
            HStack(spacing: Spacing.sm) {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)

                Text(category.displayName)
                    .font(.headline)

                Spacer()

                // Category progress
                let passed = criteria.filter { $0.isPassed }.count
                Text("\(passed)/\(criteria.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .accessibilityAddTraits(.isHeader)

            // Criteria list
            VStack(spacing: 0) {
                ForEach(criteria) { criterion in
                    RTSCriterionRow(
                        criterion: criterion,
                        onTap: {
                            selectedCriterion = criterion
                            showTestRecordingSheet = true
                        }
                    )

                    if criterion.id != criteria.last?.id {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.md)
            .adaptiveShadow(Shadow.subtle)
            .padding(.horizontal)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading criteria...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        EmptyStateView(
            title: "No Criteria Defined",
            message: "This phase doesn't have any milestone criteria defined yet.",
            icon: "list.bullet.clipboard",
            iconColor: .blue
        )
    }
}

// MARK: - RTS Criterion Row

/// Single criterion row in the checklist
struct RTSCriterionRow: View {
    let criterion: RTSMilestoneCriterion
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap?()
        }) {
            HStack(spacing: Spacing.md) {
                // Status indicator
                ZStack {
                    Circle()
                        .fill(criterion.statusColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: criterion.statusIcon)
                        .font(.body)
                        .foregroundColor(criterion.statusColor)
                }

                // Criterion details
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(criterion.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        if criterion.isRequired {
                            Text("Required")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .cornerRadius(CornerRadius.xs)
                        }
                    }

                    Text(criterion.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    // Target value
                    HStack(spacing: Spacing.sm) {
                        Text("Target: \(criterion.targetDescription)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // Latest result if available
                        if let result = criterion.latestResult {
                            Text("|")
                                .foregroundColor(.secondary)

                            Text("Latest: \(result.formattedValue)")
                                .font(.caption)
                                .foregroundColor(result.passed ? .green : .orange)
                        }
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(criterionAccessibilityLabel)
        .accessibilityHint("Double tap to record a test result")
    }

    private var criterionAccessibilityLabel: String {
        var label = criterion.name
        if criterion.isRequired {
            label += ", required"
        }
        label += ", target \(criterion.targetDescription)"

        if criterion.isPassed {
            label += ", passed"
        } else if criterion.hasBeenTested {
            label += ", not yet passed"
        } else {
            label += ", not tested"
        }

        if let result = criterion.latestResult {
            label += ", latest result \(result.formattedValue)"
        }

        return label
    }
}

// MARK: - Preview

#if DEBUG
struct RTSCriteriaChecklistView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RTSCriteriaChecklistView(
                phaseId: UUID(),
                protocolId: UUID()
            )
        }
    }
}
#endif
