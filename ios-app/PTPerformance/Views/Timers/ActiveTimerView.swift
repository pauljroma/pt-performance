//
//  ActiveTimerView.swift
//  PTPerformance
//
//  Created by BUILD 116 Agent 20 (Active Timer View)
//  Full-screen countdown timer display for active workouts
//

import SwiftUI
import Combine
import UIKit

/// Full-screen countdown timer view with phase tracking and controls
/// Displays huge timer with 0.1s precision, phase indicators, and progress
struct ActiveTimerView: View {
    // MARK: - Dependencies

    @StateObject private var viewModel: ActiveTimerViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Timer State

    /// Timer publisher for 0.1s precision updates
    @State private var timerPublisher = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    /// Whether audio cues are enabled
    @State private var audioEnabled: Bool = true

    /// Whether to show stop confirmation
    @State private var showStopConfirmation = false

    /// Whether to show completion screen
    @State private var showCompletionScreen = false

    // MARK: - Initialization

    init(template: IntervalTemplate, patientId: UUID) {
        // Use shared timer service instance to preserve state
        let timerService = IntervalTimerService.shared
        _viewModel = StateObject(wrappedValue: ActiveTimerViewModel(timerService: timerService))

        // Start timer immediately
        Task {
            try? await timerService.startTimer(template: template, patientId: patientId)
            // Haptic feedback for timer start
            await MainActor.run {
                HapticFeedback.medium()
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Full-screen phase color background
            phaseBackgroundColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentPhase)

            if viewModel.state == .completed {
                completionScreen
            } else {
                activeTimerContent
            }
        }
        .preferredColorScheme(.dark) // Force dark mode for better contrast
        .onReceive(timerPublisher) { _ in
            viewModel.update()
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onAppear {
            keepScreenAwake(true)
            viewModel.loadActiveTimer()
        }
        .onDisappear {
            keepScreenAwake(false)
        }
        .onChange(of: viewModel.state) { oldState, newState in
            // Haptic feedback for timer completion
            if newState == .completed && oldState != .completed {
                HapticFeedback.success()
            }
        }
        .alert("Stop Timer?", isPresented: $showStopConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Stop & Save", role: .destructive) {
                Task {
                    await viewModel.stopTimer()
                    // Haptic feedback for timer stop
                    HapticFeedback.warning()
                    showCompletionScreen = true
                }
            }
        } message: {
            Text("Are you sure you want to stop this workout? Your progress will be saved.")
        }
    }

    // MARK: - Active Timer Content

