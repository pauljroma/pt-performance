//
//  PatientProgramProgressView.swift
//  PTPerformance
//
//  Shows detailed program progress for a specific patient.
//  Used by therapists to monitor patient adherence and workout completion.
//

import SwiftUI
import Charts

// MARK: - Main View

struct PatientProgramProgressView: View {
    let patient: Patient

    @StateObject private var viewModel = PatientProgramProgressViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if viewModel.hasPrograms {
                    // Patient header
                    PatientProgressHeader(
                        patient: patient,
                        enrollmentDate: viewModel.selectedProgram?.enrolledAt,
                        activeProgramsCount: viewModel.activeProgramsCount
                    )

                    // Program selector (if multiple programs)
                    if viewModel.enrolledPrograms.count > 1 {
                        programSelector
                    }

                    // Selected program info
                    if let program = viewModel.selectedProgram {
                        ProgramInfoCard(program: program)

                        // Progress visualization
                        ProgressVisualizationCard(
                            program: program,
                            weeklyCompletions: viewModel.weeklyCompletions,
                            isLoading: viewModel.isLoadingDetails
                        )

                        // Workout completion stats
                        WorkoutCompletionCard(
                            program: program,
                            metrics: viewModel.adherenceMetrics
                        )

                        // Recent workout activity
                        if !viewModel.recentWorkouts.isEmpty || viewModel.isLoadingDetails {
                            RecentActivityCard(
                                workouts: viewModel.recentWorkouts,
                                isLoading: viewModel.isLoadingDetails
                            )
                        }

                        // Adherence metrics
                        if let metrics = viewModel.adherenceMetrics {
                            AdherenceMetricsCard(metrics: metrics)
                        }
                    }
                } else {
                    emptyStateView
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Program Progress")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await viewModel.refresh()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Refresh")
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadData(for: patient)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading program progress...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading program progress")
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Unable to Load Progress")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await viewModel.refresh()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Programs Assigned")
                .font(.headline)

            Text("\(patient.firstName) is not currently enrolled in any programs. Assign a program to start tracking their progress.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No programs assigned to \(patient.fullName)")
    }

    // MARK: - Program Selector

    private var programSelector: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Programs")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(viewModel.enrolledPrograms) { program in
                        ProgramSelectorPill(
                            program: program,
                            isSelected: viewModel.selectedProgram?.id == program.id
                        ) {
                            HapticFeedback.selectionChanged()
                            Task {
                                await viewModel.selectProgram(program)
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

// MARK: - Patient Progress Header

struct PatientProgressHeader: View {
    let patient: Patient
    let enrollmentDate: Date?
    let activeProgramsCount: Int

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Avatar and name
            HStack(spacing: Spacing.md) {
                ProfileAvatarImage(
                    profileImageUrl: patient.profileImageUrl,
                    firstName: patient.firstName,
                    lastName: patient.lastName,
                    size: 64
                )

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(patient.fullName)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let sport = patient.sport, let position = patient.position {
                        Label("\(sport) - \(position)", systemImage: "sportscourt")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let injury = patient.injuryType {
                        Label(injury, systemImage: "cross.case")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            // Enrollment info
            HStack {
                if let date = enrollmentDate {
                    Label("Enrolled \(date, style: .date)", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Label("\(activeProgramsCount) Active", systemImage: "doc.text.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Patient \(patient.fullName), \(activeProgramsCount) active programs")
    }
}

// MARK: - Program Selector Pill

struct ProgramSelectorPill: View {
    let program: PatientProgramEnrollment
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(program.programTitle)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: program.status.icon)
                        .font(.caption2)
                        .foregroundColor(program.status.color)

                    Text("Week \(program.currentWeek)")
                        .font(.caption2)
                }
                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(CornerRadius.md)
        }
        .accessibilityLabel("\(program.programTitle), Week \(program.currentWeek)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Program Info Card

struct ProgramInfoCard: View {
    let program: PatientProgramEnrollment

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(program.programTitle)
                        .font(.headline)

                    Text(program.programCategory)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: program.status.icon)
                    Text(program.status.displayName)
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(program.status.color)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 4)
                .background(program.status.color.opacity(0.15))
                .cornerRadius(CornerRadius.sm)
            }

            Divider()

            // Program details grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                InfoStatItem(
                    icon: "calendar",
                    label: "Duration",
                    value: "\(program.durationWeeks) weeks"
                )

                InfoStatItem(
                    icon: "flag.fill",
                    label: "Current",
                    value: "Week \(program.currentWeek)"
                )

                InfoStatItem(
                    icon: "chart.bar.fill",
                    label: "Difficulty",
                    value: program.difficultyLevel.capitalized
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
    }
}

struct InfoStatItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Progress Visualization Card

struct ProgressVisualizationCard: View {
    let program: PatientProgramEnrollment
    let weeklyCompletions: [PatientProgramProgressViewModel.WeeklyCompletion]
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Progress Timeline")
                    .font(.headline)

                Spacer()

                Text("\(Int(program.progress * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(progressColor)
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                // Main progress bar
                VStack(spacing: Spacing.xs) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                                .frame(height: 24)

                            // Progress fill
                            RoundedRectangle(cornerRadius: 8)
                                .fill(progressGradient)
                                .frame(width: geometry.size.width * program.progress, height: 24)

                            // Week markers
                            HStack(spacing: 0) {
                                ForEach(1..<program.durationWeeks, id: \.self) { week in
                                    Spacer()
                                    Rectangle()
                                        .fill(Color(.systemGray3))
                                        .frame(width: 1, height: 16)
                                }
                                Spacer()
                            }
                            .frame(height: 24)
                        }
                    }
                    .frame(height: 24)

                    // Week labels
                    HStack {
                        Text("Week 1")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("Week \(program.durationWeeks)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Weekly completion bars (if available)
                if !weeklyCompletions.isEmpty {
                    Divider()
                        .padding(.vertical, Spacing.xs)

                    Text("Weekly Completions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(weeklyCompletions) { week in
                            WeeklyCompletionBar(
                                week: week,
                                isCurrent: week.weekNumber == program.currentWeek
                            )
                        }
                    }
                    .frame(height: 60)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private var progressColor: Color {
        switch program.progress {
        case 0.8...: return .green
        case 0.5..<0.8: return .blue
        case 0.25..<0.5: return .orange
        default: return .gray
        }
    }

    private var progressGradient: LinearGradient {
        LinearGradient(
            colors: [progressColor.opacity(0.8), progressColor],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct WeeklyCompletionBar: View {
    let week: PatientProgramProgressViewModel.WeeklyCompletion
    let isCurrent: Bool

    var body: some View {
        VStack(spacing: 2) {
            // Bar
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray5))

                RoundedRectangle(cornerRadius: 3)
                    .fill(barColor)
                    .frame(height: max(4, 40 * week.completionRate))
            }
            .frame(maxWidth: .infinity, maxHeight: 40)

            // Week number
            Text("\(week.weekNumber)")
                .font(.caption2)
                .foregroundColor(isCurrent ? .blue : .secondary)
                .fontWeight(isCurrent ? .bold : .regular)
        }
    }

    private var barColor: Color {
        switch week.completionRate {
        case 0.8...: return .green
        case 0.5..<0.8: return .yellow
        case 0.01..<0.5: return .orange
        default: return .gray.opacity(0.3)
        }
    }
}

// MARK: - Workout Completion Card

struct WorkoutCompletionCard: View {
    let program: PatientProgramEnrollment
    let metrics: ProgramAdherenceMetrics?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Workout Completion")
                .font(.headline)

            HStack(spacing: Spacing.xl) {
                // Completed
                CompletionStatCircle(
                    value: program.completedWorkouts,
                    total: program.totalWorkouts,
                    label: "Completed",
                    color: .green
                )

                // Remaining
                CompletionStatCircle(
                    value: program.remainingWorkouts,
                    total: program.totalWorkouts,
                    label: "Remaining",
                    color: .orange
                )

                // On Track indicator
                VStack(spacing: Spacing.xs) {
                    Image(systemName: isOnTrack ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(isOnTrack ? .green : .orange)

                    Text(isOnTrack ? "On Track" : "Behind")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isOnTrack ? .green : .orange)
                }
                .frame(maxWidth: .infinity)
            }

            // Progress bar
            HStack(spacing: Spacing.sm) {
                ProgressView(value: Double(program.completedWorkouts), total: Double(max(1, program.totalWorkouts)))
                    .tint(.green)

                Text("\(program.completedWorkouts)/\(program.totalWorkouts)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private var isOnTrack: Bool {
        guard let metrics = metrics else {
            return program.progressPercentage >= 70
        }
        return metrics.adherenceRate >= 70
    }
}

struct CompletionStatCircle: View {
    let value: Int
    let total: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 6)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: total > 0 ? Double(value) / Double(total) : 0)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))

                Text("\(value)")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value) of \(total)")
    }
}

