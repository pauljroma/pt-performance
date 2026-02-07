//
//  AssessmentProgressViewModel.swift
//  PTPerformance
//
//  ViewModel for tracking patient progress over time including
//  ROM/pain trends, MCID achievement tracking, and outcome comparison.
//

import SwiftUI
import Combine

// MARK: - Chart Data Models

/// Data point for trend charts
struct TrendDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String?

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

/// ROM progress summary for a specific joint/movement
struct ROMProgressItem: Identifiable {
    let id = UUID()
    let joint: String
    let movement: String
    let side: Side
    let initialDegrees: Int
    let currentDegrees: Int
    let normalRange: ClosedRange<Int>
    let measurements: [TrendDataPoint]

    var change: Int {
        currentDegrees - initialDegrees
    }

    var isImproving: Bool {
        change > 0
    }

    var percentageOfNormal: Double {
        guard normalRange.upperBound > 0 else { return 0 }
        return Double(currentDegrees) / Double(normalRange.upperBound) * 100
    }

    var progressStatus: ProgressStatus {
        if isImproving && change >= 10 { return .improving }
        if change < -5 { return .declining }
        return .stable
    }

    var displayTitle: String {
        "\(side.abbreviation) \(joint.capitalized) \(movement.capitalized)"
    }
}

/// Pain progress summary
struct PainProgressItem: Identifiable {
    let id = UUID()
    let painType: String // "rest", "activity", "worst"
    let initialScore: Int
    let currentScore: Int
    let measurements: [TrendDataPoint]

    var change: Int {
        currentScore - initialScore
    }

    var isImproving: Bool {
        change < 0 // Lower pain is better
    }

    var progressStatus: ProgressStatus {
        if change <= -2 { return .improving }
        if change >= 2 { return .declining }
        return .stable
    }

    var displayTitle: String {
        switch painType {
        case "rest": return "Pain at Rest"
        case "activity": return "Pain with Activity"
        case "worst": return "Worst Pain"
        default: return "Pain"
        }
    }
}

/// Outcome measure progress summary
struct OutcomeProgressItem: Identifiable {
    let id = UUID()
    let measureType: OutcomeMeasureType
    let initialScore: Double
    let currentScore: Double
    let mcidThreshold: Double
    let measurements: [TrendDataPoint]

    var change: Double {
        currentScore - initialScore
    }

    var meetsMcid: Bool {
        if measureType.higherIsBetter {
            return change >= mcidThreshold
        } else {
            return change <= -mcidThreshold
        }
    }

    var progressStatus: ProgressStatus {
        if meetsMcid {
            return measureType.higherIsBetter ? (change > 0 ? .improving : .declining) : (change < 0 ? .improving : .declining)
        }
        return .stable
    }

    var changePercentage: Double {
        guard initialScore != 0 else { return 0 }
        return (change / initialScore) * 100
    }
}

// MARK: - Progress Summary

/// Overall progress summary for a patient
struct PatientProgressSummary {
    var overallStatus: ProgressStatus = .stable
    var romImprovements: Int = 0
    var romDeclines: Int = 0
    var painImprovements: Int = 0
    var painDeclines: Int = 0
    var mcidAchievements: Int = 0
    var totalOutcomeMeasures: Int = 0
    var daysInTreatment: Int = 0
    var totalVisits: Int = 0

    var summaryText: String {
        switch overallStatus {
        case .improving:
            return "Patient is showing overall improvement"
        case .stable:
            return "Patient is maintaining stable progress"
        case .declining:
            return "Patient progress requires attention"
        }
    }
}

// MARK: - AssessmentProgressViewModel

/// ViewModel for tracking and displaying patient progress over time
@MainActor
class AssessmentProgressViewModel: ObservableObject {

    // MARK: - Published Properties - Data

    @Published var patientId: UUID?

    // Progress Items
    @Published var romProgress: [ROMProgressItem] = []
    @Published var painProgress: [PainProgressItem] = []
    @Published var outcomeProgress: [OutcomeProgressItem] = []

    // Trend Data
    @Published var painTrend: [TrendDataPoint] = []
    @Published var romTrends: [String: [TrendDataPoint]] = [:]
    @Published var outcomeTrends: [OutcomeMeasureType: [TrendDataPoint]] = [:]

    // Summary
    @Published var progressSummary = PatientProgressSummary()

    // MARK: - Published Properties - UI State

    @Published var isLoading = false
    @Published var errorMessage: String?

    // Section-specific loading
    @Published var isLoadingROM = false
    @Published var isLoadingPain = false
    @Published var isLoadingOutcomes = false

