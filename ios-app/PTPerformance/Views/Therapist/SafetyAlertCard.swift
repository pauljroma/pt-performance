//
//  SafetyAlertCard.swift
//  PTPerformance
//
//  Prominent safety alert card for therapist dashboard
//  Part of Risk Escalation System (M4) - X2Index Command Center
//

import SwiftUI

// MARK: - Safety Alert Card

/// Prominent alert card displayed on therapist dashboard when patients show concerning patterns
struct SafetyAlertCard: View {
    let escalation: RiskEscalation
    let patient: Patient?
    var onAcknowledge: (() -> Void)?
    var onCallPatient: (() -> Void)?
    var onViewDetails: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Severity banner
            HStack(spacing: Spacing.sm) {
                Image(systemName: severityIcon)
                    .font(.subheadline.weight(.semibold))

                Text(escalation.severity.displayName.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(0.5)

                Spacer()

                Text(escalation.timeSinceCreationText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(escalation.severity.color)

            // Content
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Patient info and type
                HStack(spacing: Spacing.md) {
                    // Patient avatar
                    if let patient = patient {
                        PatientAvatarView(patient: patient, size: 44)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 44, height: 44)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        if let patient = patient {
                            Text(patient.fullName)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }

                        HStack(spacing: Spacing.xs) {
                            Image(systemName: escalation.escalationType.iconName)
                                .font(.caption)
                                .foregroundColor(escalation.escalationType.color)

                            Text(escalation.escalationType.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Status badge
                    EscalationStatusBadge(status: escalation.status)
                }

                // Message
                Text(escalation.message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                // Recommendation
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)

                    Text(escalation.recommendation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Spacing.sm)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(CornerRadius.sm)

                // Action buttons
                HStack(spacing: Spacing.md) {
                    if !escalation.isAcknowledged {
                        Button(action: { onAcknowledge?() }) {
                            Label("Acknowledge", systemImage: "eye.fill")
                                .font(.subheadline.weight(.medium))
                        }
                        .buttonStyle(AlertActionButtonStyle(color: .modusCyan))
                    }

                    Button(action: { onCallPatient?() }) {
                        Label("Call", systemImage: "phone.fill")
                            .font(.subheadline.weight(.medium))
                    }
                    .buttonStyle(AlertActionButtonStyle(color: .green))

                    Spacer()

                    Button(action: { onViewDetails?() }) {
                        Label("Details", systemImage: "chevron.right")
                            .font(.subheadline.weight(.medium))
                    }
                    .buttonStyle(AlertActionButtonStyle(color: .secondary))
                }
            }
            .padding(Spacing.md)
        }
        .background(cardBackground)
        .cornerRadius(CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(escalation.severity.color.opacity(0.5), lineWidth: 2)
        )
        .adaptiveShadow(Shadow.medium)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap for actions")
    }

    // MARK: - Computed Properties

    private var severityIcon: String {
        switch escalation.severity {
        case .critical:
            return "exclamationmark.octagon.fill"
        case .high:
            return "exclamationmark.triangle.fill"
        case .medium:
            return "exclamationmark.circle.fill"
        case .low:
            return "info.circle.fill"
        }
    }

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color(.systemGray6)
            : Color(.systemBackground)
    }

    private var accessibilityLabel: String {
        var label = "\(escalation.severity.displayName) alert"
        if let patient = patient {
            label += " for \(patient.fullName)"
        }
        label += ". \(escalation.escalationType.displayName). \(escalation.message)"
        return label
    }
}

// MARK: - Escalation Status Badge

struct EscalationStatusBadge: View {
    let status: EscalationStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.iconName)
                .font(.caption2)

            Text(status.displayName)
                .font(.caption2.weight(.medium))
        }
        .foregroundColor(status.color)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(status.color.opacity(0.15))
        .cornerRadius(CornerRadius.xs)
    }
}

// MARK: - Patient Avatar View

struct PatientAvatarView: View {
    let patient: Patient
    var size: CGFloat = 40

    var body: some View {
        if let urlString = patient.profileImageUrl,
           let url = URL(string: urlString) {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                initialsView
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            initialsView
        }
    }

    private var initialsView: some View {
        Circle()
            .fill(LinearGradient(
                colors: [.modusCyan, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(width: size, height: size)
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.35, weight: .semibold))
                    .foregroundColor(.white)
            )
    }

    private var initials: String {
        let first = patient.firstName.prefix(1)
        let last = patient.lastName.prefix(1)
        return "\(first)\(last)".uppercased()
    }
}

// MARK: - Alert Action Button Style

struct AlertActionButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(color)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(color.opacity(configuration.isPressed ? 0.2 : 0.1))
            .cornerRadius(CornerRadius.sm)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Compact Safety Alert Row

