//
//  ProgramDiffView.swift
//  PTPerformance
//
//  ACP-395: Review and Approval Workflow
//  Shows differences between AI-generated program and therapist edits
//

import SwiftUI

// MARK: - Program Diff View

/// Displays a detailed diff of all changes the therapist made to the AI-generated program.
///
/// Shows a summary of modifications at the top, followed by individual edit rows.
/// Each change displays the field changed and old/new values with color coding.
/// Supports inline and side-by-side display modes, plus per-change revert.
struct ProgramDiffView: View {

    // MARK: - Properties

    let edits: [ProgramEdit]

    // MARK: - State

    @State private var displayMode: DiffDisplayMode = .inline
    @State private var showRevertAlert = false
    @State private var editToRevert: ProgramEdit?
    @State private var revertedEdits: Set<UUID> = []

    // MARK: - Computed Properties

    private var activeEdits: [ProgramEdit] {
        edits.filter { !revertedEdits.contains($0.id) }
    }

    /// Classify edits: if oldValue is empty it's an addition, if newValue is empty it's a removal,
    /// otherwise it's a modification.
    private var modifiedCount: Int {
        activeEdits.filter { !$0.oldValue.isEmpty && !$0.newValue.isEmpty }.count
    }

    private var addedCount: Int {
        activeEdits.filter { $0.oldValue.isEmpty && !$0.newValue.isEmpty }.count
    }

    private var removedCount: Int {
        activeEdits.filter { !$0.oldValue.isEmpty && $0.newValue.isEmpty }.count
    }

    /// Group edits by the field they changed for visual organization
    private var groupedByField: [(field: String, edits: [ProgramEdit])] {
        let grouped = activeEdits.safeGrouped { $0.fieldChanged }
        return grouped.sorted { $0.key < $1.key }.map { (field: $0.key, edits: $0.value) }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                // Summary header
                summaryCard

                // Display mode toggle
                displayModePicker

                // Changes list
                if activeEdits.isEmpty {
                    noChangesView
                } else {
                    ForEach(groupedByField, id: \.field) { group in
                        fieldSection(field: group.field, edits: group.edits)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
        }
        .navigationTitle("Changes")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Revert Change", isPresented: $showRevertAlert) {
            Button("Cancel", role: .cancel) {
                editToRevert = nil
            }
            Button("Revert", role: .destructive) {
                if let edit = editToRevert {
                    withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                        revertedEdits.insert(edit.id)
                    }
                    HapticFeedback.medium()
                    editToRevert = nil
                }
            }
        } message: {
            if let edit = editToRevert {
                Text("Revert the change to \"\(edit.fieldChanged)\"? This will restore the original AI-generated value of \"\(edit.oldValue)\".")
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(DesignTokens.statusInfo)
                    Text("Change Summary")
                        .font(.headline)
                }
                .accessibilityAddTraits(.isHeader)

                Divider()

                HStack(spacing: Spacing.lg) {
                    DiffStatView(
                        count: modifiedCount,
                        label: "Modified",
                        color: DesignTokens.statusWarning,
                        icon: "pencil.circle.fill"
                    )

                    DiffStatView(
                        count: addedCount,
                        label: "Added",
                        color: DesignTokens.statusSuccess,
                        icon: "plus.circle.fill"
                    )

                    DiffStatView(
                        count: removedCount,
                        label: "Removed",
                        color: DesignTokens.statusError,
                        icon: "minus.circle.fill"
                    )
                }

                if !revertedEdits.isEmpty {
                    Divider()

                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(revertedEdits.count) \(revertedEdits.count == 1 ? "change" : "changes") reverted")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Change summary: \(modifiedCount) modified, \(addedCount) added, \(removedCount) removed")
    }

    // MARK: - Display Mode Picker

    private var displayModePicker: some View {
        Picker("Display Mode", selection: $displayMode) {
            Label("Inline", systemImage: "list.bullet")
                .tag(DiffDisplayMode.inline)
            Label("Side by Side", systemImage: "rectangle.split.2x1")
                .tag(DiffDisplayMode.sideBySide)
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Diff display mode")
        .onChange(of: displayMode) { _, _ in
            HapticFeedback.selectionChanged()
        }
    }

    // MARK: - Field Section

    private func fieldSection(field: String, edits: [ProgramEdit]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Field header
            HStack {
                Image(systemName: "pencil")
                    .foregroundColor(DesignTokens.statusInfo)
                    .font(.subheadline)

                Text(field)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("(\(edits.count) \(edits.count == 1 ? "change" : "changes"))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding(.vertical, Spacing.xxs)
            .accessibilityLabel("\(field), \(edits.count) changes")

            ForEach(edits) { edit in
                if displayMode == .inline {
                    InlineDiffRow(edit: edit) {
                        editToRevert = edit
                        showRevertAlert = true
                    }
                } else {
                    SideBySideDiffRow(edit: edit) {
                        editToRevert = edit
                        showRevertAlert = true
                    }
                }
            }
        }
    }

    // MARK: - No Changes View

    private var noChangesView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(DesignTokens.statusSuccess)
                .accessibilityHidden(true)

            Text(revertedEdits.isEmpty ? "No Changes Made" : "All Changes Reverted")
                .font(.title3)
                .fontWeight(.semibold)

            Text(revertedEdits.isEmpty
                ? "The program matches the AI-generated version."
                : "All therapist edits have been reverted to the original values.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Spacing.xxl)
    }
}

// MARK: - Display Mode Enum

enum DiffDisplayMode: String, CaseIterable {
    case inline
    case sideBySide
}

// MARK: - Diff Stat View

struct DiffStatView: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .accessibilityHidden(true)

            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(label.lowercased())")
    }
}

