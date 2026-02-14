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
        case .warning: return DesignTokens.statusWarning
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
    let type: HealthInsightType
    let category: HealthInsightCategory
    let title: String
    let message: String
    let actionText: String?
    let action: (() -> Void)?
    let timestamp: Date

    var id: String { "\(category.rawValue)-\(title)-\(timestamp.timeIntervalSince1970)" }

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
    @State private var hasAppeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header
            HStack(spacing: Spacing.sm) {
                // Type indicator with pulse for critical
                ZStack {
                    Circle()
                        .fill(insight.type.color.opacity(colorScheme == .dark ? 0.25 : 0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: insight.type.icon)
                        .font(.body)
                        .foregroundColor(insight.type.color)
                        .symbolEffect(.pulse, options: .repeating, value: insight.type == .critical)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.xs) {
                        Text(insight.category.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(insight.type.color)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility1)

                        Text("AI Insight")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(CornerRadius.xs)
                    }

                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(isExpanded ? nil : 1)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                }

                Spacer()

                // Dismiss button with haptic
                if let onDismiss = onDismiss {
                    Button(action: {
                        HapticFeedback.light()
                        onDismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(Spacing.xs)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(Circle())
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Dismiss insight")
                    .accessibilityHint("Double tap to dismiss this insight")
                }
            }

            // Message
            Text(insight.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(isExpanded ? nil : 2)
                .fixedSize(horizontal: false, vertical: isExpanded)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)

            // Expand/collapse for long messages with haptic
            if insight.message.count > 100 {
                Button {
                    withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                        isExpanded.toggle()
                    }
                    HapticFeedback.selectionChanged()
                } label: {
                    HStack(spacing: 2) {
                        Text(isExpanded ? "Show less" : "Read more")
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                    .font(.caption)
                    .foregroundColor(.modusCyan)
                }
                .frame(minHeight: 44)
                .accessibilityLabel(isExpanded ? "Show less content" : "Read more content")
            }

            // Action button with medium haptic for emphasis
            if let actionText = insight.actionText, let action = insight.action {
                Divider()
                    .padding(.vertical, Spacing.xxs)

                Button(action: {
                    HapticFeedback.medium()
                    action()
                }) {
                    HStack(spacing: Spacing.xs) {
                        Text(actionText)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .accessibilityHidden(true)
                    }
                    .foregroundColor(insight.type.color)
                }
                .frame(minHeight: 44)
                .accessibilityLabel(actionText)
                .accessibilityHint("Double tap to \(actionText.lowercased())")
            }

            // ACP-1025: AI Transparency - feedback buttons
            InsightFeedbackRow(
                insightId: insight.id,
                feedbackType: .healthInsight
            )

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
                        .stroke(
                            insight.type == .critical || insight.type == .warning
                                ? insight.type.color.opacity(colorScheme == .dark ? 0.5 : 0.4)
                                : insight.type.color.opacity(colorScheme == .dark ? 0.4 : 0.3),
                            lineWidth: insight.type == .critical ? 2 : 1
                        )
                )
        )
        // Reveal animation
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                hasAppeared = true
            }
            // Haptic feedback for critical/warning insights
            if insight.type == .critical {
                HapticFeedback.warning()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(insight.type.accessibilityLabel): \(insight.title). \(insight.message)")
        .accessibilityIdentifier("healthInsightCard")
    }
}

/// Compact insight row for lists
struct HealthInsightRow: View {
    let insight: HealthHubInsight
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

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
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)

                    Text(insight.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                }

                Spacer()

                // Category badge
                Text(insight.category.displayName)
                    .font(.caption2)
                    .foregroundColor(insight.type.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(insight.type.color.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .cornerRadius(CornerRadius.xs)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding()
            .frame(minHeight: 44) // Minimum touch target
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(insight.type.accessibilityLabel): \(insight.title), \(insight.category.displayName)")
        .accessibilityHint("Double tap to view details")
        .accessibilityIdentifier("healthInsightRow_\(insight.title.replacingOccurrences(of: " ", with: "_"))")
    }
}

// MARK: - ACP-1025: Inline Feedback Row

/// Compact inline feedback row for AI-generated insights
/// Shows thumbs up/down buttons for quick user feedback
struct InsightFeedbackRow: View {
    let insightId: String
    let feedbackType: RecommendationFeedbackType

    @State private var feedbackState: InsightFeedbackState = .none
    @State private var showThanks = false
    @StateObject private var feedbackStore = RecommendationFeedbackStore.shared
    @Environment(\.colorScheme) private var colorScheme

    private enum InsightFeedbackState {
        case none
        case positive
        case negative
    }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Divider()
                .frame(height: 16)

            Text("Helpful?")
                .font(.caption2)
                .foregroundColor(.secondary)

            // Thumbs up
            Button {
                toggleFeedback(isPositive: true)
            } label: {
                Image(systemName: feedbackState == .positive
                    ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.caption)
                    .foregroundColor(feedbackState == .positive ? .modusTealAccent : .secondary)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 36, minHeight: 36)
            .accessibilityLabel("Thumbs up - mark as helpful")

            // Thumbs down
            Button {
                toggleFeedback(isPositive: false)
            } label: {
                Image(systemName: feedbackState == .negative
                    ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .font(.caption)
                    .foregroundColor(feedbackState == .negative ? .secondary : .secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
            .frame(minWidth: 36, minHeight: 36)
            .accessibilityLabel("Thumbs down - mark as not helpful")

            if showThanks {
                Text("Thanks!")
                    .font(.caption2)
                    .foregroundColor(.modusTealAccent)
                    .transition(.opacity)
            }

            Spacer()
        }
        .onAppear {
            feedbackStore.loadFeedback()
            if let existing = feedbackStore.getFeedback(for: insightId) {
                feedbackState = existing.isPositive ? .positive : .negative
            }
        }
    }

    private func toggleFeedback(isPositive: Bool) {
        let newState: InsightFeedbackState = isPositive ? .positive : .negative

        if feedbackState == newState {
            feedbackState = .none
            feedbackStore.removeFeedback(for: insightId)
            return
        }

        feedbackState = newState
        feedbackStore.submitFeedback(
            recommendationId: insightId,
            type: feedbackType,
            isPositive: isPositive
        )
        HapticFeedback.light()

        withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
            showThanks = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { showThanks = false }
        }
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
