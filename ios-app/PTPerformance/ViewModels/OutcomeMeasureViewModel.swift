//
//  OutcomeMeasureViewModel.swift
//  PTPerformance
//
//  ViewModel for managing patient-reported outcome measures including
//  LEFS, DASH, QuickDASH, and PSFS questionnaires with live score calculation
//  and MCID tracking.
//

import SwiftUI
import Combine

// MARK: - Question Item

/// Represents a single question in an outcome measure questionnaire
struct QuestionItem: Identifiable {
    let id: String
    let text: String
    let options: [QuestionOption]
    var selectedValue: Int?

    struct QuestionOption: Identifiable {
        let id = UUID()
        let value: Int
        let label: String
    }
}

// MARK: - OutcomeMeasureViewModel

/// ViewModel for outcome measure questionnaire management
/// Handles LEFS, DASH, QuickDASH, and PSFS with live scoring and MCID tracking
@MainActor
class OutcomeMeasureViewModel: ObservableObject {

    // MARK: - Published Properties - Form State

    @Published var patientId: UUID?
    @Published var therapistId: UUID?
    @Published var clinicalAssessmentId: UUID?
    @Published var assessmentDate: Date = Date()

    @Published var selectedMeasureType: OutcomeMeasureType = .LEFS
    @Published var responses: [String: Int] = [:]
    @Published var notes: String = ""

    // MARK: - Published Properties - Score Display

    @Published var rawScore: Double = 0
    @Published var normalizedScore: Double = 0
    @Published var interpretation: String = ""
    @Published var previousScore: Double?
    @Published var changeFromPrevious: Double?
    @Published var meetsMcid: Bool = false

    // MARK: - Published Properties - UI State

    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    @Published var questions: [QuestionItem] = []
    @Published var currentQuestionIndex: Int = 0
    @Published var previousMeasures: [OutcomeMeasure] = []

    // MARK: - Dependencies

    private let outcomeService: OutcomeMeasureService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    /// Whether all required questions are answered
    var isComplete: Bool {
        let answeredCount = responses.count
        let minimumRequired = minimumQuestionsRequired
        return answeredCount >= minimumRequired
    }

    /// Minimum number of questions required for this measure type
    var minimumQuestionsRequired: Int {
        switch selectedMeasureType {
        case .LEFS: return 18
        case .DASH: return 27
        case .QuickDASH: return 10
        case .PSFS: return 1
        default: return 1
        }
    }

    /// Total number of questions for this measure type
    var totalQuestions: Int {
        selectedMeasureType.questionCount
    }

