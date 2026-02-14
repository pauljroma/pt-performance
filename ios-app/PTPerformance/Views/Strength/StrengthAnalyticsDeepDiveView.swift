//
//  StrengthAnalyticsDeepDiveView.swift
//  PTPerformance
//
//  ACP-1027: Strength Analytics Deep Dive
//  Main hub view for enhanced strength analytics features including
//  estimated 1RM trends, volume per muscle group, lift-specific progress,
//  stalled lift detection, and PR prediction.
//

import SwiftUI
import Charts

// MARK: - Strength Analytics Deep Dive View

/// Main hub view for strength analytics deep dive
/// Provides navigation to sub-views for 1RM trends, muscle group volume,
/// lift-specific detail pages, stalled lifts, and PR predictions
struct StrengthAnalyticsDeepDiveView: View {

    // MARK: - Properties

    let patientId: String

    // MARK: - State

    @StateObject private var viewModel: StrengthDeepDiveViewModel
    @State private var selectedTab: AnalyticsTab = .oneRMTrends

    // MARK: - Initialization

    init(patientId: String) {
        self.patientId = patientId
        self._viewModel = StateObject(wrappedValue: StrengthDeepDiveViewModel(patientId: patientId))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Tab selector
                    analyticsTabPicker

                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.errorMessage {
                        errorView(message: error)
                    } else {
                        // Content based on selected tab
                        switch selectedTab {
                        case .oneRMTrends:
                            EstimatedOneRMTrendChart(
                                exercises: viewModel.exerciseProgressData,
                                selectedExercise: $viewModel.selectedExerciseName
                            )

                        case .muscleGroupVolume:
                            MuscleGroupVolumeView(
                                volumeByGroup: viewModel.muscleGroupVolume,
                                weeklyBreakdown: viewModel.weeklyMuscleGroupVolume
                            )

                        case .stalledLifts:
                            StalledLiftsDetectorView(
                                stalledLifts: viewModel.stalledLifts,
                                allExercises: viewModel.exerciseProgressData,
                                onSelectLift: { name in
                                    viewModel.selectedExerciseName = name
                                    selectedTab = .oneRMTrends
                                }
                            )

                        case .prPrediction:
                            PRPredictionView(
                                predictions: viewModel.prPredictions,
                                exerciseData: viewModel.exerciseProgressData
                            )
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Strength Analytics")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.loadAllData()
            }
            .task {
                await viewModel.loadAllData()
            }
        }
    }

    // MARK: - Tab Picker

    private var analyticsTabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(AnalyticsTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                        HapticFeedback.selectionChanged()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.caption)
                            Text(tab.title)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selectedTab == tab
                                ? Color.modusCyan
                                : Color(.secondarySystemGroupedBackground)
                        )
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                        .cornerRadius(CornerRadius.xl)
                    }
                    .accessibilityLabel(tab.title)
                    .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Analyzing strength data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Unable to load analytics")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                HapticFeedback.light()
                Task { await viewModel.loadAllData() }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Spacing.xl)
        }
        .padding()
    }
}

// MARK: - Analytics Tab

enum AnalyticsTab: String, CaseIterable, Identifiable {
    case oneRMTrends
    case muscleGroupVolume
    case stalledLifts
    case prPrediction

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneRMTrends: return "1RM Trends"
        case .muscleGroupVolume: return "Muscle Groups"
        case .stalledLifts: return "Stalled Lifts"
        case .prPrediction: return "PR Prediction"
        }
    }

    var icon: String {
        switch self {
        case .oneRMTrends: return "chart.line.uptrend.xyaxis"
        case .muscleGroupVolume: return "chart.pie.fill"
        case .stalledLifts: return "exclamationmark.triangle.fill"
        case .prPrediction: return "sparkles"
        }
    }
}

// MARK: - Deep Dive Data Models

/// Exercise progress data point with estimated 1RM
struct OneRMDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
    let reps: Int
    let estimated1RM: Double
    let volume: Double
}

/// Exercise progress data for a specific exercise
struct ExerciseOneRMProgress: Identifiable {
    let id: String
    let exerciseName: String
    let dataPoints: [OneRMDataPoint]
    let current1RM: Double
    let peak1RM: Double
    let muscleGroup: MuscleGroup
    let lastPerformedDate: Date?
    let weeklyProgressRate: Double // lbs per week

