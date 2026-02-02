//
//  VideoAngleSelectorView.swift
//  PTPerformance
//
//  ACP-813: HD Video Exercise Demos - Angle selector component
//  Allows switching between front, side, back, and detail camera angles
//

import SwiftUI

/// View for selecting between different camera angles for exercise videos
struct VideoAngleSelectorView: View {
    let videos: [ExerciseVideo]
    let selectedAngle: ExerciseVideo.VideoAngle
    let onSelect: (ExerciseVideo.VideoAngle) -> Void

    @Namespace private var animation

    private var availableAngles: [ExerciseVideo.VideoAngle] {
        videos.map(\.angle).sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Horizontal angle selector
            HStack(spacing: 12) {
                ForEach(availableAngles, id: \.self) { angle in
                    angleButton(for: angle)
                }
            }

            // Thumbnail preview (if showing detail)
            if videos.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(videos, id: \.id) { video in
                            angleThumbnail(video: video)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }

    // MARK: - Angle Button

    private func angleButton(for angle: ExerciseVideo.VideoAngle) -> some View {
        let isSelected = angle == selectedAngle
        let video = videos.first { $0.angle == angle }

        return Button {
            onSelect(angle)
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.blue : Color.white.opacity(0.1))
                        .frame(width: 64, height: 64)

                    // Icon
                    Image(systemName: angle.iconName)
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.7))

                    // Cached indicator
                    if let video = video, ExerciseVideoService.shared.isVideoCached(video) {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                            Spacer()
                        }
                        .padding(4)
                    }
                }

                // Label
                Text(angle.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Angle Thumbnail

    private func angleThumbnail(video: ExerciseVideo) -> some View {
        let isSelected = video.angle == selectedAngle

        return Button {
            onSelect(video.angle)
        } label: {
            ZStack {
                // Thumbnail image
                if let thumbnailUrl = video.thumbnail {
                    AsyncImage(url: thumbnailUrl) { phase in
                        switch phase {
                        case .empty:
                            thumbnailPlaceholder(video: video)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                        case .failure:
                            thumbnailPlaceholder(video: video)
                        @unknown default:
                            thumbnailPlaceholder(video: video)
                        }
                    }
                } else {
                    thumbnailPlaceholder(video: video)
                }

                // Overlay with angle name
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: video.angle.iconName)
                            .font(.caption)
                        Text(video.angle.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()

                        // Duration
                        if let duration = video.durationDisplay {
                            Text(duration)
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(8)
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .frame(width: 140, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func thumbnailPlaceholder(video: ExerciseVideo) -> some View {
        ZStack {
            Color.gray.opacity(0.3)

            VStack(spacing: 4) {
                Image(systemName: video.angle.iconName)
                    .font(.title2)
                Text(video.angle.displayName)
                    .font(.caption2)
            }
            .foregroundColor(.white.opacity(0.5))
        }
    }
}

// MARK: - Compact Angle Selector

/// Compact horizontal angle selector for inline use
struct CompactAngleSelectorView: View {
    let videos: [ExerciseVideo]
    @Binding var selectedAngle: ExerciseVideo.VideoAngle

    private var availableAngles: [ExerciseVideo.VideoAngle] {
        videos.map(\.angle).sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(availableAngles, id: \.self) { angle in
                compactAngleButton(for: angle)
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }

    private func compactAngleButton(for angle: ExerciseVideo.VideoAngle) -> some View {
        let isSelected = angle == selectedAngle

        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedAngle = angle
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: angle.iconName)
                    .font(.caption)
                if isSelected {
                    Text(angle.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, isSelected ? 12 : 8)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Angle Indicator Dots

/// Dots indicating available angles with current selection
struct AngleIndicatorDots: View {
    let availableAngles: [ExerciseVideo.VideoAngle]
    let selectedAngle: ExerciseVideo.VideoAngle

    var body: some View {
        HStack(spacing: 6) {
            ForEach(availableAngles, id: \.self) { angle in
                Circle()
                    .fill(angle == selectedAngle ? Color.white : Color.white.opacity(0.4))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

// MARK: - Preview

#Preview("Full Selector") {
    ZStack {
        Color.black
        VideoAngleSelectorView(
            videos: ExerciseVideo.sampleVideos,
            selectedAngle: .front,
            onSelect: { _ in }
        )
        .padding()
    }
}

#Preview("Compact Selector") {
    ZStack {
        Color.black
        CompactAngleSelectorView(
            videos: ExerciseVideo.sampleVideos,
            selectedAngle: .constant(.front)
        )
        .padding()
    }
}
