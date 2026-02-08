//
//  ConfidenceBadge.swift
//  PTPerformance
//
//  X2Index Phase 2 - M6: AI Provenance and Evidence Linking
//  Visual confidence indicator showing AI claim reliability
//
//  Confidence Levels:
//  - Green checkmark: >= 0.85 (High confidence)
//  - Yellow warning: 0.5-0.85 (Moderate confidence)
//  - Red caution: < 0.5 (Low confidence)
//

import SwiftUI

// MARK: - Confidence Level

/// Confidence level categories with associated styling
enum ConfidenceLevel: String, CaseIterable {
    case high
    case moderate
    case low
    case insufficient

    /// Initialize from a confidence score
    init(score: Double) {
        switch score {
        case 0.85...1.0: self = .high
        case 0.5..<0.85: self = .moderate
        case 0.3..<0.5: self = .low
        default: self = .insufficient
        }
    }

    /// Display name for the confidence level
    var displayName: String {
        switch self {
        case .high: return "High Confidence"
        case .moderate: return "Moderate Confidence"
        case .low: return "Low Confidence"
        case .insufficient: return "Insufficient Data"
        }
    }

    /// Short display name
    var shortName: String {
        switch self {
        case .high: return "High"
        case .moderate: return "Moderate"
        case .low: return "Low"
        case .insufficient: return "Insufficient"
        }
    }

    /// SF Symbol name for the icon
    var icon: String {
        switch self {
        case .high: return "checkmark.circle.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .low: return "exclamationmark.circle.fill"
        case .insufficient: return "questionmark.circle.fill"
        }
    }

    /// Color for the confidence level
    var color: Color {
        switch self {
        case .high: return .modusTealAccent
        case .moderate: return .yellow
        case .low: return .orange
        case .insufficient: return .red
        }
    }

    /// Background color (lighter version)
    var backgroundColor: Color {
        color.opacity(0.15)
    }

    /// Tooltip explanation
    var tooltip: String {
        switch self {
        case .high:
            return "This claim is strongly supported by multiple recent data sources"
        case .moderate:
            return "This claim is supported by available data, but some uncertainty exists"
        case .low:
            return "Limited data supports this claim. Consider collecting more data"
        case .insufficient:
            return "Not enough data to reliably support this claim"
        }
    }
}

// MARK: - Confidence Badge

/// Visual badge showing AI claim confidence level
struct ConfidenceBadge: View {
    let confidence: Double
    var size: BadgeSize = .medium
    var showLabel: Bool = true
    var showTooltip: Bool = false

    @State private var isShowingTooltip = false

    private var level: ConfidenceLevel {
        ConfidenceLevel(score: confidence)
    }

    var body: some View {
        Button {
            if showTooltip {
                withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                    isShowingTooltip.toggle()
                }
                HapticFeedback.light()
            }
        } label: {
            badgeContent
        }
        .buttonStyle(.plain)
        .disabled(!showTooltip)
        .popover(isPresented: $isShowingTooltip) {
            tooltipContent
                .presentationCompactAdaptation(.popover)
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(showTooltip ? "Tap to learn more about confidence level" : "")
    }

    // MARK: - Badge Content

    @ViewBuilder
    private var badgeContent: some View {
        HStack(spacing: size.spacing) {
            // Icon
            Image(systemName: level.icon)
                .font(size.iconFont)
                .foregroundColor(level.color)

            // Optional label
            if showLabel {
                Text(level.shortName)
                    .font(size.labelFont)
                    .fontWeight(.medium)
                    .foregroundColor(level.color)
            }
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(level.backgroundColor)
        .cornerRadius(size.cornerRadius)
    }

    // MARK: - Tooltip Content

    @ViewBuilder
    private var tooltipContent: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header
            HStack(spacing: Spacing.xs) {
                Image(systemName: level.icon)
                    .font(.title3)
                    .foregroundColor(level.color)

                Text(level.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            // Score
            HStack {
                Text("Confidence Score:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(confidence * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(level.color)
            }

            Divider()

            // Explanation
            Text(level.tooltip)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Confidence bar
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.tertiarySystemGroupedBackground))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(level.color)
                            .frame(width: geometry.size.width * confidence, height: 6)
                    }
                }
                .frame(height: 6)

                // Scale labels
                HStack {
                    Text("0%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("100%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(width: 280)
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        "\(level.displayName): \(Int(confidence * 100)) percent confidence"
    }
}

// MARK: - Badge Size

extension ConfidenceBadge {
    enum BadgeSize {
        case small
        case medium
        case large

        var iconFont: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .body
            }
        }

        var labelFont: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }

        var spacing: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 4
            case .large: return 6
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 12
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small: return 3
            case .medium: return 4
            case .large: return 6
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: return CornerRadius.xs
            case .medium: return CornerRadius.sm
            case .large: return CornerRadius.md
            }
        }
    }
}

// MARK: - Confidence Score Badge

/// Badge showing just the percentage score
struct ConfidenceScoreBadge: View {
    let confidence: Double
    var size: ConfidenceBadge.BadgeSize = .medium

    private var level: ConfidenceLevel {
        ConfidenceLevel(score: confidence)
    }

