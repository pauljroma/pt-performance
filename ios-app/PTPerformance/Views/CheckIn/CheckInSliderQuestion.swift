//
//  CheckInSliderQuestion.swift
//  PTPerformance
//
//  X2Index M8: Reusable Slider Question Component
//  Large touch targets with emoji scale and haptic feedback
//

import SwiftUI

// MARK: - Check-In Slider Question

/// Reusable slider question component for check-in flow
///
/// Features:
/// - Large touch targets for quick input
/// - Emoji scale visualization (sad -> happy or low -> high)
/// - Haptic feedback on selection
/// - Large, prominent current value display
/// - Accessibility support
struct CheckInSliderQuestion: View {

    // MARK: - Properties

    let title: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    let minValue: Int
    let maxValue: Int
    @Binding var value: Int
    let minLabel: String
    let maxLabel: String
    let minEmoji: String
    let maxEmoji: String
    let isInverted: Bool // For scales where lower is better (like soreness)
    let onValueChanged: ((Int) -> Void)?

    // MARK: - Computed Properties

    /// Color based on value (respects inversion)
    private var valueColor: Color {
        let progress = Double(value - minValue) / Double(maxValue - minValue)
        let effectiveProgress = isInverted ? (1 - progress) : progress

        if effectiveProgress >= 0.8 {
            return .green
        } else if effectiveProgress >= 0.6 {
            return .yellow
        } else if effectiveProgress >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }

    /// Emoji for current value
    private var currentEmoji: String {
        let progress = Double(value - minValue) / Double(maxValue - minValue)
        let effectiveProgress = isInverted ? (1 - progress) : progress

        if effectiveProgress >= 0.8 {
            return isInverted ? minEmoji : maxEmoji
        } else if effectiveProgress >= 0.6 {
            return "😊"
        } else if effectiveProgress >= 0.4 {
            return "😐"
        } else if effectiveProgress >= 0.2 {
            return "😕"
        } else {
            return isInverted ? maxEmoji : minEmoji
        }
    }

    // MARK: - Initialization

    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        iconColor: Color,
        minValue: Int = 1,
        maxValue: Int = 10,
        value: Binding<Int>,
        minLabel: String = "Low",
        maxLabel: String = "High",
        minEmoji: String = "😴",
        maxEmoji: String = "⚡️",
        isInverted: Bool = false,
        onValueChanged: ((Int) -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.minValue = minValue
        self.maxValue = maxValue
        self._value = value
        self.minLabel = minLabel
        self.maxLabel = maxLabel
        self.minEmoji = minEmoji
        self.maxEmoji = maxEmoji
        self.isInverted = isInverted
        self.onValueChanged = onValueChanged
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            // Header
            headerSection

            // Large value display
            valueDisplaySection

            // Slider with markers
            sliderSection

            // Quick select buttons
            quickSelectSection
        }
        .padding(.horizontal)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var valueDisplaySection: some View {
        VStack(spacing: 8) {
            // Large emoji
            Text(currentEmoji)
                .font(.system(size: 60))
                .animation(.easeInOut(duration: 0.2), value: value)

            // Large number
            Text("\(value)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(valueColor)
                .animation(.easeInOut(duration: 0.2), value: value)

            // Scale reference
            Text("out of \(maxValue)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var sliderSection: some View {
        VStack(spacing: 8) {
            // Value bar indicators
            HStack(spacing: 4) {
                ForEach(minValue...maxValue, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(i <= value ? valueColor : Color.gray.opacity(0.3))
                        .frame(height: 32)
                        .onTapGesture {
                            updateValue(i)
                        }
                }
            }
            .accessibilityHidden(true)

            // Slider
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { newValue in
                        let intValue = Int(newValue.rounded())
                        if intValue != value {
                            updateValue(intValue)
                        }
                    }
                ),
                in: Double(minValue)...Double(maxValue),
                step: 1
            ) {
                Text(title)
            } minimumValueLabel: {
                VStack {
                    Text(minEmoji)
                    Text(minLabel)
                        .font(.caption2)
                }
            } maximumValueLabel: {
                VStack {
                    Text(maxEmoji)
                    Text(maxLabel)
                        .font(.caption2)
                }
            }
            .tint(valueColor)
            .accessibilityLabel(title)
            .accessibilityValue("\(value) out of \(maxValue)")
            .accessibilityHint("Slide to adjust \(title.lowercased())")
        }
    }

    private var quickSelectSection: some View {
        HStack(spacing: 12) {
            ForEach(quickSelectValues, id: \.self) { quickValue in
                Button {
                    updateValue(quickValue)
                } label: {
                    Text("\(quickValue)")
                        .font(.headline)
                        .fontWeight(value == quickValue ? .bold : .regular)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(value == quickValue ? valueColor : Color.gray.opacity(0.2))
                        )
                        .foregroundColor(value == quickValue ? .white : .primary)
                }
                .accessibilityLabel("Set to \(quickValue)")
            }
        }
    }

    // MARK: - Quick Select Values

    private var quickSelectValues: [Int] {
        let range = maxValue - minValue
        if range <= 4 {
            return Array(minValue...maxValue)
        } else if range <= 9 {
            // For 1-10 scale, show 1, 3, 5, 7, 10 or similar
            let mid = (minValue + maxValue) / 2
            return [minValue, (minValue + mid) / 2, mid, (mid + maxValue) / 2, maxValue]
        } else {
            // For larger ranges, show 5 evenly spaced values
            let step = range / 4
            return [
                minValue,
                minValue + step,
                minValue + step * 2,
                minValue + step * 3,
                maxValue
            ]
        }
    }

    // MARK: - Actions

    private func updateValue(_ newValue: Int) {
        let clamped = max(minValue, min(maxValue, newValue))
        if clamped != value {
            value = clamped
            HapticService.selection()
            onValueChanged?(clamped)
        }
    }
}

// MARK: - Compact Slider Question

/// Compact version for review screens
struct CompactSliderQuestion: View {
    let title: String
    let icon: String
    let iconColor: Color
    let value: Int
    let maxValue: Int
    let isInverted: Bool

    private var valueColor: Color {
        let progress = Double(value - 1) / Double(maxValue - 1)
        let effectiveProgress = isInverted ? (1 - progress) : progress

        if effectiveProgress >= 0.7 {
            return .green
        } else if effectiveProgress >= 0.4 {
            return .yellow
        } else {
            return .red
        }
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            // Value bar
            HStack(spacing: 2) {
                ForEach(1...maxValue, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i <= value ? valueColor : Color.gray.opacity(0.2))
                        .frame(width: 12, height: 16)
                }
            }

            Text("\(value)")
                .font(.headline.monospacedDigit())
                .foregroundColor(valueColor)
                .frame(width: 30, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#if DEBUG
struct CheckInSliderQuestion_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            CheckInSliderQuestion(
                title: "Energy Level",
                subtitle: "How energized do you feel today?",
                icon: "bolt.fill",
                iconColor: .yellow,
                minValue: 1,
                maxValue: 10,
                value: .constant(7),
                minLabel: "Exhausted",
                maxLabel: "Energized",
                minEmoji: "😴",
                maxEmoji: "⚡️"
            )

            CheckInSliderQuestion(
                title: "Soreness",
                subtitle: "Rate your muscle soreness",
                icon: "figure.walk",
                iconColor: .orange,
                minValue: 1,
                maxValue: 10,
                value: .constant(3),
                minLabel: "None",
                maxLabel: "Severe",
                minEmoji: "😊",
                maxEmoji: "😣",
                isInverted: true
            )
        }
        .padding()
        .previewDisplayName("Slider Questions")
    }
}
#endif
