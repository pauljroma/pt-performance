//
//  RTSTestRecordingView.swift
//  PTPerformance
//
//  Form for recording test results for Return-to-Sport milestone criteria
//  Includes value input, pass/fail preview, and notes
//

import SwiftUI

// MARK: - RTS Test Recording View

/// Form for recording test results
struct RTSTestRecordingView: View {
    let criterion: RTSMilestoneCriterion
    let protocolId: UUID
    @StateObject private var viewModel = RTSTestingViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var valueText: String = ""
    @State private var notes: String = ""
    @State private var showSuccessAnimation = false
    @State private var didSave = false

    @FocusState private var isValueFocused: Bool

    private var parsedValue: Double? {
        Double(valueText.replacingOccurrences(of: ",", with: "."))
    }

    private var willPass: Bool {
        guard let value = parsedValue, let target = criterion.targetValue else {
            return false
        }
        return criterion.comparisonOperator.evaluate(value: value, target: target)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Criterion info card
                criterionInfoCard

                // Value input section
                valueInputSection

                // Pass/Fail preview
                passFailPreview

                // Notes section
                notesSection

                // Save button
                saveButton
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Record Test")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") {
                        isValueFocused = false
                    }
                }
            }
        }
        .overlay {
            if showSuccessAnimation {
                successOverlay
            }
        }
    }

    // MARK: - Criterion Info Card

    private var criterionInfoCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: criterion.category.icon)
                    .foregroundColor(criterion.category.color)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(criterion.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(criterion.name)
                        .font(.headline)
                }

                Spacer()

                if criterion.isRequired {
                    Text("Required")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.red)
                        .cornerRadius(CornerRadius.xs)
                }
            }

            Text(criterion.description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()

            // Target value
            HStack {
                Text("Target:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(criterion.targetDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            // Previous result if exists
            if let previousResult = criterion.latestResult {
                HStack {
                    Text("Previous:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(previousResult.formattedValue)
                        .font(.subheadline)
                        .foregroundColor(previousResult.passed ? .green : .orange)

                    Text("on \(previousResult.formattedDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Value Input Section

    private var valueInputSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Measured Value")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: Spacing.sm) {
                TextField("Enter value", text: $valueText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .focused($isValueFocused)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(valueFieldBorderColor, lineWidth: 2)
                    )
                    .accessibilityLabel("Measured value")
                    .accessibilityHint("Enter the test result value")

                // Unit label
                if let unit = criterion.targetUnit {
                    Text(unit)
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(minWidth: 40)
                }
            }
        }
    }

    private var valueFieldBorderColor: Color {
        guard parsedValue != nil else { return Color(.systemGray4) }
        return willPass ? .green : .orange
    }

    // MARK: - Pass/Fail Preview

    private var passFailPreview: some View {
        Group {
            if parsedValue != nil {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(willPass ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                            .frame(width: 48, height: 48)

                        Image(systemName: willPass ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(willPass ? .green : .orange)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(willPass ? "Passing" : "Not Passing")
                            .font(.headline)
                            .foregroundColor(willPass ? .green : .orange)

                        Text(willPass
                            ? "This result meets the target criteria"
                            : "This result does not meet the target yet"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(Spacing.md)
                .background(willPass ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                .cornerRadius(CornerRadius.md)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(willPass ? "Result passes target criteria" : "Result does not pass target criteria")
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Notes (Optional)")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            TextEditor(text: $notes)
                .font(.body)
                .frame(minHeight: 100)
                .padding(Spacing.sm)
                .background(Color(.systemBackground))
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .overlay(
                    Group {
                        if notes.isEmpty {
                            Text("Add any relevant observations...")
                                .font(.body)
                                .foregroundColor(.secondary.opacity(0.5))
                                .padding(.horizontal, Spacing.sm + 5)
                                .padding(.vertical, Spacing.sm + 8)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
                .accessibilityLabel("Notes")
                .accessibilityHint("Add optional observations about the test")
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            saveResult()
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle")
                    Text("Save Result")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(parsedValue != nil ? Color.modusCyan : Color.gray)
            .cornerRadius(CornerRadius.lg)
        }
        .disabled(parsedValue == nil || viewModel.isLoading)
        .accessibilityLabel("Save test result")
        .accessibilityHint(parsedValue != nil ? "Double tap to save this result" : "Enter a value first")
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(willPass ? Color.green : Color.orange)
                        .frame(width: 100, height: 100)

                    Image(systemName: willPass ? "checkmark" : "arrow.right")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }

                Text(willPass ? "Test Passed!" : "Result Saved")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(willPass
                    ? "Great progress on your recovery journey"
                    : "Keep working toward your goal"
                )
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            }
            .padding(Spacing.xl)
        }
        .transition(.opacity)
    }

    // MARK: - Actions

    private func saveResult() {
        guard let value = parsedValue else { return }

        HapticFeedback.medium()

        Task {
            // Get current user ID from auth
            guard let recordedBy = UUID(uuidString: PTSupabaseClient.shared.userId ?? "") else {
                return
            }

            let success = await viewModel.recordTest(
                criterionId: criterion.id,
                protocolId: protocolId,
                value: value,
                unit: criterion.targetUnit ?? "",
                recordedBy: recordedBy,
                notes: notes.isEmpty ? nil : notes
            )

            if success {
                // Show success animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSuccessAnimation = true
                }

                HapticFeedback.success()

                // Dismiss after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            } else {
                HapticFeedback.error()
                // Handle error - would show alert in real app
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct RTSTestRecordingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RTSTestRecordingView(
                criterion: RTSMilestoneCriterion.strengthSample,
                protocolId: UUID()
            )
        }

        NavigationStack {
            RTSTestRecordingView(
                criterion: RTSMilestoneCriterion.painSample,
                protocolId: UUID()
            )
        }
        .previewDisplayName("With Previous Result")
    }
}
#endif