    /// Whether the lift has stalled (no increase in 3+ weeks)
    var isStalled: Bool {
        guard dataPoints.count >= 2 else { return false }
        let threeWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -3, to: Date()) ?? Date()
        let recentPoints = dataPoints.filter { $0.date >= threeWeeksAgo }
        guard let recentMax = recentPoints.map({ $0.estimated1RM }).max(),
              let olderMax = dataPoints.filter({ $0.date < threeWeeksAgo }).map({ $0.estimated1RM }).max() else {
            return false
        }
        // Stalled if recent max is within 2% of older max
        return abs(recentMax - olderMax) / max(olderMax, 1) < 0.02
    }

    /// Weeks since last improvement (1RM increase)
    var weeksSinceLastImprovement: Int {
        guard dataPoints.count >= 2 else { return 0 }
        let sorted = dataPoints.sorted { $0.date > $1.date }
        var runningMax = sorted.first?.estimated1RM ?? 0

        for point in sorted.dropFirst() {
            if point.estimated1RM >= runningMax {
                // This is when the last improvement happened
                let days = Calendar.current.dateComponents([.day], from: point.date, to: Date()).day ?? 0
                return max(0, days / 7)
            }
            runningMax = max(runningMax, point.estimated1RM)
        }
        return 0
    }
}

/// Muscle group categories
enum MuscleGroup: String, CaseIterable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case legs = "Legs"
    case arms = "Arms"
    case core = "Core"
    case fullBody = "Full Body"
    case other = "Other"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .chest: return .modusCyan
        case .back: return .modusDeepTeal
        case .shoulders: return .modusTealAccent
        case .legs: return .orange
        case .arms: return .purple
        case .core: return .yellow
        case .fullBody: return .modusLightTeal
        case .other: return .gray
        }
    }

    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rowing"
        case .shoulders: return "figure.arms.open"
        case .legs: return "figure.strengthtraining.functional"
        case .arms: return "figure.boxing"
        case .core: return "figure.core.training"
        case .fullBody: return "figure.cross.training"
        case .other: return "dumbbell.fill"
        }
    }

    /// Map exercise names to muscle groups
    static func from(exerciseName: String) -> MuscleGroup {
        let name = exerciseName.lowercased()

        // Chest
        if name.contains("bench press") || name.contains("chest") || name.contains("fly") ||
           name.contains("pec") || name.contains("push up") || name.contains("pushup") ||
           name.contains("incline press") || name.contains("decline press") || name.contains("dip") {
            return .chest
        }

        // Back
        if name.contains("row") || name.contains("pull up") || name.contains("pullup") ||
           name.contains("lat") || name.contains("back") || name.contains("chin up") ||
           name.contains("deadlift") || name.contains("shrug") {
            return .back
        }

        // Shoulders
        if name.contains("shoulder") || name.contains("overhead press") || name.contains("military press") ||
           name.contains("lateral raise") || name.contains("face pull") || name.contains("upright row") ||
           name.contains("ohp") || name.contains("arnold") {
            return .shoulders
        }

        // Legs
        if name.contains("squat") || name.contains("leg") || name.contains("lunge") ||
           name.contains("calf") || name.contains("hamstring") || name.contains("quad") ||
           name.contains("hip thrust") || name.contains("glute") || name.contains("step up") ||
           name.contains("front squat") || name.contains("back squat") || name.contains("bulgarian") {
            return .legs
        }

        // Arms
        if name.contains("curl") || name.contains("bicep") || name.contains("tricep") ||
           name.contains("extension") || name.contains("skull crusher") || name.contains("hammer") ||
           name.contains("preacher") {
            return .arms
        }

        // Core
        if name.contains("plank") || name.contains("ab") || name.contains("crunch") ||
           name.contains("sit up") || name.contains("core") || name.contains("oblique") ||
           name.contains("pallof") {
            return .core
        }

        // Full Body
        if name.contains("clean") || name.contains("snatch") || name.contains("thruster") ||
           name.contains("burpee") || name.contains("turkish") {
            return .fullBody
        }

        return .other
    }
}

/// Volume data for a specific muscle group
struct MuscleGroupVolumeData: Identifiable {
    let id = UUID()
    let muscleGroup: MuscleGroup
    let totalVolume: Double
    let percentage: Double
    let exerciseCount: Int
    let sessionCount: Int
}

/// Weekly volume breakdown per muscle group
struct WeeklyMuscleGroupVolume: Identifiable {
    let id = UUID()
    let weekStart: Date
    let muscleGroup: MuscleGroup
    let volume: Double
}

