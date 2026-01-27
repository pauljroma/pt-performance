import Foundation
import SwiftUI

/// ViewModel for Daily Readiness Check-in UI
/// Manages state and live preview of readiness band calculation
@MainActor
class DailyReadinessViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var readinessPreview: ReadinessPreview?

    private let readinessService: ReadinessService

    init(readinessService: ReadinessService = ReadinessService()) {
        self.readinessService = readinessService
    }

    /// Update live preview of readiness band based on current inputs
    /// - Parameters:
    ///   - sleepHours: Hours of sleep
    ///   - sleepQuality: Sleep quality rating (1-5)
    ///   - subjectiveReadiness: Subjective readiness rating (1-5)
    ///   - armSoreness: Whether arm soreness is present
    ///   - armSorenessSeverity: Severity of arm soreness (1-3)
    ///   - jointPain: List of joint pain locations
    func updatePreview(
        sleepHours: Double,
        sleepQuality: Int,
        subjectiveReadiness: Int,
        armSoreness: Bool,
        armSorenessSeverity: Int,
        jointPain: [JointPainLocation]
    ) {
        let input = ReadinessInput(
            sleepHours: sleepHours,
            sleepQuality: sleepQuality,
            hrvValue: nil,
            whoopRecoveryPct: nil,
            subjectiveReadiness: subjectiveReadiness,
            armSoreness: armSoreness,
            armSorenessSeverity: armSoreness ? armSorenessSeverity : nil,
            jointPain: jointPain,
            jointPainNotes: nil
        )

        let (band, score) = readinessService.calculateReadinessBand(input: input)
        readinessPreview = ReadinessPreview(band: band, score: score)
    }

    /// Submit daily readiness check-in
    /// - Parameters:
    ///   - sleepHours: Hours of sleep
    ///   - sleepQuality: Sleep quality rating (1-5)
    ///   - subjectiveReadiness: Subjective readiness rating (1-5)
    ///   - armSoreness: Whether arm soreness is present
    ///   - armSorenessSeverity: Severity of arm soreness (1-3, optional)
    ///   - jointPain: List of joint pain locations
    ///   - painNotes: Optional notes about pain/soreness
    func submitReadiness(
        sleepHours: Double,
        sleepQuality: Int,
        subjectiveReadiness: Int,
        armSoreness: Bool,
        armSorenessSeverity: Int?,
        jointPain: [JointPainLocation],
        painNotes: String?
    ) async {
        isLoading = true
        errorMessage = nil

        guard let patientId = PTSupabaseClient.shared.userId else {
            errorMessage = "Not signed in"
            isLoading = false
            return
        }

        let input = ReadinessInput(
            sleepHours: sleepHours,
            sleepQuality: sleepQuality,
            hrvValue: nil,
            whoopRecoveryPct: nil,
            subjectiveReadiness: subjectiveReadiness,
            armSoreness: armSoreness,
            armSorenessSeverity: armSorenessSeverity,
            jointPain: jointPain,
            jointPainNotes: painNotes
        )

        do {
            let _ = try await readinessService.submitDailyReadiness(
                patientId: patientId,
                input: input
            )

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    /// Fetch today's readiness check-in if it exists
    func fetchTodayReadiness() async {
        guard let patientId = PTSupabaseClient.shared.userId else { return }

        do {
            if let readiness = try await readinessService.fetchTodayReadiness(patientId: patientId) {
                // Update preview with existing data
                readinessPreview = ReadinessPreview(
                    band: readiness.readinessBand,
                    score: readiness.readinessScore
                )
            }
        } catch {
            // Silently fail - it's OK if no check-in exists yet today
            errorMessage = nil
        }
    }
}
