//
//  WorkoutAssignmentView.swift
//  PTPerformance
//
//  Visual week grid for assigning workout templates to specific week/day slots
//  Supports tap-to-assign and drag-drop functionality
//

import SwiftUI

struct WorkoutAssignmentView: View {
    @Binding var phase: TherapistPhaseData
    @Binding var isPresented: Bool

    @State private var selectedWeek: Int = 1
    @State private var showWorkoutPicker = false
    @State private var selectedDayForAssignment: Int?
    @State private var templates: [SystemWorkoutTemplate] = []
    @State private var isLoadingTemplates = false
    @State private var searchText = ""

    // Days of the week to show (Mon, Tue, Wed, Thu, Fri, Sat, Sun)
    private let weekdays = [
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
                // Week selector
                weekSelectorView

                Divider()

                // Main content area
                HStack(spacing: 0) {
                    // Left: Week grid
                    weekGridView
                        .frame(maxWidth: .infinity)

                    Divider()

                    // Right: Template picker
                    templatePickerView
                        .frame(width: 200)
                }
            }
            .navigationTitle("Assign Workouts")
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
            .task {
                await loadTemplates()
            }
        }
    }

    // MARK: - Week Selector

    private var weekSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(1...phase.durationWeeks, id: \.self) { week in
                    WeekTabButton(
                        week: week,
                        isSelected: selectedWeek == week,
                        assignmentCount: assignmentsInWeek(week)
                    ) {
                        selectedWeek = week
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, Spacing.sm)
        }
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Week Grid View

    private var weekGridView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header row
                HStack(spacing: 0) {
                    ForEach(weekdays, id: \.0) { _, name in
                        Text(name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.xs)
                            .background(Color(.tertiarySystemGroupedBackground))
                    }
                }

                // Day slots
                HStack(alignment: .top, spacing: 0) {
                    ForEach(weekdays, id: \.0) { day, _ in
                        DaySlotView(
                            day: day,
                            week: selectedWeek,
                            assignments: assignmentsForDay(week: selectedWeek, day: day),
                            onTap: {
                                selectedDayForAssignment = day
                                showWorkoutPicker = true
                            },
                            onRemove: { assignment in
                                removeAssignment(assignment)
                            }
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(minHeight: 200)

                Spacer()
            }
        }
        .sheet(isPresented: $showWorkoutPicker) {
            if let day = selectedDayForAssignment {
                QuickWorkoutPickerSheet(
                    templates: filteredTemplates,
                    onSelect: { template in
                        addAssignment(template: template, week: selectedWeek, day: day)
                        showWorkoutPicker = false
                    },
                    isPresented: $showWorkoutPicker
                )
            }
        }
    }

    // MARK: - Template Picker View (Right sidebar)

    private var templatePickerView: some View {
        VStack(spacing: 0) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.caption)

                TextField("Search", text: $searchText)
                    .font(.caption)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(Spacing.xs)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.sm)
            .padding(Spacing.xs)

            Divider()

            // Template list
            if isLoadingTemplates {
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
                Spacer()
            } else if filteredTemplates.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(.secondary)
                    Text("No templates")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(filteredTemplates) { template in
                            DraggableTemplateRow(template: template) {
                                // Handle tap - prompt for day selection
                                if let day = selectedDayForAssignment {
                                    addAssignment(template: template, week: selectedWeek, day: day)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxs)
                }
            }
        }
    }

    // MARK: - Filtered Templates

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

    // MARK: - Helper Methods

    private func assignmentsInWeek(_ week: Int) -> Int {
        phase.workoutAssignments.filter { $0.weekNumber == week }.count
    }

    private func assignmentsForDay(week: Int, day: Int) -> [TherapistWorkoutAssignment] {
        phase.workoutAssignments.filter { $0.weekNumber == week && $0.dayOfWeek == day }
    }

    private func addAssignment(template: SystemWorkoutTemplate, week: Int, day: Int) {
        let assignment = TherapistWorkoutAssignment(
            id: UUID(),
            templateId: template.id,
            templateName: template.name,
            weekNumber: week,
            dayOfWeek: day
        )
        phase.workoutAssignments.append(assignment)
    }

    private func removeAssignment(_ assignment: TherapistWorkoutAssignment) {
        phase.workoutAssignments.removeAll { $0.id == assignment.id }
    }

    private func loadTemplates() async {
        isLoadingTemplates = true

        do {
            let response = try await PTSupabaseClient.shared.client
                .from("system_workout_templates")
                .select()
                .order("name", ascending: true)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            templates = try decoder.decode([SystemWorkoutTemplate].self, from: response.data)
        } catch {
            // Log error but continue with empty templates
            let logger = DebugLogger.shared
            logger.log("Failed to load templates: \(error)", level: .error)
        }

        isLoadingTemplates = false
    }
}

// MARK: - Week Tab Button

private struct WeekTabButton: View {
    let week: Int
    let isSelected: Bool
    let assignmentCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("Week \(week)")
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)

                if assignmentCount > 0 {
                    Text("\(assignmentCount)")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.modusCyan : Color(.systemGray4))
                        )
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.modusCyan : Color.clear)
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Day Slot View

private struct DaySlotView: View {
    let day: Int
    let week: Int
    let assignments: [TherapistWorkoutAssignment]
    let onTap: () -> Void
    let onRemove: (TherapistWorkoutAssignment) -> Void

    var body: some View {
        VStack(spacing: 4) {
            // Assigned workouts
            ForEach(assignments) { assignment in
                AssignedWorkoutCard(assignment: assignment) {
                    onRemove(assignment)
                }
            }

            // Add button
            Button(action: onTap) {
                VStack(spacing: 4) {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                        .foregroundColor(.blue.opacity(0.6))

                    Text("Add")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .foregroundColor(Color(.systemGray4))
                )
            }
            .buttonStyle(.plain)
            .padding(Spacing.xxs)

            Spacer()
        }
        .padding(.top, Spacing.xxs)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.tertiarySystemGroupedBackground))
                .frame(width: 1),
            alignment: .trailing
        )
    }
}

// MARK: - Assigned Workout Card

private struct AssignedWorkoutCard: View {
    let assignment: TherapistWorkoutAssignment
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Text(assignment.templateName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()

                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.modusCyan.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.modusCyan.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, Spacing.xxs)
    }
}

// MARK: - Draggable Template Row

private struct DraggableTemplateRow: View {
    let template: SystemWorkoutTemplate
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)

                if let category = template.category {
                    Text(category.capitalized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(Spacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Workout Picker Sheet

private struct QuickWorkoutPickerSheet: View {
    let templates: [SystemWorkoutTemplate]
    let onSelect: (SystemWorkoutTemplate) -> Void
    @Binding var isPresented: Bool

    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search
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
                .cornerRadius(CornerRadius.sm)
                .padding(.horizontal)
                .padding(.top, Spacing.xs)

                // List
                List(filteredTemplates) { template in
                    Button {
                        onSelect(template)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(template.name)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)

                                if let category = template.category {
                                    Text(category.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.modusCyan)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
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

// MARK: - Preview

#if DEBUG
struct WorkoutAssignmentView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutAssignmentView(
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
                    )
                ]
            )),
            isPresented: .constant(true)
        )
    }
}
#endif
