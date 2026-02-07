//
//  ValidationHelpersTests.swift
//  PTPerformanceTests
//
//  Unit tests for ValidationHelpers
//  Tests validation functions for forms and inputs
//

import XCTest
@testable import PTPerformance

final class ValidationHelpersTests: XCTestCase {

    // MARK: - Program Name Validation Tests

    func testValidateProgramName_ValidName() {
        let result = ValidationHelpers.validateProgramName("My Program")
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func testValidateProgramName_EmptyName() {
        let result = ValidationHelpers.validateProgramName("")
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
        XCTAssertTrue(result.errorMessage!.contains("empty"))
    }

    func testValidateProgramName_WhitespaceOnly() {
        let result = ValidationHelpers.validateProgramName("   ")
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }

    func testValidateProgramName_TooShort() {
        let result = ValidationHelpers.validateProgramName("AB")
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
        XCTAssertTrue(result.errorMessage!.contains("3"))
    }

    func testValidateProgramName_MinimumLength() {
        let result = ValidationHelpers.validateProgramName("ABC")
        XCTAssertTrue(result.isValid)
    }

    func testValidateProgramName_TooLong() {
        let longName = String(repeating: "a", count: 101)
        let result = ValidationHelpers.validateProgramName(longName)
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
        XCTAssertTrue(result.errorMessage!.contains("100"))
    }

    func testValidateProgramName_MaximumLength() {
        let maxName = String(repeating: "a", count: 100)
        let result = ValidationHelpers.validateProgramName(maxName)
        XCTAssertTrue(result.isValid)
    }

    func testValidateProgramName_TrimsWhitespace() {
        let result = ValidationHelpers.validateProgramName("  Valid Name  ")
        XCTAssertTrue(result.isValid)
    }

    func testValidateProgramName_SpecialCharacters() {
        let result = ValidationHelpers.validateProgramName("Program #1 - Upper/Lower")
        XCTAssertTrue(result.isValid)
    }

    func testValidateProgramName_UnicodeCharacters() {
        let result = ValidationHelpers.validateProgramName("Programa de Fuerza")
        XCTAssertTrue(result.isValid)
    }

    // MARK: - RPE Validation Tests (Double - 1-10 Scale)

    func testValidateRPE_ValidValue() {
        let result = ValidationHelpers.validateRPE(7.5)
        XCTAssertTrue(result.isValid)
    }

    func testValidateRPE_MinValue() {
        let result = ValidationHelpers.validateRPE(0.0)
        XCTAssertTrue(result.isValid)
    }

    func testValidateRPE_MaxValue() {
        let result = ValidationHelpers.validateRPE(10.0)
        XCTAssertTrue(result.isValid)
    }

    func testValidateRPE_BelowRange() {
        let result = ValidationHelpers.validateRPE(-1.0)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("0") && result.errorMessage!.contains("10"))
    }

    func testValidateRPE_AboveRange() {
        let result = ValidationHelpers.validateRPE(11.0)
        XCTAssertFalse(result.isValid)
    }

    func testValidateRPE_VeryNegative() {
        let result = ValidationHelpers.validateRPE(-100.0)
        XCTAssertFalse(result.isValid)
    }

    func testValidateRPE_VeryLarge() {
        let result = ValidationHelpers.validateRPE(1000.0)
        XCTAssertFalse(result.isValid)
    }

    func testValidateRPE_HalfValues() {
        // RPE is often expressed in 0.5 increments
        XCTAssertTrue(ValidationHelpers.validateRPE(6.5).isValid)
        XCTAssertTrue(ValidationHelpers.validateRPE(7.5).isValid)
        XCTAssertTrue(ValidationHelpers.validateRPE(8.5).isValid)
        XCTAssertTrue(ValidationHelpers.validateRPE(9.5).isValid)
    }

    func testValidateRPE_CommonTrainingRPE() {
        // Common training RPE values: 6-9
        for rpe in stride(from: 6.0, through: 9.0, by: 0.5) {
            XCTAssertTrue(ValidationHelpers.validateRPE(rpe).isValid)
        }
    }

    // MARK: - RPE Validation Tests (String)

    func testValidateRPEString_ValidValue() {
        let result = ValidationHelpers.validateRPE("7.5")
        XCTAssertTrue(result.isValid)
    }