    var body: some View {
        Text("\(Int(confidence * 100))%")
            .font(size.labelFont)
            .fontWeight(.semibold)
            .foregroundColor(level.color)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(level.backgroundColor)
            .cornerRadius(size.cornerRadius)
            .accessibilityLabel("\(Int(confidence * 100)) percent confidence")
    }
}

// MARK: - Confidence Bar

/// Horizontal bar showing confidence level
struct ConfidenceBar: View {
    let confidence: Double
    var height: CGFloat = 4
    var showLabel: Bool = false

    private var level: ConfidenceLevel {
        ConfidenceLevel(score: confidence)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color(.tertiarySystemGroupedBackground))
                        .frame(height: height)

                    // Fill
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(level.color)
                        .frame(width: geometry.size.width * confidence, height: height)
                }
            }
            .frame(height: height)

            if showLabel {
                HStack {
                    Text(level.shortName)
                        .font(.caption2)
                        .foregroundColor(level.color)
                    Spacer()
                    Text("\(Int(confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .accessibilityLabel("Confidence: \(Int(confidence * 100)) percent, \(level.displayName)")
    }
}

// MARK: - Abstention Badge

/// Badge indicating AI abstained from making a claim
struct AbstentionBadge: View {
    let reason: String
    var isCompact: Bool = false

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "hand.raised.fill")
                .font(isCompact ? .caption : .body)
                .foregroundColor(.secondary)

            if !isCompact {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Abstained")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(reason)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            } else {
                Text("Abstained")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, isCompact ? 8 : Spacing.sm)
        .padding(.vertical, isCompact ? 4 : Spacing.xs)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
        .accessibilityLabel("AI abstained from this claim: \(reason)")
    }
}

// MARK: - Uncertainty Indicator

/// Indicator for claims with uncertainty flag
struct UncertaintyIndicator: View {
    var tooltip: String = "This claim has some uncertainty"
    var isCompact: Bool = false

    @State private var isShowingTooltip = false

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                isShowingTooltip.toggle()
            }
            HapticFeedback.light()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "questionmark.circle.fill")
                    .font(isCompact ? .caption2 : .caption)
                    .foregroundColor(.orange)

                if !isCompact {
                    Text("Uncertain")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, isCompact ? 4 : 8)
            .padding(.vertical, isCompact ? 2 : 4)
            .background(Color.orange.opacity(0.15))
            .cornerRadius(CornerRadius.xs)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isShowingTooltip) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.orange)

                    Text("Uncertainty Flagged")
                        .font(.headline)
                }

                Text(tooltip)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(width: 260)
            .presentationCompactAdaptation(.popover)
        }
        .accessibilityLabel("Uncertainty flagged")
        .accessibilityHint("Tap to learn more")
    }
}

// MARK: - Preview

#if DEBUG
struct ConfidenceBadge_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                Text("Confidence Badges")
                    .font(.headline)

                // High confidence
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("High (>= 85%)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: Spacing.md) {
                        ConfidenceBadge(confidence: 0.92, size: .small)
                        ConfidenceBadge(confidence: 0.92, size: .medium)
                        ConfidenceBadge(confidence: 0.92, size: .large, showTooltip: true)
                    }
                }

                // Moderate confidence
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Moderate (50-85%)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: Spacing.md) {
                        ConfidenceBadge(confidence: 0.72, size: .small)
                        ConfidenceBadge(confidence: 0.72, size: .medium)
                        ConfidenceBadge(confidence: 0.72, size: .large, showTooltip: true)
                    }
                }

                // Low confidence
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Low (30-50%)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: Spacing.md) {
                        ConfidenceBadge(confidence: 0.42, size: .small)
                        ConfidenceBadge(confidence: 0.42, size: .medium)
                        ConfidenceBadge(confidence: 0.42, size: .large, showTooltip: true)
                    }
                }

                // Insufficient
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Insufficient (< 30%)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: Spacing.md) {
                        ConfidenceBadge(confidence: 0.22, size: .small)
                        ConfidenceBadge(confidence: 0.22, size: .medium)
                        ConfidenceBadge(confidence: 0.22, size: .large, showTooltip: true)
                    }
                }

                Divider()

                Text("Score Badges")
                    .font(.headline)

                HStack(spacing: Spacing.md) {
                    ConfidenceScoreBadge(confidence: 0.95)
                    ConfidenceScoreBadge(confidence: 0.72)
                    ConfidenceScoreBadge(confidence: 0.45)
                    ConfidenceScoreBadge(confidence: 0.22)
                }

                Divider()

                Text("Confidence Bars")
                    .font(.headline)

                VStack(spacing: Spacing.md) {
                    ConfidenceBar(confidence: 0.92, showLabel: true)
                    ConfidenceBar(confidence: 0.72, showLabel: true)
                    ConfidenceBar(confidence: 0.42, showLabel: true)
                }

                Divider()

                Text("Special States")
                    .font(.headline)

                VStack(spacing: Spacing.md) {
                    AbstentionBadge(reason: "Insufficient data to make this claim")
                    AbstentionBadge(reason: "Not enough data", isCompact: true)
                    UncertaintyIndicator()
                    UncertaintyIndicator(isCompact: true)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
