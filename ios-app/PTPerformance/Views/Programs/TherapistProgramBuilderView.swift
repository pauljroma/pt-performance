//
//  TherapistProgramBuilderView.swift
//  PTPerformance
//
//  Therapist-side UI for building training programs (like "Foundation" 12-month programs)
//  Creates programs for the program_library for patients to browse and enroll
//

import SwiftUI

struct TherapistProgramBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TherapistProgramBuilderViewModel()

    @State private var showPhaseEditor = false
    @State private var editingPhaseIndex: Int?
    @State private var showPublishConfirmation = false
    // ACP-515: Removed showDeletePhaseAlert - using undo pattern instead

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Program Metadata
                programMetadataSection

                // MARK: - Phases
                phasesSection

                // MARK: - Actions
                actionsSection

                // MARK: - Error/Success Messages
                if let error = viewModel.errorMessage {
                    errorSection(error)
                }

                if let success = viewModel.successMessage {
                    successSection(success)
                }
            }
            .navigationTitle("Program Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Draft") {
                        Task {
                            await saveDraft()
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                }
            }
            .sheet(isPresented: $showPhaseEditor) {
                if let index = editingPhaseIndex {
                    PhaseEditorSheet(
                        phase: $viewModel.phases[index],
                        phaseNumber: index + 1,
                        isPresented: $showPhaseEditor
                    )
                }
            }
            .alert("Publish to Library?", isPresented: $showPublishConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Publish") {
                    Task {
                        await publishToLibrary()
                    }
                }
            } message: {
                Text("This will make the program available for patients to browse and enroll. You can edit or unpublish it later.")
            }
            // ACP-515: Removed delete phase confirmation dialog - using undo pattern instead
            .withUndoToasts()
        }
    }

    // ACP-515: Delete phase with undo support
    private func deletePhaseWithUndo(at index: Int) {
        guard index >= 0 && index < viewModel.phases.count else { return }

        // Store phase for potential undo
        let deletedPhase = viewModel.phases[index]
        let phaseName = deletedPhase.name.isEmpty ? "Phase \(index + 1)" : deletedPhase.name

        // Delete immediately
        viewModel.deletePhase(at: index)

        // Register undo action
        PTUndoManager.shared.registerDeletePhase(
            phaseIndex: index,
            phaseName: phaseName
        ) { [weak viewModel] in
            // Restore the phase at the original position
            viewModel?.phases.insert(deletedPhase, at: min(index, viewModel?.phases.count ?? 0))
        }
    }

    // MARK: - Program Metadata Section

    private var programMetadataSection: some View {
        Section {
            TextField("Program Name", text: $viewModel.programName)
                .textInputAutocapitalization(.words)
                .accessibilityLabel("Program Name")

            VStack(alignment: .leading, spacing: 4) {
                Text("Description")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextEditor(text: $viewModel.description)
                    .frame(minHeight: 80)
            }

            Picker("Category", selection: $viewModel.category) {
                ForEach(ProgramCategory.allCases, id: \.self) { category in
                    Label(category.displayName, systemImage: category.icon)
                        .tag(category.rawValue)
                }
            }

            Picker("Difficulty", selection: $viewModel.difficultyLevel) {
                ForEach(DifficultyLevel.allCases, id: \.self) { level in
                    Text(level.displayName)
                        .tag(level.rawValue)
                }
            }

            Stepper(
                "Duration: \(viewModel.durationWeeks) \(viewModel.durationWeeks == 1 ? "week" : "weeks")",
                value: $viewModel.durationWeeks,
                in: 1...52
            )

            // Equipment required
            VStack(alignment: .leading, spacing: 8) {
                Text("Equipment Required")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Add equipment (comma separated)", text: $viewModel.equipmentInput)
                    .textInputAutocapitalization(.words)
                    .onSubmit {
                        viewModel.addEquipmentFromInput()
                    }

                if !viewModel.equipmentRequired.isEmpty {
                    EquipmentFlowLayout(spacing: 6) {
                        ForEach(viewModel.equipmentRequired, id: \.self) { equipment in
                            EquipmentChip(name: equipment) {
                                viewModel.removeEquipment(equipment)
                            }
                        }
                    }
                }
            }

            // Tags
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Add tags (comma separated)", text: $viewModel.tagsInput)
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        viewModel.addTagsFromInput()
                    }

                if !viewModel.tags.isEmpty {
                    TagsFlowLayout(spacing: 6) {
                        ForEach(viewModel.tags, id: \.self) { tag in
                            TagChipRemovable(text: tag) {
                                viewModel.removeTag(tag)
                            }
                        }
                    }
                }
            }
        } header: {
            Text("Program Details")
        }
    }

    // MARK: - Phases Section

    private var phasesSection: some View {
        Section {
            if viewModel.phases.isEmpty {
                emptyPhasesView
            } else {
                ForEach(Array(viewModel.phases.enumerated()), id: \.element.id) { index, phase in
                    PhaseListRow(
                        phase: phase,
                        phaseNumber: index + 1,
                        onEdit: {
                            editingPhaseIndex = index
                            showPhaseEditor = true
                        },
                        onDelete: {
                            // ACP-515: Delete immediately with undo support
                            deletePhaseWithUndo(at: index)
                        }
                    )
                }
                .onMove(perform: viewModel.movePhases)
            }

            Button {
                viewModel.addPhase()
                editingPhaseIndex = viewModel.phases.count - 1
                showPhaseEditor = true
            } label: {
                Label("Add Phase", systemImage: "plus.circle.fill")
            }
        } header: {
            HStack {
                Text("Phases (\(viewModel.phases.count))")
                Spacer()
                if !viewModel.phases.isEmpty {
                    EditButton()
                        .font(.caption)
                }
            }
        } footer: {
            if !viewModel.phases.isEmpty {
                Text("Total duration: \(viewModel.totalPhaseDuration) weeks")
                    .font(.caption)
            }
        }
    }

    // MARK: - Empty Phases View

    private var emptyPhasesView: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "calendar.badge.plus")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
                Text("No phases yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Add phases to structure your program")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, Spacing.lg)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("No phases yet. Add phases to structure your program.")
            Spacer()
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        Section {
            Button {
                showPublishConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Label("Publish to Library", systemImage: "arrow.up.doc.fill")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .disabled(!viewModel.isReadyToPublish || viewModel.isLoading)
            .foregroundColor(viewModel.isReadyToPublish ? .modusCyan : .secondary)
        } footer: {
            if !viewModel.isReadyToPublish {
                Text("Add at least one phase with workouts to publish")
                    .font(.caption)
            }
        }
    }

    // MARK: - Error Section

    private func errorSection(_ error: String) -> some View {
        Section {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Success Section

    private func successSection(_ success: String) -> some View {
        Section {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text(success)
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }

    // MARK: - Actions

    private func saveDraft() async {
        do {
            _ = try await viewModel.createProgram()
        } catch {
            // Error is already handled in viewModel
        }
    }

    private func publishToLibrary() async {
        do {
            try await viewModel.publishToLibrary()
            dismiss()
        } catch {
            // Error is already handled in viewModel
        }
    }
}

// MARK: - Phase List Row

private struct PhaseListRow: View {
    let phase: TherapistPhaseData
    let phaseNumber: Int
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack {
                // Phase number badge
                Text("\(phaseNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(phaseColor))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(phase.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Text("\(phase.durationWeeks) weeks")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("-")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("\(phase.workoutAssignments.count) workouts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !phase.goals.isEmpty {
                        Text(phase.goals)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Phase \(phaseNumber): \(phase.name), \(phase.durationWeeks) weeks, \(phase.workoutAssignments.count) workouts")
        .accessibilityHint("Double tap to edit phase, swipe left to delete")
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var phaseColor: Color {
        let colors: [Color] = [.modusCyan, .purple, .orange, .green, .pink, .teal]
        return colors[(phaseNumber - 1) % colors.count]
    }
}

// MARK: - Equipment Chip

private struct EquipmentChip: View {
    let name: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(name)
                .font(.caption)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Remove \(name)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Tag Chip Removable

private struct TagChipRemovable: View {
    let text: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text("#\(text)")
                .font(.caption)
                .foregroundColor(.modusCyan)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Remove tag \(text)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.modusCyan.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Flow Layouts

private struct EquipmentFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0
        let maxAllowedWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxAllowedWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX - spacing)
        }
        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

private struct TagsFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0
        let maxAllowedWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxAllowedWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX - spacing)
        }
        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

// MARK: - Preview

#if DEBUG
struct TherapistProgramBuilderView_Previews: PreviewProvider {
    static var previews: some View {
        TherapistProgramBuilderView()
    }
}
#endif
