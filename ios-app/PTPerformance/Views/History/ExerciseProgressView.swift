//
//  ExerciseProgressView.swift
//  PTPerformance
//
//  Exercise-specific progress tracking with expandable detail views
//  Shows progress charts, personal records, and recent history for each exercise
//
//  BUILD 340: Added Big Lifts Scorecard integration for prominent PR display
//

import SwiftUI
import Charts

// MARK: - Exercise Progress View

/// Main view for tracking progress on individual exercises
/// Shows a searchable, sortable list of exercises with expandable detail views
/// BUILD 340: Now features Big Lifts Scorecard at the top for achievement-focused display
struct ExerciseProgressView: View {
    let patientId: String

    @StateObject private var viewModel = ExerciseProgressViewModel()
    @State private var searchText = ""
    @State private var sortOption: ExerciseSortOption = .mostRecent
    @State private var expandedExerciseId: String?
    @State private var selectedBigLiftExercise: String?
    @AppStorage("preferredWeightUnit") private var preferredWeightUnit: String = "lbs"

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
            .sheet(item: $selectedBigLiftExercise) { exerciseName in
                ExerciseHistorySheet(exerciseName: exerciseName, patientId: patientId)
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

    // MARK: - Big Lifts Data

    /// Filters exercises to show only the "big lifts" - major compound movements
    private var bigLiftsExercises: [ExerciseProgressItem] {
        let bigLiftPatterns = [
            "bench press", "squat", "deadlift", "overhead press", "barbell row",
            "back squat", "front squat", "incline press", "military press"
        ]

        return viewModel.exercises.filter { exercise in
            let name = exercise.exerciseName.lowercased()
            return bigLiftPatterns.contains { pattern in
                name.contains(pattern)
            }
        }
    }

    // MARK: - Exercise List

    private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                // BUILD 340: Big Lifts Scorecard at the top
                if !bigLiftsExercises.isEmpty && searchText.isEmpty {
                    bigLiftsSection
                }

                // Section divider
                if !bigLiftsExercises.isEmpty && searchText.isEmpty {
                    sectionDivider
                }

                // All Exercise Progress header
                if !filteredExercises.isEmpty {
                    allExerciseProgressHeader
                }

                // Summary stats (Total PRs, etc.)
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
                                    // BUILD 333: Fetch time-series data when expanding
                                    if !viewModel.hasTimeSeriesData(for: exercise.id) {
                                        Task {
                                            await viewModel.fetchExerciseTimeSeriesData(
                                                exerciseId: exercise.id,
                                                exerciseName: exercise.exerciseName
                                            )
                                        }
                                    }
                                }
                            }
                        },
                        fallbackUnit: preferredWeightUnit
                    )
                }

                // Pagination: Load More button or loading indicator
                // Only show when not searching (pagination applies to full list)
                if searchText.isEmpty && viewModel.hasMoreExercises {
                    if viewModel.isLoadingMore {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Loading more...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        Button(action: {
                            Task {
                                await viewModel.loadMoreExercises()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.circle")
                                Text("Load More Exercises")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Big Lifts Section (BUILD 340)

    private var bigLiftsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section header
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("Big Lifts")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                if bigLiftsExercises.count > 4 {
                    Text("\(bigLiftsExercises.count) lifts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Big Lifts Section, \(bigLiftsExercises.count) compound lifts tracked")

            // Big lifts grid
            InlineBigLiftsGrid(
                exercises: bigLiftsExercises,
                preferredUnit: preferredWeightUnit,
                onExerciseTap: { exerciseName in
                    HapticFeedback.light()
                    selectedBigLiftExercise = exerciseName
                }
            )
        }
    }

    // MARK: - Section Divider

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color(.systemGray4))
            .frame(height: 1)
            .padding(.vertical, Spacing.sm)
    }

    // MARK: - All Exercise Progress Header

    private var allExerciseProgressHeader: some View {
        HStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title3)
                .foregroundColor(.blue)
            Text("All Exercise Progress")
                .font(.title3)
                .fontWeight(.semibold)
            Spacer()
        }
        .padding(.top, Spacing.xs)
        .accessibilityAddTraits(.isHeader)
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
    var fallbackUnit: String = "lbs"

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
                ExerciseProgressDetailView(exercise: exercise, fallbackUnit: fallbackUnit)
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
    var fallbackUnit: String = "lbs"

    /// Returns the appropriate unit to display - prefers data unit, falls back to user preference
    private var displayUnit: String {
        exercise.loadUnit ?? fallbackUnit
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            Divider()

            // Progress Chart - show loading state if no data points yet
            if !exercise.dataPoints.isEmpty {
                progressChart
            } else {
                // BUILD 333: Loading state while fetching time-series data
                chartLoadingPlaceholder
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

    // MARK: - Chart Loading Placeholder

    private var chartLoadingPlaceholder: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Progress Over Time")
                .font(.subheadline)
                .fontWeight(.medium)

            HStack {
                Spacer()
                VStack(spacing: Spacing.sm) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Loading chart data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .frame(height: 180)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
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
            .chartYAxisLabel("Weight (\(displayUnit))")
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
                        Text(String(format: "%.1f %@", weight, session.loadUnit ?? displayUnit))
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
                value: String(format: "%.1f %@", exercise.averageWeight, displayUnit)
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
    let loadUnit: String?

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
    let loadUnit: String?
}

// MARK: - View Model

@MainActor
class ExerciseProgressViewModel: ObservableObject {
    @Published var exercises: [ExerciseProgressItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Pagination State
    @Published var hasMoreExercises = true
    @Published var isLoadingMore = false

    // MARK: - Time-Series Data Cache
    /// Cache for loaded time-series data, keyed by exercise ID
    private var timeSeriesCache: [String: [ExerciseDataPoint]] = [:]
    private var recentHistoryCache: [String: [ExerciseSessionRecord]] = [:]

    private var currentPage = 0
    private let pageSize = 20
    private var cachedPatientId: String?

    private let supabase = PTSupabaseClient.shared
    private let analyticsService = AnalyticsService.shared
    private let logger = DebugLogger.shared

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

        // Reset pagination state
        currentPage = 0
        hasMoreExercises = true
        exercises = []
        cachedPatientId = patientId

        do {
            // BUILD 333: Fetch from vw_exercise_history view with pagination
            let response: [ExerciseHistoryRecord] = try await supabase.client
                .from("vw_exercise_history")
                .select()
                .eq("patient_id", value: patientId)
                .order("last_performed", ascending: false)
                .limit(pageSize)
                .execute()
                .value

            logger.log("ExerciseProgress: Fetched \(response.count) exercises for patient", level: .diagnostic)

            // Convert to display items
            exercises = response.map { record in
                ExerciseProgressItem(
                    id: record.exerciseName,
                    exerciseId: record.exerciseTemplateId ?? record.exerciseName,
                    exerciseName: record.exerciseName,
                    dataPoints: [],  // Would need separate query for time-series data
                    trend: determineTrend(from: record.improvementRatio),
                    averageWeight: record.avgWeight ?? 0,
                    totalVolume: record.totalVolume ?? 0,
                    sessionCount: record.sessionCount,
                    lastPerformed: record.lastPerformed,
                    improvementPercentage: record.improvementRatio ?? 0,
                    personalRecord: record.maxWeight.map { weight in
                        PersonalRecord(
                            exerciseId: record.exerciseTemplateId ?? record.exerciseName,
                            exerciseName: record.exerciseName,
                            recordType: .maxWeight,
                            value: weight,
                            achievedDate: record.lastPerformed ?? Date(),
                            previousRecord: nil
                        )
                    },
                    recentHistory: [],  // Would need separate query
                    loadUnit: record.loadUnit
                )
            }

            // Check if there might be more data
            hasMoreExercises = response.count >= pageSize

            isLoading = false
        } catch {
            logger.log("ExerciseProgress: Error fetching data: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to load exercise history"
            isLoading = false
        }
    }

    /// Load more exercises for pagination
    func loadMoreExercises() async {
        guard hasMoreExercises && !isLoadingMore else { return }
        guard let patientId = cachedPatientId else { return }

        isLoadingMore = true

        do {
            currentPage += 1
            let offset = currentPage * pageSize

            let response: [ExerciseHistoryRecord] = try await supabase.client
                .from("vw_exercise_history")
                .select()
                .eq("patient_id", value: patientId)
                .order("last_performed", ascending: false)
                .range(from: offset, to: offset + pageSize - 1)
                .execute()
                .value

            logger.log("ExerciseProgress: Loaded \(response.count) more exercises", level: .diagnostic)

            // Append new exercises
            let newExercises = response.map { record in
                ExerciseProgressItem(
                    id: record.exerciseName,
                    exerciseId: record.exerciseTemplateId ?? record.exerciseName,
                    exerciseName: record.exerciseName,
                    dataPoints: [],
                    trend: determineTrend(from: record.improvementRatio),
                    averageWeight: record.avgWeight ?? 0,
                    totalVolume: record.totalVolume ?? 0,
                    sessionCount: record.sessionCount,
                    lastPerformed: record.lastPerformed,
                    improvementPercentage: record.improvementRatio ?? 0,
                    personalRecord: record.maxWeight.map { weight in
                        PersonalRecord(
                            exerciseId: record.exerciseTemplateId ?? record.exerciseName,
                            exerciseName: record.exerciseName,
                            recordType: .maxWeight,
                            value: weight,
                            achievedDate: record.lastPerformed ?? Date(),
                            previousRecord: nil
                        )
                    },
                    recentHistory: [],
                    loadUnit: record.loadUnit
                )
            }
            exercises.append(contentsOf: newExercises)

            // Check if we've reached the end
            hasMoreExercises = response.count >= pageSize

            isLoadingMore = false
        } catch {
            logger.log("ExerciseProgress: Error loading more: \(error.localizedDescription)", level: .error)
            isLoadingMore = false
            hasMoreExercises = false
        }
    }

    private func determineTrend(from ratio: Double?) -> ExerciseTrend.TrendDirection {
        guard let ratio = ratio else { return .stable }
        if ratio > 0.05 { return .increasing }
        if ratio < -0.05 { return .decreasing }
        return .stable
    }

    // MARK: - BUILD 333: Time-Series Data Fetching

    /// Fetch time-series data for a specific exercise (called when row is expanded)
    /// - Parameters:
    ///   - exerciseId: The exercise item ID
    ///   - exerciseName: The exercise name to query
    func fetchExerciseTimeSeriesData(exerciseId: String, exerciseName: String) async {
        guard let patientId = cachedPatientId else { return }

        // Check cache first
        if timeSeriesCache[exerciseId] != nil {
            // Data already loaded, update the exercise item
            updateExerciseWithCachedData(exerciseId: exerciseId)
            return
        }

        do {
            // Fetch time-series data points for charting
            let dataPoints = try await analyticsService.fetchExerciseProgressTimeSeries(
                patientId: patientId,
                exerciseName: exerciseName,
                limit: 50
            )

            // Convert to ExerciseDataPoint for chart display
            let chartDataPoints = dataPoints.map { point in
                ExerciseDataPoint(
                    date: point.date,
                    weight: point.weight,
                    reps: point.reps,
                    sets: point.sets,
                    volume: point.volume
                )
            }

            // Fetch recent history
            let recentHistory = try await analyticsService.fetchExerciseRecentHistory(
                patientId: patientId,
                exerciseName: exerciseName,
                limit: 10
            )

            // Cache the data
            timeSeriesCache[exerciseId] = chartDataPoints
            recentHistoryCache[exerciseId] = recentHistory

            // Update the exercise item with the fetched data
            updateExerciseWithCachedData(exerciseId: exerciseId)

            logger.log("ExerciseProgress: Loaded \(chartDataPoints.count) data points for \(exerciseName)", level: .diagnostic)

        } catch {
            logger.log("ExerciseProgress: Failed to fetch time-series data for \(exerciseName): \(error.localizedDescription)", level: .error)
        }
    }

    /// Update an exercise item with cached time-series data
    private func updateExerciseWithCachedData(exerciseId: String) {
        guard let index = exercises.firstIndex(where: { $0.id == exerciseId }) else { return }

        let existingExercise = exercises[index]
        let dataPoints = timeSeriesCache[exerciseId] ?? []
        let recentHistory = recentHistoryCache[exerciseId] ?? []

        // Create updated exercise item with the loaded data
        let updatedExercise = ExerciseProgressItem(
            id: existingExercise.id,
            exerciseId: existingExercise.exerciseId,
            exerciseName: existingExercise.exerciseName,
            dataPoints: dataPoints,
            trend: existingExercise.trend,
            averageWeight: existingExercise.averageWeight,
            totalVolume: existingExercise.totalVolume,
            sessionCount: existingExercise.sessionCount,
            lastPerformed: existingExercise.lastPerformed,
            improvementPercentage: existingExercise.improvementPercentage,
            personalRecord: existingExercise.personalRecord,
            recentHistory: recentHistory,
            loadUnit: existingExercise.loadUnit
        )

        exercises[index] = updatedExercise
    }

    /// Check if time-series data is loaded for an exercise
    func hasTimeSeriesData(for exerciseId: String) -> Bool {
        return timeSeriesCache[exerciseId] != nil
    }
}

// MARK: - Exercise History Database Record

private struct ExerciseHistoryRecord: Codable {
    let patientId: String
    let exerciseName: String
    let exerciseTemplateId: String?
    let sessionCount: Int
    let lastPerformed: Date?
    let firstPerformed: Date?
    let avgWeight: Double?
    let maxWeight: Double?
    let minWeight: Double?
    let totalVolume: Double?
    let improvementRatio: Double?
    let loadUnit: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case exerciseName = "exercise_name"
        case exerciseTemplateId = "exercise_template_id"
        case sessionCount = "session_count"
        case lastPerformed = "last_performed"
        case firstPerformed = "first_performed"
        case avgWeight = "avg_weight"
        case maxWeight = "max_weight"
        case minWeight = "min_weight"
        case totalVolume = "total_volume"
        case improvementRatio = "improvement_ratio"
        case loadUnit = "load_unit"
    }
}

// MARK: - String Identifiable Extension (for sheet binding)

extension String: @retroactive Identifiable {
    public var id: String { self }
}

// MARK: - Inline Big Lifts Grid (BUILD 340)

/// Displays a grid of "big lift" compound exercises with their PRs prominently
/// Uses ExerciseProgressItem data from the parent view
/// Tapping a card navigates to detailed history for that exercise
private struct InlineBigLiftsGrid: View {
    let exercises: [ExerciseProgressItem]
    let preferredUnit: String
    let onExerciseTap: (String) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm)
    ]

    var body: some View {
        if exercises.isEmpty {
            emptyBigLiftsState
        } else {
            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(exercises.prefix(6)) { exercise in
                    InlineBigLiftCard(
                        exercise: exercise,
                        preferredUnit: preferredUnit,
                        onTap: { onExerciseTap(exercise.exerciseName) }
                    )
                }
            }
        }
    }

    private var emptyBigLiftsState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "dumbbell.fill")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No Big Lifts Yet")
                .font(.headline)
            Text("Log bench press, squat, deadlift, or overhead press to see your PRs here")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(Color(.systemGray6))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Inline Big Lift Card

