//
//  TemplateDetailView.swift
//  PTPerformance
//
//  Created by Build 46 Swarm Agent 2
//  Preview template before assignment to patient
//

import SwiftUI

struct TemplateDetailView: View {

    let template: WorkoutTemplate

    @Environment(\.dismiss) private var dismiss
    @State private var phases: [TemplatePhaseDetail] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var expandedPhaseIds: Set<UUID> = []
    @State private var showingAssignSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    templateHeader

                    // Statistics
                    statisticsSection

                    // Description
                    if let description = template.description {
                        descriptionSection(description)
                    }

                    // Tags
                    if !template.tags.isEmpty {
                        tagsSection
                    }

                    Divider()

                    // Phases and Sessions
                    if isLoading && phases.isEmpty {
                        ProgressView("Loading template details...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if !phases.isEmpty {
                        phasesSection
                    }
                }
                .padding()
            }
            .navigationTitle("Template Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAssignSheet = true }) {
                        Label("Assign", systemImage: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAssignSheet) {
                AssignTemplateSheet(template: template)
            }
            .task {
                await loadTemplateDetails()
            }
        }
    }

    // MARK: - Template Header

    private var templateHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category and difficulty
            HStack(spacing: 8) {
                TemplateCategoryBadge(category: template.category.rawValue)

                if let difficulty = template.difficultyLevel {
                    Text(difficulty.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(CornerRadius.xs)
                }

                if template.isPopular {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text("Popular")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.yellow.opacity(0.15))
                    .cornerRadius(CornerRadius.xs)
                }

                Spacer()
            }

            // Template name
            Text(template.name)
                .font(.title)
                .fontWeight(.bold)

            // Duration
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)

                Text(template.durationDescription)
                    .font(.subheadline)
            }
            .foregroundColor(.secondary)
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        HStack(spacing: 0) {
            StatisticBox(
                value: "\(phases.count)",
                label: "Phases",
                icon: "list.bullet"
            )

            Divider()

            StatisticBox(
                value: "\(totalSessions)",
                label: "Sessions",
                icon: "calendar.badge.clock"
            )

            Divider()

            StatisticBox(
                value: "\(totalExercises)",
                label: "Exercises",
                icon: "figure.strengthtraining.traditional"
            )

            Divider()

            StatisticBox(
                value: "\(template.usageCount)",
                label: "Uses",
                icon: "person.2.fill"
            )
        }
        .frame(height: 80)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Description Section

    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Description", systemImage: "text.alignleft")
                .font(.headline)

            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tags", systemImage: "tag.fill")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(template.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(CornerRadius.sm)
                    }
                }
            }
        }
    }

    // MARK: - Phases Section

    private var phasesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Program Structure", systemImage: "list.bullet.rectangle")
                .font(.headline)

            ForEach(phases.indices, id: \.self) { index in
                PhaseDetailCard(
                    phaseDetail: phases[index],
                    phaseNumber: index + 1,
                    isExpanded: expandedPhaseIds.contains(phases[index].id),
                    onToggle: {
                        if expandedPhaseIds.contains(phases[index].id) {
                            expandedPhaseIds.remove(phases[index].id)
                        } else {
                            expandedPhaseIds.insert(phases[index].id)
                        }
                    }
                )
            }
        }
    }

    // MARK: - Computed Properties

    private var totalSessions: Int {
        phases.reduce(0) { $0 + $1.sessions.count }
    }

    private var totalExercises: Int {
        phases.reduce(0) { total, phase in
            total + phase.sessions.reduce(0) { $0 + $1.exerciseCount }
        }
    }

    // MARK: - Actions

    private func loadTemplateDetails() async {
        isLoading = true
        errorMessage = nil

        do {
            let detail = try await TemplatesService.shared.fetchTemplateDetails(
                templateId: template.id.uuidString
            )
            phases = detail.phases

            // Expand first phase by default
            if let firstPhase = phases.first {
                expandedPhaseIds.insert(firstPhase.id)
            }
        } catch {
            ErrorLogger.shared.logError(error, context: "TemplateDetailView.loadTemplateDetails")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Statistic Box

struct StatisticBox: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Phase Detail Card

struct PhaseDetailCard: View {
    let phaseDetail: TemplatePhaseDetail
    let phaseNumber: Int
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Phase header
            Button(action: onToggle) {
                HStack {
                    // Phase number badge
                    Text("\(phaseNumber)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.blue)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(phaseDetail.phase.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack {
                            if let duration = phaseDetail.phase.durationWeeks {
                                Label("\(duration)w", systemImage: "calendar")
                            }

                            Label("\(phaseDetail.sessions.count) sessions", systemImage: "list.bullet")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Phase description
            if let description = phaseDetail.phase.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Sessions list (when expanded)
            if isExpanded {
                Divider()

                ForEach(phaseDetail.sessions.indices, id: \.self) { index in
                    SessionDetailRow(session: phaseDetail.sessions[index], sessionNumber: index + 1)

                    if index < phaseDetail.sessions.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }
}

// MARK: - Session Detail Row

struct SessionDetailRow: View {
    let session: TemplateSession
    let sessionNumber: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Session \(sessionNumber)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                Label("\(session.estimatedDuration) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(session.name)
                .font(.subheadline)
                .fontWeight(.medium)

            if let description = session.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Exercises summary
            VStack(alignment: .leading, spacing: 4) {
                ForEach(0..<min(3, session.exercises.count), id: \.self) { index in
                    HStack(spacing: 8) {
                        Text("\(index + 1).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .leading)

                        Text(session.exercises[index].name)
                            .font(.caption)

                        Spacer()

                        Text(session.exercises[index].setsRepsDisplay)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }

                if session.exercises.count > 3 {
                    Text("+\(session.exercises.count - 3) more exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 28)
                }
            }
            .padding(.top, 4)

            if let notes = session.notes {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(CornerRadius.sm)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Assign Template Sheet

struct AssignTemplateSheet: View {
    let template: WorkoutTemplate

    @Environment(\.dismiss) private var dismiss
    @State private var patients: [Patient] = []
    @State private var selectedPatient: Patient?
    @State private var programName: String = ""
    @State private var startDate = Date()
    @State private var isAssigning = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Patient") {
                    if patients.isEmpty {
                        ProgressView("Loading patients...")
                    } else {
                        Picker("Select Patient", selection: $selectedPatient) {
                            Text("Choose a patient").tag(nil as Patient?)
                            ForEach(patients) { patient in
                                Text(patient.fullName).tag(patient as Patient?)
                            }
                        }
                    }
                }

                Section("Program Details") {
                    TextField("Program Name", text: $programName)

                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button(action: assignTemplate) {
                        if isAssigning {
                            ProgressView()
                        } else {
                            Text("Assign Template")
                        }
                    }
                    .disabled(selectedPatient == nil || programName.isEmpty || isAssigning)
                }
            }
            .navigationTitle("Assign Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadPatients()
            }
        }
    }

    private func loadPatients() async {
        do {
            let response: [Patient] = try await PTSupabaseClient.shared.client
                .from("patients")
                .select("*")
                .order("last_name", ascending: true)
                .execute()
                .value
            patients = response
        } catch {
            errorMessage = "Failed to load patients"
        }
    }

    private func assignTemplate() {
        guard let patient = selectedPatient else { return }
        isAssigning = true
        errorMessage = nil

        Task {
            do {
                let _ = try await TemplatesService.shared.createProgramFromTemplate(
                    templateId: template.id.uuidString,
                    patientId: patient.id.uuidString,
                    programName: programName,
                    startDate: startDate
                )
                isAssigning = false
                dismiss()
            } catch {
                isAssigning = false
                errorMessage = "Failed to assign: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Preview

struct TemplateDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TemplateDetailView(template: .sample)
    }
}
