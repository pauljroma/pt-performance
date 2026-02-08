//
//  DailyCheckInViewModel.swift
//  PTPerformance
//
//  X2Index M8: Daily Check-In ViewModel
//  @MainActor class managing the check-in flow with step-by-step state machine
//

import SwiftUI
import Combine

// MARK: - Check-In State

/// State of the check-in flow
enum CheckInFlowState: Equatable {
    case notStarted
    case inProgress(step: CheckInStep)
    case reviewing
    case submitting
    case completed
    case error(String)
}

// MARK: - Daily Check-In ViewModel

/// ViewModel managing the athlete daily check-in flow
///
/// Features:
/// - Step-by-step state machine navigation
/// - Real-time readiness preview calculation
/// - Completion time tracking for KPI (target: <=60s)
/// - Validation at each step
/// - Streak tracking integration
@MainActor
class DailyCheckInViewModel: ObservableObject {

    // MARK: - Published Properties

    // Flow state
    @Published var flowState: CheckInFlowState = .notStarted
    @Published var currentStep: CheckInStep = .sleep

    // Form inputs
    @Published var sleepQuality: Int = 3
    @Published var sleepHours: Double = 7.0
    @Published var includeSleepHours: Bool = false

    @Published var soreness: Int = 1
    @Published var sorenessLocations: Set<BodyLocation> = []

    @Published var energy: Int = 5
    @Published var stress: Int = 1
    @Published var mood: Int = 3

    @Published var painScore: Int = 0
    @Published var hasPain: Bool = false
    @Published var painLocations: Set<BodyLocation> = []

    @Published var freeText: String = ""

    // UI State
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var showSuccess: Bool = false

    // Results
    @Published var hasCheckedInToday: Bool = false
    @Published var estimatedReadiness: Double = 50.0
    @Published var streak: CheckInStreak?
    @Published var savedCheckIn: DailyCheckIn?

    // Completion tracking
    @Published var completionTimeSeconds: Double = 0.0
    private var startTime: Date?

    // MARK: - Dependencies

    private let checkInService: CheckInService
    private let hapticService = HapticService.shared

    // MARK: - Computed Properties

    /// Current step index (0-based)
    var currentStepIndex: Int {
        currentStep.rawValue
    }

    /// Total number of steps
    var totalSteps: Int {
        CheckInStep.allCases.count
    }

    /// Progress percentage (0.0 to 1.0)
    var progress: Double {
        Double(currentStepIndex) / Double(totalSteps - 1)
    }

    /// Whether current step is first
    var isFirstStep: Bool {
        currentStep == .sleep
    }

    /// Whether current step is last
    var isLastStep: Bool {
        currentStep == .notes
    }

    /// Whether can proceed to next step
    var canProceed: Bool {
        switch currentStep {
        case .sleep:
            return (1...5).contains(sleepQuality)
        case .soreness:
            return (1...10).contains(soreness)
        case .energy:
            return (1...10).contains(energy)
        case .stress:
            return (1...10).contains(stress)
        case .pain:
            return true // Optional step
        case .notes:
            return true // Optional step
        }
    }

    /// Whether form is complete and ready for submission
    var canSubmit: Bool {
        (1...5).contains(sleepQuality) &&
        (1...10).contains(soreness) &&
        (1...10).contains(energy) &&
        (1...10).contains(stress) &&
        (1...5).contains(mood)
    }

    /// Readiness band based on current inputs
    var readinessBand: ReadinessBand {
        if estimatedReadiness >= 80 {
            return .green
        } else if estimatedReadiness >= 60 {
            return .yellow
        } else if estimatedReadiness >= 40 {
            return .orange
        } else {
            return .red
        }
    }

    /// Readiness description
    var readinessDescription: String {
        switch readinessBand {
        case .green: return "Ready to Train"
        case .yellow: return "Train with Caution"
        case .orange: return "Reduced Intensity"
        case .red: return "Recovery Day"
        }
    }

