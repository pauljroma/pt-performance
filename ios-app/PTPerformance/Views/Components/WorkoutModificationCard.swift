//
//  WorkoutModificationCard.swift
//  PTPerformance
//
//  Adaptive Training Engine - UI card for workout modification suggestions
//  Shows suggested adjustments and allows athletes to accept/decline
//

import SwiftUI

/// Card displaying a suggested workout modification with accept/decline actions
struct WorkoutModificationCard: View {
    let modification: WorkoutModification
    let onAccept: () -> Void
    let onDecline: () -> Void
    let onModify: (() -> Void)?

    @State private var isExpanded: Bool = false
    @State private var isProcessing: Bool = false

    init(
        modification: WorkoutModification,
        onAccept: @escaping () -> Void,
        onDecline: @escaping () -> Void,
        onModify: (() -> Void)? = nil
    ) {
        self.modification = modification
        self.onAccept = onAccept
        self.onDecline = onDecline
        self.onModify = onModify
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with readiness context
            headerSection

            Divider()
                .padding(.horizontal)

            // Main content
            VStack(alignment: .leading, spacing: 12) {
                // Modification summary
                suggestionSection

                // Expandable explanation
                if isExpanded {
                    explanationSection
                }

                // Exercise-level changes (if any)
                if let exerciseChanges = modification.exerciseModifications, !exerciseChanges.isEmpty {
                    exerciseChangesSection(exerciseChanges)
                }
            }
            .padding()

            Divider()
                .padding(.horizontal)

            // Action buttons
            actionButtons
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Workout modification suggestion")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(triggerColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: modification.modificationType.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(triggerColor)
            }

            // Title and trigger
            VStack(alignment: .leading, spacing: 2) {
                Text("Suggested Adjustment")
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Text(modification.trigger.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let score = modification.readinessScore {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(Int(score))/100 readiness")
                            .font(.caption)
                            .foregroundColor(readinessColor(for: score))
                    }
                }
            }

            Spacer()

            // Expand/collapse button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
            .accessibilityLabel(isExpanded ? "Collapse details" : "Expand details")
        }
        .padding()
    }

    // MARK: - Suggestion Section

    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Primary suggestion
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 4) {
                    Text(modification.primaryDisplayText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)

                    Text(modification.reason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(isExpanded ? nil : 2)
                }
            }

            // Session name if available
            if let sessionName = modification.sessionName {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))

                    Text("For: \(sessionName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 28)
            }
        }
    }

    // MARK: - Explanation Section

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let explanation = modification.detailedExplanation {
                Text(explanation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Trigger explanation
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))

                Text(modification.trigger.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Exercise Changes Section

    private func exerciseChangesSection(_ changes: [ExerciseModificationDetail]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exercise Changes")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            ForEach(changes.prefix(3)) { change in
                HStack {
                    Text(change.exerciseName)
                        .font(.caption)
                        .foregroundColor(.primary)

                    Spacer()

                    Text(change.changeSummary)
                        .font(.caption)
                        .foregroundColor(changeColor(for: change))
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            if changes.count > 3 {
                Text("+\(changes.count - 3) more changes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Decline button
            Button {
                performAction(onDecline)
            } label: {
                HStack {
                    Image(systemName: "xmark")
                    Text("Train Full")
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(isProcessing)
            .accessibilityLabel("Decline modification and train at full intensity")

            // Modify button (optional)
            if let onModify = onModify {
                Button {
                    onModify()
                } label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Modify")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(isProcessing)
                .accessibilityLabel("Customize the modification")
            }

            // Accept button
            Button {
                performAction(onAccept)
            } label: {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark")
                    }
                    Text("Accept")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(acceptButtonColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(isProcessing)
            .accessibilityLabel("Accept the suggested modification")
        }
        .padding()
    }

    // MARK: - Helper Views

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(triggerColor.opacity(0.3), lineWidth: 1)
            )
    }

    // MARK: - Colors

    private var triggerColor: Color {
        switch modification.modificationType {
        case .loadAdjustment where (modification.loadAdjustmentPercentage ?? 0) > 0:
            return .green
        case .skipWorkout, .triggerDeload:
            return .red
        case .insertRecoveryDay:
            return .blue
        case .workoutDelay:
            return .orange
        default:
            return .orange
        }
    }

    private var acceptButtonColor: Color {
        switch modification.modificationType {
        case .loadAdjustment where (modification.loadAdjustmentPercentage ?? 0) > 0:
            return .green
        default:
            return .blue
        }
    }

    private func readinessColor(for score: Double) -> Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }

    private func changeColor(for change: ExerciseModificationDetail) -> Color {
        if let percentage = change.loadChangePercentage {
            return percentage >= 0 ? .green : .orange
        }
        return .secondary
    }

    // MARK: - Actions

    private func performAction(_ action: @escaping () -> Void) {
        isProcessing = true
        HapticService.shared.trigger(.medium)
        action()
        // Processing state will be managed by parent
    }
}

// MARK: - Compact Variant

/// Compact version of the modification card for inline display
struct WorkoutModificationCardCompact: View {
    let modification: WorkoutModification
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: modification.modificationType.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.15))
                    .clipShape(Circle())

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text("Adjustment Suggested")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)

                    Text(modification.primaryDisplayText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Workout adjustment suggested: \(modification.primaryDisplayText)")
        .accessibilityHint("Tap to view details and respond")
    }

    private var iconColor: Color {
        switch modification.modificationType {
        case .loadAdjustment where (modification.loadAdjustmentPercentage ?? 0) > 0:
            return .green
        case .skipWorkout, .triggerDeload:
            return .red
        default:
            return .orange
        }
    }
}

