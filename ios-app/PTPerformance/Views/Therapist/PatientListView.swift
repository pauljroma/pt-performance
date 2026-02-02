import SwiftUI

/// Therapist's patient list view with search and filtering
struct PatientListView: View {
    let therapistId: String

    @StateObject private var viewModel = PatientListViewModel()
    @State private var showFilterSheet = false
    @State private var showBulkAssignmentSheet = false
    @State private var showExportShareSheet = false
    @State private var exportedSummary: String = ""

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Loading patients...")
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task {
                        await viewModel.refresh()
                    }
                }
            } else {
                patientList
            }

            // Floating action bar when patients are selected
            if viewModel.isSelectionModeActive && viewModel.selectedCount > 0 {
                VStack {
                    Spacer()
                    BulkActionBar(
                        selectedCount: viewModel.selectedCount,
                        onAssignProgram: {
                            showBulkAssignmentSheet = true
                        },
                        onExportSummary: {
                            exportedSummary = viewModel.generateBulkSummary(patientIds: viewModel.selectedPatientIds)
                            showExportShareSheet = true
                        },
                        onClearSelection: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.deselectAll()
                            }
                            HapticFeedback.light()
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.selectedCount > 0)
            }
        }
        .navigationTitle(viewModel.isSelectionModeActive ? "\(viewModel.selectedCount) Selected" : "Patients")
        .searchable(text: $viewModel.searchText, prompt: "Search patients")
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.applyFilters()
        }
        .toolbar {
            // Leading toolbar items
            ToolbarItem(placement: .navigationBarLeading) {
                if viewModel.isSelectionModeActive {
                    Button(viewModel.allFilteredPatientsSelected ? "Deselect All" : "Select All") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if viewModel.allFilteredPatientsSelected {
                                viewModel.deselectAll()
                            } else {
                                viewModel.selectAll()
                            }
                        }
                        HapticFeedback.selectionChanged()
                    }
                    .accessibilityLabel(viewModel.allFilteredPatientsSelected ? "Deselect all patients" : "Select all patients")
                }
            }

            // Trailing toolbar items
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if !viewModel.isSelectionModeActive {
                    Button(action: { showFilterSheet = true }) {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filter patients")
                }

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.toggleSelectionMode()
                    }
                    HapticFeedback.medium()
                }) {
                    Text(viewModel.isSelectionModeActive ? "Done" : "Select")
                }
                .accessibilityLabel(viewModel.isSelectionModeActive ? "Exit selection mode" : "Enter selection mode")
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showBulkAssignmentSheet) {
            BulkProgramAssignmentSheet(
                viewModel: viewModel,
                therapistId: therapistId,
                onDismiss: {
                    showBulkAssignmentSheet = false
                }
            )
        }
        .sheet(isPresented: $showExportShareSheet) {
            ShareSheet(items: [exportedSummary])
        }
        .refreshable {
            await viewModel.refresh(therapistId: therapistId)
        }
        .task {
            await viewModel.fetchPatients(for: therapistId)
        }
    }

    private var patientList: some View {
        List {
            if viewModel.filteredPatients.isEmpty {
                let hasFilters = !viewModel.searchText.isEmpty || viewModel.selectedFlagFilter != .all || viewModel.selectedSport != nil
                EmptyStateView(
                    title: "No Patients Found",
                    message: hasFilters
                        ? "No patients match your current filters. Try adjusting your search criteria or clearing the filters to see all patients."
                        : "Your patient caseload is empty. Patients will appear here once they are assigned to you.",
                    icon: "person.2.slash",
                    iconColor: .secondary,
                    action: hasFilters ? EmptyStateView.EmptyStateAction(
                        title: "Clear Filters",
                        icon: "xmark.circle",
                        action: {
                            viewModel.searchText = ""
                            viewModel.selectedFlagFilter = .all
                            viewModel.selectedSport = nil
                            viewModel.applyFilters()
                        }
                    ) : nil
                )
            } else {
                ForEach(viewModel.filteredPatients) { patient in
                    if viewModel.isSelectionModeActive {
                        SelectablePatientRow(
                            patient: patient,
                            isSelected: viewModel.isSelected(patientId: patient.id),
                            onToggle: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    viewModel.toggleSelection(patientId: patient.id)
                                }
                                HapticFeedback.selectionChanged()
                            }
                        )
                    } else {
                        NavigationLink(destination: PatientDetailView(patient: patient)) {
                            PatientRowCard(patient: patient)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                HapticFeedback.medium()
                                // Quick action: View progress report
                                // Navigation handled via NavigationLink
                            } label: {
                                Label("Report", systemImage: "chart.bar.doc.horizontal")
                            }
                            .tint(.purple)

                            Button {
                                HapticFeedback.medium()
                                showBulkAssignmentSheet = true
                                viewModel.toggleSelection(patientId: patient.id)
                            } label: {
                                Label("Assign", systemImage: "doc.badge.plus")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                HapticFeedback.success()
                                // Quick select for bulk actions
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if !viewModel.isSelectionModeActive {
                                        viewModel.toggleSelectionMode()
                                    }
                                    viewModel.toggleSelection(patientId: patient.id)
                                }
                            } label: {
                                Label("Select", systemImage: "checkmark.circle")
                            }
                            .tint(.green)
                        }
                        .contextMenu {
                            Button {
                                HapticFeedback.light()
                            } label: {
                                Label("View Profile", systemImage: "person.circle")
                            }

                            Button {
                                HapticFeedback.light()
                                showBulkAssignmentSheet = true
                                viewModel.toggleSelection(patientId: patient.id)
                            } label: {
                                Label("Assign Program", systemImage: "doc.badge.plus")
                            }

                            Divider()

                            Button {
                                HapticFeedback.light()
                                // Copy patient name
                                UIPasteboard.general.string = patient.fullName
                            } label: {
                                Label("Copy Name", systemImage: "doc.on.doc")
                            }

                            if let adherence = patient.adherencePercentage {
                                Button {
                                    HapticFeedback.light()
                                    let summary = "\(patient.fullName): \(Int(adherence))% adherence"
                                    UIPasteboard.general.string = summary
                                } label: {
                                    Label("Copy Stats", systemImage: "chart.bar")
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Selectable Patient Row

/// Patient row with selection checkbox for multi-select mode
struct SelectablePatientRow: View {
    let patient: Patient
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Selection checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
                    .accessibilityLabel(isSelected ? "Selected" : "Not selected")

                // Patient card content
                PatientRowCard(patient: patient)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(patient.fullName), \(isSelected ? "selected" : "not selected")")
        .accessibilityHint("Double tap to \(isSelected ? "deselect" : "select") this patient")
    }
}

// MARK: - Bulk Action Bar

/// Floating action bar displayed when patients are selected
struct BulkActionBar: View {
    let selectedCount: Int
    let onAssignProgram: () -> Void
    let onExportSummary: () -> Void
    let onClearSelection: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Selected count
            Text("\(selectedCount) selected")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Spacer()

            // Action buttons
            Button(action: {
                HapticFeedback.medium()
                onAssignProgram()
            }) {
                Label("Assign Program", systemImage: "doc.badge.plus")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .accessibilityLabel("Assign program to \(selectedCount) patients")

            Button(action: {
                HapticFeedback.medium()
                onExportSummary()
            }) {
                Label("Export", systemImage: "square.and.arrow.up")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .accessibilityLabel("Export summary for \(selectedCount) patients")

            Button(action: onClearSelection) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Clear selection")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .adaptiveShadow(Shadow.prominent)
        )
    }
}

// ShareSheet is defined in Utils/ShareSheet.swift

// MARK: - Patient Row Card

struct PatientRowCard: View {
    let patient: Patient

    var body: some View {
        HStack(spacing: 16) {
            // Avatar - uses cached image if profile image exists
            ProfileAvatarImage(
                profileImageUrl: patient.profileImageUrl,
                firstName: patient.firstName,
                lastName: patient.lastName,
                size: 50
            )

            // Patient info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(patient.fullName)
                        .font(.headline)

                    if patient.hasHighSeverityFlags {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                if let sport = patient.sport, let position = patient.position {
                    Text("\(sport) - \(position)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    // Flag count
                    if let flagCount = patient.flagCount, flagCount > 0 {
                        Label("\(flagCount)", systemImage: "flag.fill")
                            .font(.caption)
                            .foregroundColor(patient.hasHighSeverityFlags ? .red : .orange)
                    }

                    // Adherence
                    if let adherence = patient.adherencePercentage {
                        Label("\(Int(adherence))%", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(adherenceColor(adherence))
                    }

                    // Last session
                    if let lastSession = patient.lastSessionDate {
                        Text(lastSession, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }

    private func adherenceColor(_ percentage: Double) -> Color {
        switch percentage {
        case 80...: return .green
        case 60..<80: return .yellow
        default: return .red
        }
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @ObservedObject var viewModel: PatientListViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                // Flag filter
                Section("Risk Level") {
                    Picker("Filter", selection: $viewModel.selectedFlagFilter) {
                        ForEach(PatientListViewModel.FlagFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Sport filter
                Section("Sport") {
                    Picker("Sport", selection: $viewModel.selectedSport) {
                        Text("All Sports").tag(nil as String?)
                        ForEach(viewModel.availableSports, id: \.self) { sport in
                            Text(sport).tag(sport as String?)
                        }
                    }
                }

                // Active filters summary
                Section("Active Filters") {
                    if viewModel.selectedFlagFilter != .all {
                        HStack {
                            Text("Risk Level")
                            Spacer()
                            Text(viewModel.selectedFlagFilter.rawValue)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let sport = viewModel.selectedSport {
                        HStack {
                            Text("Sport")
                            Spacer()
                            Text(sport)
                                .foregroundColor(.secondary)
                        }
                    }

                    if viewModel.selectedFlagFilter == .all && viewModel.selectedSport == nil {
                        Text("No filters applied")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            .navigationTitle("Filter Patients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        viewModel.selectedFlagFilter = .all
                        viewModel.selectedSport = nil
                        viewModel.applyFilters()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.applyFilters()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PatientListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PatientListView(therapistId: "therapist-1")
        }
    }
}
#endif
