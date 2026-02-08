import SwiftUI

/// ViewModel for Arm Care Assessment UI
/// ACP-522: Manages state and live preview of arm care traffic light
@MainActor
class ArmCareAssessmentViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showSuccess = false
    @Published var hasSubmittedToday = false
    @Published var currentTrafficLight: ArmCareTrafficLight = .green
    @Published var todayAssessment: ArmCareAssessment?

    // MARK: - Private Properties

    private let patientId: UUID
    private let armCareService: ArmCareAssessmentService

    // MARK: - Initialization

    init(patientId: UUID, armCareService: ArmCareAssessmentService = ArmCareAssessmentService()) {
        self.patientId = patientId
        self.armCareService = armCareService
    }

    // MARK: - Public Methods

    /// Update live preview of traffic light based on current inputs
    func updatePreview(
        shoulderPainScore: Int,
        shoulderStiffnessScore: Int,
        shoulderStrengthScore: Int,
        elbowPainScore: Int,
        elbowTightnessScore: Int,
        valgusStressScore: Int
    ) {
        let shoulderScore = Double(shoulderPainScore + shoulderStiffnessScore + shoulderStrengthScore) / 3.0
        let elbowScore = Double(elbowPainScore + elbowTightnessScore + valgusStressScore) / 3.0
        let overallScore = (shoulderScore + elbowScore) / 2.0

        currentTrafficLight = ArmCareTrafficLight.from(score: overallScore)
    }

    /// Load today's assessment if it exists
    func loadTodayAssessment() async {
        do {
            if let assessment = try await armCareService.getTodayAssessment(for: patientId) {
                todayAssessment = assessment
                hasSubmittedToday = true
                currentTrafficLight = assessment.trafficLight
            }
        } catch {
            // Silently fail - no assessment for today is fine
            DebugLogger.shared.info("ArmCareAssessment", "No assessment found for today: \(error.localizedDescription)")
        }
    }

    /// Submit arm care assessment
    func submitAssessment(
        shoulderPainScore: Int,
        shoulderStiffnessScore: Int,
        shoulderStrengthScore: Int,
        elbowPainScore: Int,
        elbowTightnessScore: Int,
        valgusStressScore: Int,
        painLocations: [ArmPainLocation],
        notes: String?
    ) async {
        isLoading = true
        showError = false

        do {
            let assessment = try await armCareService.submitAssessment(
                patientId: patientId,
                shoulderPainScore: shoulderPainScore,
                shoulderStiffnessScore: shoulderStiffnessScore,
                shoulderStrengthScore: shoulderStrengthScore,
                elbowPainScore: elbowPainScore,
                elbowTightnessScore: elbowTightnessScore,
                valgusStressScore: valgusStressScore,
                painLocations: painLocations,
                notes: notes
            )

            todayAssessment = assessment
            currentTrafficLight = assessment.trafficLight
            hasSubmittedToday = true
            showSuccess = true

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    /// Get workout modification based on current traffic light
    func getWorkoutModification() -> ArmCareWorkoutModification? {
        guard let assessment = todayAssessment else { return nil }
        return ArmCareWorkoutModification.from(
            trafficLight: assessment.trafficLight,
            shoulderScore: assessment.shoulderScore,
            elbowScore: assessment.elbowScore
        )
    }
}