// MARK: - Preview

#Preview("Full Card") {
    VStack(spacing: 20) {
        WorkoutModificationCard(
            modification: WorkoutModification(
                id: UUID(),
                patientId: UUID(),
                scheduledSessionId: UUID(),
                sessionName: "Upper Body Strength",
                scheduledDate: Date(),
                modificationType: .loadAdjustment,
                trigger: .lowReadiness,
                status: .pending,
                readinessScore: 58,
                fatigueScore: nil,
                loadAdjustmentPercentage: -20,
                volumeReductionSets: 1,
                delayDays: nil,
                deloadDurationDays: nil,
                exerciseModifications: [
                    ExerciseModificationDetail(
                        exerciseId: UUID(),
                        exerciseName: "Bench Press",
                        originalLoad: 185,
                        suggestedLoad: 148,
                        originalSets: nil,
                        suggestedSets: nil,
                        originalReps: nil,
                        suggestedReps: nil,
                        swapExerciseId: nil,
                        swapExerciseName: nil,
                        reason: nil
                    )
                ],
                reason: "Readiness score is below optimal (58/100)",
                detailedExplanation: "Reducing intensity will help you complete a quality session while respecting your current recovery state.",
                createdAt: Date(),
                resolvedAt: nil,
                athleteFeedback: nil
            ),
            onAccept: { print("Accepted") },
            onDecline: { print("Declined") },
            onModify: { print("Modify") }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Compact Card") {
    WorkoutModificationCardCompact(
        modification: WorkoutModification(
            id: UUID(),
            patientId: UUID(),
            scheduledSessionId: nil,
            sessionName: nil,
            scheduledDate: Date(),
            modificationType: .insertRecoveryDay,
            trigger: .lowHRV,
            status: .pending,
            readinessScore: 45,
            fatigueScore: nil,
            loadAdjustmentPercentage: nil,
            volumeReductionSets: nil,
            delayDays: nil,
            deloadDurationDays: nil,
            exerciseModifications: nil,
            reason: "HRV is 25% below baseline",
            detailedExplanation: nil,
            createdAt: Date(),
            resolvedAt: nil,
            athleteFeedback: nil
        ),
        onTap: { print("Tapped") }
    )
    .padding()
}
