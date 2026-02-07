//
//  OutcomeScoreCard.swift
//  PTPerformance
//
//  Clinical Assessments - UI card for displaying outcome measure scores
//  Shows score gauge, MCID indicator, change from baseline, and severity interpretation
//

import SwiftUI

/// Card component for displaying outcome measure scores with visual indicators
struct OutcomeScoreCard: View {
    // MARK: - Properties

    let outcomeMeasure: OutcomeMeasure
    var showDetails: Bool = true
    var onTap: (() -> Void)?

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Header with measure type
                headerSection

                Divider()
                    .padding(.horizontal)

                // Main content
                VStack(spacing: 16) {
                    // Score gauge and change indicator
                    HStack(alignment: .center, spacing: 24) {
                        scoreGauge
                        changeFromBaselineSection
                    }
                    .padding(.top, 8)

                    if showDetails {
                        Divider()

                        // Severity and MCID indicators
                        HStack(spacing: 16) {
                            severityIndicator
                            Spacer()
                            mcidIndicator
                        }
                    }
                }
                .padding()
            }
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(outcomeMeasure.measureType.displayName) score: \(outcomeMeasure.formattedScore)")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 12) {
            // Measure type icon
            ZStack {
                Circle()
                    .fill(outcomeMeasure.measureType.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: measureIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(outcomeMeasure.measureType.color)
            }

            // Title and date
            VStack(alignment: .leading, spacing: 2) {
                Text(outcomeMeasure.measureType.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(outcomeMeasure.measureType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Date badge
            VStack(alignment: .trailing, spacing: 2) {
                Text(outcomeMeasure.formattedDate)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)

                // Progress status badge
                HStack(spacing: 4) {
                    Image(systemName: outcomeMeasure.progressStatus.iconName)
                        .font(.system(size: 10))
                    Text(outcomeMeasure.progressStatus.displayName)
                        .font(.caption2.weight(.medium))
                }
                .foregroundColor(outcomeMeasure.statusColor)
            }
        }
        .padding()
    }

    // MARK: - Score Gauge

    private var scoreGauge: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color(.tertiarySystemFill), lineWidth: 10)
                .frame(width: 100, height: 100)

            // Progress ring
            Circle()
                .trim(from: 0, to: scoreProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [scoreColor.opacity(0.5), scoreColor]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * scoreProgress)
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))

            // Score display
            VStack(spacing: 2) {
                Text(outcomeMeasure.formattedScore)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(scoreColor)

                Text("/ \(outcomeMeasure.measureType.maxScore)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityLabel("Score \(outcomeMeasure.formattedScore) out of \(outcomeMeasure.measureType.maxScore)")
    }

    // MARK: - Change From Baseline Section

    private var changeFromBaselineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Change value
            if let change = outcomeMeasure.changeFromPrevious {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Change from Previous")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        Image(systemName: changeIcon(for: change))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(changeColor(for: change))

                        Text(formatChange(change))
                            .font(.title2.weight(.bold))
                            .foregroundColor(changeColor(for: change))
                    }

                    // Interpretation
                    Text(changeInterpretation(for: change))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Baseline Score")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("First Assessment")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)

                    Text("Future assessments will show change")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Previous score reference
            if let previousScore = outcomeMeasure.previousScore {
                HStack(spacing: 4) {
                    Text("Previous:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(String(format: "%.1f", previousScore))
                        .font(.caption.weight(.medium))
                        .foregroundColor(.primary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Severity Indicator

    private var severityIndicator: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Severity")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                // Severity color bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(outcomeMeasure.severityLevel.color)
                    .frame(width: 4, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(outcomeMeasure.severityLevel.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)

                    // Severity bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(.tertiarySystemFill))
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(severityGradient)
                                .frame(width: geometry.size.width * severityProgress, height: 4)
                        }
                    }
                    .frame(height: 4)
                    .frame(maxWidth: 100)
                }
            }
        }
    }

    // MARK: - MCID Indicator

    private var mcidIndicator: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text("MCID Status")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 6) {
                if outcomeMeasure.meetsMcid == true {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("Achieved")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.green)
                } else if outcomeMeasure.changeFromPrevious != nil {
                    Image(systemName: "arrow.right.circle")
                        .foregroundColor(.orange)
                    Text("In Progress")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.orange)
                } else {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.secondary)
                    Text("Baseline")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                }
            }

            // MCID threshold info
            Text("Threshold: \(String(format: "%.1f", outcomeMeasure.measureType.mcidThreshold)) pts")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helper Views

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(outcomeMeasure.measureType.color.opacity(0.2), lineWidth: 1)
            )
    }

    private var severityGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Computed Properties

    private var measureIcon: String {
        switch outcomeMeasure.measureType.bodyRegion {
        case "Lower Extremity":
            return "figure.walk"
        case "Upper Extremity":
            return "hand.raised"
        case "Cervical Spine":
            return "person.bust"
        case "Lumbar Spine":
            return "figure.stand"
        default:
            return "chart.bar"
        }
    }

    private var scoreProgress: Double {
        guard let score = outcomeMeasure.normalizedScore ?? outcomeMeasure.rawScore else { return 0 }
        let maxScore = Double(outcomeMeasure.measureType.maxScore)
        return min(1.0, max(0, score / maxScore))
    }

    private var scoreColor: Color {
        let severity = outcomeMeasure.severityLevel
        return severity.color
    }

    private var severityProgress: Double {
        switch outcomeMeasure.severityLevel {
        case .minimal: return 0.2
        case .mild: return 0.4
        case .moderate: return 0.6
        case .severe: return 0.8
        case .complete: return 1.0
        case .unknown: return 0.0
        }
    }

    // MARK: - Helper Methods

    private func changeIcon(for change: Double) -> String {
        let isPositive = outcomeMeasure.measureType.higherIsBetter ? change > 0 : change < 0
        if abs(change) < 1 {
            return "minus"
        }
        return isPositive ? "arrow.up.right" : "arrow.down.right"
    }

    private func changeColor(for change: Double) -> Color {
        if outcomeMeasure.showsImprovement {
            return .green
        } else if outcomeMeasure.showsDecline {
            return .red
        }
        return .secondary
    }

    private func formatChange(_ change: Double) -> String {
        let prefix = change > 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.1f", change))"
    }

    private func changeInterpretation(for change: Double) -> String {
        let mcid = outcomeMeasure.measureType.mcidThreshold

        if outcomeMeasure.showsImprovement {
            return "Clinically meaningful improvement"
        } else if outcomeMeasure.showsDecline {
            return "Clinically meaningful decline"
        } else if abs(change) > 0 {
            let remaining = mcid - abs(change)
            return "Need \(String(format: "%.1f", remaining)) more pts for MCID"
        }
        return "No significant change"
    }
}

