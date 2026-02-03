//
//  ExerciseVideoView.swift
//  PTPerformance
//
//  Created by Build 46 Swarm Agent 4
//  Video player with form cues for exercise demonstrations
//

import SwiftUI
import AVKit

struct ExerciseVideoView: View {

    let exercise: Exercise.ExerciseTemplate
    @State private var player: AVPlayer?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingFormCues = true

    var body: some View {
        VStack(spacing: 0) {
            // Video player
            if let videoURL = exercise.videoUrl, let url = URL(string: videoURL) {
                videoPlayer(url: url)
            } else {
                noVideoView
            }

            // Form cues
            if showingFormCues, let cues = exercise.formCues, !cues.isEmpty {
                formCuesSection(cues)
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
    }

    // MARK: - Video Player

    private func videoPlayer(url: URL) -> some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView("Loading video...")
                    .frame(height: 300)
            } else if let error = errorMessage {
                errorView(error)
            } else if let player = player {
                VideoPlayer(player: player)
                    .frame(height: 300)
                    .overlay(alignment: .topTrailing) {
                        Button(action: { showingFormCues.toggle() }) {
                            Image(systemName: showingFormCues ? "info.circle.fill" : "info.circle")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(8)
                    }
            }
        }
    }

    // MARK: - No Video View

    private var noVideoView: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.slash")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Video Available")
                .font(.headline)

            Text("Video demonstration coming soon")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Form Cues Section

    private func formCuesSection(_ cues: [Exercise.ExerciseTemplate.FormCue]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Form Cues", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.blue)

                Spacer()

                Button(action: { showingFormCues = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            ForEach(cues.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 12) {
                    // Timestamp or number
                    if let displayTime = cues[index].displayTime {
                        Text(displayTime)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .frame(width: 50, alignment: .leading)
                    } else {
                        Text("\(index + 1).")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .frame(width: 50, alignment: .leading)
                    }

                    // Cue text
                    Text(cues[index].cue)
                        .font(.subheadline)

                    Spacer()
                }
                .padding(.vertical, 4)

                if index < cues.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Unable to Load Video")
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Try Again") {
                setupPlayer()
            }
            .buttonStyle(.bordered)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Player Setup

    private func setupPlayer() {
        guard let videoURL = exercise.videoUrl, let url = URL(string: videoURL) else {
            return
        }

        isLoading = true
        errorMessage = nil

        // Use VideoService for caching
        Task {
            do {
                let cachedURL = try await VideoService.shared.loadVideo(from: url)
                await MainActor.run {
                    player = AVPlayer(url: cachedURL)
                    player?.automaticallyWaitsToMinimizeStalling = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Rounded Corner Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

struct ExerciseVideoView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseVideoView(
            exercise: Exercise.ExerciseTemplate(
                id: UUID(),
                name: "Squat",
                category: "squat",
                body_region: "lower",
                videoUrl: "https://example.com/squat.mp4",
                videoThumbnailUrl: nil,
                videoDuration: 45,
                formCues: [
                    .init(cue: "Keep chest up", timestamp: 5),
                    .init(cue: "Drive through heels", timestamp: 15),
                    .init(cue: "Control the descent", timestamp: 25)
                ],
                techniqueCues: nil,
                commonMistakes: nil,
                safetyNotes: nil
            )
        )
    }
}
