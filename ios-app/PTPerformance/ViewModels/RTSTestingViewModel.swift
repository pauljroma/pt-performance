//
//  RTSTestingViewModel.swift
//  PTPerformance
//
//  ViewModel for recording test results, milestone criteria tracking,
//  and readiness assessment in Return-to-Sport protocols.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for RTS testing and criteria management
/// Handles test recording, readiness scoring, and phase advancement decisions
@MainActor
class RTSTestingViewModel: ObservableObject {

    // MARK: - Static Formatters
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // MARK: - Published Properties - Criteria Data

    /// Milestone criteria for the current phase
    @Published var criteria: [RTSMilestoneCriterion] = []

    /// Test results keyed by criterion ID
    @Published var testResults: [UUID: RTSTestResult] = [:]

    /// Phase advancement history for the protocol
    @Published var advancements: [RTSPhaseAdvancement] = []

    // MARK: - Published Properties - UI State

    /// Whether data is currently loading
    @Published var isLoading = false

    /// Whether a save operation is in progress
    @Published var isSaving = false

    /// Error message for display
    @Published var errorMessage: String?

    /// Success message for display
    @Published var successMessage: String?

    // MARK: - Published Properties - Test Recording Form

    /// Currently selected criterion for testing
    @Published var selectedCriterion: RTSMilestoneCriterion?

    /// Test value input (as string for text field binding)
    @Published var testValue: String = ""

    /// Notes for the test result
    @Published var testNotes: String = ""

    // MARK: - Published Properties - Readiness Assessment Form

    /// Physical readiness score (0-100)
    @Published var physicalScore: Double = 0

    /// Functional readiness score (0-100)
    @Published var functionalScore: Double = 0

    /// Psychological readiness score (0-100)
    @Published var psychologicalScore: Double = 0

    /// Identified risk factors
    @Published var riskFactors: [RTSRiskFactor] = []

    /// Notes for the readiness assessment
    @Published var readinessNotes: String = ""

    // MARK: - Private Properties

    private let service = RTSService.shared
    private var cancellables = Set<AnyCancellable>()
    private var messageClearTask: Task<Void, Never>?

    // MARK: - Computed Properties - Criteria Status

    /// Criteria that have been passed
    var passedCriteria: [RTSMilestoneCriterion] {
        criteria.filter { testResults[$0.id]?.passed == true }
    }

    /// Criteria that have been tested but failed
    var failedCriteria: [RTSMilestoneCriterion] {
        criteria.filter {
            guard let result = testResults[$0.id] else { return false }
            return !result.passed
        }
    }

    /// Criteria that have not yet been tested
    var untestedCriteria: [RTSMilestoneCriterion] {
        criteria.filter { testResults[$0.id] == nil }
    }

    /// Required criteria (must pass to advance)
    var requiredCriteria: [RTSMilestoneCriterion] {
        criteria.filter { $0.isRequired }
    }

    /// Optional criteria
    var optionalCriteria: [RTSMilestoneCriterion] {
        criteria.filter { !$0.isRequired }
    }

    /// Whether all required criteria have been passed
    var allRequiredPassed: Bool {
        requiredCriteria.allSatisfy { testResults[$0.id]?.passed == true }
    }

    // MARK: - Computed Properties - Counts (for view compatibility)

    /// Total number of criteria
    var totalCount: Int { criteria.count }

    /// Number of passed criteria
    var passedCount: Int { passedCriteria.count }

    /// Number of required criteria
    var requiredCount: Int { requiredCriteria.count }

    /// Number of required criteria that have passed
    var requiredPassedCount: Int {
        requiredCriteria.filter { testResults[$0.id]?.passed == true }.count
    }

    /// Progress as integer percentage (0-100)
    var progressPercentage: Int {
        guard totalCount > 0 else { return 0 }
        return Int((Double(passedCount) / Double(totalCount)) * 100)
    }

    /// Progress as CGFloat fraction (0-1)
    var progressFraction: CGFloat {
        guard totalCount > 0 else { return 0 }
        return CGFloat(passedCount) / CGFloat(totalCount)
    }

    /// Color for progress indicator based on completion percentage
    var progressColor: Color {
        if progressFraction >= 0.8 {
            return .green
        } else if progressFraction >= 0.5 {
            return .yellow
        } else {
            return .orange
        }
    }

