//
//  RestTimerOverlay.swift
//  PTPerformance
//
//  Extracted from ManualWorkoutExecutionView.swift
//  Full-screen overlay for rest timer between exercises
//

import SwiftUI

/// Full-screen overlay for rest timer between exercises
struct RestTimerOverlay: View {
    let timeRemaining: TimeInterval
    let totalTime: TimeInterval
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Rest")
                .font(.title2)
                .foregroundColor(.secondary)

            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: totalTime > 0 ? timeRemaining / totalTime : 0)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timeRemaining)

                Text(formatTime(timeRemaining))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .frame(width: 200, height: 200)

            Text("Next exercise coming up...")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Button {
                HapticFeedback.light()
                onSkip()
            } label: {
                HStack {
                    Image(systemName: "forward.fill")
                    Text("Skip Rest")
                }
                .font(.headline)
                .foregroundColor(.blue)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .stroke(Color.blue, lineWidth: 2)
                )
            }
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rest timer, \(Int(timeRemaining)) seconds remaining")
        .accessibilityValue("\(Int(timeRemaining)) seconds")
        .accessibilityHint("Swipe up or tap Skip Rest to continue to next exercise")
        .accessibilityAddTraits(.updatesFrequently)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Preview

#if DEBUG
struct RestTimerOverlay_Previews: PreviewProvider {
    static var previews: some View {
        RestTimerOverlay(
            timeRemaining: 45,
            totalTime: 90,
            onSkip: {}
        )
    }
}
#endif
