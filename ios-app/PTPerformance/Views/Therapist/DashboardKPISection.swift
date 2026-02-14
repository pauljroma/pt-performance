//
//  DashboardKPISection.swift
//  PTPerformance
//
//  Enhanced dashboard KPI section for therapists
//  Displays key metrics, quick actions, and today's schedule
//

import SwiftUI

// MARK: - Dashboard KPI Section

struct DashboardKPISection: View {
    let patients: [Patient]
    let activeFlags: [WorkloadFlag]
    let upcomingSessions: [TherapistSessionItem]

    var onAddPatient: () -> Void
    var onCreateProgram: () -> Void
    var onCreateTemplate: (() -> Void)?
    var onViewReports: () -> Void
    var onViewAnalytics: (() -> Void)?
    var onSessionTap: ((TherapistSessionItem) -> Void)?

    // MARK: - Computed Properties

    private var totalActivePatients: Int {
        patients.count
    }

    private var patientTrend: Int {
        // Simulate week-over-week trend (in production, this would come from actual data)
        // Positive = gained patients, negative = lost patients
        0
    }

    private var averageAdherence: Double? {
        let values = patients.compactMap { $0.adherencePercentage }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private var highPriorityAlertCount: Int {
        activeFlags.filter { flag in
            flag.severity == .critical
        }.count
    }

    private var sessionsThisWeek: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return 0
        }

