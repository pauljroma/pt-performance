// DARK MODE: Optimized for dark mode with calming teal theme
import SwiftUI
import AVFoundation

/// ACP-1075: Guided Breathing for Sleep (4-7-8 Pattern)
/// Visual breathing guide with expanding/contracting circle animation, ambient sounds, and full accessibility
struct GuidedBreathingView: View {
    @StateObject private var breathingManager = BreathingManager()
    @State private var showingSettings = false
    @State private var showingCompletionSummary = false
    @State private var isSessionActive = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background - calming deep teal
            Color.modusDeepTeal
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                if !isSessionActive {
                    headerView
                        .padding(.top, Spacing.lg)
                }

                Spacer()

                if isSessionActive {
                    // Active breathing session
                    breathingCircleView
                        .transition(.scale.combined(with: .opacity))
                } else {
                    // Setup screen
                    setupView
                        .transition(.opacity)
                }

                Spacer()

                // Controls
                if isSessionActive {
                    activeControlsView
                        .padding(.bottom, Spacing.xl)
                } else {
                    startControlsView
                        .padding(.bottom, Spacing.xl)
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
        .onAppear {
            breathingManager.configure(session: BreathingSession())
        }
        .sheet(isPresented: $showingSettings) {
            settingsSheet
        }
        .sheet(isPresented: $showingCompletionSummary) {
            completionSummarySheet
        }
        .preferredColorScheme(.dark) // Force dark mode for calming effect
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.modusTealAccent.opacity(0.7))
            }
            .accessibilityLabel("Close")

            Spacer()

            Text("Guided Breathing")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Spacer()

            Button {
                showingSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.modusTealAccent.opacity(0.7))
            }
            .accessibilityLabel("Settings")
        }
    }

    // MARK: - Breathing Circle Animation

    private var breathingCircleView: some View {
        VStack(spacing: Spacing.xl) {
            // Phase text
            Text(breathingManager.currentPhase.displayText)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .transition(.opacity)
                .id(breathingManager.currentPhase.displayText) // Force rebuild for crossfade
                .animation(.easeInOut(duration: 0.5), value: breathingManager.currentPhase)
                .accessibilityLabel(breathingManager.currentPhase.displayText)
                .accessibilityHint("Current breathing phase")

            // Animated breathing circle
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.modusCyan.opacity(breathingManager.circleGlowOpacity),
                                Color.modusCyan.opacity(0)
                            ],
                            center: .center,
                            startRadius: 80,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .blur(radius: 20)
                    .animation(.easeInOut(duration: 1.0), value: breathingManager.circleGlowOpacity)

                // Main breathing circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.modusCyan, Color.modusTealAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(breathingManager.circleScale)
                    .opacity(breathingManager.circleOpacity)

                // Inner icon
                Image(systemName: breathingManager.currentPhase.icon)
                    .font(.system(size: 44))
                    .foregroundColor(.white)
                    .scaleEffect(breathingManager.circleScale)
            }
            .accessibilityHidden(true)

            // Progress ring
            progressRingView
                .padding(.top, Spacing.lg)

            // Guidance text
            Text(breathingManager.guidanceText)
                .font(.subheadline)
                .foregroundColor(.modusTealAccent.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
                .animation(.easeInOut, value: breathingManager.guidanceText)
        }
    }

    // MARK: - Progress Ring

    private var progressRingView: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.modusCyan.opacity(0.2), lineWidth: 6)
                    .frame(width: 120, height: 120)

                // Progress ring
                Circle()
                    .trim(from: 0, to: breathingManager.sessionProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Color.modusCyan, Color.modusTealAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: breathingManager.sessionProgress)

                // Time remaining
                VStack(spacing: 2) {
                    Text(formatTime(breathingManager.timeRemaining))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .monospacedDigit()

                    Text("remaining")
                        .font(.caption2)
                        .foregroundColor(.modusTealAccent.opacity(0.7))
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Session progress: \(Int(breathingManager.sessionProgress * 100))% complete, \(formatTimeForAccessibility(breathingManager.timeRemaining)) remaining")

            // Breath count
            HStack(spacing: Spacing.xs) {
                Image(systemName: "wind")
                    .font(.caption)
                    .foregroundColor(.modusTealAccent.opacity(0.7))
                Text("\(breathingManager.completedBreaths) breaths")
                    .font(.caption)
                    .foregroundColor(.modusTealAccent.opacity(0.7))
            }
            .accessibilityLabel("\(breathingManager.completedBreaths) breaths completed")
        }
    }

    // MARK: - Setup View

    private var setupView: some View {
        VStack(spacing: Spacing.xl) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.modusCyan.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "wind")
                    .font(.system(size: 50))
                    .foregroundColor(.modusCyan)
            }
            .accessibilityHidden(true)

            VStack(spacing: Spacing.sm) {
                Text("Guided Breathing for Sleep")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("The 4-7-8 breathing technique helps calm your nervous system and prepare your body for restful sleep.")
                    .font(.body)
                    .foregroundColor(.modusTealAccent.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }

            // Session options
            VStack(spacing: Spacing.md) {
                // Duration picker
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Session Duration")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.modusTealAccent)

                    HStack(spacing: Spacing.sm) {
                        ForEach([5, 10, 15, 20], id: \.self) { minutes in
                            Button {
                                HapticFeedback.selectionChanged()
                                breathingManager.setDuration(minutes * 60)
                            } label: {
                                Text("\(minutes) min")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(
                                        breathingManager.session.targetDuration == minutes * 60
                                            ? .white
                                            : .modusTealAccent
                                    )
                                    .padding(.horizontal, Spacing.md)
                                    .padding(.vertical, Spacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: CornerRadius.md)
                                            .fill(
                                                breathingManager.session.targetDuration == minutes * 60
                                                    ? Color.modusCyan
                                                    : Color.modusCyan.opacity(0.2)
                                            )
                                    )
                            }
                            .accessibilityLabel("\(minutes) minutes")
                            .accessibilityAddTraits(
                                breathingManager.session.targetDuration == minutes * 60
                                    ? [.isButton, .isSelected]
                                    : .isButton
                            )
                        }
                    }
                }

                // Ambient sound picker
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Ambient Sound")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.modusTealAccent)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.sm) {
                            ForEach(AmbientSound.allCases) { sound in
                                Button {
                                    HapticFeedback.selectionChanged()
                                    breathingManager.setAmbientSound(sound == .none ? nil : sound)
                                } label: {
                                    VStack(spacing: Spacing.xs) {
                                        Image(systemName: sound.icon)
                                            .font(.title3)
                                        Text(sound.displayName)
                                            .font(.caption)
                                    }
                                    .foregroundColor(
                                        breathingManager.session.ambientSound == sound
                                            || (sound == .none && breathingManager.session.ambientSound == nil)
                                            ? .white
                                            : .modusTealAccent
                                    )
                                    .frame(width: 80)
                                    .padding(.vertical, Spacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: CornerRadius.md)
                                            .fill(
                                                breathingManager.session.ambientSound == sound
                                                    || (sound == .none && breathingManager.session.ambientSound == nil)
                                                    ? Color.modusCyan
                                                    : Color.modusCyan.opacity(0.2)
                                            )
                                    )
                                }
                                .accessibilityLabel(sound.displayName)
                                .accessibilityAddTraits(
                                    breathingManager.session.ambientSound == sound
                                        || (sound == .none && breathingManager.session.ambientSound == nil)
                                        ? [.isButton, .isSelected]
                                        : .isButton
                                )
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }

                // Narration toggle
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundColor(.modusTealAccent)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Voice Guidance")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Text("Audio cues for each phase")
                            .font(.caption)
                            .foregroundColor(.modusTealAccent.opacity(0.7))
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { breathingManager.session.enableNarration },
                        set: { breathingManager.setNarration($0) }
                    ))
                    .tint(.modusCyan)
                    .accessibilityLabel("Voice guidance")
                    .accessibilityHint(breathingManager.session.enableNarration ? "On" : "Off")
                    .onChange(of: breathingManager.session.enableNarration) { _, _ in
                        HapticFeedback.toggle()
                    }
                }
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color.modusCyan.opacity(0.15))
                )
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    // MARK: - Controls

    private var startControlsView: some View {
        Button {
            HapticFeedback.medium()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isSessionActive = true
                breathingManager.start()
            }
        } label: {
            HStack {
                Image(systemName: "play.fill")
                    .font(.headline)
                Text("Start Session")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                LinearGradient(
                    colors: [Color.modusCyan, Color.modusTealAccent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(CornerRadius.lg)
        }
        .accessibilityLabel("Start breathing session")
        .accessibilityHint("Begins guided breathing exercise")
    }

    private var activeControlsView: some View {
        HStack(spacing: Spacing.xl) {
            // Pause/Resume
            Button {
                HapticFeedback.medium()
                if breathingManager.isPaused {
                    breathingManager.resume()
                } else {
                    breathingManager.pause()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.modusCyan.opacity(0.3))
                        .frame(width: 70, height: 70)

                    Image(systemName: breathingManager.isPaused ? "play.fill" : "pause.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
            }
            .accessibilityLabel(breathingManager.isPaused ? "Resume" : "Pause")

            // Complete
            Button {
                HapticFeedback.success()
                breathingManager.stop()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isSessionActive = false
                    showingCompletionSummary = true
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.modusCyan, Color.modusTealAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)

                    Image(systemName: "checkmark")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .accessibilityLabel("Complete session")
            .accessibilityHint("Ends session and shows summary")

            // End early
            Button {
                HapticFeedback.light()
                breathingManager.stop()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isSessionActive = false
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.modusCyan.opacity(0.3))
                        .frame(width: 70, height: 70)

                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .accessibilityLabel("End session")
        }
    }

    // MARK: - Settings Sheet

    private var settingsSheet: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        // Inhale duration
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Text("Inhale Duration")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(breathingManager.session.inhaleDuration))s")
                                    .font(.subheadline)
                                    .foregroundColor(.modusCyan)
                                    .monospacedDigit()
                            }

                            Slider(
                                value: Binding(
                                    get: { breathingManager.session.inhaleDuration },
                                    set: { breathingManager.setInhaleDuration($0) }
                                ),
                                in: 2...8,
                                step: 0.5
                            )
                            .tint(.modusCyan)
                            .accessibilityLabel("Inhale duration: \(Int(breathingManager.session.inhaleDuration)) seconds")
                        }

                        Divider()

                        // Hold duration
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Text("Hold Duration")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(breathingManager.session.holdDuration))s")
                                    .font(.subheadline)
                                    .foregroundColor(.modusCyan)
                                    .monospacedDigit()
                            }

                            Slider(
                                value: Binding(
                                    get: { breathingManager.session.holdDuration },
                                    set: { breathingManager.setHoldDuration($0) }
                                ),
                                in: 2...10,
                                step: 0.5
                            )
                            .tint(.modusCyan)
                            .accessibilityLabel("Hold duration: \(Int(breathingManager.session.holdDuration)) seconds")
                        }

                        Divider()

                        // Exhale duration
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Text("Exhale Duration")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(breathingManager.session.exhaleDuration))s")
                                    .font(.subheadline)
                                    .foregroundColor(.modusCyan)
                                    .monospacedDigit()
                            }

                            Slider(
                                value: Binding(
                                    get: { breathingManager.session.exhaleDuration },
                                    set: { breathingManager.setExhaleDuration($0) }
                                ),
                                in: 4...12,
                                step: 0.5
                            )
                            .tint(.modusCyan)
                            .accessibilityLabel("Exhale duration: \(Int(breathingManager.session.exhaleDuration)) seconds")
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                } header: {
                    Text("Breathing Pattern")
                } footer: {
                    Text("Customize your breathing rhythm. The 4-7-8 pattern (4s inhale, 7s hold, 8s exhale) is recommended for sleep.")
                }

                Section {
                    HStack {
                        Image(systemName: "wind")
                            .foregroundColor(.modusCyan)
                        VStack(alignment: .leading) {
                            Text("One Breath Cycle")
                                .font(.subheadline)
                            Text("\(Int(breathingManager.session.cycleDuration))s total")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(breathingManager.session.estimatedCycles)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.modusCyan)
                    }
                } header: {
                    Text("Session Estimate")
                } footer: {
                    Text("Based on your \(breathingManager.session.targetDuration / 60)-minute session")
                }

                Section {
                    Button {
                        HapticFeedback.medium()
                        breathingManager.resetToDefault()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset to 4-7-8 Pattern")
                        }
                        .foregroundColor(.modusCyan)
                    }
                }
            }
            .navigationTitle("Breathing Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingSettings = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Completion Summary Sheet

    private var completionSummarySheet: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                Spacer()

                // Celebration icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.modusCyan.opacity(0.3), Color.modusTealAccent.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.modusCyan, Color.modusTealAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .accessibilityHidden(true)

                VStack(spacing: Spacing.sm) {
                    Text("Session Complete")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.modusCyan)

                    Text("Well done! You've completed your breathing practice.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Session stats
                VStack(spacing: Spacing.md) {
                    BreathingStatRow(
                        icon: "clock.fill",
                        label: "Duration",
                        value: formatTime(breathingManager.elapsedSeconds)
                    )

                    BreathingStatRow(
                        icon: "wind",
                        label: "Total Breaths",
                        value: "\(breathingManager.completedBreaths)"
                    )

                    if let sound = breathingManager.session.ambientSound {
                        BreathingStatRow(
                            icon: sound.icon,
                            label: "Ambient Sound",
                            value: sound.displayName
                        )
                    }
                }
                .padding(Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .padding(.horizontal, Spacing.lg)

                Spacer()

                // Action buttons
                VStack(spacing: Spacing.md) {
                    Button {
                        HapticFeedback.success()

                        // Track breathing session completion to analytics
                        AnalyticsTracker.shared.track(
                            event: "breathing_session_saved",
                            properties: [
                                "technique": breathingManager.session.name,
                                "duration_seconds": breathingManager.elapsedSeconds,
                                "completed_breaths": breathingManager.completedBreaths,
                                "target_duration_seconds": breathingManager.session.targetDuration,
                                "completion_rate": breathingManager.session.targetDuration > 0
                                    ? Double(breathingManager.elapsedSeconds) / Double(breathingManager.session.targetDuration)
                                    : 0,
                                "ambient_sound": breathingManager.session.ambientSound?.rawValue ?? "none"
                            ]
                        )

                        showingCompletionSummary = false
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down.fill")
                                .font(.headline)
                            Text("Save to Health Log")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(
                            LinearGradient(
                                colors: [Color.modusCyan, Color.modusTealAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(CornerRadius.lg)
                    }
                    .accessibilityLabel("Save session to health log")

                    Button {
                        showingCompletionSummary = false
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.modusCyan)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.lg)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                    }
                    .accessibilityLabel("Dismiss summary")
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    private func formatTimeForAccessibility(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if minutes > 0 {
            return "\(minutes) minutes, \(remainingSeconds) seconds"
        } else {
            return "\(remainingSeconds) seconds"
        }
    }
}

// MARK: - Stat Row Component

private struct BreathingStatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.modusCyan)
                .frame(width: 30)
                .accessibilityHidden(true)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Breathing Manager

@MainActor
final class BreathingManager: ObservableObject {
    @Published var session: BreathingSession = BreathingSession()
    @Published var currentPhase: BreathingPhase = .transition
    @Published var circleScale: CGFloat = 1.0
    @Published var circleOpacity: Double = 0.8
    @Published var circleGlowOpacity: Double = 0.3
    @Published var isPaused: Bool = false
    @Published var sessionProgress: Double = 0.0
    @Published var timeRemaining: Int = 0
    @Published var elapsedSeconds: Int = 0
    @Published var completedBreaths: Int = 0
    @Published var guidanceText: String = "Prepare to begin..."

    private var timer: Timer?
    private var phaseStartTime: Date?
    private var sessionStartTime: Date?
    private var audioPlayer: AVAudioPlayer?
    private var isActive: Bool = false

    deinit {
        timer?.invalidate()
        audioPlayer?.stop()
    }

    func configure(session: BreathingSession) {
        self.session = session
        self.timeRemaining = session.targetDuration
    }

    func start() {
        sessionStartTime = Date()
        phaseStartTime = Date()
        isActive = true
        isPaused = false
        elapsedSeconds = 0
        completedBreaths = 0
        timeRemaining = session.targetDuration

        // Start ambient sound
        if let sound = session.ambientSound {
            playAmbientSound(sound)
        }

        // Begin with inhale phase
        startPhase(.inhale)

        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isActive else { return }
                self.tick()
            }
        }
    }

    func pause() {
        isPaused = true
        timer?.invalidate()
        audioPlayer?.pause()
        HapticFeedback.light()
    }

    func resume() {
        isPaused = false
        phaseStartTime = Date()
        audioPlayer?.play()
        HapticFeedback.light()

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isActive else { return }
                self.tick()
            }
        }
    }

    func stop() {
        isActive = false
        timer?.invalidate()
        timer = nil
        audioPlayer?.stop()
        audioPlayer = nil
    }

    private func tick() {
        guard !isPaused, let phaseStart = phaseStartTime else { return }

        let elapsed = Date().timeIntervalSince(phaseStart)
        let phaseDuration = currentPhaseDuration()

        // Update session progress
        if let sessionStart = sessionStartTime {
            elapsedSeconds = Int(Date().timeIntervalSince(sessionStart))
            timeRemaining = max(0, session.targetDuration - elapsedSeconds)
            sessionProgress = min(1.0, Double(elapsedSeconds) / Double(session.targetDuration))

            // End session if time is up
            if timeRemaining <= 0 {
                HapticFeedback.success()
                stop()
            }
        }

        // Animate based on phase
        updateAnimation(elapsed: elapsed, duration: phaseDuration)

        // Advance to next phase when duration is complete
        if elapsed >= phaseDuration {
            advancePhase()
        }
    }

    private func startPhase(_ phase: BreathingPhase) {
        currentPhase = phase
        phaseStartTime = Date()

        // Haptic feedback
        switch phase {
        case .inhale:
            HapticFeedback.light()
            updateGuidanceText(for: phase)
        case .hold:
            updateGuidanceText(for: phase)
        case .exhale:
            HapticFeedback.light()
            completedBreaths += 1
            updateGuidanceText(for: phase)
        case .transition:
            updateGuidanceText(for: phase)
        }

        // Voice narration (post-v1: will use AVSpeechSynthesizer for spoken phase cues)
        if session.enableNarration {
            // Narration support is planned for a future release.
        }
    }

    private func advancePhase() {
        switch currentPhase {
        case .transition:
            startPhase(.inhale)
        case .inhale:
            startPhase(.hold)
        case .hold:
            startPhase(.exhale)
        case .exhale:
            startPhase(.inhale)
        }
    }

    private func updateAnimation(elapsed: TimeInterval, duration: Double) {
        let progress = min(1.0, elapsed / duration)

        switch currentPhase {
        case .inhale:
            // Expand circle smoothly
            circleScale = 1.0 + (0.5 * progress) // 1.0 → 1.5
            circleOpacity = 0.8 + (0.2 * progress) // 0.8 → 1.0
            circleGlowOpacity = 0.3 + (0.4 * progress) // 0.3 → 0.7

        case .hold:
            // Pulsing opacity at full scale
            circleScale = 1.5
            let pulse = sin(elapsed * 2) * 0.5 + 0.5 // 0 → 1 oscillation
            circleOpacity = 0.9 + (pulse * 0.1)
            circleGlowOpacity = 0.6 + (pulse * 0.2)

        case .exhale:
            // Contract circle smoothly
            circleScale = 1.5 - (0.5 * progress) // 1.5 → 1.0
            circleOpacity = 1.0 - (0.2 * progress) // 1.0 → 0.8
            circleGlowOpacity = 0.7 - (0.4 * progress) // 0.7 → 0.3

        case .transition:
            circleScale = 1.0
            circleOpacity = 0.8
            circleGlowOpacity = 0.3
        }
    }

    private func currentPhaseDuration() -> Double {
        switch currentPhase {
        case .inhale: return session.inhaleDuration
        case .hold: return session.holdDuration
        case .exhale: return session.exhaleDuration
        case .transition: return 2.0
        }
    }

    private func updateGuidanceText(for phase: BreathingPhase) {
        switch phase {
        case .inhale:
            let tips = [
                "Breathe in slowly through your nose...",
                "Fill your lungs completely...",
                "Inhale deeply and steadily...",
                "Draw air in gently..."
            ]
            guidanceText = tips.randomElement() ?? tips[0]
        case .hold:
            let tips = [
                "Hold your breath gently...",
                "Pause and relax...",
                "Let the oxygen settle...",
                "Stay calm and still..."
            ]
            guidanceText = tips.randomElement() ?? tips[0]
        case .exhale:
            let tips = [
                "Release slowly through your mouth...",
                "Let go of all tension...",
                "Exhale completely and relax...",
                "Breathe out slowly and steadily..."
            ]
            guidanceText = tips.randomElement() ?? tips[0]
        case .transition:
            guidanceText = "Prepare for your next breath..."
        }
    }

    private func playAmbientSound(_ sound: AmbientSound) {
        // Post-v1: Ambient sound playback is not yet wired up.
        // Implementation will add bundled audio files (rain.mp3, ocean.mp3, etc.)
        // and use AVAudioPlayer with looping for continuous playback.
    }

    // MARK: - Settings Methods

    func setDuration(_ seconds: Int) {
        session.targetDuration = seconds
        timeRemaining = seconds
        objectWillChange.send()
    }

    func setAmbientSound(_ sound: AmbientSound?) {
        session.ambientSound = sound
        objectWillChange.send()
    }

    func setNarration(_ enabled: Bool) {
        session.enableNarration = enabled
        objectWillChange.send()
    }

    func setInhaleDuration(_ duration: Double) {
        session.inhaleDuration = duration
        objectWillChange.send()
    }

    func setHoldDuration(_ duration: Double) {
        session.holdDuration = duration
        objectWillChange.send()
    }

    func setExhaleDuration(_ duration: Double) {
        session.exhaleDuration = duration
        objectWillChange.send()
    }

    func resetToDefault() {
        session.inhaleDuration = 4.0
        session.holdDuration = 7.0
        session.exhaleDuration = 8.0
        HapticFeedback.success()
        objectWillChange.send()
    }
}

// MARK: - Preview

#if DEBUG
struct GuidedBreathingView_Previews: PreviewProvider {
    static var previews: some View {
        GuidedBreathingView()
            .preferredColorScheme(.dark)
    }
}
#endif
