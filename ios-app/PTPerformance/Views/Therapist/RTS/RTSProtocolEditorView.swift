// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  RTSProtocolEditorView.swift
//  PTPerformance
//
//  Create or edit Return-to-Sport protocols for patients.
//  Includes sport selection, injury details, timeline configuration, and phase preview.
//

import SwiftUI

// MARK: - RTS Protocol Editor View

/// Create or edit RTS protocols for patients
struct RTSProtocolEditorView: View {
    let patient: Patient
    var existingProtocol: RTSProtocol?

    @StateObject private var viewModel = RTSProtocolViewModel()
    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State

    @State private var hasSurgery = false
    @State private var showSportPicker = false
    @State private var showPhasePreview = false

    private var isEditMode: Bool {
        existingProtocol != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.sports.isEmpty {
                    loadingView
                } else {
                    formContent
                }
            }
            .navigationTitle(isEditMode ? "Edit Protocol" : "New RTS Protocol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(isEditMode ? "Update" : "Create") {
                        createOrUpdateProtocol()
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isFormValid || viewModel.isSaving)
                }
            }
            .task {
                await viewModel.loadSports()
                if let existing = existingProtocol {
                    populateFromExisting(existing)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearMessages()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $showPhasePreview) {
                if let sport = viewModel.selectedSport {
                    PhasePreviewSheet(sport: sport)
                }
            }
        }
    }

    // MARK: - Form Content

    private var formContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Patient header
                patientHeader

                // Sport selection
                sportSection

                // Injury details
                injurySection

                // Timeline
                timelineSection

                // Notes
                notesSection

                // Phase preview
                if let sport = viewModel.selectedSport, !sport.defaultPhases.isEmpty {
                    phasePreviewSection(sport: sport)
                }
            }
            .padding()
            .padding(.bottom, Spacing.xl)
        }
        .disabled(viewModel.isSaving)
        .overlay {
            if viewModel.isSaving {
                savingOverlay
            }
        }
    }

    // MARK: - Patient Header

    private var patientHeader: some View {
        HStack(spacing: Spacing.md) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.modusCyan, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
                .overlay(
                    Text(patient.initials)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(patient.fullName)
                    .font(.headline)

                if let sport = patient.sport {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "sportscourt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(sport)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                if let injury = patient.injuryType {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "cross.case")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(injury)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Patient: \(patient.fullName)")
    }

    // MARK: - Sport Section

    private var sportSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(title: "Sport", icon: "figure.run", required: true)

            Button {
                showSportPicker = true
            } label: {
                HStack {
                    if let sport = viewModel.selectedSport {
                        Image(systemName: sport.category.icon)
                            .foregroundColor(sport.category.color)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(sport.name)
                                .font(.body)
                                .foregroundColor(.primary)

                            Text(sport.category.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Image(systemName: "sportscourt")
                            .foregroundColor(.secondary)

                        Text("Select a sport")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(Spacing.md)
                .background(Color(.systemBackground))
                .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showSportPicker) {
                SportPickerSheet(
                    sports: viewModel.sports,
                    selectedSport: $viewModel.selectedSport
                )
            }

            if viewModel.selectedSport == nil {
                Text("Select the sport the athlete is returning to")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Injury Section

    private var injurySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(title: "Injury Details", icon: "cross.case.fill", required: true)

            VStack(spacing: Spacing.md) {
                // Injury type
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Injury Type")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextField("e.g., ACL Reconstruction, UCL Repair", text: $viewModel.injuryType)
                        .textFieldStyle(.plain)
                        .padding(Spacing.md)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.sm)
                }

                // Injury date
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Injury Date")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    DatePicker(
                        "Injury Date",
                        selection: $viewModel.injuryDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }

                // Surgery toggle and date
                Toggle(isOn: $hasSurgery) {
                    HStack {
                        Image(systemName: "stethoscope")
                            .foregroundColor(.modusCyan)
                        Text("Had Surgery")
                            .font(.subheadline)
                    }
                }
                .onChange(of: hasSurgery) { _, newValue in
                    if newValue && viewModel.surgeryDate == nil {
                        viewModel.surgeryDate = Date()
                    } else if !newValue {
                        viewModel.surgeryDate = nil
                    }
                }

                if hasSurgery {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Surgery Date")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        DatePicker(
                            "Surgery Date",
                            selection: Binding(
                                get: { viewModel.surgeryDate ?? Date() },
                                set: { viewModel.surgeryDate = $0 }
                            ),
                            in: viewModel.injuryDate...Date(),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(Spacing.md)
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.md)
        }
        .animation(.easeInOut(duration: AnimationDuration.standard), value: hasSurgery)
    }

    // MARK: - Timeline Section

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(title: "Timeline", icon: "calendar", required: true)

            VStack(spacing: Spacing.md) {
                // Target return date
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Target Return Date")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    DatePicker(
                        "Target Return Date",
                        selection: $viewModel.targetReturnDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }

                // Timeline summary
                if viewModel.targetReturnDate > viewModel.injuryDate {
                    timelineSummary
                }
            }
            .padding(Spacing.md)
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.md)
        }
    }

    private var timelineSummary: some View {
        let totalWeeks = Calendar.current.dateComponents(
            [.weekOfYear],
            from: viewModel.injuryDate,
            to: viewModel.targetReturnDate
        ).weekOfYear ?? 0

        let weeksRemaining = Calendar.current.dateComponents(
            [.weekOfYear],
            from: Date(),
            to: viewModel.targetReturnDate
        ).weekOfYear ?? 0

        return HStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.xxs) {
                Text("\(totalWeeks)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.modusCyan)
                Text("Total Weeks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            VStack(spacing: Spacing.xxs) {
                Text("\(max(0, weeksRemaining))")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                Text("Weeks Remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(Spacing.sm)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(title: "Notes", icon: "note.text", required: false)

            TextEditor(text: $viewModel.notes)
                .frame(minHeight: 100)
                .padding(Spacing.sm)
                .background(Color(.systemBackground))
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )

            Text("Add any relevant notes about the injury, patient goals, or special considerations")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Phase Preview Section

    private func phasePreviewSection(sport: RTSSport) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                sectionHeader(title: "Default Phases", icon: "timeline.selection", required: false)

                Spacer()

                Button {
                    showPhasePreview = true
                } label: {
                    Text("View Details")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }
            }

            VStack(spacing: Spacing.xs) {
                ForEach(Array(sport.defaultPhases.enumerated()), id: \.element.id) { index, phase in
                    HStack(spacing: Spacing.sm) {
                        // Phase number
                        ZStack {
                            Circle()
                                .fill(phase.activityLevel.color.opacity(0.2))
                                .frame(width: 28, height: 28)

                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(phase.activityLevel.color)
                        }

                        // Phase info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(phase.phaseName)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack(spacing: Spacing.xs) {
                                RTSTrafficLightBadge(level: phase.activityLevel, size: .small)

                                if let weeks = phase.targetDurationWeeks {
                                    Text("\(weeks) weeks")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, Spacing.xs)
                }
            }
            .padding(Spacing.md)
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.md)

            Text("These phases will be created automatically when the protocol is created")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(title: String, icon: String, required: Bool) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .foregroundColor(.modusCyan)

            Text(title)
                .font(.headline)

            if required {
                Text("*")
                    .foregroundColor(.red)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)\(required ? ", required" : "")")
    }

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading sports...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var savingOverlay: some View {
        ZStack {
            Color(.label).opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                ProgressView()
                    .scaleEffect(1.5)

                Text(isEditMode ? "Updating..." : "Creating...")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(Spacing.xl)
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.lg)
        }
    }

    // MARK: - Actions

    private func populateFromExisting(_ protocol_: RTSProtocol) {
        // Find matching sport
        if let sport = viewModel.sports.first(where: { $0.id == protocol_.sportId }) {
            viewModel.selectedSport = sport
        }

        viewModel.injuryType = protocol_.injuryType
        viewModel.injuryDate = protocol_.injuryDate
        viewModel.surgeryDate = protocol_.surgeryDate
        viewModel.targetReturnDate = protocol_.targetReturnDate
        viewModel.notes = protocol_.notes ?? ""

        hasSurgery = protocol_.surgeryDate != nil
    }

    private func createOrUpdateProtocol() {
        HapticFeedback.medium()

        Task {
            guard let therapistId = UUID(uuidString: PTSupabaseClient.shared.userId ?? "") else {
                viewModel.errorMessage = "Unable to identify therapist"
                return
            }

            let success = await viewModel.createProtocol(
                patientId: patient.id,
                therapistId: therapistId
            )

            if success {
                HapticFeedback.success()
                dismiss()
            }
        }
    }
}