    /// Progress percentage for criteria completion (based on passed criteria)
    var criteriaProgress: Double {
        guard !criteria.isEmpty else { return 0 }
        return Double(passedCriteria.count) / Double(criteria.count)
    }

    /// Progress percentage for required criteria specifically
    var requiredCriteriaProgress: Double {
        guard !requiredCriteria.isEmpty else { return 0 }
        let passedRequired = requiredCriteria.filter { testResults[$0.id]?.passed == true }
        return Double(passedRequired.count) / Double(requiredCriteria.count)
    }

    // MARK: - Computed Properties - Readiness Scores

    /// Calculated overall readiness score
    var calculatedOverallScore: Double {
        RTSReadinessScore.calculateOverall(
            physical: physicalScore,
            functional: functionalScore,
            psychological: psychologicalScore
        )
    }

    /// Traffic light based on calculated overall score
    var calculatedTrafficLight: RTSTrafficLight {
        RTSTrafficLight.from(score: calculatedOverallScore)
    }

    /// Formatted overall score as percentage string
    var formattedOverallScore: String {
        String(format: "%.0f%%", calculatedOverallScore)
    }

    /// Whether readiness form is valid for submission
    var isReadinessFormValid: Bool {
        physicalScore >= 0 && physicalScore <= 100 &&
        functionalScore >= 0 && functionalScore <= 100 &&
        psychologicalScore >= 0 && psychologicalScore <= 100
    }

    // MARK: - Computed Properties - Grouped Criteria

    /// Criteria grouped by category
    var criteriaByCategory: [RTSCriterionCategory: [RTSMilestoneCriterion]] {
        Dictionary(grouping: criteria, by: { $0.category })
    }

    /// Categories that have criteria (sorted)
    var activeCategories: [RTSCriterionCategory] {
        Array(criteriaByCategory.keys).sorted { $0.rawValue < $1.rawValue }
    }

    /// Count of high severity risk factors
    var highRiskCount: Int {
        riskFactors.filter { $0.severity == .high }.count
    }

    /// Count of moderate severity risk factors
    var moderateRiskCount: Int {
        riskFactors.filter { $0.severity == .moderate }.count
    }

    /// Whether any high severity risk factors exist
    var hasHighRisk: Bool {
        highRiskCount > 0
    }

    // MARK: - Initialization

    init() {
        DebugLogger.shared.log("[RTSTestingVM] Initialized", level: .diagnostic)
    }

    deinit {
        messageClearTask?.cancel()
        cancellables.removeAll()
    }

    // MARK: - Data Loading

    /// Load criteria for a specific phase (single parameter version)
    /// - Parameter phaseId: The phase's UUID
    func loadCriteria(phaseId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            criteria = try await service.fetchCriteria(phaseId: phaseId)

            DebugLogger.shared.log("[RTSTestingVM] Loaded \(criteria.count) criteria for phase", level: .success)
        } catch {
            handleError(error, context: "loading criteria")
        }

