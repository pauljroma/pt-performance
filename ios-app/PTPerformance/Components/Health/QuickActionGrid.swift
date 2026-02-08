//
//  QuickActionGrid.swift
//  PTPerformance
//
//  Reusable grid of quick action buttons for Health Hub
//  Provides one-tap access to key health modules
//

import SwiftUI

/// Quick action item model for the grid
struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let gradient: [Color]
    let action: QuickActionType

    enum QuickActionType {
        case startFast
        case logSupplements
        case logRecovery
        case viewLabs
        case viewBiomarkers
        case aiCoach
    }
}

/// Reusable grid of quick action buttons
/// Used in Health Hub for one-tap access to modules
struct QuickActionGrid: View {
    let actions: [QuickAction]
    let onAction: (QuickAction.QuickActionType) -> Void

    /// Default quick actions for Health Hub
    static var defaultActions: [QuickAction] {
        [
            QuickAction(
                title: "Start Fast",
                icon: "fork.knife.circle.fill",
                color: .teal,
                gradient: [.teal, .cyan],
                action: .startFast
            ),
            QuickAction(
                title: "Log Supplements",
                icon: "pill.fill",
                color: .orange,
                gradient: [.orange, .yellow],
                action: .logSupplements
            ),
            QuickAction(
                title: "Log Recovery",
                icon: "heart.fill",
                color: .pink,
                gradient: [.pink, .red.opacity(0.8)],
                action: .logRecovery
            ),
            QuickAction(
                title: "View Labs",
                icon: "cross.case.fill",
                color: .red,
                gradient: [.red, .pink],
                action: .viewLabs
            )
        ]
    }

    /// Expanded quick actions including biomarkers and AI coach
    static var expandedActions: [QuickAction] {
        defaultActions + [
            QuickAction(
                title: "Biomarkers",
                icon: "chart.bar.doc.horizontal.fill",
                color: .modusCyan,
                gradient: [.modusCyan, .modusTealAccent],
                action: .viewBiomarkers
            ),
            QuickAction(
                title: "AI Coach",
                icon: "sparkles",
                color: .purple,
                gradient: [.purple, .indigo],
                action: .aiCoach
            )
        ]
    }

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var columns: [GridItem] {
        // Adapt grid columns based on size class
        if horizontalSizeClass == .regular {
            return [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        } else {
            return [
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.sm) {
            ForEach(actions) { action in
                HealthQuickActionButton(action: action) {
                    HapticFeedback.medium()
                    onAction(action.action)
                }
            }
        }
    }
}

/// Individual quick action button with gradient and animation
struct HealthQuickActionButton: View {
    let action: QuickAction
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: action.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(
                            color: action.color.opacity(0.3),
                            radius: 4,
                            x: 0,
                            y: 2
                        )

                    Image(systemName: action.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .accessibilityHidden(true)

                Text(action.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                        isPressed = false
                    }
                }
        )
        .accessibilityLabel(action.title)
        .accessibilityHint("Tap to \(accessibilityHint(for: action.action))")
    }

    private func accessibilityHint(for type: QuickAction.QuickActionType) -> String {
        switch type {
        case .startFast:
            return "start a new fasting session"
        case .logSupplements:
            return "log your supplements"
        case .logRecovery:
            return "log a recovery session"
        case .viewLabs:
            return "view your lab results"
        case .viewBiomarkers:
            return "view your biomarker dashboard"
        case .aiCoach:
            return "open AI health coach"
        }
    }
}

/// Compact horizontal quick action bar for smaller spaces
struct QuickActionBar: View {
    let actions: [QuickAction]
    let onAction: (QuickAction.QuickActionType) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(actions) { action in
                    CompactQuickActionButton(action: action) {
                        HapticFeedback.medium()
                        onAction(action.action)
                    }
                }
            }
            .padding(.horizontal, Spacing.xxs)
        }
    }
}

/// Compact quick action button for horizontal scrolling
private struct CompactQuickActionButton: View {
    let action: QuickAction
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: action.icon)
                    .font(.subheadline)
                    .foregroundColor(action.color)

                Text(action.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(action.color.opacity(0.1))
            .cornerRadius(CornerRadius.lg)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(action.title)
    }
}

// MARK: - Preview

#if DEBUG
struct QuickActionGrid_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.lg) {
            Text("Quick Action Grid")
                .font(.headline)

            QuickActionGrid(
                actions: QuickActionGrid.defaultActions,
                onAction: { _ in }
            )
            .padding()

            Divider()

            Text("Quick Action Bar")
                .font(.headline)

            QuickActionBar(
                actions: QuickActionGrid.defaultActions,
                onAction: { _ in }
            )
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
