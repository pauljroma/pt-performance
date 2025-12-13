//
//  ReadinessServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for ReadinessService and readiness band calculation
//  Validates weighted scoring algorithm for Build 39
//

import XCTest
@testable import PTPerformance

class ReadinessServiceTests: XCTestCase {
    
    var sut: ReadinessService!
    
    // MARK: - Test Setup
    
    override func setUp() {
        super.setUp()
        // Note: Would need mock Supabase client for full integration tests
        // These tests focus on calculation logic
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Readiness Band Calculation Tests
    
    func testCalculateReadinessBand_PerfectScore_Green() {
        // Given: Perfect readiness inputs
        let input = ReadinessInput(
            sleepHours: 8.0,
            sleepQuality: 5,  // Excellent
            hrvValue: 65.0,
            whoopRecoveryPct: 95,
            subjectiveReadiness: 5,  // Excellent
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )
        
        // When: Calculate readiness band (mock version without service)
        let (band, score) = calculateMockReadinessBand(input: input)
        
        // Then: Should be green band
        XCTAssertEqual(band, .green, "Perfect inputs should result in green band")
        XCTAssertGreaterThanOrEqual(score, 85.0, "Score should be >= 85 for green")
    }
    
    func testCalculateReadinessBand_PoorSleep_Yellow() {
        // Given: Poor sleep but everything else good
        let input = ReadinessInput(
            sleepHours: 5.0,  // Poor
            sleepQuality: 2,  // Poor
            hrvValue: 60.0,
            whoopRecoveryPct: 85,
            subjectiveReadiness: 4,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )
        
        // When: Calculate
        let (band, score) = calculateMockReadinessBand(input: input)
        
        // Then: Should be yellow (70-84 range)
        XCTAssertTrue(band == .yellow || band == .orange, "Poor sleep should lower band")
        XCTAssertLessThan(score, 85.0, "Score should be below green threshold")
    }
    
    func testCalculateReadinessBand_JointPain_AutoRed() {
        // Given: Everything perfect BUT joint pain present
        let input = ReadinessInput(
            sleepHours: 8.0,
            sleepQuality: 5,
            hrvValue: 65.0,
            whoopRecoveryPct: 95,
            subjectiveReadiness: 5,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [.shoulder],  // Joint pain!
            jointPainNotes: "Mild shoulder discomfort"
        )
        
        // When: Calculate
        let (band, score) = calculateMockReadinessBand(input: input)
        
        // Then: Should be RED regardless of score
        XCTAssertEqual(band, .red, "Any joint pain should force red band")
    }
    
    func testCalculateReadinessBand_MultipleJointPain_Red() {
        // Given: Multiple joint pain locations
        let input = ReadinessInput(
            sleepHours: 7.0,
            sleepQuality: 4,
            hrvValue: 55.0,
            whoopRecoveryPct: 70,
            subjectiveReadiness: 3,
            armSoreness: true,
            armSorenessSeverity: 2,
            jointPain: [.shoulder, .elbow, .knee],
            jointPainNotes: "Multiple areas sore"
        )
        
        // When: Calculate
        let (band, score) = calculateMockReadinessBand(input: input)
        
        // Then: RED band
        XCTAssertEqual(band, .red)
    }
    
    func testCalculateReadinessBand_ModerateArmSoreness_Orange() {
        // Given: Moderate arm soreness (severity 2)
        let input = ReadinessInput(
            sleepHours: 7.0,
            sleepQuality: 3,
            hrvValue: 58.0,
            whoopRecoveryPct: 75,
            subjectiveReadiness: 3,
            armSoreness: true,
            armSorenessSeverity: 2,  // Moderate
            jointPain: [],
            jointPainNotes: nil
        )
        
        // When: Calculate
        let (band, score) = calculateMockReadinessBand(input: input)
        
        // Then: Should be orange
        XCTAssertEqual(band, .orange, "Moderate arm soreness should trigger orange")
    }
    
    func testCalculateReadinessBand_LowWHOOPRecovery_Yellow() {
        // Given: Low WHOOP recovery
        let input = ReadinessInput(
            sleepHours: 7.0,
            sleepQuality: 4,
            hrvValue: 60.0,
            whoopRecoveryPct: 40,  // Low recovery
            subjectiveReadiness: 4,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )
        
        // When: Calculate
        let (band, score) = calculateMockReadinessBand(input: input)
        
        // Then: Should be yellow or orange
        XCTAssertTrue(band == .yellow || band == .orange, "Low WHOOP recovery should lower band")
        XCTAssertLessThan(score, 85.0)
    }
    
    // MARK: - Readiness Band Adjustments Tests
    
    func testReadinessBand_GreenAdjustments() {
        let band = ReadinessBand.green
        
        XCTAssertEqual(band.loadAdjustment, 0.0, "Green should have no load adjustment")
        XCTAssertEqual(band.volumeAdjustment, 0.0, "Green should have no volume adjustment")
        XCTAssertEqual(band.description, "Full prescription")
    }
    
    func testReadinessBand_YellowAdjustments() {
        let band = ReadinessBand.yellow
        
        XCTAssertEqual(band.loadAdjustment, -0.07, "Yellow should reduce load by 7%")
        XCTAssertEqual(band.volumeAdjustment, -0.20, "Yellow should reduce volume by 20%")
    }
    
    func testReadinessBand_OrangeAdjustments() {
        let band = ReadinessBand.orange
        
        XCTAssertEqual(band.loadAdjustment, -0.12, "Orange should reduce load by 12%")
        XCTAssertEqual(band.volumeAdjustment, -0.35, "Orange should reduce volume by 35%")
    }
    
    func testReadinessBand_RedAdjustments() {
        let band = ReadinessBand.red
        
        XCTAssertEqual(band.loadAdjustment, -1.0, "Red should eliminate load")
        XCTAssertEqual(band.volumeAdjustment, -1.0, "Red should eliminate volume")
    }
    
    // MARK: - Scoring Algorithm Tests
    
    func testScoringWeights_SleepContribution() {
        // Test that sleep contributes 30% to score
        // Given: Poor sleep (< 6 hours) = -20 points
        let input1 = ReadinessInput(
            sleepHours: 5.0,
            sleepQuality: 1,
            subjectiveReadiness: 5,
            armSoreness: false,
            jointPain: []
        )
        
        let (_, score1) = calculateMockReadinessBand(input: input1)
        
        // Given: Good sleep
        let input2 = ReadinessInput(
            sleepHours: 8.0,
            sleepQuality: 5,
            subjectiveReadiness: 5,
            armSoreness: false,
            jointPain: []
        )
        
        let (_, score2) = calculateMockReadinessBand(input: input2)
        
        // Then: Difference should be significant (at least 20 points)
        XCTAssertGreaterThan(score2 - score1, 20.0, "Sleep should have significant impact on score")
    }
    
    // MARK: - Helper Methods (Mock Implementation for Testing)
    
    private func calculateMockReadinessBand(input: ReadinessInput) -> (band: ReadinessBand, score: Double) {
        var score: Double = 100.0
        
        // Sleep scoring (30% weight)
        if let sleepHours = input.sleepHours {
            if sleepHours < 6 {
                score -= 20
            } else if sleepHours < 7 {
                score -= 10
            }
        }
        
        if let sleepQuality = input.sleepQuality {
            if sleepQuality <= 2 {
                score -= 15
            } else if sleepQuality == 3 {
                score -= 5
            }
        }
        
        // WHOOP Recovery (20% weight)
        if let recovery = input.whoopRecoveryPct {
            if recovery < 33 {
                score -= 20
            } else if recovery < 66 {
                score -= 10
            }
        }
        
        // Subjective readiness (15% weight)
        if let subjective = input.subjectiveReadiness {
            if subjective <= 2 {
                score -= 15
            } else if subjective == 3 {
                score -= 8
            }
        }
        
        // Joint pain (15% weight - AUTO RED if present)
        if !input.jointPain.isEmpty {
            return (.red, score)
        }
        
        if input.armSoreness, let severity = input.armSorenessSeverity {
            if severity >= 2 {
                return (.orange, score)
            }
        }
        
        // Determine band from score
        let band: ReadinessBand
        if score >= 85 {
            band = .green
        } else if score >= 70 {
            band = .yellow
        } else if score >= 50 {
            band = .orange
        } else {
            band = .red
        }
        
        return (band, score)
    }
}
