//
//  IntervalBlockView.swift
//  PTPerformance
//
//  Created by Build 88 Agent 9 (Phase 3)
//  Views for displaying and interacting with interval blocks
//

import SwiftUI

/// Card displaying an interval block (warmup/cooldown)
struct IntervalBlockCard: View {
    let block: SessionIntervalBlock
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    // Icon
                    Image(systemName: iconName)
                        .font(.system(size: 24))
                        .foregroundColor(iconColor)
                        .frame(width: 40, height: 40)
                        .background(iconColor.opacity(0.15))
                        .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(block.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(block.blockTypeDisplay)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Completion checkmark
                    if block.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                }

                // Description
                if let description = block.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Timing info
                HStack(spacing: 16) {
                    Label(block.timingDisplay, systemImage: "clock.fill")
                    Label(block.roundsDisplay, systemImage: "repeat")
                }
                .font(.caption)
                .foregroundColor(.secondary)

                // Exercises preview
                if !block.exercises.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(block.exercises.indices, id: \.self) { index in
                                ExercisePill(exercise: block.exercises[index])
                            }
                        }
                    }
                }

                // Completion info
                if block.isCompleted {
                    HStack {
                        if let rpe = block.sessionRpe {
                            Label("RPE: \(rpe)/10", systemImage: "figure.run")
                        }

                        if let duration = block.totalDuration {
                            let minutes = duration / 60
                            let seconds = duration % 60
                            Label(String(format: "%d:%02d", minutes, seconds), systemImage: "timer")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.green)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        if block.isCompleted {
            return "checkmark.circle.fill"
        }
        switch block.blockType {
        case "mobility":
            return "figure.flexibility"
        case "endurance":
            return "flame.fill"
        case "recovery":
            return "heart.fill"
        default:
            return "timer"
        }
    }

    private var iconColor: Color {
        if block.isCompleted {
            return .green
        }
        switch block.blockType {
        case "mobility":
            return .blue
        case "endurance":
            return .orange
        case "recovery":
            return .purple
        default:
            return .gray
        }
    }

    private var backgroundColor: Color {
        if block.isCompleted {
            return Color.green.opacity(0.05)
        }
        return Color(.systemBackground)
    }

    private var borderColor: Color {
        if block.isCompleted {
            return .green.opacity(0.3)
        }
        return Color(.systemGray5)
    }
}

/// Small pill displaying an exercise name
struct ExercisePill: View {
    let exercise: IntervalExercise

    var body: some View {
        HStack(spacing: 4) {
            if exercise.hasVideo {
                Image(systemName: "play.circle.fill")
                    .font(.caption2)
            }

            Text(exercise.name)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(12)
    }
}

/// Section view for displaying interval blocks grouped by type
struct IntervalBlocksSection: View {
    let blocks: [SessionIntervalBlock]
    let title: String
    let onBlockTap: (SessionIntervalBlock) -> Void

    var body: some View {
        if !blocks.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    ForEach(blocks) { block in
                        IntervalBlockCard(block: block) {
                            onBlockTap(block)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct IntervalBlockCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Not completed
            IntervalBlockCard(block: .sampleTabata) {
                print("Tapped warmup")
            }
            .padding()

            // Completed
            IntervalBlockCard(block: .sampleCompleted) {
                print("Tapped completed warmup")
            }
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif
