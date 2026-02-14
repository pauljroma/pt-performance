//
//  BuilderProgressIndicator.swift
//  PTPerformance
//
//  Horizontal step dots showing current position in the program builder wizard
//  Shows 6 dots, highlights current step, shows completed steps differently
//

import SwiftUI

struct BuilderProgressIndicator: View {
    let currentStep: TherapistProgramBuilderViewModel.BuilderStep

    private let allSteps = TherapistProgramBuilderViewModel.BuilderStep.allCases

    private var completedSteps: Int {
        currentStep.rawValue
    }

    private var totalSteps: Int {
        allSteps.count
    }

    var body: some View {
        VStack(spacing: 8) {
            // Step dots
            HStack(spacing: 8) {
                ForEach(allSteps, id: \.self) { step in
                    StepDot(
                        step: step,
                        currentStep: currentStep
                    )
                }
            }
            .accessibilityHidden(true)

            // Step label
            Text(currentStep.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress: Step \(completedSteps + 1) of \(totalSteps), \(currentStep.displayName)")
        .accessibilityValue("\(completedSteps) steps completed")
    }
}

// MARK: - Step Dot

private struct StepDot: View {
    let step: TherapistProgramBuilderViewModel.BuilderStep
    let currentStep: TherapistProgramBuilderViewModel.BuilderStep

    private var isCompleted: Bool {
        step.rawValue < currentStep.rawValue
    }

    private var isCurrent: Bool {
        step == currentStep
    }

    var body: some View {
        ZStack {
            if isCompleted {
                // Completed step - filled with checkmark
                Circle()
                    .fill(Color.modusCyan)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    )
            } else if isCurrent {
                // Current step - larger with ring
                Circle()
                    .fill(Color.modusCyan)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(Color.modusCyan.opacity(0.3), lineWidth: 4)
                            .frame(width: 36, height: 36)
                    )
            } else {
                // Future step - empty circle
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 2)
                    .frame(width: 24, height: 24)
            }
        }
        .frame(width: 40, height: 40) // Consistent touch target
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
}

// MARK: - Linear Progress Variant

/// Alternative linear progress bar variant
struct BuilderProgressBar: View {
    let currentStep: TherapistProgramBuilderViewModel.BuilderStep

    private var progress: Double {
        let total = Double(TherapistProgramBuilderViewModel.BuilderStep.allCases.count - 1)
        return Double(currentStep.rawValue) / total
    }

    private var progressPercentage: Int {
        Int(progress * 100)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray5))
                        .frame(height: 4)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.modusCyan)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)
            .accessibilityHidden(true)

            // Step indicator
            HStack {
                Text("Step \(currentStep.rawValue + 1) of \(TherapistProgramBuilderViewModel.BuilderStep.allCases.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(currentStep.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress: Step \(currentStep.rawValue + 1) of \(TherapistProgramBuilderViewModel.BuilderStep.allCases.count), \(currentStep.displayName)")
        .accessibilityValue("\(progressPercentage) percent complete")
    }
}

// MARK: - Numbered Step Indicator

/// Alternative numbered step indicator
struct BuilderNumberedSteps: View {
    let currentStep: TherapistProgramBuilderViewModel.BuilderStep

    private let allSteps = TherapistProgramBuilderViewModel.BuilderStep.allCases

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(allSteps.enumerated()), id: \.element) { index, step in
                HStack(spacing: 0) {
                    // Step number
                    NumberedStepCircle(
                        number: index + 1,
                        isCompleted: step.rawValue < currentStep.rawValue,
                        isCurrent: step == currentStep
                    )

                    // Connector line (except for last step)
                    if index < allSteps.count - 1 {
                        Rectangle()
                            .fill(step.rawValue < currentStep.rawValue ? Color.modusCyan : Color(.systemGray4))
                            .frame(height: 2)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
            }
        }
    }
}

private struct NumberedStepCircle: View {
    let number: Int
    let isCompleted: Bool
    let isCurrent: Bool

    var body: some View {
        ZStack {
            if isCompleted {
                Circle()
                    .fill(Color.modusCyan)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    )
            } else if isCurrent {
                Circle()
                    .fill(Color.modusCyan)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text("\(number)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
            } else {
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 2)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text("\(number)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    )
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct BuilderProgressIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Default dots style
            VStack {
                Text("Dots Style")
                    .font(.caption.bold())
                BuilderProgressIndicator(currentStep: .basics)
            }

            // Progress bar style
            VStack {
                Text("Progress Bar Style")
                    .font(.caption.bold())
                BuilderProgressBar(currentStep: .phases)
                    .padding(.horizontal)
            }

            // Numbered style
            VStack {
                Text("Numbered Style")
                    .font(.caption.bold())
                BuilderNumberedSteps(currentStep: .workouts)
                    .padding(.horizontal)
            }

            // All steps
            VStack(spacing: 20) {
                Text("All Steps")
                    .font(.caption.bold())
                ForEach(TherapistProgramBuilderViewModel.BuilderStep.allCases, id: \.self) { step in
                    BuilderProgressIndicator(currentStep: step)
                }
            }
        }
        .padding()
    }
}
#endif
