//
//  ExerciseProgressView.swift
//  PTPerformance
//
//  Exercise-specific progress tracking with expandable detail views
//  Shows progress charts, personal records, and recent history for each exercise
//

import SwiftUI
import Charts

// MARK: - Exercise Progress View

/// Main view for tracking progress on individual exercises
/// Shows a searchable, sortable list of exercises with expandable detail views
struct ExerciseProgressView: View {
    let patientId: String

    @StateObject private var viewModel = ExerciseProgressViewModel()
    @State private var searchText = ""
    @State private var sortOption: ExerciseSortOption = .mostRecent
    @State private var expandedExerciseId: String?

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    ExerciseProgressLoadingView()
                } else if let error = viewModel.errorMessage {
                    ErrorStateView.genericError(message: error, retry: {
                        Task {
                            await viewModel.fetchExerciseProgress(for: patientId)
                        }
                    })
                } else if filteredExercises.isEmpty {
                    emptyState
                } else {
                    exerciseList
                }
            }
            .navigationTitle("Exercise Progress")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search exercises..."
            )
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    sortMenu
                }
            }
            .refreshable {
                await viewModel.fetchExerciseProgress(for: patientId)
            }
            .task {
                await viewModel.fetchExerciseProgress(for: patientId)
            }
        }
    }

    // MARK: - Filtered & Sorted Exercises

    private var filteredExercises: [ExerciseProgressItem] {
        var exercises = viewModel.exercises

        // Apply search filter
        if !searchText.isEmpty {
            exercises = exercises.filter {
                $0.exerciseName.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply sorting
        switch sortOption {
        case .mostRecent:
            exercises.sort { ($0.lastPerformed ?? .distantPast) > ($1.lastPerformed ?? .distantPast) }
        case .mostImproved:
            exercises.sort { $0.improvementPercentage > $1.improvementPercentage }
        case .mostFrequent:
            exercises.sort { $0.sessionCount > $1.sessionCount }
        case .alphabetical:
            exercises.sort { $0.exerciseName < $1.exerciseName }
        }

        return exercises
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            ForEach(ExerciseSortOption.allCases, id: \.self) { option in
                Button {
                    sortOption = option
                } label: {
                    HStack {
                        Text(option.displayName)
                        if sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down.circle")
        }
    }

    // MARK: - Exercise List

    private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                // Summary header
                if !filteredExercises.isEmpty {
                    progressSummaryHeader
                }

                // Exercise rows
                ForEach(filteredExercises) { exercise in
                    ExerciseProgressRow(
                        exercise: exercise,
                        isExpanded: expandedExerciseId == exercise.id,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if expandedExerciseId == exercise.id {
                                    expandedExerciseId = nil
                                } else {
                                    expandedExerciseId = exercise.id
                                }
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Progress Summary Header

    private var progressSummaryHeader: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("Progress Overview")
                    .font(.headline)
                Spacer()
                Text("\(filteredExercises.count) exercises")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: Spacing.md) {
                ProgressStatCard(
                    title: "Total PRs",
                    value: "\(viewModel.totalPersonalRecords)",
                    icon: "trophy.fill",
                    color: .yellow
                )

                ProgressStatCard(
                    title: "Improving",
                    value: "\(viewModel.improvingExercisesCount)",
                    icon: "arrow.up.right",
                    color: .green
                )

                ProgressStatCard(
                    title: "This Week",
                    value: "\(viewModel.exercisesThisWeek)",
                    icon: "calendar",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            if !searchText.isEmpty {
                EmptyStateView(
                    title: "No Exercises Found",
                    message: "No exercises match '\(searchText)'. Try a different search term.",
                    icon: "magnifyingglass",
                    iconColor: .secondary,
                    action: EmptyStateView.EmptyStateAction(
                        title: "Clear Search",
                        icon: "xmark.circle",
                        action: { searchText = "" }
                    )
                )
            } else {
                EmptyStateView(
                    title: "No Exercise History",
                    message: "Complete workouts to start tracking your exercise progress. Your sets, reps, and weights will be recorded here.",
                    icon: "dumbbell.fill",
                    iconColor: .blue
                )
            }
        }
    }
}

// MARK: - Sort Options

enum ExerciseSortOption: String, CaseIterable {
    case mostRecent
    case mostImproved
    case mostFrequent
    case alphabetical

    var displayName: String {
        switch self {
        case .mostRecent: return "Most Recent"
        case .mostImproved: return "Most Improved"
        case .mostFrequent: return "Most Frequent"
        case .alphabetical: return "A-Z"
        }
    }
}

// MARK: - Progress Stat Card

private struct ProgressStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .bold()

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Exercise Progress Row

struct ExerciseProgressRow: View {
    let exercise: ExerciseProgressItem
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Main row (always visible)
            Button(action: onTap) {
                HStack(spacing: Spacing.md) {
                    // Exercise icon
                    Circle()
                        .fill(trendColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: exercise.trend.icon)
                                .foregroundColor(trendColor)
                        )

                    // Exercise info
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        HStack {
                            Text(exercise.exerciseName)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            if exercise.hasPersonalRecord {
                                Image(systemName: "trophy.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                        }

                        HStack(spacing: Spacing.sm) {
                            if let lastDate = exercise.lastPerformed {
                                Text(lastDate, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text("\(exercise.sessionCount) sessions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Improvement badge
                    if exercise.improvementPercentage != 0 {
                        Text(exercise.formattedImprovement)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(trendColor.opacity(0.2))
                            .foregroundColor(trendColor)
                            .cornerRadius(8)
                    }

                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded detail view
            if isExpanded {
                ExerciseProgressDetailView(exercise: exercise)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var trendColor: Color {
        switch exercise.trend {
        case .increasing: return .green
        case .decreasing: return .red
        case .stable: return .gray
        }
    }
}

// MARK: - Exercise Progress Detail View

struct ExerciseProgressDetailView: View {
    let exercise: ExerciseProgressItem

    var body: some View {
        VStack(spacing: Spacing.md) {
            Divider()

            // Progress Chart
            if !exercise.dataPoints.isEmpty {
                progressChart
            }

            // Personal Record Badge
            if let pr = exercise.personalRecord {
                personalRecordBadge(pr)
            }

            // Recent History
            if !exercise.recentHistory.isEmpty {
                recentHistorySection
            }

            // Summary stats
            summaryStats
        }
        .padding([.horizontal, .bottom])
    }

    // MARK: - Progress Chart

    private var progressChart: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Progress Over Time")
                .font(.subheadline)
                .fontWeight(.medium)

            Chart {
                ForEach(exercise.dataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(30)
                }
            }
            .chartYAxisLabel("Weight (lbs)")
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .frame(height: 180)
            .padding(.vertical, Spacing.xs)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }

    // MARK: - Personal Record Badge

    private func personalRecordBadge(_ pr: PersonalRecord) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundColor(.yellow)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Personal Record")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(pr.formattedValue)
                    .font(.title3)
                    .bold()

                Text("Achieved \(pr.achievedDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let improvement = pr.formattedImprovement {
                VStack {
                    Text(improvement)
                        .font(.headline)
                        .foregroundColor(.green)
                    Text("vs previous")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.yellow.opacity(0.1), .orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(8)
    }

    // MARK: - Recent History Section

    private var recentHistorySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Recent Sessions")
                .font(.subheadline)
                .fontWeight(.medium)

            ForEach(exercise.recentHistory.prefix(5)) { session in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.date, style: .date)
                            .font(.caption)
                            .fontWeight(.medium)

                        Text("\(session.sets) sets x \(session.reps) reps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if let weight = session.weight {
                        Text(String(format: "%.1f lbs", weight))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    if session.isPersonalRecord {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
                .padding(.vertical, Spacing.xxs)

                if session.id != exercise.recentHistory.prefix(5).last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }

    // MARK: - Summary Stats

    private var summaryStats: some View {
        HStack(spacing: Spacing.md) {
            StatItem(
                label: "Avg Weight",
                value: String(format: "%.1f lbs", exercise.averageWeight)
            )

            Divider()
                .frame(height: 30)

            StatItem(
                label: "Total Volume",
                value: formatVolume(exercise.totalVolume)
            )

            Divider()
                .frame(height: 30)

            StatItem(
                label: "Sessions",
                value: "\(exercise.sessionCount)"
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fK", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Exercise Progress Item Model

struct ExerciseProgressItem: Identifiable {
    let id: String
    let exerciseId: String
    let exerciseName: String
    let dataPoints: [ExerciseDataPoint]
    let trend: ExerciseTrend.TrendDirection
    let averageWeight: Double
    let totalVolume: Double
    let sessionCount: Int
    let lastPerformed: Date?
    let improvementPercentage: Double
    let personalRecord: PersonalRecord?
    let recentHistory: [ExerciseSessionRecord]

    var hasPersonalRecord: Bool {
        personalRecord != nil
    }

    var formattedImprovement: String {
        let sign = improvementPercentage >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, improvementPercentage * 100)
    }
}

// MARK: - Exercise Session Record

struct ExerciseSessionRecord: Identifiable {
    let id: String
    let date: Date
    let sets: Int
    let reps: Int
    let weight: Double?
    let volume: Double
    let isPersonalRecord: Bool
}

// MARK: - View Model

@MainActor
class ExerciseProgressViewModel: ObservableObject {
    @Published var exercises: [ExerciseProgressItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let analyticsService = AnalyticsService.shared

    var totalPersonalRecords: Int {
        exercises.filter { $0.hasPersonalRecord }.count
    }

    var improvingExercisesCount: Int {
        exercises.filter { $0.trend == .increasing }.count
    }

    var exercisesThisWeek: Int {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return exercises.filter { ($0.lastPerformed ?? .distantPast) > oneWeekAgo }.count
    }

    func fetchExerciseProgress(for patientId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch exercise trends from analytics service
            let volumeData = try await analyticsService.calculateVolumeData(
                for: patientId,
                period: .threeMonths
            )

            // Group data by exercise and create progress items
            // Note: In a full implementation, this would use a dedicated endpoint
            // that returns exercise-specific data grouped by exercise name
            let exerciseItems = await buildExerciseProgressItems(patientId: patientId)

            exercises = exerciseItems
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func buildExerciseProgressItems(patientId: String) async -> [ExerciseProgressItem] {
        // This would typically call a backend endpoint that returns
        // exercise progress data grouped by exercise.
        // For now, we return sample data structure that matches the expected format.

        // In production, this would be:
        // let response = try await analyticsService.fetchExerciseProgressData(patientId: patientId)
        // return response.map { ... }

        return []
    }
}

// MARK: - Loading View

struct ExerciseProgressLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                // Summary header skeleton
                skeletonSummaryHeader

                // Exercise row skeletons
                ForEach(0..<5, id: \.self) { _ in
                    skeletonExerciseRow
                }
            }
            .padding()
        }
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }

    private var skeletonSummaryHeader: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 140, height: 18)
                    .shimmer(isAnimating: isAnimating)
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 14)
                    .shimmer(isAnimating: isAnimating)
            }

            HStack(spacing: Spacing.md) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 32, height: 32)
                            .shimmer(isAnimating: isAnimating)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 20)
                            .shimmer(isAnimating: isAnimating)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 12)
                            .shimmer(isAnimating: isAnimating)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var skeletonExerciseRow: some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 44, height: 44)
                .shimmer(isAnimating: isAnimating)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 16)
                    .shimmer(isAnimating: isAnimating)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 12)
                    .shimmer(isAnimating: isAnimating)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 24)
                .shimmer(isAnimating: isAnimating)

            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 16, height: 16)
                .shimmer(isAnimating: isAnimating)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}


// MARK: - Preview

#if DEBUG
struct ExerciseProgressView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ExerciseProgressView(patientId: "preview-patient-1")
                .previewDisplayName("Exercise Progress")

            ExerciseProgressLoadingView()
                .previewDisplayName("Loading State")

            // Preview with sample data
            NavigationStack {
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        ExerciseProgressRow(
                            exercise: sampleExerciseItem,
                            isExpanded: false,
                            onTap: {}
                        )

                        ExerciseProgressRow(
                            exercise: sampleExerciseItem,
                            isExpanded: true,
                            onTap: {}
                        )
                    }
                    .padding()
                }
                .navigationTitle("Preview")
            }
            .previewDisplayName("Expanded Row")
        }
    }

    static var sampleExerciseItem: ExerciseProgressItem {
        ExerciseProgressItem(
            id: "1",
            exerciseId: "ex-1",
            exerciseName: "Barbell Squat",
            dataPoints: sampleDataPoints,
            trend: .increasing,
            averageWeight: 185.0,
            totalVolume: 24500,
            sessionCount: 12,
            lastPerformed: Date(),
            improvementPercentage: 0.15,
            personalRecord: PersonalRecord.sample,
            recentHistory: sampleRecentHistory
        )
    }

    static var sampleDataPoints: [ExerciseDataPoint] {
        let calendar = Calendar.current
        var points: [ExerciseDataPoint] = []
        for i in 0..<8 {
            let weight = 175.0 + Double(i) * 2.5
            let date = calendar.date(byAdding: .day, value: -i * 7, to: Date()) ?? Date()
            points.append(ExerciseDataPoint(
                date: date,
                weight: weight,
                reps: 5,
                sets: 3,
                volume: weight * 5.0 * 3.0
            ))
        }
        return points
    }

    static var sampleRecentHistory: [ExerciseSessionRecord] {
        let calendar = Calendar.current
        var records: [ExerciseSessionRecord] = []
        for i in 0..<5 {
            let weight = 195.0 - Double(i) * 5.0
            let date = calendar.date(byAdding: .day, value: -i * 3, to: Date()) ?? Date()
            records.append(ExerciseSessionRecord(
                id: "\(i)",
                date: date,
                sets: 3,
                reps: 5,
                weight: weight,
                volume: weight * 5.0 * 3.0,
                isPersonalRecord: i == 0
            ))
        }
        return records
    }
}
#endif
