//
//  CaseloadStatusCard.swift
//  PTPerformance
//
//  Created by Build 291 Swarm Agent 5
//
//  Reusable patient status card for the caseload overview grid.
//  Displays patient status at a glance with color-coded indicators.
//

import SwiftUI

// MARK: - Patient Status Enum

/// Represents the overall status of a patient based on adherence, flags, and activity
enum PatientStatus: String, CaseIterable {
    case good = "Good"
    case attention = "Attention"
    case critical = "Critical"

    var color: Color {
        switch self {
        case .good: return .green
        case .attention: return .yellow
        case .critical: return .red
        }
    }

    var icon: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .attention: return "exclamationmark.circle.fill"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .good: return "Good status"
        case .attention: return "Needs attention"
        case .critical: return "Critical status"
        }
    }
}

// MARK: - Patient Status Calculator

extension Patient {
    /// Calculate patient status based on adherence, flags, and activity
    var calculatedStatus: PatientStatus {
        let adherence = adherencePercentage ?? 0
        let hasHighFlags = (highSeverityFlagCount ?? 0) > 0
        let daysSinceLastSession = self.daysSinceLastSession

        // Critical: Adherence <50%, high flags, or inactive >14 days
        if adherence < 50 || hasHighFlags || daysSinceLastSession > 14 {
            return .critical
        }

        // Attention: Adherence 50-80%, or inactive 7-14 days
        if adherence < 80 || (daysSinceLastSession > 7 && daysSinceLastSession <= 14) {
            return .attention
        }

        // Good: Adherence >80%, no high flags, active in last 7 days
        return .good
    }

    /// Calculate days since last session
    var daysSinceLastSession: Int {
        guard let lastSession = lastSessionDate else {
            return Int.max // No session = treat as very inactive
        }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: lastSession, to: Date())
        return components.day ?? Int.max
    }

    /// Formatted string for days since last session
    var daysSinceLastSessionText: String {
        let days = daysSinceLastSession
        if days == Int.max {
            return "No sessions"
        } else if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else {
            return "\(days) days ago"
        }
    }
}

// MARK: - CaseloadStatusCard

/// A compact card showing patient status at a glance
struct CaseloadStatusCard: View {
    let patient: Patient
    let onTap: () -> Void

    @Environment(\.colorScheme) var colorScheme

    private var status: PatientStatus {
        patient.calculatedStatus
    }

    private var adherence: Double {
        patient.adherencePercentage ?? 0
    }

    private var initialsBackgroundColor: Color {
        status.color.opacity(colorScheme == .dark ? 0.3 : 0.2)
    }

    private var cardBackgroundColor: Color {
        Color(.secondarySystemGroupedBackground)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Patient initials with status color
                initialsCircle

                // Patient name
                Text(patient.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)

                // Status indicator
                statusIndicator

                // Mini adherence bar
                adherenceBar

                // Days since last session
                Text(patient.daysSinceLastSessionText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(cardBackgroundColor)
            .cornerRadius(12)
            .adaptiveShadow(Shadow.subtle)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(status.color.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(patient.fullName), \(status.accessibilityLabel), \(Int(adherence))% adherence, last session \(patient.daysSinceLastSessionText)")
        .accessibilityHint("Double tap to view patient details")
    }

    // MARK: - Subviews

    private var initialsCircle: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [status.color.opacity(0.8), status.color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)

            Text(patient.initials)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .accessibilityHidden(true)
    }

    private var statusIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption)
                .foregroundColor(status.color)

            Text(status.rawValue)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.15))
        .cornerRadius(8)
    }

    private var adherenceBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray4))
                        .frame(height: 6)

                    // Progress bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(adherenceColor)
                        .frame(width: geometry.size.width * min(adherence / 100, 1.0), height: 6)
                }
            }
            .frame(height: 6)

            Text("\(Int(adherence))%")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(adherenceColor)
        }
    }

    private var adherenceColor: Color {
        switch adherence {
        case 80...: return .green
        case 50..<80: return .yellow
        default: return .red
        }
    }
}

// MARK: - Status Legend View

/// A legend explaining the color coding
struct CaseloadStatusLegend: View {
    var body: some View {
        HStack(spacing: 16) {
            ForEach(PatientStatus.allCases, id: \.self) { status in
                HStack(spacing: 4) {
                    Circle()
                        .fill(status.color)
                        .frame(width: 10, height: 10)

                    Text(status.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Status legend: Green for good, yellow for attention needed, red for critical")
    }
}

// MARK: - Status Summary Bar

/// Summary bar showing count of patients in each status category
struct CaseloadStatusSummary: View {
    let patients: [Patient]

    private var greenCount: Int {
        patients.filter { $0.calculatedStatus == .good }.count
    }

    private var yellowCount: Int {
        patients.filter { $0.calculatedStatus == .attention }.count
    }

    private var redCount: Int {
        patients.filter { $0.calculatedStatus == .critical }.count
    }

    var body: some View {
        HStack(spacing: 12) {
            statusCountView(count: greenCount, status: .good)

            Divider()
                .frame(height: 30)

            statusCountView(count: yellowCount, status: .attention)

            Divider()
                .frame(height: 30)

            statusCountView(count: redCount, status: .critical)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(greenCount) patients good, \(yellowCount) need attention, \(redCount) critical")
    }

    private func statusCountView(count: Int, status: PatientStatus) -> some View {
        HStack(spacing: 8) {
            Image(systemName: status.icon)
                .font(.title3)
                .foregroundColor(status.color)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(status.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#if DEBUG
struct CaseloadStatusCard_Previews: PreviewProvider {
    static var previews: some View {
        let samplePatients = [
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
                adherencePercentage: 92.5,
                lastSessionDate: Date()
            ),
            Patient(
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
                adherencePercentage: 65.0,
                lastSessionDate: Calendar.current.date(byAdding: .day, value: -10, to: Date())
            ),
            Patient(
                id: UUID(),
                therapistId: UUID(),
                firstName: "Mike",
                lastName: "Williams",
                email: "mike@example.com",
                sport: "Football",
                position: "Quarterback",
                injuryType: "Shoulder",
                targetLevel: "Pro",
                profileImageUrl: nil,
                createdAt: Date(),
                flagCount: 2,
                highSeverityFlagCount: 1,
                adherencePercentage: 35.0,
                lastSessionDate: Calendar.current.date(byAdding: .day, value: -20, to: Date())
            )
        ]

        VStack(spacing: 24) {
            // Summary bar
            CaseloadStatusSummary(patients: samplePatients)

            // Legend
            CaseloadStatusLegend()

            // Cards in a grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(samplePatients) { patient in
                    CaseloadStatusCard(patient: patient) {
                        print("Tapped \(patient.fullName)")
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .previewLayout(.sizeThatFits)
    }
}
#endif
