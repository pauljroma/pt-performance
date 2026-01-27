import Foundation
import SwiftUI

// MARK: - BUILD 296: Session Detail ViewModel (ACP-588)

@MainActor
class SessionDetailViewModel: ObservableObject {
    @Published var exerciseLogs: [ExerciseLogDetail] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let analyticsService: AnalyticsService

    init(analyticsService: AnalyticsService = AnalyticsService()) {
        self.analyticsService = analyticsService
    }

    /// Fetch exercise logs for a prescribed session
    func fetchPrescribedDetail(sessionId: String, patientId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            exerciseLogs = try await analyticsService.fetchSessionExerciseLogs(
                sessionId: sessionId,
                patientId: patientId
            )
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    /// Fetch exercises for a manual workout
    func fetchManualDetail(workoutId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            exerciseLogs = try await analyticsService.fetchManualWorkoutExercises(
                workoutId: workoutId
            )
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
