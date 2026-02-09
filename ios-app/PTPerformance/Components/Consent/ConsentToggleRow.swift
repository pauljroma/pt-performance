//
//  ConsentToggleRow.swift
//  PTPerformance
//
//  X2Index Phase 2 - Consent Management (M1)
//  Reusable toggle row component for data source consent
//

import SwiftUI

/// Reusable toggle row for managing consent for a single data source
/// Displays icon, title, description, toggle switch, and status indicator
struct ConsentToggleRow: View {

    // MARK: - Properties

    let dataSource: DataSource
    let isEnabled: Bool
    let isToggling: Bool
    let lastUpdated: Date?
    let onToggle: () -> Void

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            iconView

            // Content
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                // Title row with status
                HStack {
                    Text(dataSource.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    // Status indicator
                    statusIndicator
                }

                // Description
                Text(dataSource.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                // Last synced date
                if let lastUpdated = lastUpdated {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("Updated \(formatDate(lastUpdated))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                }
            }

            // Toggle
            toggleView
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(cardBackground)
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isEnabled ? .isSelected : [])
    }

    // MARK: - Subviews

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 44, height: 44)

            Image(systemName: dataSource.iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(iconForegroundColor)
        }
    }

    private var statusIndicator: some View {
        Group {
            if isToggling {
                ProgressView()
                    .scaleEffect(0.7)
            } else if isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
    }

    private var toggleView: some View {
        Group {
            if isToggling {
                ProgressView()
                    .scaleEffect(0.8)
                    .frame(width: 51)
            } else {
                Toggle("", isOn: Binding(
                    get: { isEnabled },
                    set: { _ in
                        HapticFeedback.toggle()
                        onToggle()
                    }
                ))
                .labelsHidden()
                .tint(.modusCyan)
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: CornerRadius.md)
            .fill(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Computed Properties

    private var iconBackgroundColor: Color {
        switch dataSource.iconColor {
        case "modusCyan":
            return Color.modusCyan.opacity(0.15)
        case "red":
            return Color.red.opacity(0.15)
        case "modusTealAccent":
            return Color.modusTealAccent.opacity(0.15)
        case "modusDeepTeal":
            return Color.modusDeepTeal.opacity(0.15)
        default:
            return Color.gray.opacity(0.15)
        }
    }

    private var iconForegroundColor: Color {
        switch dataSource.iconColor {
        case "modusCyan":
            return Color.modusCyan
        case "red":
            return Color.red
        case "modusTealAccent":
            return Color.modusTealAccent
        case "modusDeepTeal":
            return Color.modusDeepTeal
        default:
            return Color.gray
        }
    }

    // MARK: - Helper Methods

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        let statusText = isEnabled ? "enabled" : "disabled"
        return "\(dataSource.displayName) data access is \(statusText). \(dataSource.description)"
    }

    private var accessibilityHint: String {
        if isToggling {
            return "Updating consent status"
        }
        return isEnabled ? "Double tap to revoke access" : "Double tap to grant access"
    }
}

// MARK: - Compact Variant

/// Compact version of the consent toggle row for use in lists
struct ConsentToggleRowCompact: View {

    // MARK: - Properties

    let dataSource: DataSource
    let isEnabled: Bool
    let isToggling: Bool
    let onToggle: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Icon
            Image(systemName: dataSource.iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 28)

            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text(dataSource.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                if isEnabled {
                    Text("Connected")
                        .font(.caption2)
                        .foregroundColor(.green)
                } else {
                    Text("Not connected")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Toggle
            if isToggling {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                Toggle("", isOn: Binding(
                    get: { isEnabled },
                    set: { _ in
                        HapticFeedback.toggle()
                        onToggle()
                    }
                ))
                .labelsHidden()
                .tint(.modusCyan)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dataSource.displayName): \(isEnabled ? "Connected" : "Not connected")")
        .accessibilityHint(isEnabled ? "Double tap to disconnect" : "Double tap to connect")
    }

    // MARK: - Computed Properties

    private var iconColor: Color {
        switch dataSource.iconColor {
        case "modusCyan":
            return Color.modusCyan
        case "red":
            return Color.red
        case "modusTealAccent":
            return Color.modusTealAccent
        case "modusDeepTeal":
            return Color.modusDeepTeal
        default:
            return Color.gray
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ConsentToggleRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Standard variant
            VStack(spacing: 16) {
                ConsentToggleRow(
                    dataSource: .whoop,
                    isEnabled: true,
                    isToggling: false,
                    lastUpdated: Date().addingTimeInterval(-3600),
                    onToggle: {}
                )

                ConsentToggleRow(
                    dataSource: .appleHealth,
                    isEnabled: false,
                    isToggling: false,
                    lastUpdated: nil,
                    onToggle: {}
                )

                ConsentToggleRow(
                    dataSource: .labResults,
                    isEnabled: true,
                    isToggling: true,
                    lastUpdated: Date().addingTimeInterval(-86400),
                    onToggle: {}
                )
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .previewDisplayName("Standard")

            // Compact variant
            VStack(spacing: 12) {
                ConsentToggleRowCompact(
                    dataSource: .whoop,
                    isEnabled: true,
                    isToggling: false,
                    onToggle: {}
                )

                ConsentToggleRowCompact(
                    dataSource: .appleHealth,
                    isEnabled: false,
                    isToggling: false,
                    onToggle: {}
                )

                ConsentToggleRowCompact(
                    dataSource: .labResults,
                    isEnabled: true,
                    isToggling: true,
                    onToggle: {}
                )
            }
            .padding()
            .previewDisplayName("Compact")

            // Dark mode
            VStack(spacing: 16) {
                ConsentToggleRow(
                    dataSource: .whoop,
                    isEnabled: true,
                    isToggling: false,
                    lastUpdated: Date().addingTimeInterval(-3600),
                    onToggle: {}
                )
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
#endif
