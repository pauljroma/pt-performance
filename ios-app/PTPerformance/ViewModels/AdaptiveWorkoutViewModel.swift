//
//  AdaptiveWorkoutViewModel.swift
//  PTPerformance
//
//  ViewModel for managing adaptive workout modifications
//  Handles fetching, displaying, and responding to modification suggestions
//

import Foundation
import SwiftUI

/// ViewModel for managing workout modifications in the UI
@MainActor
class AdaptiveWorkoutViewModel: ObservableObject {

    // MARK: - Dependencies

    private let adaptiveService: AdaptiveTrainingService
    private var patientId: UUID?

    // MARK: - Published State

    @Published var pendingModifications: [WorkoutModification] = []
    @Published var todayModification: WorkoutModification?
    @Published var isLoading: Bool = false
    @Published var isProcessing: Bool = false
    @Published var error: Error?
    @Published var showModificationSheet: Bool = false
    @Published var showSuccessToast: Bool = false
    @Published var successMessage: String = ""

    /// Whether there's a modification for today
    var hasTodayModification: Bool {
        todayModification != nil
    }

    // MARK: - Initialization

    init(adaptiveService: AdaptiveTrainingService) {
        self.adaptiveService = adaptiveService
    }

    /// Convenience initializer using shared AdaptiveTrainingService
    convenience init() {
        self.init(adaptiveService: AdaptiveTrainingService.shared)
    }

    // MARK: - Configuration

    /// Configure the view model with patient ID
    func configure(patientId: UUID) {
        self.patientId = patientId
    }

    // MARK: - Load Modifications

    /// Load all pending modifications for the patient
    func loadPendingModifications() async {
        guard let patientId = patientId else {
            DebugLogger.shared.warning("AdaptiveWorkoutVM", "No patient ID configured")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            pendingModifications = try await adaptiveService.fetchPendingModifications(for: patientId)
            todayModification = pendingModifications.first { modification in
                Calendar.current.isDateInToday(modification.scheduledDate) && modification.isActionable
            }
            DebugLogger.shared.info("AdaptiveWorkoutVM", "Loaded \(pendingModifications.count) pending modifications")
        } catch {
            self.error = error
            DebugLogger.shared.error("AdaptiveWorkoutVM", "Failed to load modifications: \(error.localizedDescription)")
        }
    }

    /// Check for modifications after readiness check-in
    func checkForModificationAfterReadiness() async {
        guard let patientId = patientId else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // Generate new modification based on today's readiness
            if let modification = try await adaptiveService.analyzeAndGenerateModification(for: patientId) {
                todayModification = modification
                showModificationSheet = true
                DebugLogger.shared.info("AdaptiveWorkoutVM", "Generated modification: \(modification.modificationType)")
            }
        } catch {
            self.error = error
            DebugLogger.shared.error("AdaptiveWorkoutVM", "Failed to generate modification: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle User Response

    /// Accept a workout modification
    func acceptModification(_ modification: WorkoutModification) async {
        guard patientId != nil else { return }

        isProcessing = true
        defer { isProcessing = false }

        do {
            _ = try await adaptiveService.acceptModification(modification.id)

            // Update local state
            todayModification = nil
            pendingModifications.removeAll { $0.id == modification.id }

            HapticService.shared.trigger(.success)
            successMessage = "Workout adjusted for today"
            showSuccessToast = true
            DebugLogger.shared.info("AdaptiveWorkoutVM", "Accepted modification: \(modification.id)")
        } catch {
            self.error = error
            HapticService.shared.trigger(.error)
            DebugLogger.shared.error("AdaptiveWorkoutVM", "Failed to accept modification: \(error.localizedDescription)")
        }
    }

    /// Decline a workout modification
    func declineModification(_ modification: WorkoutModification) async {
        guard patientId != nil else { return }

        isProcessing = true
        defer { isProcessing = false }

        do {
            _ = try await adaptiveService.declineModification(modification.id)

            // Update local state
            todayModification = nil
            pendingModifications.removeAll { $0.id == modification.id }

            HapticService.shared.trigger(.success)
            successMessage = "Keeping original workout"
            showSuccessToast = true
            DebugLogger.shared.info("AdaptiveWorkoutVM", "Declined modification: \(modification.id)")
        } catch {
            self.error = error
            HapticService.shared.trigger(.error)
            DebugLogger.shared.error("AdaptiveWorkoutVM", "Failed to decline modification: \(error.localizedDescription)")
        }
    }

    /// Provide feedback on a modification
    func provideFeedback(_ modification: WorkoutModification, feedback: String) async {
        guard patientId != nil else { return }

        do {
            // Use accept or decline based on current status
            if modification.status == .accepted {
                _ = try await adaptiveService.acceptModification(modification.id, feedback: feedback)
            } else {
                _ = try await adaptiveService.declineModification(modification.id, feedback: feedback)
            }
            HapticService.shared.trigger(.success)
            DebugLogger.shared.info("AdaptiveWorkoutVM", "Submitted feedback for: \(modification.id)")
        } catch {
            self.error = error
            HapticService.shared.trigger(.error)
            DebugLogger.shared.error("AdaptiveWorkoutVM", "Failed to submit feedback: \(error.localizedDescription)")
        }
    }
}
