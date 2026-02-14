//
//  PTBriefRiskSection.swift
//  PTPerformance
//
//  PT Brief Risk Section - Red-bordered section for safety/risk items
//  Part of the 60-Second Athlete Brief workflow
//
//  Features:
//  - Shows items exceeding safety thresholds
//  - Red border for high/critical risks
//  - Escalation prompt for critical risks
//  - Each risk is citation-linked
//  - Critical risks require acknowledgment
//

import SwiftUI

struct PTBriefRiskSection: View {
    let risks: [PTBriefRiskAlert]
    let isLoading: Bool
    let onRiskTap: (PTBriefRiskAlert) -> Void
    let onAcknowledge: (PTBriefRiskAlert) -> Void

    @State private var showEscalationAlert = false
    @State private var selectedCriticalRisk: PTBriefRiskAlert?

    private var criticalRisks: [PTBriefRiskAlert] {
        risks.filter { $0.severity >= .high }
    }

    private var hasUnacknowledgedCritical: Bool {
        risks.contains { $0.severity >= .high && $0.requiresAcknowledgment }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section Header
            sectionHeader

            if isLoading {
                loadingState
            } else if risks.isEmpty {
                allClearState
            } else {
                // Risk Cards
                VStack(spacing: Spacing.sm) {
                    ForEach(risks.sorted(by: { $0.severity > $1.severity })) { risk in
                        RiskAlertCard(
                            risk: risk,
                            onTap: { onRiskTap(risk) },
                            onAcknowledge: {
                                if risk.severity == .critical {
                                    selectedCriticalRisk = risk
                                    showEscalationAlert = true
                                } else {
                                    onAcknowledge(risk)
                                }
                            }
                        )
                    }
                }
                .padding(Spacing.sm)
                .background(riskBackground)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(borderColor, lineWidth: hasUnacknowledgedCritical ? 2 : 1)
                )
            }
        }
        .alert("Critical Risk Acknowledgment", isPresented: $showEscalationAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Acknowledge & Continue", role: .destructive) {
                if let risk = selectedCriticalRisk {
                    onAcknowledge(risk)
                }
            }
        } message: {
            if let risk = selectedCriticalRisk {
                Text("You are acknowledging a critical risk: \(risk.title). This action will be logged for compliance purposes.")
            }
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack {
            Image(systemName: "exclamationmark.shield.fill")
                .foregroundColor(hasUnacknowledgedCritical ? .red : .orange)
                .accessibilityHidden(true)

            Text("Risk Alerts")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            if !risks.isEmpty {
                Text("(\(risks.count))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if hasUnacknowledgedCritical {
                urgentBadge
            }
        }
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Urgent Badge

    private var urgentBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "bell.fill")
                .font(.caption2)

            Text("Action Required")
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(Color.red)
        .cornerRadius(CornerRadius.xs)
    }

    // MARK: - Loading State

    private var loadingState: some View {
        HStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(0.8)

            Text("Checking risk thresholds...")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - All Clear State

    private var allClearState: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: "checkmark.shield.fill")
                    .font(.title3)
                    .foregroundColor(.green)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("All Clear")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)

                Text("No thresholds exceeded, no active risk flags")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("All clear. No thresholds exceeded, no active risk flags.")
    }

    // MARK: - Helpers

    private var riskBackground: some View {
        let highestSeverity = risks.map { $0.severity }.max() ?? .low
        let opacity: Double = {
            switch highestSeverity {
            case .critical: return 0.08
            case .high: return 0.06
            case .moderate: return 0.04
            case .low: return 0.02
            }
        }()
        return Color.red.opacity(opacity)
    }

    private var borderColor: Color {
        let highestSeverity = risks.map { $0.severity }.max() ?? .low
        switch highestSeverity {
        case .critical: return .red
        case .high: return .red.opacity(0.7)
        case .moderate: return .orange.opacity(0.5)
        case .low: return .yellow.opacity(0.5)
        }
    }
}

// MARK: - Risk Alert Card

