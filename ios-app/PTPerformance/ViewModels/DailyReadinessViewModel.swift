import SwiftUI

// MARK: - Constants

private enum DailyReadinessDefaults {
    static let sleepHours: Double = 7.0
    static let sleepQuality: Int = 3
    static let subjectiveReadiness: Int = 3
    static let armSorenessSeverity: Int = 1
}

private enum DailyReadinessLimits {
    static let minSleepHours: Double = 3.0
    static let maxSleepHours: Double = 12.0
    static let minQualityRating: Int = 1
    static let maxQualityRating: Int = 5
    static let minSeverity: Int = 1
    static let maxSeverity: Int = 3
}

/// ViewModel for Daily Readiness Check-in UI
/// Manages state and live preview of readiness band calculation
///
/// BUILD 116 - Migrated form state from view for better testability
/// Responsibilities:
/// - Form input state management (sleep, soreness, readiness, pain)
/// - Live preview calculation
/// - Form validation
/// - Submission to ReadinessService
/// - Loading/error/success states
@MainActor
class DailyReadinessViewModel: ObservableObject {
    // MARK: - Form Input State

    @Published var sleepHours: Double = DailyReadinessDefaults.sleepHours
    @Published var sleepQuality: Int = DailyReadinessDefaults.sleepQuality
    @Published var subjectiveReadiness: Int = DailyReadinessDefaults.subjectiveReadiness
    @Published var armSoreness: Bool = false
    @Published var armSorenessSeverity: Int = DailyReadinessDefaults.armSorenessSeverity
    @Published var jointPain: Set<JointPainLocation> = []
    @Published var painNotes: String = ""

    // MARK: - UI State

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var readinessPreview: ReadinessPreview?
    @Published var showSuccess = false
    @Published var hasSubmittedToday = false

    // MARK: - Dependencies

    private let readinessService: ReadinessService

    // MARK: - Computed Properties

    /// Whether form inputs are valid
    var isValid: Bool {
        sleepHours >= DailyReadinessLimits.minSleepHours &&
        sleepHours <= DailyReadinessLimits.maxSleepHours &&
        (DailyReadinessLimits.minQualityRating...DailyReadinessLimits.maxQualityRating).contains(sleepQuality) &&
        (DailyReadinessLimits.minQualityRating...DailyReadinessLimits.maxQualityRating).contains(subjectiveReadiness)
    }

    /// Whether form can be submitted
    var canSubmit: Bool {
        isValid && !isLoading
    }

    /// Formatted sleep hours display
    var sleepHoursLabel: String {
        String(format: "%.1f hours", sleepHours)
    }

    /// Get color for readiness score display
    func scoreColor(_ score: Double) -> Color {
        if score >= 85 {
            return .green
        } else if score >= 70 {
            return .yellow
        } else if score >= 50 {
            return .orange
        } else {
            return .red
        }
    }

    // MARK: - Initialization

    init(readinessService: ReadinessService = ReadinessService()) {
        self.readinessService = readinessService
    }

    // MARK: - Form Actions

    /// Toggle joint pain location
    func toggleJointPain(_ location: JointPainLocation) {
        if jointPain.contains(location) {
            jointPain.remove(location)
        } else {
            jointPain.insert(location)
        }
        updatePreviewFromInputs()
    }

    /// Reset form to default values
    func resetForm() {
        sleepHours = DailyReadinessDefaults.sleepHours
        sleepQuality = DailyReadinessDefaults.sleepQuality
        subjectiveReadiness = DailyReadinessDefaults.subjectiveReadiness
        armSoreness = false
        armSorenessSeverity = DailyReadinessDefaults.armSorenessSeverity
        jointPain = []
        painNotes = ""
        showSuccess = false
        errorMessage = nil
    }

    /// Update preview based on current form inputs
    func updatePreviewFromInputs() {
        updatePreview(
            sleepHours: sleepHours,
            sleepQuality: sleepQuality,
            subjectiveReadiness: subjectiveReadiness,
            armSoreness: armSoreness,
            armSorenessSeverity: armSorenessSeverity,
            jointPain: Array(jointPain)
        )
    }

    /// Submit readiness using current form values
    func submitReadinessFromForm() async {
        await submitReadiness(
            sleepHours: sleepHours,
            sleepQuality: sleepQuality,
            subjectiveReadiness: subjectiveReadiness,
            armSoreness: armSoreness,
            armSorenessSeverity: armSoreness ? armSorenessSeverity : nil,
            jointPain: Array(jointPain),
            painNotes: painNotes.isEmpty ? nil : painNotes
        )

        if errorMessage == nil {
            showSuccess = true
        }
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
        let input = BandCalculationInput(
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
        defer { isLoading = false }

        guard let patientId = PTSupabaseClient.shared.userId else {
            errorMessage = "Please sign in to submit your readiness check-in."
            return
        }

        let input = BandCalculationInput(
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

        guard let patientUUID = UUID(uuidString: patientId) else {
            errorMessage = "Unable to verify your account. Please sign in again."
            return
        }

        do {
            // Map BandCalculationInput fields to submitReadiness parameters
            // sorenessLevel maps to arm soreness severity
            let sorenessLevel = input.armSoreness ? (input.armSorenessSeverity ?? 2) : 0
            // energyLevel from subjective readiness (1-5 scale)
            let energyLevel = input.subjectiveReadiness
            // Sleep quality as stress indicator
            let stressLevel = input.sleepQuality.map { 6 - $0 } // Invert: 5 = low stress, 1 = high stress

            let _ = try await readinessService.submitReadiness(
                patientId: patientUUID,
                sleepHours: input.sleepHours,
                sorenessLevel: sorenessLevel,
                energyLevel: energyLevel,
                stressLevel: stressLevel,
                notes: input.jointPainNotes
            )
        } catch {
            ErrorLogger.shared.logError(error, context: "DailyReadinessViewModel.submitReadiness")
            errorMessage = "Unable to save your readiness check-in. Please try again."
        }
    }

    /// Fetch today's readiness check-in if it exists
    func fetchTodayReadiness() async {
        guard let patientIdString = PTSupabaseClient.shared.userId,
              let patientId = UUID(uuidString: patientIdString) else {
            errorMessage = "Please sign in to view your readiness check-in."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if let readiness = try await readinessService.getTodayReadiness(for: patientId) {
                // Update preview with existing data
                readinessPreview = ReadinessPreview(
                    band: readiness.readinessBand,
                    score: readiness.readinessScore
                )
            }
            // nil result means no check-in yet today - this is expected, not an error
        } catch {
            ErrorLogger.shared.logError(error, context: "DailyReadinessViewModel.fetchTodayReadiness")
            // Actual error occurred (network failure, etc.)
            if error.localizedDescription.contains("network") || error.localizedDescription.contains("connection") {
                errorMessage = "Couldn't load your readiness data. Please check your connection."
            } else {
                errorMessage = "Couldn't load your readiness data. Please try again."
            }
        }
    }
}
