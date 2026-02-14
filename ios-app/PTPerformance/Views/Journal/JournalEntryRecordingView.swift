import SwiftUI
import AVFoundation

// MARK: - Journal Entry Recording View

struct JournalEntryRecordingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audioService = AudioRecordingService()
    @State private var audioLevel: Float = 0
    @State private var levelTimer: Timer?
    @State private var showError = false

    var onSave: (JournalEntry) -> Void

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                Color.modusSubtleGradient
                    .ignoresSafeArea()

                VStack(spacing: Spacing.xl) {
                    // Header
                    if audioService.isRecording {
                        recordingHeader
                    } else {
                        instructionHeader
                    }

                    Spacer()

                    // Waveform visualization
                    if audioService.isRecording {
                        waveformVisualization
                            .padding(.horizontal, Spacing.xl)
                    }

                    // Live transcription
                    if !audioService.currentTranscription.isEmpty {
                        transcriptionPreview
                            .padding(.horizontal, Spacing.lg)
                    }

                    Spacer()

                    // Recording button
                    recordingButton

                    // Timer
                    if audioService.isRecording {
                        timerDisplay
                    }
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("Health Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticFeedback.light()
                        dismiss()
                    }
                    .foregroundColor(.modusCyan)
                    .accessibilityLabel("Cancel recording")
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(audioService.errorMessage ?? "An error occurred")
            }
            .onAppear {
                startLevelMonitoring()
            }
            .onDisappear {
                stopLevelMonitoring()
            }
        }
    }

    // MARK: - Header Views

    private var instructionHeader: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.modusCyan)
                .accessibilityHidden(true)

            Text("Record Your Health Check-In")
                .font(.title2)
                .bold()
                .foregroundColor(.modusDeepTeal)
                .accessibilityAddTraits(.isHeader)

            Text("Tap and hold to record, or tap to toggle")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.xl)
    }

    private var recordingHeader: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                    .pulse()

                Text("Recording")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Recording in progress")

            if audioService.isTranscribing {
                Text("Transcribing...")
                    .font(.caption)
                    .foregroundColor(.modusTealAccent)
            }
        }
    }

    // MARK: - Waveform Visualization

    private var waveformVisualization: some View {
        HStack(spacing: 4) {
            ForEach(0..<30, id: \.self) { index in
                WaveformBar(level: audioLevel, index: index)
            }
        }
        .frame(height: 120)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Audio level visualization")
        .accessibilityValue(String(format: "%.0f percent", audioLevel * 100))
    }

    // MARK: - Transcription Preview

    private var transcriptionPreview: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .foregroundColor(.modusTealAccent)
                Text("Live Transcription")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .bold()
            }
            .accessibilityHidden(true)

            ScrollView {
                Text(audioService.currentTranscription)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 150)
        }
        .padding(Spacing.md)
        .background(Color.modusLightTeal)
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Transcription: \(audioService.currentTranscription)")
    }

    // MARK: - Recording Button

    private var recordingButton: some View {
        Button(action: {
            if audioService.isRecording {
                handleStopRecording()
            } else {
                handleStartRecording()
            }
        }) {
            ZStack {
                // Pulsing ring when recording
                if audioService.isRecording {
                    Circle()
                        .stroke(Color.modusCyan.opacity(0.3), lineWidth: 8)
                        .frame(width: 120, height: 120)
                        .scaleEffect(audioService.isRecording ? 1.2 : 1.0)
                        .opacity(audioService.isRecording ? 0.5 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: audioService.isRecording
                        )
                }

                // Main button
                Circle()
                    .fill(audioService.isRecording ? Color.red : Color.modusCyan)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: audioService.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    )
                    .adaptiveShadow(Shadow.prominent)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(audioService.isRecording ? "Stop recording" : "Start recording")
        .accessibilityHint(audioService.isRecording ? "Tap to stop and save" : "Tap to start recording")
    }

    // MARK: - Timer Display

    private var timerDisplay: some View {
        Text(formatDuration(audioService.recordingDuration))
            .font(.system(.title3, design: .monospaced))
            .foregroundColor(.modusDeepTeal)
            .accessibilityLabel("Recording time: \(formatDuration(audioService.recordingDuration))")
    }

    // MARK: - Actions

    private func handleStartRecording() {
        HapticFeedback.medium()
        Task {
            do {
                try await audioService.startRecording()
            } catch {
                audioService.errorMessage = error.localizedDescription
                showError = true
                HapticFeedback.error()
            }
        }
    }

    private func handleStopRecording() {
        HapticFeedback.success()
        Task {
            let result = await audioService.stopRecording()

            // Create journal entry
            let entry = JournalEntry(
                date: Date(),
                audioURL: result.url,
                transcription: result.transcription,
                mood: .neutral,
                tags: [],
                duration: result.duration
            )

            onSave(entry)
            dismiss()
        }
    }

    // MARK: - Audio Level Monitoring

    private func startLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            audioLevel = audioService.getAudioLevel()
        }
    }

    private func stopLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Waveform Bar

struct WaveformBar: View {
    let level: Float
    let index: Int
    @State private var randomHeight: CGFloat = 0.3

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [.modusCyan, .modusTealAccent],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(height: calculateHeight())
            .animation(.easeInOut(duration: 0.1), value: level)
            .onAppear {
                randomHeight = CGFloat.random(in: 0.2...0.8)
            }
    }

    private func calculateHeight() -> CGFloat {
        let baseHeight: CGFloat = 20
        let maxHeight: CGFloat = 120
        let levelMultiplier = CGFloat(level)
        let randomVariation = randomHeight * 0.3
        return baseHeight + (maxHeight - baseHeight) * levelMultiplier * (randomHeight + randomVariation)
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.quick), value: configuration.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
struct JournalEntryRecordingView_Previews: PreviewProvider {
    static var previews: some View {
        JournalEntryRecordingView { entry in
            print("Saved entry: \(entry)")
        }
    }
}
#endif