private struct RiskAlertCard: View {
    let risk: PTBriefRiskAlert
    let onTap: () -> Void
    let onAcknowledge: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header row
            HStack(spacing: Spacing.sm) {
                severityIcon

                VStack(alignment: .leading, spacing: 2) {
                    Text(risk.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(risk.severity.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(risk.severity.color)
                }

                Spacer()

                citationBadge
            }

            // Description
            Text(risk.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            // Threshold comparison
            thresholdComparison

            // Action buttons for acknowledgment
            if risk.requiresAcknowledgment {
                acknowledgeButton
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.sm)
        .onTapGesture {
            HapticFeedback.light()
            onTap()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(risk.requiresAcknowledgment ? "Tap to acknowledge or view details" : "Tap to view details")
    }

    // MARK: - Severity Icon

    private var severityIcon: some View {
        ZStack {
            Circle()
                .fill(risk.severity.color.opacity(0.15))
                .frame(width: 32, height: 32)

            Image(systemName: risk.severity.icon)
                .font(.caption)
                .foregroundColor(risk.severity.color)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Citation Badge

    private var citationBadge: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            HStack(spacing: 2) {
                Image(systemName: "doc.text")
                    .font(.system(size: 8))

                Text("\(risk.citationCount)")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(.modusCyan)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.modusCyan.opacity(0.1))
            .cornerRadius(CornerRadius.xs)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(risk.citationCount) citations")
    }

    // MARK: - Threshold Comparison

    private var thresholdComparison: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Threshold")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(risk.thresholdValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Current")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(risk.currentValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(risk.severity.color)
            }

            Spacer()

            Text(risk.source)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(Spacing.xs)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.xs)
    }

    // MARK: - Acknowledge Button

    private var acknowledgeButton: some View {
        Button(action: {
            HapticFeedback.medium()
            onAcknowledge()
        }) {
            HStack {
                Image(systemName: "checkmark.circle")
                    .font(.caption)

                Text("Acknowledge")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
            .background(risk.severity.color)
            .cornerRadius(CornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var accessibilityLabel: String {
        "\(risk.severity.displayName) risk: \(risk.title). \(risk.description). Threshold \(risk.thresholdValue), current value \(risk.currentValue). \(risk.citationCount) citations."
    }
}

// MARK: - Preview

#if DEBUG
struct PTBriefRiskSection_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // With risks
            ScrollView {
                PTBriefRiskSection(
                    risks: [
                        PTBriefRiskAlert(
                            id: UUID(),
                            title: "Elevated Workload Ratio",
                            description: "Acute:chronic workload ratio exceeds recommended threshold for injury prevention",
                            severity: .high,
                            thresholdValue: "1.3",
                            currentValue: "1.52",
                            source: "Workload Calculator",
                            citationCount: 3,
                            requiresAcknowledgment: true,
                            timestamp: Date()
                        ),
                        PTBriefRiskAlert(
                            id: UUID(),
                            title: "Sleep Deficit",
                            description: "Cumulative sleep debt may impact recovery",
                            severity: .moderate,
                            thresholdValue: "7h avg",
                            currentValue: "5.5h avg",
                            source: "Sleep Tracker",
                            citationCount: 2,
                            requiresAcknowledgment: false,
                            timestamp: Date()
                        )
                    ],
                    isLoading: false,
                    onRiskTap: { _ in },
                    onAcknowledge: { _ in }
                )
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .previewDisplayName("With Risks")

            // Critical risk
            ScrollView {
                PTBriefRiskSection(
                    risks: [
                        PTBriefRiskAlert(
                            id: UUID(),
                            title: "Pain Spike Detected",
                            description: "Reported pain level exceeds safety threshold. Immediate review recommended.",
                            severity: .critical,
                            thresholdValue: "6/10",
                            currentValue: "8/10",
                            source: "Daily Check-in",
                            citationCount: 1,
                            requiresAcknowledgment: true,
                            timestamp: Date()
                        )
                    ],
                    isLoading: false,
                    onRiskTap: { _ in },
                    onAcknowledge: { _ in }
                )
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .previewDisplayName("Critical Risk")

            // Loading
            ScrollView {
                PTBriefRiskSection(
                    risks: [],
                    isLoading: true,
                    onRiskTap: { _ in },
                    onAcknowledge: { _ in }
                )
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .previewDisplayName("Loading")

            // All clear
            ScrollView {
                PTBriefRiskSection(
                    risks: [],
                    isLoading: false,
                    onRiskTap: { _ in },
                    onAcknowledge: { _ in }
                )
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .previewDisplayName("All Clear")

            // Dark mode
            ScrollView {
                PTBriefRiskSection(
                    risks: [
                        PTBriefRiskAlert(
                            id: UUID(),
                            title: "HRV Below Baseline",
                            description: "Heart rate variability 20% below personal baseline",
                            severity: .moderate,
                            thresholdValue: "45 ms",
                            currentValue: "36 ms",
                            source: "Apple Watch",
                            citationCount: 2,
                            requiresAcknowledgment: false,
                            timestamp: Date()
                        )
                    ],
                    isLoading: false,
                    onRiskTap: { _ in },
                    onAcknowledge: { _ in }
                )
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
#endif
