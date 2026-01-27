import SwiftUI

// MARK: - BUILD 296: Exercise Info Sheet (ACP-587)

/// Generic exercise info modal — shows video, technique cues, safety notes
/// Unlike ExerciseDetailSheet (substitution-only), this works from any exercise context
struct ExerciseTemplateInfoSheet: View {
    let exerciseName: String
    let exerciseTemplateId: String?

    @StateObject private var viewModel = ExerciseInfoViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading exercise info...")
                } else if let template = viewModel.template {
                    exerciseContent(template)
                } else if viewModel.errorMessage != nil {
                    noDataView
                } else {
                    noDataView
                }
            }
            .navigationTitle(exerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            if let id = exerciseTemplateId {
                await viewModel.fetchTemplate(id: id)
            }
        }
    }

    // MARK: - Main Content

    private func exerciseContent(_ template: ExerciseTemplateDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Video section
                videoSection(template)

                // Category/body region badges
                if template.category != nil || template.bodyRegion != nil {
                    badgesSection(template)
                }

                // Technique cues
                if let cues = template.techniqueCues {
                    techniqueCuesSection(cues)
                }

                // Safety notes
                if let safetyNotes = template.safetyNotes, !safetyNotes.isEmpty {
                    safetySection(safetyNotes)
                }

                // Common mistakes
                if let mistakes = template.commonMistakes, !mistakes.isEmpty {
                    commonMistakesSection(mistakes)
                }

                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    // MARK: - Video Section

    @ViewBuilder
    private func videoSection(_ template: ExerciseTemplateDetail) -> some View {
        if let videoUrl = template.videoUrl {
            VideoPlayerView(videoUrl: videoUrl)
                .frame(height: 250)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)

                VStack(spacing: 12) {
                    Image(systemName: "video.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))

                    Text("Video Coming Soon")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
    }

    // MARK: - Badges

    private func badgesSection(_ template: ExerciseTemplateDetail) -> some View {
        HStack(spacing: 8) {
            if let category = template.category {
                Text(category)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }

            if let bodyRegion = template.bodyRegion {
                Text(bodyRegion)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - Technique Cues

    private func techniqueCuesSection(_ cues: TechniqueCues) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How to Perform")
                .font(.headline)

            if !cues.setup.isEmpty {
                cueGroup(title: "Setup", icon: "figure.stand", cues: cues.setup, color: .blue)
            }

            if !cues.execution.isEmpty {
                cueGroup(title: "Execution", icon: "figure.strengthtraining.traditional", cues: cues.execution, color: .purple)
            }

            if !cues.breathing.isEmpty {
                cueGroup(title: "Breathing", icon: "lungs.fill", cues: cues.breathing, color: .teal)
            }
        }
        .padding(16)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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

    // MARK: - Safety Notes

    private func safetySection(_ notes: String) -> some View {
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
        .padding(16)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Common Mistakes

    private func commonMistakesSection(_ mistakes: String) -> some View {
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
        .padding(16)
        .background(Color.red.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - No Data View

    private var noDataView: some View {
        VStack(spacing: 16) {
            Image(systemName: "info.circle")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("Exercise information not available")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
