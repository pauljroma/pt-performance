//
//  ExerciseDetailSheet.swift
//  PTPerformance
//
//  BUILD 170: Exercise alternative videos & explanations (ACP-587)
//  Feature #1: Exercise Detail Modal
//

import SwiftUI

/// Full-screen modal displaying exercise video and detailed instructions
struct ExerciseDetailSheet: View {
    let substitution: ExerciseSubstitution
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // MARK: - Video Section
                    videoSection

                    // MARK: - Overview Section
                    overviewSection

                    // MARK: - How to Perform Section
                    if let techniqueCues = substitution.techniqueCues {
                        howToPerformSection(cues: techniqueCues)
                    }

                    // MARK: - Equipment & Muscles Section
                    equipmentAndMusclesSection

                    // MARK: - Safety Section
                    if let safetyNotes = substitution.safetyNotes {
                        safetySection(notes: safetyNotes)
                    }

                    // MARK: - Common Mistakes Section
                    if let commonMistakes = substitution.commonMistakes {
                        commonMistakesSection(mistakes: commonMistakes)
                    }

                    // Bottom padding for scrolling
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.xs)
            }
            .navigationTitle(substitution.exerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Video Section

    @ViewBuilder
    private var videoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let videoUrl = substitution.videoUrl {
                // Real video player
                VideoPlayerView(videoUrl: videoUrl)
                    .frame(height: 250)
                    .cornerRadius(CornerRadius.md)
                    .adaptiveShadow(Shadow.medium)
            } else {
                // Placeholder when video not available
                videoPlaceholder
            }
        }
    }

    private var videoPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 250)

            VStack(spacing: 16) {
                Image(systemName: "video.badge.plus")
                    .font(.system(size: 50))
                    .foregroundColor(.gray.opacity(0.5))

                VStack(spacing: 4) {
                    Text("Video Coming Soon")
                        .font(.headline)
                        .foregroundColor(.gray)

                    Text("Instructional video will be added")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                }
            }
        }
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why This Exercise")
                .font(.headline)
                .foregroundColor(.primary)

            Text(substitution.rationale)
                .font(.body)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                // Difficulty badge
                if let difficulty = substitution.difficultyLevel {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption)
                        Text(difficulty)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(CornerRadius.sm)
                }

                // Confidence badge
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                    Text("\(substitution.confidence)% Match")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.green)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(CornerRadius.sm)
            }
        }
        .padding(Spacing.md)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - How to Perform Section

    private func howToPerformSection(cues: TechniqueCues) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How to Perform")
                .font(.headline)
                .foregroundColor(.primary)

            // Setup cues
            if !cues.setup.isEmpty {
                cueGroup(
                    title: "Setup",
                    icon: "figure.stand",
                    cues: cues.setup,
                    color: .blue
                )
            }

            // Execution cues
            if !cues.execution.isEmpty {
                cueGroup(
                    title: "Execution",
                    icon: "figure.strengthtraining.traditional",
                    cues: cues.execution,
                    color: .purple
                )
            }

            // Breathing cues
            if !cues.breathing.isEmpty {
                cueGroup(
                    title: "Breathing",
                    icon: "lungs.fill",
                    cues: cues.breathing,
                    color: .teal
                )
            }
        }
        .padding(Spacing.md)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    private func cueGroup(title: String, icon: String, cues: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(cues.enumerated()), id: \.offset) { index, cue in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .trailing)

                        Text(cue)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.leading, 28)
        }
    }

    // MARK: - Equipment & Muscles Section

    private var equipmentAndMusclesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Equipment
            if let equipment = substitution.equipment, !equipment.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "dumbbell.fill")
                            .foregroundColor(.modusCyan)
                        Text("Equipment Needed")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.modusCyan)
                    }

                    FlowLayout(spacing: 8) {
                        ForEach(equipment, id: \.self) { item in
                            Text(item)
                                .font(.caption)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, 6)
                                .background(Color.modusCyan.opacity(0.1))
                                .foregroundColor(.modusCyan)
                                .cornerRadius(CornerRadius.sm)
                        }
                    }
                }
            }

            // Muscles
            if let muscles = substitution.musclesTargeted, !muscles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.arms.open")
                            .foregroundColor(.green)
                        Text("Muscles Targeted")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }

                    FlowLayout(spacing: 8) {
                        ForEach(muscles, id: \.self) { muscle in
                            Text(muscle)
                                .font(.caption)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(CornerRadius.sm)
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Safety Section

    private func safetySection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Safety Notes")
                    .font(.headline)
                    .foregroundColor(.orange)
            }

            Text(notes)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding(Spacing.md)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Common Mistakes Section

    private func commonMistakesSection(mistakes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text("Common Mistakes")
                    .font(.headline)
                    .foregroundColor(.red)
            }

            Text(mistakes)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding(Spacing.md)
        .background(Color.red.opacity(0.05))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    ExerciseDetailSheet(
        substitution: ExerciseSubstitution(
            from: ExerciseSubstitutionItem(
                originalExerciseId: "123",
                originalExerciseName: "Barbell Bench Press",
                substituteExerciseId: "456",
                substituteExerciseName: "Dumbbell Bench Press",
                reason: "Dumbbell variation allows for better shoulder positioning and can be performed with minimal equipment.",
                videoUrl: nil,
                videoThumbnailUrl: nil,
                techniqueCues: TechniqueCues(
                    setup: ["Lie flat on bench", "Feet flat on floor", "Hold dumbbells above chest"],
                    execution: ["Lower dumbbells with control", "Press up while squeezing chest", "Keep elbows at 45 degrees"],
                    breathing: ["Inhale on descent", "Exhale on press"]
                ),
                formCues: nil,
                commonMistakes: "Flaring elbows too wide, arching back excessively, using momentum instead of control.",
                safetyNotes: "Keep core engaged throughout the movement. Use a spotter if lifting heavy.",
                equipmentRequired: ["Dumbbells", "Flat Bench"],
                musclesTargeted: ["Chest", "Shoulders", "Triceps"],
                difficultyLevel: "Intermediate"
            ),
            confidence: 92
        )
    )
}
