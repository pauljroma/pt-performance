//
//  NutritionProgressRingTests.swift
//  PTPerformanceTests
//
//  Tests for NutritionProgressRing and related nutrition UI components
//

import XCTest
import SwiftUI
@testable import PTPerformance

final class NutritionMacroRingTests: XCTestCase {

    // MARK: - Initialization Tests

    func testNutritionMacroRing_DefaultValues() {
        let ring = NutritionMacroRing(
            progress: 0.5,
            macroName: "Protein",
            color: .red,
            currentGrams: 80,
            targetGrams: 160
        )

        XCTAssertEqual(ring.progress, 0.5)
        XCTAssertEqual(ring.macroName, "Protein")
        XCTAssertEqual(ring.currentGrams, 80)
        XCTAssertEqual(ring.targetGrams, 160)
        XCTAssertEqual(ring.size, 80) // Default
        XCTAssertEqual(ring.lineWidth, 8) // Default
        XCTAssertTrue(ring.animated) // Default
    }

    func testNutritionMacroRing_CustomSize() {
        let ring = NutritionMacroRing(
            progress: 0.75,
            macroName: "Carbs",
            color: .blue,
            currentGrams: 150,
            targetGrams: 200,
            size: 100,
            lineWidth: 12,
            animated: false
        )

        XCTAssertEqual(ring.size, 100)
        XCTAssertEqual(ring.lineWidth, 12)
        XCTAssertFalse(ring.animated)
    }

    // MARK: - Progress Tests

    func testProgress_ZeroValue() {
        let ring = NutritionMacroRing(
            progress: 0,
            macroName: "Fat",
            color: .yellow,
            currentGrams: 0,
            targetGrams: 70
        )

        XCTAssertEqual(ring.progress, 0)
    }

    func testProgress_FullProgress() {
        let ring = NutritionMacroRing(
            progress: 1.0,
            macroName: "Protein",
            color: .red,
            currentGrams: 160,
            targetGrams: 160
        )

        XCTAssertEqual(ring.progress, 1.0)
    }

    func testProgress_OverProgress() {
        let ring = NutritionMacroRing(
            progress: 1.5,
            macroName: "Protein",
            color: .red,
            currentGrams: 240,
            targetGrams: 160
        )

        // Progress should be capped at 1.0 in the view
        XCTAssertEqual(ring.progress, 1.5)
    }
}

final class TripleMacroRingsViewTests: XCTestCase {

    func testTripleMacroRingsView_AllValues() {
        let view = TripleMacroRingsView(
            proteinCurrent: 120,
            proteinTarget: 160,
            carbsCurrent: 180,
            carbsTarget: 250,
            fatCurrent: 50,
            fatTarget: 70
        )

        XCTAssertEqual(view.proteinCurrent, 120)
        XCTAssertEqual(view.proteinTarget, 160)
        XCTAssertEqual(view.carbsCurrent, 180)
        XCTAssertEqual(view.carbsTarget, 250)
        XCTAssertEqual(view.fatCurrent, 50)
        XCTAssertEqual(view.fatTarget, 70)
    }

    func testTripleMacroRingsView_ZeroTargets() {
        let view = TripleMacroRingsView(
            proteinCurrent: 0,
            proteinTarget: 0,
            carbsCurrent: 0,
            carbsTarget: 0,
            fatCurrent: 0,
            fatTarget: 0
        )

        // Should handle zero targets gracefully
        XCTAssertEqual(view.proteinTarget, 0)
        XCTAssertEqual(view.carbsTarget, 0)
        XCTAssertEqual(view.fatTarget, 0)
    }
}

final class CalorieProgressRingTests: XCTestCase {

    func testCalorieProgressRing_NormalProgress() {
        let ring = CalorieProgressRing(
            currentCalories: 1500,
            targetCalories: 2000,
            size: 150
        )

        XCTAssertEqual(ring.currentCalories, 1500)
        XCTAssertEqual(ring.targetCalories, 2000)
        XCTAssertEqual(ring.size, 150)
    }

    func testCalorieProgressRing_AtGoal() {
        let ring = CalorieProgressRing(
            currentCalories: 2000,
            targetCalories: 2000,
            size: 150
        )

        XCTAssertEqual(ring.currentCalories, ring.targetCalories)
    }

    func testCalorieProgressRing_OverGoal() {
        let ring = CalorieProgressRing(
            currentCalories: 2500,
            targetCalories: 2000,
            size: 150
        )

        XCTAssertGreaterThan(ring.currentCalories, ring.targetCalories)
    }

    func testCalorieProgressRing_ZeroTarget() {
        let ring = CalorieProgressRing(
            currentCalories: 500,
            targetCalories: 0,
            size: 150
        )

        // Should handle zero target gracefully
        XCTAssertEqual(ring.targetCalories, 0)
    }
}

final class NutritionGoalCelebrationTests: XCTestCase {

    // Helper class to test Binding-based views
    private class TestBindingWrapper<T>: ObservableObject {
        @Published var value: T

        init(_ value: T) {
            self.value = value
        }
    }

    func testNutritionGoalCelebration_ProteinGoal() {
        let wrapper = TestBindingWrapper(true)

        // Create the view using a binding - we can't easily test SwiftUI views
        // but we can verify the initialization works without crashing
        let binding = Binding(get: { wrapper.value }, set: { wrapper.value = $0 })

        let celebration = NutritionGoalCelebration(
            goalType: "Protein",
            isShowing: binding
        )

        XCTAssertEqual(celebration.goalType, "Protein")
    }

    func testNutritionGoalCelebration_CalorieGoal() {
        let wrapper = TestBindingWrapper(true)
        let binding = Binding(get: { wrapper.value }, set: { wrapper.value = $0 })

        let celebration = NutritionGoalCelebration(
            goalType: "Calorie",
            isShowing: binding
        )

        XCTAssertEqual(celebration.goalType, "Calorie")
    }
}