    // MARK: - Initialization

    init(checkInService: CheckInService = .shared) {
        self.checkInService = checkInService
    }

    // MARK: - Flow Control

    /// Start the check-in flow
    func startCheckIn() {
        flowState = .inProgress(step: .sleep)
        currentStep = .sleep
        startTime = Date()
        hapticService.trigger(.light)
        updateEstimatedReadiness()
    }

    /// Move to next step
    func nextStep() {
        guard canProceed else { return }

        hapticService.trigger(.selection)

        if let next = currentStep.next {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = next
                flowState = .inProgress(step: next)
            }
        } else {
            // Last step - go to review
            withAnimation(.easeInOut(duration: 0.3)) {
                flowState = .reviewing
            }
        }

        updateEstimatedReadiness()
    }

    /// Move to previous step
    func previousStep() {
        hapticService.trigger(.selection)

        if let prev = currentStep.previous {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = prev
                flowState = .inProgress(step: prev)
            }
        }
    }

    /// Skip current optional step
    func skipStep() {
        guard currentStep.isOptional else { return }
        nextStep()
    }

    /// Jump to specific step
    func goToStep(_ step: CheckInStep) {
        hapticService.trigger(.light)
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = step
            flowState = .inProgress(step: step)
        }
    }

    // MARK: - Form Updates

    /// Update sleep quality with haptic feedback
    func updateSleepQuality(_ value: Int) {
        let clamped = max(1, min(5, value))
        if clamped != sleepQuality {
            sleepQuality = clamped
            hapticService.trigger(.selection)
            updateEstimatedReadiness()
        }
    }

    /// Update soreness level with haptic feedback
    func updateSoreness(_ value: Int) {
        let clamped = max(1, min(10, value))
        if clamped != soreness {
            soreness = clamped
            hapticService.trigger(.selection)
            updateEstimatedReadiness()
        }
    }

    /// Update energy level with haptic feedback
    func updateEnergy(_ value: Int) {
        let clamped = max(1, min(10, value))
        if clamped != energy {
            energy = clamped
            hapticService.trigger(.selection)
            updateEstimatedReadiness()
        }
    }

    /// Update stress level with haptic feedback
    func updateStress(_ value: Int) {
        let clamped = max(1, min(10, value))
        if clamped != stress {
            stress = clamped
            hapticService.trigger(.selection)
            updateEstimatedReadiness()
        }
    }

    /// Update mood with haptic feedback
    func updateMood(_ value: Int) {
        let clamped = max(1, min(5, value))
        if clamped != mood {
            mood = clamped
            hapticService.trigger(.selection)
            updateEstimatedReadiness()
        }
    }

    /// Update pain score with haptic feedback
    func updatePainScore(_ value: Int) {
        let clamped = max(0, min(10, value))
        if clamped != painScore {
            painScore = clamped
            hasPain = clamped > 0
            hapticService.trigger(.selection)
            updateEstimatedReadiness()
        }
    }

    /// Toggle soreness location
    func toggleSorenessLocation(_ location: BodyLocation) {
        hapticService.trigger(.light)
        if sorenessLocations.contains(location) {
            sorenessLocations.remove(location)
        } else {
            sorenessLocations.insert(location)
        }
    }

    /// Toggle pain location
    func togglePainLocation(_ location: BodyLocation) {
        hapticService.trigger(.light)
        if painLocations.contains(location) {
            painLocations.remove(location)
        } else {
            painLocations.insert(location)
        }
    }

    // MARK: - Readiness Calculation

    /// Update estimated readiness based on current inputs
    private func updateEstimatedReadiness() {
        // Weighted formula matching DailyCheckIn model
        let sleepComponent = Double(sleepQuality) / 5.0 * 30.0
        let energyComponent = Double(energy) / 10.0 * 25.0
        let sorenessComponent = Double(11 - soreness) / 10.0 * 20.0
        let stressComponent = Double(11 - stress) / 10.0 * 15.0
        let moodComponent = Double(mood) / 5.0 * 10.0

        var score = sleepComponent + energyComponent + sorenessComponent + stressComponent + moodComponent

        // Pain penalty
        if hasPain && painScore > 0 {
            score -= Double(painScore) * 2
        }

        estimatedReadiness = max(0, min(100, score))
    }

    // MARK: - Submission

    /// Submit the check-in
    func submit() async {
        guard canSubmit else {
            errorMessage = "Please complete all required fields"
            showError = true
            return
        }

        isLoading = true
        flowState = .submitting

        // Calculate completion time
        if let start = startTime {
            completionTimeSeconds = Date().timeIntervalSince(start)
        }

        // Build input
        var input = DailyCheckInInput()
        input.sleepQuality = sleepQuality
        input.sleepHours = includeSleepHours ? sleepHours : nil
        input.soreness = soreness
        input.sorenessLocations = sorenessLocations.isEmpty ? nil : sorenessLocations.map { $0.rawValue }
        input.stress = stress
        input.energy = energy
        input.painScore = hasPain ? painScore : nil
        input.painLocations = painLocations.isEmpty ? nil : painLocations.map { $0.rawValue }
        input.mood = mood
        input.freeText = freeText.isEmpty ? nil : freeText

        do {
            let checkIn = try await checkInService.submitCheckIn(input)
            savedCheckIn = checkIn

            // Get updated streak
            streak = await checkInService.getStreak()

            isLoading = false
            flowState = .completed
            showSuccess = true

            // Success haptic
            hapticService.trigger(.success)

            // Log KPI metric
            DebugLogger.shared.log("[CheckIn] Completed in \(String(format: "%.1f", completionTimeSeconds))s", level: .success)

        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            flowState = .error(error.localizedDescription)
            showError = true

            // Error haptic
            hapticService.trigger(.error)

            ErrorLogger.shared.logError(error, context: "DailyCheckInViewModel.submit")
        }
    }

    // MARK: - Data Loading

    /// Check if already checked in today
    func checkTodayStatus() async {
        hasCheckedInToday = await checkInService.hasCheckedInToday()

        if hasCheckedInToday {
            // Load existing check-in
            if let existing = await checkInService.getTodayCheckIn() {
                loadFromExisting(existing)
            }
        }

        // Load streak
        streak = await checkInService.getStreak()
    }

    /// Load form values from existing check-in
    private func loadFromExisting(_ checkIn: DailyCheckIn) {
        sleepQuality = checkIn.sleepQuality
        if let hours = checkIn.sleepHours {
            sleepHours = hours
            includeSleepHours = true
        }
        soreness = checkIn.soreness
        if let locations = checkIn.sorenessLocations {
            sorenessLocations = Set(locations.compactMap { BodyLocation(rawValue: $0) })
        }
        stress = checkIn.stress
        energy = checkIn.energy
        mood = checkIn.mood
        if let pain = checkIn.painScore {
            painScore = pain
            hasPain = pain > 0
        }
        if let locations = checkIn.painLocations {
            painLocations = Set(locations.compactMap { BodyLocation(rawValue: $0) })
        }
        if let text = checkIn.freeText {
            freeText = text
        }

        updateEstimatedReadiness()
    }

    // MARK: - Reset

    /// Reset the form to defaults
    func reset() {
        flowState = .notStarted
        currentStep = .sleep

        sleepQuality = 3
        sleepHours = 7.0
        includeSleepHours = false

        soreness = 1
        sorenessLocations = []

        energy = 5
        stress = 1
        mood = 3

        painScore = 0
        hasPain = false
        painLocations = []

        freeText = ""

        showError = false
        showSuccess = false
        errorMessage = ""
        savedCheckIn = nil
        startTime = nil
        completionTimeSeconds = 0

        updateEstimatedReadiness()
    }
}
