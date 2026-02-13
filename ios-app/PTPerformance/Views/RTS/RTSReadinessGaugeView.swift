//
//  RTSReadinessGaugeView.swift
//  PTPerformance
//
//  Visual readiness score display for Return-to-Sport protocols
//  Shows overall score with traffic light color and component breakdowns
//

import SwiftUI

// MARK: - RTS Readiness Gauge View

/// Visual readiness score display
struct RTSReadinessGaugeView: View {
    let score: RTSReadinessScore?
    var showDetails: Bool = true

    var body: some View {
        VStack(spacing: Spacing.md) {
            if let score = score {
                // Main gauge and component gauges
                HStack(alignment: .top, spacing: Spacing.lg) {
                    // Main circular gauge
                    mainGauge(score: score)

                    if showDetails {
                        // Component scores
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            componentRow(
                                title: "Physical",
                                score: score.physicalScore,
                                icon: "figure.walk",
                                color: .blue
                            )

                            componentRow(
                                title: "Functional",
                                score: score.functionalScore,
                                icon: "figure.run",
                                color: .green
                            )

                            componentRow(
                                title: "Psychological",
                                score: score.psychologicalScore,
                                icon: "brain.head.profile",
                                color: .purple
                            )
                        }
                    }
                }

                // Risk factors list
                if showDetails && !score.riskFactors.isEmpty {
                    riskFactorsSection(riskFactors: score.riskFactors)
                }

                // Date recorded
                if showDetails {
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Recorded \(score.formattedShortDate)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                }
            } else {
                emptyState
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
    }

    // MARK: - Main Gauge

    private func mainGauge(score: RTSReadinessScore) -> some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 12)
                .frame(width: 100, height: 100)

            // Score arc
            Circle()
                .trim(from: 0, to: CGFloat(score.overallScore) / 100)
                .stroke(
                    score.trafficLight.color,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: 0) {
                Text("\(Int(score.overallScore))")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(score.trafficLight.color)

                Text("Ready")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Overall readiness score: \(Int(score.overallScore)) percent, \(score.trafficLight.displayName)")
    }

    // MARK: - Component Row

    private func componentRow(title: String, score: Double, icon: String, color: Color) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(Int(score))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                // Mini progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.systemGray5))

                        RoundedRectangle(cornerRadius: 2)
                            .fill(RTSTrafficLight.from(score: score).color)
                            .frame(width: geometry.size.width * CGFloat(score / 100))
                    }
                }
                .frame(height: 4)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(Int(score)) percent")
    }

    // MARK: - Risk Factors Section

    private func riskFactorsSection(riskFactors: [RTSRiskFactor]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)

                Text("Risk Factors")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()
            }
            .accessibilityAddTraits(.isHeader)

            ForEach(riskFactors) { factor in
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: factor.severity.icon)
                        .font(.caption)
                        .foregroundColor(factor.severity.color)
                        .frame(width: 16)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(factor.name)
                                .font(.caption)
                                .fontWeight(.medium)

                            Spacer()

                            Text(factor.severity.displayName)
                                .font(.caption2)
                                .foregroundColor(factor.severity.color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(factor.severity.color.opacity(0.15))
                                .cornerRadius(CornerRadius.xs)
                        }

                        if let notes = factor.notes {
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(factor.name), \(factor.severity.displayName) risk")
            }
        }
        .padding(Spacing.sm)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "gauge.badge.questionmark")
                .font(.title)
                .foregroundColor(.secondary)

            Text("No Readiness Score")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("A readiness assessment has not been recorded yet")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Spacing.lg)
    }
}

// MARK: - Compact Gauge View

/// Compact circular gauge for inline display
struct RTSScoreGauge: View {
    let score: Double
    var size: GaugeSize = .medium
    var showLabel: Bool = true

    enum GaugeSize {
        case small, medium, large

        var diameter: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 60
            case .large: return 100
            }
        }

        var lineWidth: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 10
            }
        }

        var fontSize: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .title2
            }
        }
    }

    private var trafficLight: RTSTrafficLight {
        RTSTrafficLight.from(score: score)
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color(.systemGray5), lineWidth: size.lineWidth)
                .frame(width: size.diameter, height: size.diameter)

            // Score arc
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(
                    trafficLight.color,
                    style: StrokeStyle(lineWidth: size.lineWidth, lineCap: .round)
                )
                .frame(width: size.diameter, height: size.diameter)
                .rotationEffect(.degrees(-90))

            // Score label
            if showLabel {
                Text("\(Int(score))")
                    .font(size.fontSize)
                    .fontWeight(.bold)
                    .foregroundColor(trafficLight.color)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Score: \(Int(score)) percent, \(trafficLight.displayName)")
    }
}

// MARK: - Trend Indicator

/// Trend direction indicator for readiness scores
struct RTSReadinessTrendIndicator: View {
    let trend: RTSReadinessTrendDirection

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trend.icon)
                .font(.caption)

            Text(trend.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(trend.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(trend.color.opacity(0.15))
        .cornerRadius(CornerRadius.xs)
        .accessibilityLabel("Trend: \(trend.displayName)")
    }
}

// MARK: - Preview

#if DEBUG
struct RTSReadinessGaugeView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Green score
                RTSReadinessGaugeView(
                    score: RTSReadinessScore.greenSample,
                    showDetails: true
                )

                // Yellow score
                RTSReadinessGaugeView(
                    score: RTSReadinessScore.yellowSample,
                    showDetails: true
                )

                // Red score
                RTSReadinessGaugeView(
                    score: RTSReadinessScore.redSample,
                    showDetails: true
                )

                // Empty state
                RTSReadinessGaugeView(
                    score: nil,
                    showDetails: true
                )

                // Compact gauges
                HStack(spacing: Spacing.lg) {
                    RTSScoreGauge(score: 85, size: .small)
                    RTSScoreGauge(score: 70, size: .medium)
                    RTSScoreGauge(score: 45, size: .large)
                }

                // Trend indicators
                HStack(spacing: Spacing.md) {
                    RTSReadinessTrendIndicator(trend: .improving)
                    RTSReadinessTrendIndicator(trend: .stable)
                    RTSReadinessTrendIndicator(trend: .declining)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
