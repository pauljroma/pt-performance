// ACP-1035: Streamlined Quick Setup — Progressive Disclosure
// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  QuickSetupView.swift
//  PTPerformance
//
//  Reduced from 6 steps to 4: Welcome -> Mode -> Goals -> Complete
//  Readiness check-in and therapist link are deferred (progressive disclosure)
//

import SwiftUI

/// Main Quick Setup container view — streamlined for speed
struct QuickSetupView: View {
    @StateObject private var viewModel = QuickSetupViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator (hidden on welcome and complete)
                if viewModel.currentStep != .welcome && viewModel.currentStep != .complete {
                    QuickSetupProgressView(currentStep: viewModel.currentStep)
                        .padding(.top, 8)
                        .padding(.horizontal)
                }

                // Skip for Now button in top-right (visible on non-terminal steps)
                if viewModel.currentStep != .welcome && viewModel.currentStep != .complete {
                    HStack {
                        Spacer()
                        Button(action: {
                            Task { await viewModel.handleSkipForNow() }
                        }) {
                            Text("Skip for Now")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.modusCyan)
                        }
                        .accessibilityLabel("Skip for Now")
                        .accessibilityHint("Skip setup and go straight to the app")
                        .padding(.trailing, 20)
                        .padding(.top, 4)
                    }
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

                    CompleteStepView(
                        quickStarted: viewModel.quickStarted,
                        selectedMode: viewModel.selectedMode
                    )
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
                            HapticFeedback.medium()
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
                            .cornerRadius(CornerRadius.md)
                        }
                        .accessibilityLabel("Back")
                        .accessibilityHint("Go to the previous step")
                    }

                    Button(action: {
                        HapticFeedback.medium()
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
                        .cornerRadius(CornerRadius.md)
                    }
                    .accessibilityLabel(viewModel.continueButtonText)
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

    // ACP-1035: Reduced to 2 core steps (mode, goals)
    private let totalSteps = 2

    private var progress: Double {
        switch currentStep {
        case .welcome: return 0
        case .modeSelection: return 0.5
        case .goalSelection: return 1.0
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
                        .cornerRadius(CornerRadius.xs)

                    Rectangle()
                        .fill(Color.modusCyan)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(CornerRadius.xs)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)

            // Step indicator
            Text("Step \(stepNumber) of \(totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var stepNumber: Int {
        switch currentStep {
        case .welcome: return 0
        case .modeSelection: return 1
        case .goalSelection: return 2
        case .complete: return 2
        }
    }
}

// MARK: - Welcome Step

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.modusCyan.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "sparkles")
                    .font(.system(size: 56))
                    .foregroundColor(.modusCyan)
            }
            .padding(.bottom, 8)

            // Title
            Text("Let's Personalize")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.modusDeepTeal)
                .multilineTextAlignment(.center)

            // Subtitle — emphasize speed
            Text("Two quick choices and you're in.\nThis takes about 30 seconds.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            // What we'll ask
            VStack(alignment: .leading, spacing: 14) {
                SetupFeatureRow(
                    icon: "target",
                    title: "Choose your mode",
                    subtitle: "Rehab, Strength, or Performance"
                )
                SetupFeatureRow(
                    icon: "star.fill",
                    title: "Pick your goals",
                    subtitle: "We'll track what matters to you"
                )
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
                .font(.system(size: 22))
                .foregroundColor(.modusCyan)
                .frame(width: 36)

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
                    .foregroundColor(.modusDeepTeal)

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
                        onTap: {
                            HapticFeedback.selectionChanged()
                            selectedMode = mode
                        }
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
                    .cornerRadius(CornerRadius.md)

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(mode.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Metrics
                    Text(mode.primaryMetrics.joined(separator: " · "))
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
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.modusCyan : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mode.displayName). \(mode.description)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Goal Selection Step (ACP-1035: Visual Cards UI)

struct GoalSelectionStepView: View {
    let availableGoals: [QuickSetupViewModel.QuickGoalTemplate]
    @Binding var selectedGoals: Set<QuickSetupViewModel.QuickGoalTemplate>

    // Grid layout: 2 columns for visual cards
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Text("What's Your Focus?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.modusDeepTeal)

                Text("Pick up to 3 goals — you can change these anytime")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)

            // Goal cards in a 2-column grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(availableGoals) { goal in
                        GoalVisualCard(
                            goal: goal,
                            isSelected: selectedGoals.contains(goal),
                            onTap: {
                                HapticFeedback.light()
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

            // Selection indicator
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index < selectedGoals.count ? Color.modusCyan : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                }
                Text("\(selectedGoals.count) of 3 selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
            .padding(.bottom, 4)
        }
        .padding()
    }
}

/// ACP-1035: Visual goal card with icon, gradient accent, and tap-to-select
struct GoalVisualCard: View {
    let goal: QuickSetupViewModel.QuickGoalTemplate
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(isSelected ? goal.color : goal.color.opacity(0.12))
                        .frame(width: 52, height: 52)

                    Image(systemName: goal.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : goal.color)
                }

                // Title
                Text(goal.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                // Short description
                Text(goal.description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? goal.color : Color.clear, lineWidth: 2.5)
            )
            .overlay(alignment: .topTrailing) {
                // Selected checkmark badge
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(goal.color)
                        .background(Circle().fill(Color(.systemBackground)).padding(2))
                        .offset(x: 6, y: -6)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(goal.title). \(goal.description)")
        .accessibilityHint(isSelected ? "Double tap to deselect this goal" : "Double tap to select this goal")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Complete Step

struct CompleteStepView: View {
    let quickStarted: Bool
    let selectedMode: Mode

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Success icon
            ZStack {
                Circle()
                    .fill(Color.modusTealAccent.opacity(0.12))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.modusTealAccent)
            }
            .padding(.bottom, 8)

            // Title
            Text("You're All Set!")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.modusDeepTeal)

            // Subtitle
            Text("Your \(selectedMode.displayName) dashboard is ready.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            // What's next — with deferred items hint
            VStack(alignment: .leading, spacing: 14) {
                Text("What's Next")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)
                    .padding(.bottom, 2)

                NextStepRow(
                    icon: "figure.strengthtraining.traditional",
                    text: "Start your first workout",
                    color: .modusCyan
                )
                NextStepRow(
                    icon: "chart.line.uptrend.xyaxis",
                    text: "Check in daily for smart recommendations",
                    color: .modusTealAccent
                )
                NextStepRow(
                    icon: "person.badge.plus",
                    text: "Connect with your therapist anytime in Settings",
                    color: .modusDeepTeal
                )
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
    var color: Color = .modusCyan

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 28)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview

#Preview {
    QuickSetupView()
}
