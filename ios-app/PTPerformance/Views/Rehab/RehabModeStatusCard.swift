//
//  RehabModeStatusCard.swift
//  PTPerformance
//
//  Status card for Rehab Mode displaying pain tracking, alerts, and deload status
//  ACP-MODE: Mode-specific status card for rehabilitation-focused athletes
//

import SwiftUI

/// Status card component displaying rehab mode metrics
/// Shows pain score, active alerts, deload urgency, and quick actions
struct RehabModeStatusCard: View {
    // MARK: - Properties

    var todayPainScore: Int? = nil
    var previousPainScore: Int? = nil
    var activePainRegions: [PainLocation] = []
    var hasActiveAlerts: Bool = false
    var alertCount: Int = 0
    var deloadUrgency: DeloadUrgency? = nil
    var onLogPain: (() -> Void)? = nil
    var onViewAlerts: (() -> Void)? = nil
    var onViewDashboard: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            headerSection

            // Content based on state
            if hasPainData {
                painStatusSection
            } else {
                noPainDataPrompt
            }

            // Deload urgency indicator (if applicable)
            if let urgency = deloadUrgency, urgency != .none {
                deloadUrgencyBanner(urgency: urgency)
            }

            // Alerts indicator (if any)
            if hasActiveAlerts && alertCount > 0 {
                alertsIndicator
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Computed Properties

    private var hasPainData: Bool {
        todayPainScore != nil || !activePainRegions.isEmpty
    }

    private var painTrend: PainTrend {
        guard let today = todayPainScore, let previous = previousPainScore else {
            return .unknown
        }
        if today < previous {
            return .improving
        } else if today > previous {
            return .worsening
        }
        return .stable
    }

    private var painScoreColor: Color {
        guard let score = todayPainScore else { return .secondary }
        switch score {
        case 0...3: return .green
        case 4...6: return .yellow
        case 7...8: return .orange
        default: return .red
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            Image(systemName: "heart.text.square.fill")
                .font(.title2)
                .foregroundColor(.pink)
                .accessibilityHidden(true)

            Text("Rehab Status")
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            if let onViewDashboard = onViewDashboard {
                Button(action: {
                    HapticFeedback.light()
                    onViewDashboard()
                }) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("View rehab dashboard")
            }
        }
    }

    // MARK: - Pain Status Section

    private var painStatusSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                // Pain score circle
                if let score = todayPainScore {
                    painScoreCircle(score: score)
                }

                // Pain info
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    if let score = todayPainScore {
                        HStack(spacing: Spacing.xs) {
                            Text("Pain Level: \(score)/10")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            trendIndicator
                        }
                    }

                    if !activePainRegions.isEmpty {
                        Text(painRegionsSummary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()
            }

            // Log pain button
            if let onLogPain = onLogPain {
                Button(action: {
                    HapticFeedback.light()
                    onLogPain()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Log Pain")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.pink.opacity(0.15))
                    .foregroundColor(.pink)
                    .cornerRadius(CornerRadius.sm)
                }
                .accessibilityLabel("Log pain")
                .accessibilityHint("Opens pain logging form")
            }
        }
    }

    // MARK: - Pain Score Circle

    private func painScoreCircle(score: Int) -> some View {
        ZStack {
            Circle()
                .fill(painScoreColor.opacity(0.2))
                .frame(width: 56, height: 56)

            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(painScoreColor)

                Text("/10")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pain score \(score) out of 10")
    }

    // MARK: - Trend Indicator

    @ViewBuilder
    private var trendIndicator: some View {
        switch painTrend {
        case .improving:
            HStack(spacing: 2) {
                Image(systemName: "arrow.down.right")
                    .font(.caption2)
                Text("Better")
                    .font(.caption)
            }
            .foregroundColor(.green)

        case .worsening:
            HStack(spacing: 2) {
                Image(systemName: "arrow.up.right")
                    .font(.caption2)
                Text("Worse")
                    .font(.caption)
            }
            .foregroundColor(.red)

        case .stable:
            HStack(spacing: 2) {
                Image(systemName: "minus")
                    .font(.caption2)
                Text("Stable")
                    .font(.caption)
            }
            .foregroundColor(.secondary)

        case .unknown:
            EmptyView()
        }
    }

    // MARK: - Pain Regions Summary

    private var painRegionsSummary: String {
        if activePainRegions.isEmpty {
            return "No active pain regions"
        }
        let regionNames = activePainRegions.prefix(3).map { $0.region.shortName }
        let joined = regionNames.joined(separator: ", ")
        if activePainRegions.count > 3 {
            return "\(joined) +\(activePainRegions.count - 3) more"
        }
        return joined
    }

    // MARK: - No Pain Data Prompt

    private var noPainDataPrompt: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.title3)
                    .foregroundColor(.pink)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Track your recovery")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Log pain levels to monitor progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            if let onLogPain = onLogPain {
                Button(action: {
                    HapticFeedback.light()
                    onLogPain()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Log Pain Now")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.sm)
                }
                .accessibilityLabel("Log pain now")
                .accessibilityHint("Opens pain logging form")
            }
        }
    }

    // MARK: - Deload Urgency Banner

    private func deloadUrgencyBanner(urgency: DeloadUrgency) -> some View {
        Button(action: {
            HapticFeedback.light()
            onViewDashboard?()
        }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: urgency.icon)
                    .font(.subheadline)
                    .foregroundColor(urgency.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(urgency.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(urgency.color)

                    Text(urgency.subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(Spacing.sm)
            .background(urgency.color.opacity(0.1))
            .cornerRadius(CornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(urgency.title): \(urgency.subtitle)")
    }

    // MARK: - Alerts Indicator

    private var alertsIndicator: some View {
        Button(action: {
            HapticFeedback.light()
            onViewAlerts?()
        }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundColor(.orange)

                Text("\(alertCount) Active Alert\(alertCount == 1 ? "" : "s")")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()

                Text("View")
                    .font(.caption)
                    .foregroundColor(.modusCyan)
            }
            .padding(Spacing.sm)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(CornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(alertCount) active alerts")
        .accessibilityHint("Tap to view alerts")
    }
}

// MARK: - Pain Trend Enum

private enum PainTrend {
    case improving
    case worsening
    case stable
    case unknown
}

// MARK: - Preview

#if DEBUG
struct RehabModeStatusCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                // With pain data
                RehabModeStatusCard(
                    todayPainScore: 4,
                    previousPainScore: 6,
                    activePainRegions: [
                        PainLocation(region: .shoulderRight, intensity: 4),
                        PainLocation(region: .kneeLeft, intensity: 3)
                    ],
                    hasActiveAlerts: true,
                    alertCount: 2,
                    deloadUrgency: .suggested,
                    onLogPain: {},
                    onViewAlerts: {},
                    onViewDashboard: {}
                )

                // No pain data
                RehabModeStatusCard(
                    onLogPain: {},
                    onViewDashboard: {}
                )

                // High pain with required deload
                RehabModeStatusCard(
                    todayPainScore: 8,
                    previousPainScore: 7,
                    deloadUrgency: .required,
                    onLogPain: {},
                    onViewDashboard: {}
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