// MARK: - Recent Activity Card

struct RecentActivityCard: View {
    let workouts: [CompletedWorkout]
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)

                Spacer()

                Text("Last 5 workouts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if isLoading {
                VStack(spacing: Spacing.sm) {
                    ForEach(0..<3, id: \.self) { _ in
                        HStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 50)
                        }
                    }
                }
            } else if workouts.isEmpty {
                Text("No completed workouts yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing.md)
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(workouts) { workout in
                        RecentWorkoutRow(workout: workout)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
    }
}

struct RecentWorkoutRow: View {
    let workout: CompletedWorkout

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }

            // Workout info
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: Spacing.sm) {
                    if let duration = workout.durationMinutes {
                        Label("\(duration) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let volume = workout.totalVolume, volume > 0 {
                        Label(formatVolume(volume), systemImage: "scalemass")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Date
            Text(workout.completedAt, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(workout.displayName), completed \(workout.completedAt, style: .relative)")
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fK lbs", volume / 1000)
        } else {
            return String(format: "%.0f lbs", volume)
        }
    }
}

// MARK: - Adherence Metrics Card

struct AdherenceMetricsCard: View {
    let metrics: ProgramAdherenceMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Adherence Metrics")
                    .font(.headline)

                Spacer()

                // Overall adherence badge
                HStack(spacing: 4) {
                    Image(systemName: adherenceIcon)
                    Text("\(Int(metrics.adherenceRate))%")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(adherenceColor)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 4)
                .background(adherenceColor.opacity(0.15))
                .cornerRadius(CornerRadius.sm)
            }

            // Metrics grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                AdherenceMetricItem(
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    label: "Completed On Time",
                    value: "\(metrics.completedOnTime)"
                )

                AdherenceMetricItem(
                    icon: "xmark.circle.fill",
                    iconColor: .red,
                    label: "Missed",
                    value: "\(metrics.missedWorkouts)"
                )

                AdherenceMetricItem(
                    icon: "calendar",
                    iconColor: .blue,
                    label: "Total Scheduled",
                    value: "\(metrics.totalScheduled)"
                )

                AdherenceMetricItem(
                    icon: "flame.fill",
                    iconColor: .orange,
                    label: "Current Streak",
                    value: "\(metrics.currentStreak) days"
                )
            }

            // Visual breakdown bar
            if metrics.totalScheduled > 0 {
                VStack(spacing: Spacing.xs) {
                    GeometryReader { geometry in
                        HStack(spacing: 2) {
                            // Completed section
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: geometry.size.width * (metrics.completedPercentage / 100))

                            // Missed section
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: geometry.size.width * (metrics.missedPercentage / 100))

                            // Remaining section
                            Rectangle()
                                .fill(Color(.systemGray4))
                        }
                        .cornerRadius(4)
                    }
                    .frame(height: 12)

                    // Legend
                    HStack(spacing: Spacing.lg) {
                        AdherenceLegendItem(color: .green, label: "Completed")
                        AdherenceLegendItem(color: .red, label: "Missed")
                        AdherenceLegendItem(color: Color(.systemGray4), label: "Remaining")
                    }
                    .font(.caption2)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private var adherenceColor: Color {
        switch metrics.adherenceRate {
        case 80...: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }

    private var adherenceIcon: String {
        switch metrics.adherenceRate {
        case 80...: return "star.fill"
        case 60..<80: return "checkmark.circle"
        default: return "exclamationmark.triangle"
        }
    }
}

struct AdherenceMetricItem: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

private struct AdherenceLegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PatientProgramProgressView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PatientProgramProgressView(patient: Patient(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                therapistId: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
                firstName: "John",
                lastName: "Brebbia",
                email: "john@example.com",
                sport: "Baseball",
                position: "Pitcher",
                injuryType: "Tommy John Recovery",
                targetLevel: "MLB",
                profileImageUrl: nil,
                createdAt: Date(),
                flagCount: 0,
                highSeverityFlagCount: 0,
                adherencePercentage: 85.0,
                lastSessionDate: Date()
            ))
        }
    }
}
#endif
