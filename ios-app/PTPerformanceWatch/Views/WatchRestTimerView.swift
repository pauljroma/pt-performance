//
//  WatchRestTimerView.swift
//  PTPerformanceWatch
//
//  Circular rest timer with haptic feedback
//  ACP-824: Apple Watch Standalone App
//

import SwiftUI
import WatchKit

struct WatchRestTimerView: View {
    let duration: Int
    let onComplete: () -> Void
    let onSkip: () -> Void

    @State private var timeRemaining: Int
    @State private var isActive = true
    @State private var timer: Timer?
    @State private var lastHapticPulse: Int = 0

    private let hapticIntervals = [15, 30, 45, 60, 90, 120] // Haptic pulse points

    init(duration: Int, onComplete: @escaping () -> Void, onSkip: @escaping () -> Void) {
        self.duration = duration
        self.onComplete = onComplete
        self.onSkip = onSkip
        self._timeRemaining = State(initialValue: duration)
    }

    private var progress: Double {
        guard duration > 0 else { return 0 }
        return Double(duration - timeRemaining) / Double(duration)
    }

    private var timeDisplay: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        return "\(seconds)"
    }

    private var progressColor: Color {
        if timeRemaining <= 5 {
            return .red
        } else if timeRemaining <= 15 {
            return .orange
        }
        return .blue
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("REST")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fontWeight(.semibold)

            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)

                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        progressColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                // Time display
                VStack(spacing: 2) {
                    Text(timeDisplay)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(progressColor)

                    if timeRemaining > 60 {
                        Text("sec")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 120, height: 120)
            .padding(.vertical, 8)

            // Controls
            HStack(spacing: 16) {
                // Add 30 seconds
                Button {
                    addTime(30)
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                }
                .buttonStyle(.plain)

                // Skip button
                Button {
                    stopTimer()
                    onSkip()
                } label: {
                    Text("Skip")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .tint(.orange)

                // Subtract 15 seconds
                Button {
                    subtractTime(15)
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - Timer Control

    private func startTimer() {
        isActive = true
        lastHapticPulse = duration
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            tick()
        }
    }

    private func stopTimer() {
        isActive = false
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard isActive else { return }

        if timeRemaining > 0 {
            timeRemaining -= 1

            // Check for haptic pulse intervals
            checkHapticPulse()

            // Final countdown haptics
            if timeRemaining <= 3 && timeRemaining > 0 {
                WatchHapticService.shared.restIntervalPulse()
            }

            // Complete
            if timeRemaining == 0 {
                stopTimer()
                WatchHapticService.shared.restComplete()
                onComplete()
            }
        }
    }

    private func checkHapticPulse() {
        // Find if we've crossed a haptic interval threshold
        for interval in hapticIntervals.reversed() {
            if timeRemaining == interval && lastHapticPulse != interval {
                WatchHapticService.shared.restIntervalPulse()
                lastHapticPulse = interval
                break
            }
        }
    }

    private func addTime(_ seconds: Int) {
        timeRemaining += seconds
        WatchHapticService.shared.selection()
    }

    private func subtractTime(_ seconds: Int) {
        timeRemaining = max(0, timeRemaining - seconds)
        WatchHapticService.shared.selection()

        if timeRemaining == 0 {
            stopTimer()
            onComplete()
        }
    }
}

// MARK: - Preview

#Preview {
    WatchRestTimerView(
        duration: 90,
        onComplete: {},
        onSkip: {}
    )
}
