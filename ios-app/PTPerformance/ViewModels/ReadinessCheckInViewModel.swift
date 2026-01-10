import Foundation
import SwiftUI

/// ViewModel for managing daily readiness check-in form
/// BUILD 116 - Agent 11: ReadinessCheckInViewModel
///
/// Responsibilities:
/// - Input state management (sleep, soreness, energy, stress)
/// - Form validation
/// - Submission to ReadinessService
/// - Loading/error/success states
/// - Today's entry check (prevent duplicates)
@MainActor
class ReadinessCheckInViewModel: ObservableObject {
    // MARK: - Dependencies

    private let readinessService: ReadinessService
    private let patientId: UUID

    // MARK: - Input State

    @Published var sleepHours: Double = 7.0
    @Published var sorenessLevel: Int = 5
    @Published var energyLevel: Int = 5
    @Published var stressLevel: Int = 5
    @Published var notes: String = ""

    // MARK: - UI State

    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var showSuccess: Bool = false
    @Published var hasSubmittedToday: Bool = false
    @Published var todayEntry: DailyReadiness?

    // MARK: - Computed Properties

    /// Checks if all inputs are valid
    var isValid: Bool {
        sleepHours >= 0 && sleepHours <= 24 &&
        (1...10).contains(sorenessLevel) &&
        (1...10).contains(energyLevel) &&
        (1...10).contains(stressLevel)
    }

    /// Whether the form can be submitted
    var canSubmit: Bool {
        isValid && !isLoading
    }

    /// Preview of the current readiness score category (from submitted entry)
    var scorePreview: ReadinessCategory? {
        guard let score = todayEntry?.readinessScore else { return nil }
        return ReadinessCategory.category(for: score)
    }

    // MARK: - BUILD 123: Live Score Calculation

    /// Calculate live readiness score from current form inputs
    /// Algorithm approximates database trigger calculation:
    /// - Sleep: 35% weight (normalized to 8 hours = 100%)
    /// - Energy: 35% weight (1-10 scale)
    /// - Soreness: 15% weight (inverse - lower is better)
    /// - Stress: 15% weight (inverse - lower is better)
    var liveReadinessScore: Double {
        // Sleep score: normalize to 8 hours = 100%, max at 9 hours
        let sleepScore = min((sleepHours / 8.0) * 100, 100)

        // Energy score: 1-10 scale → 0-100%
        let energyScore = (Double(energyLevel) / 10.0) * 100

        // Soreness penalty: inverse (10 = worst, 1 = best)
        let sorenessScore = (1.0 - (Double(sorenessLevel - 1) / 9.0)) * 100

        // Stress penalty: inverse (10 = worst, 1 = best)
        let stressScore = (1.0 - (Double(stressLevel - 1) / 9.0)) * 100

        // Weighted total
        let total = (sleepScore * 0.35) + (energyScore * 0.35) + (sorenessScore * 0.15) + (stressScore * 0.15)

        return max(0, min(100, total)) // Clamp to 0-100
    }

    /// Live readiness category based on current form inputs
    var liveScoreCategory: ReadinessCategory {
        return ReadinessCategory.category(for: liveReadinessScore)
    }

    /// Formatted live score for display
    var liveScoreFormatted: String {
        return String(format: "%.0f", liveReadinessScore)
    }

    // MARK: - Initialization

    /// Initialize with patient ID and optional service dependency
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - readinessService: Service for readiness operations (defaults to shared instance)
    init(
        patientId: UUID,
        readinessService: ReadinessService = ReadinessService()
    ) {
        self.patientId = patientId
        self.readinessService = readinessService
    }

    // MARK: - Load Today's Entry

    /// Load today's readiness entry if it exists
    /// Populates form with existing values or defaults
    func loadTodayEntry() async {
        isLoading = true

        do {
            todayEntry = try await readinessService.getTodayReadiness(for: patientId)

            if let entry = todayEntry {
                // Populate form with today's values
                sleepHours = entry.sleepHours ?? 7.0
                sorenessLevel = entry.sorenessLevel ?? 5
                energyLevel = entry.energyLevel ?? 5
                stressLevel = entry.stressLevel ?? 5
                notes = entry.notes ?? ""
                hasSubmittedToday = true
            } else {
                // No entry for today - use defaults
                hasSubmittedToday = false
                resetForm()
            }
        } catch {
            // No entry for today is expected, not an error
            hasSubmittedToday = false
            resetForm()
        }

        isLoading = false
    }