// MARK: - Sport Picker Sheet

private struct SportPickerSheet: View {
    let sports: [RTSSport]
    @Binding var selectedSport: RTSSport?
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    private var filteredSports: [RTSSport] {
        if searchText.isEmpty {
            return sports
        }
        return sports.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.category.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedSports: [RTSSportCategory: [RTSSport]] {
        Dictionary(grouping: filteredSports, by: { $0.category })
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(RTSSportCategory.allCases) { category in
                    if let sports = groupedSports[category], !sports.isEmpty {
                        Section {
                            ForEach(sports) { sport in
                                Button {
                                    HapticFeedback.selectionChanged()
                                    selectedSport = sport
                                    dismiss()
                                } label: {
                                    HStack {
                                        Image(systemName: category.icon)
                                            .foregroundColor(category.color)
                                            .frame(width: 24)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(sport.name)
                                                .font(.body)
                                                .foregroundColor(.primary)

                                            Text("\(sport.defaultPhases.count) phases")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        if selectedSport?.id == sport.id {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.modusCyan)
                                        }
                                    }
                                }
                            }
                        } header: {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                                Text(category.displayName)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search sports")
            .navigationTitle("Select Sport")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Phase Preview Sheet

private struct PhasePreviewSheet: View {
    let sport: RTSSport
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    // Sport header
                    HStack(spacing: Spacing.md) {
                        Image(systemName: sport.category.icon)
                            .font(.title)
                            .foregroundColor(sport.category.color)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(sport.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(sport.category.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(Spacing.md)
                    .background(Color(.systemBackground))
                    .cornerRadius(CornerRadius.lg)

                    // Phases
                    ForEach(Array(sport.defaultPhases.enumerated()), id: \.element.id) { index, phase in
                        phaseCard(phase: phase, index: index)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Protocol Phases")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func phaseCard(phase: RTSPhaseTemplate, index: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(phase.activityLevel.color)
                        .frame(width: 32, height: 32)

                    Text("\(index + 1)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(phase.phaseName)
                        .font(.headline)

                    HStack(spacing: Spacing.sm) {
                        RTSTrafficLightBadge(level: phase.activityLevel, size: .small)

                        if let weeks = phase.targetDurationWeeks {
                            Text("\(weeks) weeks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()
            }

            Divider()

            // Description
            Text(phase.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }
}

// MARK: - Preview

#if DEBUG
struct RTSProtocolEditorView_Previews: PreviewProvider {
    static var previews: some View {
        RTSProtocolEditorView(patient: Patient.samplePatients[0])
    }
}
#endif
