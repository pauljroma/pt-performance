//
//  EnhancedWorkoutSummaryView.swift
//  PTPerformance
//
//  ACP-1016: Workout Summary Enhancement
//  Richer post-workout summary with volume, PRs, muscle breakdown, and sharing
//

import SwiftUI
import Charts

// MARK: - Enhanced Workout Summary View

/// Enhanced post-workout summary with detailed stats, PR celebrations, and sharing
struct EnhancedWorkoutSummaryView: View {
    let workoutName: String
    let completedAt: Date
    let duration: Int?
    let totalVolume: Double
    let previousVolume: Double?
    let exercisesCompleted: [ExerciseSummary]
    let muscleGroupBreakdown: [MuscleGroupVolume]
    let currentStreak: Int
    let onDismiss: () -> Void
    let onShare: ((UIImage) -> Void)?

    @State private var workoutNote: String = ""
    @State private var selectedMood: WorkoutMood?
    @State private var showShareSheet = false
    @State private var summaryImage: UIImage?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    headerSection

                    // Total Volume Section
                    volumeSection

                    // PR Highlights
                    if !personalRecords.isEmpty {
                        prSection
                    }

                    // Muscle Group Breakdown
                    muscleGroupSection

                    // Comparison to Last Session
                    if let previousVolume = previousVolume {
                        comparisonSection(previousVolume: previousVolume)
                    }

                    // Quick Note Entry
                    noteSection