    func testValidateRPEString_Empty() {
        let result = ValidationHelpers.validateRPE("")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("empty"))
    }

    func testValidateRPEString_InvalidFormat() {
        let result = ValidationHelpers.validateRPE("abc")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("number"))
    }

    func testValidateRPEString_WithWhitespace() {
        let result = ValidationHelpers.validateRPE(" 8 ")
        XCTAssertTrue(result.isValid)
    }

    func testValidateRPEString_WhitespaceOnly() {
        let result = ValidationHelpers.validateRPE("   ")
        XCTAssertFalse(result.isValid)
    }

    func testValidateRPEString_SpecialCharacters() {
        XCTAssertFalse(ValidationHelpers.validateRPE("8@").isValid)
        XCTAssertFalse(ValidationHelpers.validateRPE("RPE8").isValid)
        XCTAssertFalse(ValidationHelpers.validateRPE("8/10").isValid)
    }

    func testValidateRPEString_NegativeString() {
        let result = ValidationHelpers.validateRPE("-5")
        XCTAssertFalse(result.isValid)
    }

    func testValidateRPEString_IntegerString() {
        let result = ValidationHelpers.validateRPE("8")
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Pain Score Validation Tests (0-10 Scale)

    func testValidatePainScore_ValidValue() {
        let result = ValidationHelpers.validatePainScore(5)
        XCTAssertTrue(result.isValid)
    }

    func testValidatePainScore_MinValue() {
        let result = ValidationHelpers.validatePainScore(0)
        XCTAssertTrue(result.isValid)
    }

    func testValidatePainScore_MaxValue() {
        let result = ValidationHelpers.validatePainScore(10)
        XCTAssertTrue(result.isValid)
    }

    func testValidatePainScore_BelowRange() {
        let result = ValidationHelpers.validatePainScore(-1)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("0") && result.errorMessage!.contains("10"))
    }

    func testValidatePainScore_AboveRange() {
        let result = ValidationHelpers.validatePainScore(11)
        XCTAssertFalse(result.isValid)
    }

    func testValidatePainScore_VeryNegative() {
        let result = ValidationHelpers.validatePainScore(-100)
        XCTAssertFalse(result.isValid)
    }

    func testValidatePainScore_VeryLarge() {
        let result = ValidationHelpers.validatePainScore(1000)
        XCTAssertFalse(result.isValid)
    }

    func testValidatePainScore_AllValidValues() {
        for score in 0...10 {
            XCTAssertTrue(ValidationHelpers.validatePainScore(score).isValid)
        }
    }

    // MARK: - Pain Score Validation Tests (String)

    func testValidatePainScoreString_ValidValue() {
        let result = ValidationHelpers.validatePainScore("5")
        XCTAssertTrue(result.isValid)
    }

    func testValidatePainScoreString_Empty() {
        let result = ValidationHelpers.validatePainScore("")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("empty"))
    }

    func testValidatePainScoreString_WhitespaceOnly() {
        let result = ValidationHelpers.validatePainScore("   ")
        XCTAssertFalse(result.isValid)
    }

    func testValidatePainScoreString_InvalidFormat() {
        let result = ValidationHelpers.validatePainScore("abc")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("integer"))
    }

    func testValidatePainScoreString_DecimalValue() {
        // Pain scores should be integers
        let result = ValidationHelpers.validatePainScore("5.5")
        XCTAssertFalse(result.isValid)
    }

    func testValidatePainScoreString_WithWhitespace() {
        let result = ValidationHelpers.validatePainScore(" 5 ")
        XCTAssertTrue(result.isValid)
    }

    func testValidatePainScoreString_NegativeString() {
        let result = ValidationHelpers.validatePainScore("-1")
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Sets Validation Tests (Positive Integers)

    func testValidateSets_ValidValue() {
        let result = ValidationHelpers.validateSets(3)
        XCTAssertTrue(result.isValid)
    }

    func testValidateSets_MinValue() {
        let result = ValidationHelpers.validateSets(1)
        XCTAssertTrue(result.isValid)
    }

    func testValidateSets_MaxValue() {
        let result = ValidationHelpers.validateSets(99)
        XCTAssertTrue(result.isValid)
    }

    func testValidateSets_ZeroValue() {
        let result = ValidationHelpers.validateSets(0)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("1"))
    }

    func testValidateSets_NegativeValue() {
        let result = ValidationHelpers.validateSets(-5)
        XCTAssertFalse(result.isValid)
    }

    func testValidateSets_TooLarge() {
        let result = ValidationHelpers.validateSets(100)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("99"))
    }

    func testValidateSets_VeryLarge() {
        let result = ValidationHelpers.validateSets(1000)
        XCTAssertFalse(result.isValid)
    }

    func testValidateSets_CommonValues() {
        // Common set numbers: 1-5
        for sets in 1...5 {
            XCTAssertTrue(ValidationHelpers.validateSets(sets).isValid)
        }
    }

    // MARK: - Sets Validation Tests (String)

    func testValidateSetsString_ValidValue() {
        let result = ValidationHelpers.validateSets("3")
        XCTAssertTrue(result.isValid)
    }

    func testValidateSetsString_Empty() {
        let result = ValidationHelpers.validateSets("")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("empty"))
    }

    func testValidateSetsString_WhitespaceOnly() {
        let result = ValidationHelpers.validateSets("   ")
        XCTAssertFalse(result.isValid)
    }

    func testValidateSetsString_InvalidFormat() {
        let result = ValidationHelpers.validateSets("abc")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("integer"))
    }

    func testValidateSetsString_DecimalValue() {
        let result = ValidationHelpers.validateSets("3.5")
        XCTAssertFalse(result.isValid)
    }

    func testValidateSetsString_WithWhitespace() {
        let result = ValidationHelpers.validateSets(" 4 ")
        XCTAssertTrue(result.isValid)
    }

    func testValidateSetsString_SpecialCharacters() {
        XCTAssertFalse(ValidationHelpers.validateSets("3x").isValid)
        XCTAssertFalse(ValidationHelpers.validateSets("3 sets").isValid)
    }

    // MARK: - Reps Validation Tests (Positive Integers)

    func testValidateReps_ValidValue() {
        let result = ValidationHelpers.validateReps(10)
        XCTAssertTrue(result.isValid)
    }

    func testValidateReps_MinValue() {
        let result = ValidationHelpers.validateReps(1)
        XCTAssertTrue(result.isValid)
    }

    func testValidateReps_MaxValue() {
        let result = ValidationHelpers.validateReps(999)
        XCTAssertTrue(result.isValid)
    }

    func testValidateReps_ZeroValue() {
        let result = ValidationHelpers.validateReps(0)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("1"))
    }

    func testValidateReps_NegativeValue() {
        let result = ValidationHelpers.validateReps(-5)
        XCTAssertFalse(result.isValid)
    }

    func testValidateReps_TooLarge() {
        let result = ValidationHelpers.validateReps(1000)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("999"))
    }

    func testValidateReps_CommonValues() {
        // Common rep ranges: 1-20
        for reps in 1...20 {
            XCTAssertTrue(ValidationHelpers.validateReps(reps).isValid)
        }
    }

    // MARK: - Exercise Reps Validation Tests (String - Ranges like "8-10")

    func testValidateExerciseReps_ValidSingleValue() {
        let result = ValidationHelpers.validateExerciseReps("10")
        XCTAssertTrue(result.isValid)
    }

    func testValidateExerciseReps_ValidRange() {
        let result = ValidationHelpers.validateExerciseReps("8-12")
        XCTAssertTrue(result.isValid)
    }

    func testValidateExerciseReps_Empty() {
        let result = ValidationHelpers.validateExerciseReps("")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("empty"))
    }

    func testValidateExerciseReps_InvalidFormat() {
        let result = ValidationHelpers.validateExerciseReps("abc")
        XCTAssertFalse(result.isValid)
    }

    func testValidateExerciseReps_RangeStartGreaterThanEnd() {
        let result = ValidationHelpers.validateExerciseReps("12-8")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("less than"))
    }

    func testValidateExerciseReps_RangeStartEqualsEnd() {
        let result = ValidationHelpers.validateExerciseReps("10-10")
        XCTAssertFalse(result.isValid)
    }

    func testValidateExerciseReps_TooManyDashes() {
        let result = ValidationHelpers.validateExerciseReps("8-10-12")
        XCTAssertFalse(result.isValid)
    }

    func testValidateExerciseReps_NegativeValue() {
        let result = ValidationHelpers.validateExerciseReps("-5")
        XCTAssertFalse(result.isValid)
    }

    func testValidateExerciseReps_ZeroValue() {
        let result = ValidationHelpers.validateExerciseReps("0")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("1"))
    }

    func testValidateExerciseReps_TooLarge() {
        let result = ValidationHelpers.validateExerciseReps("1000")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("999"))
    }

    func testValidateExerciseReps_MaxValue() {
        let result = ValidationHelpers.validateExerciseReps("999")
        XCTAssertTrue(result.isValid)
    }

    func testValidateExerciseReps_MinValue() {
        let result = ValidationHelpers.validateExerciseReps("1")
        XCTAssertTrue(result.isValid)
    }

    func testValidateExerciseReps_RangeWithSpaces() {
        let result = ValidationHelpers.validateExerciseReps(" 8-12 ")
        XCTAssertTrue(result.isValid)
    }

    func testValidateExerciseReps_CommonRanges() {
        // Common rep ranges
        XCTAssertTrue(ValidationHelpers.validateExerciseReps("1-3").isValid)   // Power
        XCTAssertTrue(ValidationHelpers.validateExerciseReps("3-5").isValid)   // Strength
        XCTAssertTrue(ValidationHelpers.validateExerciseReps("6-8").isValid)   // Strength/Hypertrophy
        XCTAssertTrue(ValidationHelpers.validateExerciseReps("8-12").isValid)  // Hypertrophy
        XCTAssertTrue(ValidationHelpers.validateExerciseReps("12-15").isValid) // Endurance
        XCTAssertTrue(ValidationHelpers.validateExerciseReps("15-20").isValid) // Endurance
    }

    func testValidateExerciseReps_WideRange() {
        let result = ValidationHelpers.validateExerciseReps("1-999")
        XCTAssertTrue(result.isValid)
    }

    func testValidateExerciseReps_RangeWithZeroStart() {
        let result = ValidationHelpers.validateExerciseReps("0-10")
        XCTAssertFalse(result.isValid)
    }

    func testValidateExerciseReps_RangeEndTooLarge() {
        let result = ValidationHelpers.validateExerciseReps("8-1000")
        XCTAssertFalse(result.isValid)
    }

    func testValidateExerciseReps_NonIntegerRange() {
        let result = ValidationHelpers.validateExerciseReps("8.5-12")
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Load Validation Tests (Positive Doubles)

    func testValidateLoad_ValidValue() {
        let result = ValidationHelpers.validateLoad(100.0)
        XCTAssertTrue(result.isValid)
    }

    func testValidateLoad_ZeroValue() {
        let result = ValidationHelpers.validateLoad(0.0)
        XCTAssertTrue(result.isValid) // Zero is valid (bodyweight)
    }

    func testValidateLoad_NegativeValue() {
        let result = ValidationHelpers.validateLoad(-50.0)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("negative"))
    }

    func testValidateLoad_MaxValue() {
        let result = ValidationHelpers.validateLoad(9999.0)
        XCTAssertTrue(result.isValid)
    }

    func testValidateLoad_TooLarge() {
        let result = ValidationHelpers.validateLoad(10000.0)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("9999"))
    }

    func testValidateLoad_DecimalValue() {
        let result = ValidationHelpers.validateLoad(102.5)
        XCTAssertTrue(result.isValid)
    }

    func testValidateLoad_SmallDecimal() {
        let result = ValidationHelpers.validateLoad(0.5)
        XCTAssertTrue(result.isValid)
    }

    func testValidateLoad_VeryNegative() {
        let result = ValidationHelpers.validateLoad(-1000.0)
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Load Validation Tests (String)

    func testValidateLoadString_ValidValue() {
        let result = ValidationHelpers.validateLoad("100")
        XCTAssertTrue(result.isValid)
    }

    func testValidateLoadString_Empty() {
        let result = ValidationHelpers.validateLoad("")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("empty"))
    }

    func testValidateLoadString_WhitespaceOnly() {
        let result = ValidationHelpers.validateLoad("   ")
        XCTAssertFalse(result.isValid)
    }

    func testValidateLoadString_InvalidFormat() {
        let result = ValidationHelpers.validateLoad("abc")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("number"))
    }

    func testValidateLoadString_WithWhitespace() {
        let result = ValidationHelpers.validateLoad(" 100.5 ")
        XCTAssertTrue(result.isValid)
    }

    func testValidateLoadString_WithUnits() {
        // Units should not be included
        XCTAssertFalse(ValidationHelpers.validateLoad("100lbs").isValid)
        XCTAssertFalse(ValidationHelpers.validateLoad("100 kg").isValid)
    }

    // MARK: - Exercise Weight Validation Tests

    func testValidateExerciseWeight_ValidInteger() {
        let result = ValidationHelpers.validateExerciseWeight("100")
        XCTAssertTrue(result.isValid)
    }

    func testValidateExerciseWeight_ValidDecimal() {
        let result = ValidationHelpers.validateExerciseWeight("100.5")
        XCTAssertTrue(result.isValid)
    }

    func testValidateExerciseWeight_Empty() {
        let result = ValidationHelpers.validateExerciseWeight("")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("empty"))
    }

    func testValidateExerciseWeight_InvalidFormat() {
        let result = ValidationHelpers.validateExerciseWeight("abc")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("number"))
    }

    func testValidateExerciseWeight_NegativeValue() {
        let result = ValidationHelpers.validateExerciseWeight("-50")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("negative"))
    }

    func testValidateExerciseWeight_ZeroValue() {
        let result = ValidationHelpers.validateExerciseWeight("0")
        XCTAssertTrue(result.isValid) // Zero weight is valid (bodyweight exercises)
    }

    func testValidateExerciseWeight_TooLarge() {
        let result = ValidationHelpers.validateExerciseWeight("10000")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("9999"))
    }

    func testValidateExerciseWeight_MaxValue() {
        let result = ValidationHelpers.validateExerciseWeight("9999")
        XCTAssertTrue(result.isValid)
    }

    func testValidateExerciseWeight_TooManyDecimals() {
        let result = ValidationHelpers.validateExerciseWeight("100.123")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("decimal"))
    }

    func testValidateExerciseWeight_TwoDecimalPlaces() {
        let result = ValidationHelpers.validateExerciseWeight("100.55")
        XCTAssertTrue(result.isValid)
    }

    func testValidateExerciseWeight_OneDecimalPlace() {
        let result = ValidationHelpers.validateExerciseWeight("100.5")
        XCTAssertTrue(result.isValid)
    }

    func testValidateExerciseWeight_WhitespaceOnly() {
        let result = ValidationHelpers.validateExerciseWeight("   ")
        XCTAssertFalse(result.isValid)
    }

    func testValidateExerciseWeight_SpecialCharacters() {
        XCTAssertFalse(ValidationHelpers.validateExerciseWeight("100lbs").isValid)
        XCTAssertFalse(ValidationHelpers.validateExerciseWeight("$100").isValid)
    }

    // MARK: - Body Composition Weight Validation Tests

    func testValidateBodyWeight_ValidValue() {
        let result = ValidationHelpers.validateBodyWeight(150.0)
        XCTAssertTrue(result.isValid)
    }

    func testValidateBodyWeight_ZeroValue() {
        let result = ValidationHelpers.validateBodyWeight(0.0)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("greater than 0"))
    }

    func testValidateBodyWeight_NegativeValue() {
        let result = ValidationHelpers.validateBodyWeight(-50.0)
        XCTAssertFalse(result.isValid)
    }

    func testValidateBodyWeight_MaxValue() {
        let result = ValidationHelpers.validateBodyWeight(1000.0)
        XCTAssertTrue(result.isValid)
    }

    func testValidateBodyWeight_TooLarge() {
        let result = ValidationHelpers.validateBodyWeight(1001.0)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("1000"))
    }

    func testValidateBodyWeight_DecimalValue() {
        let result = ValidationHelpers.validateBodyWeight(175.5)
        XCTAssertTrue(result.isValid)
    }

    func testValidateBodyWeight_SmallValue() {
        let result = ValidationHelpers.validateBodyWeight(1.0)
        XCTAssertTrue(result.isValid)
    }

    func testValidateBodyWeight_VerySmall() {
        let result = ValidationHelpers.validateBodyWeight(0.1)
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Body Composition Weight Validation Tests (String)

    func testValidateBodyWeightString_ValidValue() {
        let result = ValidationHelpers.validateBodyWeight("150")
        XCTAssertTrue(result.isValid)
    }

    func testValidateBodyWeightString_Empty() {
        let result = ValidationHelpers.validateBodyWeight("")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("empty"))
    }

    func testValidateBodyWeightString_WhitespaceOnly() {
        let result = ValidationHelpers.validateBodyWeight("   ")
        XCTAssertFalse(result.isValid)
    }

    func testValidateBodyWeightString_InvalidFormat() {
        let result = ValidationHelpers.validateBodyWeight("abc")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("number"))
    }

    func testValidateBodyWeightString_WithWhitespace() {
        let result = ValidationHelpers.validateBodyWeight(" 175.5 ")
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Email Validation Tests

    func testValidateEmail_ValidEmail() {
        let result = ValidationHelpers.validateEmail("test@example.com")
        XCTAssertTrue(result.isValid)
    }

    func testValidateEmail_Empty() {
        let result = ValidationHelpers.validateEmail("")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("empty"))
    }

    func testValidateEmail_NoAtSymbol() {
        let result = ValidationHelpers.validateEmail("testexample.com")
        XCTAssertFalse(result.isValid)
    }

    func testValidateEmail_NoDomain() {
        let result = ValidationHelpers.validateEmail("test@")
        XCTAssertFalse(result.isValid)
    }

    func testValidateEmail_NoTLD() {
        let result = ValidationHelpers.validateEmail("test@example")
        XCTAssertFalse(result.isValid)
    }

    func testValidateEmail_ShortTLD() {
        let result = ValidationHelpers.validateEmail("test@example.c")
        XCTAssertFalse(result.isValid)
    }

    func testValidateEmail_ValidWithSubdomain() {
        let result = ValidationHelpers.validateEmail("test@mail.example.com")
        XCTAssertTrue(result.isValid)
    }

    func testValidateEmail_ValidWithPlus() {
        let result = ValidationHelpers.validateEmail("test+label@example.com")
        XCTAssertTrue(result.isValid)
    }

    func testValidateEmail_ValidWithNumbers() {
        let result = ValidationHelpers.validateEmail("test123@example123.com")
        XCTAssertTrue(result.isValid)
    }

    func testValidateEmail_TrimsWhitespace() {
        let result = ValidationHelpers.validateEmail("  test@example.com  ")
        XCTAssertTrue(result.isValid)
    }

    func testValidateEmail_WhitespaceOnly() {
        let result = ValidationHelpers.validateEmail("   ")
        XCTAssertFalse(result.isValid)
    }

    func testValidateEmail_MultipleAtSymbols() {
        let result = ValidationHelpers.validateEmail("test@@example.com")
        XCTAssertFalse(result.isValid)
    }

    func testValidateEmail_SpecialCharactersInLocal() {
        // Valid special characters in local part
        XCTAssertTrue(ValidationHelpers.validateEmail("test.user@example.com").isValid)
        XCTAssertTrue(ValidationHelpers.validateEmail("test_user@example.com").isValid)
        XCTAssertTrue(ValidationHelpers.validateEmail("test-user@example.com").isValid)
    }

    func testValidateEmail_LongTLD() {
        let result = ValidationHelpers.validateEmail("test@example.technology")
        XCTAssertTrue(result.isValid)
    }

    func testValidateEmail_NumericDomain() {
        let result = ValidationHelpers.validateEmail("test@123.com")
        XCTAssertTrue(result.isValid)
    }

    func testValidateEmail_MissingLocal() {
        let result = ValidationHelpers.validateEmail("@example.com")
        XCTAssertFalse(result.isValid)
    }

    func testValidateEmail_SpaceInEmail() {
        let result = ValidationHelpers.validateEmail("test user@example.com")
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Phone Number Validation Tests

    func testValidatePhoneNumber_ValidUSFormat() {
        let result = ValidationHelpers.validatePhoneNumber("(555) 123-4567")
        XCTAssertTrue(result.isValid)
    }

    func testValidatePhoneNumber_ValidPlainDigits() {
        let result = ValidationHelpers.validatePhoneNumber("5551234567")
        XCTAssertTrue(result.isValid)
    }

    func testValidatePhoneNumber_ValidWithCountryCode() {
        let result = ValidationHelpers.validatePhoneNumber("+1 555 123 4567")
        XCTAssertTrue(result.isValid)
    }

    func testValidatePhoneNumber_ValidInternational() {
        let result = ValidationHelpers.validatePhoneNumber("+44 20 7946 0958")
        XCTAssertTrue(result.isValid)
    }

    func testValidatePhoneNumber_Empty() {
        let result = ValidationHelpers.validatePhoneNumber("")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("empty"))
    }

    func testValidatePhoneNumber_WhitespaceOnly() {
        let result = ValidationHelpers.validatePhoneNumber("   ")
        XCTAssertFalse(result.isValid)
    }

    func testValidatePhoneNumber_TooShort() {
        let result = ValidationHelpers.validatePhoneNumber("12345")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("10"))
    }

    func testValidatePhoneNumber_TooLong() {
        let result = ValidationHelpers.validatePhoneNumber("1234567890123456")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("15"))
    }

    func testValidatePhoneNumber_InvalidCharacters() {
        // Use enough digits (10+) so it passes digit count check first, then fails on invalid chars
        // "555-ABC-1234567" has 10 digits but contains letters A, B, C which are invalid
        let result = ValidationHelpers.validatePhoneNumber("555-ABC-1234567")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("invalid"), "Should fail on invalid characters")
    }

    func testValidatePhoneNumber_SpecialCharactersOnly() {
        let result = ValidationHelpers.validatePhoneNumber("()-+. ")
        XCTAssertFalse(result.isValid)
    }

    func testValidatePhoneNumber_ValidWithDashes() {
        let result = ValidationHelpers.validatePhoneNumber("555-123-4567")
        XCTAssertTrue(result.isValid)
    }

    func testValidatePhoneNumber_ValidWithDots() {
        let result = ValidationHelpers.validatePhoneNumber("555.123.4567")
        XCTAssertTrue(result.isValid)
    }

    func testValidatePhoneNumber_ValidWithSpaces() {
        let result = ValidationHelpers.validatePhoneNumber("555 123 4567")
        XCTAssertTrue(result.isValid)
    }

    func testValidatePhoneNumber_ExactlyTenDigits() {
        let result = ValidationHelpers.validatePhoneNumber("5551234567")
        XCTAssertTrue(result.isValid)
    }

    func testValidatePhoneNumber_ExactlyFifteenDigits() {
        let result = ValidationHelpers.validatePhoneNumber("123456789012345")
        XCTAssertTrue(result.isValid)
    }

    func testValidatePhoneNumber_WithLeadingPlus() {
        let result = ValidationHelpers.validatePhoneNumber("+15551234567")
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Date Range Validation Tests

    func testValidateDateRange_ValidRange() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(86400) // 1 day later
        let result = ValidationHelpers.validateDateRange(startDate: startDate, endDate: endDate)
        XCTAssertTrue(result.isValid)
    }

    func testValidateDateRange_SameDate() {
        let date = Date()
        let result = ValidationHelpers.validateDateRange(startDate: date, endDate: date)
        XCTAssertTrue(result.isValid)
    }

    func testValidateDateRange_EndBeforeStart() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(-86400) // 1 day before
        let result = ValidationHelpers.validateDateRange(startDate: startDate, endDate: endDate)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("before"))
    }

    func testValidateDateRange_LongRange() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(86400 * 365) // 1 year later
        let result = ValidationHelpers.validateDateRange(startDate: startDate, endDate: endDate)
        XCTAssertTrue(result.isValid)
    }

    func testValidateDateRange_WithMaxDays_Valid() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(86400 * 7) // 7 days later
        let result = ValidationHelpers.validateDateRange(startDate: startDate, endDate: endDate, maxDays: 30)
        XCTAssertTrue(result.isValid)
    }

    func testValidateDateRange_WithMaxDays_ExceedsMax() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(86400 * 31) // 31 days later
        let result = ValidationHelpers.validateDateRange(startDate: startDate, endDate: endDate, maxDays: 30)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("30"))
    }

    func testValidateDateRange_WithMaxDays_ExactlyMax() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(86400 * 30) // 30 days later
        let result = ValidationHelpers.validateDateRange(startDate: startDate, endDate: endDate, maxDays: 30)
        XCTAssertTrue(result.isValid)
    }

    func testValidateDateRange_WithMaxDays_EndBeforeStart() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(-86400) // 1 day before
        let result = ValidationHelpers.validateDateRange(startDate: startDate, endDate: endDate, maxDays: 30)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("before"))
    }

    func testValidateDateRange_VeryShortRange() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(1) // 1 second later
        let result = ValidationHelpers.validateDateRange(startDate: startDate, endDate: endDate)
        XCTAssertTrue(result.isValid)
    }

    // MARK: - UUID Validation Tests

    func testValidateUUID_ValidUUID() {
        let result = ValidationHelpers.validateUUID("550e8400-e29b-41d4-a716-446655440000")
        XCTAssertTrue(result.isValid)
    }

    func testValidateUUID_ValidUppercase() {
        let result = ValidationHelpers.validateUUID("550E8400-E29B-41D4-A716-446655440000")
        XCTAssertTrue(result.isValid)
    }

    func testValidateUUID_ValidMixedCase() {
        let result = ValidationHelpers.validateUUID("550e8400-E29B-41d4-A716-446655440000")
        XCTAssertTrue(result.isValid)
    }

    func testValidateUUID_Empty() {
        let result = ValidationHelpers.validateUUID("")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("empty"))
    }

    func testValidateUUID_WhitespaceOnly() {
        let result = ValidationHelpers.validateUUID("   ")
        XCTAssertFalse(result.isValid)
    }

    func testValidateUUID_InvalidFormat() {
        let result = ValidationHelpers.validateUUID("not-a-valid-uuid")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("Invalid"))
    }

    func testValidateUUID_TooShort() {
        let result = ValidationHelpers.validateUUID("550e8400-e29b-41d4-a716")
        XCTAssertFalse(result.isValid)
    }

    func testValidateUUID_TooLong() {
        let result = ValidationHelpers.validateUUID("550e8400-e29b-41d4-a716-446655440000-extra")
        XCTAssertFalse(result.isValid)
    }

    func testValidateUUID_NoDashes() {
        let result = ValidationHelpers.validateUUID("550e8400e29b41d4a716446655440000")
        XCTAssertFalse(result.isValid)
    }

    func testValidateUUID_WithWhitespace() {
        let result = ValidationHelpers.validateUUID(" 550e8400-e29b-41d4-a716-446655440000 ")
        XCTAssertTrue(result.isValid)
    }

    func testValidateUUID_InvalidCharacters() {
        let result = ValidationHelpers.validateUUID("550e8400-e29b-41d4-a716-44665544000g")
        XCTAssertFalse(result.isValid)
    }

    func testValidateUUID_RandomValid() {
        // Generate and validate a random UUID
        let uuid = UUID().uuidString
        let result = ValidationHelpers.validateUUID(uuid)
        XCTAssertTrue(result.isValid)
    }

    func testValidateUUID_AllZeros() {
        let result = ValidationHelpers.validateUUID("00000000-0000-0000-0000-000000000000")
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Password Validation Tests

    func testValidatePassword_ValidPassword() {
        let result = ValidationHelpers.validatePassword("Password123")
        XCTAssertTrue(result.isValid)
    }

    func testValidatePassword_Empty() {
        let result = ValidationHelpers.validatePassword("")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("empty"))
    }

    func testValidatePassword_TooShort() {
        let result = ValidationHelpers.validatePassword("Pass1")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("8"))
    }

    func testValidatePassword_MinimumLength() {
        let result = ValidationHelpers.validatePassword("Passwor1")
        XCTAssertTrue(result.isValid)
    }

    func testValidatePassword_NoUppercase() {
        let result = ValidationHelpers.validatePassword("password123")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("uppercase"))
    }

    func testValidatePassword_NoNumber() {
        let result = ValidationHelpers.validatePassword("PasswordABC")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("number"))
    }

    func testValidatePassword_AllCriteriaMet() {
        let result = ValidationHelpers.validatePassword("SecurePass99")
        XCTAssertTrue(result.isValid)
    }

    func testValidatePassword_WithSpecialCharacters() {
        let result = ValidationHelpers.validatePassword("Password1!")
        XCTAssertTrue(result.isValid)
    }

    func testValidatePassword_AllUppercase() {
        let result = ValidationHelpers.validatePassword("PASSWORD123")
        XCTAssertTrue(result.isValid)
    }

    func testValidatePassword_VeryLong() {
        let longPassword = "Password1" + String(repeating: "a", count: 100)
        let result = ValidationHelpers.validatePassword(longPassword)
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Not Empty Validation Tests

    func testValidateNotEmpty_ValidText() {
        let result = ValidationHelpers.validateNotEmpty("Hello", fieldName: "Test")
        XCTAssertTrue(result.isValid)
    }

    func testValidateNotEmpty_EmptyText() {
        let result = ValidationHelpers.validateNotEmpty("", fieldName: "Test")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("Test"))
    }

    func testValidateNotEmpty_WhitespaceOnly() {
        let result = ValidationHelpers.validateNotEmpty("   ", fieldName: "Username")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("Username"))
    }

    func testValidateNotEmpty_DefaultFieldName() {
        let result = ValidationHelpers.validateNotEmpty("")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("Field"))
    }

    func testValidateNotEmpty_SingleCharacter() {
        let result = ValidationHelpers.validateNotEmpty("a", fieldName: "Test")
        XCTAssertTrue(result.isValid)
    }

    func testValidateNotEmpty_Newlines() {
        let result = ValidationHelpers.validateNotEmpty("\n\n", fieldName: "Test")
        XCTAssertFalse(result.isValid)
    }

    func testValidateNotEmpty_Tabs() {
        let result = ValidationHelpers.validateNotEmpty("\t\t", fieldName: "Test")
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Length Validation Tests

    func testValidateLength_ValidLength() {
        let result = ValidationHelpers.validateLength("Hello", minLength: 3, maxLength: 10)
        XCTAssertTrue(result.isValid)
    }

    func testValidateLength_TooShort() {
        let result = ValidationHelpers.validateLength("Hi", minLength: 3, maxLength: 10, fieldName: "Text")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("Text"))
        XCTAssertTrue(result.errorMessage!.contains("3"))
    }

    func testValidateLength_TooLong() {
        let result = ValidationHelpers.validateLength("Hello World!", minLength: 3, maxLength: 10, fieldName: "Text")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("10"))
    }

    func testValidateLength_ExactMinimum() {
        let result = ValidationHelpers.validateLength("ABC", minLength: 3, maxLength: 10)
        XCTAssertTrue(result.isValid)
    }

    func testValidateLength_ExactMaximum() {
        let result = ValidationHelpers.validateLength("ABCDEFGHIJ", minLength: 3, maxLength: 10)
        XCTAssertTrue(result.isValid)
    }

    func testValidateLength_TrimsWhitespace() {
        let result = ValidationHelpers.validateLength("  AB  ", minLength: 3, maxLength: 10)
        XCTAssertFalse(result.isValid) // After trimming, only "AB" which is 2 chars
    }

    func testValidateLength_EmptyWithZeroMin() {
        let result = ValidationHelpers.validateLength("", minLength: 0, maxLength: 10)
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Range Validation Tests

    func testValidateRange_ValidValue() {
        let result = ValidationHelpers.validateRange(5, min: 1, max: 10)
        XCTAssertTrue(result.isValid)
    }

    func testValidateRange_AtMinimum() {
        let result = ValidationHelpers.validateRange(1, min: 1, max: 10)
        XCTAssertTrue(result.isValid)
    }

    func testValidateRange_AtMaximum() {
        let result = ValidationHelpers.validateRange(10, min: 1, max: 10)
        XCTAssertTrue(result.isValid)
    }

    func testValidateRange_BelowMinimum() {
        let result = ValidationHelpers.validateRange(0, min: 1, max: 10, fieldName: "Value")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("Value"))
    }

    func testValidateRange_AboveMaximum() {
        let result = ValidationHelpers.validateRange(11, min: 1, max: 10, fieldName: "Count")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("Count"))
    }

    func testValidateRange_WithDoubles() {
        let result = ValidationHelpers.validateRange(5.5, min: 1.0, max: 10.0)
        XCTAssertTrue(result.isValid)
    }

    func testValidateRange_WithNegatives() {
        let result = ValidationHelpers.validateRange(-5, min: -10, max: 0)
        XCTAssertTrue(result.isValid)
    }

    func testValidateRange_VeryLargeNumbers() {
        let result = ValidationHelpers.validateRange(500000, min: 0, max: 1000000)
        XCTAssertTrue(result.isValid)
    }

    func testValidateRange_VerySmallDecimals() {
        let result = ValidationHelpers.validateRange(0.001, min: 0.0, max: 1.0)
        XCTAssertTrue(result.isValid)
    }

    // MARK: - ValidationResult Tests

    func testValidationResult_Valid_IsValid() {
        let result = ValidationResult.valid
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func testValidationResult_Invalid_IsNotValid() {
        let result = ValidationResult.invalid("Error message")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Error message")
    }

    func testValidationResult_Equatable() {
        XCTAssertEqual(ValidationResult.valid, ValidationResult.valid)
        XCTAssertEqual(ValidationResult.invalid("Error"), ValidationResult.invalid("Error"))
        XCTAssertNotEqual(ValidationResult.valid, ValidationResult.invalid("Error"))
        XCTAssertNotEqual(ValidationResult.invalid("Error1"), ValidationResult.invalid("Error2"))
    }

    func testValidationResult_EmptyErrorMessage() {
        let result = ValidationResult.invalid("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "")
    }

    // MARK: - Edge Case Tests

    func testEdgeCase_VeryLongString() {
        let veryLongString = String(repeating: "a", count: 10000)
        let result = ValidationHelpers.validateProgramName(veryLongString)
        XCTAssertFalse(result.isValid)
    }

    func testEdgeCase_UnicodeCharacters() {
        let result = ValidationHelpers.validateNotEmpty("Hello", fieldName: "Test")
        XCTAssertTrue(result.isValid)
    }

    func testEdgeCase_EmojiInName() {
        let result = ValidationHelpers.validateProgramName("Workout Plan")
        XCTAssertTrue(result.isValid)
    }

    func testEdgeCase_NullCharacter() {
        let result = ValidationHelpers.validateProgramName("Test\0Name")
        // Should still be valid as it contains non-whitespace characters
        XCTAssertTrue(result.isValid)
    }
}
