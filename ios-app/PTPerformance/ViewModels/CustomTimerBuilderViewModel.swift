//
//  CustomTimerBuilderViewModel.swift
//  PTPerformance
//
//  ViewModel for custom timer builder with form validation and template creation
//

import Foundation
import SwiftUI

/// ViewModel for custom timer builder
/// Handles form state, validation, and timer template creation
@MainActor
class CustomTimerBuilderViewModel: ObservableObject {
    // MARK: - Dependencies

    private let timerService: IntervalTimerService
    private let patientId: UUID

    // MARK: - Form State

    /// Timer template name (2-50 characters)
    @Published var templateName: String = "" {
        didSet { updateValidation() }
    }

    /// Timer type (Tabata, EMOM, AMRAP, Intervals, Custom)
    @Published var timerType: TimerType = .custom {
        didSet { applyTypeDefaults() }
    }

    /// Work duration in seconds (5-300)
    @Published var workSeconds: Int = 30 {
        didSet { updateValidation() }
    }

    /// Rest duration in seconds (0-300)
    @Published var restSeconds: Int = 30 {
        didSet { updateValidation() }
    }

    /// Number of rounds (1-50)
    @Published var rounds: Int = 5 {
        didSet { updateValidation() }
    }

    /// Number of cycles (1-10)
    @Published var cycles: Int = 1 {
        didSet { updateValidation() }
    }

    /// Rest between cycles in seconds (10-600)
    @Published var cycleRestSeconds: Int = 60 {
        didSet { updateValidation() }
    }

    /// Whether to save as reusable template
    @Published var saveAsTemplate: Bool = false

    /// Whether to make template public
    @Published var makePublic: Bool = false

    // MARK: - UI State

    /// Whether create operation is in progress
    @Published var isCreating: Bool = false

    /// Whether to show error alert
    @Published var showError: Bool = false

    /// Error message to display
    @Published var errorMessage: String = ""

    /// Whether to show validation error alert
    @Published var showValidationError: Bool = false

    /// Validation error message
    @Published var validationError: String = ""

    /// Whether form is valid for submission
    @Published private(set) var isValid: Bool = false

    // MARK: - Computed Properties

    /// Total duration for a single cycle (work + rest) x rounds
    var singleCycleDuration: Int {
        (workSeconds + restSeconds) * rounds
    }

    /// Total duration including all cycles and cycle rest
    var totalDuration: Int {
        if cycles == 1 {
            return singleCycleDuration
        } else {
            // Multi-cycle: (cycle + cycle rest) x cycles - final cycle rest
            return (singleCycleDuration + cycleRestSeconds) * cycles - cycleRestSeconds
        }
    }