/// Individual card for a big lift exercise showing weight, estimated 1RM, and improvement
private struct InlineBigLiftCard: View {
    let exercise: ExerciseProgressItem
    let preferredUnit: String
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var displayUnit: String {
        exercise.loadUnit ?? preferredUnit
    }

    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Exercise name with trophy if PR
                HStack {
                    Text(shortExerciseName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundColor(.primary)

                    Spacer()

                    if exercise.hasPersonalRecord {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }

                Spacer()

                // Max weight prominently displayed
                if let pr = exercise.personalRecord {
                    Text(formatWeight(pr.value))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .monospacedDigit()

                    // Estimated 1RM (if different from max weight)
                    if let estimated1RM = estimated1RMValue, estimated1RM > pr.value {
                        HStack(spacing: 2) {
                            Text("Est 1RM:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(formatWeight(estimated1RM))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                        }
                    }
                } else {
                    Text(formatWeight(exercise.averageWeight))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .monospacedDigit()

                    Text("Avg Weight")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Improvement badge
                if exercise.improvementPercentage != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: exercise.improvementPercentage > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                        Text(exercise.formattedImprovement)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(exercise.improvementPercentage > 0 ? .green : .red)
                }
            }
            .padding(Spacing.sm)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .background(cardBackgroundColor)
            .cornerRadius(CornerRadius.md)
            .adaptiveShadow(Shadow.subtle)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.exerciseName), \(exercise.personalRecord.map { formatWeight($0.value) } ?? formatWeight(exercise.averageWeight))")
        .accessibilityHint("Double tap to view exercise history")
    }

    /// Shortened exercise name for compact display
    private var shortExerciseName: String {
        let name = exercise.exerciseName
        // Remove common prefixes for compact display
        let shortened = name
            .replacingOccurrences(of: "Barbell ", with: "")
            .replacingOccurrences(of: "Dumbbell ", with: "DB ")
        return shortened
    }

    /// Estimates 1RM using Epley formula if we have rep data
    /// This is a simplified calculation - the full RMCalculator is used in ExerciseHistorySheet
    private var estimated1RMValue: Double? {
        guard let pr = exercise.personalRecord else { return nil }
        // Simple Epley formula estimate: weight * (1 + reps/30)
        // Since we don't have rep count in ExerciseProgressItem, return nil
        // The actual 1RM is calculated in ExerciseHistorySheet with full session data
        return nil
    }

    private func formatWeight(_ weight: Double) -> String {
        if weight == floor(weight) {
            return "\(Int(weight)) \(displayUnit)"
        }
        return String(format: "%.1f %@", weight, displayUnit)
    }
}

// MARK: - Loading View

struct ExerciseProgressLoadingView: View {
    @State private var isAnimating = false

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                // BUILD 340: Big Lifts skeleton
                skeletonBigLiftsSection

