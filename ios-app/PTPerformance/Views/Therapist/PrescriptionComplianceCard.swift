//
//  PrescriptionComplianceCard.swift
//  PTPerformance
//
//  Reusable card component for displaying prescription compliance status
//  Shows patient info, prescription details, status, and quick actions
//

import SwiftUI

// MARK: - Prescription Compliance Card

/// Card component showing prescription status with patient info and actions
struct PrescriptionComplianceCard: View {
    let item: PrescriptionWithPatient
    let onRemind: () -> Void
    let onCancel: () -> Void
    let onExtend: () -> Void
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var showingActions = false

    private var prescription: WorkoutPrescription { item.prescription }
    private var patient: Patient { item.patient }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Patient info and status
                headerSection

                // Prescription details
                prescriptionDetailsSection

                // Due date with urgency indicator
                if let dueDate = prescription.dueDate {
                    dueDateSection(dueDate)
                }

                // Quick actions
                actionsSection
            }
            .padding(16)
            .background(cardBackground)
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(borderColor, lineWidth: prescription.isOverdue ? 2 : 1)
            )
            .adaptiveShadow(Shadow.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to view details")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 12) {
            // Patient avatar
            patientAvatar

            // Patient name and info
            VStack(alignment: .leading, spacing: 2) {
                Text(patient.fullName)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if let sport = patient.sport, let position = patient.position {
                    Text("\(sport) - \(position)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else if let sport = patient.sport {
                    Text(sport)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Status badge
            statusBadge
        }
    }

    private var patientAvatar: some View {
        ZStack {
            Circle()
                .fill(avatarGradient)
                .frame(width: 44, height: 44)

            Text(patient.initials)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .accessibilityHidden(true)
    }

    private var avatarGradient: LinearGradient {
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.caption2)

            Text(statusText)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.15))
        .foregroundColor(statusColor)
        .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Prescription Details Section

    private var prescriptionDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Prescription name
            Text(prescription.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            // Priority badge
            HStack(spacing: 8) {
                priorityBadge

                if let instructions = prescription.instructions, !instructions.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "text.bubble")
                            .font(.caption2)
                        Text("Has instructions")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
    }

    private var priorityBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)

            Text(prescription.priority.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(priorityColor.opacity(0.1))
        .foregroundColor(priorityColor)
        .cornerRadius(CornerRadius.xs)
    }

    // MARK: - Due Date Section

    private func dueDateSection(_ dueDate: Date) -> some View {
        HStack(spacing: 8) {
            // Urgency indicator bar
            RoundedRectangle(cornerRadius: 2)
                .fill(urgencyColor(for: dueDate))
                .frame(width: 4, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(dueDateLabel(for: dueDate))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(urgencyColor(for: dueDate))

                Text(formatDueDate(dueDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Days indicator
            if let days = prescription.daysUntilDue {
                daysIndicator(days)
            }
        }
        .padding(10)
        .background(urgencyBackgroundColor(for: dueDate))
        .cornerRadius(CornerRadius.sm)
    }

    private func daysIndicator(_ days: Int) -> some View {
        VStack(spacing: 2) {
            Text(abs(days).description)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(days < 0 ? .red : (days == 0 ? .orange : .primary))

            Text(days < 0 ? "days late" : (days == 0 ? "today" : (days == 1 ? "day left" : "days left")))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        HStack(spacing: 12) {
            // Remind button
            if prescription.status != .completed && prescription.status != .cancelled {
                actionButton(
                    icon: "bell",
                    title: "Remind",
                    color: .blue,
                    action: {
                        HapticFeedback.light()
                        onRemind()
                    }
                )
            }

            // Extend button
            if prescription.status != .completed && prescription.status != .cancelled {
                actionButton(
                    icon: "calendar.badge.plus",
                    title: "Extend",
                    color: .green,
                    action: {
                        HapticFeedback.light()
                        onExtend()
                    }
                )
            }

            Spacer()

            // Cancel button
            if prescription.status != .completed && prescription.status != .cancelled {
                actionButton(
                    icon: "xmark",
                    title: "Cancel",
                    color: .red,
                    action: {
                        HapticFeedback.medium()
                        onCancel()
                    }
                )
            }
        }
    }

    private func actionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(CornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(title) prescription")
    }

    // MARK: - Computed Properties

    private var cardBackground: Color {
        prescription.isOverdue
            ? Color.red.opacity(colorScheme == .dark ? 0.1 : 0.05)
            : Color(.systemBackground)
    }

    private var borderColor: Color {
        prescription.isOverdue ? .red.opacity(0.5) : Color(.separator).opacity(0.3)
    }

    private var statusText: String {
        if prescription.isOverdue {
            return "Overdue"
        }
        return prescription.status.displayName
    }

    private var statusIcon: String {
        if prescription.isOverdue {
            return "exclamationmark.triangle.fill"
        }
        switch prescription.status {
        case .pending: return "clock"
        case .viewed: return "eye"
        case .started: return "play.circle"
        case .completed: return "checkmark.circle.fill"
        case .expired: return "xmark.circle"
        case .cancelled: return "xmark.circle"
        }
    }

    private var statusColor: Color {
        if prescription.isOverdue {
            return .red
        }
        switch prescription.status {
        case .pending: return .blue
        case .viewed: return .purple
        case .started: return .orange
        case .completed: return .green
        case .expired: return .gray
        case .cancelled: return .gray
        }
    }

    private var priorityColor: Color {
        switch prescription.priority {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }

    private func urgencyColor(for dueDate: Date) -> Color {
        if prescription.isOverdue { return .red }

        let calendar = Calendar.current
        if calendar.isDateInToday(dueDate) { return .orange }
        if calendar.isDateInTomorrow(dueDate) { return .blue }

        guard let days = prescription.daysUntilDue else { return .secondary }
        if days <= 3 { return .orange }

        return .secondary
    }

    private func urgencyBackgroundColor(for dueDate: Date) -> Color {
        urgencyColor(for: dueDate).opacity(colorScheme == .dark ? 0.15 : 0.08)
    }

    private func dueDateLabel(for dueDate: Date) -> String {
        if prescription.isOverdue { return "OVERDUE" }

        let calendar = Calendar.current
        if calendar.isDateInToday(dueDate) { return "DUE TODAY" }
        if calendar.isDateInTomorrow(dueDate) { return "DUE TOMORROW" }

        guard let days = prescription.daysUntilDue else { return "DUE DATE" }
        if days <= 3 { return "DUE SOON" }

        return "DUE DATE"
    }

    private static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private func formatDueDate(_ date: Date) -> String {
        Self.mediumDateFormatter.string(from: date)
    }

    private var accessibilityDescription: String {
        var parts: [String] = []
        parts.append("Prescription for \(patient.fullName)")
        parts.append(prescription.name)
        parts.append("Status: \(statusText)")
        parts.append("Priority: \(prescription.priority.displayName)")

        if let dueDate = prescription.dueDate {
            parts.append("Due: \(formatDueDate(dueDate))")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Compact Prescription Card

/// Smaller card variant for list display
struct CompactPrescriptionCard: View {
    let item: PrescriptionWithPatient
    let onTap: () -> Void

    private static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private var prescription: WorkoutPrescription { item.prescription }
    private var patient: Patient { item.patient }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)

                // Patient initials
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(patient.initials)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(patient.fullName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(prescription.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Due date or status
                VStack(alignment: .trailing, spacing: 2) {
                    if prescription.isOverdue {
                        Text("Overdue")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    } else if let dueDate = prescription.dueDate {
                        Text(formatRelativeDate(dueDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(prescription.status.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var statusColor: Color {
        if prescription.isOverdue { return .red }
        switch prescription.status {
        case .pending: return .blue
        case .viewed: return .purple
        case .started: return .orange
        case .completed: return .green
        case .expired, .cancelled: return .gray
        }
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }

        if let days = calendar.dateComponents([.day], from: Date(), to: date).day {
            if days < 0 { return "\(abs(days))d late" }
            if days <= 7 { return "In \(days)d" }
        }

        return Self.monthDayFormatter.string(from: date)
    }
}

// MARK: - Prescription Stats Card

/// Card showing prescription statistics summary
struct PrescriptionStatsCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)

                Spacer()
            }

            Text("\(count)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }
        }
        .frame(width: 130)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
    }
}

// MARK: - Preview

#if DEBUG
struct PrescriptionComplianceCard_Previews: PreviewProvider {
    static var samplePrescription: WorkoutPrescription {
        WorkoutPrescription(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            templateId: UUID(),
            templateType: "system",
            name: "Upper Body Recovery",
            instructions: "Focus on proper form and controlled movements",
            dueDate: Date().addingTimeInterval(86400),
            priority: .high,
            status: .viewed,
            manualSessionId: nil,
            prescribedAt: Date().addingTimeInterval(-86400 * 3),
            viewedAt: Date().addingTimeInterval(-86400),
            startedAt: nil,
            completedAt: nil,
            createdAt: Date().addingTimeInterval(-86400 * 3)
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
            injuryType: "Tommy John",
            targetLevel: "MLB",
            profileImageUrl: nil,
            createdAt: Date(),
            flagCount: 0,
            highSeverityFlagCount: 0,
            adherencePercentage: 85,
            lastSessionDate: Date()
        )
    }

    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Full card
                PrescriptionComplianceCard(
                    item: PrescriptionWithPatient(
                        prescription: samplePrescription,
                        patient: samplePatient
                    ),
                    onRemind: {},
                    onCancel: {},
                    onExtend: {},
                    onTap: {}
                )

                // Overdue card
                PrescriptionComplianceCard(
                    item: PrescriptionWithPatient(
                        prescription: WorkoutPrescription(
                            id: UUID(),
                            patientId: UUID(),
                            therapistId: UUID(),
                            templateId: UUID(),
                            templateType: "system",
                            name: "Core Stability",
                            instructions: nil,
                            dueDate: Date().addingTimeInterval(-86400 * 2),
                            priority: .urgent,
                            status: .pending,
                            manualSessionId: nil,
                            prescribedAt: Date().addingTimeInterval(-86400 * 5),
                            viewedAt: nil,
                            startedAt: nil,
                            completedAt: nil,
                            createdAt: Date().addingTimeInterval(-86400 * 5)
                        ),
                        patient: samplePatient
                    ),
                    onRemind: {},
                    onCancel: {},
                    onExtend: {},
                    onTap: {}
                )

                // Compact cards
                VStack(spacing: 8) {
                    CompactPrescriptionCard(
                        item: PrescriptionWithPatient(
                            prescription: samplePrescription,
                            patient: samplePatient
                        ),
                        onTap: {}
                    )

                    CompactPrescriptionCard(
                        item: PrescriptionWithPatient(
                            prescription: WorkoutPrescription(
                                id: UUID(),
                                patientId: UUID(),
                                therapistId: UUID(),
                                templateId: nil,
                                templateType: nil,
                                name: "Shoulder Mobility",
                                instructions: nil,
                                dueDate: Date(),
                                priority: .medium,
                                status: .completed,
                                manualSessionId: nil,
                                prescribedAt: Date().addingTimeInterval(-86400 * 7),
                                viewedAt: Date().addingTimeInterval(-86400 * 6),
                                startedAt: Date().addingTimeInterval(-86400),
                                completedAt: Date(),
                                createdAt: Date().addingTimeInterval(-86400 * 7)
                            ),
                            patient: samplePatient
                        ),
                        onTap: {}
                    )
                }

                // Stats cards
                HStack(spacing: 12) {
                    PrescriptionStatsCard(
                        title: "Active",
                        count: 12,
                        icon: "doc.badge.clock",
                        color: .blue,
                        subtitle: "prescriptions"
                    )

                    PrescriptionStatsCard(
                        title: "Overdue",
                        count: 3,
                        icon: "exclamationmark.triangle",
                        color: .red,
                        subtitle: "need attention"
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
