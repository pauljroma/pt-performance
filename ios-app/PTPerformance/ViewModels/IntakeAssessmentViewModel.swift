//
//  IntakeAssessmentViewModel.swift
//  PTPerformance
//
//  ViewModel for managing intake assessment form including ROM measurements,
//  pain assessment tracking, functional tests, and save/submit/sign workflow.
//

import SwiftUI
import Combine

// MARK: - Form Section State

/// Tracks completion status of assessment sections
struct AssessmentSectionStatus: Equatable {
    var subjectiveComplete: Bool = false
    var objectiveComplete: Bool = false
    var painComplete: Bool = false
    var romComplete: Bool = false
    var functionalTestsComplete: Bool = false
    var assessmentComplete: Bool = false
    var planComplete: Bool = false

    var allRequiredComplete: Bool {
        subjectiveComplete && objectiveComplete && assessmentComplete && planComplete
    }

    var completionPercentage: Double {
        let sections: [Bool] = [
            subjectiveComplete,
            objectiveComplete,
            painComplete,
            romComplete,
            functionalTestsComplete,
            assessmentComplete,
            planComplete
        ]
        let completed = sections.filter { $0 }.count
        return Double(completed) / Double(sections.count) * 100
    }
}

// MARK: - IntakeAssessmentViewModel

/// ViewModel for intake assessment form management
/// Manages comprehensive initial evaluation including ROM, pain, and functional tests
@MainActor
class IntakeAssessmentViewModel: ObservableObject {

    // MARK: - Published Properties - Form State

    // Patient & Session Info
    @Published var patientId: UUID?
    @Published var therapistId: UUID?
    @Published var assessmentDate: Date = Date()

    // Subjective Section
    @Published var chiefComplaint: String = ""
    @Published var historyOfPresentIllness: String = ""
    @Published var pastMedicalHistory: String = ""
    @Published var functionalGoals: [String] = []
    @Published var newGoal: String = ""

    // Pain Assessment
    @Published var painAtRest: Int = 0
    @Published var painWithActivity: Int = 5
    @Published var painWorst: Int = 7
    @Published var painLocations: [String] = []
    @Published var newPainLocation: String = ""

    // ROM Measurements
    @Published var romMeasurements: [ROMeasurement] = []
    @Published var selectedJoint: JointType = .shoulder
    @Published var selectedSide: Side = .right

    // Functional Tests
    @Published var functionalTests: [FunctionalTest] = []

    // Objective & Assessment
    @Published var objectiveFindings: String = ""
    @Published var assessmentSummary: String = ""
    @Published var treatmentPlan: String = ""

    // MARK: - Published Properties - UI State

    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var showValidationErrors = false

    @Published var currentAssessment: ClinicalAssessment?
    @Published var sectionStatus = AssessmentSectionStatus()
    @Published var lastAutoSaveDate: Date?

    // MARK: - Section-specific errors

    @Published var subjectiveError: String?
    @Published var objectiveError: String?
    @Published var painError: String?
    @Published var romError: String?
    @Published var assessmentError: String?

    // MARK: - Dependencies

    private let assessmentService: ClinicalAssessmentService
    private var autoSaveTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Constants

    private enum AutoSaveConfig {
        static let interval: TimeInterval = 30.0
    }

    // MARK: - Computed Properties

    /// Whether form inputs are valid for saving as draft
    var canSaveDraft: Bool {
        patientId != nil && therapistId != nil && !isSaving
    }

    /// Whether form is complete enough to submit
    var canSubmit: Bool {
        guard patientId != nil, therapistId != nil else { return false }
        return sectionStatus.allRequiredComplete && !isSaving
    }

    /// Whether assessment can be signed
    var canSign: Bool {
        guard let assessment = currentAssessment else { return false }
        return assessment.status == .complete && assessment.isReadyForSignature && !isSaving
    }

    /// Average pain score across measurements
    var averagePainScore: Double {
        let scores = [painAtRest, painWithActivity, painWorst]
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }

    /// Whether pain levels indicate concern
    var isPainConcerning: Bool {
        painWorst >= 7 || painWithActivity >= 6
    }

    /// Count of ROM limitations found
    var romLimitationsCount: Int {
        romMeasurements.filter { $0.isLimited }.count
    }

    /// Count of abnormal functional test results
    var abnormalTestsCount: Int {
        functionalTests.filter { $0.isAbnormal }.count
    }

