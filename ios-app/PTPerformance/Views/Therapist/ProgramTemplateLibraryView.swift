//
//  ProgramTemplateLibraryView.swift
//  PTPerformance
//
//  Template library for saving and reusing program structures
//

import SwiftUI

/// Main view for browsing and managing program templates
struct ProgramTemplateLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProgramTemplateViewModel()

    // Callback when a template is selected to create a program
    var onSelectTemplate: ((ProgramTemplate) -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading templates...")
                } else if !viewModel.hasTemplates {
                    emptyStateView
                } else {
                    templateListView
                }
            }
            .navigationTitle("Template Library")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, prompt: "Search templates")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach([nil] + ProgramType.allCases.map { Optional($0) }, id: \.self) { type in
                            Button {
                                viewModel.selectedProgramType = type
                            } label: {
                                HStack {
                                    if let type = type {
                                        Label(type.displayName, systemImage: type.icon)
                                    } else {
                                        Text("All Types")
                                    }
                                    if viewModel.selectedProgramType == type {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: viewModel.selectedProgramType != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .alert("Success", isPresented: .init(
                get: { viewModel.successMessage != nil },
                set: { if !$0 { viewModel.successMessage = nil } }
            )) {
                Button("OK", role: .cancel) {
                    viewModel.successMessage = nil
                }
            } message: {
                if let message = viewModel.successMessage {
                    Text(message)
                }
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let message = viewModel.errorMessage {
                    Text(message)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        EmptyStateView(
            title: "No Program Templates",
            message: "Save your programs as templates to reuse them with multiple patients. Templates help you create consistent, evidence-based programs efficiently.",
            icon: "doc.on.doc.fill",
            iconColor: .blue,
            action: nil
        )
    }

    // MARK: - Template List

    private var templateListView: some View {
        List {
            // Show filter info if filtering
            if viewModel.selectedProgramType != nil || !viewModel.searchText.isEmpty {
                Section {
                    HStack {
                        Text("\(viewModel.filteredTemplates.count) template(s) found")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        if viewModel.selectedProgramType != nil || !viewModel.searchText.isEmpty {
                            Button("Clear Filters") {
                                viewModel.clearFilters()
                            }
                            .font(.caption)
                        }
                    }
                }
            }

            // No results after filtering
            if viewModel.isFilteredEmpty {
                EmptyStateView(
                    title: "No Matching Templates",
                    message: "No program templates match your current search or filters. Try adjusting your criteria to find more results.",
                    icon: "magnifyingglass",
                    iconColor: .secondary,
                    action: EmptyStateView.EmptyStateAction(
                        title: "Clear Filters",
                        icon: "xmark.circle",
                        action: { viewModel.clearFilters() }
                    )
                )
            } else {
                // Templates grouped by type
                ForEach(ProgramType.allCases) { type in
                    let templatesForType = viewModel.filteredTemplates.filter { $0.programType == type }

                    if !templatesForType.isEmpty {
                        Section {
                            ForEach(templatesForType) { template in
                                TemplateRowView(
                                    template: template,
                                    onSelect: {
                                        onSelectTemplate?(template)
                                        dismiss()
                                    },
                                    onToggleShare: {
                                        viewModel.toggleShared(template)
                                    }
                                )
                            }
                            .onDelete { offsets in
                                let templatesToDelete = offsets.map { templatesForType[$0] }
                                for template in templatesToDelete {
                                    viewModel.deleteTemplate(template)
                                }
                            }
                        } header: {
                            Label(type.displayName, systemImage: type.icon)
                                .foregroundColor(type.color)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Template Row View

struct TemplateRowView: View {
    let template: ProgramTemplate
    var onSelect: (() -> Void)?
    var onToggleShare: (() -> Void)?

    var body: some View {
        Button {
            onSelect?()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Header row
                HStack {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    if template.isShared {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .accessibilityHidden(true)
                    }
                }

                // Description
                if !template.description.isEmpty {
                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Stats row
                HStack(spacing: 16) {
                    Label("\(template.phases.count) phases", systemImage: "list.number")
                    Label("\(template.totalDurationWeeks) weeks", systemImage: "calendar")
                    if template.totalSessionCount > 0 {
                        Label("\(template.totalSessionCount) sessions", systemImage: "figure.run")
                    }
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(template.name)\(template.isShared ? ", shared template" : ""), \(template.phases.count) phases, \(template.totalDurationWeeks) weeks\(template.totalSessionCount > 0 ? ", \(template.totalSessionCount) sessions" : "")")
        .accessibilityHint("Double tap to use this template, swipe for more options")
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                // Handled by onDelete modifier
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                onToggleShare?()
            } label: {
                Label(
                    template.isShared ? "Unshare" : "Share",
                    systemImage: template.isShared ? "person.fill.xmark" : "person.2.fill"
                )
            }
            .tint(template.isShared ? .orange : .blue)
        }
        .contextMenu {
            Button {
                onSelect?()
            } label: {
                Label("Use Template", systemImage: "plus.circle")
            }

            Button {
                onToggleShare?()
            } label: {
                Label(
                    template.isShared ? "Stop Sharing" : "Share Template",
                    systemImage: template.isShared ? "person.fill.xmark" : "person.2.fill"
                )
            }

            Divider()

            Button(role: .destructive) {
                // Delete handled through swipe
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Save Template Sheet

struct ProgramSaveTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProgramTemplateViewModel

    let programName: String
    let programType: ProgramType
    let phases: [ProgramPhase]

    @State private var templateName: String = ""
    @State private var templateDescription: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Template Details") {
                    TextField("Template Name", text: $templateName)
                        .textInputAutocapitalization(.words)

                    TextField("Description (optional)", text: $templateDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Program Info") {
                    LabeledContent("Type", value: programType.displayName)
                    LabeledContent("Phases", value: "\(phases.count)")
                    LabeledContent("Total Duration", value: "\(phases.reduce(0) { $0 + $1.durationWeeks }) weeks")
                }

                Section {
                    ForEach(Array(phases.enumerated()), id: \.element.id) { _, phase in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(phase.name)
                                .font(.subheadline)
                            Text("\(phase.durationWeeks) weeks, \(phase.sessions.count) sessions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Phases to Save")
                }
            }
            .navigationTitle("Save as Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveTemplate(
                            name: templateName,
                            description: templateDescription,
                            programType: programType,
                            phases: phases
                        )
                        dismiss()
                    }
                    .disabled(templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                // Pre-fill with program name
                templateName = programName.isEmpty ? "" : "\(programName) Template"
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ProgramTemplateLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramTemplateLibraryView { template in
            print("Selected template: \(template.name)")
        }

        ProgramSaveTemplateSheet(
            viewModel: ProgramTemplateViewModel(),
            programName: "ACL Recovery",
            programType: .rehab,
            phases: [
                ProgramPhase(name: "Phase 1", durationWeeks: 2, sessions: [], order: 1),
                ProgramPhase(name: "Phase 2", durationWeeks: 4, sessions: [], order: 2)
            ]
        )
        .previewDisplayName("Save Template Sheet")
    }
}
#endif
