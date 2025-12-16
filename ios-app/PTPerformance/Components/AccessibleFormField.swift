//
//  AccessibleFormField.swift
//  PTPerformance
//
//  Created by Build 61 - Form Validation & Accessibility
//  Accessible form field wrapper with validation support
//

import SwiftUI

/// An accessible form field wrapper that provides validation feedback and VoiceOver support
struct AccessibleFormField: View {
    // Field configuration
    let label: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var validation: ((String) -> ValidationResult)?

    // Optional customization
    var onValidationChange: ((ValidationResult) -> Void)?

    // Internal state
    @State private var validationResult: ValidationResult?
    @State private var hasStartedEditing: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Text field with validation indicator
            HStack(spacing: 12) {
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocapitalization(.none)
                            .focused($isFocused)
                    } else {
                        TextField(placeholder, text: $text)
                            .textFieldStyle(PlainTextFieldStyle())
                            .keyboardType(keyboardType)
                            .autocapitalization(keyboardType == .emailAddress ? .none : .sentences)
                            .focused($isFocused)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(borderColor, lineWidth: borderWidth)
                )

                // Validation indicator
                if hasStartedEditing {
                    FormValidationIndicator(validationResult: validationResult)
                        .frame(width: 24, height: 24)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabelText)
            .accessibilityHint(accessibilityHintText)
            .accessibilityValue(accessibilityValueText)

            // Error message
            if let errorMessage = validationResult?.errorMessage, hasStartedEditing {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(errorMessage)
                        .font(.caption)
                }
                .foregroundColor(.red)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Error: \(errorMessage)")
            }
        }
        .onChange(of: text) { newValue in
            if !hasStartedEditing && !newValue.isEmpty {
                hasStartedEditing = true
            }

            if hasStartedEditing, let validation = validation {
                let result = validation(newValue)
                withAnimation(.easeInOut(duration: 0.2)) {
                    validationResult = result
                }
                onValidationChange?(result)
            }
        }
        .onChange(of: isFocused) { focused in
            if focused && !hasStartedEditing {
                hasStartedEditing = true
            }
        }
    }

    // MARK: - Computed Properties

    private var borderColor: Color {
        guard hasStartedEditing, let result = validationResult else {
            return Color(.systemGray4)
        }

        switch result {
        case .valid:
            return .green
        case .invalid:
            return .red
        }
    }

    private var borderWidth: CGFloat {
        guard hasStartedEditing, validationResult != nil else {
            return 1
        }
        return 2
    }

    private var accessibilityLabelText: String {
        return "\(label) text field"
    }

    private var accessibilityHintText: String {
        if isSecure {
            return "Enter your \(label.lowercased()). Your input will be hidden for security."
        } else if keyboardType == .emailAddress {
            return "Enter your \(label.lowercased()) in email format."
        } else if keyboardType == .decimalPad || keyboardType == .numberPad {
            return "Enter a numeric value for \(label.lowercased())."
        } else {
            return "Enter \(label.lowercased())."
        }
    }

    private var accessibilityValueText: String {
        if text.isEmpty {
            return "Empty"
        }

        // Don't read out password values
        if isSecure {
            return "\(text.count) characters entered"
        }

        // Include validation state
        if hasStartedEditing, let result = validationResult {
            switch result {
            case .valid:
                return "\(text). Valid"
            case .invalid(let message):
                return "\(text). Invalid: \(message)"
            }
        }

        return text
    }
}

// MARK: - Preview

#if DEBUG
struct AccessibleFormField_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Email field with validation
                AccessibleFormField(
                    label: "Email",
                    text: .constant("test@example.com"),
                    placeholder: "Enter email",
                    keyboardType: .emailAddress,
                    validation: ValidationHelpers.validateEmail
                )

                // Password field with validation
                AccessibleFormField(
                    label: "Password",
                    text: .constant("Pass123"),
                    placeholder: "Enter password",
                    isSecure: true,
                    validation: ValidationHelpers.validatePassword
                )

                // Program name with validation
                AccessibleFormField(
                    label: "Program Name",
                    text: .constant("Winter Strength"),
                    placeholder: "Enter program name",
                    validation: ValidationHelpers.validateProgramName
                )

                // Weight field with validation
                AccessibleFormField(
                    label: "Weight",
                    text: .constant("185.5"),
                    placeholder: "0",
                    keyboardType: .decimalPad,
                    validation: ValidationHelpers.validateExerciseWeight
                )

                // Reps field with validation
                AccessibleFormField(
                    label: "Reps",
                    text: .constant("8-12"),
                    placeholder: "Enter reps",
                    keyboardType: .numberPad,
                    validation: ValidationHelpers.validateExerciseReps
                )
            }
            .padding()
        }
    }
}
#endif
