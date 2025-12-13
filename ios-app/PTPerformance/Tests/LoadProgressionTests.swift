//
//  LoadProgressionTests.swift
//  PTPerformanceTests
//
//  Unit tests for ProgressionCalculator and load progression logic
//  Validates RPE-based load calculations for Build 38
//

import XCTest
@testable import PTPerformance

class LoadProgressionTests: XCTestCase {
    
    // MARK: - Test Setup
    
    override func setUpWithTearDown() throws {
        try super.setUpWithTearDown()
    }
    
    // MARK: - ProgressionCalculator Tests
    
    func testCalculateNextLoad_IncreasesWhenRPELow() {
        // Given: Current load 100 lbs, target RPE 8.0, actual RPE 7.0 (0.5 below)
        let currentLoad: Double = 100.0
        let targetRpeHigh: Double = 8.0
        let actualRpe: Double = 7.0
        
        // When: Calculate next load for lower body exercise
        let result = ProgressionCalculator.calculateNextLoad(
            currentLoad: currentLoad,
            targetRpeHigh: targetRpeHigh,
            actualRpe: actualRpe,
            exerciseType: .primary,
            bodyRegion: .lowerBody
        )
        
        // Then: Should increase by 10 lbs for lower body
        XCTAssertEqual(result.action, .increase, "Should increase load when RPE is low")
        XCTAssertEqual(result.nextLoad, 110.0, "Lower body should increase by 10 lbs")
        XCTAssertTrue(result.reason.contains("below target"), "Reason should mention RPE below target")
    }
    
    func testCalculateNextLoad_IncreasesUpperBody() {
        // Given: Upper body exercise with low RPE
        let currentLoad: Double = 50.0
        let targetRpeHigh: Double = 8.0
        let actualRpe: Double = 7.0
        
        // When: Calculate for upper body
        let result = ProgressionCalculator.calculateNextLoad(
            currentLoad: currentLoad,
            targetRpeHigh: targetRpeHigh,
            actualRpe: actualRpe,
            exerciseType: .primary,
            bodyRegion: .upperBody
        )
        
        // Then: Should increase by 5 lbs for upper body
        XCTAssertEqual(result.action, .increase)
        XCTAssertEqual(result.nextLoad, 55.0, "Upper body should increase by 5 lbs")
    }
    
    func testCalculateNextLoad_HoldsWhenRPEInRange() {
        // Given: RPE within target range
        let currentLoad: Double = 100.0
        let targetRpeHigh: Double = 8.0
        let actualRpe: Double = 8.0  // Exactly at target
        
        // When: Calculate next load
        let result = ProgressionCalculator.calculateNextLoad(
            currentLoad: currentLoad,
            targetRpeHigh: targetRpeHigh,
            actualRpe: actualRpe,
            exerciseType: .primary,
            bodyRegion: .lowerBody
        )
        
        // Then: Should hold current load
        XCTAssertEqual(result.action, .hold, "Should hold when RPE within range")
        XCTAssertEqual(result.nextLoad, 100.0, "Load should stay the same")
        XCTAssertTrue(result.reason.contains("within target"), "Reason should mention RPE in range")
    }
    
    func testCalculateNextLoad_DecreasesWhenRPEHigh() {
        // Given: RPE overshooting target by more than 0.5
        let currentLoad: Double = 100.0
        let targetRpeHigh: Double = 8.0
        let actualRpe: Double = 9.0  // 1.0 above target
        
        // When: Calculate next load
        let result = ProgressionCalculator.calculateNextLoad(
            currentLoad: currentLoad,
            targetRpeHigh: targetRpeHigh,
            actualRpe: actualRpe,
            exerciseType: .primary,
            bodyRegion: .lowerBody
        )
        
        // Then: Should decrease by 5%
        XCTAssertEqual(result.action, .decrease, "Should decrease when RPE too high")
        XCTAssertEqual(result.nextLoad, 95.0, accuracy: 0.01, "Should decrease by 5%")
        XCTAssertTrue(result.reason.contains("overshoot"), "Reason should mention RPE overshoot")
    }
    
    func testCalculateNextLoad_BufferZone() {
        // Given: RPE exactly 0.5 below target (on the edge)
        let currentLoad: Double = 100.0
        let targetRpeHigh: Double = 8.0
        let actualRpe: Double = 7.5  // Exactly 0.5 below
        
        // When: Calculate next load
        let result = ProgressionCalculator.calculateNextLoad(
            currentLoad: currentLoad,
            targetRpeHigh: targetRpeHigh,
            actualRpe: actualRpe,
            exerciseType: .primary,
            bodyRegion: .lowerBody
        )
        
        // Then: Should hold (within buffer)
        XCTAssertEqual(result.action, .hold, "Should hold when at buffer edge")
        XCTAssertEqual(result.nextLoad, 100.0)
    }
    
    func testCalculateNextLoad_SecondaryExercise() {
        // Given: Secondary exercise with same RPE logic
        let currentLoad: Double = 75.0
        let targetRpeHigh: Double = 7.0
        let actualRpe: Double = 6.0
        
        // When: Calculate for secondary exercise
        let result = ProgressionCalculator.calculateNextLoad(
            currentLoad: currentLoad,
            targetRpeHigh: targetRpeHigh,
            actualRpe: actualRpe,
            exerciseType: .secondary,
            bodyRegion: .lowerBody
        )
        
        // Then: Should still apply same progression rules
        XCTAssertEqual(result.action, .increase)
        XCTAssertEqual(result.nextLoad, 85.0)  // +10 lbs for lower body
    }
    
    // MARK: - Edge Cases
    
    func testCalculateNextLoad_ZeroLoad() {
        // Given: Starting from zero (bodyweight exercise transitioning to weighted)
        let result = ProgressionCalculator.calculateNextLoad(
            currentLoad: 0.0,
            targetRpeHigh: 8.0,
            actualRpe: 7.0,
            exerciseType: .primary,
            bodyRegion: .upperBody
        )
        
        // Then: Should still apply increment
        XCTAssertEqual(result.nextLoad, 5.0, "Should add 5 lbs from zero for upper body")
    }
    
    func testCalculateNextLoad_VeryHighRPE() {
        // Given: RPE way too high (10 on a scale to 8)
        let result = ProgressionCalculator.calculateNextLoad(
            currentLoad: 100.0,
            targetRpeHigh: 8.0,
            actualRpe: 10.0,
            exerciseType: .primary,
            bodyRegion: .lowerBody
        )
        
        // Then: Should decrease by 5%
        XCTAssertEqual(result.action, .decrease)
        XCTAssertEqual(result.nextLoad, 95.0, accuracy: 0.01)
    }
    
    // MARK: - Performance Tests
    
    func testCalculateNextLoad_Performance() {
        measure {
            for _ in 0..<1000 {
                _ = ProgressionCalculator.calculateNextLoad(
                    currentLoad: 100.0,
                    targetRpeHigh: 8.0,
                    actualRpe: 7.5,
                    exerciseType: .primary,
                    bodyRegion: .lowerBody
                )
            }
        }
    }
}
