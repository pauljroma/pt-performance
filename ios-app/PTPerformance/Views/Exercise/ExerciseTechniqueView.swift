// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  ExerciseTechniqueView.swift
//  PTPerformance
//
//  Build 61: Exercise technique guides with video support (ACP-156)
//

import SwiftUI

/// Full-screen technique guide for exercises with video support
struct ExerciseTechniqueView: View {
    let exercise: Exercise

    @Environment(\.dismiss) private var dismiss
    @State private var showVideo = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with exercise name
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.exercise_name ?? "Exercise Technique")
                            .font(.title)
                            .fontWeight(.bold)

                        if let category = exercise.exercise_templates?.category {
                            HStack(spacing: 8) {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .foregroundColor(.blue)
                                Text(category.capitalized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                if let bodyRegion = exercise.exercise_templates?.body_region {
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Text(bodyRegion.capitalized)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Video player section (if video exists)
                    if let videoUrl = exercise.exercise_templates?.videoUrl, !videoUrl.isEmpty {
                        VideoPlayerView(videoUrl: videoUrl)
                            .frame(height: 250)
                            .cornerRadius(CornerRadius.md)
                            .padding(.horizontal)
                    } else {
                        // Fallback placeholder if no video
                        VideoPlaceholderView(exerciseName: exercise.exercise_name ?? "Exercise")
                            .frame(height: 250)
                            .cornerRadius(CornerRadius.md)
                            .padding(.horizontal)
                    }

                    // Technique cues section
                    if let techniqueCues = exercise.exercise_templates?.techniqueCues {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Technique Cues")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal)

                            ExerciseCuesCard(techniqueCues: techniqueCues)
                                .padding(.horizontal)
                        }
                    }

                    // Common mistakes section
                    if let commonMistakes = exercise.exercise_templates?.commonMistakes, !commonMistakes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Common Mistakes")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal)

                            CommonMistakesCard(mistakes: commonMistakes)
                                .padding(.horizontal)
                        }
                    }

                    // Safety notes section
                    if let safetyNotes = exercise.exercise_templates?.safetyNotes, !safetyNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Safety Notes")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal)

                            SafetyNotesCard(notes: safetyNotes)
                                .padding(.horizontal)
                        }
                    }

                    // Additional info section
                    PrescriptionInfoCard(exercise: exercise)
                        .padding(.horizontal)

                    Spacer(minLength: 24)
                }
                .padding(.bottom, 24)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Video Placeholder View

/// Placeholder view when no video is available
struct VideoPlaceholderView: View {
    let exerciseName: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))

            VStack(spacing: 16) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)

                Text("No video available")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("Video coming soon for \(exerciseName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - Common Mistakes Card

struct CommonMistakesCard: View {
    let mistakes: String

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Watch Out For:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Text(mistakes)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .groupBoxStyle(TechniqueGroupBoxStyle(accentColor: .orange))
    }
}

// MARK: - Safety Notes Card

struct SafetyNotesCard: View {
    let notes: String

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.red)
                    Text("Important Safety Information")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Text(notes)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .groupBoxStyle(TechniqueGroupBoxStyle(accentColor: .red))
    }
}

// MARK: - Prescription Info Card

struct PrescriptionInfoCard: View {
    let exercise: Exercise

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Prescription")
                    .font(.headline)
                    .fontWeight(.semibold)

                VStack(spacing: 8) {
                    HStack {
                        Label("Sets", systemImage: "number.square.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(exercise.sets)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    HStack {
                        Label("Reps", systemImage: "repeat")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(exercise.repsDisplay)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    if let load = exercise.prescribed_load, let unit = exercise.load_unit {
                        HStack {
                            Label("Load", systemImage: "scalemass.fill")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(load)) \(unit)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }

                    if let rest = exercise.rest_period_seconds {
                        HStack {
                            Label("Rest", systemImage: "timer")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(rest)s")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .groupBoxStyle(TechniqueGroupBoxStyle(accentColor: .blue))
    }
}

// MARK: - Custom GroupBox Style

struct TechniqueGroupBoxStyle: GroupBoxStyle {
    let accentColor: Color

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            configuration.content
                .padding(16)
        }
        .background(accentColor.opacity(0.05))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    ExerciseTechniqueView(
        exercise: Exercise(
            id: UUID(),
            session_id: UUID(),
            exercise_template_id: UUID(),
            sequence: 1,
            target_sets: 3,
            target_reps: 10,
            prescribed_sets: nil,
            prescribed_reps: "8-10",
            prescribed_load: 185,
            load_unit: "lbs",
            rest_period_seconds: 120,
            notes: nil,
            exercise_templates: Exercise.ExerciseTemplate(
                id: UUID(),
                name: "Back Squat",
                category: "squat",
                body_region: "lower",
                videoUrl: "https://www.youtube.com/watch?v=example",
                videoThumbnailUrl: nil,
                videoDuration: 90,
                formCues: nil,
                techniqueCues: Exercise.TechniqueCues(
                    setup: ["Feet shoulder-width apart", "Bar on upper traps", "Core braced"],
                    execution: ["Push knees out", "Hips back and down", "Drive through heels"],
                    breathing: ["Breathe in at top", "Hold breath during descent", "Exhale on drive up"]
                ),
                commonMistakes: "Knees caving in, excessive forward lean, not reaching proper depth",
                safetyNotes: "Keep spine neutral throughout movement. Stop if you feel pain in knees or lower back."
            )
        )
    )
}
