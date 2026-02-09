//
//  QuickSetupView.swift
//  PTPerformance
//
//  Quick Setup flow - configures new users with mode, goals, readiness baseline
//

import SwiftUI

/// Main Quick Setup container view
struct QuickSetupView: View {
    @StateObject private var viewModel = QuickSetupViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                if viewModel.currentStep != .welcome && viewModel.currentStep != .complete {
                    QuickSetupProgressView(currentStep: viewModel.currentStep)
                        .padding(.top, 8)
                        .padding(.horizontal)
                }

                // Content
                TabView(selection: $viewModel.currentStep) {
                    WelcomeStepView()
                        .tag(QuickSetupViewModel.SetupStep.welcome)

                    ModeSelectionStepView(selectedMode: $viewModel.selectedMode)
                        .tag(QuickSetupViewModel.SetupStep.modeSelection)

                    GoalSelectionStepView(
                        availableGoals: viewModel.availableGoals,
                        selectedGoals: $viewModel.selectedGoals
                    )
                    .tag(QuickSetupViewModel.SetupStep.goalSelection)

                    ReadinessStepView(
                        sleepHours: $viewModel.sleepHours,
                        sorenessLevel: $viewModel.sorenessLevel,
                        energyLevel: $viewModel.energyLevel,
                        stressLevel: $viewModel.stressLevel
                    )
                    .tag(QuickSetupViewModel.SetupStep.readinessCheckIn)

                    TherapistLinkStepView(
                        code: $viewModel.therapistCode,
                        hasTherapist: viewModel.hasTherapist
                    )
                    .tag(QuickSetupViewModel.SetupStep.therapistLink)

                    CompleteStepView()
                        .tag(QuickSetupViewModel.SetupStep.complete)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)

                // Error message
                if let error = viewModel.error {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }

                // Navigation buttons
                HStack(spacing: 16) {
                    if viewModel.canGoBack {
                        Button(action: {
                            viewModel.goToPreviousStep()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.modusCyan)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                    }

                    Button(action: {
                        Task {
                            await viewModel.handleContinue()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(viewModel.continueButtonText)
                                if viewModel.currentStep != .complete {
                                    Image(systemName: "chevron.right")
                                }
                            }
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(viewModel.canContinue ? Color.modusCyan : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!viewModel.canContinue || viewModel.isLoading)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .onChange(of: viewModel.isComplete) { _, complete in
            if complete {
                dismiss()
            }
        }
        .interactiveDismissDisabled(viewModel.currentStep != .complete)
    }
}

// MARK: - Progress View

struct QuickSetupProgressView: View {
    let currentStep: QuickSetupViewModel.SetupStep

    private let totalSteps = 4  // Excluding welcome and complete

    private var progress: Double {
        switch currentStep {
        case .welcome: return 0
        case .modeSelection: return 0.25
        case .goalSelection: return 0.5
        case .readinessCheckIn: return 0.75
        case .therapistLink: return 1.0
        case .complete: return 1.0
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                        .cornerRadius(2)

                    Rectangle()
                        .fill(Color.modusCyan)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)

            // Step indicator
            Text("Step \(currentStep.rawValue) of \(totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Welcome Step

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundColor(.modusCyan)
                .padding(.bottom, 16)

            // Title
            Text("Start Training Smarter")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)

            // Subtitle
            Text("Let's personalize your experience.\nThis takes about 2 minutes.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            // Features preview
            VStack(alignment: .leading, spacing: 16) {
                SetupFeatureRow(icon: "target", title: "Set Your Goals", subtitle: "Track what matters to you")
                SetupFeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Daily Check-ins", subtitle: "Optimize your training")
                SetupFeatureRow(icon: "person.2", title: "Connect with Therapist", subtitle: "Get personalized programs")
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
    }
}

struct SetupFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.modusCyan)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Mode Selection Step

struct ModeSelectionStepView: View {
    @Binding var selectedMode: Mode

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Choose Your Mode")
                    .font(.system(size: 28, weight: .bold))

                Text("This personalizes your dashboard and features")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)

            // Mode cards
            VStack(spacing: 16) {
                ForEach(Mode.allCases, id: \.self) { mode in
                    ModeCard(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        onTap: { selectedMode = mode }
                    )
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .padding()
    }
}

struct ModeCard: View {
    let mode: Mode
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: mode.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : .modusCyan)
                    .frame(width: 60, height: 60)
                    .background(isSelected ? Color.modusCyan : Color.modusCyan.opacity(0.1))
                    .cornerRadius(12)

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(mode.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Metrics
                    Text(mode.primaryMetrics.joined(separator: " • "))
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.modusCyan)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.modusCyan : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Goal Selection Step

struct GoalSelectionStepView: View {
    let availableGoals: [QuickSetupViewModel.QuickGoalTemplate]
    @Binding var selectedGoals: Set<QuickSetupViewModel.QuickGoalTemplate>

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Set Your Goals")
                    .font(.system(size: 28, weight: .bold))

                Text("Select 1-3 goals to focus on")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 32)

            // Goal cards
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(availableGoals) { goal in
                        GoalCard(
                            goal: goal,
                            isSelected: selectedGoals.contains(goal),
                            onTap: {
                                if selectedGoals.contains(goal) {
                                    selectedGoals.remove(goal)
                                } else if selectedGoals.count < 3 {
                                    selectedGoals.insert(goal)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }

            // Selection count
            Text("\(selectedGoals.count) of 3 selected")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct GoalCard: View {
    let goal: QuickSetupViewModel.QuickGoalTemplate
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: goal.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : goal.color)
                    .frame(width: 48, height: 48)
                    .background(isSelected ? goal.color : goal.color.opacity(0.1))
                    .cornerRadius(10)

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(goal.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? goal.color : .gray)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? goal.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Readiness Step

struct ReadinessStepView: View {
    @Binding var sleepHours: Double
    @Binding var sorenessLevel: Int
    @Binding var energyLevel: Int
    @Binding var stressLevel: Int

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("How Are You Feeling?")
                        .font(.system(size: 28, weight: .bold))

                    Text("This sets your baseline for training recommendations")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                VStack(spacing: 20) {
                    // Sleep
                    ReadinessSlider(
                        title: "Sleep",
                        icon: "moon.fill",
                        value: $sleepHours,
                        range: 0...12,
                        step: 0.5,
                        valueLabel: String(format: "%.1f hrs", sleepHours),
                        color: .indigo
                    )

                    // Soreness (inverted - 1 is best)
                    ReadinessSlider(
                        title: "Soreness",
                        icon: "figure.walk",
                        value: Binding(
                            get: { Double(sorenessLevel) },
                            set: { sorenessLevel = Int($0) }
                        ),
                        range: 1...10,
                        step: 1,
                        valueLabel: sorenessLabel,
                        color: .orange,
                        isInverted: true
                    )

                    // Energy
                    ReadinessSlider(
                        title: "Energy",
                        icon: "bolt.fill",
                        value: Binding(
                            get: { Double(energyLevel) },
                            set: { energyLevel = Int($0) }
                        ),
                        range: 1...10,
                        step: 1,
                        valueLabel: energyLabel,
                        color: .green
                    )

                    // Stress (inverted - 1 is best)
                    ReadinessSlider(
                        title: "Stress",
                        icon: "brain.head.profile",
                        value: Binding(
                            get: { Double(stressLevel) },
                            set: { stressLevel = Int($0) }
                        ),
                        range: 1...10,
                        step: 1,
                        valueLabel: stressLabel,
                        color: .purple,
                        isInverted: true
                    )
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
        }
        .padding()
    }

    private var sorenessLabel: String {
        switch sorenessLevel {
        case 1...2: return "None"
        case 3...4: return "Mild"
        case 5...6: return "Moderate"
        case 7...8: return "Significant"
        default: return "Severe"
        }
    }

    private var energyLabel: String {
        switch energyLevel {
        case 1...2: return "Exhausted"
        case 3...4: return "Low"
        case 5...6: return "Moderate"
        case 7...8: return "Good"
        default: return "Excellent"
        }
    }

    private var stressLabel: String {
        switch stressLevel {
        case 1...2: return "Relaxed"
        case 3...4: return "Low"
        case 5...6: return "Moderate"
        case 7...8: return "High"
        default: return "Very High"
        }
    }
}

struct ReadinessSlider: View {
    let title: String
    let icon: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let valueLabel: String
    let color: Color
    var isInverted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                Spacer()
                Text(valueLabel)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Slider(value: $value, in: range, step: step)
                .tint(color)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Therapist Link Step

struct TherapistLinkStepView: View {
    @Binding var code: String
    let hasTherapist: Bool

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Connect with Therapist")
                    .font(.system(size: 28, weight: .bold))

                Text("Optional: Enter the code from your therapist")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)

            // Icon
            Image(systemName: hasTherapist ? "checkmark.circle.fill" : "person.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(hasTherapist ? .green : .modusCyan)
                .padding()

            if hasTherapist {
                Text("Therapist Connected!")
                    .font(.headline)
                    .foregroundColor(.green)
            } else {
                // Code input
                VStack(spacing: 16) {
                    TextField("Enter 8-character code", text: $code)
                        .textCase(.uppercase)
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)

                    Text("Your therapist will give you this code.\nYou can also connect later from Settings.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Complete Step

struct CompleteStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Success animation
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)
                .padding(.bottom, 16)

            // Title
            Text("You're All Set!")
                .font(.system(size: 32, weight: .bold))

            // Subtitle
            Text("Your personalized dashboard is ready.\nLet's start your journey!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            // What's next
            VStack(alignment: .leading, spacing: 16) {
                Text("What's Next")
                    .font(.headline)
                    .padding(.bottom, 4)

                NextStepRow(icon: "figure.strengthtraining.traditional", text: "Complete your first workout")
                NextStepRow(icon: "chart.line.uptrend.xyaxis", text: "Check in daily for personalized recommendations")
                NextStepRow(icon: "star.fill", text: "Build your streak and track progress")
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
    }
}

struct NextStepRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.modusCyan)
                .frame(width: 32)

            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Preview

#Preview {
    QuickSetupView()
}