                    // Share Button
                    shareButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Workout Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticFeedback.light()
                        onDismiss()
                    }
                    .foregroundColor(.modusCyan)
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.modusTealAccent)
                .accessibilityHidden(true)

            Text(workoutName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.modusPrimary)
                .accessibilityAddTraits(.isHeader)

            Text(completedAt, style: .date)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if currentStreak > 0 {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange, .red],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Text("\(currentStreak) Day Streak")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundColor(.orange)
                .accessibilityLabel("\(currentStreak) day workout streak")
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Volume Section

    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Total Volume Lifted")
                .font(.headline)
                .foregroundColor(.modusPrimary)
                .accessibilityAddTraits(.isHeader)

            HStack(alignment: .bottom, spacing: Spacing.xs) {
                Text(formatVolume(totalVolume))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.modusCyan)

                Text("lbs")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .padding(.bottom, Spacing.xs)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Total volume lifted: \(formatVolume(totalVolume)) pounds")

            if let previousVolume = previousVolume, previousVolume > 0 {
                volumeComparisonIndicator(current: totalVolume, previous: previousVolume)
            }

            if let duration = duration {
                HStack(spacing: Spacing.md) {
                    Label("\(duration) min", systemImage: "clock.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Label("\(exercisesCompleted.count) exercises", systemImage: "figure.strengthtraining.traditional")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private func volumeComparisonIndicator(current: Double, previous: Double) -> some View {
        let delta = current - previous
        let percentChange = (delta / previous) * 100
        let isIncrease = delta > 0

        return HStack(spacing: Spacing.xs) {
            Image(systemName: isIncrease ? "arrow.up.right" : "arrow.down.right")
                .font(.caption)
                .foregroundColor(isIncrease ? .modusTealAccent : .orange)

            Text("\(abs(Int(delta))) lbs (\(String(format: "%.1f", abs(percentChange)))%)")
                .font(.subheadline)
                .foregroundColor(isIncrease ? .modusTealAccent : .orange)

            Text("vs last session")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityLabel("\(isIncrease ? "Increased" : "Decreased") by \(abs(Int(delta))) pounds, \(String(format: "%.1f", abs(percentChange))) percent compared to last session")
    }

    // MARK: - PR Section

    private var personalRecords: [ExerciseSummary] {
        exercisesCompleted.filter { $0.isPersonalRecord }
    }

    private var prSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                    .accessibilityHidden(true)

                Text("New Personal Records!")
                    .font(.headline)
                    .foregroundColor(.modusPrimary)
            }
            .accessibilityAddTraits(.isHeader)

            ForEach(personalRecords) { exercise in
                PRCelebrationCard(exercise: exercise)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color.yellow.opacity(0.1),
                    Color.orange.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 2)
        )
        .onAppear {
            if !personalRecords.isEmpty {
                HapticFeedback.success()
            }
        }
    }

    private var sortedMuscleGroups: [MuscleGroupVolume] {
        muscleGroupBreakdown.sorted(by: { $0.volume > $1.volume })
    }

    // MARK: - Muscle Group Section

    private var muscleGroupSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Muscle Groups Trained")
                .font(.headline)
                .foregroundColor(.modusPrimary)
                .accessibilityAddTraits(.isHeader)

            if !muscleGroupBreakdown.isEmpty {
                muscleGroupChart
                muscleGroupList
            } else {
                Text("No muscle group data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private var muscleGroupChart: some View {
        Chart {
            ForEach(sortedMuscleGroups) { group in
                BarMark(
                    x: .value("Volume", group.volume),
                    y: .value("Muscle Group", group.displayName)
                )
                .foregroundStyle(group.color)
                .annotation(position: .trailing) {
                    Text(formatVolume(group.volume))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: CGFloat(muscleGroupBreakdown.count) * 40)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityLabel("Muscle group volume breakdown chart")
    }

    private var muscleGroupList: some View {
        VStack(spacing: Spacing.xs) {
            ForEach(sortedMuscleGroups) { group in
                HStack {
                    Circle()
                        .fill(group.color)
                        .frame(width: 8, height: 8)
                        .accessibilityHidden(true)

                    Text(group.displayName)
                        .font(.caption)
                        .foregroundColor(.primary)

                    Spacer()

                    Text("\(formatVolume(group.volume)) lbs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.top, Spacing.sm)
    }

    // MARK: - Comparison Section

    private func comparisonSection(previousVolume: Double) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("vs Last Session")
                .font(.headline)
                .foregroundColor(.modusPrimary)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Previous")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatVolume(previousVolume))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }

                Image(systemName: "arrow.right")
                    .foregroundColor(.modusCyan)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatVolume(totalVolume))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.modusCyan)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Previous session: \(formatVolume(previousVolume)) pounds, Today: \(formatVolume(totalVolume)) pounds")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Note Section

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("How did this workout feel?")
                .font(.headline)
                .foregroundColor(.modusPrimary)
                .accessibilityAddTraits(.isHeader)

            // Mood selector
            HStack(spacing: Spacing.md) {
                ForEach(WorkoutMood.allCases) { mood in
                    moodButton(mood)
                }
            }
            .accessibilityElement(children: .contain)

            // Note text field
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Notes (optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Add notes about this workout...", text: $workoutNote, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                    .accessibilityLabel("Workout notes")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private func moodButton(_ mood: WorkoutMood) -> some View {
        Button(action: {
            HapticFeedback.selectionChanged()
            selectedMood = selectedMood == mood ? nil : mood
        }) {
            VStack(spacing: Spacing.xxs) {
                Text(mood.emoji)
                    .font(.title2)
                Text(mood.label)
                    .font(.caption2)
                    .foregroundColor(selectedMood == mood ? .modusCyan : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(
                selectedMood == mood
                    ? Color.modusCyan.opacity(0.1)
                    : Color(.tertiarySystemGroupedBackground)
            )
            .cornerRadius(CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(selectedMood == mood ? Color.modusCyan : Color.clear, lineWidth: 2)
            )
        }
        .accessibilityLabel("\(mood.label) mood")
        .accessibilityAddTraits(selectedMood == mood ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Share Button

    private var shareButton: some View {
        Button(action: {
            HapticFeedback.medium()
            generateSummaryCard()
        }) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Share Workout Summary")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                LinearGradient(
                    colors: [.modusCyan, .modusTealAccent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(CornerRadius.md)
        }
        .accessibilityLabel("Share workout summary")
    }

    // MARK: - Helper Methods

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }

    @MainActor
    private func generateSummaryCard() {
        let renderer = ImageRenderer(content: ShareableSummaryCard(
            workoutName: workoutName,
            completedAt: completedAt,
            totalVolume: totalVolume,
            duration: duration,
            exerciseCount: exercisesCompleted.count,
            prCount: personalRecords.count,
            streak: currentStreak
        ))

        renderer.scale = 3.0

        if let image = renderer.uiImage {
            summaryImage = image
            onShare?(image)
        }
    }
}

// MARK: - PR Celebration Card

private struct PRCelebrationCard: View {
    let exercise: ExerciseSummary
    @State private var showConfetti = false

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if let prDetails = exercise.prDetails {
                    Text(prDetails)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if showConfetti {
                Text("🎉")
                    .font(.title2)
            }
        }
        .padding(Spacing.sm)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3).delay(0.2)) {
                showConfetti = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Personal record: \(exercise.name)")
    }
}

// MARK: - Shareable Summary Card

private struct ShareableSummaryCard: View {
    let workoutName: String
    let completedAt: Date
    let totalVolume: Double
    let duration: Int?
    let exerciseCount: Int
    let prCount: Int
    let streak: Int

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Header with branding
            VStack(spacing: Spacing.xs) {
                Text("PT PERFORMANCE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.modusCyan)
                    .tracking(2)

                Text(workoutName)
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.modusPrimary)

                Text(completedAt, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                StatCardMini(
                    value: formatVolume(totalVolume),
                    unit: "lbs",
                    label: "Total Volume",
                    icon: "scalemass.fill",
                    color: .modusCyan
                )

                if let duration = duration {
                    StatCardMini(
                        value: "\(duration)",
                        unit: "min",
                        label: "Duration",
                        icon: "clock.fill",
                        color: .modusTealAccent
                    )
                }

                StatCardMini(
                    value: "\(exerciseCount)",
                    unit: exerciseCount == 1 ? "exercise" : "exercises",
                    label: "Completed",
                    icon: "figure.strengthtraining.traditional",
                    color: .modusPrimary
                )

                if prCount > 0 {
                    StatCardMini(
                        value: "\(prCount)",
                        unit: prCount == 1 ? "PR" : "PRs",
                        label: "New Records",
                        icon: "trophy.fill",
                        color: .yellow
                    )
                }
            }

            if streak > 0 {
                Divider()

                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Text("\(streak) Day Streak")
                        .font(.headline)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(Spacing.xl)
        .frame(width: 400, height: 500)
        .background(
            LinearGradient(
                colors: [
                    Color.modusLightTeal,
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
}

private struct StatCardMini: View {
    let value: String
    let unit: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 2)
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.8))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Supporting Models

struct ExerciseSummary: Identifiable {
    let id: UUID
    let name: String
    let sets: Int
    let reps: [Int]
    let weight: Double?
    let volume: Double
    let isPersonalRecord: Bool
    let prDetails: String?
    let muscleGroup: String?

    init(
        id: UUID = UUID(),
        name: String,
        sets: Int,
        reps: [Int],
        weight: Double? = nil,
        volume: Double,
        isPersonalRecord: Bool = false,
        prDetails: String? = nil,
        muscleGroup: String? = nil
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.volume = volume
        self.isPersonalRecord = isPersonalRecord
        self.prDetails = prDetails
        self.muscleGroup = muscleGroup
    }
}

struct MuscleGroupVolume: Identifiable {
    let id = UUID()
    let muscleGroup: String
    let volume: Double

    var displayName: String {
        muscleGroup.capitalized
    }

    var color: Color {
        switch muscleGroup.lowercased() {
        case "push", "chest", "shoulders":
            return .modusCyan
        case "pull", "back":
            return .modusTealAccent
        case "legs", "squat", "lower":
            return .modusPrimary
        case "core", "abs":
            return Color.purple
        default:
            return .modusDeepTeal
        }
    }
}

enum WorkoutMood: String, CaseIterable, Identifiable {
    case great, good, ok, tough, bad

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .great: return "💪"
        case .good: return "😊"
        case .ok: return "😐"
        case .tough: return "😓"
        case .bad: return "😫"
        }
    }

    var label: String {
        rawValue.capitalized
    }
}

// MARK: - Preview

#if DEBUG
struct EnhancedWorkoutSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedWorkoutSummaryView(
            workoutName: "Push Day",
            completedAt: Date(),
            duration: 45,
            totalVolume: 12500,
            previousVolume: 11200,
            exercisesCompleted: [
                ExerciseSummary(
                    name: "Bench Press",
                    sets: 4,
                    reps: [8, 8, 8, 7],
                    weight: 185,
                    volume: 5920,
                    isPersonalRecord: true,
                    prDetails: "New max: 185 lbs x 8 reps",
                    muscleGroup: "push"
                ),
                ExerciseSummary(
                    name: "Overhead Press",
                    sets: 3,
                    reps: [10, 10, 9],
                    weight: 95,
                    volume: 2755,
                    muscleGroup: "push"
                ),
                ExerciseSummary(
                    name: "Incline Dumbbell Press",
                    sets: 3,
                    reps: [12, 12, 11],
                    weight: 60,
                    volume: 2100,
                    muscleGroup: "push"
                )
            ],
            muscleGroupBreakdown: [
                MuscleGroupVolume(muscleGroup: "push", volume: 8500),
                MuscleGroupVolume(muscleGroup: "shoulders", volume: 2800),
                MuscleGroupVolume(muscleGroup: "core", volume: 1200)
            ],
            currentStreak: 7,
            onDismiss: {},
            onShare: { _ in }
        )
    }
}
#endif
