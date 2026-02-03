import Foundation
import SwiftUI

// MARK: - Constants

private enum Defaults {
    static let sleepHours = 7.0
    static let levelValue = 5
}

private enum Limits {
    static let minSleepHours = 0.0
    static let maxSleepHours = 24.0
    static let optimalSleepHours = 8.0
    static let minLevel = 1
    static let maxLevel = 10
    static let levelDivisor = 10.0
    static let levelRangeNormalizer = 9.0
}

private enum ScoreWeights {
    static let sleep = 0.35
    static let energy = 0.35
    static let soreness = 0.15
    static let stress = 0.15
}

private enum ScoreBounds {
    static let minimum = 0.0
    static let maximum = 100.0
    static let percentMultiplier = 100.0
}

private enum Timing {
    static let successDismissNanoseconds: UInt64 = 2_000_000_000
}

private enum ColorThresholds {
    static let lowRange = 1...3
    static let midRange = 4...6
    static let highMidRange = 7...8
}

/// ViewModel for managing daily readiness check-in form
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

    @Published var sleepHours: Double = Defaults.sleepHours
    @Published var sorenessLevel: Int = Defaults.levelValue
    @Published var energyLevel: Int = Defaults.levelValue
    @Published var stressLevel: Int = Defaults.levelValue
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
        sleepHours >= Limits.minSleepHours && sleepHours <= Limits.maxSleepHours &&
        (Limits.minLevel...Limits.maxLevel).contains(sorenessLevel) &&
        (Limits.minLevel...Limits.maxLevel).contains(energyLevel) &&
        (Limits.minLevel...Limits.maxLevel).contains(stressLevel)
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

    // MARK: - Live Score Calculation

    /// Calculate live readiness score from current form inputs
    /// Algorithm approximates database trigger calculation:
    /// - Sleep: 35% weight (normalized to 8 hours = 100%)
    /// - Energy: 35% weight (1-10 scale)
    /// - Soreness: 15% weight (inverse - lower is better)
    /// - Stress: 15% weight (inverse - lower is better)
    var liveReadinessScore: Double {
        // Sleep score: normalize to optimal hours = 100%
        let sleepScore = min((sleepHours / Limits.optimalSleepHours) * ScoreBounds.percentMultiplier, ScoreBounds.maximum)

        // Energy score: 1-10 scale → 0-100%
        let energyScore = (Double(energyLevel) / Limits.levelDivisor) * ScoreBounds.percentMultiplier

        // Soreness penalty: inverse (10 = worst, 1 = best)
        let sorenessScore = (1.0 - (Double(sorenessLevel - 1) / Limits.levelRangeNormalizer)) * ScoreBounds.percentMultiplier

        // Stress penalty: inverse (10 = worst, 1 = best)
        let stressScore = (1.0 - (Double(stressLevel - 1) / Limits.levelRangeNormalizer)) * ScoreBounds.percentMultiplier

        // Weighted total
        let total = (sleepScore * ScoreWeights.sleep) + (energyScore * ScoreWeights.energy) + (sorenessScore * ScoreWeights.soreness) + (stressScore * ScoreWeights.stress)

        return max(ScoreBounds.minimum, min(ScoreBounds.maximum, total))
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
        showError = false

        do {
            todayEntry = try await readinessService.getTodayReadiness(for: patientId)

            if let entry = todayEntry {
                // Populate form with today's values
                sleepHours = entry.sleepHours ?? Defaults.sleepHours
                sorenessLevel = entry.sorenessLevel ?? Defaults.levelValue
                energyLevel = entry.energyLevel ?? Defaults.levelValue
                stressLevel = entry.stressLevel ?? Defaults.levelValue
                notes = entry.notes ?? ""
                hasSubmittedToday = true
            } else {
                // No entry for today - use defaults (this is expected for new users)
                hasSubmittedToday = false
                resetForm()
            }
        } catch {
            // This is an actual error (network failure, etc.), not just "no data"
            print("❌ Failed to load today's readiness: \(error)")

            if error.localizedDescription.contains("network") || error.localizedDescription.contains("connection") {
                errorMessage = "Couldn't load your previous check-in. Please check your connection."
            } else {
                errorMessage = "Couldn't load your previous check-in. Please try again."
            }
            showError = true

            // Still allow user to submit a new check-in
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

            // Auto-dismiss success after delay
            try? await Task.sleep(nanoseconds: Timing.successDismissNanoseconds)
            showSuccess = false

        } catch {
            // Log the actual error for debugging
            print("❌ ReadinessCheckIn Error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")

            // Show user-friendly message with more detail
            let nsError = error as NSError
            if nsError.domain == "Supabase" || error.localizedDescription.contains("RLS") {
                errorMessage = "Permission error. Please try logging out and back in."
            } else if error.localizedDescription.contains("network") || error.localizedDescription.contains("connection") {
                errorMessage = "Network error. Please check your connection and try again."
            } else {
                errorMessage = "Couldn't save check-in: \(error.localizedDescription)"
            }
            showError = true
        }

        isLoading = false
    }

    // MARK: - Reset Form

    /// Reset form to default values
    func resetForm() {
        sleepHours = Defaults.sleepHours
        sorenessLevel = Defaults.levelValue
        energyLevel = Defaults.levelValue
        stressLevel = Defaults.levelValue
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
            if sleepHours < Limits.minSleepHours || sleepHours > Limits.maxSleepHours {
                return "Sleep hours must be between \(Int(Limits.minSleepHours)) and \(Int(Limits.maxSleepHours))"
            }
        case "soreness":
            if !(Limits.minLevel...Limits.maxLevel).contains(sorenessLevel) {
                return "Soreness level must be between \(Limits.minLevel) and \(Limits.maxLevel)"
            }
        case "energy":
            if !(Limits.minLevel...Limits.maxLevel).contains(energyLevel) {
                return "Energy level must be between \(Limits.minLevel) and \(Limits.maxLevel)"
            }
        case "stress":
            if !(Limits.minLevel...Limits.maxLevel).contains(stressLevel) {
                return "Stress level must be between \(Limits.minLevel) and \(Limits.maxLevel)"
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
        case ColorThresholds.lowRange:
            return .green
        case ColorThresholds.midRange:
            return .yellow
        case ColorThresholds.highMidRange:
            return .orange
        default:
            return .red
        }
    }

    /// Get color for energy level (green = high energy)
    var energyColor: Color {
        switch energyLevel {
        case ColorThresholds.lowRange:
            return .red
        case ColorThresholds.midRange:
            return .yellow
        case ColorThresholds.highMidRange:
            return .orange
        default:
            return .green
        }
    }

    /// Get color for stress level (red = high stress)
    var stressColor: Color {
        switch stressLevel {
        case ColorThresholds.lowRange:
            return .green
        case ColorThresholds.midRange:
            return .yellow
        case ColorThresholds.highMidRange:
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
