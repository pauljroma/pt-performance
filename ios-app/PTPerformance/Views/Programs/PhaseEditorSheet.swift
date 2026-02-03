//
//  PhaseEditorSheet.swift
//  PTPerformance
//
//  Sheet for editing a single phase within a therapist-built program
//  Includes phase metadata and workout assignment section
//

import SwiftUI

struct PhaseEditorSheet: View {
    @Binding var phase: TherapistPhaseData
    let phaseNumber: Int
    @Binding var isPresented: Bool

    @State private var showWorkoutAssignment = false
    @State private var showWorkoutSearch = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Phase Details
                phaseDetailsSection

                // MARK: - Goals
                goalsSection

                // MARK: - Workout Assignments
                workoutAssignmentsSection
            }
            .navigationTitle("Phase \(phaseNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showWorkoutAssignment) {
                WorkoutAssignmentView(
                    phase: $phase,
                    isPresented: $showWorkoutAssignment
                )
            }
            .sheet(isPresented: $showWorkoutSearch) {
                WorkoutSearchSheet(
                    onSelect: { template in
                        addWorkoutAssignment(template: template)
                    },
                    isPresented: $showWorkoutSearch
                )
            }
        }
    }

    // MARK: - Phase Details Section

    private var phaseDetailsSection: some View {
        Section {
            TextField("Phase Name", text: $phase.name)
                .textInputAutocapitalization(.words)

            Stepper(
                "Duration: \(phase.durationWeeks) \(phase.durationWeeks == 1 ? "week" : "weeks")",
                value: $phase.durationWeeks,
                in: 1...16
            )

            HStack {
                Text("Sequence")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(phase.sequence)")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("Phase Details")
        }
    }

    // MARK: - Goals Section

    private var goalsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                TextEditor(text: $phase.goals)
                    .frame(minHeight: 80)
            }
        } header: {
            Text("Phase Goals")
        } footer: {
            Text("Describe what patients should achieve during this phase")
        }
    }

    // MARK: - Workout Assignments Section

    private var workoutAssignmentsSection: some View {
        Section {
            if phase.workoutAssignments.isEmpty {
                emptyAssignmentsView
            } else {
                // Group assignments by week
                let groupedAssignments = Dictionary(grouping: phase.workoutAssignments) { $0.weekNumber }
                let sortedWeeks = groupedAssignments.keys.sorted()

                ForEach(sortedWeeks, id: \.self) { week in
                    weekSection(week: week, assignments: groupedAssignments[week] ?? [])
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    showWorkoutSearch = true
                } label: {
                    Label("Quick Add", systemImage: "plus.circle")
                }

                Spacer()

                Button {
                    showWorkoutAssignment = true
                } label: {
                    Label("Visual Grid", systemImage: "calendar")
                }
            }
            .padding(.vertical, 4)
        } header: {
            HStack {
                Text("Workout Assignments (\(phase.workoutAssignments.count))")
                Spacer()
            }
        } footer: {
            Text("Assign workouts to specific weeks and days")
        }
    }

    // MARK: - Empty Assignments View

    private var emptyAssignmentsView: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "dumbbell")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No workouts assigned")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Use Quick Add or Visual Grid to assign workouts")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 24)
            Spacer()
        }
    }

    // MARK: - Week Section

    private func weekSection(week: Int, assignments: [TherapistWorkoutAssignment]) -> some View {
        DisclosureGroup {
            ForEach(assignments.sorted { $0.dayOfWeek < $1.dayOfWeek }) { assignment in
                WorkoutAssignmentRow(
                    assignment: assignment,
                    onDelete: {
                        deleteAssignment(assignment)
                    }
                )
            }
        } label: {
            HStack {
                Text("Week \(week)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(assignments.count) workouts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func addWorkoutAssignment(template: SystemWorkoutTemplate) {
        // Find the next available slot
        let existingWeeks = phase.workoutAssignments.map { $0.weekNumber }
        let nextWeek = existingWeeks.isEmpty ? 1 : (existingWeeks.max() ?? 0)

        // Find next available day in that week
        let daysInWeek = phase.workoutAssignments
            .filter { $0.weekNumber == nextWeek }
            .map { $0.dayOfWeek }
        let nextDay = getNextAvailableDay(usedDays: daysInWeek)

        let assignment = TherapistWorkoutAssignment(
            id: UUID(),
            templateId: template.id,
            templateName: template.name,
            weekNumber: nextWeek,
            dayOfWeek: nextDay
        )

        phase.workoutAssignments.append(assignment)
    }

    private func deleteAssignment(_ assignment: TherapistWorkoutAssignment) {
        phase.workoutAssignments.removeAll { $0.id == assignment.id }
    }

    private func getNextAvailableDay(usedDays: [Int]) -> Int {
        // Typical workout days: Mon(1), Tue(2), Thu(4), Sat(6)
        let preferredDays = [1, 2, 4, 6, 3, 5, 7]
        for day in preferredDays {
            if !usedDays.contains(day) {
                return day
            }
        }
        return 1 // Default to Monday if all days are taken
    }
}

// MARK: - Workout Assignment Row

private struct WorkoutAssignmentRow: View {
    let assignment: TherapistWorkoutAssignment
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.templateName)
                    .font(.subheadline)

                Text(dayName(assignment.dayOfWeek))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private func dayName(_ day: Int) -> String {
        let days = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        guard day >= 0 && day < days.count else { return "Day \(day)" }
        return days[day]
    }
}

// MARK: - Workout Search Sheet

struct WorkoutSearchSheet: View {
    let onSelect: (SystemWorkoutTemplate) -> Void
    @Binding var isPresented: Bool

    @State private var searchText = ""
    @State private var templates: [SystemWorkoutTemplate] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search workouts...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocorrectionDisabled()

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)

                // Content
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task {
                                await loadTemplates()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    Spacer()
                } else if filteredTemplates.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No workouts found")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(filteredTemplates) { template in
                        WorkoutTemplateSearchRow(template: template) {
                            onSelect(template)
                            isPresented = false
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Add Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .task {
                await loadTemplates()
            }
        }
    }

    private var filteredTemplates: [SystemWorkoutTemplate] {
        if searchText.isEmpty {
            return templates
        }
        let lowercasedSearch = searchText.lowercased()
        return templates.filter { template in
            template.name.lowercased().contains(lowercasedSearch) ||
            (template.category?.lowercased().contains(lowercasedSearch) ?? false) ||
            (template.tags?.contains { $0.lowercased().contains(lowercasedSearch) } ?? false)
        }
    }

    private func loadTemplates() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await PTSupabaseClient.shared.client
                .from("system_workout_templates")
                .select()
                .order("name", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            templates = try decoder.decode([SystemWorkoutTemplate].self, from: response.data)
        } catch {
            errorMessage = "Failed to load workouts: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

// MARK: - Workout Template Search Row

private struct WorkoutTemplateSearchRow: View {
    let template: SystemWorkoutTemplate
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        if let category = template.category {
                            Text(category.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let duration = template.durationDisplay {
                            Text("-")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(duration)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let difficulty = template.difficulty {
                            Text("-")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(difficulty.capitalized)
                                .font(.caption)
                                .foregroundColor(difficultyColor(difficulty))
                        }
                    }
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .secondary
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PhaseEditorSheet_Previews: PreviewProvider {
    static var previews: some View {
        PhaseEditorSheet(
            phase: .constant(TherapistPhaseData(
                id: UUID(),
                name: "Foundation Phase",
                sequence: 1,
                durationWeeks: 4,
                goals: "Build baseline strength and movement patterns",
                workoutAssignments: [
                    TherapistWorkoutAssignment(
                        id: UUID(),
                        templateId: UUID(),
                        templateName: "Lower Body Strength A",
                        weekNumber: 1,
                        dayOfWeek: 1
                    ),
                    TherapistWorkoutAssignment(
                        id: UUID(),
                        templateId: UUID(),
                        templateName: "Upper Body Push",
                        weekNumber: 1,
                        dayOfWeek: 3
                    )
                ]
            )),
            phaseNumber: 1,
            isPresented: .constant(true)
        )
    }
}
#endif