    private var activeTimerContent: some View {
        VStack(spacing: 0) {
            // Top bar with progress and stop button
            topBar

            Spacer()

            // Main timer display
            mainTimerDisplay

            Spacer()

            // Bottom controls
            bottomControls
        }
        .padding(.vertical, 40)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(spacing: 12) {
            // Linear progress bar
            ProgressView(value: viewModel.roundProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color(.label)))
                .scaleEffect(y: 3) // Make progress bar thicker
                .padding(.horizontal, 40)

            HStack {
                // Round status
                Text(viewModel.roundStatusText)
                    .font(.headline)
                    .foregroundColor(Color(.label).opacity(0.9))

                Spacer()

                // Stop button
                Button(action: {
                    showStopConfirmation = true
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Color(.label))
                }
                .accessibilityLabel("Stop timer")
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Main Timer Display

    private var mainTimerDisplay: some View {
        VStack(spacing: 40) {
            // Phase indicator
            Text(viewModel.phaseDisplayName)
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundColor(Color(.label))
                .shadow(color: Color(.systemBackground).opacity(0.3), radius: 10)
                .accessibilityAddTraits(.isHeader)

            // Huge countdown timer with circular progress ring
            ZStack {
                // Circular progress ring
                Circle()
                    .stroke(Color(.label).opacity(0.2), lineWidth: 20)
                    .frame(width: 320, height: 320)

                Circle()
                    .trim(from: 0, to: phaseProgress)
                    .stroke(Color(.label), lineWidth: 20)
                    .frame(width: 320, height: 320)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: phaseProgress)

                // Timer text (80% of screen)
                Text(viewModel.formattedTimeRemaining)
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundColor(Color(.label))
                    .shadow(color: Color(.systemBackground).opacity(0.5), radius: 10)
                    .scaleEffect(isLastThreeSeconds ? pulseScale : 1.0)
                    .animation(
                        isLastThreeSeconds
                            ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
                            : .default,
                        value: isLastThreeSeconds
                    )
                    .accessibilityLabel("Time remaining: \(viewModel.formattedTimeRemaining)")
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1) // Limit max size for layout
            }

            // Template name
            Text(viewModel.templateName)
                .font(.title2)
                .foregroundColor(Color(.label).opacity(0.8))
                .accessibilityLabel("Template: \(viewModel.templateName)")
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 24) {
            // Play/Pause button (large)
            Button(action: {
                if viewModel.canPause {
                    viewModel.pauseTimer()
                    // Haptic feedback for pause
                    HapticFeedback.medium()
                } else if viewModel.canResume {
                    viewModel.resumeTimer()
                    // Haptic feedback for resume
                    HapticFeedback.medium()
                }
            }) {
                Image(systemName: viewModel.canPause ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(Color(.label))
                    .shadow(color: Color(.systemBackground).opacity(0.3), radius: 10)
            }
            .accessibilityLabel(viewModel.canPause ? "Pause timer" : "Resume timer")

            // Audio toggle
            Button(action: {
                audioEnabled.toggle()
            }) {
                HStack {
                    Image(systemName: audioEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                        .font(.title3)
                    Text(audioEnabled ? "Audio On" : "Audio Off")
                        .font(.headline)
                }
                .foregroundColor(Color(.label).opacity(0.7))
            }
            .accessibilityLabel("Toggle audio cues")
            .accessibilityValue(audioEnabled ? "On" : "Off")

            // Total elapsed time
            Text("Total: \(viewModel.formattedTotalElapsed)")
                .font(.caption)
                .foregroundColor(Color(.label).opacity(0.5))
                .accessibilityLabel("Total elapsed time: \(viewModel.formattedTotalElapsed)")
        }
    }

    // MARK: - Completion Screen

    private var completionScreen: some View {
        ZStack {
            // Green background for completion
            Color.green.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 120))
                    .foregroundColor(Color(.label))
                    .accessibilityHidden(true)

                // Title
                Text("Workout Complete!")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(Color(.label))
                    .accessibilityAddTraits(.isHeader)

                // Stats
                VStack(spacing: 20) {
                    statsRow(label: "Total Time", value: viewModel.formattedTotalElapsed)
                    statsRow(label: "Rounds Completed", value: "\(viewModel.currentRound) of \(viewModel.totalRounds)")
                    if !viewModel.templateName.isEmpty {
                        statsRow(label: "Template", value: viewModel.templateName)
                    }
                }
                .padding(.horizontal, 40)

                Spacer()

                // Close button
                Button(action: {
                    dismiss()
                }) {
                    Text("Save & Close")
                        .font(.title2.bold())
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color(.systemBackground))
                        .cornerRadius(CornerRadius.lg)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)
                .accessibilityLabel("Save and Close")
                .accessibilityHint("Saves your workout and returns to timer selection")
            }
        }
    }

    private func statsRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.title3)
                .foregroundColor(Color(.label).opacity(0.9))
            Spacer()
            Text(value)
                .font(.title3.bold())
                .foregroundColor(Color(.label))
        }
        .padding(.vertical, 8)
    }

    // MARK: - Computed Properties

    /// Phase background color based on current phase
    private var phaseBackgroundColor: Color {
        switch viewModel.currentPhase {
        case .work:
            return Color(red: 1.0, green: 0.23, blue: 0.19) // #FF3B30
        case .rest:
            return Color(red: 0.20, green: 0.78, blue: 0.35) // #34C759
        case .break:
            return Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF
        }
    }

    /// Phase progress as fraction (0.0 to 1.0) for circular ring
    private var phaseProgress: CGFloat {
        let phaseDuration: Double
        switch viewModel.currentPhase {
        case .work:
            phaseDuration = Double(viewModel.workSeconds)
        case .rest:
            phaseDuration = Double(viewModel.restSeconds)
        case .break:
            phaseDuration = 60.0 // Default 60s break
        }

        guard phaseDuration > 0 else { return 0 }

        let elapsed = phaseDuration - viewModel.timeRemaining
        return CGFloat(elapsed / phaseDuration)
    }

    /// Whether we're in the last 3 seconds (for pulsing animation)
    private var isLastThreeSeconds: Bool {
        return viewModel.timeRemaining <= 3.0 && viewModel.timeRemaining > 0
    }

    /// Pulse scale for last 3 seconds animation
    private var pulseScale: CGFloat {
        return isLastThreeSeconds ? 1.1 : 1.0
    }

    // MARK: - Helper Methods

    /// Keep screen awake during workout
    private func keepScreenAwake(_ awake: Bool) {
        UIApplication.shared.isIdleTimerDisabled = awake
    }

    /// Handle scene phase changes (background/foreground)
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            viewModel.handleAppWillBackground()
        case .active:
            Task {
                await viewModel.handleAppWillForeground()
            }
        default:
            break
        }
    }
}

// MARK: - Preview Support

#Preview("Active - Work Phase") {
    ActiveTimerView(
        template: IntervalTemplate.sample,
        patientId: UUID()
    )
}

#Preview("Active - Rest Phase") {
    let template = IntervalTemplate(
        id: UUID(),
        name: "EMOM 10",
        type: .emom,
        workSeconds: 40,
        restSeconds: 20,
        rounds: 10,
        cycles: 1,
        createdBy: nil,
        isPublic: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    return ActiveTimerView(
        template: template,
        patientId: UUID()
    )
}

#Preview("Completed") {
    let template = IntervalTemplate(
        id: UUID(),
        name: "5 Min AMRAP",
        type: .amrap,
        workSeconds: 300,
        restSeconds: 0,
        rounds: 1,
        cycles: 1,
        createdBy: nil,
        isPublic: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    return ActiveTimerView(
        template: template,
        patientId: UUID()
    )
}
