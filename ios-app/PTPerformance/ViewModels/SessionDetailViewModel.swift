import SwiftUI

// MARK: - Session Detail ViewModel (ACP-588)

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
        defer { isLoading = false }

        do {
            exerciseLogs = try await analyticsService.fetchSessionExerciseLogs(
                sessionId: sessionId,
                patientId: patientId
            )
        } catch {
            ErrorLogger.shared.logError(error, context: "SessionDetailViewModel.fetchPrescribedDetail")
            errorMessage = "Unable to load session details. Please try again."
        }
    }

    /// Fetch exercises for a manual workout
    func fetchManualDetail(workoutId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            exerciseLogs = try await analyticsService.fetchManualWorkoutExercises(
                workoutId: workoutId
            )
        } catch {
            ErrorLogger.shared.logError(error, context: "SessionDetailViewModel.fetchManualDetail")
            errorMessage = "Unable to load workout details. Please try again."
        }
    }
}
