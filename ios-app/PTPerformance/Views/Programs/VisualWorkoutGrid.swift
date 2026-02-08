//
//  VisualWorkoutGrid.swift
//  PTPerformance
//
//  A calendar-style grid for workout assignment.
//  Horizontal scroll with weeks as columns and days as rows (Mon-Sun).
//  Supports tap-to-add and swipe-to-delete functionality.
//

import SwiftUI

// MARK: - Visual Workout Grid View

struct VisualWorkoutGrid: View {
    @Binding var phase: TherapistPhaseData
    @Binding var isPresented: Bool

    @State private var showWorkoutPicker = false
    @State private var selectedCell: GridCell?
    @State private var templates: [SystemWorkoutTemplate] = []
    @State private var isLoadingTemplates = false

    // Days of the week (Mon = 1 through Sun = 7)
    private let days: [(Int, String)] = [
        (1, "Mon"),
        (2, "Tue"),
        (3, "Wed"),
        (4, "Thu"),
        (5, "Fri"),
        (6, "Sat"),
        (7, "Sun")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with phase info
                headerView

                Divider()

                // Grid content
                gridContent
            }
            .navigationTitle("Workout Grid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showWorkoutPicker) {
                if let cell = selectedCell {
                    WorkoutPickerSheet(
                        templates: templates,
                        weekNumber: cell.week,
                        dayOfWeek: cell.day,
                        onSelect: { template in
                            addWorkout(template: template, week: cell.week, day: cell.day)
                            showWorkoutPicker = false
                        },
                        isPresented: $showWorkoutPicker
                    )
                }
            }
            .task {
                await loadTemplates()
            }
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(phase.name.isEmpty ? "Phase" : phase.name)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("\(phase.durationWeeks) weeks - \(phase.workoutAssignments.count) workouts assigned")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Legend
            HStack(spacing: 12) {
                legendItem(color: .blue, label: "Assigned")
                legendItem(color: Color(.systemGray5), label: "Empty")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Grid Content

    private var gridContent: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(spacing: 0) {
                // Week headers row
                weekHeadersRow

                // Day rows
                ForEach(days, id: \.0) { day, dayName in
                    dayRow(day: day, dayName: dayName)
                }
            }
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Week Headers Row

    private var weekHeadersRow: some View {
        HStack(spacing: 0) {
            // Empty corner cell
            Text("Day")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 50, height: 40)
                .background(Color(.tertiarySystemGroupedBackground))

            // Week columns
            ForEach(1...phase.durationWeeks, id: \.self) { week in
                Text("Week \(week)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(width: 100, height: 40)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .overlay(
                        Rectangle()
                            .fill(Color(.separator).opacity(0.3))
                            .frame(width: 1),
                        alignment: .leading
                    )
            }
        }
    }

    // MARK: - Day Row

    private func dayRow(day: Int, dayName: String) -> some View {
        HStack(spacing: 0) {
            // Day label
            Text(dayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 50, height: 80)
                .background(Color(.secondarySystemGroupedBackground))
                .overlay(
                    Rectangle()
                        .fill(Color(.separator).opacity(0.3))
                        .frame(height: 1),
                    alignment: .top
                )

            // Cells for each week
            ForEach(1...phase.durationWeeks, id: \.self) { week in
                gridCell(week: week, day: day)
            }
        }
    }

    // MARK: - Grid Cell

    private func gridCell(week: Int, day: Int) -> some View {
        let assignments = assignmentsFor(week: week, day: day)

        return VStack(spacing: 4) {
            if assignments.isEmpty {
                // Empty cell - tap to add
                emptyCell(week: week, day: day)
            } else {
                // Show assigned workouts
                ForEach(assignments) { assignment in
                    assignedWorkoutCell(assignment: assignment)
                }

                // Add more button if there's room
                if assignments.count < 3 {
                    addMoreButton(week: week, day: day)
                }
            }
        }
        .frame(width: 100, height: 80)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
    }

    private func emptyCell(week: Int, day: Int) -> some View {
        Button {
            selectedCell = GridCell(week: week, day: day)
            showWorkoutPicker = true
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "plus.circle")
                    .font(.title3)
                    .foregroundColor(.blue.opacity(0.5))

                Text("Add")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel("Add workout to Week \(week), \(dayName(for: day))")
        .accessibilityHint("Double tap to add a workout to this slot")
    }

