//
//  DailyCheckInView.swift
//  PTPerformance
//
//  X2Index M8: Daily Check-In View
//  Full-screen check-in flow optimized for <=60 second completion
//

import SwiftUI

// MARK: - Daily Check-In View

/// Full-screen athlete daily check-in flow
///
/// Features:
/// - Progress indicator (step 1 of 5, etc.)
/// - Large touch targets for quick input
/// - Slider components for 1-10 scales
/// - Optional pain/notes at end
/// - Completion celebration animation
/// - Target: <=60 seconds to complete
struct DailyCheckInView: View {

    // MARK: - Properties

    @StateObject private var viewModel = DailyCheckInViewModel()
    @Environment(\.dismiss) private var dismiss

    let onComplete: (() -> Void)?

    // MARK: - Initialization

    init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()

                // Content based on state
                switch viewModel.flowState {
                case .notStarted:
                    startView

                case .inProgress(let step):
                    stepView(for: step)

                case .reviewing:
                    reviewView

                case .submitting:
                    submittingView

                case .completed:
                    CheckInCompletionView(
                        checkIn: viewModel.savedCheckIn,
                        streak: viewModel.streak,
                        onViewPlan: {
                            dismiss()
                            onComplete?()
                        },
                        onDismiss: {
                            dismiss()
                        }
                    )

                case .error(let message):
                    errorView(message: message)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if case .inProgress = viewModel.flowState {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .principal) {
                        progressIndicator
                    }
                }

