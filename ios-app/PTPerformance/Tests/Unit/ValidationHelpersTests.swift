//
//  ValidationHelpersTests.swift
//  PTPerformanceTests
//
//  Unit tests for ValidationHelpers utility
//  Tests form validation logic for various input types
//

import XCTest
@testable import PTPerformance

final class ValidationHelpersUnitTests: XCTestCase {

    // MARK: - ValidationResult Tests

    func testValidationResultIsValid() {
        let valid = ValidationResult.valid
        let invalid = ValidationResult.invalid("Error message")

        XCTAssertTrue(valid.isValid)
        XCTAssertFalse(invalid.isValid)
    }

    func testValidationResultErrorMessage() {
        let valid = ValidationResult.valid
        let invalid = ValidationResult.invalid("Error message")

        XCTAssertNil(valid.errorMessage)
        XCTAssertEqual(invalid.errorMessage, "Error message")
    }

    func testValidationResultEquatable() {
        XCTAssertEqual(ValidationResult.valid, ValidationResult.valid)
        XCTAssertEqual(
            ValidationResult.invalid("Error"),
            ValidationResult.invalid("Error")
        )
        XCTAssertNotEqual(
            ValidationResult.valid,
            ValidationResult.invalid("Error")
        )
        XCTAssertNotEqual(
            ValidationResult.invalid("Error 1"),
            ValidationResult.invalid("Error 2")
        )
    }

    // MARK: - Program Name Validation Tests

    func testValidateProgramNameValid() {
        let result = ValidationHelpers.validateProgramName("Upper Body Strength")
        XCTAssertTrue(result.isValid)
    }

    func testValidateProgramNameEmpty() {
        let result = ValidationHelpers.validateProgramName("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Program name cannot be empty")
    }

    func testValidateProgramNameWhitespaceOnly() {
        let result = ValidationHelpers.validateProgramName("   ")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Program name cannot be empty")
    }

    func testValidateProgramNameTooShort() {
        let result = ValidationHelpers.validateProgramName("Ab")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Program name must be at least 3 characters")
    }

    func testValidateProgramNameTooLong() {
        let longName = String(repeating: "a", count: 101)
        let result = ValidationHelpers.validateProgramName(longName)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Program name must be 100 characters or less")
    }

    func testValidateProgramNameBoundary() {
        // Exactly 3 characters should be valid
        let threeChars = ValidationHelpers.validateProgramName("Abs")
        XCTAssertTrue(threeChars.isValid)

        // Exactly 100 characters should be valid
        let hundredChars = ValidationHelpers.validateProgramName(String(repeating: "a", count: 100))
        XCTAssertTrue(hundredChars.isValid)
    }

    // MARK: - RPE Validation Tests (1-10 Scale - Double)

    func testValidateRPEDoubleValid() {
        let result = ValidationHelpers.validateRPE(7.5)
        XCTAssertTrue(result.isValid)
    }

    func testValidateRPEDoubleBoundaries() {
        let zero = ValidationHelpers.validateRPE(0.0)
        XCTAssertTrue(zero.isValid)

        let ten = ValidationHelpers.validateRPE(10.0)
        XCTAssertTrue(ten.isValid)
    }

