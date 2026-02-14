// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  VideoThumbnailView.swift
//  PTPerformance
//
//  ACP-813: HD Video Exercise Demos - Video thumbnail with play button
//  Displays video preview with duration, resolution, and cache status
//
//  BUILD 350: ACP-942 - Use CachedAsyncImage for 60fps scroll performance
//

import SwiftUI

/// Video thumbnail with play button overlay for exercise video previews
struct VideoThumbnailView: View {
    let video: ExerciseVideo
    var showDuration: Bool = true
    var showResolution: Bool = false
    var showCacheStatus: Bool = true
    var onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Thumbnail image
                thumbnailImage

                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .clear, .black.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Play button
                playButton

                // Info overlay
                infoOverlay
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    // MARK: - Thumbnail Image

    private var thumbnailImage: some View {
        Group {
            if let thumbnailUrl = video.thumbnail {
                // ACP-942: Use CachedAsyncImage for better scroll performance
                CachedAsyncImage(url: thumbnailUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    placeholderView
                }
            } else {
                placeholderView
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
    }

    private var placeholderView: some View {
        ZStack {
            Color.gray.opacity(0.2)

            VStack(spacing: 8) {
                Image(systemName: video.angle.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(.gray)

                Text(video.angle.displayName)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }

    // MARK: - Play Button

    private var playButton: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.6))
                .frame(width: 64, height: 64)

            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: 64, height: 64)

            Image(systemName: "play.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .offset(x: 2) // Visual centering for play icon
        }
    }

    // MARK: - Info Overlay

    private var infoOverlay: some View {
        VStack {
            // Top row - cache and resolution
            HStack {
                // Cache indicator
                if showCacheStatus && ExerciseVideoService.shared.isVideoCached(video) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.caption2)
                        Text("Offline")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxs)
                    .background(Color.green.opacity(0.8))
                    .cornerRadius(CornerRadius.xs)
                }

                Spacer()

                // Resolution badge
                if showResolution {
                    Text(video.resolution.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.modusCyan.opacity(0.8))
                        .cornerRadius(CornerRadius.xs)
                }
            }
            .padding(Spacing.xs)

            Spacer()

            // Bottom row - angle and duration
            HStack {
                // Angle indicator
                HStack(spacing: 4) {
                    Image(systemName: video.angle.iconName)
                        .font(.caption)
                    Text(video.angle.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)

                Spacer()

                // Duration
                if showDuration, let duration = video.durationDisplay {
                    Text(duration)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(CornerRadius.xs)
                }
            }
            .padding(Spacing.xs)
        }
    }
}

// MARK: - Compact Video Thumbnail

/// Compact thumbnail for list views
struct CompactVideoThumbnailView: View {
    let video: ExerciseVideo
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Thumbnail
                ZStack {
                    if let thumbnailUrl = video.thumbnail {
                        // ACP-942: Use CachedAsyncImage for better scroll performance
                        CachedAsyncImage(url: thumbnailUrl) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            thumbnailPlaceholder
                        }
                    } else {
                        thumbnailPlaceholder
                    }

                    // Play icon
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
                .frame(width: 80, height: 45)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.angle.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 8) {
                        if let duration = video.durationDisplay {
                            Label(duration, systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if ExerciseVideoService.shared.isVideoCached(video) {
                            Label("Offline", systemImage: "arrow.down.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Image(systemName: video.angle.iconName)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Video Thumbnail Grid

/// Grid of video thumbnails for multi-angle display
struct VideoThumbnailGridView: View {
    let videos: [ExerciseVideo]
    let onSelect: (ExerciseVideo) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(videos, id: \.id) { video in
                VideoThumbnailView(
                    video: video,
                    showResolution: false,
                    onTap: { onSelect(video) }
                )
            }
        }
    }
}

// MARK: - Primary Video Card

/// Large card for primary exercise video
struct PrimaryVideoCardView: View {
    let video: ExerciseVideo
    let exerciseName: String
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Large thumbnail
                ZStack {
                    // Thumbnail - ACP-942: Use CachedAsyncImage for better scroll performance
                    if let thumbnailUrl = video.thumbnail {
                        CachedAsyncImage(url: thumbnailUrl) { image in
                            image
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                        } placeholder: {
                            thumbnailPlaceholder
                        }
                    } else {
                        thumbnailPlaceholder
                    }

                    // Gradient
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.6)],
                        startPoint: .center,
                        endPoint: .bottom
                    )

                    // Play button
                    VStack {
                        Spacer()

                        HStack {
                            // Play button and title
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 48, height: 48)

                                    Image(systemName: "play.fill")
                                        .font(.title3)
                                        .foregroundColor(.black)
                                        .offset(x: 2)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Watch Demo")
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    if let duration = video.durationDisplay {
                                        Text(duration)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                            }

                            Spacer()

                            // HD badge
                            Text("HD")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, Spacing.xxs)
                                .background(Color.modusCyan)
                                .cornerRadius(CornerRadius.xs)
                        }
                        .padding()
                    }

                    // Cache indicator
                    if ExerciseVideoService.shared.isVideoCached(video) {
                        VStack {
                            HStack {
                                Spacer()
                                Label("Available Offline", systemImage: "checkmark.circle.fill")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, Spacing.xs)
                                    .padding(.vertical, Spacing.xxs)
                                    .background(Color.green.opacity(0.9))
                                    .cornerRadius(CornerRadius.xs)
                            }
                            Spacer()
                        }
                        .padding(Spacing.xs)
                    }
                }
                .aspectRatio(16/9, contentMode: .fit)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .adaptiveShadow(Shadow.medium)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            Color.gray.opacity(0.2)

            VStack(spacing: 12) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.gray)

                Text(exerciseName)
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Preview

#Preview("Thumbnail") {
    VideoThumbnailView(
        video: ExerciseVideo.sample,
        onTap: {}
    )
    .frame(width: 200)
    .padding()
}

#Preview("Compact") {
    CompactVideoThumbnailView(
        video: ExerciseVideo.sample,
        onTap: {}
    )
    .padding()
}

#Preview("Grid") {
    VideoThumbnailGridView(
        videos: ExerciseVideo.sampleVideos,
        onSelect: { _ in }
    )
    .padding()
}

#Preview("Primary Card") {
    PrimaryVideoCardView(
        video: ExerciseVideo.sample,
        exerciseName: "Back Squat",
        onTap: {}
    )
    .padding()
}
