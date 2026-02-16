//
//  IntervalTimer.swift
//  PTPerformance
//
//  Created by Build 88 Agent 9 (Phase 3)
//  Interval timer component for Tabata, EMOM, and other time-based training
//

import SwiftUI
import AVFoundation

/// Timer state for interval training
enum IntervalTimerState {
    case ready
    case work
    case rest
    case completed
}

/// Full-screen interval timer view
struct IntervalTimerView: View {
    let intervalBlock: SessionIntervalBlock
    let onComplete: (Int, Int) -> Void  // (actualDuration, rpe)
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: IntervalTimerViewModel

    init(intervalBlock: SessionIntervalBlock, onComplete: @escaping (Int, Int) -> Void) {
        self.intervalBlock = intervalBlock
        self.onComplete = onComplete
        self._viewModel = StateObject(wrappedValue: IntervalTimerViewModel(block: intervalBlock))
    }

    var body: some View {
        ZStack {
            // Background color based on state
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 40) {
                // Header
                VStack(spacing: 8) {
                    Text(intervalBlock.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Round \(viewModel.currentRound) of \(intervalBlock.rounds)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .foregroundColor(.white)

                Spacer()

                // Main timer display
                VStack(spacing: 20) {
                    // State label (WORK / REST)
                    Text(stateLabel)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(0.9)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityLabel("State: \(stateLabel)")

                    // Countdown timer
                    Text(timeDisplay)
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .accessibilityLabel("Time remaining: \(viewModel.timeRemaining) seconds")
                        .accessibilityValue("\(viewModel.timeRemaining) seconds")
                        .accessibilityIdentifier("intervalTimer.timeDisplay")

                    // Current exercise
                    if let currentExercise = viewModel.currentExercise {
                        Text(currentExercise.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .accessibilityLabel("Exercise: \(currentExercise.name)")
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(stateLabel). Time remaining: \(viewModel.timeRemaining) seconds. Round \(viewModel.currentRound) of \(intervalBlock.rounds)")

                Spacer()

                // Controls
                HStack(spacing: 60) {
                    // Cancel button
                    Button(action: {
                        viewModel.stop()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Stop the timer and return")
                    .accessibilityIdentifier("intervalTimer.cancelButton")

                    // Play/Pause button
                    Button(action: {
                        viewModel.togglePlayPause()
                    }) {
                        Image(systemName: viewModel.isRunning ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel(viewModel.isRunning ? "Pause" : "Play")
                    .accessibilityHint(viewModel.isRunning ? "Pause the timer" : "Start the timer")
                    .accessibilityIdentifier("intervalTimer.playPauseButton")

                    // Reset button
                    Button(action: {
                        viewModel.reset()
                    }) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .accessibilityLabel("Reset")
                    .accessibilityHint("Reset timer to beginning")
                    .accessibilityIdentifier("intervalTimer.resetButton")
                }
                .padding(.bottom, 40)
            }
            .padding()
        }
        .onDisappear {
            viewModel.stop()
        }
        .sheet(isPresented: $viewModel.showCompletionSheet) {
            CompletionRPESheet(
                blockName: intervalBlock.name,
                actualDuration: viewModel.totalElapsedTime,
                onSubmit: { rpe in
                    onComplete(viewModel.totalElapsedTime, rpe)
                    dismiss()
                }
            )
        }
    }

    private var backgroundColor: Color {
        switch viewModel.state {
        case .ready:
            return Color.modusCyan.opacity(0.3)
        case .work:
            return Color.green
        case .rest:
            return Color.orange
        case .completed:
            return Color.purple.opacity(0.7)
        }
    }

    private var stateLabel: String {
        switch viewModel.state {
        case .ready:
            return "GET READY"
        case .work:
            return "WORK"
        case .rest:
            return "REST"
        case .completed:
            return "COMPLETE!"
        }
    }

    private var timeDisplay: String {
        let seconds = viewModel.timeRemaining
        return String(format: "%02d", seconds)
    }
}

/// ViewModel for interval timer
@MainActor
class IntervalTimerViewModel: ObservableObject {
    @Published var state: IntervalTimerState = .ready
    @Published var currentRound: Int = 1
    @Published var timeRemaining: Int = 0
    @Published var isRunning: Bool = false
    @Published var showCompletionSheet: Bool = false

    private let block: SessionIntervalBlock
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    private(set) var totalElapsedTime: Int = 0
    private var startTime: Date?

    init(block: SessionIntervalBlock) {
        self.block = block
        self.timeRemaining = 5  // 5-second get ready countdown
        setupAudio()
    }

    var currentExercise: IntervalExercise? {
        guard !block.exercises.isEmpty else { return nil }
        let index = (currentRound - 1) % block.exercises.count
        return block.exercises[index]
    }

    func togglePlayPause() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }

    func start() {
        guard !isRunning else { return }

        isRunning = true
        if startTime == nil {
            startTime = Date()
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }

        // Auto-start from ready state
        if state == .ready {
            state = .ready
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func stop() {
        pause()
        if let start = startTime {
            totalElapsedTime = Int(Date().timeIntervalSince(start))
        }
    }

    func reset() {
        stop()
        state = .ready
        currentRound = 1
        timeRemaining = 5
        totalElapsedTime = 0
        startTime = nil
    }

    private func tick() {
        timeRemaining -= 1

        if timeRemaining <= 0 {
            advanceState()
        }

        // Beep on last 3 seconds
        if timeRemaining <= 3 && timeRemaining > 0 {
            playBeep()
        }
    }

    private func advanceState() {
        switch state {
        case .ready:
            // Move to work interval
            state = .work
            timeRemaining = block.workDuration
            playStartBeep()

        case .work:
            // Work interval done, move to rest
            state = .rest
            timeRemaining = block.restDuration
            playEndBeep()

        case .rest:
            // Rest interval done
            if currentRound < block.rounds {
                // Next round
                currentRound += 1
                state = .work
                timeRemaining = block.workDuration
                playStartBeep()
            } else {
                // All rounds complete
                complete()
            }

        case .completed:
            break
        }
    }

    private func complete() {
        state = .completed
        isRunning = false
        timer?.invalidate()
        timer = nil

        if let start = startTime {
            totalElapsedTime = Int(Date().timeIntervalSince(start))
        }

        playCompletionBeep()

        // Show RPE sheet after 1 second delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showCompletionSheet = true
        }
    }

    // MARK: - Audio

    private func setupAudio() {
        // Configure audio session for playing sounds even in silent mode
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            DebugLogger.shared.warning("IntervalTimerComponent", "Failed to setup audio session: \(error.localizedDescription)")
        }
    }

    private func playBeep() {
        // Use system sound for countdown beeps
        AudioServicesPlaySystemSound(1057)  // Tock sound
    }

    private func playStartBeep() {
        // Use system sound for work interval start
        AudioServicesPlaySystemSound(1073)  // SMS Received sound
    }

    private func playEndBeep() {
        // Use system sound for work interval end
        AudioServicesPlaySystemSound(1052)  // Short beep
    }

    private func playCompletionBeep() {
        // Use system sound for completion
        AudioServicesPlaySystemSound(1025)  // SMS Alert sound
    }

    deinit {
        timer?.invalidate()
    }
}

/// RPE rating sheet after interval block completion
struct CompletionRPESheet: View {
    let blockName: String
    let actualDuration: Int
    let onSubmit: (Int) -> Void

    @State private var selectedRPE: Int = 5
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)

                    Text("Interval Block Complete!")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(blockName)
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text(durationDisplay)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 30)

                // RPE Selector
                VStack(spacing: 20) {
                    Text("How hard was this warmup?")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)

                    Text("Rate of Perceived Exertion (RPE)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // RPE Scale
                    VStack(spacing: 12) {
                        Picker("RPE", selection: $selectedRPE) {
                            ForEach(0...10, id: \.self) { rpe in
                                Text("\(rpe)").tag(rpe)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 150)
                        .accessibilityLabel("Rate of Perceived Exertion")
                        .accessibilityValue("\(selectedRPE) out of 10. \(rpeDescription)")
                        .accessibilityHint("Swipe up or down to change RPE value")
                        .accessibilityIdentifier("intervalTimer.rpePicker")

                        // RPE description
                        Text(rpeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .accessibilityLabel(rpeDescription)
                    }
                }

                Spacer()

                // Submit button
                Button(action: {
                    onSubmit(selectedRPE)
                    dismiss()
                }) {
                    Text("Save & Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.modusCyan)
                        .cornerRadius(CornerRadius.md)
                }
                .accessibilityLabel("Save and Continue")
                .accessibilityHint("Save RPE rating of \(selectedRPE) and return to workout")
                .accessibilityIdentifier("intervalTimer.submitButton")
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        onSubmit(5)  // Default to moderate
                        dismiss()
                    }
                }
            }
        }
    }

    private var durationDisplay: String {
        let minutes = actualDuration / 60
        let seconds = actualDuration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var rpeDescription: String {
        switch selectedRPE {
        case 0...1:
            return "Very Light - No exertion"
        case 2...3:
            return "Light - Easy pace"
        case 4...5:
            return "Moderate - Comfortable"
        case 6...7:
            return "Hard - Challenging"
        case 8...9:
            return "Very Hard - Difficult"
        case 10:
            return "Maximum - All-out effort"
        default:
            return ""
        }
    }
}

// MARK: - Preview

#if DEBUG
struct IntervalTimerView_Previews: PreviewProvider {
    static var previews: some View {
        IntervalTimerView(
            intervalBlock: .sampleTabata,
            onComplete: { duration, rpe in
                #if DEBUG
                print("Completed: \(duration)s, RPE: \(rpe)")
                #endif
            }
        )
    }
}
#endif
