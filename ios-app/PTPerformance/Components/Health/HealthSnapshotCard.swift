//
//  HealthSnapshotCard.swift
//  PTPerformance
//
//  Today's health summary card
//  Shows Recovery %, Fasting status, Supplements logged, Lab alerts
//

import SwiftUI

/// Model for today's health snapshot data
struct HealthSnapshotData {
    let recoveryScore: Int?
    let recoveryTrend: TrendDirection
    let fastingStatus: FastingStatus
    let supplementsCompliance: SupplementsCompliance
    let labAlerts: Int
    let lastUpdated: Date

    struct FastingStatus {
        let isFasting: Bool
        let hoursElapsed: Double?
        let targetHours: Int?
        let currentProtocol: String?
    }

    struct SupplementsCompliance {
        let taken: Int
        let total: Int

        var percentage: Double {
            guard total > 0 else { return 0 }
            return Double(taken) / Double(total)
        }

        var isComplete: Bool {
            taken >= total && total > 0
        }
    }

    enum TrendDirection {
        case up
        case down
        case stable
        case unknown

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "arrow.right"
            case .unknown: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up: return .modusTealAccent
            case .down: return .orange
            case .stable: return .modusCyan
            case .unknown: return .secondary
            }
        }
    }

    /// Empty snapshot for loading state
    static var empty: HealthSnapshotData {
        HealthSnapshotData(
            recoveryScore: nil,
            recoveryTrend: .unknown,
            fastingStatus: FastingStatus(isFasting: false, hoursElapsed: nil, targetHours: nil, currentProtocol: nil),
            supplementsCompliance: SupplementsCompliance(taken: 0, total: 0),
            labAlerts: 0,
            lastUpdated: Date()
        )
    }
}