        return upcomingSessions.filter { item in
            let sessionDate = item.session.scheduledDate
            return sessionDate >= weekStart && sessionDate < weekEnd
        }.count
    }

    private var todaysSessions: [TherapistSessionItem] {
        let calendar = Calendar.current
        return upcomingSessions
            .filter { calendar.isDateInToday($0.session.scheduledDate) }
            .sorted { $0.session.scheduledTime < $1.session.scheduledTime }
    }

    private var nextThreeAppointments: [TherapistSessionItem] {
        Array(todaysSessions.prefix(3))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // KPI Cards Section
            kpiCardsSection

            // Quick Actions Section
            quickActionsSection

            // Today's Schedule Preview
            if !nextThreeAppointments.isEmpty {
                schedulePreviewSection
            }
        }
    }

    // MARK: - KPI Cards Section

    private var kpiCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Total Active Patients
                    KPICard(
                        icon: "person.2.fill",
                        title: "Active Patients",
                        value: "\(totalActivePatients)",
                        trend: patientTrend,
                        trendLabel: "vs last week",
                        accentColor: .blue
                    )
                    .accessibilityLabel("Total active patients: \(totalActivePatients)")

                    // Average Adherence
                    KPICard(
                        icon: "checkmark.circle.fill",
                        title: "Avg Adherence",
                        value: averageAdherence.map { "\(Int($0))%" } ?? "N/A",
                        trend: nil,
                        trendLabel: nil,
                        accentColor: adherenceColor(for: averageAdherence)
                    )
                    .accessibilityLabel("Average adherence: \(averageAdherence.map { "\(Int($0)) percent" } ?? "Not available")")

                    // High Priority Alerts
                    KPICard(
                        icon: "exclamationmark.triangle.fill",
                        title: "Priority Alerts",
                        value: "\(highPriorityAlertCount)",
                        trend: nil,
                        trendLabel: nil,
                        accentColor: highPriorityAlertCount > 0 ? .red : .green
                    )
                    .accessibilityLabel("High priority alerts: \(highPriorityAlertCount)")

                    // Sessions This Week
                    KPICard(
                        icon: "calendar.badge.clock",
                        title: "This Week",
                        value: "\(sessionsThisWeek)",
                        trend: nil,
                        trendLabel: "sessions",
                        accentColor: .purple
                    )
                    .accessibilityLabel("Sessions this week: \(sessionsThisWeek)")
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            // First row of actions
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "person.badge.plus",
                    title: "Add Patient",
                    color: .modusCyan,
                    action: onAddPatient
                )
                .accessibilityLabel("Add new patient")
                .accessibilityHint("Opens the add patient form")

                QuickActionButton(
                    icon: "doc.badge.plus",
                    title: "Create Program",
                    color: .green,
                    action: onCreateProgram
                )
                .accessibilityLabel("Create new program")
                .accessibilityHint("Opens the program builder")

                QuickActionButton(
                    icon: "chart.bar.doc.horizontal",
                    title: "View Reports",
                    color: .orange,
                    action: onViewReports
                )
                .accessibilityLabel("View reports")
                .accessibilityHint("Opens the reporting dashboard")
            }
            .padding(.horizontal)

            // Second row with template builder and analytics
            HStack(spacing: 12) {
                if let onCreateTemplate = onCreateTemplate {
                    QuickActionButton(
                        icon: "dumbbell.fill",
                        title: "Create Template",
                        color: .purple,
                        action: onCreateTemplate
                    )
                    .accessibilityLabel("Create workout template")
                    .accessibilityHint("Opens the workout template builder")
                }

                if let onViewAnalytics = onViewAnalytics {
                    QuickActionButton(
                        icon: "chart.bar.xaxis",
                        title: "Analytics",
                        color: .teal,
                        action: onViewAnalytics
                    )
                    .accessibilityLabel("View program analytics")
                    .accessibilityHint("Opens the program analytics dashboard")
                }

                // Placeholder for balance (hidden but maintains grid alignment)
                if onCreateTemplate == nil || onViewAnalytics == nil {
                    Color.clear
                        .frame(maxWidth: .infinity)
                }

                if onCreateTemplate == nil && onViewAnalytics == nil {
                    Color.clear
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Schedule Preview Section

    private var schedulePreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Schedule")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                if todaysSessions.count > 3 {
                    Text("+\(todaysSessions.count - 3) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(nextThreeAppointments, id: \.session.id) { item in
                    SchedulePreviewRow(item: item)
                        .onTapGesture {
                            onSessionTap?(item)
                        }
                        .accessibilityLabel("Appointment with \(item.patient.fullName) at \(item.session.formattedTime)")
                        .accessibilityHint("Tap to view appointment details")
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Helper Methods

    private func adherenceColor(for percentage: Double?) -> Color {
        guard let percentage = percentage else { return .gray }
        switch percentage {
        case 80...: return .green
        case 50..<80: return .yellow
        default: return .red
        }
    }
}

// MARK: - KPI Card Component

struct KPICard: View {
    let icon: String
    let title: String
    let value: String
    let trend: Int?
    let trendLabel: String?
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(accentColor)

                Spacer()

                if let trend = trend, trend != 0 {
                    KPITrendBadge(value: trend)
                }
            }

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let trendLabel = trendLabel {
                    Text(trendLabel)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }
        }
        .frame(width: 140)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
    }
}

// MARK: - KPI Trend Badge Component

struct KPITrendBadge: View {
    let value: Int

    private var isPositive: Bool { value > 0 }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.caption2)

            Text("\(abs(value))")
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundColor(isPositive ? .green : .red)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            (isPositive ? Color.green : Color.red).opacity(0.15)
        )
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Quick Action Button Component

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(color.gradient)
            .cornerRadius(CornerRadius.md)
            .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Schedule Preview Row Component

struct SchedulePreviewRow: View {
    let item: TherapistSessionItem

    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            VStack(spacing: 2) {
                Text(item.session.formattedTime)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(width: 60, alignment: .leading)

            // Divider line
            Rectangle()
                .fill(statusColor)
                .frame(width: 3)
                .cornerRadius(1.5)

            // Patient info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.patient.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(item.session.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Status badge
            StatusBadge(status: item.session.status)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    private var statusColor: Color {
        switch item.session.status {
        case .scheduled: return .blue
        case .completed: return .green
        case .cancelled: return .red
        case .rescheduled: return .orange
        }
    }
}

// MARK: - Status Badge Component

struct StatusBadge: View {
    let status: ScheduledSession.ScheduleStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(textColor)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(backgroundColor)
            .cornerRadius(CornerRadius.sm)
    }

