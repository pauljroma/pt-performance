//
//  PatientExceptionCard.swift
//  PTPerformance
//
//  Card component showing a patient exception with severity,
//  trends, and quick actions for the coaching dashboard.
//

import SwiftUI

// MARK: - PatientExceptionCard

struct PatientExceptionCard: View {
    let exception: PatientException
    var onTap: (() -> Void)?
    var onNavigate: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            Button(action: {
                HapticFeedback.light()
                onTap?()
            }) {
                VStack(spacing: Spacing.md) {
                    // Header row
                    headerRow

                    // Exception reasons
                    exceptionBadges

                    // Trends row
                    if exception.painTrend != nil || exception.adherenceTrend != nil {
                        trendsRow
                    }

                    // Footer with days since session
                    footerRow
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded actions (optional)
            if isExpanded {
                Divider()

                expandedActions
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(severityBorderColor, lineWidth: 2)
        )
        .adaptiveShadow(Shadow.medium)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap for details")
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(spacing: Spacing.md) {
            // Patient avatar
            patientAvatar

            // Patient info
            VStack(alignment: .leading, spacing: 4) {
                Text(exception.patient.fullName)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if let sport = exception.patient.sport {
                    Text(sport)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Severity indicator
            severityBadge
        }
    }

    private var patientAvatar: some View {
        ZStack {
            if let imageUrl = exception.patient.profileImageUrl,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialsView
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                initialsView
            }

            // Severity ring
            Circle()
                .stroke(exception.severity.color, lineWidth: 3)
                .frame(width: 54, height: 54)
        }
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [exception.severity.color.opacity(0.6), exception.severity.color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)

            Text(exception.patient.initials)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }

    private var severityBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: severityIcon)
                .font(.caption)

            Text(exception.severity.displayName)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 6)
        .background(exception.severity.color)
        .cornerRadius(CornerRadius.sm)
    }

    private var severityIcon: String {
        switch exception.severity {
        case .critical: return "exclamationmark.octagon.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .low: return "info.circle.fill"
        }
    }

    // MARK: - Exception Badges

    private var exceptionBadges: some View {
        HStack(spacing: Spacing.xs) {
            // Exception type badge
            HStack(spacing: 4) {
                Image(systemName: exception.exceptionType.icon)
                    .font(.caption)
                Text(exception.exceptionType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(exception.exceptionType.color)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 6)
            .background(exception.exceptionType.color.opacity(0.15))
            .cornerRadius(CornerRadius.xs)

            Spacer()

            // Time ago
            Text(timeAgoText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Trends Row

    private var trendsRow: some View {
        HStack(spacing: Spacing.lg) {
            if let painTrend = exception.painTrend, let currentPain = exception.currentPain {
                trendIndicator(
                    label: "Pain",
                    value: "\(Int(currentPain))/10",
                    trend: painTrend,
                    isBad: painTrend == .improving
                )
            }

            if let adherenceTrend = exception.adherenceTrend, let currentAdherence = exception.currentAdherence {
                trendIndicator(
                    label: "Adherence",
                    value: "\(Int(currentAdherence))%",
                    trend: adherenceTrend,
                    isBad: adherenceTrend == .declining
                )
            }

            Spacer()
        }
    }

    private func trendIndicator(label: String, value: String, trend: PatientException.TrendDirection, isBad: Bool) -> some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            // Trend arrow
            Image(systemName: trend.icon)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(isBad ? .red : .green)
                .padding(Spacing.xxs)
                .background((isBad ? Color.red : Color.green).opacity(0.15))
                .clipShape(Circle())
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Footer Row

    private var footerRow: some View {
        HStack {
            // Days since last session
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption)
                Text(daysSinceText)
                    .font(.caption)
            }
            .foregroundColor(.secondary)

            Spacer()

            // Navigate button
            Button(action: {
                HapticFeedback.medium()
                onNavigate?()
            }) {
                HStack(spacing: 4) {
                    Text("View Profile")
                        .font(.caption)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                }
                .foregroundColor(.modusCyan)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Expanded Actions

    private var expandedActions: some View {
        HStack(spacing: Spacing.md) {
            actionButton(icon: "message.fill", title: "Message", color: .modusCyan) {
                // Send message action
            }

            actionButton(icon: "phone.fill", title: "Call", color: .green) {
                // Schedule call action
            }

            actionButton(icon: "checkmark.circle.fill", title: "Mark Reviewed", color: .purple) {
                // Mark as reviewed
            }
        }
        .padding()
    }

    private func actionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Computed Properties

    private var severityBorderColor: Color {
        exception.severity.color.opacity(colorScheme == .dark ? 0.4 : 0.3)
    }

    private var timeAgoText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: exception.createdAt, relativeTo: Date())
    }

    private var daysSinceText: String {
        let days = exception.daysSinceLastSession
        if days == 0 {
            return "Active today"
        } else if days == 1 {
            return "1 day ago"
        } else if days == Int.max {
            return "No sessions"
        } else {
            return "\(days) days ago"
        }
    }

    private var accessibilityLabel: String {
        var label = "\(exception.patient.fullName), \(exception.severity.displayName) severity"
        label += ", \(exception.exceptionType.rawValue)"
        if let pain = exception.currentPain {
            label += ", pain level \(Int(pain)) out of 10"
        }
        if let adherence = exception.currentAdherence {
            label += ", \(Int(adherence)) percent adherence"
        }
        label += ", last active \(daysSinceText)"
        return label
    }
}

// MARK: - Compact Exception Row

/// A more compact version for lists
struct CompactExceptionRow: View {
    let exception: PatientException
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap?()
        }) {
            HStack(spacing: Spacing.md) {
                // Severity indicator
                Circle()
                    .fill(exception.severity.color)
                    .frame(width: 12, height: 12)

                // Patient name
                Text(exception.patient.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // Exception badge
                Text(exception.exceptionType.rawValue)
                    .font(.caption2)
                    .foregroundColor(exception.exceptionType.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(exception.exceptionType.color.opacity(0.15))
                    .cornerRadius(CornerRadius.xs)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#if DEBUG
struct PatientExceptionCard_Previews: PreviewProvider {
    static var sampleException: PatientException {
        PatientException(
            id: UUID(),
            patient: Patient(
                id: UUID(),
                therapistId: UUID(),
                firstName: "Mike",
                lastName: "Williams",
                email: "mike@example.com",
                sport: "Football",
                position: "QB",
                injuryType: "Shoulder",
                targetLevel: "Pro",
                profileImageUrl: nil,
                createdAt: Date(),
                flagCount: 2,
                highSeverityFlagCount: 1,
                adherencePercentage: 35.0,
                lastSessionDate: Calendar.current.date(byAdding: .day, value: -12, to: Date())
            ),
            exceptionType: .lowAdherence,
            severity: .critical,
            message: "Adherence has dropped to 35%",
            daysSinceLastSession: 12,
            painTrend: .improving,
            adherenceTrend: .declining,
            currentPain: 7.0,
            currentAdherence: 35.0,
            createdAt: Date().addingTimeInterval(-7200)
        )
    }

    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                PatientExceptionCard(
                    exception: sampleException,
                    onTap: { },
                    onNavigate: { }
                )

                CompactExceptionRow(
                    exception: sampleException,
                    onTap: { }
                )
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(CornerRadius.md)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
