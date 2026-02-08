//
//  PatientContextCard.swift
//  PTPerformance
//
//  Patient Context feature for the enhanced program builder wizard.
//  Shows rich context when a patient is selected including injury info,
//  previous programs, and active goals.
//

import SwiftUI

// MARK: - Patient Context Card

/// A rich context card displayed when a patient is selected in the program builder wizard.
/// Shows patient details, injury/condition, previous programs, and active goals.
struct PatientContextCard: View {
    let patient: Patient
    let onChangePatient: () -> Void

    @StateObject private var viewModel = PatientContextViewModel()
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row - always visible
            headerRow

            // Collapsible content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    // Injury/Condition Badge
                    if let injuryType = patient.injuryType {
                        injuryBadgeSection(injuryType: injuryType)
                    }

                    // Previous Programs Section
                    if !viewModel.previousPrograms.isEmpty {
                        previousProgramsSection
                    }

                    // Active Goals Section
                    if !viewModel.activeGoals.isEmpty {
                        activeGoalsSection
                    }

                    // Smart Suggestion
                    if let suggestion = viewModel.suggestedProgramType {
                        smartSuggestionBanner(programType: suggestion)
                    }
                }
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .task {
            await viewModel.loadPatientContext(for: patient)
        }
        .onChange(of: patient.id) { _, newId in
            Task {
                await viewModel.loadPatientContext(for: patient)
            }
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(spacing: 12) {
            // Patient avatar
            patientAvatar

            // Patient info
            VStack(alignment: .leading, spacing: 2) {
                Text(patient.fullName)
                    .font(.headline)
                    .foregroundColor(.primary)

                if let age = viewModel.patientAge {
                    Text("\(age) years old")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let sport = patient.sport {
                    Text(sport)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Change patient button
            Button {
                HapticService.selection()
                onChangePatient()
            } label: {
                Text("Change")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)

            // Expand/Collapse chevron
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
                HapticService.light()
            } label: {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "Collapse details" : "Expand details")
        }
    }

    // MARK: - Patient Avatar

    private var patientAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.15))
                .frame(width: 48, height: 48)

            Text(String(patient.firstName.prefix(1)).uppercased())
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Injury Badge Section

    private func injuryBadgeSection(injuryType: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: injuryIcon(for: injuryType))
                    .font(.caption)
                    .foregroundColor(.orange)

                Text(injuryType)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)

            // Suggestion hint
            HStack(spacing: 4) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption2)
                    .foregroundColor(.yellow)

                Text("Suggested: Rehabilitation")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Previous Programs Section

    private var previousProgramsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.caption)
                    .foregroundColor(.blue)

                Text("\(viewModel.previousPrograms.count) previous program\(viewModel.previousPrograms.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            // Details
            VStack(alignment: .leading, spacing: 4) {
                if let lastCompleted = viewModel.lastCompletedDate {
                    HStack(spacing: 4) {
                        Text("Last completed:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(lastCompleted, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let adherence = patient.adherencePercentage {
                    HStack(spacing: 4) {
                        Text("Adherence rate:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(adherence))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(adherenceColor(for: adherence))
                    }
                }
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }

    // MARK: - Active Goals Section

    private var activeGoalsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack {
                Image(systemName: "target")
                    .font(.caption)
                    .foregroundColor(.green)

                Text("Active Goals")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            // Goals list (max 3)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(viewModel.activeGoals.prefix(3)) { goal in
                    PatientGoalMiniRow(goal: goal)
                }

                if viewModel.activeGoals.count > 3 {
                    Text("+\(viewModel.activeGoals.count - 3) more goals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color.green.opacity(0.05))
        .cornerRadius(8)
    }

    // MARK: - Smart Suggestion Banner

    private func smartSuggestionBanner(programType: ProgramType) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundColor(.purple)

            Text("Recommended: \(programType.displayName) Program")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.purple)

            Spacer()

            Image(systemName: programType.icon)
                .font(.caption)
                .foregroundColor(programType.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Helpers

    private func injuryIcon(for injuryType: String) -> String {
        let lowercased = injuryType.lowercased()

        if lowercased.contains("shoulder") || lowercased.contains("rotator") {
            return "figure.arms.open"
        } else if lowercased.contains("knee") || lowercased.contains("acl") || lowercased.contains("mcl") {
            return "figure.walk"
        } else if lowercased.contains("back") || lowercased.contains("spine") {
            return "figure.stand"
        } else if lowercased.contains("elbow") || lowercased.contains("tommy john") || lowercased.contains("ucl") {
            return "hand.raised.fill"
        } else if lowercased.contains("ankle") || lowercased.contains("foot") {
            return "shoe.fill"
        } else if lowercased.contains("hip") {
            return "figure.cooldown"
        } else if lowercased.contains("hamstring") || lowercased.contains("quad") {
            return "figure.run"
        } else {
            return "cross.case.fill"
        }
    }

    private func adherenceColor(for percentage: Double) -> Color {
        if percentage >= 85 {
            return .green
        } else if percentage >= 70 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Patient Goal Mini Row

private struct PatientGoalMiniRow: View {
    let goal: PatientGoal

    var body: some View {
        HStack(spacing: 8) {
            // Category icon
            Image(systemName: goal.category.icon)
                .font(.caption2)
                .foregroundColor(goal.category.color)
                .frame(width: 16)

            // Goal title
            Text(goal.title)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()

            // Progress indicator
            HStack(spacing: 4) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(.systemGray5))

                        Rectangle()
                            .fill(goal.category.color)
                            .frame(width: geometry.size.width * goal.progress)
                    }
                }
                .frame(width: 40, height: 4)
                .cornerRadius(2)

                // Percentage
                Text(goal.progressPercentageText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 30, alignment: .trailing)
            }
        }
    }
}

// MARK: - Patient Context ViewModel

@MainActor
class PatientContextViewModel: ObservableObject {
    @Published var previousPrograms: [Program] = []
    @Published var activeGoals: [PatientGoal] = []
    @Published var lastCompletedDate: Date?
    @Published var patientAge: Int?
    @Published var suggestedProgramType: ProgramType?
    @Published var isLoading = false
    @Published var error: String?

    private let supabase = PTSupabaseClient.shared

    // MARK: - Load Patient Context

    func loadPatientContext(for patient: Patient) async {
        isLoading = true
        error = nil

        // Calculate suggested program type
        suggestedProgramType = suggestProgramType(for: patient)

        // Load data in parallel
        async let programsTask: () = loadPreviousPrograms(for: patient.id)
        async let goalsTask: () = loadActiveGoals(for: patient.id)

        _ = await (programsTask, goalsTask)

        isLoading = false
    }

    // MARK: - Smart Suggestion Logic

    /// Suggests an appropriate program type based on patient data
    func suggestProgramType(for patient: Patient) -> ProgramType? {
        // If patient has an injury, suggest rehabilitation
        if patient.injuryType != nil {
            return .rehab
        }

        // Check goals for performance indicators
        let performanceGoals = activeGoals.filter { goal in
            goal.category == .strength ||
            goal.category == .endurance ||
            goal.category == .bodyComposition
        }

        if !performanceGoals.isEmpty {
            return .performance
        }

        // Check for rehabilitation goals
        let rehabGoals = activeGoals.filter { goal in
            goal.category == .painReduction ||
            goal.category == .rehabilitation ||
            goal.category == .mobility
        }

        if !rehabGoals.isEmpty {
            return .rehab
        }

        // Check if patient has sports/performance context
        if patient.sport != nil || patient.targetLevel != nil {
            return .performance
        }

        // Default - no strong suggestion
        return nil
    }

    // MARK: - Load Previous Programs

    private func loadPreviousPrograms(for patientId: UUID) async {
        do {
            let response = try await supabase.client
                .from("programs")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .order("created_at", ascending: false)
                .limit(5)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let programs = try decoder.decode([Program].self, from: response.data)

            previousPrograms = programs

            // Find last completed date
            if let lastCompleted = programs.first(where: { $0.status == "completed" }) {
                lastCompletedDate = lastCompleted.createdAt
            }

        } catch {
            ErrorLogger.shared.logError(error, context: "PatientContextViewModel.loadPreviousPrograms")
            // Don't show error to user - this is supplementary data
            previousPrograms = []
        }
    }

    // MARK: - Load Active Goals

    private func loadActiveGoals(for patientId: UUID) async {
        do {
            let response = try await supabase.client
                .from("patient_goals")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .eq("status", value: "active")
                .order("created_at", ascending: false)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let goals = try decoder.decode([PatientGoal].self, from: response.data)

            activeGoals = goals

            // Re-evaluate suggestion after goals are loaded
            // Note: This will be called after the initial suggestion

        } catch {
            ErrorLogger.shared.logError(error, context: "PatientContextViewModel.loadActiveGoals")
            // Don't show error to user - this is supplementary data
            activeGoals = []
        }
    }
}

// MARK: - Patient Picker Integration View

/// A view that integrates patient selection with the context card for use in wizards
struct PatientSelectionWithContext: View {
    @Binding var selectedPatient: Patient?
    let onProgramTypeSuggested: ((ProgramType) -> Void)?

    @State private var showPatientPicker = false

    init(
        selectedPatient: Binding<Patient?>,
        onProgramTypeSuggested: ((ProgramType) -> Void)? = nil
    ) {
        self._selectedPatient = selectedPatient
        self.onProgramTypeSuggested = onProgramTypeSuggested
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let patient = selectedPatient {
                // Show context card when patient is selected
                PatientContextCard(patient: patient) {
                    showPatientPicker = true
                }
            } else {
                // Show selection prompt
                selectPatientPrompt
            }
        }
        .sheet(isPresented: $showPatientPicker) {
            PatientPickerSheet { patient in
                selectedPatient = patient
                HapticService.selection()
            }
        }
    }

    // MARK: - Select Patient Prompt

    private var selectPatientPrompt: some View {
        Button {
            showPatientPicker = true
            HapticService.selection()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 48, height: 48)

                    Image(systemName: "person.fill.badge.plus")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Select Patient")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Choose a patient for this program")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select Patient")
        .accessibilityHint("Opens patient picker to choose a patient for the program")
    }
}

// MARK: - Preview Provider

#if DEBUG
struct PatientContextCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // With patient selected
            PatientContextCard(
                patient: Patient.samplePatients[0],
                onChangePatient: {}
            )
            .padding()
            .previewDisplayName("With Patient")

            // Patient selection view - no patient
            PatientSelectionWithContext(selectedPatient: .constant(nil))
                .padding()
                .previewDisplayName("No Patient Selected")

            // Patient selection view - with patient
            PatientSelectionWithContext(selectedPatient: .constant(Patient.samplePatients[1]))
                .padding()
                .previewDisplayName("Patient Selected")
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