    /// Formatted total time string (e.g., "5m 30s")
    var formattedTotalTime: String {
        let minutes = totalDuration / 60
        let seconds = totalDuration % 60

        if minutes > 0 {
            if seconds > 0 {
                return "\(minutes)m \(seconds)s"
            }
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }

    /// Whether to show cycle rest field
    var showCycleRest: Bool {
        cycles > 1 && timerType != .tabata
    }

    /// Validation message (nil if valid)
    var validationMessage: String? {
        let trimmedName = templateName.trimmingCharacters(in: .whitespaces)

        if trimmedName.isEmpty {
            return "Template name is required"
        }
        if trimmedName.count < 2 {
            return "Template name must be at least 2 characters"
        }
        if trimmedName.count > 50 {
            return "Template name must be 50 characters or less"
        }
        if workSeconds <= 0 {
            return "Work duration must be greater than 0"
        }
        if restSeconds < 0 {
            return "Rest duration cannot be negative"
        }
        if rounds < 1 {
            return "Rounds must be at least 1"
        }
        if rounds > 50 {
            return "Rounds cannot exceed 50"
        }
        if cycles < 1 {
            return "Cycles must be at least 1"
        }
        if cycles > 10 {
            return "Cycles cannot exceed 10"
        }
        if totalDuration > 7200 {
            return "Total duration cannot exceed 2 hours"
        }

        // Type-specific validation
        if timerType == .emom {
            // EMOM should have rest = 0 or work + rest = 60
            if restSeconds != 0 && (workSeconds + restSeconds) != 60 {
                return "EMOM intervals should equal 60 seconds (work + rest)"
            }
        }

        return nil
    }

    // MARK: - Initialization

    init(patientId: UUID, timerService: IntervalTimerService? = nil) {
        self.patientId = patientId
        self.timerService = timerService ?? .shared
        updateValidation()
    }

    // MARK: - Validation

    /// Update validation state based on current form values
    private func updateValidation() {
        isValid = validationMessage == nil
    }

    // MARK: - Timer Type Defaults

    /// Apply default values when timer type changes
    private func applyTypeDefaults() {
        switch timerType {
        case .tabata:
            workSeconds = 20
            restSeconds = 10
            rounds = 8
            cycles = 1

        case .emom:
            workSeconds = 40
            restSeconds = 20
            rounds = 10
            cycles = 1

        case .amrap:
            workSeconds = 30
            restSeconds = 30
            rounds = 10
            cycles = 1

        case .intervals:
            workSeconds = 40
            restSeconds = 20
            rounds = 8
            cycles = 1

        case .custom:
            // No defaults for custom - keep current values
            break
        }

        updateValidation()
    }

    // MARK: - Create Timer

    /// Create timer and start it
    /// - Returns: The created IntervalTemplate if successful, nil on failure
    func createAndStartTimer() async -> IntervalTemplate? {
        // Validate first
        if let error = validationMessage {
            validationError = error
            showValidationError = true
            return nil
        }

        guard isValid else {
            validationError = "Invalid timer configuration"
            showValidationError = true
            return nil
        }

        isCreating = true

        do {
            let template: IntervalTemplate

            if saveAsTemplate {
                // Save to database
                template = try await timerService.createTemplate(
                    name: templateName.trimmingCharacters(in: .whitespaces),
                    type: timerType,
                    workSeconds: workSeconds,
                    restSeconds: restSeconds,
                    rounds: rounds,
                    cycles: cycles,
                    isPublic: makePublic
                )

                #if DEBUG
                print("Template saved to database: \(template.id)")
                #endif
            } else {
                // Create temporary template (not saved to database)
                template = IntervalTemplate(
                    id: UUID(),
                    name: templateName.trimmingCharacters(in: .whitespaces),
                    type: timerType,
                    workSeconds: workSeconds,
                    restSeconds: restSeconds,
                    rounds: rounds,
                    cycles: cycles,
                    createdBy: nil,
                    isPublic: false,
                    createdAt: Date(),
                    updatedAt: Date()
                )

                #if DEBUG
                print("Temporary template created: \(template.id)")
                #endif
            }

            // Start timer with template
            try await timerService.startTimer(template: template, patientId: patientId)

            #if DEBUG
            print("Timer started with template: \(template.name)")
            #endif

            isCreating = false
            return template

        } catch {
            isCreating = false
            errorMessage = error.localizedDescription
            showError = true

            DebugLogger.shared.error("CUSTOM_TIMER", """
                Failed to create timer:
                Template name: \(templateName)
                Error: \(error.localizedDescription)
                Type: \(type(of: error))
                """)

            return nil
        }
    }

    // MARK: - Reset Form

    /// Reset form to default values
    func resetForm() {
        templateName = ""
        timerType = .custom
        workSeconds = 30
        restSeconds = 30
        rounds = 5
        cycles = 1
        cycleRestSeconds = 60
        saveAsTemplate = false
        makePublic = false
        isCreating = false
        showError = false
        errorMessage = ""
        showValidationError = false
        validationError = ""
        updateValidation()
    }

    // MARK: - Error Handling

    /// Dismiss error alert
    func dismissError() {
        showError = false
        errorMessage = ""
    }

    /// Dismiss validation error alert
    func dismissValidationError() {
        showValidationError = false
        validationError = ""
    }
}

// MARK: - Preview Support

extension CustomTimerBuilderViewModel {
    /// Preview instance with default state
    static var preview: CustomTimerBuilderViewModel {
        CustomTimerBuilderViewModel(patientId: UUID())
    }

    /// Preview instance with Tabata defaults
    static var previewTabata: CustomTimerBuilderViewModel {
        let vm = CustomTimerBuilderViewModel(patientId: UUID())
        vm.timerType = .tabata
        vm.templateName = "Classic Tabata"
        return vm
    }

    /// Preview instance with multi-cycle config
    static var previewMultiCycle: CustomTimerBuilderViewModel {
        let vm = CustomTimerBuilderViewModel(patientId: UUID())
        vm.templateName = "Multi-Cycle Workout"
        vm.cycles = 3
        vm.cycleRestSeconds = 120
        return vm
    }

    /// Preview instance with validation error
    static var previewInvalid: CustomTimerBuilderViewModel {
        let vm = CustomTimerBuilderViewModel(patientId: UUID())
        vm.templateName = "A" // Too short
        return vm
    }
}
