//
//  VideoPlayerView.swift
//  PTPerformance
//
//  Build 61: Video player for exercise technique guides (ACP-156)
//

import SwiftUI
import AVKit
import AVFoundation

/// Video player with playback controls for exercise technique videos
struct VideoPlayerView: View {
    let videoUrl: String

    @StateObject private var playerController = VideoPlayerController()
    @State private var showControls = true
    @State private var controlsTimer: Timer?

    var body: some View {
        ZStack {
            // Video player
            if let player = playerController.player {
                VideoPlayer(player: player)
                    .onTapGesture {
                        toggleControls()
                    }
                    .onDisappear {
                        playerController.pause()
                    }
            } else {
                // Loading state
                ZStack {
                    Color.black
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Text("Loading video...")
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                }
            }

            // Custom controls overlay
            if showControls {
                VStack {
                    Spacer()

                    // Control bar
                    VStack(spacing: 12) {
                        // Progress bar
                        VideoProgressBar(
                            currentTime: playerController.currentTime,
                            duration: playerController.duration
                        ) { newTime in
                            playerController.seek(to: newTime)
                        }

                        // Playback controls
                        HStack(spacing: 24) {
                            // Play/Pause button
                            Button {
                                playerController.togglePlayPause()
                                resetControlsTimer()
                            } label: {
                                Image(systemName: playerController.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                            }

                            // Time display
                            HStack(spacing: 4) {
                                Text(formatTime(playerController.currentTime))
                                Text("/")
                                Text(formatTime(playerController.duration))
                            }
                            .font(.caption)
                            .foregroundColor(.white)
                            .monospacedDigit()

                            Spacer()

                            // Playback speed toggle
                            Button {
                                playerController.toggleSpeed()
                                resetControlsTimer()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "gauge.with.dots.needle.50percent")
                                    Text(String(format: "%.1fx", playerController.playbackSpeed))
                                }
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                            }

                            // Loop toggle
                            Button {
                                playerController.toggleLoop()
                                resetControlsTimer()
                            } label: {
                                Image(systemName: playerController.isLooping ? "repeat.1" : "repeat")
                                    .font(.title3)
                                    .foregroundColor(playerController.isLooping ? .blue : .white)
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                    .padding(.top, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .transition(.opacity)
            }

            // Error state
            if let error = playerController.error {
                ZStack {
                    Color.black
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.yellow)

                        Text("Unable to load video")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text(error)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
            }
        }
        .onAppear {
            playerController.setupPlayer(with: videoUrl)
            startControlsTimer()
        }
        .onChange(of: showControls) { isShowing in
            if isShowing {
                startControlsTimer()
            }
        }
    }

    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showControls.toggle()
        }
        if showControls {
            startControlsTimer()
        }
    }

    private func startControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                if playerController.isPlaying {
                    showControls = false
                }
            }
        }
    }

    private func resetControlsTimer() {
        if showControls {
            startControlsTimer()
        }
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Video Progress Bar

struct VideoProgressBar: View {
    let currentTime: Double
    let duration: Double
    let onSeek: (Double) -> Void

    @State private var isDragging = false
    @State private var dragPosition: Double = 0

    var progress: Double {
        guard duration > 0 else { return 0 }
        return isDragging ? dragPosition : currentTime / duration
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)

                // Progress track
                Rectangle()
                    .fill(Color.white)
                    .frame(width: geometry.size.width * progress, height: 4)

                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .offset(x: geometry.size.width * progress - 6)
                    .opacity(isDragging ? 1 : 0)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let newPosition = max(0, min(1, value.location.x / geometry.size.width))
                        dragPosition = newPosition
                    }
                    .onEnded { value in
                        isDragging = false
                        let newPosition = max(0, min(1, value.location.x / geometry.size.width))
                        onSeek(newPosition * duration)
                    }
            )
        }
        .frame(height: 12)
        .padding(.horizontal, 16)
    }
}

// MARK: - Video Player Controller

class VideoPlayerController: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var isLooping = false
    @Published var playbackSpeed: Float = 1.0
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var error: String?

    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?

    deinit {
        cleanup()
    }

    func setupPlayer(with urlString: String) {
        cleanup()

        // Parse URL (handle YouTube, Vimeo, or direct URLs)
        guard let url = parseVideoUrl(urlString) else {
            error = "Invalid video URL"
            return
        }

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.rate = playbackSpeed

        // Observe player status
        statusObserver = playerItem.observe(\.status) { [weak self] item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    self?.error = nil
                    self?.duration = item.duration.seconds
                case .failed:
                    self?.error = "Failed to load video"
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }

        // Observe playback time
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }

        // Observe playback end
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            if self.isLooping {
                self.player?.seek(to: .zero)
                self.player?.play()
            } else {
                self.isPlaying = false
            }
        }
    }

    func togglePlayPause() {
        guard let player = player else { return }

        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func toggleLoop() {
        isLooping.toggle()
    }

    func toggleSpeed() {
        // Toggle between 1.0x and 0.5x
        playbackSpeed = playbackSpeed == 1.0 ? 0.5 : 1.0
        player?.rate = isPlaying ? playbackSpeed : 0
    }

    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }

    private func parseVideoUrl(_ urlString: String) -> URL? {
        // Handle direct URLs
        if let url = URL(string: urlString), urlString.hasPrefix("http") {
            // For YouTube/Vimeo, you'd need to extract the video ID and use their embed URL
            // For now, we'll support direct video URLs (mp4, m3u8, etc.)
            return url
        }
        return nil
    }

    private func cleanup() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        statusObserver?.invalidate()
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
        player?.pause()
        player = nil
    }
}

// MARK: - Preview

#Preview {
    VideoPlayerView(videoUrl: "https://example.com/video.mp4")
        .frame(height: 250)
        .cornerRadius(12)
}
