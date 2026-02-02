//
//  GestureSetLoggerViewModel.swift
//  PTPerformance
//
//  ACP-514: Gesture-Based Set Logging
//  ViewModel for managing gesture-based set logging state
//
//  Gestures:
//  - Single tap: +1 rep
//  - Double tap: Complete set
//  - Swipe up: +5 lbs weight
//  - Swipe down: -5 lbs weight
//

import Foundation
import SwiftUI
import Combine

// MARK: - Gesture Set Logger ViewModel

@MainActor
class GestureSetLoggerViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Current rep count for the active set
    @Published var repCount: Int = 0

    /// Current weight in pounds
    @Published var weight: Double = 0

    /// Whether the current set is marked as complete
    @Published var isSetComplete: Bool = false

    /// Total sets completed in this exercise
    @Published var completedSets: Int = 0

    /// Target sets for the exercise (optional)
    @Published var targetSets: Int?

    /// Target reps for the exercise (optional)
    @Published var targetReps: Int?

    /// Target weight for the exercise (optional)
    @Published var targetWeight: Double?

    /// Weight unit (lbs or kg)
    @Published var weightUnit: String = "lbs"

    /// Weight adjustment increment (default 5 lbs)
    @Published var weightIncrement: Double = 5.0

    /// Animation trigger for rep count changes
    @Published var repAnimationTrigger: Bool = false

    /// Animation trigger for weight changes
    @Published var weightAnimationTrigger: Bool = false

    /// Direction of last weight change (for animation)
    @Published var lastWeightChangeDirection: WeightChangeDirection = .none

    /// Logged sets data for persistence
    @Published private(set) var loggedSets: [LoggedSet] = []

    /// Error message for display
    @Published var errorMessage: String?

    // MARK: - Computed Properties

    /// Progress towards target sets
    var setsProgress: Double {
        guard let target = targetSets, target > 0 else { return 0 }
        return Double(completedSets) / Double(target)
    }

    /// Whether all target sets are complete
    var allSetsComplete: Bool {
        guard let target = targetSets else { return false }
        return completedSets >= target
    }

    /// Display string for current weight
    var weightDisplay: String {
        if weight == 0 {
            return "BW"  // Bodyweight
        }
        return weight.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(weight)) \(weightUnit)"
            : String(format: "%.1f \(weightUnit)", weight)
    }

    /// Display string for rep count
    var repDisplay: String {
        if let target = targetReps {
            return "\(repCount)/\(target)"
        }
        return "\(repCount)"
    }

    /// Display string for sets progress
    var setsDisplay: String {
        if let target = targetSets {
            return "Set \(completedSets + 1) of \(target)"
        }
        return "Set \(completedSets + 1)"
    }

    // MARK: - Weight Change Direction

    enum WeightChangeDirection {
        case none
        case up
        case down
    }

    // MARK: - Logged Set Model

    struct LoggedSet: Identifiable, Equatable {
        let id: UUID
        let setNumber: Int
        let reps: Int
        let weight: Double
        let weightUnit: String
        let completedAt: Date

        init(setNumber: Int, reps: Int, weight: Double, weightUnit: String) {
            self.id = UUID()
            self.setNumber = setNumber
            self.reps = reps
            self.weight = weight
            self.weightUnit = weightUnit
            self.completedAt = Date()
        }
    }

    // MARK: - Initialization

    init(
        targetSets: Int? = nil,
        targetReps: Int? = nil,
        targetWeight: Double? = nil,
        weightUnit: String = "lbs"
    ) {
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.weightUnit = weightUnit

        // Start with target weight if provided
        if let targetWeight = targetWeight {
            self.weight = targetWeight
        }
    }

    // MARK: - Gesture Actions

    /// Handle single tap - increment rep count
    func handleTap() {
        repCount += 1

        // Trigger animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            repAnimationTrigger.toggle()
        }

        // Haptic feedback
        HapticFeedback.light()

        DebugLogger.shared.log("GestureSetLogger: Tap - rep count now \(repCount)", level: .diagnostic)
    }

    /// Handle double tap - complete the current set
    func handleDoubleTap() {
        guard repCount > 0 else {
            // Can't complete a set with 0 reps
            HapticFeedback.warning()
            errorMessage = "Add at least 1 rep before completing the set"
            return
        }

        // Log the completed set
        let loggedSet = LoggedSet(
            setNumber: completedSets + 1,
            reps: repCount,
            weight: weight,
            weightUnit: weightUnit
        )
        loggedSets.append(loggedSet)

        // Update state
        completedSets += 1
        isSetComplete = true

        // Trigger animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            repAnimationTrigger.toggle()
        }

        // Success haptic feedback
        HapticFeedback.success()

        DebugLogger.shared.log("GestureSetLogger: Double tap - completed set \(completedSets) with \(repCount) reps @ \(weightDisplay)", level: .success)

        // Reset rep count for next set after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.resetForNextSet()
        }
    }

    /// Handle swipe up - increase weight
    func handleSwipeUp() {
        weight += weightIncrement
        lastWeightChangeDirection = .up

        // Trigger animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            weightAnimationTrigger.toggle()
        }

        // Haptic feedback
        HapticFeedback.medium()

        DebugLogger.shared.log("GestureSetLogger: Swipe up - weight now \(weightDisplay)", level: .diagnostic)
    }

    /// Handle swipe down - decrease weight
    func handleSwipeDown() {
        // Don't go below 0
        let newWeight = max(0, weight - weightIncrement)

        if newWeight != weight {
            weight = newWeight
            lastWeightChangeDirection = .down

            // Trigger animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                weightAnimationTrigger.toggle()
            }

            // Haptic feedback
            HapticFeedback.medium()

            DebugLogger.shared.log("GestureSetLogger: Swipe down - weight now \(weightDisplay)", level: .diagnostic)
        } else {
            // Already at minimum
            HapticFeedback.warning()
        }
    }

    // MARK: - State Management

    /// Reset state for the next set
    func resetForNextSet() {
        repCount = 0
        isSetComplete = false

        // Keep the weight the same for next set
        DebugLogger.shared.log("GestureSetLogger: Reset for next set", level: .diagnostic)
    }

    /// Reset all state (for new exercise)
    func resetAll() {
        repCount = 0
        weight = targetWeight ?? 0
        isSetComplete = false
        completedSets = 0
        loggedSets.removeAll()
        lastWeightChangeDirection = .none
        errorMessage = nil

        DebugLogger.shared.log("GestureSetLogger: Full reset", level: .diagnostic)
    }

    /// Configure for a new exercise
    func configure(
        targetSets: Int?,
        targetReps: Int?,
        targetWeight: Double?,
        weightUnit: String = "lbs"
    ) {
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.weightUnit = weightUnit
        resetAll()
    }

    /// Manually set the rep count
    func setRepCount(_ count: Int) {
        repCount = max(0, count)
    }

    /// Manually set the weight
    func setWeight(_ newWeight: Double) {
        weight = max(0, newWeight)
    }

    /// Undo the last logged set
    func undoLastSet() {
        guard !loggedSets.isEmpty else { return }

        let removedSet = loggedSets.removeLast()
        completedSets = max(0, completedSets - 1)

        // Restore the values from the removed set
        repCount = removedSet.reps
        weight = removedSet.weight

        HapticFeedback.warning()

        DebugLogger.shared.log("GestureSetLogger: Undid set \(removedSet.setNumber)", level: .diagnostic)
    }

    // MARK: - Data Export

    /// Get all logged sets for persistence
    func getLoggedSetsData() -> [(setNumber: Int, reps: Int, weight: Double)] {
        return loggedSets.map { ($0.setNumber, $0.reps, $0.weight) }
    }

    /// Get reps array for persistence (matches existing data model)
    func getRepsArray() -> [Int] {
        return loggedSets.map { $0.reps }
    }

    /// Get average weight across all sets
    func getAverageWeight() -> Double? {
        guard !loggedSets.isEmpty else { return nil }
        let total = loggedSets.reduce(0) { $0 + $1.weight }
        return total / Double(loggedSets.count)
    }

    /// Get total volume (reps * weight) for this exercise
    func getTotalVolume() -> Double {
        return loggedSets.reduce(0) { $0 + Double($1.reps) * $1.weight }
    }
}
