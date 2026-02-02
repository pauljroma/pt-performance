//
//  SlowMotionControlView.swift
//  PTPerformance
//
//  ACP-813: HD Video Exercise Demos - Slow motion playback controls
//  Features: 0.25x, 0.5x, 0.75x, 1x, 1.25x, 1.5x, 2x playback speeds
//

import SwiftUI

/// View for selecting video playback speed with slow-motion options
struct SlowMotionControlView: View {
    let currentSpeed: PlaybackSpeed
    let supportsSlowMotion: Bool
    let onSelect: (PlaybackSpeed) -> Void

    @Namespace private var animation

    // Available speeds based on slow-motion support
    private var availableSpeeds: [PlaybackSpeed] {
        if supportsSlowMotion {
            return PlaybackSpeed.allSpeeds
        } else {
            // Only normal and faster speeds if slow-motion not supported
            return PlaybackSpeed.allSpeeds.filter { !$0.isSlowMotion }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Slow motion indicator
            if supportsSlowMotion && currentSpeed.isSlowMotion {
                slowMotionBadge
            }

            // Speed selector grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(availableSpeeds) { speed in
                    speedButton(for: speed)
                }
            }

            // Speed description
            speedDescription
        }
    }

    // MARK: - Slow Motion Badge

    private var slowMotionBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "figure.run")
            Text("Slow Motion Active")
                .font(.caption)
                .fontWeight(.medium)
            Text("-")
            Text("Perfect for form review")
                .font(.caption)
        }
        .foregroundColor(.blue)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.15))
        .cornerRadius(8)
    }

    // MARK: - Speed Button

    private func speedButton(for speed: PlaybackSpeed) -> some View {
        let isSelected = speed == currentSpeed

        return Button {
            onSelect(speed)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.blue : Color.white.opacity(0.1))
                        .frame(height: 48)

                    // Speed value
                    Text(speed.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                }

                // Speed indicator icon
                if speed.isSlowMotion {
                    HStack(spacing: 2) {
                        Image(systemName: "tortoise.fill")
                            .font(.caption2)
                        if speed == .quarter {
                            Text("Ultra slow")
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.5))
                } else if speed == .normal {
                    Text("Normal")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .blue : .white.opacity(0.5))
                } else {
                    HStack(spacing: 2) {
                        Image(systemName: "hare.fill")
                            .font(.caption2)
                    }
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Speed Description

    private var speedDescription: some View {
        HStack(spacing: 8) {
            Image(systemName: speedDescriptionIcon)
                .foregroundColor(speedDescriptionColor)

            Text(speedDescriptionText)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal)
    }

    private var speedDescriptionIcon: String {
        switch currentSpeed {
        case .quarter:
            return "magnifyingglass"
        case .half:
            return "eye.fill"
        case .threeQuarter:
            return "figure.walk"
        case .normal:
            return "play.fill"
        case .oneAndQuarter, .oneAndHalf:
            return "forward.fill"
        case .double:
            return "forward.end.fill"
        }
    }

    private var speedDescriptionText: String {
        switch currentSpeed {
        case .quarter:
            return "Ultra slow - Analyze every detail of the movement"
        case .half:
            return "Half speed - Great for learning proper form"
        case .threeQuarter:
            return "Slightly slower - Follow along while learning"
        case .normal:
            return "Normal speed - Watch at real-time pace"
        case .oneAndQuarter:
            return "Slightly faster - Quick review"
        case .oneAndHalf:
            return "Fast - Efficient review when familiar"
        case .double:
            return "Double speed - Rapid overview"
        }
    }

    private var speedDescriptionColor: Color {
        if currentSpeed.isSlowMotion {
            return .blue
        } else if currentSpeed == .normal {
            return .green
        } else {
            return .orange
        }
    }
}

// MARK: - Compact Speed Control

/// Compact inline speed control for video player overlay
struct CompactSpeedControlView: View {
    @Binding var currentSpeed: PlaybackSpeed
    let supportsSlowMotion: Bool

    var body: some View {
        Menu {
            ForEach(availableSpeeds) { speed in
                Button {
                    currentSpeed = speed
                } label: {
                    HStack {
                        Text(speed.displayName)
                        if speed == currentSpeed {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "gauge.with.dots.needle.50percent")
                Text(currentSpeed.displayName)
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(currentSpeed.isSlowMotion ? .blue : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
        }
    }

    private var availableSpeeds: [PlaybackSpeed] {
        if supportsSlowMotion {
            return PlaybackSpeed.allSpeeds
        } else {
            return PlaybackSpeed.allSpeeds.filter { !$0.isSlowMotion }
        }
    }
}

// MARK: - Speed Slider

/// Continuous speed slider for fine-grained control
struct SpeedSliderView: View {
    @Binding var speed: Float
    let range: ClosedRange<Float>
    let supportsSlowMotion: Bool

    init(speed: Binding<Float>, supportsSlowMotion: Bool = true) {
        self._speed = speed
        self.supportsSlowMotion = supportsSlowMotion
        self.range = supportsSlowMotion ? 0.25...2.0 : 1.0...2.0
    }

    var body: some View {
        VStack(spacing: 8) {
            // Speed display
            HStack {
                Text("Playback Speed")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                Text(String(format: "%.2fx", speed))
                    .font(.headline)
                    .foregroundColor(speedColor)
                    .monospacedDigit()
            }

            // Slider
            HStack(spacing: 12) {
                Image(systemName: "tortoise.fill")
                    .foregroundColor(.white.opacity(0.5))

                Slider(value: $speed, in: range, step: 0.05)
                    .tint(speedColor)

                Image(systemName: "hare.fill")
                    .foregroundColor(.white.opacity(0.5))
            }

            // Preset buttons
            HStack(spacing: 8) {
                ForEach(presetSpeeds, id: \.self) { preset in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            speed = preset
                        }
                    } label: {
                        Text(String(format: "%.1fx", preset))
                            .font(.caption)
                            .fontWeight(speed == preset ? .bold : .regular)
                            .foregroundColor(speed == preset ? .white : .white.opacity(0.6))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(speed == preset ? speedColor.opacity(0.3) : Color.clear)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }

    private var speedColor: Color {
        if speed < 1.0 {
            return .blue
        } else if speed == 1.0 {
            return .green
        } else {
            return .orange
        }
    }

    private var presetSpeeds: [Float] {
        if supportsSlowMotion {
            return [0.25, 0.5, 1.0, 1.5, 2.0]
        } else {
            return [1.0, 1.25, 1.5, 2.0]
        }
    }
}

// MARK: - Preview

#Preview("Full Control") {
    ZStack {
        Color.black
        SlowMotionControlView(
            currentSpeed: .half,
            supportsSlowMotion: true,
            onSelect: { _ in }
        )
        .padding()
    }
}

#Preview("Compact Control") {
    ZStack {
        Color.black
        CompactSpeedControlView(
            currentSpeed: .constant(.normal),
            supportsSlowMotion: true
        )
        .padding()
    }
}

#Preview("Speed Slider") {
    ZStack {
        Color.black
        SpeedSliderView(
            speed: .constant(0.75),
            supportsSlowMotion: true
        )
        .padding()
    }
}
