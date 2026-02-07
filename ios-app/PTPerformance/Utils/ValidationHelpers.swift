//
//  ValidationHelpers.swift
//  PTPerformance
//
//  Created by Build 61 - Form Validation & Accessibility
//  Provides comprehensive validation for form inputs across the app
//

import Foundation

// MARK: - ValidationResult

/// Result of a validation operation
enum ValidationResult: Equatable {
    case valid
    case invalid(String)

    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case .invalid(let message) = self {
            return message
        }
        return nil
    }
}

// MARK: - ValidationHelpers

/// Collection of validation functions for common form inputs
struct ValidationHelpers {

    // MARK: - Program Validation

    /// Validates a program name
    /// - Parameter name: The program name to validate
    /// - Returns: ValidationResult indicating if valid or error message
    static func validateProgramName(_ name: String) -> ValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return .invalid("Program name cannot be empty")
        }

        if trimmed.count < 3 {
            return .invalid("Program name must be at least 3 characters")
        }

        if trimmed.count > 100 {
            return .invalid("Program name must be 100 characters or less")
        }

        return .valid
    }

    // MARK: - Exercise Validation

    /// Validates exercise reps input (single value or range)
    /// - Parameter reps: The reps string to validate (e.g., "10" or "8-12")
    /// - Returns: ValidationResult indicating if valid or error message
    static func validateExerciseReps(_ reps: String) -> ValidationResult {
        let trimmed = reps.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return .invalid("Reps cannot be empty")
        }

        // Check if it's a range (e.g., "8-12")
        if trimmed.contains("-") {
            let parts = trimmed.split(separator: "-")
            if parts.count != 2 {
                return .invalid("Range must be in format like 8-12")
            }

            guard let start = Int(parts[0]), let end = Int(parts[1]) else {
                return .invalid("Range values must be integers")
            }

            if start < 1 || end < 1 {
                return .invalid("Reps must be at least 1")
            }

            if start > 999 || end > 999 {
                return .invalid("Reps must be 999 or less")
            }

            if start >= end {
                return .invalid("Range start must be less than end")
            }

            return .valid
        }

        // Single value
        guard let value = Int(trimmed) else {
            return .invalid("Reps must be an integer or range (e.g., 8-12)")
        }

        if value < 1 {
            return .invalid("Reps must be at least 1")
        }

        if value > 999 {
            return .invalid("Reps must be 999 or less")
        }

        return .valid
    }

    /// Validates exercise weight input
    /// - Parameter weight: The weight string to validate
    /// - Returns: ValidationResult indicating if valid or error message
    static func validateExerciseWeight(_ weight: String) -> ValidationResult {
        let trimmed = weight.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return .invalid("Weight cannot be empty")
        }

        guard let value = Double(trimmed) else {
            return .invalid("Weight must be a valid number")
        }

        if value < 0 {
            return .invalid("Weight cannot be negative")
        }

        if value > 9999 {
            return .invalid("Weight must be 9999 or less")
        }

        // Check for reasonable decimal places (max 2)
        let components = trimmed.split(separator: ".")
        if components.count == 2 {
            if components[1].count > 2 {
                return .invalid("Weight can have at most 2 decimal places")
            }
        }

        return .valid
    }

    /// Validates RPE (Rating of Perceived Exertion) value
    /// - Parameter rpe: The RPE value to validate
    /// - Returns: ValidationResult indicating if valid or error message
    static func validateRPE(_ rpe: Double) -> ValidationResult {
        if rpe < 0 || rpe > 10 {
            return .invalid("RPE must be between 0 and 10")
        }
        return .valid
    }

    /// Validates RPE from string input
    /// - Parameter rpe: The RPE string to validate
    /// - Returns: ValidationResult indicating if valid or error message
    static func validateRPE(_ rpe: String) -> ValidationResult {
        let trimmed = rpe.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return .invalid("RPE cannot be empty")
        }

        guard let value = Double(trimmed) else {
            return .invalid("RPE must be a number")
        }

        return validateRPE(value)
    }

    // MARK: - Authentication Validation

    /// Validates an email address
    /// - Parameter email: The email to validate
    /// - Returns: ValidationResult indicating if valid or error message
    static func validateEmail(_ email: String) -> ValidationResult {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return .invalid("Email cannot be empty")
        }

        // Email regex pattern
        let emailPattern = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailPattern)

        if !emailPredicate.evaluate(with: trimmed) {
            return .invalid("Please enter a valid email address")
        }

        return .valid
    }

    /// Validates a password
    /// - Parameter password: The password to validate
    /// - Returns: ValidationResult indicating if valid or error message
    static func validatePassword(_ password: String) -> ValidationResult {
        if password.isEmpty {
            return .invalid("Password cannot be empty")
        }

        if password.count < 8 {
            return .invalid("Password must be at least 8 characters")
        }

        // Check for at least one uppercase letter
        let uppercasePattern = ".*[A-Z]+.*"
        let uppercasePredicate = NSPredicate(format: "SELF MATCHES %@", uppercasePattern)
        if !uppercasePredicate.evaluate(with: password) {
            return .invalid("Password must contain at least 1 uppercase letter")
        }

        // Check for at least one number
        let numberPattern = ".*[0-9]+.*"
        let numberPredicate = NSPredicate(format: "SELF MATCHES %@", numberPattern)
        if !numberPredicate.evaluate(with: password) {
            return .invalid("Password must contain at least 1 number")
        }

        return .valid
    }

    // MARK: - General Validation

    /// Validates that a string is not empty after trimming
    /// - Parameters:
    ///   - text: The text to validate
    ///   - fieldName: The name of the field for error messages
    /// - Returns: ValidationResult indicating if valid or error message
    static func validateNotEmpty(_ text: String, fieldName: String = "Field") -> ValidationResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return .invalid("\(fieldName) cannot be empty")
        }

        return .valid
    }

    /// Validates that a string is within a length range
    /// - Parameters:
    ///   - text: The text to validate
    ///   - minLength: Minimum length (inclusive)
    ///   - maxLength: Maximum length (inclusive)
    ///   - fieldName: The name of the field for error messages
    /// - Returns: ValidationResult indicating if valid or error message
    static func validateLength(_ text: String, minLength: Int, maxLength: Int, fieldName: String = "Field") -> ValidationResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.count < minLength {
            return .invalid("\(fieldName) must be at least \(minLength) characters")
        }

        if trimmed.count > maxLength {
            return .invalid("\(fieldName) must be \(maxLength) characters or less")
        }

        return .valid
    }

    /// Validates a numeric range
    /// - Parameters:
    ///   - value: The value to validate
    ///   - min: Minimum value (inclusive)
    ///   - max: Maximum value (inclusive)
    ///   - fieldName: The name of the field for error messages
    /// - Returns: ValidationResult indicating if valid or error message
    static func validateRange<T: Comparable>(_ value: T, min: T, max: T, fieldName: String = "Value") -> ValidationResult {
        if value < min || value > max {
            return .invalid("\(fieldName) must be between \(min) and \(max)")
        }
        return .valid
    }

    // MARK: - Pain Score Validation

    /// Validates a pain score (0-10 scale)
    /// - Parameter painScore: The pain score value to validate
    /// - Returns: ValidationResult indicating if valid or error message
    static func validatePainScore(_ painScore: Int) -> ValidationResult {
        if painScore < 0 || painScore > 10 {
            return .invalid("Pain score must be between 0 and 10")
        }
        return .valid
    }

    /// Validates a pain score from string input
    /// - Parameter painScore: The pain score string to validate
    /// - Returns: ValidationResult indicating if valid or error message
    static func validatePainScore(_ painScore: String) -> ValidationResult {
        let trimmed = painScore.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return .invalid("Pain score cannot be empty")
        }

        guard let value = Int(trimmed) else {
            return .invalid("Pain score must be an integer")
        }

        return validatePainScore(value)
    }

    // MARK: - Sets Validation

    /// Validates exercise sets (positive integers)
    /// - Parameter sets: The sets value to validate
    /// - Returns: ValidationResult indicating if valid or error message
    static func validateSets(_ sets: Int) -> ValidationResult {
        if sets < 1 {
            return .invalid("Sets must be at least 1")
        }

        if sets > 99 {
            return .invalid("Sets must be 99 or less")
        }

        return .valid
    }

    /// Validates exercise sets from string input
    /// - Parameter sets: The sets string to validate
    /// - Returns: ValidationResult indicating if valid or error message
    static func validateSets(_ sets: String) -> ValidationResult {
        let trimmed = sets.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return .invalid("Sets cannot be empty")
        }

        guard let value = Int(trimmed) else {
            return .invalid("Sets must be an integer")
        }

        return validateSets(value)
    }

    // MARK: - Load Validation

    /// Validates exercise load (positive doubles)
    /// - Parameter load: The load value to validate
    /// - Returns: ValidationResult indicating if valid or error message
    static func validateLoad(_ load: Double) -> ValidationResult {
        if load < 0 {
            return .invalid("Load cannot be negative")
        }

        if load > 9999 {
            return .invalid("Load must be 9999 or less")
        }

        return .valid
    }

    /// Validates exercise load from string input
    /// - Parameter load: The load string to validate
    /// - Returns: ValidationResult indicating if valid or error message
    static func validateLoad(_ load: String) -> ValidationResult {
        let trimmed = load.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return .invalid("Load cannot be empty")
        }

        guard let value = Double(trimmed) else {
            return .invalid("Load must be a valid number")
        }

        return validateLoad(value)
    }

    // MARK: - Body Composition Weight Validation

    /// Validates body composition weight
    /// - Parameter weight: The weight value in kg or lbs to validate
    /// - Returns: ValidationResult indicating if valid or error message
    static func validateBodyWeight(_ weight: Double) -> ValidationResult {
        if weight <= 0 {
            return .invalid("Weight must be greater than 0")
        }

        if weight > 1000 {
            return .invalid("Weight must be 1000 or less")
        }

        return .valid
    }

    /// Validates body composition weight from string input
    /// - Parameter weight: The weight string to validate
    /// - Returns: ValidationResult indicating if valid or error message
    static func validateBodyWeight(_ weight: String) -> ValidationResult {
        let trimmed = weight.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return .invalid("Weight cannot be empty")
        }

        guard let value = Double(trimmed) else {
            return .invalid("Weight must be a valid number")
        }

        return validateBodyWeight(value)
    }

    // MARK: - Phone Number Validation

    /// Validates a phone number
    /// - Parameter phone: The phone number string to validate
    /// - Returns: ValidationResult indicating if valid or error message
    static func validatePhoneNumber(_ phone: String) -> ValidationResult {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return .invalid("Phone number cannot be empty")
        }

        // Remove common formatting characters for validation
        let digitsOnly = trimmed.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        // Phone number must have between 10 and 15 digits (E.164 standard)
        if digitsOnly.count < 10 {
            return .invalid("Phone number must have at least 10 digits")
        }

        if digitsOnly.count > 15 {
            return .invalid("Phone number must have at most 15 digits")
        }

        // Check that original string only contains valid characters
        let validCharacters = CharacterSet(charactersIn: "0123456789()-+. ")
        if trimmed.rangeOfCharacter(from: validCharacters.inverted) != nil {
            return .invalid("Phone number contains invalid characters")
        }

        return .valid
    }

    // MARK: - Date Range Validation

    /// Validates a date range
    /// - Parameters:
    ///   - startDate: The start date
    ///   - endDate: The end date
    /// - Returns: ValidationResult indicating if valid or error message
    static func validateDateRange(startDate: Date, endDate: Date) -> ValidationResult {
        if startDate > endDate {
            return .invalid("Start date must be before or equal to end date")
        }
        return .valid
    }

    /// Validates a date range with optional maximum span
    /// - Parameters:
    ///   - startDate: The start date
    ///   - endDate: The end date
    ///   - maxDays: Maximum number of days allowed in the range
    /// - Returns: ValidationResult indicating if valid or error message
    static func validateDateRange(startDate: Date, endDate: Date, maxDays: Int) -> ValidationResult {
        let basicResult = validateDateRange(startDate: startDate, endDate: endDate)
        guard basicResult.isValid else {
            return basicResult
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        if let days = components.day, days > maxDays {
            return .invalid("Date range cannot exceed \(maxDays) days")
        }

        return .valid
    }

    // MARK: - UUID Validation

    /// Validates a UUID string
    /// - Parameter uuidString: The UUID string to validate
    /// - Returns: ValidationResult indicating if valid or error message
    static func validateUUID(_ uuidString: String) -> ValidationResult {
        let trimmed = uuidString.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return .invalid("UUID cannot be empty")
        }

        if UUID(uuidString: trimmed) == nil {
            return .invalid("Invalid UUID format")
        }

        return .valid
    }

    // MARK: - Reps Validation (Integer)

    /// Validates exercise reps (positive integers)
    /// - Parameter reps: The reps value to validate
    /// - Returns: ValidationResult indicating if valid or error message
    static func validateReps(_ reps: Int) -> ValidationResult {
        if reps < 1 {
            return .invalid("Reps must be at least 1")
        }

        if reps > 999 {
            return .invalid("Reps must be 999 or less")
        }

        return .valid
    }
}