    private var textColor: Color {
        switch status {
        case .scheduled: return .blue
        case .completed: return .green
        case .cancelled: return .red
        case .rescheduled: return .orange
        }
    }

    private var backgroundColor: Color {
        textColor.opacity(0.15)
    }
}

// MARK: - TherapistSessionItem Sample Data Extension

extension TherapistSessionItem {
    /// Sample data for previews
    static var sampleForKPI: TherapistSessionItem {
        guard let firstPatient = Patient.samplePatients.first else {
            fatalError("samplePatients must not be empty")
        }
        return TherapistSessionItem(
            session: .sample,
            patient: firstPatient
        )
    }

    /// Sample list for previews
    static var sampleListForKPI: [TherapistSessionItem] {
        let patients = Patient.samplePatients
        guard let firstPatient = patients.first else {
            return []
        }
        let secondPatient = patients.dropFirst().first ?? firstPatient
        return [
            TherapistSessionItem(
                session: ScheduledSession.__createDirectly(
                    id: UUID(),
                    patientId: firstPatient.id,
                    sessionId: UUID(),
                    scheduledDate: Date(),
                    scheduledTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
                    status: .scheduled,
                    completedAt: nil,
                    reminderSent: false,
                    notes: "Upper Body Strength",
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                patient: firstPatient
            ),
            TherapistSessionItem(
                session: ScheduledSession.__createDirectly(
                    id: UUID(),
                    patientId: secondPatient.id,
                    sessionId: UUID(),
                    scheduledDate: Date(),
                    scheduledTime: Calendar.current.date(bySettingHour: 11, minute: 30, second: 0, of: Date()) ?? Date(),
                    status: .scheduled,
                    completedAt: nil,
                    reminderSent: false,
                    notes: "ACL Rehab Session",
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                patient: secondPatient
            ),
            TherapistSessionItem(
                session: ScheduledSession.__createDirectly(
                    id: UUID(),
                    patientId: firstPatient.id,
                    sessionId: UUID(),
                    scheduledDate: Date(),
                    scheduledTime: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date(),
                    status: .scheduled,
                    completedAt: nil,
                    reminderSent: false,
                    notes: "Initial Assessment",
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                patient: firstPatient
            )
        ]
    }
}

// MARK: - Preview

#if DEBUG
struct DashboardKPISection_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            DashboardKPISection(
                patients: Patient.samplePatients,
                activeFlags: [],
                upcomingSessions: TherapistSessionItem.sampleListForKPI,
                onAddPatient: { print("Add Patient tapped") },
                onCreateProgram: { print("Create Program tapped") },
                onCreateTemplate: { print("Create Template tapped") },
                onViewReports: { print("View Reports tapped") },
                onViewAnalytics: { print("View Analytics tapped") },
                onSessionTap: { item in print("Session tapped: \(item.patient.fullName)") }
            )
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Dashboard KPI Section")

        // Dark mode preview
        ScrollView {
            DashboardKPISection(
                patients: Patient.samplePatients,
                activeFlags: [],
                upcomingSessions: TherapistSessionItem.sampleListForKPI,
                onAddPatient: {},
                onCreateProgram: {},
                onCreateTemplate: {},
                onViewReports: {},
                onViewAnalytics: {},
                onSessionTap: nil
            )
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")

        // Empty state preview
        ScrollView {
            DashboardKPISection(
                patients: [],
                activeFlags: [],
                upcomingSessions: [],
                onAddPatient: {},
                onCreateProgram: {},
                onCreateTemplate: nil,
                onViewReports: {},
                onViewAnalytics: nil,
                onSessionTap: nil
            )
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Empty State")
    }
}
#endif
