//
//  WorkoutProgressHeader.swift
//  PTPerformance
//
//  Extracted from ManualWorkoutExecutionView.swift
//  Displays workout progress with timer, completion count, and progress bar
//

import SwiftUI

/// Progress header displaying elapsed time, exercise completion count, and progress bar
struct WorkoutProgressHeader: View {
    let elapsedTimeDisplay: String
    let progressText: String
    let completedCount: Int
    let totalExercises: Int
    let progressPercentage: Double
    @Binding var isTimerVisible: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Timer and Progress Row
            HStack {
                // Elapsed Time (conditionally visible, but always tracked)
                if isTimerVisible {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Time")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.blue)
                            Text(elapsedTimeDisplay)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                    }
                }

                Spacer()

                // Timer visibility toggle button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isTimerVisible.toggle()
                    }
                } label: {
                    Image(systemName: isTimerVisible ? "eye.fill" : "eye.slash.fill")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.sm)
                }
                .accessibilityLabel(isTimerVisible ? "Hide timer" : "Show timer")

                Spacer()

                // Progress
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(progressText)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green)
                        .frame(width: geometry.size.width * progressPercentage, height: 8)
                        .animation(.easeInOut, value: progressPercentage)
                }
            }
            .frame(height: 8)
            .accessibilityHidden(true)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Workout progress: \(completedCount) of \(totalExercises) exercises completed, elapsed time \(elapsedTimeDisplay)")
    }
}

// MARK: - Preview

#if DEBUG
struct WorkoutProgressHeader_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutProgressHeader(
            elapsedTimeDisplay: "12:34",
            progressText: "3 / 5",
            completedCount: 3,
            totalExercises: 5,
            progressPercentage: 0.6,
            isTimerVisible: .constant(true)
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
