//
//  ExerciseVideoPlayerView.swift
//  PTPerformance
//
//  ACP-813: HD Video Exercise Demos - Full-featured video player
//  Features: Multi-angle, slow-motion, loop mode, PiP, AirPlay
//

import SwiftUI
import AVKit
import AVFoundation

/// Full-featured HD video player for exercise demonstrations
struct ExerciseVideoPlayerView: View {
    let videos: [ExerciseVideo]
    let exerciseName: String
    var patientId: UUID? = nil
    var onDismiss: (() -> Void)? = nil

    @StateObject private var controller = ExerciseVideoPlayerController()
    @State private var selectedVideo: ExerciseVideo?
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    @State private var showAngleSelector = false
    @State private var showSpeedSelector = false
    @State private var isFullScreen = false

    @Environment(\.dismiss) private var dismiss

    // Available angles from videos
    private var availableAngles: [ExerciseVideo.VideoAngle] {
        videos.map(\.angle).sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()

                // Video player
                if let player = controller.player {
                    VideoPlayer(player: player)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showControls.toggle()
                            }
                            if showControls {
                                startControlsTimer()
                            }
                        }
                } else if controller.isLoading {
                    loadingView
                } else if let error = controller.error {
                    errorView(error)
                }

                // Controls overlay
                if showControls {
                    controlsOverlay(geometry: geometry)
                        .transition(.opacity)
                }

                // Angle selector sheet
                if showAngleSelector {
                    angleSelector
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Speed selector sheet
                if showSpeedSelector {
                    speedSelector
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            setupInitialVideo()
            startControlsTimer()
        }
        .onDisappear {
            logVideoView()
            controller.pause()
        }
        .onChange(of: selectedVideo) { _, newVideo in
            if let video = newVideo {
                switchToVideo(video)
            }
        }
        .statusBarHidden(isFullScreen)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            Text("Loading video...")
                .foregroundColor(.white)
                .font(.subheadline)
        }
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.yellow)

            Text("Unable to Load Video")
                .font(.headline)
                .foregroundColor(.white)

            Text(message)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Try Again") {
                if let video = selectedVideo {
                    switchToVideo(video)
                }
            }
            .buttonStyle(.bordered)
            .tint(.white)
        }
    }

    // MARK: - Controls Overlay

    private func controlsOverlay(geometry: GeometryProxy) -> some View {
        VStack {
            // Top bar
            topControlBar

            Spacer()

            // Bottom controls
            bottomControlBar(geometry: geometry)
        }
        .background(
            LinearGradient(
                colors: [.black.opacity(0.6), .clear, .clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    // MARK: - Top Control Bar

    private var topControlBar: some View {
        HStack {
            // Close button
            Button {
                onDismiss?() ?? dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }

            Spacer()

            // Exercise name
            VStack(alignment: .center, spacing: 2) {
                Text(exerciseName)
                    .font(.headline)
                    .foregroundColor(.white)

                if let video = selectedVideo {
                    Text(video.angle.displayName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            Spacer()

            // AirPlay button
            AirPlayButton()
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Bottom Control Bar

    private func bottomControlBar(geometry: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            // Progress bar
            VideoProgressBar(
                currentTime: controller.currentTime,
                duration: controller.duration
            ) { newTime in
                controller.seek(to: newTime)
                resetControlsTimer()
            }

            // Main controls row
            HStack(spacing: 20) {
                // Play/Pause
                Button {
                    controller.togglePlayPause()
                    resetControlsTimer()
                } label: {
                    Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }

                // Time display
                HStack(spacing: 4) {
                    Text(formatTime(controller.currentTime))
                    Text("/")
                    Text(formatTime(controller.duration))
                }
                .font(.caption)
                .foregroundColor(.white)
                .monospacedDigit()

                Spacer()

                // Angle selector (if multiple angles)
                if availableAngles.count > 1 {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showAngleSelector.toggle()
                            showSpeedSelector = false
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: selectedVideo?.angle.iconName ?? "person.fill")
                            Text(selectedVideo?.angle.displayName ?? "Angle")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(showAngleSelector ? Color.blue : Color.white.opacity(0.2))
                        .cornerRadius(8)
                    }
                }

                // Speed selector
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showSpeedSelector.toggle()
                        showAngleSelector = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "gauge.with.dots.needle.50percent")
                        Text(controller.playbackSpeed.displayName)
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(controller.playbackSpeed.isSlowMotion ? .blue : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(showSpeedSelector ? Color.blue : Color.white.opacity(0.2))
                    .cornerRadius(8)
                }

                // Loop toggle
                Button {
                    controller.toggleLoop()
                    resetControlsTimer()
                } label: {
                    Image(systemName: controller.isLooping ? "repeat.1" : "repeat")
                        .font(.title3)
                        .foregroundColor(controller.isLooping ? .blue : .white)
                        .frame(width: 44, height: 44)
                }

                // PiP button
                if controller.supportsPictureInPicture {
                    Button {
                        controller.togglePictureInPicture()
                    } label: {
                        Image(systemName: "pip.enter")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .padding(.top, 12)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Angle Selector

    private var angleSelector: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Select Angle")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showAngleSelector = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                // Angle options
                VideoAngleSelectorView(
                    videos: videos,
                    selectedAngle: selectedVideo?.angle ?? .front,
                    onSelect: { angle in
                        if let video = videos.first(where: { $0.angle == angle }) {
                            selectedVideo = video
                        }
                        withAnimation(.spring(response: 0.3)) {
                            showAngleSelector = false
                        }
                    }
                )
            }
            .padding()
            .background(Color.black.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .ignoresSafeArea()
    }

    // MARK: - Speed Selector

    private var speedSelector: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Playback Speed")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showSpeedSelector = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                // Speed options
                SlowMotionControlView(
                    currentSpeed: controller.playbackSpeed,
                    supportsSlowMotion: selectedVideo?.supportsSlowMotion ?? true,
                    onSelect: { speed in
                        controller.setPlaybackSpeed(speed)
                        withAnimation(.spring(response: 0.3)) {
                            showSpeedSelector = false
                        }
                    }
                )
            }
            .padding()
            .background(Color.black.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .ignoresSafeArea()
    }

    // MARK: - Helper Methods

    private func setupInitialVideo() {
        // Use primary video or first video
        let initialVideo = videos.first { $0.isPrimary } ?? videos.first
        selectedVideo = initialVideo

        if let video = initialVideo {
            controller.setupPlayer(with: video)
        }
    }

    private func switchToVideo(_ video: ExerciseVideo) {
        // Remember current position and state
        let currentPosition = controller.currentTime / max(controller.duration, 1)
        let wasPlaying = controller.isPlaying

        // Switch video
        controller.setupPlayer(with: video)

        // Restore position approximately
        if controller.duration > 0 {
            let newTime = currentPosition * controller.duration
            controller.seek(to: newTime)
        }

        // Restore playback state
        if wasPlaying {
            controller.play()
        }
    }

    private func startControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak controller] _ in
            Task { @MainActor in
                if controller?.isPlaying == true && !showAngleSelector && !showSpeedSelector {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showControls = false
                    }
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

    private func logVideoView() {
        guard let video = selectedVideo,
              let patientId = patientId else { return }

        let watchDuration = Int(controller.currentTime)
        let completed = controller.currentTime >= controller.duration * 0.9

        Task {
            try? await ExerciseVideoService.shared.logVideoView(
                video: video,
                patientId: patientId,
                watchDuration: watchDuration,
                completed: completed,
                playbackSpeed: controller.playbackSpeed
            )
        }
    }
}

// MARK: - Video Player Controller

@MainActor
class ExerciseVideoPlayerController: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var isLooping = false
    @Published var playbackSpeed: PlaybackSpeed = .normal
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isLoading = false
    @Published var error: String?
    @Published var supportsPictureInPicture = false

    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?
    private var pipController: AVPictureInPictureController?

    nonisolated deinit {
        // Note: cleanup is handled by ARC for most resources
        // The time observer, status observer, and end observer will be
        // cleaned up when the object is deallocated
    }

    func setupPlayer(with video: ExerciseVideo) {
        cleanup()
        isLoading = true
        error = nil

        // Get URL (cached or remote)
        guard let url = ExerciseVideoService.shared.getVideoUrl(video) else {
            error = "Invalid video URL"
            isLoading = false
            return
        }

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.rate = playbackSpeed.rawValue

        // Configure for AirPlay
        player?.allowsExternalPlayback = true
        player?.usesExternalPlaybackWhileExternalScreenIsActive = true

        // Setup PiP if available
        setupPictureInPicture()

        // Observe player status
        statusObserver = playerItem.observe(\.status) { [weak self] item, _ in
            Task { @MainActor in
                switch item.status {
                case .readyToPlay:
                    self?.error = nil
                    self?.duration = item.duration.seconds.isFinite ? item.duration.seconds : 0
                    self?.isLoading = false
                case .failed:
                    self?.error = "Failed to load video"
                    self?.isLoading = false
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
            Task { @MainActor in
                self?.currentTime = time.seconds.isFinite ? time.seconds : 0
            }
        }

        // Observe playback end
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.isLooping {
                    self.player?.seek(to: .zero)
                    self.player?.play()
                } else {
                    self.isPlaying = false
                }
            }
        }
    }

    func play() {
        player?.rate = playbackSpeed.rawValue
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func toggleLoop() {
        isLooping.toggle()
    }

    func setPlaybackSpeed(_ speed: PlaybackSpeed) {
        playbackSpeed = speed
        if isPlaying {
            player?.rate = speed.rawValue
        }
    }

    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }

    func togglePictureInPicture() {
        guard let pipController = pipController else { return }

        if pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
        } else {
            pipController.startPictureInPicture()
        }
    }

    private func setupPictureInPicture() {
        guard AVPictureInPictureController.isPictureInPictureSupported(),
              let player = player else {
            supportsPictureInPicture = false
            return
        }

        let playerLayer = AVPlayerLayer(player: player)
        if AVPictureInPictureController.isPictureInPictureSupported() {
            pipController = AVPictureInPictureController(playerLayer: playerLayer)
            supportsPictureInPicture = pipController != nil
        }
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
        pipController = nil
    }
}

// MARK: - AirPlay Button

struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.tintColor = .white
        routePickerView.activeTintColor = .systemBlue
        routePickerView.prioritizesVideoDevices = true
        return routePickerView
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

// MARK: - Preview

#Preview {
    ExerciseVideoPlayerView(
        videos: ExerciseVideo.sampleVideos,
        exerciseName: "Back Squat"
    )
}
