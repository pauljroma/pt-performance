//
//  ExerciseVideoDemoView.swift
//  PTPerformance
//
//  ACP-813: HD Video Exercise Demos - Exercise demo view with multi-angle videos
//  Integrates video player with exercise technique information
//

import SwiftUI

/// Main view for exercise video demonstrations with multi-angle support
struct ExerciseVideoDemoView: View {
    let exercise: Exercise
    var patientId: UUID? = nil

    @StateObject private var viewModel = ExerciseVideoDemoViewModel()
    @State private var showFullScreenPlayer = false
    @State private var selectedVideo: ExerciseVideo?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerSection

                    // Video section
                    if viewModel.isLoading {
                        loadingSection
                    } else if viewModel.videos.isEmpty {
                        noVideoSection
                    } else {
                        videoSection
                    }

                    // Technique cues (if available)
                    if let techniqueCues = exercise.exercise_templates?.techniqueCues {
                        techniqueSection(techniqueCues)
                    }

                    // Prescription info
                    prescriptionSection

                    // Cache management
                    if !viewModel.videos.isEmpty {
                        cacheSection
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .task {
                await viewModel.loadVideos(for: exercise)
            }
            .fullScreenCover(isPresented: $showFullScreenPlayer) {
                if !viewModel.videos.isEmpty {
                    ExerciseVideoPlayerView(
                        videos: viewModel.videos,
                        exerciseName: exercise.exercise_name ?? "Exercise",
                        patientId: patientId,
                        onDismiss: {
                            showFullScreenPlayer = false
                        }
                    )
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
                if viewModel.canRetry {
                    Button("Retry") {
                        Task {
                            await viewModel.loadVideos(for: exercise)
                        }
                    }
                }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.exercise_name ?? "Exercise")
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
                        Text("-")
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
    }

    // MARK: - Loading Section

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading videos...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - No Video Section

    private var noVideoSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Video Available")
                .font(.headline)

            Text("Video demonstration coming soon for this exercise")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Video Section

    private var videoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Primary video card
            if let primaryVideo = viewModel.primaryVideo {
                PrimaryVideoCardView(
                    video: primaryVideo,
                    exerciseName: exercise.exercise_name ?? "Exercise"
                ) {
                    showFullScreenPlayer = true
                }
                .padding(.horizontal)
            }

            // Multiple angles available
            if viewModel.videos.count > 1 {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Available Angles")
                            .font(.headline)

                        Spacer()

                        Text("\(viewModel.videos.count) angles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Angle thumbnails
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.videos, id: \.id) { video in
                                VideoThumbnailView(
                                    video: video,
                                    showResolution: true
                                ) {
                                    selectedVideo = video
                                    showFullScreenPlayer = true
                                }
                                .frame(width: 180)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }

    // MARK: - Technique Section

    private func techniqueSection(_ cues: Exercise.TechniqueCues) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Technique Guide")
                .font(.headline)
                .padding(.horizontal)

            ExerciseCuesCard(techniqueCues: cues)
                .padding(.horizontal)
        }
    }

    // MARK: - Prescription Section

    private var prescriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Prescription")
                .font(.headline)
                .padding(.horizontal)

            GroupBox {
                VStack(spacing: 12) {
                    HStack {
                        Label("Sets", systemImage: "number.square.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(exercise.prescribed_sets)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Divider()

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
                        Divider()
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
                        Divider()
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
            .padding(.horizontal)
        }
    }

    // MARK: - Cache Section

    private var cacheSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Offline Access")
                .font(.headline)
                .padding(.horizontal)

            GroupBox {
                VStack(spacing: 16) {
                    // Cache status
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Downloaded Videos")
                                .font(.subheadline)

                            Text("\(viewModel.cachedVideoCount) of \(viewModel.videos.count) angles")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if viewModel.cachedVideoCount == viewModel.videos.count {
                            Label("Ready", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }

                    // Download all button
                    if viewModel.cachedVideoCount < viewModel.videos.count {
                        Button {
                            Task {
                                await viewModel.downloadAllVideos()
                            }
                        } label: {
                            HStack {
                                if viewModel.isDownloading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                }
                                Text(viewModel.isDownloading ? "Downloading..." : "Download All for Offline")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.isDownloading)
                    }

                    // Storage info
                    if viewModel.totalFileSize > 0 {
                        HStack {
                            Image(systemName: "externaldrive.fill")
                                .foregroundColor(.secondary)
                            Text("Total size: \(viewModel.totalFileSizeDisplay)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - View Model

@MainActor
class ExerciseVideoDemoViewModel: ObservableObject {
    @Published var videos: [ExerciseVideo] = []
    @Published var isLoading = false
    @Published var isDownloading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var canRetry = false

    private let videoService = ExerciseVideoService.shared

    var primaryVideo: ExerciseVideo? {
        videos.first { $0.isPrimary } ?? videos.first
    }

    var cachedVideoCount: Int {
        videos.filter { videoService.isVideoCached($0) }.count
    }

    var totalFileSize: Int64 {
        videos.compactMap(\.fileSizeBytes).reduce(0, +)
    }

    var totalFileSizeDisplay: String {
        let megabytes = Double(totalFileSize) / 1_000_000
        if megabytes >= 1000 {
            return String(format: "%.1f GB", megabytes / 1000)
        } else {
            return String(format: "%.0f MB", megabytes)
        }
    }

    func loadVideos(for exercise: Exercise) async {
        guard let templateId = exercise.exercise_templates?.id else {
            // Try using exercise_template_id directly
            await loadVideos(exerciseId: exercise.exercise_template_id)
            return
        }
        await loadVideos(exerciseId: templateId)
    }

    private func loadVideos(exerciseId: UUID) async {
        isLoading = true
        errorMessage = nil
        showError = false

        do {
            videos = try await videoService.fetchVideos(exerciseId: exerciseId)
        } catch {
            errorMessage = error.localizedDescription
            canRetry = true
            showError = true
        }

        isLoading = false
    }

    func downloadAllVideos() async {
        isDownloading = true

        for video in videos where !videoService.isVideoCached(video) {
            do {
                try await videoService.cacheVideo(video)
            } catch {
                // Continue with other videos even if one fails
                DebugLogger.shared.log(
                    "Failed to cache video \(video.id): \(error.localizedDescription)",
                    level: .warning
                )
            }
        }

        isDownloading = false
        // Trigger UI update
        objectWillChange.send()
    }
}

// MARK: - Preview

#Preview {
    ExerciseVideoDemoView(
        exercise: Exercise(
            id: UUID(),
            session_id: UUID(),
            exercise_template_id: UUID(),
            sequence: 1,
            prescribed_sets: 3,
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
                videoUrl: nil,
                videoThumbnailUrl: nil,
                videoDuration: nil,
                formCues: nil,
                techniqueCues: Exercise.TechniqueCues(
                    setup: ["Feet shoulder-width apart", "Bar on upper traps"],
                    execution: ["Push knees out", "Hips back and down"],
                    breathing: ["Breathe in at top", "Hold during descent"]
                ),
                commonMistakes: nil,
                safetyNotes: nil
            )
        )
    )
}
