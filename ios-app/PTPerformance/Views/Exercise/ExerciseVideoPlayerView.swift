// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  ExerciseVideoPlayerView.swift
//  PTPerformance
//
//  ACP-813: HD Video Exercise Demos - Full-featured video player
//  ACP-1014: Enhanced video player with improved scrubbing, PiP, A-B loop, bookmarks, and preloading
//  Features: Multi-angle, slow-motion scrubbing, loop mode, PiP, AirPlay, A-B segments, form cue bookmarks
//

import SwiftUI
import AVKit
import AVFoundation

/// Form cue bookmark model
struct FormCueBookmark: Identifiable, Codable {
    let id: UUID
    let timestamp: Double
    let label: String
    let createdAt: Date

    init(id: UUID = UUID(), timestamp: Double, label: String, createdAt: Date = Date()) {
        self.id = id
        self.timestamp = timestamp
        self.label = label
        self.createdAt = createdAt
    }
}

/// A-B loop segment model
struct LoopSegment: Equatable {
    var pointA: Double?
    var pointB: Double?

    var isComplete: Bool {
        pointA != nil && pointB != nil
    }

    var range: ClosedRange<Double>? {
        guard let a = pointA, let b = pointB else { return nil }
        return min(a, b)...max(a, b)
    }
}

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
    @State private var showBookmarksPanel = false
    @State private var showLoopControls = false
    @State private var isFullScreen = false
    @State private var loopSegment = LoopSegment()
    @State private var bookmarks: [FormCueBookmark] = []
    @State private var newBookmarkLabel = ""
    @State private var showBookmarkInput = false
    @State private var angleSwitchOpacity: Double = 1.0

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
                        .opacity(angleSwitchOpacity)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                                showControls.toggle()
                            }
                            if showControls {
                                startControlsTimer()
                            }
                            HapticFeedback.light()
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

                // Bookmarks panel
                if showBookmarksPanel {
                    bookmarksPanel
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }

                // Loop controls panel
                if showLoopControls {
                    loopControlsPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Bookmark input dialog
                if showBookmarkInput {
                    bookmarkInputDialog
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            setupInitialVideo()
            startControlsTimer()
            preloadNextVideos()
        }
        .onDisappear {
            controlsTimer?.invalidate()
            controlsTimer = nil
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
        .padding(.top, Spacing.xs)
    }

    // MARK: - Bottom Control Bar

    private func bottomControlBar(geometry: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            // Enhanced progress bar with bookmarks and loop markers
            EnhancedVideoProgressBar(
                currentTime: controller.currentTime,
                duration: controller.duration,
                bookmarks: bookmarks,
                loopSegment: loopSegment,
                onSeek: { newTime in
                    controller.seek(to: newTime)
                    HapticFeedback.light()
                    resetControlsTimer()
                },
                onBookmarkTap: { bookmark in
                    controller.seek(to: bookmark.timestamp)
                    HapticFeedback.medium()
                }
            )

            // Main controls row
            HStack(spacing: 16) {
                // Play/Pause
                Button {
                    controller.togglePlayPause()
                    HapticFeedback.light()
                    resetControlsTimer()
                } label: {
                    Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(controller.isPlaying ? "Pause" : "Play")
                .accessibilityHint("Toggles video playback")

                // Time display
                HStack(spacing: 4) {
                    Text(formatTime(controller.currentTime))
                    Text("/")
                    Text(formatTime(controller.duration))
                }
                .font(.caption)
                .foregroundColor(.white)
                .monospacedDigit()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Current time \(formatTime(controller.currentTime)) of \(formatTime(controller.duration))")

                Spacer()

                // Angle selector (if multiple angles)
                if availableAngles.count > 1 {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showAngleSelector.toggle()
                            showSpeedSelector = false
                            showBookmarksPanel = false
                            showLoopControls = false
                        }
                        HapticFeedback.selectionChanged()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: selectedVideo?.angle.iconName ?? "person.fill")
                            Text(selectedVideo?.angle.displayName ?? "Angle")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 6)
                        .background(showAngleSelector ? Color.modusCyan : Color.white.opacity(0.2))
                        .cornerRadius(CornerRadius.sm)
                    }
                    .accessibilityLabel("Camera angle: \(selectedVideo?.angle.displayName ?? "Unknown")")
                    .accessibilityHint("Change camera angle")
                }

                // Speed selector
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showSpeedSelector.toggle()
                        showAngleSelector = false
                        showBookmarksPanel = false
                        showLoopControls = false
                    }
                    HapticFeedback.selectionChanged()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "gauge.with.dots.needle.50percent")
                        Text(controller.playbackSpeed.displayName)
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(controller.playbackSpeed.isSlowMotion ? .modusCyan : .white)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 6)
                    .background(showSpeedSelector ? Color.modusCyan : Color.white.opacity(0.2))
                    .cornerRadius(CornerRadius.sm)
                }
                .accessibilityLabel("Playback speed: \(controller.playbackSpeed.displayName)")
                .accessibilityHint("Adjust playback speed")

                // A-B Loop button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showLoopControls.toggle()
                        showAngleSelector = false
                        showSpeedSelector = false
                        showBookmarksPanel = false
                    }
                    HapticFeedback.selectionChanged()
                } label: {
                    Image(systemName: loopSegment.isComplete ? "repeat.circle.fill" : "repeat.circle")
                        .font(.title3)
                        .foregroundColor(loopSegment.isComplete ? .modusTealAccent : .white)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("A-B Loop")
                .accessibilityHint(loopSegment.isComplete ? "Loop is active" : "Set loop points")

                // Bookmarks button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showBookmarksPanel.toggle()
                        showAngleSelector = false
                        showSpeedSelector = false
                        showLoopControls = false
                    }
                    HapticFeedback.selectionChanged()
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bookmark.fill")
                            .font(.title3)
                            .foregroundColor(bookmarks.isEmpty ? .white : .modusTealAccent)
                            .frame(width: 44, height: 44)

                        if !bookmarks.isEmpty {
                            Text("\(bookmarks.count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(3)
                                .background(Color.modusCyan)
                                .clipShape(Circle())
                                .offset(x: 8, y: -2)
                        }
                    }
                }
                .accessibilityLabel("Bookmarks")
                .accessibilityHint("\(bookmarks.count) bookmarks")

                // PiP button
                if controller.supportsPictureInPicture {
                    Button {
                        controller.togglePictureInPicture()
                        HapticFeedback.medium()
                    } label: {
                        Image(systemName: "pip.enter")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Picture in Picture")
                    .accessibilityHint("Enable picture in picture mode")
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.md)
        }
        .padding(.top, Spacing.sm)
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

    // MARK: - Bookmarks Panel

    private var bookmarksPanel: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Form Cue Bookmarks")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showBookmarksPanel = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                // Add bookmark button
                Button {
                    showBookmarkInput = true
                    HapticFeedback.light()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Bookmark at \(formatTime(controller.currentTime))")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.modusCyan)
                    .cornerRadius(CornerRadius.md)
                }
                .accessibilityLabel("Add bookmark at current time")

                // Bookmarks list
                if bookmarks.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "bookmark")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.5))
                        Text("No bookmarks yet")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        Text("Tap + to save form cues")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.vertical, Spacing.lg)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(bookmarks.sorted { $0.timestamp < $1.timestamp }) { bookmark in
                                bookmarkRow(bookmark)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
            .padding()
            .background(Color.black.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .padding()
        }
        .ignoresSafeArea()
    }

    private func bookmarkRow(_ bookmark: FormCueBookmark) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(bookmark.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                Text(formatTime(bookmark.timestamp))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .monospacedDigit()
            }

            Spacer()

            // Jump to button
            Button {
                controller.seek(to: bookmark.timestamp)
                HapticFeedback.medium()
                withAnimation(.spring(response: 0.3)) {
                    showBookmarksPanel = false
                }
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.modusTealAccent)
            }
            .accessibilityLabel("Jump to \(bookmark.label)")

            // Delete button
            Button {
                withAnimation {
                    bookmarks.removeAll { $0.id == bookmark.id }
                }
                HapticFeedback.light()
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red.opacity(0.8))
            }
            .accessibilityLabel("Delete bookmark")
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Bookmark Input Dialog

    private var bookmarkInputDialog: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    showBookmarkInput = false
                    newBookmarkLabel = ""
                }

            VStack(spacing: 20) {
                Text("Add Form Cue")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("At \(formatTime(controller.currentTime))")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .monospacedDigit()

                TextField("e.g., Keep back straight", text: $newBookmarkLabel)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .onSubmit {
                        addBookmark()
                    }

                HStack(spacing: 12) {
                    Button("Cancel") {
                        showBookmarkInput = false
                        newBookmarkLabel = ""
                        HapticFeedback.light()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.md)

                    Button("Save") {
                        addBookmark()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.modusCyan)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.md)
                    .disabled(newBookmarkLabel.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(Spacing.lg)
            .background(Color.black.opacity(0.95))
            .cornerRadius(CornerRadius.lg)
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Loop Controls Panel

    private var loopControlsPanel: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("A-B Loop")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showLoopControls = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                // Instructions
                if !loopSegment.isComplete {
                    Text("Set start and end points to loop a specific segment")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                // Loop point buttons
                HStack(spacing: 12) {
                    // Point A
                    Button {
                        loopSegment.pointA = controller.currentTime
                        HapticFeedback.medium()
                    } label: {
                        VStack(spacing: 4) {
                            Text("A")
                                .font(.title2)
                                .fontWeight(.bold)
                            if let pointA = loopSegment.pointA {
                                Text(formatTime(pointA))
                                    .font(.caption)
                                    .monospacedDigit()
                            } else {
                                Text("Set Start")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(loopSegment.pointA != nil ? Color.modusTealAccent : Color.white.opacity(0.2))
                        .cornerRadius(CornerRadius.md)
                    }
                    .accessibilityLabel(loopSegment.pointA != nil ? "Point A set at \(formatTime(loopSegment.pointA!))" : "Set point A")

                    // Point B
                    Button {
                        loopSegment.pointB = controller.currentTime
                        HapticFeedback.medium()
                        if loopSegment.isComplete {
                            controller.setLoopSegment(loopSegment.range)
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text("B")
                                .font(.title2)
                                .fontWeight(.bold)
                            if let pointB = loopSegment.pointB {
                                Text(formatTime(pointB))
                                    .font(.caption)
                                    .monospacedDigit()
                            } else {
                                Text("Set End")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(loopSegment.pointB != nil ? Color.modusTealAccent : Color.white.opacity(0.2))
                        .cornerRadius(CornerRadius.md)
                    }
                    .accessibilityLabel(loopSegment.pointB != nil ? "Point B set at \(formatTime(loopSegment.pointB!))" : "Set point B")
                }

                // Active loop info
                if loopSegment.isComplete, let range = loopSegment.range {
                    HStack {
                        Image(systemName: "repeat.circle.fill")
                            .foregroundColor(.modusTealAccent)
                        Text("Looping \(formatTime(range.lowerBound)) - \(formatTime(range.upperBound))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.vertical, Spacing.xs)
                    .padding(.horizontal, Spacing.sm)
                    .background(Color.modusTealAccent.opacity(0.2))
                    .cornerRadius(CornerRadius.sm)
                }

                // Clear button
                if loopSegment.pointA != nil || loopSegment.pointB != nil {
                    Button {
                        loopSegment = LoopSegment()
                        controller.setLoopSegment(nil)
                        HapticFeedback.light()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Clear Loop Points")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(CornerRadius.md)
                    }
                }
            }
            .padding()
            .background(Color.black.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .padding()
        }
        .ignoresSafeArea()
    }

    // MARK: - Helper Methods

    private func addBookmark() {
        guard !newBookmarkLabel.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let bookmark = FormCueBookmark(
            timestamp: controller.currentTime,
            label: newBookmarkLabel.trimmingCharacters(in: .whitespaces)
        )
        bookmarks.append(bookmark)
        newBookmarkLabel = ""
        showBookmarkInput = false
        HapticFeedback.success()
    }

    private func preloadNextVideos() {
        // Preload other angle videos for this exercise
        let videosToPreload = videos.filter { !ExerciseVideoService.shared.isVideoCached($0) }
        if !videosToPreload.isEmpty {
            Task {
                for video in videosToPreload.prefix(2) {
                    try? await ExerciseVideoService.shared.cacheVideo(video)
                }
            }
        }
    }

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

        // Smooth crossfade animation
        withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
            angleSwitchOpacity = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationDuration.standard / 2) {
            // Switch video at midpoint of fade
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

            // Fade back in
            withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                angleSwitchOpacity = 1.0
            }
        }

        HapticFeedback.selectionChanged()
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
    private var loopSegmentRange: ClosedRange<Double>?

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
                guard let self = self else { return }
                self.currentTime = time.seconds.isFinite ? time.seconds : 0

                // Check A-B loop segment
                if let loopRange = self.loopSegmentRange,
                   self.currentTime >= loopRange.upperBound {
                    self.player?.seek(to: CMTime(seconds: loopRange.lowerBound, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                }
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

    func setLoopSegment(_ range: ClosedRange<Double>?) {
        loopSegmentRange = range
        if range != nil && !isLooping {
            isLooping = true
        }
    }

    func setPlaybackSpeed(_ speed: PlaybackSpeed) {
        playbackSpeed = speed
        if isPlaying {
            player?.rate = speed.rawValue
        }
    }

    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
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

// MARK: - Enhanced Video Progress Bar

struct EnhancedVideoProgressBar: View {
    let currentTime: Double
    let duration: Double
    let bookmarks: [FormCueBookmark]
    let loopSegment: LoopSegment
    let onSeek: (Double) -> Void
    let onBookmarkTap: (FormCueBookmark) -> Void

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

                // Loop segment highlight
                if let range = loopSegment.range, duration > 0 {
                    let startX = CGFloat(range.lowerBound / duration) * geometry.size.width
                    let endX = CGFloat(range.upperBound / duration) * geometry.size.width
                    Rectangle()
                        .fill(Color.modusTealAccent.opacity(0.4))
                        .frame(width: endX - startX, height: 4)
                        .offset(x: startX)
                }

                // Progress track
                Rectangle()
                    .fill(Color.modusCyan)
                    .frame(width: geometry.size.width * progress, height: 4)

                // Bookmark indicators
                ForEach(bookmarks) { bookmark in
                    if duration > 0 {
                        let position = CGFloat(bookmark.timestamp / duration) * geometry.size.width
                        Button {
                            onBookmarkTap(bookmark)
                        } label: {
                            Image(systemName: "bookmark.fill")
                                .font(.caption2)
                                .foregroundColor(.modusTealAccent)
                                .frame(width: 16, height: 16)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .offset(x: position - 8, y: -10)
                        }
                        .accessibilityLabel(bookmark.label)
                    }
                }

                // Loop point A marker
                if let pointA = loopSegment.pointA, duration > 0 {
                    let position = CGFloat(pointA / duration) * geometry.size.width
                    VStack(spacing: 2) {
                        Text("A")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(2)
                            .background(Color.modusTealAccent)
                            .clipShape(Circle())
                        Rectangle()
                            .fill(Color.modusTealAccent)
                            .frame(width: 2, height: 8)
                    }
                    .offset(x: position - 1, y: -18)
                }

                // Loop point B marker
                if let pointB = loopSegment.pointB, duration > 0 {
                    let position = CGFloat(pointB / duration) * geometry.size.width
                    VStack(spacing: 2) {
                        Text("B")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(2)
                            .background(Color.modusTealAccent)
                            .clipShape(Circle())
                        Rectangle()
                            .fill(Color.modusTealAccent)
                            .frame(width: 2, height: 8)
                    }
                    .offset(x: position - 1, y: -18)
                }

                // Playhead thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: isDragging ? 16 : 12, height: isDragging ? 16 : 12)
                    .shadow(color: Color(.systemGray4).opacity(0.3), radius: 2)
                    .offset(x: geometry.size.width * progress - (isDragging ? 8 : 6))
                    .animation(.easeInOut(duration: 0.15), value: isDragging)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            HapticFeedback.light()
                        }
                        isDragging = true
                        let newPosition = max(0, min(1, value.location.x / geometry.size.width))
                        dragPosition = newPosition
                    }
                    .onEnded { value in
                        isDragging = false
                        let newPosition = max(0, min(1, value.location.x / geometry.size.width))
                        onSeek(newPosition * duration)
                        HapticFeedback.selectionChanged()
                    }
            )
        }
        .frame(height: 44)
        .padding(.horizontal, Spacing.md)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Video progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
        .accessibilityAdjustableAction { direction in
            let increment: Double = 5.0 // 5 seconds
            switch direction {
            case .increment:
                onSeek(min(duration, currentTime + increment))
            case .decrement:
                onSeek(max(0, currentTime - increment))
            @unknown default:
                break
            }
        }
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
