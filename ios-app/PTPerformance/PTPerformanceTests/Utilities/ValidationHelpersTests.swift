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

    // MARK: - Exercise Reps Validation Tests

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

    // MARK: - RPE Validation Tests (Double)

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
}