// MARK: - ProgramEdit Change Type (derived)

extension ProgramEdit {
    /// Derived change type based on old/new value content
    var derivedChangeType: DerivedChangeType {
        if oldValue.isEmpty && !newValue.isEmpty {
            return .added
        } else if !oldValue.isEmpty && newValue.isEmpty {
            return .removed
        } else {
            return .modified
        }
    }

    enum DerivedChangeType {
        case modified
        case added
        case removed
    }
}

// MARK: - Inline Diff Row

struct InlineDiffRow: View {
    let edit: ProgramEdit
    let onRevert: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Exercise ID + change type badge
                HStack {
                    Text("Exercise \(edit.exerciseId.uuidString.prefix(8))...")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    changeTypeBadge
                }

                // Field changed
                Text(edit.fieldChanged)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                // Value diff
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    if edit.derivedChangeType != .added {
                        // Old value (red)
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "minus")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(DesignTokens.statusError)
                            Text(edit.oldValue)
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.statusError)
                                .strikethrough()
                        }
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(DesignTokens.statusError.opacity(0.08))
                        .cornerRadius(CornerRadius.xs)
                    }

                    if edit.derivedChangeType != .removed {
                        // New value (green)
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "plus")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(DesignTokens.statusSuccess)
                            Text(edit.newValue)
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.statusSuccess)
                        }
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(DesignTokens.statusSuccess.opacity(0.08))
                        .cornerRadius(CornerRadius.xs)
                    }
                }

                // Revert button
                HStack {
                    Spacer()

                    Button {
                        HapticFeedback.light()
                        onRevert()
                    } label: {
                        Label("Revert", systemImage: "arrow.uturn.backward")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.secondary)
                    .accessibilityLabel("Revert change to \(edit.fieldChanged)")
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var changeTypeBadge: some View {
        Group {
            switch edit.derivedChangeType {
            case .modified:
                Text("Modified")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(DesignTokens.statusWarning.opacity(0.15))
                    .foregroundColor(DesignTokens.statusWarning)
                    .cornerRadius(CornerRadius.xs)
            case .added:
                Text("Added")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(DesignTokens.statusSuccess.opacity(0.15))
                    .foregroundColor(DesignTokens.statusSuccess)
                    .cornerRadius(CornerRadius.xs)
            case .removed:
                Text("Removed")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(DesignTokens.statusError.opacity(0.15))
                    .foregroundColor(DesignTokens.statusError)
                    .cornerRadius(CornerRadius.xs)
            }
        }
    }
}

// MARK: - Side by Side Diff Row

struct SideBySideDiffRow: View {
    let edit: ProgramEdit
    let onRevert: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Header
                HStack {
                    Text("Exercise \(edit.exerciseId.uuidString.prefix(8))...")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Button {
                        HapticFeedback.light()
                        onRevert()
                    } label: {
                        Label("Revert", systemImage: "arrow.uturn.backward")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.secondary)
                }

                Text(edit.fieldChanged)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                // Side by side comparison
                HStack(spacing: Spacing.xs) {
                    // Original (left)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Original")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(edit.oldValue.isEmpty ? "--" : edit.oldValue)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Spacing.xs)
                            .background(edit.oldValue.isEmpty ? Color(.tertiarySystemFill) : DesignTokens.statusError.opacity(0.08))
                            .cornerRadius(CornerRadius.xs)
                            .foregroundColor(edit.oldValue.isEmpty ? .secondary : DesignTokens.statusError)
                    }
                    .frame(maxWidth: .infinity)

                    // Arrow
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("changed to")

                    // Modified (right)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Modified")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(edit.newValue.isEmpty ? "--" : edit.newValue)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Spacing.xs)
                            .background(edit.newValue.isEmpty ? Color(.tertiarySystemFill) : DesignTokens.statusSuccess.opacity(0.08))
                            .cornerRadius(CornerRadius.xs)
                            .foregroundColor(edit.newValue.isEmpty ? .secondary : DesignTokens.statusSuccess)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Diff View - Inline") {
    NavigationStack {
        ProgramDiffView(edits: [
            ProgramEdit.sampleEdit,
            ProgramEdit.sampleRepsEdit,
            ProgramEdit(
                exerciseId: UUID(),
                fieldChanged: "exercise_added",
                oldValue: "",
                newValue: "Lateral Raises 3x12"
            ),
            ProgramEdit(
                exerciseId: UUID(),
                fieldChanged: "exercise_removed",
                oldValue: "Leg Press 4x10",
                newValue: ""
            )
        ])
    }
}

#Preview("Diff Stat") {
    HStack(spacing: Spacing.lg) {
        DiffStatView(count: 5, label: "Modified", color: DesignTokens.statusWarning, icon: "pencil.circle.fill")
        DiffStatView(count: 2, label: "Added", color: DesignTokens.statusSuccess, icon: "plus.circle.fill")
        DiffStatView(count: 1, label: "Removed", color: DesignTokens.statusError, icon: "minus.circle.fill")
    }
    .padding()
}

#Preview("Inline Diff Row - Modified") {
    InlineDiffRow(
        edit: ProgramEdit.sampleEdit,
        onRevert: {}
    )
    .padding()
}

#Preview("Side by Side Diff Row") {
    SideBySideDiffRow(
        edit: ProgramEdit.sampleRepsEdit,
        onRevert: {}
    )
    .padding()
}
#endif