// MARK: - Compact Outcome Score Card

/// Compact version for list displays
struct OutcomeScoreCardCompact: View {
    let outcomeMeasure: OutcomeMeasure
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                // Score circle
                ZStack {
                    Circle()
                        .stroke(Color(.tertiarySystemFill), lineWidth: 3)
                        .frame(width: 44, height: 44)

                    Circle()
                        .trim(from: 0, to: scoreProgress)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))

                    Text(outcomeMeasure.formattedScore)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor)
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(outcomeMeasure.measureType.rawValue)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)

                    HStack(spacing: 4) {
                        Text(outcomeMeasure.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let change = outcomeMeasure.changeFromPrevious {
                            Text("•")
                                .foregroundColor(.secondary)
                            Image(systemName: outcomeMeasure.progressStatus.iconName)
                                .font(.system(size: 10))
                                .foregroundColor(outcomeMeasure.statusColor)
                            Text(formatChange(change))
                                .font(.caption.weight(.medium))
                                .foregroundColor(outcomeMeasure.statusColor)
                        }
                    }
                }

                Spacer()

                // MCID indicator
                if outcomeMeasure.meetsMcid == true {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 16))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }

    private var scoreProgress: Double {
        guard let score = outcomeMeasure.normalizedScore ?? outcomeMeasure.rawScore else { return 0 }
        let maxScore = Double(outcomeMeasure.measureType.maxScore)
        return min(1.0, max(0, score / maxScore))
    }

    private var scoreColor: Color {
        outcomeMeasure.severityLevel.color
    }

    private func formatChange(_ change: Double) -> String {
        let prefix = change > 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.0f", change))"
    }
}

// MARK: - Mini Score Badge

/// Minimal score badge for inline display
struct OutcomeScoreBadge: View {
    let measureType: OutcomeMeasureType
    let score: Double
    let meetsMcid: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(measureType.rawValue)
                .font(.caption.weight(.medium))
                .foregroundColor(.primary)

            Text(String(format: "%.0f", score))
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(badgeColor)
                .clipShape(Capsule())

            if meetsMcid {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.tertiarySystemBackground))
        )
    }

    private var badgeColor: Color {
        measureType.color
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Full Card") {
    ScrollView {
        VStack(spacing: 20) {
            OutcomeScoreCard(
                outcomeMeasure: OutcomeMeasure.sample,
                onTap: { print("Tapped LEFS") }
            )

            OutcomeScoreCard(
                outcomeMeasure: OutcomeMeasure.dashSample
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Compact Cards") {
    VStack(spacing: 12) {
        OutcomeScoreCardCompact(
            outcomeMeasure: OutcomeMeasure.sample,
            onTap: { print("Tapped") }
        )

        OutcomeScoreCardCompact(
            outcomeMeasure: OutcomeMeasure.dashSample
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Score Badges") {
    HStack(spacing: 8) {
        OutcomeScoreBadge(measureType: .LEFS, score: 68, meetsMcid: true)
        OutcomeScoreBadge(measureType: .DASH, score: 35, meetsMcid: false)
        OutcomeScoreBadge(measureType: .NPRS, score: 4, meetsMcid: false)
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(spacing: 20) {
        OutcomeScoreCard(
            outcomeMeasure: OutcomeMeasure.sample
        )

        OutcomeScoreCardCompact(
            outcomeMeasure: OutcomeMeasure.sample
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
#endif