/// Stalled lift data
struct StalledLiftInfo: Identifiable {
    let id = UUID()
    let exerciseName: String
    let muscleGroup: MuscleGroup
    let current1RM: Double
    let peak1RM: Double
    let weeksSinceProgress: Int
    let suggestion: String
    let recentDataPoints: [OneRMDataPoint]
}

/// PR prediction data
struct PRPrediction: Identifiable {
    let id = UUID()
    let exerciseName: String
    let current1RM: Double
    let nextMilestone: Double
    let estimatedWeeksToMilestone: Int
    let weeklyProgressRate: Double
    let confidence: Double // 0-100
    let recentTrend: PerformanceTrend
}

// MARK: - Deep Dive ViewModel

@MainActor
class StrengthDeepDiveViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var exerciseProgressData: [ExerciseOneRMProgress] = []
    @Published var muscleGroupVolume: [MuscleGroupVolumeData] = []
    @Published var weeklyMuscleGroupVolume: [WeeklyMuscleGroupVolume] = []
    @Published var stalledLifts: [StalledLiftInfo] = []
    @Published var prPredictions: [PRPrediction] = []
    @Published var selectedExerciseName: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let patientId: String
    private let analyticsService = AnalyticsService.shared
    private let strengthService = StrengthAnalyticsService()
    private let supabase = PTSupabaseClient.shared
    private let logger = DebugLogger.shared

    // MARK: - Initialization

    init(patientId: String) {
        self.patientId = patientId
    }

    // MARK: - Data Loading

    func loadAllData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch raw exercise data
            let exerciseData = try await fetchExerciseProgressData()
            exerciseProgressData = exerciseData

            // Derive muscle group volume from exercise data
            muscleGroupVolume = calculateMuscleGroupVolume(from: exerciseData)

            // Calculate weekly breakdown
            weeklyMuscleGroupVolume = calculateWeeklyMuscleGroupVolume(from: exerciseData)

            // Identify stalled lifts
            stalledLifts = identifyStalledLifts(from: exerciseData)

            // Generate PR predictions
            prPredictions = generatePRPredictions(from: exerciseData)

            // Select first exercise if none selected
            if selectedExerciseName == nil {
                selectedExerciseName = exerciseData.first?.exerciseName
            }

            logger.success("STRENGTH_DEEP_DIVE", "Loaded analytics for \(exerciseData.count) exercises")
        } catch {
            logger.error("STRENGTH_DEEP_DIVE", "Failed to load data: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Data Fetching

    private func fetchExerciseProgressData() async throws -> [ExerciseOneRMProgress] {
        // Fetch exercise history from vw_exercise_history view
        struct ExerciseHistoryRow: Codable {
            let patientId: String
            let exerciseName: String
            let exerciseTemplateId: String?
            let sessionCount: Int
            let lastPerformed: Date?
            let avgWeight: Double?
            let maxWeight: Double?
            let totalVolume: Double?
            let improvementRatio: Double?
            let loadUnit: String?

            enum CodingKeys: String, CodingKey {
                case patientId = "patient_id"
                case exerciseName = "exercise_name"
                case exerciseTemplateId = "exercise_template_id"
                case sessionCount = "session_count"
                case lastPerformed = "last_performed"
                case avgWeight = "avg_weight"
                case maxWeight = "max_weight"
                case totalVolume = "total_volume"
                case improvementRatio = "improvement_ratio"
                case loadUnit = "load_unit"
            }
        }

        let response: [ExerciseHistoryRow] = try await supabase.client
            .from("vw_exercise_history")
            .select()
            .eq("patient_id", value: patientId)
            .order("last_performed", ascending: false)
            .limit(50)
            .execute()
            .value

        var allProgress: [ExerciseOneRMProgress] = []

        for record in response {
            // Fetch time-series for each exercise (limited to top exercises for performance)
            guard allProgress.count < 20 else { break }

            do {
                let timeSeries = try await strengthService.fetchExerciseProgressTimeSeries(
                    patientId: patientId,
                    exerciseName: record.exerciseName,
                    limit: 30
                )

                let dataPoints = timeSeries.map { point in
                    let est1RM = RMCalculator.epley(weight: point.weight, reps: point.reps)
                    return OneRMDataPoint(
                        date: point.date,
                        weight: point.weight,
                        reps: point.reps,
                        estimated1RM: est1RM,
                        volume: point.volume
                    )
                }

                guard !dataPoints.isEmpty else { continue }

                let current1RM = dataPoints.last?.estimated1RM ?? 0
                let peak1RM = dataPoints.map { $0.estimated1RM }.max() ?? 0
                let muscleGroup = MuscleGroup.from(exerciseName: record.exerciseName)

                // Calculate weekly progress rate
                let weeklyRate = calculateWeeklyProgressRate(from: dataPoints)

                let progress = ExerciseOneRMProgress(
                    id: record.exerciseName,
                    exerciseName: record.exerciseName,
                    dataPoints: dataPoints,
                    current1RM: current1RM,
                    peak1RM: peak1RM,
                    muscleGroup: muscleGroup,
                    lastPerformedDate: record.lastPerformed,
                    weeklyProgressRate: weeklyRate
                )
                allProgress.append(progress)
            } catch {
                // Continue even if individual exercise fails
                logger.warning("STRENGTH_DEEP_DIVE", "Failed to fetch time-series for \(record.exerciseName): \(error.localizedDescription)")
            }
        }

        return allProgress
    }

    // MARK: - Calculations

    private func calculateWeeklyProgressRate(from dataPoints: [OneRMDataPoint]) -> Double {
        guard dataPoints.count >= 2 else { return 0 }
        let sorted = dataPoints.sorted { $0.date < $1.date }
        let first = sorted.first!
        let last = sorted.last!

        let weeks = max(1, Calendar.current.dateComponents([.weekOfYear], from: first.date, to: last.date).weekOfYear ?? 1)
        return (last.estimated1RM - first.estimated1RM) / Double(weeks)
    }

    private func calculateMuscleGroupVolume(from exercises: [ExerciseOneRMProgress]) -> [MuscleGroupVolumeData] {
        var volumeByGroup: [MuscleGroup: (volume: Double, exercises: Set<String>, sessions: Int)] = [:]

        for exercise in exercises {
            let group = exercise.muscleGroup
            let totalVol = exercise.dataPoints.reduce(0) { $0 + $1.volume }
            let existing = volumeByGroup[group] ?? (volume: 0, exercises: Set<String>(), sessions: 0)
            var exerciseSet = existing.exercises
            exerciseSet.insert(exercise.exerciseName)
            volumeByGroup[group] = (
                volume: existing.volume + totalVol,
                exercises: exerciseSet,
                sessions: existing.sessions + exercise.dataPoints.count
            )
        }

        let totalVolume = volumeByGroup.values.reduce(0) { $0 + $1.volume }

        return volumeByGroup.map { group, data in
            MuscleGroupVolumeData(
                muscleGroup: group,
                totalVolume: data.volume,
                percentage: totalVolume > 0 ? (data.volume / totalVolume) * 100 : 0,
                exerciseCount: data.exercises.count,
                sessionCount: data.sessions
            )
        }
        .sorted { $0.totalVolume > $1.totalVolume }
    }

    private func calculateWeeklyMuscleGroupVolume(from exercises: [ExerciseOneRMProgress]) -> [WeeklyMuscleGroupVolume] {
        let calendar = Calendar.current
        var weeklyData: [Date: [MuscleGroup: Double]] = [:]

        for exercise in exercises {
            let group = exercise.muscleGroup
            for point in exercise.dataPoints {
                let weekStart = calendar.dateInterval(of: .weekOfYear, for: point.date)?.start ?? point.date
                weeklyData[weekStart, default: [:]][group, default: 0] += point.volume
            }
        }

        return weeklyData.flatMap { weekStart, groupVolumes in
            groupVolumes.map { group, volume in
                WeeklyMuscleGroupVolume(
                    weekStart: weekStart,
                    muscleGroup: group,
                    volume: volume
                )
            }
        }
        .sorted { $0.weekStart < $1.weekStart }
    }

    private func identifyStalledLifts(from exercises: [ExerciseOneRMProgress]) -> [StalledLiftInfo] {
        exercises.compactMap { exercise -> StalledLiftInfo? in
            guard exercise.dataPoints.count >= 3 else { return nil }

            let threeWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -3, to: Date()) ?? Date()
            let recentPoints = exercise.dataPoints.filter { $0.date >= threeWeeksAgo }
            let olderPoints = exercise.dataPoints.filter { $0.date < threeWeeksAgo }

            guard !recentPoints.isEmpty, !olderPoints.isEmpty else { return nil }

            let recentMax = recentPoints.map { $0.estimated1RM }.max() ?? 0
            let olderMax = olderPoints.map { $0.estimated1RM }.max() ?? 0

            // Stalled if recent max hasn't exceeded older max by more than 2%
            let changePercent = olderMax > 0 ? (recentMax - olderMax) / olderMax : 0
            guard changePercent < 0.02 else { return nil }

            let weeksSinceProgress = exercise.weeksSinceLastImprovement
            guard weeksSinceProgress >= 3 else { return nil }

            let suggestion = generateStalledLiftSuggestion(
                exerciseName: exercise.exerciseName,
                current1RM: exercise.current1RM,
                weeksSinceProgress: weeksSinceProgress,
                muscleGroup: exercise.muscleGroup
            )

            return StalledLiftInfo(
                exerciseName: exercise.exerciseName,
                muscleGroup: exercise.muscleGroup,
                current1RM: exercise.current1RM,
                peak1RM: exercise.peak1RM,
                weeksSinceProgress: weeksSinceProgress,
                suggestion: suggestion,
                recentDataPoints: Array(recentPoints.suffix(6))
            )
        }
        .sorted { $0.weeksSinceProgress > $1.weeksSinceProgress }
    }

    private func generateStalledLiftSuggestion(
        exerciseName: String,
        current1RM: Double,
        weeksSinceProgress: Int,
        muscleGroup: MuscleGroup
    ) -> String {
        if weeksSinceProgress >= 6 {
            return "Consider a deload week followed by a variation change. Try paused reps or tempo work for \(exerciseName)."
        } else if weeksSinceProgress >= 4 {
            return "Try adjusting rep ranges (e.g., switch to 3x3 or 5x5). Increase training frequency for \(muscleGroup.rawValue.lowercased()) if recovery allows."
        } else {
            return "Minor plateau detected. Try adding an extra set or microloading (+2.5 lbs) on your next session."
        }
    }

    private func generatePRPredictions(from exercises: [ExerciseOneRMProgress]) -> [PRPrediction] {
        exercises.compactMap { exercise -> PRPrediction? in
            guard exercise.dataPoints.count >= 3 else { return nil }
            guard exercise.weeklyProgressRate > 0 else { return nil }

            let current = exercise.current1RM
            let milestones: [Double] = [
                135, 185, 225, 275, 315, 365, 405, 455, 500, 545, 585, 635
            ]

            // Find next milestone above current 1RM
            guard let nextMilestone = milestones.first(where: { $0 > current }) else { return nil }

            let difference = nextMilestone - current
            let weeksNeeded = Int(ceil(difference / max(exercise.weeklyProgressRate, 0.1)))

            // Calculate confidence based on data consistency
            let confidence = calculatePredictionConfidence(exercise: exercise)

            // Determine trend
            let trend: PerformanceTrend
            if exercise.weeklyProgressRate > 1 {
                trend = .improving
            } else if exercise.weeklyProgressRate > 0 {
                trend = .plateaued
            } else {
                trend = .declining
            }

            return PRPrediction(
                exerciseName: exercise.exerciseName,
                current1RM: current,
                nextMilestone: nextMilestone,
                estimatedWeeksToMilestone: weeksNeeded,
                weeklyProgressRate: exercise.weeklyProgressRate,
                confidence: confidence,
                recentTrend: trend
            )
        }
        .sorted { $0.estimatedWeeksToMilestone < $1.estimatedWeeksToMilestone }
    }

    private func calculatePredictionConfidence(exercise: ExerciseOneRMProgress) -> Double {
        var confidence: Double = 50

        // More data points = higher confidence
        let dataPointCount = exercise.dataPoints.count
        if dataPointCount >= 10 { confidence += 20 }
        else if dataPointCount >= 5 { confidence += 10 }

        // Consistent progress = higher confidence
        if exercise.weeklyProgressRate > 0 && !exercise.isStalled {
            confidence += 15
        }

        // Recent activity = higher confidence
        if let lastDate = exercise.lastPerformedDate {
            let daysSinceLast = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            if daysSinceLast <= 7 { confidence += 10 }
            else if daysSinceLast <= 14 { confidence += 5 }
        }

        // Cap at 95
        return min(95, max(10, confidence))
    }
}

// MARK: - Preview

#if DEBUG
struct StrengthAnalyticsDeepDiveView_Previews: PreviewProvider {
    static var previews: some View {
        StrengthAnalyticsDeepDiveView(patientId: "preview-patient")
    }
}
#endif