        isLoading = false
    }

    /// Load criteria and test results together (convenience method)
    /// - Parameters:
    ///   - phaseId: The phase's UUID
    ///   - protocolId: The protocol's UUID
    func loadCriteria(phaseId: UUID, protocolId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch criteria for the phase
            var fetchedCriteria = try await service.fetchCriteria(phaseId: phaseId)

            // Fetch latest results and attach to criteria
            let latestResults = try await service.fetchLatestResults(phaseId: phaseId, protocolId: protocolId)

            for index in fetchedCriteria.indices {
                fetchedCriteria[index].latestResult = latestResults[fetchedCriteria[index].id]
            }

            criteria = fetchedCriteria
            testResults = latestResults

            DebugLogger.shared.log("[RTSTestingVM] Loaded \(criteria.count) criteria with \(latestResults.count) results", level: .success)
        } catch {
            handleError(error, context: "loading criteria and results")
        }

        isLoading = false
    }

    /// Load test results for a phase within a protocol
    /// - Parameters:
    ///   - phaseId: The phase's UUID
    ///   - protocolId: The protocol's UUID
    func loadTestResults(phaseId: UUID, protocolId: UUID) async {
        isLoading = true

        do {
            let results = try await service.fetchLatestResults(phaseId: phaseId, protocolId: protocolId)
            testResults = results

            // Update criteria with their latest results
            for index in criteria.indices {
                criteria[index].latestResult = testResults[criteria[index].id]
            }

            DebugLogger.shared.log("[RTSTestingVM] Loaded \(results.count) test results", level: .success)
        } catch {
            DebugLogger.shared.error("RTSTestingViewModel", "Failed to load test results: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Load advancement history for a protocol
    /// - Parameter protocolId: The protocol's UUID
    func loadAdvancements(protocolId: UUID) async {
        isLoading = true

        do {
            advancements = try await service.fetchAdvancements(protocolId: protocolId)

            DebugLogger.shared.log("[RTSTestingVM] Loaded \(advancements.count) advancements", level: .success)
        } catch {
            DebugLogger.shared.error("RTSTestingViewModel", "Failed to load advancements: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Test Recording

    /// Record a test result for a criterion
    /// - Parameters:
    ///   - criterionId: The criterion's UUID
    ///   - protocolId: The protocol's UUID
    ///   - value: The measured value
    ///   - unit: The unit of measurement
    ///   - recordedBy: UUID of the person recording
    ///   - notes: Optional notes about the test
    /// - Returns: True if recording was successful
    func recordTest(
        criterionId: UUID,
        protocolId: UUID,
        value: Double,
        unit: String,
        recordedBy: UUID,
        notes: String?
    ) async -> Bool {
        isSaving = true
        errorMessage = nil

        do {
            let result = try await service.recordTestResult(
                criterionId: criterionId,
                protocolId: protocolId,
                value: value,
                unit: unit,
                recordedBy: recordedBy,
                notes: notes
            )

            // Update local state
            testResults[criterionId] = result

            // Update the criterion's latest result
            if let index = criteria.firstIndex(where: { $0.id == criterionId }) {
                criteria[index].latestResult = result
            }

            let passedText = result.passed ? "PASSED" : "NOT PASSED"
            showSuccessMessage("Test recorded: \(passedText)")

            DebugLogger.shared.log("[RTSTestingVM] Recorded test for criterion \(criterionId): \(value) \(unit), passed: \(result.passed)", level: .success)

            // Clear the form
            testValue = ""
            testNotes = ""
            selectedCriterion = nil

            isSaving = false
            return true
        } catch {
            handleError(error, context: "recording test")
            isSaving = false
            return false
        }
    }

    /// Evaluate if a test value would pass a criterion
    /// - Parameters:
    ///   - criterion: The criterion to evaluate against
    ///   - value: The value to test
    /// - Returns: True if the value would pass
    func evaluateTest(criterion: RTSMilestoneCriterion, value: Double) -> Bool {
        guard let target = criterion.targetValue else { return true }
        return criterion.comparisonOperator.evaluate(value: value, target: target)
    }

    /// Prepare for recording a test by setting the selected criterion
    /// - Parameter criterion: The criterion to test
    func prepareTest(for criterion: RTSMilestoneCriterion) {
        selectedCriterion = criterion
        testValue = ""
        testNotes = ""
    }

    // MARK: - Readiness Assessment

    /// Record a readiness score assessment
    /// - Parameters:
    ///   - protocolId: The protocol's UUID
    ///   - phaseId: The current phase's UUID
    ///   - recordedBy: UUID of the person recording
    /// - Returns: The created readiness score or nil if failed
    func recordReadinessScore(
        protocolId: UUID,
        phaseId: UUID,
        recordedBy: UUID
    ) async -> RTSReadinessScore? {
        guard isReadinessFormValid else {
            errorMessage = "Please ensure all scores are between 0 and 100"
            return nil
        }

        isSaving = true
        errorMessage = nil

        do {
            let riskFactorInputs: [RTSRiskFactorInput] = riskFactors.map { factor in
                RTSRiskFactorInput(
                    category: factor.category,
                    name: factor.name,
                    severity: factor.severity.rawValue,
                    notes: factor.notes
                )
            }

            var input = RTSReadinessScoreInput(
                protocolId: protocolId.uuidString,
                phaseId: phaseId.uuidString,
                recordedBy: recordedBy.uuidString,
                recordedAt: Self.iso8601Formatter.string(from: Date()),
                physicalScore: physicalScore,
                functionalScore: functionalScore,
                psychologicalScore: psychologicalScore,
                riskFactors: riskFactorInputs,
                notes: readinessNotes.isEmpty ? nil : readinessNotes
            )

            // Calculate derived fields
            input.calculateDerivedFields()

            let score = try await service.recordReadinessScore(input: input)

            showSuccessMessage("Readiness score recorded: \(score.overallPercentage)")

            DebugLogger.shared.log("[RTSTestingVM] Recorded readiness score: \(score.id), overall: \(score.overallScore)", level: .success)

            // Reset form
            resetReadinessForm()

            isSaving = false
            return score
        } catch {
            handleError(error, context: "recording readiness score")
            isSaving = false
            return nil
        }
    }

    /// Add a risk factor to the assessment
    /// - Parameters:
    ///   - category: Risk factor category
    ///   - name: Name/description of the risk
    ///   - severity: Severity level
    ///   - notes: Optional additional notes
    func addRiskFactor(category: String, name: String, severity: RTSRiskSeverity, notes: String?) {
        let factor = RTSRiskFactor(
            category: category,
            name: name,
            severity: severity,
            notes: notes
        )
        riskFactors.append(factor)

        DebugLogger.shared.log("[RTSTestingVM] Added risk factor: \(name) (\(severity.rawValue))", level: .diagnostic)
    }

    /// Remove a risk factor from the assessment
    /// - Parameter factor: The risk factor to remove
    func removeRiskFactor(_ factor: RTSRiskFactor) {
        riskFactors.removeAll { $0.id == factor.id }

        DebugLogger.shared.log("[RTSTestingVM] Removed risk factor: \(factor.name)", level: .diagnostic)
    }

    /// Clear all risk factors
    func clearRiskFactors() {
        riskFactors.removeAll()
    }

    // MARK: - Phase Advancement

    /// Determine if the current phase can be advanced
    /// - Returns: Tuple with can advance flag and reason string
    func canAdvancePhase() -> (canAdvance: Bool, reason: String) {
        // Check if all required criteria are passed
        guard allRequiredPassed else {
            let failedRequired = requiredCriteria.filter { testResults[$0.id]?.passed != true }
            let names = failedRequired.map { $0.name }.joined(separator: ", ")
            return (false, "Required criteria not met: \(names)")
        }

        // Check for high severity risk factors
        if hasHighRisk {
            return (false, "High severity risk factors present. Address before advancing.")
        }

        // Check minimum readiness (if we have a recent score)
        // This would typically check the latest readiness from the protocol VM
        let passedCount = passedCriteria.count
        let totalCount = criteria.count
        let percentage = totalCount > 0 ? Int((Double(passedCount) / Double(totalCount)) * 100) : 0

        return (true, "All required criteria met. \(passedCount)/\(totalCount) (\(percentage)%) criteria passed.")
    }

    /// Request advancement to the next phase
    /// - Parameters:
    ///   - protocolId: The protocol's UUID
    ///   - fromPhaseId: Current phase's UUID
    ///   - toPhaseId: Target phase's UUID
    ///   - decidedBy: UUID of the person making the decision
    ///   - reason: Reason for the advancement decision
    /// - Returns: True if advancement was recorded successfully
    func requestAdvancement(
        protocolId: UUID,
        fromPhaseId: UUID,
        toPhaseId: UUID,
        decidedBy: UUID,
        reason: String
    ) async -> Bool {
        let (canAdvance, advanceReason) = canAdvancePhase()

        guard canAdvance else {
            errorMessage = advanceReason
            return false
        }

        isSaving = true
        errorMessage = nil

        do {
            let criteriaSummary = getCriteriaSummary()

            let advancement = try await service.recordAdvancement(
                protocolId: protocolId,
                fromPhaseId: fromPhaseId,
                toPhaseId: toPhaseId,
                decision: .advance,
                reason: reason,
                criteriaSummary: criteriaSummary,
                decidedBy: decidedBy
            )

            advancements.insert(advancement, at: 0)
            showSuccessMessage("Phase advancement approved")

            DebugLogger.shared.log("[RTSTestingVM] Recorded advancement: \(advancement.id)", level: .success)

            isSaving = false
            return true
        } catch {
            handleError(error, context: "requesting advancement")
            isSaving = false
            return false
        }
    }

    // MARK: - Helpers

    /// Reset the ViewModel to initial state
    func reset() {
        criteria = []
        testResults = [:]
        advancements = []
        selectedCriterion = nil
        testValue = ""
        testNotes = ""
        resetReadinessForm()
        clearMessages()

        DebugLogger.shared.log("[RTSTestingVM] Reset complete", level: .diagnostic)
    }

    /// Reset the readiness assessment form
    func resetReadinessForm() {
        physicalScore = 0
        functionalScore = 0
        psychologicalScore = 0
        riskFactors = []
        readinessNotes = ""
    }

    /// Clear error and success messages
    func clearMessages() {
        messageClearTask?.cancel()
        errorMessage = nil
        successMessage = nil
    }

    /// Get a summary of the current criteria status
    /// - Returns: RTSCriteriaSummary for the current state
    func getCriteriaSummary() -> RTSCriteriaSummary {
        let total = criteria.count
        let passed = passedCriteria.count
        let requiredTotal = requiredCriteria.count
        let requiredPassed = requiredCriteria.filter { testResults[$0.id]?.passed == true }.count

        // Build notes with key results
        var notes: [String] = []
        for criterion in passedCriteria.prefix(3) {
            if let result = testResults[criterion.id] {
                notes.append("\(criterion.name): \(result.formattedValue)")
            }
        }

        return RTSCriteriaSummary(
            totalCriteria: total,
            passedCriteria: passed,
            requiredPassed: requiredPassed,
            requiredTotal: requiredTotal,
            notes: notes.isEmpty ? nil : notes.joined(separator: ", ")
        )
    }

    /// Get status for a specific criterion
    /// - Parameter criterion: The criterion to check
    /// - Returns: Status text and color tuple
    func getStatusForCriterion(_ criterion: RTSMilestoneCriterion) -> (text: String, color: Color) {
        guard let result = testResults[criterion.id] else {
            return ("Not Tested", .gray)
        }

        if result.passed {
            return ("Passed", .green)
        } else {
            return ("Not Passed", .red)
        }
    }

    // MARK: - Private Helpers

    /// Handle an error by logging and setting error message
    private func handleError(_ error: Error, context: String) {
        DebugLogger.shared.error("RTSTestingViewModel", "\(context): \(error.localizedDescription)")
        errorMessage = error.localizedDescription
    }

    /// Show a success message that auto-clears after 3 seconds
    private func showSuccessMessage(_ message: String) {
        successMessage = message

        // Auto-clear after 3 seconds
        messageClearTask?.cancel()
        messageClearTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if !Task.isCancelled {
                successMessage = nil
            }
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension RTSTestingViewModel {
    /// Preview instance with sample data
    static var preview: RTSTestingViewModel {
        let viewModel = RTSTestingViewModel()
        viewModel.criteria = [
            RTSMilestoneCriterion.strengthSample,
            RTSMilestoneCriterion.functionalSample,
            RTSMilestoneCriterion.painSample,
            RTSMilestoneCriterion.psychologicalSample
        ]

        // Add some test results
        guard viewModel.criteria.count >= 3 else { return viewModel }
        viewModel.testResults[viewModel.criteria[0].id] = RTSTestResult(
            criterionId: viewModel.criteria[0].id,
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 87,
            unit: "%",
            passed: true
        )
        viewModel.testResults[viewModel.criteria[2].id] = RTSTestResult(
            criterionId: viewModel.criteria[2].id,
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 3,
            unit: "/10",
            passed: false,
            notes: "Pain with cutting movements"
        )

        // Set readiness scores
        viewModel.physicalScore = 75
        viewModel.functionalScore = 70
        viewModel.psychologicalScore = 65

        // Add risk factors
        viewModel.riskFactors = [
            RTSRiskFactor.strengthSample,
            RTSRiskFactor.psychologicalSample
        ]

        return viewModel
    }

    /// Preview instance in loading state
    static var loadingPreview: RTSTestingViewModel {
        let viewModel = RTSTestingViewModel()
        viewModel.isLoading = true
        return viewModel
    }

    /// Preview instance with error state
    static var errorPreview: RTSTestingViewModel {
        let viewModel = RTSTestingViewModel()
        viewModel.errorMessage = "Failed to record test result. Please try again."
        return viewModel
    }

    /// Preview instance with all criteria passed
    static var allPassedPreview: RTSTestingViewModel {
        let viewModel = RTSTestingViewModel()
        viewModel.criteria = [
            RTSMilestoneCriterion.strengthSample,
            RTSMilestoneCriterion.functionalSample
        ]

        // All tests passed
        for criterion in viewModel.criteria {
            viewModel.testResults[criterion.id] = RTSTestResult(
                criterionId: criterion.id,
                protocolId: UUID(),
                recordedBy: UUID(),
                value: 90,
                unit: "%",
                passed: true
            )
        }

        viewModel.physicalScore = 88
        viewModel.functionalScore = 85
        viewModel.psychologicalScore = 82

        return viewModel
    }
}
#endif
