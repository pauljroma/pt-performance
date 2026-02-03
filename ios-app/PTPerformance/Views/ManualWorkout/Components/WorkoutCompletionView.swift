//
//  WorkoutCompletionView.swift
//  PTPerformance
//
//  Extracted from ManualWorkoutExecutionView.swift
//  Displays workout completion summary with stats
//

import SwiftUI

/// View displaying workout completion summary with duration, volume, RPE, and pain stats
struct WorkoutCompletionView: View {
    let workoutName: String
    let elapsedTimeDisplay: String
    let completedCount: Int
    let totalExercises: Int
    let volumeDisplay: String
    let averageRPE: Double?
    let averagePain: Double?
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .padding(.top, 40)
                    .accessibilityHidden(true)

                Text("Workout Complete!")
                    .font(.title)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)

                Text(workoutName)
                    .font(.title3)
                    .foregroundColor(.secondary)

                // Summary Stats
                VStack(spacing: 16) {
                    summaryStatRow(title: "Duration", value: elapsedTimeDisplay, icon: "clock.fill", color: .blue)
                    summaryStatRow(title: "Exercises", value: "\(completedCount)/\(totalExercises)", icon: "list.bullet", color: .purple)
                    summaryStatRow(title: "Total Volume", value: volumeDisplay, icon: "scalemass.fill", color: .green)

                    if let avgRpe = averageRPE {
                        summaryStatRow(title: "Avg RPE", value: String(format: "%.1f", avgRpe), icon: "bolt.fill", color: rpeColor(Int(avgRpe)))
                    }

                    if let avgPain = averagePain {
                        summaryStatRow(title: "Avg Pain", value: String(format: "%.1f", avgPain), icon: "hand.raised.fill", color: painColor(Int(avgPain)))
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Done Button
                Button {
                    onDismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.top, 16)
                .accessibilityLabel("Done")
                .accessibilityHint("Closes workout summary and returns to home")
            }
            .padding()
        }
    }

    private func summaryStatRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
                .accessibilityHidden(true)

            Text(title)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.headline)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Color Helpers

    private func rpeColor(_ value: Int) -> Color {
        switch value {
        case 1...4: return .green
        case 5...7: return .yellow
        case 8...9: return .orange
        case 10: return .red
        default: return .gray
        }
    }

    private func painColor(_ value: Int) -> Color {
        switch value {
        case 0...2: return .green
        case 3...4: return .yellow
        case 5...6: return .orange
        case 7...10: return .red
        default: return .gray
        }
    }
}

// MARK: - Preview

#if DEBUG
struct WorkoutCompletionView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutCompletionView(
            workoutName: "Upper Body Strength",
            elapsedTimeDisplay: "45:23",
            completedCount: 5,
            totalExercises: 5,
            volumeDisplay: "12.5k lbs",
            averageRPE: 7.5,
            averagePain: 2.0,
            onDismiss: {}
        )
    }
}
#endif
