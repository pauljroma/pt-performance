//
//  PerformanceModeStatusCard.swift
//  PTPerformance
//
//  Status card for Performance Mode displaying ACWR, readiness, and training recommendations
//  ACP-MODE: Mode-specific status card for performance-focused athletes
//

import SwiftUI

/// Status card component displaying performance mode metrics
/// Shows ACWR (Acute:Chronic Workload Ratio), readiness score, and training recommendations
struct PerformanceModeStatusCard: View {
    // MARK: - Properties

    var statusData: PerformanceStatusData = .empty
    var onTapCard: (() -> Void)? = nil
    var onCheckIn: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            headerSection

            // Content based on state
            if statusData.hasData {
                performanceMetricsSection
            } else {
                noDataPrompt
            }

            // Training recommendation (if available)
            if !statusData.trainingRecommendation.isEmpty {
                trainingRecommendationBanner
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Computed Properties

    private var acwrStatus: ACWRStatus {
        ACWRStatus.status(for: statusData.acwrValue)
    }

    private var acwrColor: Color {
        acwrStatus.color
    }

    private var readinessColor: Color {
        ReadinessColor.color(for: statusData.readinessScore)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        Button(action: {
            HapticFeedback.light()
            onTapCard?()
        }) {
            HStack {
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .font(.title2)
                    .foregroundColor(.modusCyan)
                    .accessibilityHidden(true)

                Text("Performance Status")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                // Last updated indicator
                if let lastUpdated = statusData.lastUpdated {
                    Text(timeAgoText(from: lastUpdated))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if onTapCard != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Performance status")
        .accessibilityHint(onTapCard != nil ? "Tap to view performance dashboard" : "")
    }

    // MARK: - Performance Metrics Section

    private var performanceMetricsSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                // ACWR gauge
                acwrGauge

                // Readiness score
                readinessIndicator

                Spacer()
            }

            // ACWR status indicator
            acwrStatusIndicator
        }
    }

    // MARK: - ACWR Gauge

    private var acwrGauge: some View {
        VStack(spacing: 4) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    .frame(width: 64, height: 64)

                // Progress ring
                Circle()
                    .trim(from: 0, to: acwrProgressValue)
                    .stroke(acwrColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))

                // Value text
                VStack(spacing: 0) {
                    Text(statusData.formattedACWR)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(acwrColor)
                        .monospacedDigit()

                    Text("ACWR")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("ACWR \(statusData.formattedACWR), status: \(acwrStatus.rawValue)")
    }

    private var acwrProgressValue: CGFloat {
        // Map ACWR 0-2 to progress 0-1
        min(1.0, max(0, statusData.acwrValue / 2.0))
    }

    // MARK: - Readiness Indicator

    private var readinessIndicator: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Readiness")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(statusData.formattedReadiness)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(readinessColor)
                    .monospacedDigit()

                Text("%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(readinessColor)
                        .frame(width: geometry.size.width * (statusData.readinessScore / 100), height: 4)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: 100)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Readiness \(statusData.formattedReadiness) percent")
    }

    // MARK: - ACWR Status Indicator

    private var acwrStatusIndicator: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: acwrStatusIcon)
                .font(.subheadline)
                .foregroundColor(acwrColor)

            Text(acwrStatus.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(acwrColor)

            Text("-")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(acwrStatusDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)

            Spacer()
        }
        .padding(Spacing.sm)
        .background(acwrColor.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
    }

    private var acwrStatusIcon: String {
        acwrStatus.icon
    }

    private var acwrStatusDescription: String {
        acwrStatus.recommendation
    }

    // MARK: - Training Recommendation Banner

    private var trainingRecommendationBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "lightbulb.fill")
                .font(.subheadline)
                .foregroundColor(.yellow)

            Text(statusData.trainingRecommendation)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(Spacing.sm)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
        .accessibilityLabel("Training recommendation: \(statusData.trainingRecommendation)")
    }

    // MARK: - No Data Prompt

    private var noDataPrompt: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Image(systemName: "waveform.path.ecg.rectangle")
                    .font(.title3)
                    .foregroundColor(.modusCyan)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Track your performance")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Complete check-ins to see your metrics")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            if let onCheckIn = onCheckIn {
                Button(action: {
                    HapticFeedback.light()
                    onCheckIn()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Check In Now")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.modusCyan)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.sm)
                }
                .accessibilityLabel("Check in now")
                .accessibilityHint("Opens daily check-in form")
            }
        }
    }

    // MARK: - Helpers

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    private func timeAgoText(from date: Date) -> String {
        Self.relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#if DEBUG
struct PerformanceModeStatusCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                // Optimal status
                PerformanceModeStatusCard(
                    statusData: PerformanceStatusData(
                        acwrValue: 1.1,
                        readinessScore: 85,
                        trainingRecommendation: "Training load is well balanced",
                        lastUpdated: Date()
                    ),
                    onTapCard: {},
                    onCheckIn: {}
                )

                // Caution status
                PerformanceModeStatusCard(
                    statusData: PerformanceStatusData(
                        acwrValue: 1.4,
                        readinessScore: 62,
                        trainingRecommendation: "Monitor fatigue levels closely",
                        lastUpdated: Date().addingTimeInterval(-3600)
                    ),
                    onTapCard: {}
                )

                // Danger status
                PerformanceModeStatusCard(
                    statusData: PerformanceStatusData(
                        acwrValue: 1.7,
                        readinessScore: 45,
                        trainingRecommendation: "Consider reducing training load",
                        lastUpdated: Date()
                    ),
                    onTapCard: {}
                )

                // No data
                PerformanceModeStatusCard(
                    onTapCard: {},
                    onCheckIn: {}
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