    private func assignedWorkoutCell(assignment: TherapistWorkoutAssignment) -> some View {
        HStack(spacing: 4) {
            Text(assignment.templateName)
                .font(.caption2)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundColor(.primary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.15))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.blue.opacity(0.3), lineWidth: 0.5)
        )
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteAssignment(assignment)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                deleteAssignment(assignment)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
        .accessibilityLabel("\(assignment.templateName)")
        .accessibilityHint("Swipe left to delete")
    }

    private func addMoreButton(week: Int, day: Int) -> some View {
        Button {
            selectedCell = GridCell(week: week, day: day)
            showWorkoutPicker = true
        } label: {
            HStack(spacing: 2) {
                Image(systemName: "plus")
                    .font(.caption2)
                Text("Add")
                    .font(.caption2)
            }
            .foregroundColor(.blue.opacity(0.7))
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
    }

    // MARK: - Helper Methods

    private func assignmentsFor(week: Int, day: Int) -> [TherapistWorkoutAssignment] {
        phase.workoutAssignments.filter { $0.weekNumber == week && $0.dayOfWeek == day }
    }

    private func addWorkout(template: SystemWorkoutTemplate, week: Int, day: Int) {
        let assignment = TherapistWorkoutAssignment(
            id: UUID(),
            templateId: template.id,
            templateName: template.name,
            weekNumber: week,
            dayOfWeek: day
        )
        phase.workoutAssignments.append(assignment)
    }

    private func deleteAssignment(_ assignment: TherapistWorkoutAssignment) {
        phase.workoutAssignments.removeAll { $0.id == assignment.id }
    }

    private func dayName(for day: Int) -> String {
        switch day {
        case 1: return "Monday"
        case 2: return "Tuesday"
        case 3: return "Wednesday"
        case 4: return "Thursday"
        case 5: return "Friday"
        case 6: return "Saturday"
        case 7: return "Sunday"
        default: return "Day \(day)"
        }
    }

    private func loadTemplates() async {
        isLoadingTemplates = true

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
            DebugLogger.shared.log("Failed to load workout templates: \(error)", level: .error)
        }

        isLoadingTemplates = false
    }
}

// MARK: - Grid Cell Model

private struct GridCell {
    let week: Int
    let day: Int
}

// MARK: - Workout Picker Sheet

private struct WorkoutPickerSheet: View {
    let templates: [SystemWorkoutTemplate]
    let weekNumber: Int
    let dayOfWeek: Int
    let onSelect: (SystemWorkoutTemplate) -> Void
    @Binding var isPresented: Bool

    @State private var searchText = ""

    private let days = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Context header
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text("Week \(weekNumber), \(days[dayOfWeek])")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search workouts...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())

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
                .padding(.vertical, 8)

                // Template list
                if filteredTemplates.isEmpty {
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
                        WorkoutTemplateRow(template: template) {
                            onSelect(template)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Select Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
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
            (template.category?.lowercased().contains(lowercasedSearch) ?? false)
        }
    }
}

// MARK: - Workout Template Row

private struct WorkoutTemplateRow: View {
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
                            Text(duration)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let difficulty = template.difficulty {
                            Text(difficulty.capitalized)
                                .font(.caption)
                                .foregroundColor(difficultyColor(difficulty))
                        }
                    }
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.title3)
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
struct VisualWorkoutGrid_Previews: PreviewProvider {
    static var previews: some View {
        VisualWorkoutGrid(
            phase: .constant(TherapistPhaseData(
                id: UUID(),
                name: "Foundation Phase",
                sequence: 1,
                durationWeeks: 4,
                goals: "Build baseline strength",
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
                    ),
                    TherapistWorkoutAssignment(
                        id: UUID(),
                        templateId: UUID(),
                        templateName: "Lower Body Strength B",
                        weekNumber: 1,
                        dayOfWeek: 5
                    ),
                    TherapistWorkoutAssignment(
                        id: UUID(),
                        templateId: UUID(),
                        templateName: "Full Body",
                        weekNumber: 2,
                        dayOfWeek: 1
                    )
                ]
            )),
            isPresented: .constant(true)
        )
    }
}
#endif
