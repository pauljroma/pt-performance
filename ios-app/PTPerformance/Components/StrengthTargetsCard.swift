//
//  StrengthTargetsCard.swift
//  PTPerformance
//
//  Display estimated 1RM and recommended training loads
//

import SwiftUI

struct StrengthTargetsCard: View {
    let exercise: Exercise
    let oneRepMax: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(.blue)
                Text("Strength Targets")
                    .font(.headline)
            }

            if let rm = oneRepMax {
                VStack(alignment: .leading, spacing: 12) {
                    // 1RM Display
                    HStack {
                        Text("Estimated 1RM:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(rm)) lbs")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }

                    Divider()

                    // Training Zones
                    VStack(spacing: 10) {
                        TargetRow(
                            goal: "Strength",
                            percentage: 0.85,
                            oneRM: rm,
                            color: .red,
                            icon: "bolt.fill"
                        )

                        TargetRow(
                            goal: "Hypertrophy",
                            percentage: 0.70,
                            oneRM: rm,
                            color: .orange,
                            icon: "figure.arms.open"
                        )

                        TargetRow(
                            goal: "Endurance",
                            percentage: 0.50,
                            oneRM: rm,
                            color: .green,
                            icon: "arrow.clockwise"
                        )
                    }
                }
            } else {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("Log exercises with this patient to see strength targets")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }
}

struct TargetRow: View {
    let goal: String
    let percentage: Double
    let oneRM: Double
    let color: Color
    let icon: String

    var targetWeight: Int {
        Int(oneRM * percentage)
    }

    var repRange: String {
        switch percentage {
        case 0.85...:
            return "1-5 reps"
        case 0.65..<0.85:
            return "6-12 reps"
        default:
            return "12-20 reps"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(goal)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(repRange)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(targetWeight) lbs")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)

                Text("\(Int(percentage * 100))% of 1RM")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// Preview
#if DEBUG
struct StrengthTargetsCard_Previews: PreviewProvider {
    static var sampleExercise: Exercise {
        Exercise(
            id: UUID(),
            session_id: UUID(),
            exercise_template_id: UUID(),
            sequence: 1,
            target_sets: 3,
            target_reps: 10,
            prescribed_sets: nil,
            prescribed_reps: "8-10",
            prescribed_load: 135,
            load_unit: "lbs",
            rest_period_seconds: 90,
            notes: nil,
            exercise_templates: Exercise.ExerciseTemplate(
                id: UUID(),
                name: "Bench Press",
                category: "push",
                body_region: "upper",
                videoUrl: nil,
                videoThumbnailUrl: nil,
                videoDuration: nil,
                formCues: nil,
                techniqueCues: nil,
                commonMistakes: nil,
                safetyNotes: nil
            )
        )
    }

    static var previews: some View {
        VStack(spacing: 16) {
            // With 1RM
            StrengthTargetsCard(
                exercise: sampleExercise,
                oneRepMax: 185
            )

            // Without 1RM
            StrengthTargetsCard(
                exercise: sampleExercise,
                oneRepMax: nil
            )
        }
        .padding()
    }
}
#endif