    // MARK: - Submit Readiness

    /// Submit readiness check-in to database
    /// Score is automatically calculated by database trigger
    func submitReadiness() async {
        guard canSubmit else { return }

        isLoading = true
        showError = false

        do {
            let entry = try await readinessService.submitReadiness(
                patientId: patientId,
                date: Date(),
                sleepHours: sleepHours,
                sorenessLevel: sorenessLevel,
                energyLevel: energyLevel,
                stressLevel: stressLevel,
                notes: notes.isEmpty ? nil : notes
            )

            todayEntry = entry
            hasSubmittedToday = true
            showSuccess = true

            // Auto-dismiss success after 2 seconds
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showSuccess = false

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    // MARK: - Reset Form

    /// Reset form to default values
    func resetForm() {
        sleepHours = 7.0
        sorenessLevel = 5
        energyLevel = 5
        stressLevel = 5
        notes = ""
        showError = false
        errorMessage = ""
        showSuccess = false
    }

    // MARK: - Validation Messages

    /// Get validation message for a specific field
    /// - Parameter field: Field name to validate
    /// - Returns: Error message if invalid, nil if valid
    func validationMessage(for field: String) -> String? {
        switch field {
        case "sleep":
            if sleepHours < 0 || sleepHours > 24 {
                return "Sleep hours must be between 0 and 24"
            }
        case "soreness":
            if !(1...10).contains(sorenessLevel) {
                return "Soreness level must be between 1 and 10"
            }
        case "energy":
            if !(1...10).contains(energyLevel) {
                return "Energy level must be between 1 and 10"
            }
        case "stress":
            if !(1...10).contains(stressLevel) {
                return "Stress level must be between 1 and 10"
            }
        default:
            break
        }
        return nil
    }

    // MARK: - Helper Methods

    /// Get display label for sleep hours
    var sleepHoursLabel: String {
        return String(format: "%.1f hours", sleepHours)
    }

    /// Get display label for soreness level
    var sorenessLevelLabel: String {
        return "\(sorenessLevel) / 10"
    }

    /// Get display label for energy level
    var energyLevelLabel: String {
        return "\(energyLevel) / 10"
    }

    /// Get display label for stress level
    var stressLevelLabel: String {
        return "\(stressLevel) / 10"
    }

    /// Get color for soreness level (red = high soreness)
    var sorenessColor: Color {
        switch sorenessLevel {
        case 1...3:
            return .green
        case 4...6:
            return .yellow
        case 7...8:
            return .orange
        default:
            return .red
        }
    }

    /// Get color for energy level (green = high energy)
    var energyColor: Color {
        switch energyLevel {
        case 1...3:
            return .red
        case 4...6:
            return .yellow
        case 7...8:
            return .orange
        default:
            return .green
        }
    }

    /// Get color for stress level (red = high stress)
    var stressColor: Color {
        switch stressLevel {
        case 1...3:
            return .green
        case 4...6:
            return .yellow
        case 7...8:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Preview Support

extension ReadinessCheckInViewModel {
    /// Preview instance with sample data
    static var preview: ReadinessCheckInViewModel {
        let vm = ReadinessCheckInViewModel(
            patientId: UUID(),
            readinessService: ReadinessService()
        )
        return vm
    }

    /// Preview instance with today's entry already submitted
    static var previewWithToday: ReadinessCheckInViewModel {
        let vm = ReadinessCheckInViewModel(
            patientId: UUID(),
            readinessService: ReadinessService()
        )
        vm.hasSubmittedToday = true
        vm.sleepHours = 8.5
        vm.sorenessLevel = 3
        vm.energyLevel = 8
        vm.stressLevel = 4
        vm.notes = "Feeling great, well-rested"
        return vm
    }
}
