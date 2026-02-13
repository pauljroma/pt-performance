import SwiftUI

// MARK: - BUILD 296: Exercise Info Sheet (ACP-587)
// MARK: - ACP-813: Updated with HD Video Exercise Demos support

/// Generic exercise info modal — shows video, technique cues, safety notes
/// Unlike ExerciseDetailSheet (substitution-only), this works from any exercise context
/// ACP-813: Now supports multi-angle HD video demos with offline caching
struct ExerciseTemplateInfoSheet: View {
    let exerciseName: String
    let exerciseTemplateId: String?
    var patientId: UUID? = nil

    @StateObject private var viewModel = ExerciseInfoViewModel()
    @State private var hdVideos: [ExerciseVideo] = []
    @State private var isLoadingVideos = false
    @State private var showFullScreenPlayer = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
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
            // BUILD 354: Support lookup by ID or by name
            if let id = exerciseTemplateId, !id.isEmpty {
                await viewModel.fetchTemplate(id: id)
                // ACP-813: Load HD videos
                await loadHDVideos(exerciseId: id)
            } else if !exerciseName.isEmpty {
                // Fallback: lookup by name when ID not available (e.g., from workout templates)
                await viewModel.fetchTemplateByName(exerciseName)
                // Load HD videos by template ID if found
                if let templateId = viewModel.template?.id {
                    await loadHDVideos(exerciseId: templateId.uuidString)
                }
            }
        }
        .fullScreenCover(isPresented: $showFullScreenPlayer) {
            if !hdVideos.isEmpty {
                ExerciseVideoPlayerView(
                    videos: hdVideos,
                    exerciseName: exerciseName,
                    patientId: patientId,
                    onDismiss: {
                        showFullScreenPlayer = false
                    }
                )
            }
        }
    }

    // ACP-813: Load HD videos for this exercise
    private func loadHDVideos(exerciseId: String) async {
        guard let uuid = UUID(uuidString: exerciseId) else { return }
        isLoadingVideos = true
        do {
            hdVideos = try await ExerciseVideoService.shared.fetchVideos(exerciseId: uuid)
        } catch {
            // Non-fatal - fall back to legacy video
            DebugLogger.shared.log(
                "Failed to load HD videos: \(error.localizedDescription)",
                level: .warning
            )
        }
        isLoadingVideos = false
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
    // ACP-813: Updated to support HD multi-angle videos

    @ViewBuilder
    private func videoSection(_ template: ExerciseTemplateDetail) -> some View {
        // ACP-813: Prefer HD videos if available
        if !hdVideos.isEmpty {
            hdVideoSection
        } else if isLoadingVideos {
            // Loading HD videos
            VStack(spacing: 16) {
                ProgressView()
                Text("Loading HD videos...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        } else if let videoUrl = template.videoUrl {
            // Legacy single video fallback
            VideoPlayerView(videoUrl: videoUrl)
                .frame(height: 250)
                .cornerRadius(CornerRadius.md)
                .adaptiveShadow(Shadow.medium)
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

    // ACP-813: HD Video Section with multi-angle support
    @ViewBuilder
    private var hdVideoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Primary video card
            if let primaryVideo = hdVideos.first(where: { $0.isPrimary }) ?? hdVideos.first {
                PrimaryVideoCardView(
                    video: primaryVideo,
                    exerciseName: exerciseName
                ) {
                    showFullScreenPlayer = true
                }
            }

            // Show available angles if multiple
            if hdVideos.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "camera.viewfinder")
                            .foregroundColor(.blue)
                        Text("\(hdVideos.count) angles available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(hdVideos, id: \.id) { video in
                                Button {
                                    showFullScreenPlayer = true
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: video.angle.iconName)
                                            .font(.title3)
                                        Text(video.angle.displayName)
                                            .font(.caption2)
                                    }
                                    .foregroundColor(.primary)
                                    .frame(width: 70, height: 50)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(CornerRadius.sm)
                                    .overlay(
                                        Group {
                                            if ExerciseVideoService.shared.isVideoCached(video) {
                                                VStack {
                                                    HStack {
                                                        Spacer()
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .font(.caption2)
                                                            .foregroundColor(.green)
                                                    }
                                                    Spacer()
                                                }
                                                .padding(4)
                                            }
                                        }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
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
                    .cornerRadius(CornerRadius.sm)
            }

            if let bodyRegion = template.bodyRegion {
                Text(bodyRegion)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(CornerRadius.sm)
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
        .cornerRadius(CornerRadius.md)
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
        .cornerRadius(CornerRadius.md)
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
