//
//  ReviewApprovalSheet.swift
//  PTPerformance
//
//  ACP-395: Review and Approval Workflow
//  Bottom sheet for the final approval, revision request, or rejection flow
//

import SwiftUI

// MARK: - Review Approval Sheet

/// Bottom sheet for the program approval/rejection workflow.
///
/// Provides a segmented control to choose between Approve, Request Revision, and Reject.
/// Includes required checkboxes for safety verification, a notes text field
/// (required for rejection, optional for approval), and submit/cancel actions.
struct ReviewApprovalSheet: View {

    // MARK: - Properties

    let review: ProgramReview
    let onApprove: (String) -> Void
    let onReject: (String) -> Void
    let onRequestRevision: (String) -> Void

    // MARK: - State

    @Environment(\.dismiss) private var dismiss
    @State private var selectedAction: ReviewAction = .approve
    @State private var notes = ""
    @State private var contraindicationsReviewed = false
    @State private var exercisesVerified = false
    @State private var isSubmitting = false

    // MARK: - Computed Properties

    private var canSubmit: Bool {
        guard contraindicationsReviewed && exercisesVerified else { return false }
        guard !isSubmitting else { return false }

        switch selectedAction {
        case .approve:
            return true
        case .requestRevision:
            return !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .reject:
            return !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private var submitButtonTitle: String {
        switch selectedAction {
        case .approve:
            return "Approve Program"
        case .requestRevision:
            return "Request Revision"
        case .reject:
            return "Reject Program"
        }
    }

    private var submitButtonColor: Color {
        switch selectedAction {
        case .approve:
            return DesignTokens.statusSuccess
        case .requestRevision:
            return DesignTokens.statusWarning
        case .reject:
            return DesignTokens.statusError
        }
    }

    private var submitButtonIcon: String {
        switch selectedAction {
        case .approve:
            return "checkmark.seal.fill"
        case .requestRevision:
            return "arrow.triangle.2.circlepath"
        case .reject:
            return "xmark.seal.fill"
        }
    }

    private var notesRequired: Bool {
        selectedAction == .reject || selectedAction == .requestRevision
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Program summary header
                    programSummary

                    // Action picker
                    actionPicker

                    // Checklist
                    checklistSection

                    // Notes
                    notesSection

                    // Warning for critical contraindications
                    if selectedAction == .approve && review.hasCriticalContraindications {
                        criticalWarning
                    }

                    // Submit button
                    submitButton

                    // Cancel button
                    cancelButton
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xl)
            }
            .navigationTitle("Review Decision")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .interactiveDismissDisabled(isSubmitting)
        }
    }

    // MARK: - Program Summary

    private var programSummary: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text("Program Review")
                        .font(.headline)

                    Spacer()

                    if let confidence = review.aiConfidenceScore {
                        AIConfidenceBadge(score: confidence)
                    }
                }

                HStack(spacing: Spacing.xs) {
                    if review.aiGenerated {
                        Image(systemName: "cpu")
                            .font(.caption)
                            .foregroundColor(DesignTokens.statusInfo)
                            .accessibilityHidden(true)

                        Text(review.aiModel ?? "AI Generated")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("\(review.editCount) \(review.editCount == 1 ? "edit" : "edits")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Contraindication count
                if !review.contraindications.isEmpty {
                    let criticalCount = review.contraindications.filter { $0.severity == .critical }.count
                    let warningCount = review.contraindications.filter { $0.severity == .warning }.count

                    HStack(spacing: Spacing.xs) {
                        if criticalCount > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "exclamationmark.octagon.fill")
                                    .font(.caption2)
                                Text("\(criticalCount) critical")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(DesignTokens.statusError)
                        }

                        if warningCount > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                Text("\(warningCount) \(warningCount == 1 ? "warning" : "warnings")")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(DesignTokens.statusWarning)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Action Picker

    private var actionPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Decision")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            Picker("Review Action", selection: $selectedAction) {
                Text("Approve").tag(ReviewAction.approve)
                Text("Revise").tag(ReviewAction.requestRevision)
                Text("Reject").tag(ReviewAction.reject)
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedAction) { _, _ in
                HapticFeedback.selectionChanged()
            }
        }
    }

    // MARK: - Checklist Section

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Verification Checklist")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            ReviewChecklistItem(
                isChecked: $contraindicationsReviewed,
                title: "I have reviewed all contraindications",
                description: review.contraindications.isEmpty
                    ? "No contraindications were flagged for this program."
                    : "\(review.contraindications.count) \(review.contraindications.count == 1 ? "contraindication" : "contraindications") flagged for review.",
                icon: "shield.checkered"
            )

            ReviewChecklistItem(
                isChecked: $exercisesVerified,
                title: "I have verified exercise selections are appropriate",
                description: "Confirmed that all exercises are suitable for this patient's condition and goals.",
                icon: "figure.run"
            )
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(selectedAction == .approve ? "Notes (Optional)" : "Notes (Required)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                if notesRequired {
                    Text("*")
                        .font(.subheadline)
                        .foregroundColor(DesignTokens.statusError)
                }
            }

            TextEditor(text: $notes)
                .frame(minHeight: 80)
                .padding(Spacing.xs)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .stroke(Color(.separator), lineWidth: 1)
                )
                .accessibilityLabel(selectedAction == .approve ? "Optional notes" : "Required notes")

            if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && notesRequired {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.caption2)
                    Text(selectedAction == .reject ? "A rejection reason is required." : "Revision notes are required.")
                        .font(.caption)
                }
                .foregroundColor(DesignTokens.statusError)
            }
        }
    }

    // MARK: - Critical Warning

    private var criticalWarning: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.octagon.fill")
                .font(.title3)
                .foregroundColor(DesignTokens.statusError)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Critical Contraindications Present")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.statusError)

                Text("This program has critical contraindications flagged. By approving, you confirm these have been addressed or are acceptable for this patient.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(Spacing.sm)
        .background(DesignTokens.statusError.opacity(0.08))
        .cornerRadius(CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(DesignTokens.statusError.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Warning: Critical contraindications present. By approving, you confirm these have been addressed.")
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            HapticFeedback.medium()
            isSubmitting = true

            switch selectedAction {
            case .approve:
                onApprove(notes)
            case .requestRevision:
                onRequestRevision(notes)
            case .reject:
                onReject(notes)
            }
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: submitButtonIcon)
                    Text(submitButtonTitle)
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(canSubmit ? submitButtonColor : Color.gray)
            .cornerRadius(CornerRadius.md)
        }
        .disabled(!canSubmit)
        .accessibilityLabel(submitButtonTitle)
        .accessibilityHint(canSubmit ? "Double tap to submit" : "Complete all required fields first")
    }

    // MARK: - Cancel Button

    private var cancelButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Cancel")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
        }
        .accessibilityLabel("Cancel review decision")
    }
}

