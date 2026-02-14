//
//  ExerciseCuesCard.swift
//  PTPerformance
//
//  Build 61: Exercise technique cues display (ACP-156)
//

import SwiftUI

/// Card displaying exercise technique cues organized by setup, execution, and breathing
struct ExerciseCuesCard: View {
    let techniqueCues: Exercise.TechniqueCues

    var body: some View {
        VStack(spacing: 16) {
            // Setup section
            if !techniqueCues.setup.isEmpty {
                CueSection(
                    title: "Setup",
                    icon: "figure.stand",
                    iconColor: .modusCyan,
                    cues: techniqueCues.setup
                )
            }

            // Execution section
            if !techniqueCues.execution.isEmpty {
                CueSection(
                    title: "Execution",
                    icon: "figure.strengthtraining.traditional",
                    iconColor: .green,
                    cues: techniqueCues.execution
                )
            }

            // Breathing section
            if !techniqueCues.breathing.isEmpty {
                CueSection(
                    title: "Breathing",
                    icon: "wind",
                    iconColor: .orange,
                    cues: techniqueCues.breathing
                )
            }
        }
    }
}

// MARK: - Cue Section

struct CueSection: View {
    let title: String
    let icon: String
    let iconColor: Color
    let cues: [String]

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                // Section header
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.title3)
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }

                // Cues list
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(cues.indices, id: \.self) { index in
                        HStack(alignment: .top, spacing: 10) {
                            // Bullet point
                            Circle()
                                .fill(iconColor)
                                .frame(width: 6, height: 6)
                                .padding(.top, 7)

                            // Cue text
                            Text(cues[index])
                                .font(.body)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .groupBoxStyle(CueGroupBoxStyle(accentColor: iconColor))
    }
}

// MARK: - Custom GroupBox Style

struct CueGroupBoxStyle: GroupBoxStyle {
    let accentColor: Color

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            configuration.content
                .padding(Spacing.md)
        }
        .background(accentColor.opacity(0.05))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(accentColor.opacity(0.2), lineWidth: 1.5)
        )
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ExerciseCuesCard(
                techniqueCues: Exercise.TechniqueCues(
                    setup: [
                        "Feet shoulder-width apart",
                        "Bar resting on upper traps (high bar) or rear delts (low bar)",
                        "Hands gripping bar slightly wider than shoulders",
                        "Core braced, chest up",
                        "Eyes looking slightly down and forward"
                    ],
                    execution: [
                        "Push knees out slightly as you descend",
                        "Hips move back and down simultaneously",
                        "Keep chest up and maintain neutral spine",
                        "Descend until thighs are parallel or below",
                        "Drive through heels to stand up",
                        "Keep core tight throughout the movement"
                    ],
                    breathing: [
                        "Take a deep breath in at the top before descending",
                        "Hold breath (Valsalva maneuver) during the descent",
                        "Maintain breath hold at the bottom and during initial ascent",
                        "Exhale as you complete the lift and reach the top"
                    ]
                )
            )
            .padding()

            // Alternative example with fewer cues
            ExerciseCuesCard(
                techniqueCues: Exercise.TechniqueCues(
                    setup: [
                        "Lie flat on bench",
                        "Feet flat on floor",
                        "Grip bar slightly wider than shoulders"
                    ],
                    execution: [
                        "Lower bar to chest with control",
                        "Press bar straight up",
                        "Keep elbows at 45-degree angle"
                    ],
                    breathing: [
                        "Breathe in as you lower",
                        "Exhale as you press up"
                    ]
                )
            )
            .padding()
        }
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
