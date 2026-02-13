//
//  ProtocolBuilderViewModel.swift
//  PTPerformance
//
//  ViewModel for Protocol Builder - manages template selection,
//  customization state, validation, and tracks assignment time for KPI
//

import Foundation
import Combine

/// ViewModel for the Protocol Builder workflow
/// Tracks time to ensure <60s assignment target per M7 requirements
@MainActor
class ProtocolBuilderViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Available protocol templates
    @Published var templates: [ProtocolTemplate] = []

    /// Currently selected template
    @Published var selectedTemplate: ProtocolTemplate?

    /// Customization settings for the selected template
    @Published var customization: PlanCustomization = PlanCustomization(template: .postWorkoutRecovery)

    /// Loading state
    @Published var isLoading = false

    /// Assignment in progress
    @Published var isAssigning = false

    /// Show success alert
    @Published var showingSuccess = false

    /// Show error alert
    @Published var showingError = false

    /// Error message
    @Published var errorMessage: String?

    /// Assignment error (for detailed error handling)
    @Published var assignmentError: Error?

    /// The assigned plan after successful assignment
    @Published var assignedPlan: AthletePlan?

    /// Elapsed seconds since view appeared (for <60s KPI tracking)
    @Published var elapsedSeconds: Int = 0

    // MARK: - Private Properties

    private let athleteId: UUID
    private let protocolService = ProtocolService.shared
    private var timerCancellable: AnyCancellable?
    private var startTime: Date?
    private var assignmentDuration: TimeInterval = 0

    // MARK: - Initialization

    init(athleteId: UUID) {
        self.athleteId = athleteId
        startTimer()
    }

    deinit {
        timerCancellable?.cancel()
    }

    // MARK: - Timer Methods

    private func startTimer() {
        startTime = Date()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateElapsedTime()
            }
    }

    private func updateElapsedTime() {
        guard let startTime = startTime else { return }
        elapsedSeconds = Int(Date().timeIntervalSince(startTime))
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        if let startTime = startTime {
            assignmentDuration = Date().timeIntervalSince(startTime)
        }
    }

    var formattedElapsedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedAssignmentTime: String {
        let seconds = Int(assignmentDuration)
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return "\(minutes)m \(remainingSeconds)s"
        }
    }

    /// Whether the assignment was completed within the 60s target
    var metTimeTarget: Bool {
        assignmentDuration < 60
    }

    // MARK: - Template Methods

    /// Load available templates from service
    func loadTemplates() async {
        isLoading = true
        defer { isLoading = false }

        do {
            templates = try await protocolService.getTemplates()
        } catch {
            // Fallback to sample templates
            templates = ProtocolTemplate.sampleTemplates
        }
    }

    /// Load templates filtered by category
    func loadTemplates(category: ProtocolTemplate.ProtocolCategory) async {
        isLoading = true
        defer { isLoading = false }

        do {
            templates = try await protocolService.getTemplates(category: category)
        } catch {
            templates = ProtocolTemplate.sampleTemplates.filter { $0.category == category }
        }
    }

    /// Select a template and initialize customization
    func selectTemplate(_ template: ProtocolTemplate) {
        selectedTemplate = template
        customization = PlanCustomization(template: template)
    }

    /// Clear template selection
    func clearSelection() {
        selectedTemplate = nil
    }

    // MARK: - Validation

    /// Validates the current customization before assignment
    var isValid: Bool {
        guard selectedTemplate != nil else { return false }
        guard customization.includedTaskCount > 0 else { return false }
        guard customization.endDate > customization.startDate else { return false }
        return true
    }

    /// Validation errors if any
    var validationErrors: [String] {
        var errors: [String] = []

        if selectedTemplate == nil {
            errors.append("Please select a protocol template")
        }

        if customization.includedTaskCount == 0 {
            errors.append("At least one task must be included")
        }

        if customization.endDate <= customization.startDate {
            errors.append("End date must be after start date")
        }

        return errors
    }

    // MARK: - Plan Creation

    /// Assigns the selected protocol to the athlete
    func assignProtocol() async {
        guard let template = selectedTemplate else {
            DebugLogger.shared.log("[Protocol] No template selected", level: .warning)
            return
        }

        guard isValid else {
            errorMessage = validationErrors.first
            showingError = true
            HapticService.error()
            return
        }

        isAssigning = true
        assignmentError = nil

        let assignmentStartTime = Date()

        do {
            let plan = try await protocolService.createPlan(
                athleteId: athleteId,
                template: template,
                customizations: customization
            )

            stopTimer()

            // Track assignment time for KPI
            let assignmentTime = Date().timeIntervalSince(assignmentStartTime)
            DebugLogger.shared.log("[Protocol] Assigned in \(String(format: "%.1f", assignmentTime))s (target: <60s)", level: .success)

            assignedPlan = plan
            showingSuccess = true
            HapticService.success()

            // Track KPI
            await trackAssignmentKPI(
                athleteId: athleteId,
                templateId: template.id,
                duration: assignmentDuration
            )

        } catch {
            assignmentError = error
            errorMessage = error.localizedDescription
            showingError = true
            DebugLogger.shared.log("[Protocol] Assignment failed: \(error.localizedDescription)", level: .error)
            HapticService.error()
        }

        isAssigning = false
    }

    /// Create and assign the plan to the athlete (legacy method for backwards compatibility)
    func createPlan(
        athleteId: UUID,
        template: ProtocolTemplate,
        customizations: PlanCustomization
    ) async {
        guard isValid else {
            errorMessage = validationErrors.first
            showingError = true
            HapticService.error()
            return
        }

        isAssigning = true
        assignmentError = nil

        let assignmentStartTime = Date()

        do {
            let plan = try await protocolService.createPlan(
                athleteId: athleteId,
                template: template,
                customizations: customizations
            )

            stopTimer()

            // Track assignment time for KPI
            let assignmentTime = Date().timeIntervalSince(assignmentStartTime)
            DebugLogger.shared.log("[Protocol] Assigned in \(String(format: "%.1f", assignmentTime))s (target: <60s)", level: .success)

            assignedPlan = plan
            showingSuccess = true
            HapticService.success()

            // Track KPI
            await trackAssignmentKPI(
                athleteId: athleteId,
                templateId: template.id,
                duration: assignmentDuration
            )

        } catch {
            assignmentError = error
            errorMessage = error.localizedDescription
            showingError = true
            DebugLogger.shared.log("[Protocol] Assignment failed: \(error.localizedDescription)", level: .error)
            HapticService.error()
        }

        isAssigning = false
    }

    // MARK: - KPI Tracking

    private func trackAssignmentKPI(
        athleteId: UUID,
        templateId: UUID,
        duration: TimeInterval
    ) async {
        // In a real implementation, this would send to analytics
        let kpiData = AssignmentKPI(
            athleteId: athleteId,
            templateId: templateId,
            assignedBy: UUID(), // Would be current user ID
            durationSeconds: duration,
            metTarget: duration < 60,
            taskCount: customization.includedTaskCount,
            timestamp: Date()
        )

        // Log for debugging
        DebugLogger.shared.log("[ProtocolBuilder] Assignment KPI: Duration=\(formattedAssignmentTime), Met<60s=\(kpiData.metTarget), Tasks=\(customization.includedTaskCount)", level: .diagnostic)

        // TODO: Send to analytics service
    }
}