// MARK: - Review Action Enum

enum ReviewAction: String, CaseIterable {
    case approve = "Approve"
    case requestRevision = "Request Revision"
    case reject = "Reject"
}

// MARK: - Review Checklist Item

struct ReviewChecklistItem: View {
    @Binding var isChecked: Bool
    let title: String
    let description: String
    let icon: String

    var body: some View {
        Button {
            HapticFeedback.toggle()
            withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                isChecked.toggle()
            }
        } label: {
            HStack(alignment: .top, spacing: Spacing.sm) {
                // Checkbox
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(isChecked ? DesignTokens.statusSuccess : .secondary)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundColor(DesignTokens.statusInfo)
                            .accessibilityHidden(true)

                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding(Spacing.sm)
            .background(isChecked ? DesignTokens.statusSuccess.opacity(0.05) : Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(isChecked ? DesignTokens.statusSuccess.opacity(0.3) : Color(.separator), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
        .accessibilityValue(isChecked ? "Checked" : "Unchecked")
        .accessibilityHint("Double tap to \(isChecked ? "uncheck" : "check")")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Approval Sheet - Default") {
    ReviewApprovalSheet(
        review: ProgramReview.samplePending,
        onApprove: { _ in },
        onReject: { _ in },
        onRequestRevision: { _ in }
    )
}

#Preview("Approval Sheet - With Critical Contraindications") {
    ReviewApprovalSheet(
        review: ProgramReview.sampleRejected,
        onApprove: { _ in },
        onReject: { _ in },
        onRequestRevision: { _ in }
    )
}

#Preview("Checklist Items") {
    VStack(spacing: Spacing.sm) {
        ReviewChecklistItem(
            isChecked: .constant(false),
            title: "I have reviewed all contraindications",
            description: "2 contraindications flagged for review.",
            icon: "shield.checkered"
        )

        ReviewChecklistItem(
            isChecked: .constant(true),
            title: "I have verified exercise selections",
            description: "Confirmed that all exercises are suitable.",
            icon: "figure.run"
        )
    }
    .padding()
}
#endif
