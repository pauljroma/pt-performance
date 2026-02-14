//
//  AlertDetailSheet.swift
//  PTPerformance
//
//  Full alert detail sheet with patient information and actions.
//  Provides therapists with comprehensive exception details and intervention options.
//

import SwiftUI

// MARK: - AlertDetailSheet

struct AlertDetailSheet: View {
    let exception: PatientException
    var onAction: ((AlertAction) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    enum AlertAction {
        case viewPatient
        case sendMessage
        case scheduleCall
        case dismiss
        case markReviewed
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Patient header
                    patientHeader

                    // Alert details
                    alertDetailsCard

                    // Metrics section
                    if exception.currentPain != nil || exception.currentAdherence != nil {
                        metricsCard
                    }

                    // Timeline
                    timelineCard

                    // Recommended actions
                    recommendedActionsCard

                    // Quick actions
                    quickActionsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Alert Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { onAction?(.markReviewed); dismiss() }) {
                            Label("Mark as Reviewed", systemImage: "checkmark.circle")
                        }
                        Button(role: .destructive, action: { onAction?(.dismiss); dismiss() }) {
                            Label("Dismiss Alert", systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    // MARK: - Patient Header

    private var patientHeader: some View {
        HStack(spacing: Spacing.md) {
            // Avatar with severity ring
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
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
                } else {
                    initialsView
                }

                Circle()
                    .stroke(exception.severity.color, lineWidth: 4)
                    .frame(width: 76, height: 76)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(exception.patient.fullName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                if let sport = exception.patient.sport, let position = exception.patient.position {
                    Text("\(sport) - \(position)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let injury = exception.patient.injuryType {
                    Text(injury)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
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
                .frame(width: 70, height: 70)

            Text(exception.patient.initials)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }

    // MARK: - Alert Details Card

    private var alertDetailsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Severity badge
            HStack {
                severityBadge

                Spacer()

                Text(timeAgoText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Exception type
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(exception.exceptionType.color.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: exception.exceptionType.icon)
                        .font(.title3)
                        .foregroundColor(exception.exceptionType.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(exception.exceptionType.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(exception.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Days since last session
            HStack(spacing: Spacing.sm) {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)

                Text("Last active: \(daysSinceText)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private var severityBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: severityIcon)
                .font(.subheadline)

            Text("\(exception.severity.displayName) Priority")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
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

    // MARK: - Metrics Card

    private var metricsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Current Metrics")
                .font(.headline)

            HStack(spacing: Spacing.lg) {
                if let pain = exception.currentPain {
                    metricItem(
                        title: "Pain Level",
                        value: "\(Int(pain))/10",
                        trend: exception.painTrend,
                        color: painColor(for: pain)
                    )
                }

                if let adherence = exception.currentAdherence {
                    metricItem(
                        title: "Adherence",
                        value: "\(Int(adherence))%",
                        trend: exception.adherenceTrend,
                        color: adherenceColor(for: adherence)
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private func metricItem(title: String, value: String, trend: PatientException.TrendDirection?, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 6) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(trendColor(for: trend, metricType: title))
                        .padding(4)
                        .background(trendColor(for: trend, metricType: title).opacity(0.15))
                        .clipShape(Circle())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }

    private func trendColor(for trend: PatientException.TrendDirection, metricType: String) -> Color {
        // For pain, up is bad. For adherence, down is bad.
        if metricType == "Pain Level" {
            return trend == .up ? .red : .green
        } else {
            return trend == .down ? .red : .green
        }
    }

    // MARK: - Timeline Card

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Recent Activity")
                .font(.headline)

            VStack(spacing: 0) {
                timelineItem(
                    icon: "bell.badge.fill",
                    color: exception.severity.color,
                    title: "Alert Generated",
                    subtitle: timeAgoText,
                    isFirst: true,
                    isLast: false
                )

                timelineItem(
                    icon: "person.fill",
                    color: .blue,
                    title: "Last Session",
                    subtitle: daysSinceText,
                    isFirst: false,
                    isLast: false
                )

                timelineItem(
                    icon: "calendar",
                    color: .green,
                    title: "Patient Since",
                    subtitle: patientSinceText,
                    isFirst: false,
                    isLast: true
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private func timelineItem(icon: String, color: Color, title: String, subtitle: String, isFirst: Bool, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 2, height: 12)
                }

                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(color)
                }

                if !isLast {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 2, height: 12)
                }
            }
            .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)

            Spacer()
        }
    }

    // MARK: - Recommended Actions Card

    private var recommendedActionsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Recommended Actions")
                .font(.headline)

            VStack(spacing: Spacing.sm) {
                ForEach(recommendedActions, id: \.title) { action in
                    HStack(spacing: Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(action.color.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: action.icon)
                                .font(.subheadline)
                                .foregroundColor(action.color)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(action.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            Text(action.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.md)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private var recommendedActions: [(title: String, description: String, icon: String, color: Color)] {
        var actions: [(String, String, String, Color)] = []

        switch exception.exceptionType {
        case .painSpike, .painElevated:
            actions.append(("Review Pain Logs", "Check detailed pain reports", "waveform.path.ecg", .red))
            actions.append(("Adjust Program", "Consider modifying exercises", "slider.horizontal.3", .orange))
            actions.append(("Schedule Check-in", "Discuss concerns with patient", "phone.fill", .green))

        case .lowAdherence, .decliningAdherence:
            actions.append(("Send Reminder", "Encourage patient engagement", "bell.badge.fill", .orange))
            actions.append(("Review Schedule", "Check for scheduling conflicts", "calendar", .blue))
            actions.append(("Simplify Program", "Consider reducing complexity", "minus.circle", .purple))

        case .missedSession, .inactivity:
            actions.append(("Check In", "Reach out to patient", "message.fill", .blue))
            actions.append(("Review Barriers", "Identify obstacles to adherence", "magnifyingglass", .orange))
            actions.append(("Reschedule", "Set up new session time", "calendar.badge.plus", .green))
        }

        return actions
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(spacing: Spacing.md) {
            // Primary action
            Button(action: {
                HapticFeedback.medium()
                onAction?(.viewPatient)
                dismiss()
            }) {
                HStack {
                    Image(systemName: "person.circle.fill")
                    Text("View Patient Profile")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(CornerRadius.md)
            }

            // Secondary actions
            HStack(spacing: Spacing.md) {
                Button(action: {
                    HapticFeedback.light()
                    onAction?(.sendMessage)
                }) {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Message")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.md)
                }

                Button(action: {
                    HapticFeedback.light()
                    onAction?(.scheduleCall)
                }) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("Call")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.md)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var timeAgoText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: exception.createdAt, relativeTo: Date())
    }

    private var daysSinceText: String {
        let days = exception.daysSinceLastSession
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else if days == Int.max {
            return "No sessions"
        } else {
            return "\(days) days ago"
        }
    }

    private static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private var patientSinceText: String {
        Self.mediumDateFormatter.string(from: exception.patient.createdAt)
    }

    private func painColor(for pain: Double) -> Color {
        switch pain {
        case 0..<4: return .green
        case 4..<7: return .yellow
        default: return .red
        }
    }

    private func adherenceColor(for adherence: Double) -> Color {
        switch adherence {
        case 80...: return .green
        case 50..<80: return .yellow
        default: return .red
        }
    }
}

// MARK: - Preview

#if DEBUG
struct AlertDetailSheet_Previews: PreviewProvider {
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
                position: "Quarterback",
                injuryType: "Shoulder Impingement",
                targetLevel: "Pro",
                profileImageUrl: nil,
                createdAt: Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
                flagCount: 2,
                highSeverityFlagCount: 1,
                adherencePercentage: 35.0,
                lastSessionDate: Calendar.current.date(byAdding: .day, value: -12, to: Date())
            ),
            exceptionType: .painSpike,
            severity: .critical,
            message: "Reported severe shoulder pain (9/10) during rehabilitation exercises",
            daysSinceLastSession: 12,
            painTrend: .up,
            adherenceTrend: .down,
            currentPain: 9.0,
            currentAdherence: 35.0,
            createdAt: Date().addingTimeInterval(-7200)
        )
    }

    static var previews: some View {
        AlertDetailSheet(
            exception: sampleException,
            onAction: { _ in }
        )
    }
}
#endif
