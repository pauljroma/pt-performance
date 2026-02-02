//
//  ValidationHelpersTests.swift
//  PTPerformanceTests
//
//  Unit tests for ValidationHelpers utility
//  Tests form validation logic for various input types
//

import XCTest
@testable import PTPerformance

final class ValidationHelpersTests: XCTestCase {

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

    // MARK: - Exercise Reps Validation Tests

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

    // MARK: - RPE Validation Tests (Double)

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

    // MARK: - RPE Validation Tests (String)

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
}
