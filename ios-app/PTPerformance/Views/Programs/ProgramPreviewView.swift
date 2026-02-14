//
//  ProgramPreviewView.swift
//  PTPerformance
//
//  Preview of a program before publishing.
//  Shows program name, type, patient name (if assigned), timeline,
//  phase breakdown with week ranges, week-by-week workout calendar,
//  total duration, exercise count, and patient preview.
//

import SwiftUI

// MARK: - Program Preview View

struct ProgramPreviewView: View {
    @ObservedObject var viewModel: TherapistProgramBuilderViewModel
    @Binding var isPresented: Bool

    @State private var showPublishConfirmation = false
    @State private var isPublishing = false
    @State private var selectedPreviewTab: PreviewTab = .therapist

    enum PreviewTab: String, CaseIterable {
        case therapist = "Builder View"
        case patient = "Patient View"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // View Toggle (Therapist vs Patient Preview)
                    previewToggle

                    if selectedPreviewTab == .therapist {
                        therapistPreviewContent
                    } else {
                        patientPreviewContent
                    }

                    // Publish Button (always visible)
                    publishButton
                        .padding(.top, 8)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Program Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") {
                        isPresented = false
                    }
                }
            }
            .alert("Publish Program?", isPresented: $showPublishConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Publish") {
                    Task {
                        await publishProgram()
                    }
                }
            } message: {
                Text("This will make '\(viewModel.programName)' available in the program library for patients to browse and enroll.")
            }
        }
    }

    // MARK: - Preview Toggle

    private var previewToggle: some View {
        Picker("Preview Mode", selection: $selectedPreviewTab) {
            ForEach(PreviewTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Switch between builder view and patient view")
    }

    // MARK: - Therapist Preview Content

    private var therapistPreviewContent: some View {
        VStack(spacing: 24) {
            // Header Section (program name and type)
            headerSection

            // Patient Section (if assigned)
            if viewModel.selectedPatient != nil {
                patientSection
            }

            // Timeline Section
            timelineSection

            // Week-by-Week Workout Calendar
            weeklyWorkoutCalendar

            // Phase Cards Section (with week ranges)
            phaseCardsSection

            // Summary Stats Section
            summaryStatsSection
        }
    }

    // MARK: - Patient Preview Content

    private var patientPreviewContent: some View {
        VStack(spacing: 24) {
            // Patient-facing header
            patientPreviewHeader

            // How it looks in their app
            patientProgramCard

            // What they'll see for each phase
            patientPhaseList

            // Exercise count and commitment info
            patientCommitmentSection
        }
    }

    // MARK: - Patient Preview Header

    private var patientPreviewHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "eye.fill")
                .font(.title)
                .foregroundColor(.blue)
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
                .accessibilityHidden(true)

            Text("How Patients Will See It")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Patient Program Card (Preview)

    private var patientProgramCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Program Card Preview")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            // Simulated program card as patient would see
            VStack(alignment: .leading, spacing: 12) {
                // Cover image placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(categoryGradient)
                    .frame(height: 120)
                    .overlay(
                        VStack {
                            Image(systemName: categoryIcon)
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.9))
                            Text(viewModel.programName.isEmpty ? "Untitled Program" : viewModel.programName)
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                    )

                // Program info
                HStack(spacing: 16) {
                    // Duration
                    Label("\(viewModel.totalPhaseDuration) weeks", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Difficulty
                    let difficulty = DifficultyLevel(rawValue: viewModel.difficultyLevel) ?? .intermediate
                    Text(difficulty.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(difficulty.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(difficulty.color.opacity(0.15))
                        .cornerRadius(CornerRadius.sm)

                    Spacer()

                    // Workouts count
                    Label("\(totalWorkouts) workouts", systemImage: "dumbbell.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Description preview
                if !viewModel.description.isEmpty {
                    Text(viewModel.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.lg)
            .shadow(color: Color(.systemGray4).opacity(0.05), radius: 4, y: 2)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private var categoryGradient: LinearGradient {
        let category = ProgramCategory(rawValue: viewModel.category) ?? .strength
        return LinearGradient(
            colors: [category.color, category.color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var categoryIcon: String {
        let category = ProgramCategory(rawValue: viewModel.category) ?? .strength
        return category.icon
    }

    // MARK: - Patient Phase List

    private var patientPhaseList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Phase Overview (Patient View)")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            if viewModel.phases.isEmpty {
                Text("No phases defined yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                let phaseWeekRanges = calculatePhaseWeekRanges()
                ForEach(Array(viewModel.phases.enumerated()), id: \.element.id) { index, phase in
                    let range = phaseWeekRanges[index]
                    PatientPhasePreviewCard(
                        phase: phase,
                        phaseNumber: index + 1,
                        startWeek: range.start,
                        endWeek: range.end
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Patient Commitment Section

    private var patientCommitmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Commitment Summary")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                CommitmentRow(
                    icon: "calendar",
                    title: "Duration",
                    value: "\(viewModel.totalPhaseDuration) weeks",
                    color: .blue
                )

                CommitmentRow(
                    icon: "figure.strengthtraining.traditional",
                    title: "Total Workouts",
                    value: "\(totalWorkouts)",
                    color: .green
                )

                CommitmentRow(
                    icon: "clock",
                    title: "Avg. Workouts/Week",
                    value: String(format: "%.1f", averageWorkoutsPerWeek),
                    color: .orange
                )

                CommitmentRow(
                    icon: "dumbbell.fill",
                    title: "Total Exercises",
                    value: "\(totalExerciseCount)",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private var averageWorkoutsPerWeek: Double {
        guard viewModel.totalPhaseDuration > 0 else { return 0 }
        return Double(totalWorkouts) / Double(viewModel.totalPhaseDuration)
    }

    private var totalExerciseCount: Int {
        // Estimate: assume ~6 exercises per workout on average
        totalWorkouts * 6
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Program name
            Text(viewModel.programName.isEmpty ? "Untitled Program" : viewModel.programName)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            // Type badge and duration
            HStack(spacing: 12) {
                // Category badge
                categoryBadge

                // Duration pill
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("\(viewModel.totalPhaseDuration) weeks")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.sm)

                // Difficulty badge
                difficultyBadge
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Patient Section

    private var patientSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assigned Patient")
                .font(.headline)
                .fontWeight(.semibold)

            if let patient = viewModel.selectedPatient {
                HStack(spacing: 12) {
                    // Patient avatar
                    Circle()
                        .fill(Color.blue.gradient)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(patient.initials)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        )
                        .accessibilityHidden(true)

                    // Patient info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(patient.fullName)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if let condition = patient.injuryType {
                            Text(condition)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if let sport = patient.sport {
                            Text(sport)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "person.fill.checkmark")
                        .foregroundColor(.green)
                        .font(.title3)
                        .accessibilityLabel("Patient assigned")
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.md)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .accessibilityElement(children: .contain)
    }

    private var categoryBadge: some View {
        let category = ProgramCategory(rawValue: viewModel.category) ?? .strength
        return HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption)
            Text(category.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(category.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(category.color.opacity(0.15))
        .cornerRadius(CornerRadius.sm)
    }

    private var difficultyBadge: some View {
        let difficulty = DifficultyLevel(rawValue: viewModel.difficultyLevel) ?? .intermediate
        return Text(difficulty.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(difficulty.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(difficulty.color.opacity(0.15))
            .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Timeline Section

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Program Timeline")
                .font(.headline)
                .fontWeight(.semibold)

            // Horizontal timeline
            if !viewModel.phases.isEmpty {
                ProgramTimelineView(phases: viewModel.phases)
            } else {
                Text("No phases defined")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Weekly Workout Calendar

    private var weeklyWorkoutCalendar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Week-by-Week Schedule")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(totalWorkouts) total workouts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.phases.isEmpty {
                Text("Add phases to see weekly schedule")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                WeeklyCalendarGrid(phases: viewModel.phases)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Phase Cards Section

    private var phaseCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Phase Breakdown (\(viewModel.phases.count))")
                .font(.headline)
                .fontWeight(.semibold)

            if viewModel.phases.isEmpty {
                emptyPhasesCard
            } else {
                let phaseWeekRanges = calculatePhaseWeekRanges()
                ForEach(Array(viewModel.phases.enumerated()), id: \.element.id) { index, phase in
                    let range = phaseWeekRanges[index]
                    PhasePreviewCard(
                        phase: phase,
                        phaseNumber: index + 1,
                        startWeek: range.start,
                        endWeek: range.end
                    )
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
    }

    /// Calculate the week ranges for each phase
    private func calculatePhaseWeekRanges() -> [(start: Int, end: Int)] {
        var ranges: [(start: Int, end: Int)] = []
        var currentWeek = 1

        for phase in viewModel.phases {
            let startWeek = currentWeek
            let endWeek = currentWeek + phase.durationWeeks - 1
            ranges.append((start: startWeek, end: endWeek))
            currentWeek = endWeek + 1
        }

        return ranges
    }

    private var emptyPhasesCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No phases added yet")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Go back to add phases before publishing")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Summary Stats Section

    private var summaryStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                SummaryStatCard(
                    title: "Total Weeks",
                    value: "\(viewModel.totalPhaseDuration)",
                    icon: "calendar",
                    color: .blue
                )

                SummaryStatCard(
                    title: "Phases",
                    value: "\(viewModel.phases.count)",
                    icon: "chart.bar.fill",
                    color: .purple
                )

                SummaryStatCard(
                    title: "Workouts",
                    value: "\(totalWorkouts)",
                    icon: "dumbbell.fill",
                    color: .green
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private var totalWorkouts: Int {
        viewModel.phases.reduce(0) { $0 + $1.workoutAssignments.count }
    }

    // MARK: - Publish Button

    private var publishButton: some View {
        Button {
            showPublishConfirmation = true
        } label: {
            HStack(spacing: 8) {
                if isPublishing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.up.doc.fill")
                }
                Text(isPublishing ? "Publishing..." : "Publish to Library")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canPublish ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.md)
        }
        .disabled(!canPublish || isPublishing)
        .accessibilityLabel(canPublish ? "Publish program to library" : "Cannot publish - program is incomplete")
        .accessibilityHint(canPublish ? "Double tap to publish this program" : "Add phases with workouts to enable publishing")
    }

    private var canPublish: Bool {
        viewModel.isReadyToPublish
    }

    // MARK: - Actions

    private func publishProgram() async {
        isPublishing = true

        do {
            try await viewModel.publishToLibrary()
            isPresented = false
        } catch {
            // Error is handled in viewModel
        }

        isPublishing = false
    }
}

// MARK: - Weekly Calendar Grid

private struct WeeklyCalendarGrid: View {
    let phases: [TherapistPhaseData]

    private let phaseColors: [Color] = [.blue, .purple, .orange, .green, .pink, .teal]
    private let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    private var totalWeeks: Int {
        max(1, phases.reduce(0) { $0 + $1.durationWeeks })
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 8) {
                // Week headers
                HStack(spacing: 4) {
                    Text("")
                        .frame(width: 40)

                    ForEach(1...min(totalWeeks, 12), id: \.self) { week in
                        Text("W\(week)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(width: 44)
                    }

                    if totalWeeks > 12 {
                        Text("...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 30)
                    }
                }

                // Day rows
                ForEach(1...7, id: \.self) { day in
                    HStack(spacing: 4) {
                        Text(daysOfWeek[day - 1])
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .leading)

                        ForEach(1...min(totalWeeks, 12), id: \.self) { week in
                            let workoutInfo = getWorkoutInfo(week: week, day: day)
                            DayCell(
                                hasWorkout: workoutInfo.hasWorkout,
                                phaseColor: workoutInfo.color,
                                workoutCount: workoutInfo.count
                            )
                        }

                        if totalWeeks > 12 {
                            Text("")
                                .frame(width: 30)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func getWorkoutInfo(week: Int, day: Int) -> (hasWorkout: Bool, color: Color, count: Int) {
        var currentWeek = 1

        for (index, phase) in phases.enumerated() {
            let phaseEndWeek = currentWeek + phase.durationWeeks - 1

            if week >= currentWeek && week <= phaseEndWeek {
                let phaseWeek = week - currentWeek + 1
                let workouts = phase.workoutAssignments.filter {
                    $0.weekNumber == phaseWeek && $0.dayOfWeek == day
                }
                let color = phaseColors[index % phaseColors.count]
                return (hasWorkout: !workouts.isEmpty, color: color, count: workouts.count)
            }

            currentWeek = phaseEndWeek + 1
        }

        return (hasWorkout: false, color: .gray, count: 0)
    }
}

private struct DayCell: View {
    let hasWorkout: Bool
    let phaseColor: Color
    let workoutCount: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(hasWorkout ? phaseColor.opacity(0.2) : Color(.systemGray6))
                .frame(width: 44, height: 28)

            if hasWorkout {
                Circle()
                    .fill(phaseColor)
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityLabel(hasWorkout ? "\(workoutCount) workout\(workoutCount == 1 ? "" : "s")" : "No workout")
    }
}

// MARK: - Program Timeline View

private struct ProgramTimelineView: View {
    let phases: [TherapistPhaseData]

    private let phaseColors: [Color] = [.blue, .purple, .orange, .green, .pink, .teal]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(phases.enumerated()), id: \.element.id) { index, phase in
                    TimelinePhaseSegment(
                        phase: phase,
                        phaseNumber: index + 1,
                        color: phaseColors[index % phaseColors.count],
                        isLast: index == phases.count - 1,
                        totalWeeks: totalDuration
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var totalDuration: Int {
        phases.reduce(0) { $0 + $1.durationWeeks }
    }
}

private struct TimelinePhaseSegment: View {
    let phase: TherapistPhaseData
    let phaseNumber: Int
    let color: Color
    let isLast: Bool
    let totalWeeks: Int

    private var widthRatio: CGFloat {
        guard totalWeeks > 0 else { return 1.0 }
        return CGFloat(phase.durationWeeks) / CGFloat(totalWeeks)
    }

    var body: some View {
        VStack(spacing: 4) {
            // Phase bar
            HStack(spacing: 0) {
                Rectangle()
                    .fill(color)
                    .frame(width: max(60, 200 * widthRatio), height: 24)
                    .cornerRadius(isLast ? 4 : 0, corners: isLast ? [.topRight, .bottomRight] : [])
                    .cornerRadius(phaseNumber == 1 ? 4 : 0, corners: phaseNumber == 1 ? [.topLeft, .bottomLeft] : [])
                    .overlay(
                        Text("\(phase.durationWeeks)w")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }

            // Phase name
            Text(phase.name.isEmpty ? "Phase \(phaseNumber)" : phase.name)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: max(60, 200 * widthRatio))
        }
    }
}

// MARK: - Phase Preview Card

private struct PhasePreviewCard: View {
    let phase: TherapistPhaseData
    let phaseNumber: Int
    let startWeek: Int
    let endWeek: Int

    private let phaseColors: [Color] = [.blue, .purple, .orange, .green, .pink, .teal]

    private var phaseColor: Color {
        phaseColors[(phaseNumber - 1) % phaseColors.count]
    }

    private var weekRangeText: String {
        if startWeek == endWeek {
            return "Week \(startWeek)"
        } else {
            return "Weeks \(startWeek)-\(endWeek)"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack {
                // Phase number badge
                Text("\(phaseNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(phaseColor))

                // Phase name
                Text(phase.name.isEmpty ? "Phase \(phaseNumber)" : phase.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                // Duration
                Text("\(phase.durationWeeks) weeks")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.sm)
            }

            // Week range
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(weekRangeText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Goals (if any)
            if !phase.goals.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "target")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(phase.goals)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            // Workout count
            HStack(spacing: 4) {
                Image(systemName: "dumbbell.fill")
                    .font(.caption)
                    .foregroundColor(phaseColor)

                Text("\(phase.workoutAssignments.count) workouts assigned")
                    .font(.caption)
                    .foregroundColor(phase.workoutAssignments.isEmpty ? .orange : .secondary)
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(phase.name.isEmpty ? "Phase \(phaseNumber)" : phase.name), \(weekRangeText), \(phase.durationWeeks) weeks, \(phase.workoutAssignments.count) workouts")
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Patient Phase Preview Card

private struct PatientPhasePreviewCard: View {
    let phase: TherapistPhaseData
    let phaseNumber: Int
    let startWeek: Int
    let endWeek: Int

    private let phaseColors: [Color] = [.blue, .purple, .orange, .green, .pink, .teal]

    private var phaseColor: Color {
        phaseColors[(phaseNumber - 1) % phaseColors.count]
    }

    var body: some View {
        HStack(spacing: 12) {
            // Phase indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(phaseColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(phase.name.isEmpty ? "Phase \(phaseNumber)" : phase.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    Label("Weeks \(startWeek)-\(endWeek)", systemImage: "calendar")
                    Label("\(phase.workoutAssignments.count) workouts", systemImage: "figure.strengthtraining.traditional")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            // Phase number
            Text("\(phaseNumber)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(phaseColor)
                .frame(width: 24, height: 24)
                .background(phaseColor.opacity(0.15))
                .cornerRadius(CornerRadius.sm)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Commitment Row

private struct CommitmentRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Summary Stat Card

private struct SummaryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Preview

#if DEBUG
struct ProgramPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TherapistProgramBuilderViewModel()
        viewModel.programName = "12-Week Strength Foundation"
        viewModel.description = "A comprehensive strength building program designed for athletes looking to build a solid foundation of strength and power."
        viewModel.category = "strength"
        viewModel.difficultyLevel = "intermediate"
        viewModel.phases = [
            TherapistPhaseData(
                name: "Adaptation",
                sequence: 1,
                durationWeeks: 3,
                goals: "Movement proficiency, work capacity, tissue preparation",
                workoutAssignments: [
                    TherapistWorkoutAssignment(
                        templateId: UUID(),
                        templateName: "Lower Body A",
                        weekNumber: 1,
                        dayOfWeek: 1
                    ),
                    TherapistWorkoutAssignment(
                        templateId: UUID(),
                        templateName: "Upper Body A",
                        weekNumber: 1,
                        dayOfWeek: 3
                    ),
                    TherapistWorkoutAssignment(
                        templateId: UUID(),
                        templateName: "Full Body",
                        weekNumber: 1,
                        dayOfWeek: 5
                    )
                ]
            ),
            TherapistPhaseData(
                name: "Hypertrophy",
                sequence: 2,
                durationWeeks: 3,
                goals: "Muscle growth, increased volume, progressive overload",
                workoutAssignments: [
                    TherapistWorkoutAssignment(
                        templateId: UUID(),
                        templateName: "Push Day",
                        weekNumber: 1,
                        dayOfWeek: 1
                    ),
                    TherapistWorkoutAssignment(
                        templateId: UUID(),
                        templateName: "Pull Day",
                        weekNumber: 1,
                        dayOfWeek: 3
                    )
                ]
            ),
            TherapistPhaseData(
                name: "Strength",
                sequence: 3,
                durationWeeks: 3,
                goals: "Maximal strength development, neural adaptations",
                workoutAssignments: []
            ),
            TherapistPhaseData(
                name: "Power",
                sequence: 4,
                durationWeeks: 3,
                goals: "Rate of force development, explosive training",
                workoutAssignments: []
            )
        ]

        return ProgramPreviewView(viewModel: viewModel, isPresented: .constant(true))
    }
}
#endif
