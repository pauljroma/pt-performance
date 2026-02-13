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

        var accessibilityDescription: String {
            switch self {
            case .up: return "improving"
            case .down: return "declining"
            case .stable: return "stable"
            case .unknown: return "unknown"
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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Header
            HStack {
                Text("Today's Health")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Text(data.lastUpdated.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
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
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("healthSnapshotCard")
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
                                .dynamicTypeSize(...DynamicTypeSize.accessibility1)

                            Image(systemName: data.recoveryTrend.icon)
                                .font(.caption)
                                .foregroundColor(data.recoveryTrend.color)
                                .accessibilityHidden(true)
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
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel("Recovery: \(data.recoveryScore.map { "\($0) percent, trend \(data.recoveryTrend.accessibilityDescription)" } ?? "no data")")
        .accessibilityHint(onRecoveryTap != nil ? "Double tap to view recovery details" : "")
        .accessibilityIdentifier("recoveryMetric")
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
                                .dynamicTypeSize(...DynamicTypeSize.accessibility1)

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
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel(fastingAccessibilityLabel)
        .accessibilityHint(onFastingTap != nil ? "Double tap to view fasting details" : "")
        .accessibilityIdentifier("fastingMetric")
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
                                .dynamicTypeSize(...DynamicTypeSize.accessibility1)

                            if data.supplementsCompliance.isComplete {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.modusTealAccent)
                                    .accessibilityHidden(true)
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
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel("Supplements: \(data.supplementsCompliance.taken) of \(data.supplementsCompliance.total) taken\(data.supplementsCompliance.isComplete ? ", all complete" : "")")
        .accessibilityHint(onSupplementsTap != nil ? "Double tap to view supplement details" : "")
        .accessibilityIdentifier("supplementsMetric")
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
                                .dynamicTypeSize(...DynamicTypeSize.accessibility1)

                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                                .accessibilityHidden(true)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.modusTealAccent)
                                .accessibilityHidden(true)

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
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel(data.labAlerts > 0 ? "\(data.labAlerts) lab alert\(data.labAlerts == 1 ? "" : "s") requiring attention" : "No lab alerts, all clear")
        .accessibilityHint(onLabAlertsTap != nil ? "Double tap to view lab details" : "")
        .accessibilityIdentifier("labAlertsMetric")
    }
}

/// Individual metric view for the snapshot card
private struct SnapshotMetricView<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content

    @Environment(\.colorScheme) private var colorScheme

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
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 44) // Minimum touch target
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
                color: .pink,
                accessibilityLabel: "Recovery: \(data.recoveryScore.map { "\($0) percent" } ?? "no data")"
            )

            Divider()
                .frame(height: 30)
                .accessibilityHidden(true)

            // Fasting
            MiniMetric(
                icon: "fork.knife.circle.fill",
                value: data.fastingStatus.isFasting ? String(format: "%.0fh", data.fastingStatus.hoursElapsed ?? 0) : "Eat",
                color: data.fastingStatus.isFasting ? .teal : .orange,
                accessibilityLabel: data.fastingStatus.isFasting ? "Fasting: \(String(format: "%.0f", data.fastingStatus.hoursElapsed ?? 0)) hours" : "Currently eating"
            )

            Divider()
                .frame(height: 30)
                .accessibilityHidden(true)

            // Supplements
            MiniMetric(
                icon: "pill.fill",
                value: "\(data.supplementsCompliance.taken)/\(data.supplementsCompliance.total)",
                color: data.supplementsCompliance.isComplete ? .modusTealAccent : .orange,
                accessibilityLabel: "Supplements: \(data.supplementsCompliance.taken) of \(data.supplementsCompliance.total) taken"
            )

            Divider()
                .frame(height: 30)
                .accessibilityHidden(true)

            // Lab alerts
            MiniMetric(
                icon: data.labAlerts > 0 ? "exclamationmark.triangle.fill" : "checkmark.circle.fill",
                value: data.labAlerts > 0 ? "\(data.labAlerts)" : "",
                color: data.labAlerts > 0 ? .red : .modusTealAccent,
                accessibilityLabel: data.labAlerts > 0 ? "\(data.labAlerts) lab alerts" : "No lab alerts"
            )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("miniHealthSnapshotCard")
    }
}

/// Mini metric for compact display
private struct MiniMetric: View {
    let icon: String
    let value: String
    let color: Color
    let accessibilityLabel: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .accessibilityHidden(true)

            if !value.isEmpty {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 44) // Minimum touch target
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
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