                if case .reviewing = viewModel.flowState {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back") {
                            viewModel.goToStep(.notes)
                        }
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                }
            } message: {
                Text(viewModel.errorMessage)
            }
            .task {
                await viewModel.checkTodayStatus()
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(CheckInStep.allCases) { step in
                Circle()
                    .fill(stepColor(for: step))
                    .frame(width: step == viewModel.currentStep ? 10 : 8,
                           height: step == viewModel.currentStep ? 10 : 8)
                    .animation(.easeInOut, value: viewModel.currentStep)
            }
        }
        .accessibilityLabel("Step \(viewModel.currentStepIndex + 1) of \(viewModel.totalSteps)")
    }

    private func stepColor(for step: CheckInStep) -> Color {
        if step.rawValue < viewModel.currentStepIndex {
            return .green
        } else if step == viewModel.currentStep {
            return .modusCyan
        } else if step.isOptional {
            return .gray.opacity(0.3)
        } else {
            return .gray.opacity(0.5)
        }
    }

    // MARK: - Start View

    private var startView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: "sun.horizon.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)

            // Title
            VStack(spacing: 8) {
                Text("Good \(timeOfDayGreeting)!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Let's check in on how you're feeling")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Streak reminder if at risk
            if let streak = viewModel.streak, streak.isAtRisk && streak.currentStreak > 0 {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(streak.currentStreak) day streak at risk!")
                        .fontWeight(.medium)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(CornerRadius.md)
            }

            // Already checked in indicator
            if viewModel.hasCheckedInToday {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("You've already checked in today")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
            }

            Spacer()

            // Start button
            Button {
                viewModel.startCheckIn()
            } label: {
                HStack {
                    Image(systemName: viewModel.hasCheckedInToday ? "pencil" : "play.fill")
                    Text(viewModel.hasCheckedInToday ? "Update Check-In" : "Start Check-In")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.modusCyan)
                .cornerRadius(CornerRadius.md)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Step Views

    @ViewBuilder
    private func stepView(for step: CheckInStep) -> some View {
        VStack(spacing: 0) {
            // Step content
            stepContent(for: step)

            Spacer()

            // Navigation buttons
            stepNavigationButtons
        }
    }

    @ViewBuilder
    private func stepContent(for step: CheckInStep) -> some View {
        ScrollView {
            switch step {
            case .sleep:
                sleepStep
            case .soreness:
                sorenessStep
            case .energy:
                energyStep
            case .stress:
                stressStep
            case .pain:
                painStep
            case .notes:
                notesStep
            }
        }
    }

    // MARK: - Sleep Step

    private var sleepStep: some View {
        VStack(spacing: 24) {
            CheckInSliderQuestion(
                title: "Sleep Quality",
                subtitle: "How well did you sleep last night?",
                icon: "bed.double.fill",
                iconColor: .blue,
                minValue: 1,
                maxValue: 5,
                value: $viewModel.sleepQuality,
                minLabel: "Poor",
                maxLabel: "Excellent",
                minEmoji: "😴",
                maxEmoji: "😃",
                onValueChanged: { viewModel.updateSleepQuality($0) }
            )
            .padding(.top, 24)

            // Optional sleep hours toggle
            Toggle(isOn: $viewModel.includeSleepHours) {
                HStack {
                    Image(systemName: "clock")
                    Text("Add sleep duration")
                }
            }
            .padding(.horizontal)

            if viewModel.includeSleepHours {
                VStack(spacing: 8) {
                    Text("\(String(format: "%.1f", viewModel.sleepHours)) hours")
                        .font(.title2.bold())

                    Slider(value: $viewModel.sleepHours, in: 0...12, step: 0.5)
                        .tint(.blue)
                        .padding(.horizontal)
                }
                .transition(.opacity)
            }
        }
    }

    // MARK: - Soreness Step

    private var sorenessStep: some View {
        VStack(spacing: 24) {
            CheckInSliderQuestion(
                title: "Muscle Soreness",
                subtitle: "How sore are your muscles?",
                icon: "figure.walk",
                iconColor: .orange,
                minValue: 1,
                maxValue: 10,
                value: $viewModel.soreness,
                minLabel: "None",
                maxLabel: "Severe",
                minEmoji: "😊",
                maxEmoji: "😣",
                isInverted: true,
                onValueChanged: { viewModel.updateSoreness($0) }
            )
            .padding(.top, 24)

            // Soreness locations
            if viewModel.soreness >= 4 {
                locationSelector(
                    title: "Where are you sore?",
                    locations: $viewModel.sorenessLocations,
                    toggle: viewModel.toggleSorenessLocation
                )
                .transition(.opacity)
            }
        }
    }

    // MARK: - Energy Step

    private var energyStep: some View {
        VStack(spacing: 24) {
            CheckInSliderQuestion(
                title: "Energy Level",
                subtitle: "How energized do you feel?",
                icon: "bolt.fill",
                iconColor: .yellow,
                minValue: 1,
                maxValue: 10,
                value: $viewModel.energy,
                minLabel: "Exhausted",
                maxLabel: "Energized",
                minEmoji: "😴",
                maxEmoji: "⚡️",
                onValueChanged: { viewModel.updateEnergy($0) }
            )
            .padding(.top, 24)

            // Mood quick selector
            VStack(spacing: 12) {
                Text("How's your mood?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 16) {
                    ForEach(1...5, id: \.self) { moodValue in
                        Button {
                            viewModel.updateMood(moodValue)
                        } label: {
                            Text(moodEmoji(for: moodValue))
                                .font(.system(size: 40))
                                .opacity(viewModel.mood == moodValue ? 1.0 : 0.4)
                                .scaleEffect(viewModel.mood == moodValue ? 1.2 : 1.0)
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Stress Step

    private var stressStep: some View {
        VStack(spacing: 24) {
            CheckInSliderQuestion(
                title: "Stress Level",
                subtitle: "How stressed do you feel?",
                icon: "brain.head.profile",
                iconColor: .purple,
                minValue: 1,
                maxValue: 10,
                value: $viewModel.stress,
                minLabel: "Calm",
                maxLabel: "Stressed",
                minEmoji: "😌",
                maxEmoji: "😰",
                isInverted: true,
                onValueChanged: { viewModel.updateStress($0) }
            )
            .padding(.top, 24)
        }
    }

    // MARK: - Pain Step (Optional)

    private var painStep: some View {
        VStack(spacing: 24) {
            // Optional indicator
            HStack {
                Text("Optional")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(CornerRadius.xs)
            }
            .padding(.top, 16)

            // Pain toggle
            Toggle(isOn: $viewModel.hasPain) {
                HStack {
                    Image(systemName: "bandage.fill")
                        .foregroundColor(.red)
                    Text("I have pain today")
                        .font(.headline)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            if viewModel.hasPain {
                CheckInSliderQuestion(
                    title: "Pain Level",
                    subtitle: "Rate your pain intensity",
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .red,
                    minValue: 0,
                    maxValue: 10,
                    value: $viewModel.painScore,
                    minLabel: "None",
                    maxLabel: "Severe",
                    minEmoji: "😌",
                    maxEmoji: "😖",
                    isInverted: true,
                    onValueChanged: { viewModel.updatePainScore($0) }
                )

                locationSelector(
                    title: "Where is the pain?",
                    locations: $viewModel.painLocations,
                    toggle: viewModel.togglePainLocation
                )
            }
        }
    }

    // MARK: - Notes Step (Optional)

    private var notesStep: some View {
        VStack(spacing: 24) {
            // Optional indicator
            HStack {
                Text("Optional")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(CornerRadius.xs)
            }
            .padding(.top, 16)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(.blue)
                    Text("Anything else to note?")
                        .font(.headline)
                }

                TextEditor(text: $viewModel.freeText)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                Text("e.g., unusual stress, travel, illness, etc.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            // Live readiness preview
            readinessPreview
                .padding(.top, 16)
        }
    }

    // MARK: - Location Selector

    private func locationSelector(
        title: String,
        locations: Binding<Set<BodyLocation>>,
        toggle: @escaping (BodyLocation) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(BodyLocation.allCases) { location in
                    Button {
                        toggle(location)
                    } label: {
                        VStack(spacing: 4) {
                            Text(location.emoji)
                            Text(location.displayName)
                                .font(.caption)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(locations.wrappedValue.contains(location)
                                      ? Color.orange.opacity(0.2)
                                      : Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(locations.wrappedValue.contains(location)
                                        ? Color.orange
                                        : Color.clear, lineWidth: 2)
                        )
                    }
                    .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Readiness Preview

    private var readinessPreview: some View {
        VStack(spacing: 12) {
            Text("Your Readiness Preview")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                // Score circle
                ZStack {
                    Circle()
                        .fill(viewModel.readinessBand.color.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Text(String(format: "%.0f", viewModel.estimatedReadiness))
                        .font(.title2.bold())
                        .foregroundColor(viewModel.readinessBand.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.readinessDescription)
                        .font(.headline)
                        .foregroundColor(viewModel.readinessBand.color)

                    Text("Based on your inputs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.readinessBand.color.opacity(0.1))
            )
            .padding(.horizontal)
        }
    }

    // MARK: - Navigation Buttons

    private var stepNavigationButtons: some View {
        HStack(spacing: 16) {
            // Back button
            if !viewModel.isFirstStep {
                Button {
                    viewModel.previousStep()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.secondary)
                    .padding()
                }
            }

            Spacer()

            // Skip button (for optional steps)
            if viewModel.currentStep.isOptional {
                Button {
                    viewModel.skipStep()
                } label: {
                    Text("Skip")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }

            // Next/Review button
            Button {
                if viewModel.isLastStep {
                    withAnimation {
                        viewModel.flowState = .reviewing
                    }
                } else {
                    viewModel.nextStep()
                }
            } label: {
                HStack {
                    Text(viewModel.isLastStep ? "Review" : "Next")
                    Image(systemName: "chevron.right")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(viewModel.canProceed ? Color.modusCyan : Color.gray)
                .cornerRadius(CornerRadius.md)
            }
            .disabled(!viewModel.canProceed)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Review View

    private var reviewView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Review Your Check-In")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 24)

                // Summary cards
                VStack(spacing: 12) {
                    CompactSliderQuestion(
                        title: "Sleep Quality",
                        icon: "bed.double.fill",
                        iconColor: .blue,
                        value: viewModel.sleepQuality,
                        maxValue: 5,
                        isInverted: false
                    )

                    CompactSliderQuestion(
                        title: "Soreness",
                        icon: "figure.walk",
                        iconColor: .orange,
                        value: viewModel.soreness,
                        maxValue: 10,
                        isInverted: true
                    )

                    CompactSliderQuestion(
                        title: "Energy",
                        icon: "bolt.fill",
                        iconColor: .yellow,
                        value: viewModel.energy,
                        maxValue: 10,
                        isInverted: false
                    )

                    CompactSliderQuestion(
                        title: "Stress",
                        icon: "brain.head.profile",
                        iconColor: .purple,
                        value: viewModel.stress,
                        maxValue: 10,
                        isInverted: true
                    )

                    if viewModel.hasPain {
                        CompactSliderQuestion(
                            title: "Pain",
                            icon: "bandage.fill",
                            iconColor: .red,
                            value: viewModel.painScore,
                            maxValue: 10,
                            isInverted: true
                        )
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(CornerRadius.lg)
                .padding(.horizontal)

                // Readiness preview
                readinessPreview

                Spacer()

                // Submit button
                Button {
                    Task {
                        await viewModel.submit()
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Submit Check-In")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canSubmit ? Color.green : Color.gray)
                    .cornerRadius(CornerRadius.md)
                }
                .disabled(!viewModel.canSubmit)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Submitting View

    private var submittingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Saving your check-in...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("Something went wrong")
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                Task {
                    await viewModel.submit()
                }
            } label: {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.modusCyan)
                    .cornerRadius(CornerRadius.md)
            }

            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Morning"
        } else if hour < 17 {
            return "Afternoon"
        } else {
            return "Evening"
        }
    }

    private func moodEmoji(for value: Int) -> String {
        switch value {
        case 1: return "😢"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "😁"
        default: return "😐"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct DailyCheckInView_Previews: PreviewProvider {
    static var previews: some View {
        DailyCheckInView()
    }
}
#endif