    /// Formatted assessment date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: assessmentDate)
    }

    // MARK: - Initialization

    init(assessmentService: ClinicalAssessmentService = ClinicalAssessmentService()) {
        self.assessmentService = assessmentService
        setupAutoSave()
        setupFormObservers()
    }

    deinit {
        autoSaveTimer?.invalidate()
    }

    // MARK: - Setup

    private func setupAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: AutoSaveConfig.interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.autoSaveDraft()
            }
        }
    }

    private func setupFormObservers() {
        // Observe changes to update section completion status
        $chiefComplaint
            .combineLatest($historyOfPresentIllness)
            .sink { [weak self] complaint, history in
                self?.sectionStatus.subjectiveComplete = !complaint.isEmpty && !history.isEmpty
            }
            .store(in: &cancellables)

        $objectiveFindings
            .sink { [weak self] findings in
                self?.sectionStatus.objectiveComplete = !findings.isEmpty
            }
            .store(in: &cancellables)

        $assessmentSummary
            .sink { [weak self] summary in
                self?.sectionStatus.assessmentComplete = !summary.isEmpty
            }
            .store(in: &cancellables)

        $treatmentPlan
            .sink { [weak self] plan in
                self?.sectionStatus.planComplete = !plan.isEmpty
            }
            .store(in: &cancellables)

        $painLocations
            .sink { [weak self] locations in
                self?.sectionStatus.painComplete = !locations.isEmpty
            }
            .store(in: &cancellables)

        $romMeasurements
            .sink { [weak self] measurements in
                self?.sectionStatus.romComplete = !measurements.isEmpty
            }
            .store(in: &cancellables)

        $functionalTests
            .sink { [weak self] tests in
                self?.sectionStatus.functionalTestsComplete = !tests.isEmpty
            }
            .store(in: &cancellables)
    }

    // MARK: - Form Actions

    /// Initialize form for a new assessment
    func initializeNewAssessment(patientId: UUID, therapistId: UUID) {
        self.patientId = patientId
        self.therapistId = therapistId
        self.assessmentDate = Date()
        resetForm()
    }

    /// Load existing assessment for editing
    func loadAssessment(_ assessment: ClinicalAssessment) {
        currentAssessment = assessment
        patientId = assessment.patientId
        therapistId = assessment.therapistId
        assessmentDate = assessment.assessmentDate

        // Populate form fields
        chiefComplaint = assessment.chiefComplaint ?? ""
        historyOfPresentIllness = assessment.historyOfPresentIllness ?? ""
        pastMedicalHistory = assessment.pastMedicalHistory ?? ""
        functionalGoals = assessment.functionalGoals ?? []

        painAtRest = assessment.painAtRest ?? 0
        painWithActivity = assessment.painWithActivity ?? 5
        painWorst = assessment.painWorst ?? 7
        painLocations = assessment.painLocations ?? []

        romMeasurements = assessment.romMeasurements ?? []
        functionalTests = assessment.functionalTests ?? []

        objectiveFindings = assessment.objectiveFindings ?? ""
        assessmentSummary = assessment.assessmentSummary ?? ""
        treatmentPlan = assessment.treatmentPlan ?? ""
    }

    /// Reset form to initial state
    func resetForm() {
        chiefComplaint = ""
        historyOfPresentIllness = ""
        pastMedicalHistory = ""
        functionalGoals = []
        newGoal = ""

        painAtRest = 0
        painWithActivity = 5
        painWorst = 7
        painLocations = []
        newPainLocation = ""

        romMeasurements = []
        functionalTests = []

        objectiveFindings = ""
        assessmentSummary = ""
        treatmentPlan = ""

        currentAssessment = nil
        errorMessage = nil
        successMessage = nil
        showValidationErrors = false
        sectionStatus = AssessmentSectionStatus()
    }

    // MARK: - Goal Management

    /// Add a new functional goal
    func addGoal() {
        let trimmed = newGoal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        functionalGoals.append(trimmed)
        newGoal = ""
    }

    /// Remove a functional goal at index
    func removeGoal(at index: Int) {
        guard functionalGoals.indices.contains(index) else { return }
        functionalGoals.remove(at: index)
    }

    // MARK: - Pain Location Management

    /// Add a new pain location
    func addPainLocation() {
        let trimmed = newPainLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        painLocations.append(trimmed)
        newPainLocation = ""
    }

    /// Remove a pain location at index
    func removePainLocation(at index: Int) {
        guard painLocations.indices.contains(index) else { return }
        painLocations.remove(at: index)
    }

    // MARK: - ROM Measurement Management

    /// Add a new ROM measurement
    func addROMMeasurement(
        joint: String,
        movement: String,
        degrees: Int,
        side: Side,
        painWithMovement: Bool = false,
        endFeel: String? = nil,
        notes: String? = nil
    ) {
        guard let normalRange = ROMNormalReference.normalRange(joint: joint, movement: movement) else {
            romError = "Unknown joint/movement combination"
            return
        }

        let measurement = ROMeasurement(
            joint: joint,
            movement: movement,
            degrees: degrees,
            normalRange: normalRange,
            side: side,
            painWithMovement: painWithMovement,
            endFeel: endFeel,
            notes: notes
        )

        romMeasurements.append(measurement)
        romError = nil
    }

    /// Update an existing ROM measurement
    func updateROMMeasurement(_ measurement: ROMeasurement) {
        guard let index = romMeasurements.firstIndex(where: { $0.id == measurement.id }) else { return }
        romMeasurements[index] = measurement
    }

    /// Remove a ROM measurement
    func removeROMMeasurement(_ measurement: ROMeasurement) {
        romMeasurements.removeAll { $0.id == measurement.id }
    }

    // MARK: - Functional Test Management

    /// Add a new functional test
    func addFunctionalTest(
        testName: String,
        result: String,
        score: Double? = nil,
        normalValue: String? = nil,
        interpretation: String? = nil,
        notes: String? = nil
    ) {
        let test = FunctionalTest(
            testName: testName,
            result: result,
            score: score,
            normalValue: normalValue,
            interpretation: interpretation,
            notes: notes
        )
        functionalTests.append(test)
    }

    /// Update an existing functional test
    func updateFunctionalTest(_ test: FunctionalTest) {
        guard let index = functionalTests.firstIndex(where: { $0.id == test.id }) else { return }
        functionalTests[index] = test
    }

    /// Remove a functional test
    func removeFunctionalTest(_ test: FunctionalTest) {
        functionalTests.removeAll { $0.id == test.id }
    }

    // MARK: - Save Operations

    /// Create new assessment as draft
    func createDraft() async {
        guard let patientId = patientId, let therapistId = therapistId else {
            errorMessage = "Patient and therapist IDs are required"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let assessment = try await assessmentService.createAssessment(
                patientId: patientId,
                therapistId: therapistId,
                assessmentType: .intake,
                assessmentDate: assessmentDate
            )

            currentAssessment = assessment
            successMessage = "Draft created successfully"

            // Now update with form data
            await saveDraft()
        } catch {
            errorMessage = "Failed to create assessment: \(error.localizedDescription)"
            DebugLogger.shared.error("IntakeAssessmentViewModel", "Create draft error: \(error)")
        }

        isSaving = false
    }

    /// Save current form state as draft
    func saveDraft() async {
        guard var assessment = currentAssessment else {
            await createDraft()
            return
        }

        guard assessment.status.isEditable else {
            errorMessage = "Cannot edit a signed assessment"
            return
        }

        isSaving = true
        errorMessage = nil

        // Update assessment with form values
        assessment.chiefComplaint = chiefComplaint.isEmpty ? nil : chiefComplaint
        assessment.historyOfPresentIllness = historyOfPresentIllness.isEmpty ? nil : historyOfPresentIllness
        assessment.pastMedicalHistory = pastMedicalHistory.isEmpty ? nil : pastMedicalHistory
        assessment.functionalGoals = functionalGoals.isEmpty ? nil : functionalGoals

        assessment.painAtRest = painAtRest
        assessment.painWithActivity = painWithActivity
        assessment.painWorst = painWorst
        assessment.painLocations = painLocations.isEmpty ? nil : painLocations

        assessment.romMeasurements = romMeasurements.isEmpty ? nil : romMeasurements
        assessment.functionalTests = functionalTests.isEmpty ? nil : functionalTests

        assessment.objectiveFindings = objectiveFindings.isEmpty ? nil : objectiveFindings
        assessment.assessmentSummary = assessmentSummary.isEmpty ? nil : assessmentSummary
        assessment.treatmentPlan = treatmentPlan.isEmpty ? nil : treatmentPlan

        do {
            let updated = try await assessmentService.updateAssessment(assessment)
            currentAssessment = updated
            lastAutoSaveDate = Date()
            successMessage = "Draft saved"

            #if DEBUG
            print("[IntakeAssessmentVM] Draft saved: \(updated.id)")
            #endif
        } catch {
            errorMessage = "Failed to save draft: \(error.localizedDescription)"
            DebugLogger.shared.error("IntakeAssessmentViewModel", "Save draft error: \(error)")
        }

        isSaving = false
    }

    /// Auto-save draft (silent, no UI updates for success)
    private func autoSaveDraft() async {
        guard currentAssessment != nil, !isSaving else { return }

        do {
            await saveDraft()
        } catch {
            // Silent failure for auto-save
            #if DEBUG
            print("[IntakeAssessmentVM] Auto-save failed: \(error)")
            #endif
        }
    }

    /// Submit assessment (mark as complete)
    func submitAssessment() async {
        guard let assessment = currentAssessment else {
            errorMessage = "No assessment to submit"
            return
        }

        // Validate required fields
        guard validateForSubmission() else {
            showValidationErrors = true
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            // First save the draft
            await saveDraft()

            // Then mark as complete
            let completed = try await assessmentService.completeAssessment(assessment.id)
            currentAssessment = completed
            successMessage = "Assessment submitted successfully"
        } catch {
            errorMessage = "Failed to submit assessment: \(error.localizedDescription)"
            DebugLogger.shared.error("IntakeAssessmentViewModel", "Submit error: \(error)")
        }

        isSaving = false
    }

    /// Sign the assessment (locks it from editing)
    func signAssessment() async {
        guard let assessment = currentAssessment else {
            errorMessage = "No assessment to sign"
            return
        }

        guard assessment.status == .complete else {
            errorMessage = "Assessment must be complete before signing"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let signed = try await assessmentService.signAssessment(assessment.id)
            currentAssessment = signed
            successMessage = "Assessment signed successfully"

            // Stop auto-save timer since assessment is now locked
            autoSaveTimer?.invalidate()
        } catch {
            errorMessage = "Failed to sign assessment: \(error.localizedDescription)"
            DebugLogger.shared.error("IntakeAssessmentViewModel", "Sign error: \(error)")
        }

        isSaving = false
    }

    // MARK: - Validation

    /// Validate form for submission
    private func validateForSubmission() -> Bool {
        var isValid = true

        // Clear previous errors
        subjectiveError = nil
        objectiveError = nil
        painError = nil
        romError = nil
        assessmentError = nil

        // Validate subjective section
        if chiefComplaint.isEmpty {
            subjectiveError = "Chief complaint is required"
            isValid = false
        }

        // Validate objective section
        if objectiveFindings.isEmpty {
            objectiveError = "Objective findings are required"
            isValid = false
        }

        // Validate pain scores
        if painAtRest < 0 || painAtRest > 10 ||
           painWithActivity < 0 || painWithActivity > 10 ||
           painWorst < 0 || painWorst > 10 {
            painError = "Pain scores must be between 0 and 10"
            isValid = false
        }

        // Validate assessment summary
        if assessmentSummary.isEmpty {
            assessmentError = "Assessment summary is required"
            isValid = false
        }

        // Validate treatment plan
        if treatmentPlan.isEmpty {
            assessmentError = "Treatment plan is required"
            isValid = false
        }

        return isValid
    }

    // MARK: - Helpers

    /// Clear any displayed messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    /// Get available movements for selected joint
    func getAvailableMovements() -> [MovementType] {
        return selectedJoint.availableMovements
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension IntakeAssessmentViewModel {
    static var preview: IntakeAssessmentViewModel {
        let viewModel = IntakeAssessmentViewModel()
        viewModel.patientId = UUID()
        viewModel.therapistId = UUID()
        viewModel.chiefComplaint = "Right shoulder pain with overhead activities"
        viewModel.painAtRest = 2
        viewModel.painWithActivity = 5
        viewModel.painWorst = 7
        viewModel.painLocations = ["Right shoulder", "Upper back"]
        viewModel.romMeasurements = [ROMeasurement.sample]
        viewModel.functionalTests = [FunctionalTest.sample]
        return viewModel
    }
}
#endif
