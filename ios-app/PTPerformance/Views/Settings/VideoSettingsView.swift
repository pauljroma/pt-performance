// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  VideoSettingsView.swift
//  PTPerformance
//
//  Created by Content & Polish Sprint Agent 5
//  Settings view for video playback preferences
//

import SwiftUI

/// Settings view for video playback preferences
/// Allows users to configure video quality, autoplay, captions, and playback speed
struct VideoSettingsView: View {
    @StateObject private var preferencesService = VideoPreferencesService.shared
    @State private var showQualityInfo = false
    @State private var isUpdating = false
    @State private var updateError: String?
    @State private var showErrorAlert = false

    var body: some View {
        List {
            // Quality Section
            Section {
                // Quality picker
                Picker("Video Quality", selection: qualityBinding) {
                    ForEach(VideoQuality.allCases) { quality in
                        Text(quality.displayName).tag(quality)
                    }
                }
                .disabled(isUpdating)

                // Quality info
                if let quality = preferencesService.preferences?.preferredQuality {
                    HStack {
                        Image(systemName: qualityIcon(for: quality))
                            .foregroundColor(DesignTokens.statusInfo)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        Text(quality.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Quality info: \(quality.description)")
                }
            } header: {
                Text("Quality")
            } footer: {
                Text("Auto adjusts quality based on your connection speed")
            }

            // Playback Section
            Section {
                // Auto-play toggle
                Toggle(isOn: autoPlayBinding) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(DesignTokens.statusSuccess)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        Text("Auto-play Videos")
                    }
                }
                .disabled(isUpdating)
                .accessibilityLabel("Auto-play Videos")
                .accessibilityValue(preferencesService.isAutoPlayEnabled ? "On" : "Off")
                .accessibilityHint("Toggle to automatically play videos when they load")

                // Captions toggle
                Toggle(isOn: captionsBinding) {
                    HStack {
                        Image(systemName: "captions.bubble.fill")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        Text("Show Captions")
                    }
                }
                .disabled(isUpdating)
                .accessibilityLabel("Show Captions")
                .accessibilityValue(preferencesService.areCaptionsEnabled ? "On" : "Off")
                .accessibilityHint("Toggle to display captions on videos")

                // Playback speed
                Picker(selection: speedBinding) {
                    Text("0.5x").tag(0.5)
                    Text("0.75x").tag(0.75)
                    Text("1x (Normal)").tag(1.0)
                    Text("1.25x").tag(1.25)
                    Text("1.5x").tag(1.5)
                    Text("2x").tag(2.0)
                } label: {
                    HStack {
                        Image(systemName: "speedometer")
                            .foregroundColor(DesignTokens.statusWarning)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        Text("Playback Speed")
                    }
                }
                .disabled(isUpdating)
                .accessibilityLabel("Playback Speed")
                .accessibilityValue(formatSpeed(preferencesService.currentPlaybackSpeed))
            } header: {
                Text("Playback")
            } footer: {
                Text("Playback speed applies to all exercise videos")
            }

            // Data Usage Section
            Section {
                HStack {
                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                        .foregroundColor(DesignTokens.statusInfo)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    Text("Estimated per 5-min video")
                    Spacer()
                    Text(estimatedDataUsage)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Estimated data per 5 minute video: \(estimatedDataUsage)")

                // Quality comparison
                VStack(alignment: .leading, spacing: 8) {
                    DataUsageRow(quality: .sd, label: "SD (480p)")
                    DataUsageRow(quality: .hd, label: "HD (720p)")
                    DataUsageRow(quality: .fhd, label: "Full HD (1080p)")
                }
                .padding(.vertical, Spacing.xxs)
            } header: {
                Text("Data Usage")
            } footer: {
                Text("Data usage may vary based on video content and encoding")
            }

            // Current Settings Summary
            if let prefs = preferencesService.preferences {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        SummaryRow(label: "Quality", value: prefs.preferredQuality.displayName)
                        SummaryRow(label: "Auto-play", value: prefs.autoPlay ? "On" : "Off")
                        SummaryRow(label: "Captions", value: prefs.showCaptions ? "On" : "Off")
                        SummaryRow(label: "Speed", value: formatSpeed(prefs.playbackSpeed))
                    }
                } header: {
                    Text("Current Settings")
                }
            }
        }
        .navigationTitle("Video Settings")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if preferencesService.isLoading && preferencesService.preferences == nil {
                ProgressView("Loading preferences...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.9))
            }
        }
        .overlay(alignment: .top) {
            if isUpdating {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Saving...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(CornerRadius.sm)
                .shadow(radius: 2)
                .padding(.top, Spacing.xs)
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(updateError ?? "An unknown error occurred")
        }
        .task {
            await loadPreferences()
        }
    }