    func testValidateRPEDoubleNegative() {
        let result = ValidationHelpers.validateRPE(-1.0)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "RPE must be between 0 and 10")
    }

    func testValidateRPEDoubleAboveTen() {
        let result = ValidationHelpers.validateRPE(11.0)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "RPE must be between 0 and 10")
    }

    func testValidateRPEDoubleVeryNegative() {
        let result = ValidationHelpers.validateRPE(-100.0)
        XCTAssertFalse(result.isValid)
    }

    func testValidateRPEDoubleVeryLarge() {
        let result = ValidationHelpers.validateRPE(1000.0)
        XCTAssertFalse(result.isValid)
    }

    func testValidateRPEDoubleHalfValues() {
        // RPE is often expressed in 0.5 increments
        for rpe in stride(from: 0.5, through: 9.5, by: 1.0) {
            XCTAssertTrue(ValidationHelpers.validateRPE(rpe).isValid)
        }
    }

    // MARK: - RPE Validation Tests (1-10 Scale - String)

    func testValidateRPEStringValid() {
        let result = ValidationHelpers.validateRPE("8.5")
        XCTAssertTrue(result.isValid)
    }

    func testValidateRPEStringEmpty() {
        let result = ValidationHelpers.validateRPE("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "RPE cannot be empty")
    }

    func testValidateRPEStringNotNumber() {
        let result = ValidationHelpers.validateRPE("hard")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "RPE must be a number")
    }

    func testValidateRPEStringOutOfRange() {
        let result = ValidationHelpers.validateRPE("15")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "RPE must be between 0 and 10")
    }

    func testValidateRPEStringWhitespaceOnly() {
        let result = ValidationHelpers.validateRPE("   ")
        XCTAssertFalse(result.isValid)
    }

    func testValidateRPEStringWithWhitespace() {
        let result = ValidationHelpers.validateRPE(" 8.5 ")
        XCTAssertTrue(result.isValid)
    }

    func testValidateRPEStringSpecialCharacters() {
        XCTAssertFalse(ValidationHelpers.validateRPE("8@").isValid)
        XCTAssertFalse(ValidationHelpers.validateRPE("RPE8").isValid)
    }

    // MARK: - Pain Score Validation Tests (0-10 Scale)

    func testValidatePainScoreIntValid() {
        let result = ValidationHelpers.validatePainScore(5)
        XCTAssertTrue(result.isValid)
    }

    func testValidatePainScoreIntBoundaries() {
        XCTAssertTrue(ValidationHelpers.validatePainScore(0).isValid)
        XCTAssertTrue(ValidationHelpers.validatePainScore(10).isValid)
    }

    func testValidatePainScoreIntNegative() {
        let result = ValidationHelpers.validatePainScore(-1)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Pain score must be between 0 and 10")
    }

    func testValidatePainScoreIntAboveTen() {
        let result = ValidationHelpers.validatePainScore(11)
        XCTAssertFalse(result.isValid)
    }

    func testValidatePainScoreIntVeryNegative() {
        let result = ValidationHelpers.validatePainScore(-100)
        XCTAssertFalse(result.isValid)
    }

    func testValidatePainScoreIntVeryLarge() {
        let result = ValidationHelpers.validatePainScore(1000)
        XCTAssertFalse(result.isValid)
    }

    func testValidatePainScoreStringValid() {
        let result = ValidationHelpers.validatePainScore("5")
        XCTAssertTrue(result.isValid)
    }

    func testValidatePainScoreStringEmpty() {
        let result = ValidationHelpers.validatePainScore("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Pain score cannot be empty")
    }

    func testValidatePainScoreStringNotInteger() {
        let result = ValidationHelpers.validatePainScore("abc")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Pain score must be an integer")
    }

    func testValidatePainScoreStringDecimal() {
        // Pain scores should be integers
        let result = ValidationHelpers.validatePainScore("5.5")
        XCTAssertFalse(result.isValid)
    }

    func testValidatePainScoreStringWithWhitespace() {
        let result = ValidationHelpers.validatePainScore(" 5 ")
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Sets Validation Tests (Positive Integers)

    func testValidateSetsIntValid() {
        let result = ValidationHelpers.validateSets(3)
        XCTAssertTrue(result.isValid)
    }

    func testValidateSetsIntBoundaries() {
        XCTAssertTrue(ValidationHelpers.validateSets(1).isValid)
        XCTAssertTrue(ValidationHelpers.validateSets(99).isValid)
    }

    func testValidateSetsIntZero() {
        let result = ValidationHelpers.validateSets(0)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Sets must be at least 1")
    }

    func testValidateSetsIntNegative() {
        let result = ValidationHelpers.validateSets(-5)
        XCTAssertFalse(result.isValid)
    }

    func testValidateSetsIntTooLarge() {
        let result = ValidationHelpers.validateSets(100)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Sets must be 99 or less")
    }

    func testValidateSetsStringValid() {
        let result = ValidationHelpers.validateSets("3")
        XCTAssertTrue(result.isValid)
    }

    func testValidateSetsStringEmpty() {
        let result = ValidationHelpers.validateSets("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Sets cannot be empty")
    }

    func testValidateSetsStringNotInteger() {
        let result = ValidationHelpers.validateSets("abc")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Sets must be an integer")
    }

    func testValidateSetsStringDecimal() {
        let result = ValidationHelpers.validateSets("3.5")
        XCTAssertFalse(result.isValid)
    }

    func testValidateSetsStringWithWhitespace() {
        let result = ValidationHelpers.validateSets(" 4 ")
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Reps Validation Tests (Positive Integers)

    func testValidateRepsIntValid() {
        let result = ValidationHelpers.validateReps(10)
        XCTAssertTrue(result.isValid)
    }

    func testValidateRepsIntBoundaries() {
        XCTAssertTrue(ValidationHelpers.validateReps(1).isValid)
        XCTAssertTrue(ValidationHelpers.validateReps(999).isValid)
    }

    func testValidateRepsIntZero() {
        let result = ValidationHelpers.validateReps(0)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Reps must be at least 1")
    }

    func testValidateRepsIntNegative() {
        let result = ValidationHelpers.validateReps(-5)
        XCTAssertFalse(result.isValid)
    }

    func testValidateRepsIntTooLarge() {
        let result = ValidationHelpers.validateReps(1000)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Reps must be 999 or less")
    }

    // MARK: - Exercise Reps Validation Tests (String - Ranges like "8-10")

    func testValidateExerciseRepsValidSingleValue() {
        let result = ValidationHelpers.validateExerciseReps("10")
        XCTAssertTrue(result.isValid)
    }

    func testValidateExerciseRepsValidRange() {
        let result = ValidationHelpers.validateExerciseReps("8-12")
        XCTAssertTrue(result.isValid)
    }

    func testValidateExerciseRepsEmpty() {
        let result = ValidationHelpers.validateExerciseReps("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Reps cannot be empty")
    }

    func testValidateExerciseRepsInvalidRangeFormat() {
        let result = ValidationHelpers.validateExerciseReps("8-12-15")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Range must be in format like 8-12")
    }

    func testValidateExerciseRepsNonIntegerRange() {
        let result = ValidationHelpers.validateExerciseReps("a-b")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Range values must be integers")
    }

    func testValidateExerciseRepsRangeBelowOne() {
        let result = ValidationHelpers.validateExerciseReps("0-5")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Reps must be at least 1")
    }

    func testValidateExerciseRepsRangeAboveMax() {
        let result = ValidationHelpers.validateExerciseReps("8-1000")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Reps must be 999 or less")
    }

    func testValidateExerciseRepsRangeStartNotLessThanEnd() {
        let result = ValidationHelpers.validateExerciseReps("12-8")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Range start must be less than end")

        let equal = ValidationHelpers.validateExerciseReps("10-10")
        XCTAssertFalse(equal.isValid)
        XCTAssertEqual(equal.errorMessage, "Range start must be less than end")
    }

    func testValidateExerciseRepsSingleValueNotInteger() {
        let result = ValidationHelpers.validateExerciseReps("ten")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Reps must be an integer or range (e.g., 8-12)")
    }

    func testValidateExerciseRepsSingleValueBelowOne() {
        let result = ValidationHelpers.validateExerciseReps("0")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Reps must be at least 1")
    }

    func testValidateExerciseRepsSingleValueAboveMax() {
        let result = ValidationHelpers.validateExerciseReps("1000")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Reps must be 999 or less")
    }

    func testValidateExerciseRepsCommonRanges() {
        XCTAssertTrue(ValidationHelpers.validateExerciseReps("1-3").isValid)
        XCTAssertTrue(ValidationHelpers.validateExerciseReps("3-5").isValid)
        XCTAssertTrue(ValidationHelpers.validateExerciseReps("6-8").isValid)
        XCTAssertTrue(ValidationHelpers.validateExerciseReps("8-12").isValid)
        XCTAssertTrue(ValidationHelpers.validateExerciseReps("12-15").isValid)
    }

    func testValidateExerciseRepsWithWhitespace() {
        let result = ValidationHelpers.validateExerciseReps(" 8-12 ")
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Load Validation Tests (Positive Doubles)

    func testValidateLoadDoubleValid() {
        let result = ValidationHelpers.validateLoad(100.0)
        XCTAssertTrue(result.isValid)
    }

    func testValidateLoadDoubleZero() {
        let result = ValidationHelpers.validateLoad(0.0)
        XCTAssertTrue(result.isValid) // Zero is valid (bodyweight)
    }

    func testValidateLoadDoubleNegative() {
        let result = ValidationHelpers.validateLoad(-50.0)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Load cannot be negative")
    }

    func testValidateLoadDoubleBoundary() {
        XCTAssertTrue(ValidationHelpers.validateLoad(9999.0).isValid)
        XCTAssertFalse(ValidationHelpers.validateLoad(10000.0).isValid)
    }

    func testValidateLoadStringValid() {
        let result = ValidationHelpers.validateLoad("100")
        XCTAssertTrue(result.isValid)
    }

    func testValidateLoadStringEmpty() {
        let result = ValidationHelpers.validateLoad("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Load cannot be empty")
    }

    func testValidateLoadStringNotNumber() {
        let result = ValidationHelpers.validateLoad("abc")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Load must be a valid number")
    }

    func testValidateLoadStringWithWhitespace() {
        let result = ValidationHelpers.validateLoad(" 100.5 ")
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Exercise Weight Validation Tests

    func testValidateExerciseWeightValid() {
        let result = ValidationHelpers.validateExerciseWeight("185.5")
        XCTAssertTrue(result.isValid)
    }

    func testValidateExerciseWeightValidInteger() {
        let result = ValidationHelpers.validateExerciseWeight("200")
        XCTAssertTrue(result.isValid)
    }

    func testValidateExerciseWeightEmpty() {
        let result = ValidationHelpers.validateExerciseWeight("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Weight cannot be empty")
    }

    func testValidateExerciseWeightNotNumber() {
        let result = ValidationHelpers.validateExerciseWeight("heavy")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Weight must be a valid number")
    }

    func testValidateExerciseWeightNegative() {
        let result = ValidationHelpers.validateExerciseWeight("-50")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Weight cannot be negative")
    }

    func testValidateExerciseWeightTooLarge() {
        let result = ValidationHelpers.validateExerciseWeight("10000")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Weight must be 9999 or less")
    }

    func testValidateExerciseWeightTooManyDecimals() {
        let result = ValidationHelpers.validateExerciseWeight("185.555")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Weight can have at most 2 decimal places")
    }

    func testValidateExerciseWeightZero() {
        // Zero should be valid (bodyweight exercises)
        let result = ValidationHelpers.validateExerciseWeight("0")
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Body Composition Weight Validation Tests

    func testValidateBodyWeightDoubleValid() {
        let result = ValidationHelpers.validateBodyWeight(150.0)
        XCTAssertTrue(result.isValid)
    }

    func testValidateBodyWeightDoubleZero() {
        let result = ValidationHelpers.validateBodyWeight(0.0)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Weight must be greater than 0")
    }

    func testValidateBodyWeightDoubleNegative() {
        let result = ValidationHelpers.validateBodyWeight(-50.0)
        XCTAssertFalse(result.isValid)
    }

    func testValidateBodyWeightDoubleBoundary() {
        XCTAssertTrue(ValidationHelpers.validateBodyWeight(1000.0).isValid)
        XCTAssertFalse(ValidationHelpers.validateBodyWeight(1001.0).isValid)
    }

    func testValidateBodyWeightStringValid() {
        let result = ValidationHelpers.validateBodyWeight("150")
        XCTAssertTrue(result.isValid)
    }

    func testValidateBodyWeightStringEmpty() {
        let result = ValidationHelpers.validateBodyWeight("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Weight cannot be empty")
    }

    func testValidateBodyWeightStringNotNumber() {
        let result = ValidationHelpers.validateBodyWeight("abc")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Weight must be a valid number")
    }

    // MARK: - Email Validation Tests

    func testValidateEmailValid() {
        let result = ValidationHelpers.validateEmail("user@example.com")
        XCTAssertTrue(result.isValid)
    }

    func testValidateEmailValidWithSubdomain() {
        let result = ValidationHelpers.validateEmail("user@mail.example.com")
        XCTAssertTrue(result.isValid)
    }

    func testValidateEmailValidWithPlus() {
        let result = ValidationHelpers.validateEmail("user+tag@example.com")
        XCTAssertTrue(result.isValid)
    }

    func testValidateEmailEmpty() {
        let result = ValidationHelpers.validateEmail("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Email cannot be empty")
    }

    func testValidateEmailNoAtSymbol() {
        let result = ValidationHelpers.validateEmail("userexample.com")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Please enter a valid email address")
    }

    func testValidateEmailNoDomain() {
        let result = ValidationHelpers.validateEmail("user@")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Please enter a valid email address")
    }

    func testValidateEmailNoTLD() {
        let result = ValidationHelpers.validateEmail("user@example")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Please enter a valid email address")
    }

    func testValidateEmailTrimsWhitespace() {
        let result = ValidationHelpers.validateEmail("  user@example.com  ")
        XCTAssertTrue(result.isValid)
    }

    func testValidateEmailMultipleAtSymbols() {
        let result = ValidationHelpers.validateEmail("user@@example.com")
        XCTAssertFalse(result.isValid)
    }

    func testValidateEmailSpaceInEmail() {
        let result = ValidationHelpers.validateEmail("user name@example.com")
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Phone Number Validation Tests

    func testValidatePhoneNumberValidUSFormat() {
        let result = ValidationHelpers.validatePhoneNumber("(555) 123-4567")
        XCTAssertTrue(result.isValid)
    }

    func testValidatePhoneNumberValidPlainDigits() {
        let result = ValidationHelpers.validatePhoneNumber("5551234567")
        XCTAssertTrue(result.isValid)
    }

    func testValidatePhoneNumberValidWithCountryCode() {
        let result = ValidationHelpers.validatePhoneNumber("+1 555 123 4567")
        XCTAssertTrue(result.isValid)
    }

    func testValidatePhoneNumberEmpty() {
        let result = ValidationHelpers.validatePhoneNumber("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Phone number cannot be empty")
    }

    func testValidatePhoneNumberTooShort() {
        let result = ValidationHelpers.validatePhoneNumber("12345")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("10"))
    }

    func testValidatePhoneNumberTooLong() {
        let result = ValidationHelpers.validatePhoneNumber("1234567890123456")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("15"))
    }

    func testValidatePhoneNumberInvalidCharacters() {
        let result = ValidationHelpers.validatePhoneNumber("555-ABC-1234")
        XCTAssertFalse(result.isValid)
    }

    func testValidatePhoneNumberValidFormats() {
        XCTAssertTrue(ValidationHelpers.validatePhoneNumber("555-123-4567").isValid)
        XCTAssertTrue(ValidationHelpers.validatePhoneNumber("555.123.4567").isValid)
        XCTAssertTrue(ValidationHelpers.validatePhoneNumber("555 123 4567").isValid)
        XCTAssertTrue(ValidationHelpers.validatePhoneNumber("+15551234567").isValid)
    }

    // MARK: - Date Range Validation Tests

    func testValidateDateRangeValid() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(86400)
        let result = ValidationHelpers.validateDateRange(startDate: startDate, endDate: endDate)
        XCTAssertTrue(result.isValid)
    }

    func testValidateDateRangeSameDate() {
        let date = Date()
        let result = ValidationHelpers.validateDateRange(startDate: date, endDate: date)
        XCTAssertTrue(result.isValid)
    }

    func testValidateDateRangeEndBeforeStart() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(-86400)
        let result = ValidationHelpers.validateDateRange(startDate: startDate, endDate: endDate)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("before"))
    }

    func testValidateDateRangeWithMaxDaysValid() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(86400 * 7)
        let result = ValidationHelpers.validateDateRange(startDate: startDate, endDate: endDate, maxDays: 30)
        XCTAssertTrue(result.isValid)
    }

    func testValidateDateRangeWithMaxDaysExceedsMax() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(86400 * 31)
        let result = ValidationHelpers.validateDateRange(startDate: startDate, endDate: endDate, maxDays: 30)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("30"))
    }

    // MARK: - UUID Validation Tests

    func testValidateUUIDValid() {
        let result = ValidationHelpers.validateUUID("550e8400-e29b-41d4-a716-446655440000")
        XCTAssertTrue(result.isValid)
    }

    func testValidateUUIDValidUppercase() {
        let result = ValidationHelpers.validateUUID("550E8400-E29B-41D4-A716-446655440000")
        XCTAssertTrue(result.isValid)
    }

    func testValidateUUIDEmpty() {
        let result = ValidationHelpers.validateUUID("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "UUID cannot be empty")
    }

    func testValidateUUIDInvalidFormat() {
        let result = ValidationHelpers.validateUUID("not-a-valid-uuid")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("Invalid"))
    }

    func testValidateUUIDTooShort() {
        let result = ValidationHelpers.validateUUID("550e8400-e29b-41d4-a716")
        XCTAssertFalse(result.isValid)
    }

    func testValidateUUIDWithWhitespace() {
        let result = ValidationHelpers.validateUUID(" 550e8400-e29b-41d4-a716-446655440000 ")
        XCTAssertTrue(result.isValid)
    }

    func testValidateUUIDRandomValid() {
        let uuid = UUID().uuidString
        let result = ValidationHelpers.validateUUID(uuid)
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Password Validation Tests

    func testValidatePasswordValid() {
        let result = ValidationHelpers.validatePassword("SecurePass1")
        XCTAssertTrue(result.isValid)
    }

    func testValidatePasswordEmpty() {
        let result = ValidationHelpers.validatePassword("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Password cannot be empty")
    }

    func testValidatePasswordTooShort() {
        let result = ValidationHelpers.validatePassword("Pass1")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Password must be at least 8 characters")
    }

    func testValidatePasswordNoUppercase() {
        let result = ValidationHelpers.validatePassword("password1")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Password must contain at least 1 uppercase letter")
    }

    func testValidatePasswordNoNumber() {
        let result = ValidationHelpers.validatePassword("Password")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Password must contain at least 1 number")
    }

    func testValidatePasswordBoundary() {
        // Exactly 8 characters with uppercase and number
        let result = ValidationHelpers.validatePassword("Secure1!")
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Not Empty Validation Tests

    func testValidateNotEmptyValid() {
        let result = ValidationHelpers.validateNotEmpty("Hello", fieldName: "Greeting")
        XCTAssertTrue(result.isValid)
    }

    func testValidateNotEmptyEmpty() {
        let result = ValidationHelpers.validateNotEmpty("", fieldName: "Username")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Username cannot be empty")
    }

    func testValidateNotEmptyWhitespaceOnly() {
        let result = ValidationHelpers.validateNotEmpty("   ", fieldName: "Bio")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Bio cannot be empty")
    }

    func testValidateNotEmptyDefaultFieldName() {
        let result = ValidationHelpers.validateNotEmpty("")
        XCTAssertEqual(result.errorMessage, "Field cannot be empty")
    }

    // MARK: - Length Validation Tests

    func testValidateLengthValid() {
        let result = ValidationHelpers.validateLength("Hello", minLength: 3, maxLength: 10, fieldName: "Name")
        XCTAssertTrue(result.isValid)
    }

    func testValidateLengthTooShort() {
        let result = ValidationHelpers.validateLength("Hi", minLength: 3, maxLength: 10, fieldName: "Name")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Name must be at least 3 characters")
    }

    func testValidateLengthTooLong() {
        let result = ValidationHelpers.validateLength("Hello World!", minLength: 3, maxLength: 10, fieldName: "Name")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Name must be 10 characters or less")
    }

    func testValidateLengthBoundaries() {
        // Exactly minimum
        let min = ValidationHelpers.validateLength("abc", minLength: 3, maxLength: 10)
        XCTAssertTrue(min.isValid)

        // Exactly maximum
        let max = ValidationHelpers.validateLength("abcdefghij", minLength: 3, maxLength: 10)
        XCTAssertTrue(max.isValid)
    }

    // MARK: - Range Validation Tests

    func testValidateRangeValid() {
        let result = ValidationHelpers.validateRange(50, min: 1, max: 100, fieldName: "Age")
        XCTAssertTrue(result.isValid)
    }

    func testValidateRangeBelowMin() {
        let result = ValidationHelpers.validateRange(0, min: 1, max: 100, fieldName: "Age")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Age must be between 1 and 100")
    }

    func testValidateRangeAboveMax() {
        let result = ValidationHelpers.validateRange(150, min: 1, max: 100, fieldName: "Age")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Age must be between 1 and 100")
    }

    func testValidateRangeBoundaries() {
        // Exactly minimum
        let min = ValidationHelpers.validateRange(1, min: 1, max: 100)
        XCTAssertTrue(min.isValid)

        // Exactly maximum
        let max = ValidationHelpers.validateRange(100, min: 1, max: 100)
        XCTAssertTrue(max.isValid)
    }

    func testValidateRangeDouble() {
        let result = ValidationHelpers.validateRange(5.5, min: 0.0, max: 10.0, fieldName: "Rating")
        XCTAssertTrue(result.isValid)

        let outOfRange = ValidationHelpers.validateRange(10.5, min: 0.0, max: 10.0, fieldName: "Rating")
        XCTAssertFalse(outOfRange.isValid)
    }

    func testValidateRangeNegatives() {
        let result = ValidationHelpers.validateRange(-5, min: -10, max: 0)
        XCTAssertTrue(result.isValid)
    }
}