/// Today's health summary card
struct HealthSnapshotCard: View {
    let data: HealthSnapshotData
    let isLoading: Bool
    var onRecoveryTap: (() -> Void)?
    var onFastingTap: (() -> Void)?
    var onSupplementsTap: (() -> Void)?
    var onLabAlertsTap: (() -> Void)?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Header
            HStack {
                Text("Today's Health")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                Spacer()

                Text(data.lastUpdated.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if isLoading {
                loadingView
            } else {
                // Metrics grid - adapt based on size class
                if horizontalSizeClass == .regular {
                    HStack(spacing: Spacing.md) {
                        recoveryMetric
                        fastingMetric
                        supplementsMetric
                        labAlertsMetric
                    }
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Spacing.sm) {
                        recoveryMetric
                        fastingMetric
                        supplementsMetric
                        labAlertsMetric
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Spacer()
        }
        .frame(height: 100)
    }

    // MARK: - Recovery Metric

    private var recoveryMetric: some View {
        Button(action: { onRecoveryTap?() }) {
            SnapshotMetricView(
                title: "Recovery",
                icon: "heart.fill",
                iconColor: .pink,
                content: {
                    if let score = data.recoveryScore {
                        HStack(spacing: 4) {
                            Text("\(score)%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Image(systemName: data.recoveryTrend.icon)
                                .font(.caption)
                                .foregroundColor(data.recoveryTrend.color)
                        }
                    } else {
                        Text("--")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .disabled(onRecoveryTap == nil)
        .accessibilityLabel("Recovery: \(data.recoveryScore.map { "\($0) percent" } ?? "no data")")
        .accessibilityHint(onRecoveryTap != nil ? "Tap to view recovery details" : "")
    }

    // MARK: - Fasting Metric

    private var fastingMetric: some View {
        Button(action: { onFastingTap?() }) {
            SnapshotMetricView(
                title: "Fasting",
                icon: "fork.knife.circle.fill",
                iconColor: data.fastingStatus.isFasting ? .teal : .orange,
                content: {
                    if data.fastingStatus.isFasting, let hours = data.fastingStatus.hoursElapsed {
                        VStack(spacing: 0) {
                            Text(String(format: "%.1fh", hours))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.modusTealAccent)

                            if let target = data.fastingStatus.targetHours {
                                Text("of \(target)h")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        Text("Eating")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .disabled(onFastingTap == nil)
        .accessibilityLabel(fastingAccessibilityLabel)
        .accessibilityHint(onFastingTap != nil ? "Tap to view fasting details" : "")
    }

    private var fastingAccessibilityLabel: String {
        if data.fastingStatus.isFasting, let hours = data.fastingStatus.hoursElapsed {
            return "Fasting: \(String(format: "%.1f", hours)) hours elapsed"
        } else {
            return "Fasting: Currently in eating window"
        }
    }

    // MARK: - Supplements Metric

    private var supplementsMetric: some View {
        Button(action: { onSupplementsTap?() }) {
            SnapshotMetricView(
                title: "Supplements",
                icon: "pill.fill",
                iconColor: .orange,
                content: {
                    if data.supplementsCompliance.total > 0 {
                        HStack(spacing: 4) {
                            Text("\(data.supplementsCompliance.taken)/\(data.supplementsCompliance.total)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(data.supplementsCompliance.isComplete ? .modusTealAccent : .primary)

                            if data.supplementsCompliance.isComplete {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.modusTealAccent)
                            }
                        }
                    } else {
                        Text("--")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .disabled(onSupplementsTap == nil)
        .accessibilityLabel("Supplements: \(data.supplementsCompliance.taken) of \(data.supplementsCompliance.total) taken")
        .accessibilityHint(onSupplementsTap != nil ? "Tap to view supplement details" : "")
    }

    // MARK: - Lab Alerts Metric

    private var labAlertsMetric: some View {
        Button(action: { onLabAlertsTap?() }) {
            SnapshotMetricView(
                title: "Lab Alerts",
                icon: "cross.case.fill",
                iconColor: data.labAlerts > 0 ? .red : .modusCyan,
                content: {
                    if data.labAlerts > 0 {
                        HStack(spacing: 4) {
                            Text("\(data.labAlerts)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)

                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.modusTealAccent)

                            Text("Clear")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.modusTealAccent)
                        }
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .disabled(onLabAlertsTap == nil)
        .accessibilityLabel(data.labAlerts > 0 ? "\(data.labAlerts) lab alerts requiring attention" : "No lab alerts")
        .accessibilityHint(onLabAlertsTap != nil ? "Tap to view lab details" : "")
    }
}

/// Individual metric view for the snapshot card
private struct SnapshotMetricView<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content

    init(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            // Icon
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(iconColor)
                .accessibilityHidden(true)

            // Value
            content

            // Label
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
    }
}

/// Mini snapshot for widgets or compact displays
struct MiniHealthSnapshotCard: View {
    let data: HealthSnapshotData

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Recovery
            MiniMetric(
                icon: "heart.fill",
                value: data.recoveryScore.map { "\($0)%" } ?? "--",
                color: .pink
            )

            Divider()
                .frame(height: 30)

            // Fasting
            MiniMetric(
                icon: "fork.knife.circle.fill",
                value: data.fastingStatus.isFasting ? String(format: "%.0fh", data.fastingStatus.hoursElapsed ?? 0) : "Eat",
                color: data.fastingStatus.isFasting ? .teal : .orange
            )

            Divider()
                .frame(height: 30)

            // Supplements
            MiniMetric(
                icon: "pill.fill",
                value: "\(data.supplementsCompliance.taken)/\(data.supplementsCompliance.total)",
                color: data.supplementsCompliance.isComplete ? .modusTealAccent : .orange
            )

            Divider()
                .frame(height: 30)

            // Lab alerts
            MiniMetric(
                icon: data.labAlerts > 0 ? "exclamationmark.triangle.fill" : "checkmark.circle.fill",
                value: data.labAlerts > 0 ? "\(data.labAlerts)" : "",
                color: data.labAlerts > 0 ? .red : .modusTealAccent
            )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

/// Mini metric for compact display
private struct MiniMetric: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            if !value.isEmpty {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#if DEBUG
struct HealthSnapshotCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.lg) {
            Text("Health Snapshot Card")
                .font(.headline)

            HealthSnapshotCard(
                data: HealthSnapshotData(
                    recoveryScore: 78,
                    recoveryTrend: .up,
                    fastingStatus: HealthSnapshotData.FastingStatus(
                        isFasting: true,
                        hoursElapsed: 14.5,
                        targetHours: 16,
                        currentProtocol: "16:8"
                    ),
                    supplementsCompliance: HealthSnapshotData.SupplementsCompliance(taken: 4, total: 6),
                    labAlerts: 2,
                    lastUpdated: Date()
                ),
                isLoading: false,
                onRecoveryTap: {},
                onFastingTap: {},
                onSupplementsTap: {},
                onLabAlertsTap: {}
            )

            Text("Complete State")
                .font(.headline)

            HealthSnapshotCard(
                data: HealthSnapshotData(
                    recoveryScore: 92,
                    recoveryTrend: .stable,
                    fastingStatus: HealthSnapshotData.FastingStatus(
                        isFasting: false,
                        hoursElapsed: nil,
                        targetHours: nil,
                        currentProtocol: nil
                    ),
                    supplementsCompliance: HealthSnapshotData.SupplementsCompliance(taken: 6, total: 6),
                    labAlerts: 0,
                    lastUpdated: Date()
                ),
                isLoading: false
            )

            Text("Mini Snapshot")
                .font(.headline)

            MiniHealthSnapshotCard(
                data: HealthSnapshotData(
                    recoveryScore: 85,
                    recoveryTrend: .up,
                    fastingStatus: HealthSnapshotData.FastingStatus(
                        isFasting: true,
                        hoursElapsed: 12,
                        targetHours: 16,
                        currentProtocol: "16:8"
                    ),
                    supplementsCompliance: HealthSnapshotData.SupplementsCompliance(taken: 3, total: 5),
                    labAlerts: 1,
                    lastUpdated: Date()
                )
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