    // Section-specific errors
    @Published var romError: String?
    @Published var painError: String?
    @Published var outcomesError: String?

    // Time Range
    @Published var selectedTimeRange: TimeRange = .threeMonths

    // MARK: - Dependencies

    private let assessmentService: ClinicalAssessmentService
    private let outcomeService: OutcomeMeasureService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Time Range Options

    enum TimeRange: String, CaseIterable, Identifiable {
        case oneMonth = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1Y"
        case all = "All"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .oneMonth: return "1 Month"
            case .threeMonths: return "3 Months"
            case .sixMonths: return "6 Months"
            case .oneYear: return "1 Year"
            case .all: return "All Time"
            }
        }

        var days: Int? {
            switch self {
            case .oneMonth: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .oneYear: return 365
            case .all: return nil
            }
        }

        var startDate: Date? {
            guard let days = days else { return nil }
            return Calendar.current.date(byAdding: .day, value: -days, to: Date())
        }
    }

    // MARK: - Computed Properties

    /// Overall progress status based on all metrics
    var overallStatus: ProgressStatus {
        progressSummary.overallStatus
    }

    /// Color for overall status display
    var statusColor: Color {
        overallStatus.color
    }

    /// Icon for overall status
    var statusIcon: String {
        overallStatus.iconName
    }

    /// Whether any data has been loaded
    var hasData: Bool {
        !romProgress.isEmpty || !painProgress.isEmpty || !outcomeProgress.isEmpty
    }

    /// MCID achievement rate
    var mcidAchievementRate: Double {
        guard progressSummary.totalOutcomeMeasures > 0 else { return 0 }
        return Double(progressSummary.mcidAchievements) / Double(progressSummary.totalOutcomeMeasures) * 100
    }

    // MARK: - Initialization

    @MainActor
    init(
        assessmentService: ClinicalAssessmentService = ClinicalAssessmentService(),
        outcomeService: OutcomeMeasureService = .shared
    ) {
        self.assessmentService = assessmentService
        self.outcomeService = outcomeService

        setupObservers()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Reload data when time range changes
        $selectedTimeRange
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.refreshAllData()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    /// Initialize with patient ID and load data
    func initialize(patientId: UUID) async {
        self.patientId = patientId
        await refreshAllData()
    }

    /// Refresh all progress data
    func refreshAllData() async {
        guard let patientId = patientId else {
            errorMessage = "No patient selected"
            return
        }

        isLoading = true
        errorMessage = nil

        // Clear previous errors
        romError = nil
        painError = nil
        outcomesError = nil

        // Load data sections in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadROMProgress(patientId: patientId) }
            group.addTask { await self.loadPainProgress(patientId: patientId) }
            group.addTask { await self.loadOutcomeProgress(patientId: patientId) }
        }

        // Calculate overall summary
        calculateProgressSummary()

        // Check if all sections failed
        if romError != nil && painError != nil && outcomesError != nil {
            errorMessage = "Unable to load progress data. Please check your connection."
        }

        isLoading = false
    }

    /// Load ROM progress data
    private func loadROMProgress(patientId: UUID) async {
        isLoadingROM = true

        do {
            let assessments = try await assessmentService.fetchAssessments(for: patientId, limit: 20)

            // Filter by time range
            let filteredAssessments = filterByTimeRange(assessments)

            // Extract ROM measurements and build progress items
            var romData: [String: [(date: Date, measurement: ROMeasurement)]] = [:]

            for assessment in filteredAssessments {
                guard let measurements = assessment.romMeasurements else { continue }
                for measurement in measurements {
                    let key = "\(measurement.joint)_\(measurement.movement)_\(measurement.side.rawValue)"
                    if romData[key] == nil {
                        romData[key] = []
                    }
                    romData[key]?.append((assessment.assessmentDate, measurement))
                }
            }

            // Build progress items
            var progressItems: [ROMProgressItem] = []
            for (key, measurements) in romData {
                let sorted = measurements.sorted { $0.date < $1.date }
                guard let first = sorted.first, let last = sorted.last else { continue }

                let trendPoints = sorted.map { TrendDataPoint(date: $0.date, value: Double($0.measurement.degrees), label: nil) }

                let item = ROMProgressItem(
                    joint: first.measurement.joint,
                    movement: first.measurement.movement,
                    side: first.measurement.side,
                    initialDegrees: first.measurement.degrees,
                    currentDegrees: last.measurement.degrees,
                    normalRange: first.measurement.normalRangeMin...first.measurement.normalRangeMax,
                    measurements: trendPoints
                )
                progressItems.append(item)

                romTrends[key] = trendPoints
            }

            romProgress = progressItems.sorted { $0.displayTitle < $1.displayTitle }

            #if DEBUG
            print("[AssessmentProgressVM] Loaded \(romProgress.count) ROM progress items")
            #endif
        } catch {
            romError = "Unable to load ROM progress"
            DebugLogger.shared.error("AssessmentProgressViewModel", "ROM progress error: \(error)")
        }

        isLoadingROM = false
    }

    /// Load pain progress data
    private func loadPainProgress(patientId: UUID) async {
        isLoadingPain = true

        do {
            let assessments = try await assessmentService.fetchAssessments(for: patientId, limit: 20)
            let filteredAssessments = filterByTimeRange(assessments)

            // Collect pain data over time
            var restPainData: [(date: Date, score: Int)] = []
            var activityPainData: [(date: Date, score: Int)] = []
            var worstPainData: [(date: Date, score: Int)] = []

            for assessment in filteredAssessments {
                if let pain = assessment.painAtRest {
                    restPainData.append((assessment.assessmentDate, pain))
                }
                if let pain = assessment.painWithActivity {
                    activityPainData.append((assessment.assessmentDate, pain))
                }
                if let pain = assessment.painWorst {
                    worstPainData.append((assessment.assessmentDate, pain))
                }
            }

            // Build progress items
            var progressItems: [PainProgressItem] = []

            if !restPainData.isEmpty {
                let sorted = restPainData.sorted { $0.date < $1.date }
                let trendPoints = sorted.map { TrendDataPoint(date: $0.date, value: Double($0.score), label: nil) }
                progressItems.append(PainProgressItem(
                    painType: "rest",
                    initialScore: sorted.first!.score,
                    currentScore: sorted.last!.score,
                    measurements: trendPoints
                ))
                painTrend = trendPoints // Use rest pain as primary trend
            }

            if !activityPainData.isEmpty {
                let sorted = activityPainData.sorted { $0.date < $1.date }
                let trendPoints = sorted.map { TrendDataPoint(date: $0.date, value: Double($0.score), label: nil) }
                progressItems.append(PainProgressItem(
                    painType: "activity",
                    initialScore: sorted.first!.score,
                    currentScore: sorted.last!.score,
                    measurements: trendPoints
                ))
            }

            if !worstPainData.isEmpty {
                let sorted = worstPainData.sorted { $0.date < $1.date }
                let trendPoints = sorted.map { TrendDataPoint(date: $0.date, value: Double($0.score), label: nil) }
                progressItems.append(PainProgressItem(
                    painType: "worst",
                    initialScore: sorted.first!.score,
                    currentScore: sorted.last!.score,
                    measurements: trendPoints
                ))
            }

            painProgress = progressItems

            #if DEBUG
            print("[AssessmentProgressVM] Loaded \(painProgress.count) pain progress items")
            #endif
        } catch {
            painError = "Unable to load pain progress"
            DebugLogger.shared.error("AssessmentProgressViewModel", "Pain progress error: \(error)")
        }

        isLoadingPain = false
    }

    /// Load outcome measure progress
    private func loadOutcomeProgress(patientId: UUID) async {
        isLoadingOutcomes = true

        do {
            // Fetch progress from outcome service
            let progress = try await outcomeService.fetchPatientProgress(patientId: patientId)

            var progressItems: [OutcomeProgressItem] = []

            for summary in progress.measures {
                // Fetch trend data for this measure type
                let trend = try await outcomeService.fetchMeasureTrend(
                    patientId: patientId,
                    measureType: summary.measureType,
                    limit: 10
                )

                let trendPoints = trend.measurements.map {
                    TrendDataPoint(date: $0.date, value: $0.score, label: nil)
                }

                let item = OutcomeProgressItem(
                    measureType: summary.measureType,
                    initialScore: summary.previousScore ?? summary.latestScore,
                    currentScore: summary.latestScore,
                    mcidThreshold: summary.measureType.mcidThreshold,
                    measurements: trendPoints
                )

                progressItems.append(item)
                outcomeTrends[summary.measureType] = trendPoints
            }

            outcomeProgress = progressItems

            // Update MCID count
            progressSummary.mcidAchievements = progress.mcidAchievementCount
            progressSummary.totalOutcomeMeasures = progress.measures.count

            #if DEBUG
            print("[AssessmentProgressVM] Loaded \(outcomeProgress.count) outcome progress items")
            #endif
        } catch {
            outcomesError = "Unable to load outcome measures"
            DebugLogger.shared.error("AssessmentProgressViewModel", "Outcome progress error: \(error)")
        }

        isLoadingOutcomes = false
    }

    // MARK: - Progress Calculation

    /// Calculate overall progress summary
    private func calculateProgressSummary() {
        var summary = PatientProgressSummary()

        // Count ROM improvements/declines
        for item in romProgress {
            if item.progressStatus == .improving { summary.romImprovements += 1 }
            if item.progressStatus == .declining { summary.romDeclines += 1 }
        }

        // Count pain improvements/declines
        for item in painProgress {
            if item.progressStatus == .improving { summary.painImprovements += 1 }
            if item.progressStatus == .declining { summary.painDeclines += 1 }
        }

        // Count MCID achievements
        summary.mcidAchievements = outcomeProgress.filter { $0.meetsMcid }.count
        summary.totalOutcomeMeasures = outcomeProgress.count

        // Calculate overall status
        let improvements = summary.romImprovements + summary.painImprovements + summary.mcidAchievements
        let declines = summary.romDeclines + summary.painDeclines

        if improvements > declines && improvements > 0 {
            summary.overallStatus = .improving
        } else if declines > improvements && declines > 0 {
            summary.overallStatus = .declining
        } else {
            summary.overallStatus = .stable
        }

        progressSummary = summary
    }

    // MARK: - Helpers

    /// Filter assessments by selected time range
    private func filterByTimeRange(_ assessments: [ClinicalAssessment]) -> [ClinicalAssessment] {
        guard let startDate = selectedTimeRange.startDate else { return assessments }
        return assessments.filter { $0.assessmentDate >= startDate }
    }

    /// Get trend data for a specific ROM measurement
    func getROMTrend(joint: String, movement: String, side: Side) -> [TrendDataPoint] {
        let key = "\(joint)_\(movement)_\(side.rawValue)"
        return romTrends[key] ?? []
    }

    /// Get trend data for a specific outcome measure
    func getOutcomeTrend(measureType: OutcomeMeasureType) -> [TrendDataPoint] {
        return outcomeTrends[measureType] ?? []
    }

    /// Clear error messages
    func clearErrors() {
        errorMessage = nil
        romError = nil
        painError = nil
        outcomesError = nil
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension AssessmentProgressViewModel {
    static var preview: AssessmentProgressViewModel {
        let viewModel = AssessmentProgressViewModel()
        viewModel.patientId = UUID()

        // Sample ROM progress
        viewModel.romProgress = [
            ROMProgressItem(
                joint: "shoulder",
                movement: "flexion",
                side: .right,
                initialDegrees: 120,
                currentDegrees: 155,
                normalRange: 150...180,
                measurements: [
                    TrendDataPoint(date: Date().addingTimeInterval(-86400 * 30), value: 120, label: nil),
                    TrendDataPoint(date: Date().addingTimeInterval(-86400 * 20), value: 135, label: nil),
                    TrendDataPoint(date: Date().addingTimeInterval(-86400 * 10), value: 145, label: nil),
                    TrendDataPoint(date: Date(), value: 155, label: nil)
                ]
            )
        ]

        // Sample pain progress
        viewModel.painProgress = [
            PainProgressItem(
                painType: "activity",
                initialScore: 7,
                currentScore: 4,
                measurements: [
                    TrendDataPoint(date: Date().addingTimeInterval(-86400 * 30), value: 7, label: nil),
                    TrendDataPoint(date: Date().addingTimeInterval(-86400 * 20), value: 6, label: nil),
                    TrendDataPoint(date: Date().addingTimeInterval(-86400 * 10), value: 5, label: nil),
                    TrendDataPoint(date: Date(), value: 4, label: nil)
                ]
            )
        ]

        // Sample outcome progress
        viewModel.outcomeProgress = [
            OutcomeProgressItem(
                measureType: .LEFS,
                initialScore: 54,
                currentScore: 68,
                mcidThreshold: 9.0,
                measurements: [
                    TrendDataPoint(date: Date().addingTimeInterval(-86400 * 30), value: 54, label: nil),
                    TrendDataPoint(date: Date(), value: 68, label: nil)
                ]
            )
        ]

        viewModel.progressSummary = PatientProgressSummary(
            overallStatus: .improving,
            romImprovements: 3,
            romDeclines: 0,
            painImprovements: 2,
            painDeclines: 0,
            mcidAchievements: 1,
            totalOutcomeMeasures: 2
        )

        return viewModel
    }
}
#endif
