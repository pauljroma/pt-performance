//
//  AtRiskPatientsCard.swift
//  PTPerformance
//
//  Card component displaying patients at risk (adherence < 60%)
//  Shows days since last activity with quick actions
//

import SwiftUI

// MARK: - At Risk Patients Card

struct AtRiskPatientsCard: View {
    let atRiskPatients: [AtRiskPatient]
    var onSendReminder: ((Patient) -> Void)?
    var onViewProfile: ((Patient) -> Void)?
    var onViewAll: (() -> Void)?

    @State private var expandedPatientId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Label {
                    Text("At-Risk Patients")
                        .font(.headline)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }

                Spacer()

                if atRiskPatients.count > 5 {
                    Button(action: { onViewAll?() }) {
                        Text("View All (\(atRiskPatients.count))")
                            .font(.subheadline)
                            .foregroundColor(.modusCyan)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            if atRiskPatients.isEmpty {
                // Empty state
                HStack {
                    Spacer()
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)

                        Text("All patients on track!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, Spacing.lg)
                    Spacer()
                }
            } else {
                // Patient list
                VStack(spacing: Spacing.sm) {
                    ForEach(atRiskPatients.prefix(5)) { atRiskPatient in
                        AtRiskPatientRow(
                            atRiskPatient: atRiskPatient,
                            isExpanded: expandedPatientId == atRiskPatient.id,
                            onTap: {
                                withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                                    if expandedPatientId == atRiskPatient.id {
                                        expandedPatientId = nil
                                    } else {
                                        expandedPatientId = atRiskPatient.id
                                    }
                                }
                            },
                            onSendReminder: {
                                onSendReminder?(atRiskPatient.patient)
                            },
                            onViewProfile: {
                                onViewProfile?(atRiskPatient.patient)
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
    }
}

// MARK: - At Risk Patient Row

struct AtRiskPatientRow: View {
    let atRiskPatient: AtRiskPatient
    let isExpanded: Bool
    var onTap: (() -> Void)?
    var onSendReminder: (() -> Void)?
    var onViewProfile: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    private var patient: Patient { atRiskPatient.patient }

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            Button(action: { onTap?() }) {
                HStack(spacing: Spacing.md) {
                    // Risk level indicator
                    RiskLevelIndicator(level: atRiskPatient.riskLevel)

                    // Patient info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(patient.fullName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        HStack(spacing: Spacing.sm) {
                            // Adherence badge
                            AdherenceBadge(percentage: atRiskPatient.adherencePercentage)

                            // Days since activity
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                Text(daysText)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Expand indicator
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded actions
            if isExpanded {
                Divider()
                    .padding(.leading, 44)

                HStack(spacing: Spacing.md) {
                    // Send reminder button
                    Button(action: { onSendReminder?() }) {
                        Label("Send Reminder", systemImage: "bell.badge.fill")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(QuickActionButtonStyle(color: .orange))

                    // View profile button
                    Button(action: { onViewProfile?() }) {
                        Label("View Profile", systemImage: "person.circle.fill")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(QuickActionButtonStyle(color: .modusCyan))
                }
                .padding(.vertical, Spacing.sm)
                .padding(.leading, 44)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .background(
            isExpanded
                ? atRiskPatient.riskLevel.color.opacity(colorScheme == .dark ? 0.15 : 0.08)
                : Color.clear
        )
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(patient.fullName), \(atRiskPatient.riskLevel.displayName) risk, \(Int(atRiskPatient.adherencePercentage))% adherence, \(daysText)")
        .accessibilityHint("Double tap to show actions")
    }

    private var daysText: String {
        let days = atRiskPatient.daysSinceLastActivity
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "1 day ago"
        } else {
            return "\(days) days ago"
        }
    }
}

// MARK: - Risk Level Indicator

struct RiskLevelIndicator: View {
    let level: AtRiskPatient.RiskLevel

    var body: some View {
        ZStack {
            Circle()
                .fill(level.color.opacity(0.2))
                .frame(width: 36, height: 36)

            Image(systemName: iconName)
                .font(.subheadline)
                .foregroundColor(level.color)
        }
        .accessibilityHidden(true)
    }

    private var iconName: String {
        switch level {
        case .moderate: return "exclamationmark.circle.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}

// MARK: - Adherence Badge

struct AdherenceBadge: View {
    let percentage: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.caption2)
            Text("\(Int(percentage))%")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(color)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, 3)
        .background(color.opacity(0.15))
        .cornerRadius(CornerRadius.xs)
    }

    private var color: Color {
        switch percentage {
        case 45...: return .yellow
        case 30..<45: return .orange
        default: return .red
        }
    }
}

// MARK: - Quick Action Button Style

struct QuickActionButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(color)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(color.opacity(configuration.isPressed ? 0.2 : 0.1))
            .cornerRadius(CornerRadius.sm)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Compact At Risk Summary

/// Compact summary showing at-risk count with breakdown
struct AtRiskSummaryBadge: View {
    let atRiskPatients: [AtRiskPatient]

    private var criticalCount: Int {
        atRiskPatients.filter { $0.riskLevel == .critical }.count
    }

    private var highCount: Int {
        atRiskPatients.filter { $0.riskLevel == .high }.count
    }

    private var moderateCount: Int {
        atRiskPatients.filter { $0.riskLevel == .moderate }.count
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            if criticalCount > 0 {
                RiskCountBadge(count: criticalCount, level: .critical)
            }
            if highCount > 0 {
                RiskCountBadge(count: highCount, level: .high)
            }
            if moderateCount > 0 {
                RiskCountBadge(count: moderateCount, level: .moderate)
            }
        }
    }
}

struct RiskCountBadge: View {
    let count: Int
    let level: AtRiskPatient.RiskLevel

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(level.color)
                .frame(width: 8, height: 8)

            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(level.color.opacity(0.15))
        .cornerRadius(CornerRadius.xs)
    }
}

// MARK: - Preview

#if DEBUG
struct AtRiskPatientsCard_Previews: PreviewProvider {
    static var sampleAtRiskPatients: [AtRiskPatient] = [
        AtRiskPatient(
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
                adherencePercentage: 25.0,
                lastSessionDate: Calendar.current.date(byAdding: .day, value: -15, to: Date())
            ),
            adherencePercentage: 25.0,
            daysSinceLastActivity: 15,
            riskLevel: .critical
        ),
        AtRiskPatient(
            id: UUID(),
            patient: Patient(
                id: UUID(),
                therapistId: UUID(),
                firstName: "Sarah",
                lastName: "Johnson",
                email: "sarah@example.com",
                sport: "Basketball",
                position: "Guard",
                injuryType: "ACL",
                targetLevel: "College",
                profileImageUrl: nil,
                createdAt: Date(),
                flagCount: 1,
                highSeverityFlagCount: 0,
                adherencePercentage: 42.0,
                lastSessionDate: Calendar.current.date(byAdding: .day, value: -8, to: Date())
            ),
            adherencePercentage: 42.0,
            daysSinceLastActivity: 8,
            riskLevel: .high
        ),
        AtRiskPatient(
            id: UUID(),
            patient: Patient(
                id: UUID(),
                therapistId: UUID(),
                firstName: "Tom",
                lastName: "Davis",
                email: "tom@example.com",
                sport: "Baseball",
                position: "Pitcher",
                injuryType: "Elbow",
                targetLevel: "College",
                profileImageUrl: nil,
                createdAt: Date(),
                flagCount: 0,
                highSeverityFlagCount: 0,
                adherencePercentage: 55.0,
                lastSessionDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())
            ),
            adherencePercentage: 55.0,
            daysSinceLastActivity: 5,
            riskLevel: .moderate
        )
    ]

    static var previews: some View {
        VStack(spacing: Spacing.lg) {
            AtRiskPatientsCard(
                atRiskPatients: sampleAtRiskPatients,
                onSendReminder: { patient in
                    print("Send reminder to \(patient.fullName)")
                },
                onViewProfile: { patient in
                    print("View profile for \(patient.fullName)")
                },
                onViewAll: {
                    print("View all at-risk patients")
                }
            )

            // Empty state
            AtRiskPatientsCard(
                atRiskPatients: [],
                onSendReminder: nil,
                onViewProfile: nil,
                onViewAll: nil
            )

            // Summary badge
            AtRiskSummaryBadge(atRiskPatients: sampleAtRiskPatients)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