                // Section divider
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 1)
                    .padding(.vertical, Spacing.sm)

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

    // BUILD 340: Big Lifts skeleton
    private var skeletonBigLiftsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header skeleton
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 28, height: 28)
                    .shimmer(isAnimating: isAnimating)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 22)
                    .shimmer(isAnimating: isAnimating)

                Spacer()
            }

            // Cards grid skeleton
            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(0..<4, id: \.self) { _ in
                    skeletonBigLiftCard
                }
            }
        }
    }

    private var skeletonBigLiftCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Title row
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 14)
                    .shimmer(isAnimating: isAnimating)
                Spacer()
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 16, height: 16)
                    .shimmer(isAnimating: isAnimating)
            }

            Spacer()

            // Weight
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 28)
                .shimmer(isAnimating: isAnimating)

            // Improvement
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 14)
                .shimmer(isAnimating: isAnimating)
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
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

            // BUILD 340: Big Lifts Scorecard Preview
            NavigationStack {
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        // Big Lifts Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                Text("Big Lifts")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                            }

                            InlineBigLiftsGrid(
                                exercises: sampleBigLifts,
                                preferredUnit: "lbs",
                                onExerciseTap: { _ in }
                            )
                        }

                        // Divider
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 1)
                            .padding(.vertical, Spacing.sm)

                        // Exercise rows
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
            .previewDisplayName("Big Lifts + Rows")
        }
    }

    // Sample big lifts for preview
    static var sampleBigLifts: [ExerciseProgressItem] {
        [
            ExerciseProgressItem(
                id: "bench",
                exerciseId: "ex-bench",
                exerciseName: "Bench Press",
                dataPoints: [],
                trend: .increasing,
                averageWeight: 185.0,
                totalVolume: 18500,
                sessionCount: 15,
                lastPerformed: Date(),
                improvementPercentage: 0.08,
                personalRecord: PersonalRecord(
                    exerciseId: "ex-bench",
                    exerciseName: "Bench Press",
                    recordType: .maxWeight,
                    value: 225.0,
                    achievedDate: Date().addingTimeInterval(-86400 * 3),
                    previousRecord: 215.0
                ),
                recentHistory: [],
                loadUnit: "lbs"
            ),
            ExerciseProgressItem(
                id: "squat",
                exerciseId: "ex-squat",
                exerciseName: "Back Squat",
                dataPoints: [],
                trend: .increasing,
                averageWeight: 275.0,
                totalVolume: 32000,
                sessionCount: 18,
                lastPerformed: Date().addingTimeInterval(-86400),
                improvementPercentage: 0.12,
                personalRecord: PersonalRecord(
                    exerciseId: "ex-squat",
                    exerciseName: "Back Squat",
                    recordType: .maxWeight,
                    value: 315.0,
                    achievedDate: Date().addingTimeInterval(-86400 * 7),
                    previousRecord: 295.0
                ),
                recentHistory: [],
                loadUnit: "lbs"
            ),
            ExerciseProgressItem(
                id: "deadlift",
                exerciseId: "ex-deadlift",
                exerciseName: "Deadlift",
                dataPoints: [],
                trend: .stable,
                averageWeight: 345.0,
                totalVolume: 28000,
                sessionCount: 12,
                lastPerformed: Date().addingTimeInterval(-86400 * 2),
                improvementPercentage: 0.03,
                personalRecord: PersonalRecord(
                    exerciseId: "ex-deadlift",
                    exerciseName: "Deadlift",
                    recordType: .maxWeight,
                    value: 405.0,
                    achievedDate: Date().addingTimeInterval(-86400 * 14),
                    previousRecord: 385.0
                ),
                recentHistory: [],
                loadUnit: "lbs"
            ),
            ExerciseProgressItem(
                id: "ohp",
                exerciseId: "ex-ohp",
                exerciseName: "Overhead Press",
                dataPoints: [],
                trend: .increasing,
                averageWeight: 115.0,
                totalVolume: 9800,
                sessionCount: 10,
                lastPerformed: Date().addingTimeInterval(-86400 * 4),
                improvementPercentage: 0.05,
                personalRecord: PersonalRecord(
                    exerciseId: "ex-ohp",
                    exerciseName: "Overhead Press",
                    recordType: .maxWeight,
                    value: 135.0,
                    achievedDate: Date().addingTimeInterval(-86400 * 10),
                    previousRecord: 125.0
                ),
                recentHistory: [],
                loadUnit: "lbs"
            )
        ]
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
            recentHistory: sampleRecentHistory,
            loadUnit: "lbs"
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
                isPersonalRecord: i == 0,
                loadUnit: "lbs"
            ))
        }
        return records
    }
}
#endif