// MARK: - Assignment KPI Model

struct AssignmentKPI: Codable {
    let athleteId: UUID
    let templateId: UUID
    let assignedBy: UUID
    let durationSeconds: TimeInterval
    let metTarget: Bool
    let taskCount: Int
    let timestamp: Date
}

// MARK: - Quick Assignment Helpers

extension ProtocolBuilderViewModel {
    /// Quick assign with default settings
    func quickAssign() async {
        guard let template = selectedTemplate else { return }

        await createPlan(
            athleteId: athleteId,
            template: template,
            customizations: customization
        )
    }

    /// Get suggested templates based on athlete context
    func getSuggestedTemplates(for athleteContext: AthleteContext) -> [ProtocolTemplate] {
        // In a real implementation, this would use ML or rules to suggest
        // For now, return templates based on context category
        switch athleteContext {
        case .postWorkout:
            return templates.filter { $0.category == .recovery }
        case .returningFromInjury:
            return templates.filter { $0.category == .returnToPlay || $0.category == .injury }
        case .peakPerformance:
            return templates.filter { $0.category == .performance }
        case .maintenance:
            return templates.filter { $0.category == .maintenance }
        case .general:
            return templates
        }
    }
}

// MARK: - Athlete Context

enum AthleteContext {
    case postWorkout
    case returningFromInjury
    case peakPerformance
    case maintenance
    case general
}