    /// Progress percentage (0-100)
    var completionProgress: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(responses.count) / Double(totalQuestions) * 100
    }

    /// Whether form can be submitted
    var canSubmit: Bool {
        patientId != nil && therapistId != nil && isComplete && !isSaving
    }

    /// MCID threshold for current measure type
    var mcidThreshold: Double {
        outcomeService.getMcidThreshold(for: selectedMeasureType)
    }

    /// Score color based on severity
    var scoreColor: Color {
        let severity = calculateSeverityLevel()
        return severity.color
    }

    /// Progress status based on change from previous
    var progressStatus: ProgressStatus {
        guard let change = changeFromPrevious else { return .stable }

        if selectedMeasureType.higherIsBetter {
            if change >= mcidThreshold { return .improving }
            else if change <= -mcidThreshold { return .declining }
        } else {
            if change <= -mcidThreshold { return .improving }
            else if change >= mcidThreshold { return .declining }
        }
        return .stable
    }

    /// Formatted score for display
    var formattedScore: String {
        String(format: "%.1f", normalizedScore)
    }

    /// Formatted change from previous
    var formattedChange: String? {
        guard let change = changeFromPrevious else { return nil }
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", change))"
    }

    // MARK: - Initialization

    @MainActor
    init(outcomeService: OutcomeMeasureService = .shared) {
        self.outcomeService = outcomeService
        setupObservers()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Recalculate score when responses change
        $responses
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.calculateLiveScore()
            }
            .store(in: &cancellables)

        // Load questions when measure type changes
        $selectedMeasureType
            .sink { [weak self] measureType in
                self?.loadQuestionsForMeasureType(measureType)
                self?.responses = [:]
                self?.calculateLiveScore()
            }
            .store(in: &cancellables)
    }

    // MARK: - Form Actions

    /// Initialize for a new outcome measure
    func initialize(
        patientId: UUID,
        therapistId: UUID,
        measureType: OutcomeMeasureType = .LEFS,
        clinicalAssessmentId: UUID? = nil
    ) {
        self.patientId = patientId
        self.therapistId = therapistId
        self.clinicalAssessmentId = clinicalAssessmentId
        self.selectedMeasureType = measureType
        self.assessmentDate = Date()

        resetForm()

        // Fetch previous measure for comparison
        Task {
            await fetchPreviousMeasure()
        }
    }

    /// Reset form to initial state
    func resetForm() {
        responses = [:]
        notes = ""
        rawScore = 0
        normalizedScore = 0
        interpretation = ""
        changeFromPrevious = nil
        meetsMcid = false
        currentQuestionIndex = 0
        errorMessage = nil
        successMessage = nil
    }

    /// Record an answer for a question
    func recordAnswer(questionId: String, value: Int) {
        responses[questionId] = value

        // Update question item
        if let index = questions.firstIndex(where: { $0.id == questionId }) {
            questions[index].selectedValue = value
        }
    }

    /// Move to next question
    func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
        }
    }

    /// Move to previous question
    func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }

    /// Jump to a specific question
    func goToQuestion(_ index: Int) {
        guard index >= 0 && index < questions.count else { return }
        currentQuestionIndex = index
    }

    // MARK: - Score Calculation

    /// Calculate live score based on current responses
    func calculateLiveScore() {
        guard !responses.isEmpty else {
            rawScore = 0
            normalizedScore = 0
            interpretation = "Answer questions to see your score"
            return
        }

        rawScore = outcomeService.calculateRawScore(responses: responses, measureType: selectedMeasureType)
        normalizedScore = outcomeService.calculateNormalizedScore(rawScore: rawScore, measureType: selectedMeasureType)
        interpretation = outcomeService.generateInterpretation(normalizedScore: normalizedScore, measureType: selectedMeasureType)

        // Calculate change from previous if available
        if let previous = previousScore {
            changeFromPrevious = normalizedScore - previous
            meetsMcid = outcomeService.calculateMcidAchievement(change: changeFromPrevious, measureType: selectedMeasureType)
        }
    }

    /// Calculate severity level from current score
    private func calculateSeverityLevel() -> SeverityLevel {
        let maxScore = Double(selectedMeasureType.maxScore)
        let percentage = selectedMeasureType.higherIsBetter ?
            (normalizedScore / maxScore) * 100 :
            ((maxScore - normalizedScore) / maxScore) * 100

        switch percentage {
        case 80...100: return .minimal
        case 60..<80: return .mild
        case 40..<60: return .moderate
        case 20..<40: return .severe
        default: return .complete
        }
    }

    // MARK: - Data Operations

    /// Fetch previous measure for comparison
    func fetchPreviousMeasure() async {
        guard let patientId = patientId else { return }

        do {
            if let previous = try await outcomeService.fetchLatestMeasure(
                patientId: patientId,
                measureType: selectedMeasureType
            ) {
                previousScore = previous.normalizedScore ?? previous.rawScore
            } else {
                previousScore = nil
            }
        } catch {
            #if DEBUG
            print("[OutcomeMeasureVM] Failed to fetch previous measure: \(error)")
            #endif
        }
    }

    /// Fetch all previous measures for this patient and type
    func fetchMeasureHistory() async {
        guard let patientId = patientId else { return }

        isLoading = true
        errorMessage = nil

        do {
            previousMeasures = try await outcomeService.fetchOutcomeMeasures(
                patientId: patientId,
                measureType: selectedMeasureType,
                limit: 10
            )
        } catch {
            errorMessage = "Failed to load history: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Submit the outcome measure
    func submitMeasure() async {
        guard let patientId = patientId,
              let therapistId = therapistId else {
            errorMessage = "Patient and therapist IDs are required"
            return
        }

        guard isComplete else {
            errorMessage = "Please answer all required questions"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let measure = try await outcomeService.submitOutcomeMeasure(
                patientId: patientId,
                therapistId: therapistId,
                measureType: selectedMeasureType,
                responses: responses,
                clinicalAssessmentId: clinicalAssessmentId,
                notes: notes.isEmpty ? nil : notes
            )

            successMessage = "Outcome measure submitted successfully"

            #if DEBUG
            print("[OutcomeMeasureVM] Submitted measure: \(measure.id), Score: \(measure.normalizedScore ?? 0)")
            #endif
        } catch {
            errorMessage = "Failed to submit: \(error.localizedDescription)"
            DebugLogger.shared.error("OutcomeMeasureViewModel", "Submit error: \(error)")
        }

        isSaving = false
    }

    // MARK: - Question Loading

    /// Load questions for the selected measure type
    private func loadQuestionsForMeasureType(_ measureType: OutcomeMeasureType) {
        switch measureType {
        case .LEFS:
            questions = generateLEFSQuestions()
        case .DASH:
            questions = generateDASHQuestions()
        case .QuickDASH:
            questions = generateQuickDASHQuestions()
        case .PSFS:
            questions = generatePSFSQuestions()
        default:
            questions = []
        }

        currentQuestionIndex = 0
    }

    /// Generate LEFS questions (20 items)
    private func generateLEFSQuestions() -> [QuestionItem] {
        let activities = [
            "Any of your usual work, housework, or school activities",
            "Your usual hobbies, recreational, or sporting activities",
            "Getting into or out of the bath",
            "Walking between rooms",
            "Putting on your shoes or socks",
            "Squatting",
            "Lifting an object, like a bag of groceries from the floor",
            "Performing light activities around your home",
            "Performing heavy activities around your home",
            "Getting into or out of a car",
            "Walking 2 blocks",
            "Walking a mile",
            "Going up or down 10 stairs (about 1 flight of stairs)",
            "Standing for 1 hour",
            "Sitting for 1 hour",
            "Running on even ground",
            "Running on uneven ground",
            "Making sharp turns while running fast",
            "Hopping",
            "Rolling over in bed"
        ]

        let options = [
            QuestionItem.QuestionOption(value: 0, label: "Extreme Difficulty/Unable"),
            QuestionItem.QuestionOption(value: 1, label: "Quite a Bit of Difficulty"),
            QuestionItem.QuestionOption(value: 2, label: "Moderate Difficulty"),
            QuestionItem.QuestionOption(value: 3, label: "A Little Bit of Difficulty"),
            QuestionItem.QuestionOption(value: 4, label: "No Difficulty")
        ]

        return activities.enumerated().map { index, activity in
            QuestionItem(
                id: "q\(index + 1)",
                text: "How difficult is it for you to: \(activity)?",
                options: options,
                selectedValue: responses["q\(index + 1)"]
            )
        }
    }

    /// Generate DASH questions (30 items - simplified for demo)
    private func generateDASHQuestions() -> [QuestionItem] {
        let activities = [
            "Open a tight or new jar",
            "Write",
            "Turn a key",
            "Prepare a meal",
            "Push open a heavy door",
            "Place an object on a shelf above your head",
            "Do heavy household chores",
            "Garden or do yard work",
            "Make a bed",
            "Carry a shopping bag or briefcase",
            "Carry a heavy object (over 10 lbs)",
            "Change a lightbulb overhead",
            "Wash or blow dry your hair",
            "Wash your back",
            "Put on a pullover sweater",
            "Use a knife to cut food",
            "Recreational activities requiring little effort",
            "Recreational activities requiring arm force",
            "Recreational activities moving arm freely",
            "Manage transportation needs",
            "Sexual activities",
            "Social activities",
            "Work activities",
            "Achieve usual level of work",
            "Arm, shoulder or hand pain",
            "Pain during activity",
            "Tingling",
            "Weakness",
            "Stiffness",
            "Difficulty sleeping due to pain"
        ]

        let options = [
            QuestionItem.QuestionOption(value: 1, label: "No Difficulty"),
            QuestionItem.QuestionOption(value: 2, label: "Mild Difficulty"),
            QuestionItem.QuestionOption(value: 3, label: "Moderate Difficulty"),
            QuestionItem.QuestionOption(value: 4, label: "Severe Difficulty"),
            QuestionItem.QuestionOption(value: 5, label: "Unable")
        ]

        return activities.enumerated().map { index, activity in
            QuestionItem(
                id: "q\(index + 1)",
                text: activity,
                options: options,
                selectedValue: responses["q\(index + 1)"]
            )
        }
    }

    /// Generate QuickDASH questions (11 items)
    private func generateQuickDASHQuestions() -> [QuestionItem] {
        let activities = [
            "Open a tight or new jar",
            "Do heavy household chores",
            "Carry a shopping bag or briefcase",
            "Wash your back",
            "Use a knife to cut food",
            "Recreational activities requiring arm force",
            "Social activities interference",
            "Work or daily activities limitation",
            "Arm, shoulder or hand pain",
            "Tingling (pins and needles)",
            "Difficulty sleeping due to pain"
        ]

        let options = [
            QuestionItem.QuestionOption(value: 1, label: "No Difficulty"),
            QuestionItem.QuestionOption(value: 2, label: "Mild Difficulty"),
            QuestionItem.QuestionOption(value: 3, label: "Moderate Difficulty"),
            QuestionItem.QuestionOption(value: 4, label: "Severe Difficulty"),
            QuestionItem.QuestionOption(value: 5, label: "Unable")
        ]

        return activities.enumerated().map { index, activity in
            QuestionItem(
                id: "q\(index + 1)",
                text: activity,
                options: options,
                selectedValue: responses["q\(index + 1)"]
            )
        }
    }

    /// Generate PSFS questions (patient-specific activities)
    private func generatePSFSQuestions() -> [QuestionItem] {
        let options = (0...10).map { value in
            QuestionItem.QuestionOption(
                value: value,
                label: value == 0 ? "Unable" : value == 10 ? "Able without difficulty" : "\(value)"
            )
        }

        return [
            QuestionItem(
                id: "activity1",
                text: "Activity 1: Rate your ability to perform this activity",
                options: options,
                selectedValue: responses["activity1"]
            ),
            QuestionItem(
                id: "activity2",
                text: "Activity 2: Rate your ability to perform this activity",
                options: options,
                selectedValue: responses["activity2"]
            ),
            QuestionItem(
                id: "activity3",
                text: "Activity 3: Rate your ability to perform this activity",
                options: options,
                selectedValue: responses["activity3"]
            )
        ]
    }

    // MARK: - Helpers

    /// Get available measure types for a body region
    func getAvailableMeasures(for bodyRegion: String) -> [OutcomeMeasureType] {
        return outcomeService.getAvailableMeasures(for: bodyRegion)
    }

    /// Clear messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension OutcomeMeasureViewModel {
    static var preview: OutcomeMeasureViewModel {
        let viewModel = OutcomeMeasureViewModel()
        viewModel.patientId = UUID()
        viewModel.therapistId = UUID()
        viewModel.selectedMeasureType = .LEFS
        viewModel.rawScore = 68
        viewModel.normalizedScore = 85
        viewModel.interpretation = "Good lower extremity function with mild limitations"
        viewModel.previousScore = 54
        viewModel.changeFromPrevious = 14
        viewModel.meetsMcid = true
        return viewModel
    }
}
#endif
