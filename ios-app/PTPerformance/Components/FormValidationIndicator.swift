//
//  FormValidationIndicator.swift
//  PTPerformance
//
//  Created by Build 61 - Form Validation & Accessibility
//  Visual indicator for form field validation state
//

import SwiftUI

/// A visual indicator that shows validation state with animated icons
struct FormValidationIndicator: View {
    let validationResult: ValidationResult?

    // Animation state
    @State private var scale: CGFloat = 0.5

    var body: some View {
        Group {
            if let result = validationResult {
                switch result {
                case .valid:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .accessibilityLabel("Valid input")
                        .transition(.scale.combined(with: .opacity))

                case .invalid:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .accessibilityLabel("Invalid input")
                        .transition(.scale.combined(with: .opacity))
                }
            } else {
                // No validation yet - show placeholder
                Image(systemName: "circle")
                    .foregroundColor(.gray.opacity(0.3))
                    .accessibilityHidden(true)
            }
        }
        .font(.system(size: 16))
        .scaleEffect(scale)
        .onChange(of: validationResult) { _, _ in
            // Animate when validation state changes
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }
        .onAppear {
            // Initial animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }
    }
}

/// Extension to provide a convenient validation indicator with text
struct FormValidationRow: View {
    let label: String
    let validationResult: ValidationResult?

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            FormValidationIndicator(validationResult: validationResult)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct FormValidationIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Valid state
            HStack {
                Text("Valid Field")
                Spacer()
                FormValidationIndicator(validationResult: .valid)
            }
            .padding()

            // Invalid state
            HStack {
                Text("Invalid Field")
                Spacer()
                FormValidationIndicator(validationResult: .invalid("Error message"))
            }
            .padding()

            // No validation yet
            HStack {
                Text("Not Validated")
                Spacer()
                FormValidationIndicator(validationResult: nil)
            }
            .padding()

            Divider()

            // Full row examples
            VStack(spacing: 10) {
                FormValidationRow(
                    label: "Valid Row",
                    validationResult: .valid
                )
                .padding()
                .background(Color.gray.opacity(0.1))

                FormValidationRow(
                    label: "Invalid Row",
                    validationResult: .invalid("Error")
                )
                .padding()
                .background(Color.gray.opacity(0.1))
            }
        }
        .padding()
    }
}
#endif
