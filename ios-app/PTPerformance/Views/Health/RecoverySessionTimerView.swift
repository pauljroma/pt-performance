import SwiftUI

/// ACP-903: Recovery Session Timer View
/// Active timer during session with countdown/countup, haptic feedback, and contrast therapy phases
struct RecoverySessionTimerView: View {
    let sessionType: RecoverySessionType
    let targetDuration: Int // seconds
    let temperature: Double?
    let onComplete: (Int, String) -> Void
    let onCancel: () -> Void

    @StateObject private var timerManager = RecoveryTimerManager()
    @State private var showingConfirmCancel = false
    @State private var sessionNotes = ""
    @State private var showingCompleteSheet = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.top, Spacing.lg)

                Spacer()

                // Timer Display
                timerDisplayView

                // Phase indicator (for contrast therapy)
                if sessionType == .contrastTherapy {
                    contrastPhaseIndicator
                        .padding(.top, Spacing.lg)
                }

                Spacer()

                // Session Info
                sessionInfoView
                    .padding(.bottom, Spacing.lg)

                // Controls
                controlsView
                    .padding(.bottom, Spacing.xl)
            }
            .padding(.horizontal, Spacing.lg)
        }
        .onAppear {
            timerManager.configure(
                sessionType: sessionType,
                targetDuration: targetDuration
            )
            timerManager.start()
        }
        .onDisappear {
            timerManager.stop()
        }
        .confirmationDialog(
            "End Session?",
            isPresented: $showingConfirmCancel,
            titleVisibility: .visible
        ) {
            Button("End Without Saving", role: .destructive) {
                timerManager.stop()
                onCancel()
            }
            Button("Save Progress") {
                showingCompleteSheet = true
            }
            Button("Continue Session", role: .cancel) {}
        } message: {
            Text("You've been recovering for \(formatTime(timerManager.elapsedSeconds)). Would you like to save this session?")
        }
        .sheet(isPresented: $showingCompleteSheet) {
            completeSessionSheet
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        Group {
            if sessionType == .contrastTherapy {
                // Animated gradient for contrast therapy
                LinearGradient(
                    colors: timerManager.isHotPhase
                        ? [Color.orange.opacity(0.3), Color.red.opacity(0.2)]
                        : [Color.cyan.opacity(0.3), Color.blue.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .animation(.easeInOut(duration: 1.0), value: timerManager.isHotPhase)
            } else if sessionType.isColdTherapy {
                LinearGradient(
                    colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [Color.orange.opacity(0.3), Color.red.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button {
                showingConfirmCancel = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Cancel session")

            Spacer()

            VStack(spacing: 2) {
                Text(sessionType.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)

                if let temp = temperature {
                    Text("\(Int(temp))°F")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Placeholder for symmetry
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(.clear)
        }
    }

    // MARK: - Timer Display

    private var timerDisplayView: some View {
        VStack(spacing: Spacing.lg) {
            // Session icon
            ZStack {
                Circle()
                    .fill(sessionType.color.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: currentPhaseIcon)
                    .font(.system(size: 44))
                    .foregroundStyle(sessionType.gradient)
            }
            .accessibilityHidden(true)

            // Main timer
            Text(formatTime(timerManager.displaySeconds))
                .font(.system(size: 72, weight: .thin, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.primary)
                .accessibilityLabel("Timer: \(formatTimeForAccessibility(timerManager.displaySeconds))")

            // Progress indicator
            if timerManager.countdownMode {
                timerProgressView
            } else {
                // Elapsed time label
                Text("Elapsed Time")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Target duration indicator
            if !timerManager.countdownMode {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "flag.fill")
                        .font(.caption)
                    Text("Target: \(formatTime(targetDuration))")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
    }

    private var timerProgressView: some View {
        VStack(spacing: Spacing.xs) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: timerManager.progress)
                    .stroke(
                        sessionType.gradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerManager.progress)
            }
            .accessibilityHidden(true)

            Text("\(Int(timerManager.progress * 100))% complete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var currentPhaseIcon: String {
        if sessionType == .contrastTherapy {
            return timerManager.isHotPhase ? "flame.fill" : "snowflake"
        }
        return sessionType.icon
    }

    // MARK: - Contrast Phase Indicator

    private var contrastPhaseIndicator: some View {
        VStack(spacing: Spacing.md) {
            // Phase label
            HStack(spacing: Spacing.sm) {
                Image(systemName: timerManager.isHotPhase ? "flame.fill" : "snowflake")
                    .font(.title3)
                    .foregroundColor(timerManager.isHotPhase ? .orange : .cyan)

                Text(timerManager.isHotPhase ? "Hot Phase" : "Cold Phase")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(timerManager.isHotPhase ? Color.orange.opacity(0.2) : Color.cyan.opacity(0.2))
            )

            // Phase progress
            HStack(spacing: Spacing.xs) {
                Text("Phase \(timerManager.currentPhase) of \(timerManager.totalPhases)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("|")
                    .foregroundColor(.secondary)

                Text("\(formatTime(timerManager.phaseTimeRemaining)) remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Phase dots
            HStack(spacing: Spacing.xs) {
                ForEach(1...timerManager.totalPhases, id: \.self) { phase in
                    Circle()
                        .fill(
                            phase < timerManager.currentPhase
                                ? Color.modusTealAccent
                                : phase == timerManager.currentPhase
                                    ? (timerManager.isHotPhase ? Color.orange : Color.cyan)
                                    : Color.gray.opacity(0.3)
                        )
                        .frame(width: 10, height: 10)
                }
            }
            .accessibilityHidden(true)

            // Guidance text
            Text(contrastGuidanceText)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
        }
    }

    private var contrastGuidanceText: String {
        if timerManager.isHotPhase {
            return "Relax in the heat. Focus on deep breathing."
        } else {
            return "Embrace the cold. Stay calm and breathe steadily."
        }
    }

    // MARK: - Session Info

    private var sessionInfoView: some View {
        VStack(spacing: Spacing.sm) {
            // Guidance text
            Text(sessionGuidanceText)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Heart rate zone (if available in future)
            // This is a placeholder for potential heart rate integration
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var sessionGuidanceText: String {
        if sessionType.isColdTherapy {
            if timerManager.elapsedSeconds < 60 {
                return "Take slow, deep breaths. The initial shock will pass."
            } else if timerManager.elapsedSeconds < 120 {
                return "Your body is adapting. Focus on your breathing."
            } else {
                return "Great work! You've passed the hardest part."
            }
        } else if sessionType == .contrastTherapy {
            return "Follow the phase guidance above."
        } else {
            // Heat therapy
            if timerManager.elapsedSeconds < 300 {
                return "Allow your body to warm up gradually."
            } else if timerManager.elapsedSeconds < 900 {
                return "Stay hydrated. Exit if you feel lightheaded."
            } else {
                return "Excellent session! Consider finishing soon."
            }
        }
    }

    // MARK: - Controls

    private var controlsView: some View {
        VStack(spacing: Spacing.md) {
            // Main control buttons
            HStack(spacing: Spacing.xl) {
                // Pause/Resume
                Button {
                    HapticFeedback.medium()
                    if timerManager.isPaused {
                        timerManager.resume()
                    } else {
                        timerManager.pause()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(.secondarySystemBackground))
                            .frame(width: 70, height: 70)

                        Image(systemName: timerManager.isPaused ? "play.fill" : "pause.fill")
                            .font(.title)
                            .foregroundColor(.primary)
                    }
                }
                .accessibilityLabel(timerManager.isPaused ? "Resume timer" : "Pause timer")

                // Complete
                Button {
                    HapticFeedback.success()
                    showingCompleteSheet = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.modusTealAccent)
                            .frame(width: 90, height: 90)

                        Image(systemName: "checkmark")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .accessibilityLabel("Complete session")
                .accessibilityHint("Saves your recovery session")

                // Add time (for countdown mode)
                Button {
                    HapticFeedback.light()
                    timerManager.addTime(60)
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(.secondarySystemBackground))
                            .frame(width: 70, height: 70)

                        VStack(spacing: 0) {
                            Image(systemName: "plus")
                                .font(.headline)
                            Text("1m")
                                .font(.caption2)
                        }
                        .foregroundColor(.primary)
                    }
                }
                .accessibilityLabel("Add 1 minute")
            }

            // Skip phase (for contrast therapy)
            if sessionType == .contrastTherapy {
                Button {
                    HapticFeedback.medium()
                    timerManager.skipPhase()
                } label: {
                    Text("Skip to Next Phase")
                        .font(.subheadline)
                        .foregroundColor(.modusCyan)
                }
                .accessibilityLabel("Skip to next phase")
            }
        }
    }

    // MARK: - Complete Session Sheet

    private var completeSessionSheet: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: Spacing.md) {
                        // Session summary
                        HStack {
                            Image(systemName: sessionType.icon)
                                .font(.title)
                                .foregroundStyle(sessionType.gradient)

                            VStack(alignment: .leading) {
                                Text(sessionType.displayName)
                                    .font(.headline)
                                Text("Session Complete")
                                    .font(.subheadline)
                                    .foregroundColor(.modusTealAccent)
                            }

                            Spacer()

                            Text(formatTime(timerManager.elapsedSeconds))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                    }
                }

                Section {
                    TextField("How did it feel?", text: $sessionNotes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Session Notes (Optional)")
                }
            }
            .navigationTitle("Save Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") {
                        showingCompleteSheet = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        timerManager.stop()
                        onComplete(timerManager.elapsedSeconds, sessionNotes)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
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

// MARK: - Recovery Timer Manager

@MainActor
class RecoveryTimerManager: ObservableObject {
    @Published var elapsedSeconds: Int = 0
    @Published var isPaused: Bool = false
    @Published var countdownMode: Bool = true
    @Published var isHotPhase: Bool = true // For contrast therapy
    @Published var currentPhase: Int = 1
    @Published var phaseTimeRemaining: Int = 0

    private var timer: Timer?
    private var targetDuration: Int = 0
    private var sessionType: RecoverySessionType = .traditionalSauna

    // Contrast therapy configuration
    private let hotPhaseDuration: Int = 180 // 3 minutes
    private let coldPhaseDuration: Int = 60 // 1 minute
    let totalPhases: Int = 6 // 3 hot, 3 cold = 6 phases

    // Haptic feedback intervals (in seconds)
    private let hapticIntervals: Set<Int> = [60, 120, 180, 300, 600]

    var displaySeconds: Int {
        if countdownMode {
            return max(0, targetDuration - elapsedSeconds)
        } else {
            return elapsedSeconds
        }
    }

    var progress: Double {
        guard targetDuration > 0 else { return 0 }
        return min(1.0, Double(elapsedSeconds) / Double(targetDuration))
    }

    func configure(sessionType: RecoverySessionType, targetDuration: Int) {
        self.sessionType = sessionType
        self.targetDuration = targetDuration
        self.countdownMode = sessionType != .contrastTherapy
        self.elapsedSeconds = 0
        self.isPaused = false

        if sessionType == .contrastTherapy {
            isHotPhase = true
            currentPhase = 1
            phaseTimeRemaining = hotPhaseDuration
        }
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func pause() {
        isPaused = true
        timer?.invalidate()
        HapticFeedback.light()
    }

    func resume() {
        isPaused = false
        start()
        HapticFeedback.light()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func addTime(_ seconds: Int) {
        targetDuration += seconds
    }

    func skipPhase() {
        guard sessionType == .contrastTherapy else { return }
        advancePhase()
    }

    private func tick() {
        guard !isPaused else { return }

        elapsedSeconds += 1

        // Haptic feedback at intervals
        if hapticIntervals.contains(elapsedSeconds) {
            HapticFeedback.medium()
        }

        // Contrast therapy phase management
        if sessionType == .contrastTherapy {
            phaseTimeRemaining -= 1
            if phaseTimeRemaining <= 0 {
                advancePhase()
            }

            // Haptic for phase change warning (10 seconds before)
            if phaseTimeRemaining == 10 {
                HapticFeedback.warning()
            }
        }

        // Countdown complete
        if countdownMode && displaySeconds <= 0 {
            HapticFeedback.success()
        }
    }

    private func advancePhase() {
        guard currentPhase < totalPhases else { return }

        currentPhase += 1
        isHotPhase.toggle()

        // Strong haptic for phase change
        HapticFeedback.heavy()

        phaseTimeRemaining = isHotPhase ? hotPhaseDuration : coldPhaseDuration
    }
}

// MARK: - Preview

#if DEBUG
struct RecoverySessionTimerView_Previews: PreviewProvider {
    static var previews: some View {
        RecoverySessionTimerView(
            sessionType: .traditionalSauna,
            targetDuration: 900,
            temperature: 175,
            onComplete: { _, _ in },
            onCancel: {}
        )
        .previewDisplayName("Sauna Timer")

        RecoverySessionTimerView(
            sessionType: .coldPlunge,
            targetDuration: 180,
            temperature: 45,
            onComplete: { _, _ in },
            onCancel: {}
        )
        .previewDisplayName("Cold Plunge Timer")

        RecoverySessionTimerView(
            sessionType: .contrastTherapy,
            targetDuration: 960,
            temperature: 180,
            onComplete: { _, _ in },
            onCancel: {}
        )
        .previewDisplayName("Contrast Therapy Timer")
    }
}
#endif