/// Compact version for list display
struct SafetyAlertRow: View {
    let escalation: RiskEscalation
    let patientName: String?
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: Spacing.md) {
                // Severity indicator
                Circle()
                    .fill(escalation.severity.color)
                    .frame(width: 12, height: 12)

                // Type icon
                Image(systemName: escalation.escalationType.iconName)
                    .font(.subheadline)
                    .foregroundColor(escalation.escalationType.color)
                    .frame(width: 24)

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        if let name = patientName {
                            Text(name)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        Text(escalation.timeSinceCreationText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(escalation.escalationType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Safety Alerts Summary Banner

/// Summary banner showing total escalation counts
struct SafetyAlertsBanner: View {
    let summary: EscalationSummary
    var onTap: (() -> Void)?

    var body: some View {
        if summary.totalActive > 0 {
            Button(action: { onTap?() }) {
                HStack(spacing: Spacing.md) {
                    // Alert icon
                    ZStack {
                        Circle()
                            .fill(bannerColor.opacity(0.2))
                            .frame(width: 36, height: 36)

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundColor(bannerColor)
                    }

                    // Counts
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(summary.unacknowledgedCount) Safety Alert\(summary.unacknowledgedCount == 1 ? "" : "s")")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)

                        HStack(spacing: Spacing.sm) {
                            if summary.criticalCount > 0 {
                                CountBadge(count: summary.criticalCount, color: .red)
                            }
                            if summary.highCount > 0 {
                                CountBadge(count: summary.highCount, color: .orange)
                            }
                            if summary.mediumCount > 0 {
                                CountBadge(count: summary.mediumCount, color: .yellow)
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(Spacing.md)
                .background(bannerColor.opacity(0.1))
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(bannerColor.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var bannerColor: Color {
        if summary.criticalCount > 0 {
            return .red
        } else if summary.highCount > 0 {
            return .orange
        } else {
            return .yellow
        }
    }
}

// MARK: - Count Badge

struct CountBadge: View {
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text("\(count)")
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, 3)
        .background(color.opacity(0.15))
        .cornerRadius(CornerRadius.xs)
    }
}

// MARK: - Preview

#if DEBUG
struct SafetyAlertCard_Previews: PreviewProvider {
    static var sampleEscalation: RiskEscalation {
        RiskEscalation(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            escalationType: .painSpike,
            severity: .critical,
            triggerData: [
                "new_pain_level": .int(8),
                "previous_pain_level": .int(3),
                "increase": .int(5)
            ],
            message: "Pain level spiked from 3 to 8 (+5 points)",
            recommendation: "Immediate follow-up recommended. Review recent activities for potential injury or overuse.",
            createdAt: Date().addingTimeInterval(-3600),
            acknowledgedAt: nil,
            acknowledgedBy: nil,
            resolvedAt: nil,
            resolutionNotes: nil,
            status: .pending
        )
    }

    static var samplePatient: Patient {
        Patient(
            id: UUID(),
            therapistId: UUID(),
            firstName: "John",
            lastName: "Brebbia",
            email: "john@example.com",
            sport: "Baseball",
            position: "Pitcher",
            injuryType: "Elbow UCL",
            targetLevel: "MLB",
            profileImageUrl: nil,
            createdAt: Date(),
            flagCount: 2,
            highSeverityFlagCount: 1,
            adherencePercentage: 75.0,
            lastSessionDate: Date()
        )
    }

    static var previews: some View {
        VStack(spacing: Spacing.lg) {
            SafetyAlertCard(
                escalation: sampleEscalation,
                patient: samplePatient,
                onAcknowledge: { print("Acknowledge") },
                onCallPatient: { print("Call") },
                onViewDetails: { print("Details") }
            )

            // Different severity levels
            SafetyAlertCard(
                escalation: RiskEscalation(
                    id: UUID(),
                    patientId: UUID(),
                    therapistId: UUID(),
                    escalationType: .lowRecovery,
                    severity: .high,
                    triggerData: [:],
                    message: "Recovery score has been below 40% for 4 consecutive days",
                    recommendation: "Consider reducing training intensity.",
                    createdAt: Date().addingTimeInterval(-86400),
                    acknowledgedAt: Date(),
                    acknowledgedBy: UUID(),
                    resolvedAt: nil,
                    resolutionNotes: nil,
                    status: .acknowledged
                ),
                patient: samplePatient
            )

            SafetyAlertsBanner(
                summary: EscalationSummary(
                    totalActive: 5,
                    criticalCount: 1,
                    highCount: 2,
                    mediumCount: 2,
                    lowCount: 0,
                    unacknowledgedCount: 3,
                    patientsAffected: 3,
                    oldestUnacknowledgedDate: Date().addingTimeInterval(-7200)
                )
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
