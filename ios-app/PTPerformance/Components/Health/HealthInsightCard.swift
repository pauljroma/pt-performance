//
//  HealthInsightCard.swift
//  PTPerformance
//
//  Card showing AI-generated health insights
//  Displays contextual recommendations like "Your sleep has been low for 3 days..."
//

import SwiftUI

/// Health insight severity/type
enum HealthInsightType: String, Codable {
    case info
    case positive
    case warning
    case critical

    var icon: String {
        switch self {
        case .info: return "lightbulb.fill"
        case .positive: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }

    var color: Color {
        switch self {
        case .info: return .modusCyan
        case .positive: return .modusTealAccent
        case .warning: return .orange
        case .critical: return .red
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .info: return "Information"
        case .positive: return "Positive insight"
        case .warning: return "Warning"
        case .critical: return "Critical alert"
        }
    }
}

/// Health insight category
enum HealthInsightCategory: String, Codable {
    case sleep
    case recovery
    case nutrition
    case fasting
    case supplements
    case biomarkers
    case training
    case general

    var icon: String {
        switch self {
        case .sleep: return "moon.fill"
        case .recovery: return "heart.fill"
        case .nutrition: return "fork.knife"
        case .fasting: return "fork.knife.circle.fill"
        case .supplements: return "pill.fill"
        case .biomarkers: return "chart.bar.doc.horizontal.fill"
        case .training: return "figure.run"
        case .general: return "brain.head.profile"
        }
    }

    var displayName: String {
        switch self {
        case .sleep: return "Sleep"
        case .recovery: return "Recovery"
        case .nutrition: return "Nutrition"
        case .fasting: return "Fasting"
        case .supplements: return "Supplements"
        case .biomarkers: return "Biomarkers"
        case .training: return "Training"
        case .general: return "Health"
        }
    }
}

/// Model for a health insight
struct HealthHubInsight: Identifiable {
    let id = UUID()
    let type: HealthInsightType
    let category: HealthInsightCategory
    let title: String
    let message: String
    let actionText: String?
    let action: (() -> Void)?
    let timestamp: Date

    init(
        type: HealthInsightType,
        category: HealthInsightCategory,
        title: String,
        message: String,
        actionText: String? = nil,
        action: (() -> Void)? = nil,
        timestamp: Date = Date()
    ) {
        self.type = type
        self.category = category
        self.title = title
        self.message = message
        self.actionText = actionText
        self.action = action
        self.timestamp = timestamp
    }
}

/// Card showing AI-generated health insight
struct HealthInsightCard: View {
    let insight: HealthHubInsight
    var onDismiss: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header
            HStack(spacing: Spacing.sm) {
                // Type indicator
                ZStack {
                    Circle()
                        .fill(insight.type.color.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: insight.type.icon)
                        .font(.body)
                        .foregroundColor(insight.type.color)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.xs) {
                        Text(insight.category.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(insight.type.color)

                        Text("AI Insight")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(4)
                    }

                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(isExpanded ? nil : 1)
                }

                Spacer()

                // Dismiss button
                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(Spacing.xs)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Dismiss insight")
                }
            }

            // Message
            Text(insight.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(isExpanded ? nil : 2)
                .fixedSize(horizontal: false, vertical: isExpanded)

            // Expand/collapse for long messages
            if insight.message.count > 100 {
                Button {
                    withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "Show less" : "Read more")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }
            }

            // Action button
            if let actionText = insight.actionText, let action = insight.action {
                Divider()
                    .padding(.vertical, Spacing.xxs)

                Button(action: {
                    HapticFeedback.light()
                    action()
                }) {
                    HStack(spacing: Spacing.xs) {
                        Text(actionText)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .foregroundColor(insight.type.color)
                }
                .accessibilityLabel(actionText)
            }

            // Timestamp
            HStack {
                Spacer()
                Text(insight.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(insight.type.color.opacity(0.3), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(insight.type.accessibilityLabel): \(insight.title)")
    }
}

/// Compact insight row for lists
struct HealthInsightRow: View {
    let insight: HealthHubInsight
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            HStack(spacing: Spacing.sm) {
                // Icon
                Image(systemName: insight.type.icon)
                    .font(.body)
                    .foregroundColor(insight.type.color)
                    .frame(width: 24)
                    .accessibilityHidden(true)

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(insight.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Category badge
                Text(insight.category.displayName)
                    .font(.caption2)
                    .foregroundColor(insight.type.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(insight.type.color.opacity(0.1))
                    .cornerRadius(CornerRadius.xs)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(insight.type.accessibilityLabel): \(insight.title)")
        .accessibilityHint("Tap to view details")
    }
}

/// Multiple insights carousel
struct HealthInsightsCarousel: View {
    let insights: [HealthHubInsight]
    var onInsightTap: ((HealthHubInsight) -> Void)?
    var onDismiss: ((HealthHubInsight) -> Void)?

    var body: some View {
        if insights.isEmpty {
            noInsightsView
        } else if insights.count == 1 {
            HealthInsightCard(
                insight: insights[0],
                onDismiss: onDismiss.map { dismiss in { dismiss(insights[0]) } }
            )
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(insights) { insight in
                        HealthInsightCard(
                            insight: insight,
                            onDismiss: onDismiss.map { dismiss in { dismiss(insight) } }
                        )
                        .frame(width: 300)
                        .onTapGesture {
                            onInsightTap?(insight)
                        }
                    }
                }
                .padding(.horizontal, Spacing.xxs)
            }
        }
    }

    private var noInsightsView: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(.modusCyan)

            VStack(alignment: .leading, spacing: 2) {
                Text("All Caught Up")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("No new health insights at this time. Keep up the great work!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - Preview

#if DEBUG
struct HealthInsightCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                Text("Health Insight Cards")
                    .font(.headline)

                HealthInsightCard(
                    insight: HealthHubInsight(
                        type: .warning,
                        category: .sleep,
                        title: "Sleep Deficit Detected",
                        message: "Your sleep has been below 6 hours for the past 3 days. This may impact your recovery and training performance.",
                        actionText: "View Sleep Details",
                        action: {}
                    ),
                    onDismiss: {}
                )

                HealthInsightCard(
                    insight: HealthHubInsight(
                        type: .positive,
                        category: .recovery,
                        title: "Recovery Streak",
                        message: "You've completed recovery sessions 5 days in a row. Great consistency!",
                        actionText: nil,
                        action: nil
                    )
                )

                HealthInsightCard(
                    insight: HealthHubInsight(
                        type: .critical,
                        category: .biomarkers,
                        title: "Vitamin D Below Range",
                        message: "Your latest Vitamin D result (18 ng/mL) is below the optimal range. Consider consulting with your provider.",
                        actionText: "View Lab Results",
                        action: {}
                    )
                )

                Text("Compact Row")
                    .font(.headline)

                HealthInsightRow(
                    insight: HealthHubInsight(
                        type: .info,
                        category: .fasting,
                        title: "Optimal Eating Window",
                        message: "Based on your schedule, 12pm-8pm eating window is recommended."
                    ),
                    onTap: {}
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