    // MARK: - Load Preferences

    private func loadPreferences() async {
        do {
            try await preferencesService.fetchPreferences()
        } catch {
            updateError = error.localizedDescription
            showErrorAlert = true
        }
    }

    // MARK: - Computed Bindings

    private var qualityBinding: Binding<VideoQuality> {
        Binding(
            get: { preferencesService.currentQuality },
            set: { newValue in
                Task {
                    await updateQuality(newValue)
                }
            }
        )
    }

    private var autoPlayBinding: Binding<Bool> {
        Binding(
            get: { preferencesService.isAutoPlayEnabled },
            set: { newValue in
                Task {
                    await updateAutoPlay(newValue)
                }
            }
        )
    }

    private var captionsBinding: Binding<Bool> {
        Binding(
            get: { preferencesService.areCaptionsEnabled },
            set: { newValue in
                Task {
                    await updateCaptions(newValue)
                }
            }
        )
    }

    private var speedBinding: Binding<Double> {
        Binding(
            get: { preferencesService.currentPlaybackSpeed },
            set: { newValue in
                Task {
                    await updateSpeed(newValue)
                }
            }
        )
    }

    // MARK: - Update Methods

    private func updateQuality(_ quality: VideoQuality) async {
        isUpdating = true
        defer { isUpdating = false }

        do {
            try await preferencesService.setPreferredQuality(quality)
        } catch {
            updateError = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func updateAutoPlay(_ enabled: Bool) async {
        isUpdating = true
        defer { isUpdating = false }

        do {
            try await preferencesService.setAutoPlay(enabled)
        } catch {
            updateError = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func updateCaptions(_ enabled: Bool) async {
        isUpdating = true
        defer { isUpdating = false }

        do {
            try await preferencesService.setShowCaptions(enabled)
        } catch {
            updateError = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func updateSpeed(_ speed: Double) async {
        isUpdating = true
        defer { isUpdating = false }

        do {
            try await preferencesService.setPlaybackSpeed(speed)
        } catch {
            updateError = error.localizedDescription
            showErrorAlert = true
        }
    }

    // MARK: - Helper Methods

    private var estimatedDataUsage: String {
        guard let quality = preferencesService.preferences?.preferredQuality else {
            return "~75 MB"
        }
        return calculateDataUsage(for: quality, durationMinutes: 5)
    }

    private func calculateDataUsage(for quality: VideoQuality, durationMinutes: Int) -> String {
        // Bitrate in kbps, convert to MB for duration
        // MB = (bitrate_kbps * duration_seconds) / (8 * 1000)
        let bitrate = quality.estimatedBitrate
        let durationSeconds = durationMinutes * 60
        let megabytes = Double(bitrate * durationSeconds) / 8000.0

        if megabytes < 100 {
            return String(format: "~%.0f MB", megabytes)
        } else {
            return String(format: "~%.1f GB", megabytes / 1000)
        }
    }

    private func qualityIcon(for quality: VideoQuality) -> String {
        switch quality {
        case .auto: return "wand.and.stars"
        case .sd: return "video"
        case .hd: return "video.fill"
        case .fhd: return "4k.tv.fill"
        }
    }

    private func formatSpeed(_ speed: Double) -> String {
        if speed == 1.0 {
            return "Normal"
        }
        return String(format: "%.2gx", speed)
    }
}

// MARK: - Data Usage Row

private struct DataUsageRow: View {
    let quality: VideoQuality
    let label: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(dataUsage)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var dataUsage: String {
        // Calculate for 5 minutes
        let bitrate = quality.estimatedBitrate
        let durationSeconds = 5 * 60
        let megabytes = Double(bitrate * durationSeconds) / 8000.0
        return String(format: "~%.0f MB", megabytes)
    }
}

// MARK: - Summary Row

private struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        VideoSettingsView()
    }
}
