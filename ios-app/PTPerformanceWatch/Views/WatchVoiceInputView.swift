//
//  WatchVoiceInputView.swift
//  PTPerformanceWatch
//
//  Voice input interface for hands-free set logging
//  ACP-824: Apple Watch Standalone App
//

import SwiftUI

struct WatchVoiceInputView: View {
    @ObservedObject var voiceService: VoiceLoggingService
    let onComplete: (VoiceCommandResult?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var isListening = false
    @State private var recognizedText = ""
    @State private var parsedResult: VoiceCommandResult?
    @State private var errorMessage: String?
    @State private var animationPhase = 0.0

    var body: some View {
        VStack(spacing: 12) {
            // Status indicator
            Text(isListening ? "Listening..." : "Tap to Start")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Microphone button with animation
            Button {
                toggleListening()
            } label: {
                ZStack {
                    // Animated rings when listening
                    if isListening {
                        ForEach(0..<3) { i in
                            Circle()
                                .stroke(Color.modusCyan.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                                .scaleEffect(1 + Double(i) * 0.2 + animationPhase * 0.1)
                                .animation(
                                    Animation.easeInOut(duration: 1)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.2),
                                    value: animationPhase
                                )
                        }
                    }

                    Circle()
                        .fill(isListening ? Color.red : Color.modusCyan)
                        .frame(width: 60, height: 60)

                    Image(systemName: isListening ? "stop.fill" : "mic.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .frame(width: 80, height: 80)

            // Recognized text display
            if !recognizedText.isEmpty {
                Text(recognizedText)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal)
            }

            // Parsed result preview
            if let result = parsedResult, result.isValid {
                VStack(spacing: 4) {
                    Text("Detected:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(result.summary)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
                .padding(.vertical, 4)

                // Confirm button
                Button {
                    onComplete(result)
                    dismiss()
                } label: {
                    Label("Confirm", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            // Help text
            Text("Say: \"10 reps at 135\"")
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Cancel button
            Button("Cancel") {
                stopListening()
                onComplete(nil)
                dismiss()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .font(.caption)
        }
        .padding()
        .onAppear {
            animationPhase = 1.0
        }
        .onDisappear {
            stopListening()
        }
    }

    // MARK: - Actions

    private func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }

    private func startListening() {
        isListening = true
        errorMessage = nil
        recognizedText = ""
        parsedResult = nil
        WatchHapticService.shared.selection()

        Task {
            do {
                try await voiceService.startListening()

                // Monitor for results
                for await result in voiceService.recognitionResults {
                    await MainActor.run {
                        recognizedText = result.rawText
                        if let parsed = voiceService.processVoiceCommand(result.rawText) {
                            parsedResult = parsed
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Voice recognition failed"
                    isListening = false
                    WatchHapticService.shared.error()
                }
            }
        }
    }

    private func stopListening() {
        voiceService.stopListening()
        isListening = false
    }
}

// MARK: - Preview

#Preview {
    WatchVoiceInputView(
        voiceService: VoiceLoggingService(),
        onComplete: { _ in }
    )
}
