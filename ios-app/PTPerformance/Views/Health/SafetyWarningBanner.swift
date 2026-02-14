// DARK MODE: See ModeThemeModifier.swift for central theme control
import SwiftUI

/// Reusable safety warning banner for supplement interaction alerts.
/// Supports compact mode (for lists/dashboards) and expanded mode (for detail views).
/// Color-coded by overall safety rating with animated entrance and VoiceOver support.
struct SafetyWarningBanner: View {
    /// Overall safety rating for the user's current supplement routine.
    let safetyRating: SafetyRating
    /// Number of interactions detected.
    let interactionCount: Int
    /// The most critical interaction message (used in expanded mode).
    let mostCriticalMessage: String?
    /// Whether to use expanded layout (shows inline detail + "View all" link).
    var isExpanded: Bool = false
    /// Action when the banner is tapped (typically navigates to full interaction view).
    let onTap: () -> Void

    @State private var isVisible = false

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            if isExpanded {
                expandedContent
            } else {
                compactContent
            }
        }
        .buttonStyle(.plain)
        .offset(y: isVisible ? 0 : -20)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to view interaction details")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Compact Content

    private var compactContent: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: iconName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(iconForegroundColor)
                .accessibilityHidden(true)

            Text(compactText)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(textForegroundColor)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(textForegroundColor.opacity(0.7))
                .accessibilityHidden(true)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(bannerBackgroundColor)
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header row
            HStack(spacing: Spacing.sm) {
                Image(systemName: iconName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(iconForegroundColor)
                    .accessibilityHidden(true)

                Text(compactText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(textForegroundColor)

                Spacer()
            }

            // Most critical interaction detail
            if let message = mostCriticalMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(textForegroundColor.opacity(0.85))
                    .lineLimit(2)
                    .padding(.leading, Spacing.lg)
            }

            // "View all" link
            if interactionCount > 1 {
                HStack {
                    Spacer()
                    Text("View all \(interactionCount) interactions")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(textForegroundColor)
                        .underline()
                }
            } else if interactionCount == 1 {
                HStack {
                    Spacer()
                    Text("View details")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(textForegroundColor)
                        .underline()
                }
            }
        }
        .padding(Spacing.md)
        .background(bannerBackgroundColor)
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Styling Helpers

    private var iconName: String {
        switch safetyRating {
        case .safe:
            return "checkmark.shield.fill"
        case .caution:
            return "exclamationmark.triangle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .danger:
            return "xmark.octagon.fill"
        }
    }

    private var compactText: String {
        switch safetyRating {
        case .safe:
            return "All clear \u{2013} no interactions"
        case .caution, .warning, .danger:
            if interactionCount == 1 {
                return "1 interaction found"
            } else {
                return "\(interactionCount) interactions found"
            }
        }
    }

    private var bannerBackgroundColor: Color {
        switch safetyRating {
        case .safe:
            return Color.green.opacity(0.15)
        case .caution:
            return Color.yellow.opacity(0.2)
        case .warning:
            return Color.orange.opacity(0.2)
        case .danger:
            return Color.red.opacity(0.2)
        }
    }

    private var iconForegroundColor: Color {
        switch safetyRating {
        case .safe: return .green
        case .caution: return .yellow
        case .warning: return .orange
        case .danger: return .red
        }
    }

    private var textForegroundColor: Color {
        switch safetyRating {
        case .safe: return .green
        case .caution: return .brown
        case .warning: return .orange
        case .danger: return .red
        }
    }

    private var accessibilityDescription: String {
        switch safetyRating {
        case .safe:
            return "Safety status: safe. No supplement interactions detected."
        case .caution:
            let count = interactionCount == 1 ? "1 interaction" : "\(interactionCount) interactions"
            return "Safety status: caution. \(count) detected. Tap to review."
        case .warning:
            let count = interactionCount == 1 ? "1 interaction" : "\(interactionCount) interactions"
            return "Safety status: warning. \(count) detected. Tap to review."
        case .danger:
            let count = interactionCount == 1 ? "1 interaction" : "\(interactionCount) interactions"
            return "Safety status: danger. \(count) detected. Immediate review recommended."
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SafetyWarningBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.lg) {
            // Compact variants
            SafetyWarningBanner(
                safetyRating: .safe,
                interactionCount: 0,
                mostCriticalMessage: nil,
                onTap: {}
            )

            SafetyWarningBanner(
                safetyRating: .caution,
                interactionCount: 1,
                mostCriticalMessage: "Vitamin D and Magnesium may compete for absorption",
                onTap: {}
            )

            SafetyWarningBanner(
                safetyRating: .warning,
                interactionCount: 2,
                mostCriticalMessage: "Calcium can reduce iron absorption by up to 50%",
                onTap: {}
            )

            SafetyWarningBanner(
                safetyRating: .danger,
                interactionCount: 3,
                mostCriticalMessage: "St. John's Wort may dangerously interact with your medication",
                onTap: {}
            )

            Divider()
                .padding(.vertical, Spacing.sm)

            // Expanded variants
            SafetyWarningBanner(
                safetyRating: .warning,
                interactionCount: 2,
                mostCriticalMessage: "Calcium can reduce iron absorption by up to 50%",
                isExpanded: true,
                onTap: {}
            )

            SafetyWarningBanner(
                safetyRating: .danger,
                interactionCount: 3,
                mostCriticalMessage: "St. John's Wort may dangerously interact with your medication",
                isExpanded: true,
                onTap: {}
            )

            SafetyWarningBanner(
                safetyRating: .safe,
                interactionCount: 0,
                mostCriticalMessage: nil,
                isExpanded: true,
                onTap: {}
            )
        }
        .padding()
        .previewDisplayName("Safety Warning Banners")
    }
}
#endif
