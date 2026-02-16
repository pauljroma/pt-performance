//
//  SafetyIncidentRow.swift
//  PTPerformance
//
//  Safety Incident Row View for X2Index KPI Dashboard
//  Shows incident severity, type, athlete, status with quick actions
//

import SwiftUI

// MARK: - Safety Incident Row

/// Row view for displaying a safety incident in a list
/// Shows severity, type, athlete info, status, and quick actions
struct SafetyIncidentRow: View {
    let incident: SafetyIncident
    let onTap: () -> Void

    @State private var isPerformingAction = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Severity Indicator
                severityIndicator

                // Main Content
                VStack(alignment: .leading, spacing: 4) {
                    // Type and Time
                    HStack {
                        Label(incident.incidentType.displayName, systemImage: incident.incidentType.icon)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        Text(incident.ageString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Description
                    Text(incident.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    // Status and Actions
                    HStack {
                        statusBadge

                        if incident.isEscalated {
                            escalationBadge
                        }

                        Spacer()

                        quickActions
                    }
                }
            }
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(severityBorderColor, lineWidth: incident.isHighSeverity ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isPerformingAction)
    }

    // MARK: - Severity Indicator

    private var severityIndicator: some View {
        VStack {
            Image(systemName: incident.severity.icon)
                .font(.title2)
                .foregroundColor(severityColor)

            Text(incident.severity.displayName)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(severityColor)
        }
        .frame(width: 60)
        .padding(.vertical, Spacing.xs)
        .background(severityColor.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: incident.status.icon)
                .font(.caption2)
            Text(incident.status.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(statusColor.opacity(0.15))
        .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Escalation Badge

    private var escalationBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.caption2)
            Text("Escalated")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(.purple)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(Color.purple.opacity(0.15))
        .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: 8) {
            if incident.status == .open {
                // Investigate Action
                Button {
                    Task {
                        await investigate()
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }
                .buttonStyle(.plain)

                // Escalate Action
                if !incident.isEscalated {
                    Button {
                        Task {
                            await escalate()
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                    .buttonStyle(.plain)
                }
            }

            // View Details (chevron)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Colors

    private var severityColor: Color {
        switch incident.severity {
        case .low: return .gray
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        case .unknown: return .gray
        }
    }

    private var severityBorderColor: Color {
        incident.isHighSeverity ? severityColor : Color(.separator)
    }

    private var statusColor: Color {
        switch incident.status {
        case .open: return .red
        case .investigating: return .yellow
        case .resolved: return .green
        case .dismissed: return .gray
        case .unknown: return .gray
        }
    }

    // MARK: - Actions

    private func investigate() async {
        isPerformingAction = true
        defer { isPerformingAction = false }

        guard let userId = UUID(uuidString: PTSupabaseClient.shared.userId ?? "") else { return }

        let resolution = IncidentResolution(
            incidentId: incident.id,
            resolvedBy: userId,
            notes: "Started investigation"
        )

        // Update status to investigating
        do {
            try await SafetyService.shared.escalateIncident(incidentId: incident.id, escalateTo: userId)
        } catch {
            ErrorLogger.shared.logError(error, context: "SafetyIncidentRow.investigate")
        }
    }

    private func escalate() async {
        isPerformingAction = true
        defer { isPerformingAction = false }

        guard let userId = UUID(uuidString: PTSupabaseClient.shared.userId ?? "") else { return }

        do {
            try await SafetyService.shared.escalateIncident(incidentId: incident.id, escalateTo: userId)
        } catch {
            ErrorLogger.shared.logError(error, context: "SafetyIncidentRow.escalate")
        }
    }
}

// MARK: - Compact Safety Incident Row

/// A more compact version for use in smaller spaces
struct CompactSafetyIncidentRow: View {
    let incident: SafetyIncident
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Severity dot
                Circle()
                    .fill(severityColor)
                    .frame(width: 10, height: 10)

                // Type icon
                Image(systemName: incident.incidentType.icon)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Description
                Text(incident.description)
                    .font(.caption)
                    .lineLimit(1)

                Spacer()

                // Time
                Text(incident.ageString)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, Spacing.xs)
            .padding(.horizontal, Spacing.sm)
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(CornerRadius.sm)
        }
        .buttonStyle(.plain)
    }

    private var severityColor: Color {
        switch incident.severity {
        case .low: return .gray
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        case .unknown: return .gray
        }
    }
}

// MARK: - Safety Incident Card

/// Card-style view for prominent display of a single incident
struct SafetyIncidentCard: View {
    let incident: SafetyIncident
    let onInvestigate: (() -> Void)?
    let onEscalate: (() -> Void)?
    let onResolve: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: incident.severity.icon)
                    .font(.title2)
                    .foregroundColor(severityColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(incident.incidentType.displayName)
                        .font(.headline)

                    Text(incident.severity.displayName + " Severity")
                        .font(.caption)
                        .foregroundColor(severityColor)
                }

                Spacer()

                Text(incident.ageString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Description
            Text(incident.description)
                .font(.subheadline)

            // Status
            HStack {
                statusBadge

                if incident.isEscalated {
                    Label("Escalated", systemImage: "arrow.up.circle.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                }

                Spacer()
            }

            // Actions
            if !incident.isResolved {
                HStack(spacing: 12) {
                    if let onInvestigate = onInvestigate, incident.status == .open {
                        Button {
                            onInvestigate()
                        } label: {
                            Label("Investigate", systemImage: "magnifyingglass")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }

                    if let onEscalate = onEscalate, !incident.isEscalated {
                        Button {
                            onEscalate()
                        } label: {
                            Label("Escalate", systemImage: "arrow.up.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .tint(.purple)
                    }

                    Spacer()

                    if let onResolve = onResolve {
                        Button {
                            onResolve()
                        } label: {
                            Label("Resolve", systemImage: "checkmark.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(severityColor.opacity(incident.isHighSeverity ? 0.5 : 0.2), lineWidth: incident.isHighSeverity ? 2 : 1)
        )
    }

    private var severityColor: Color {
        switch incident.severity {
        case .low: return .gray
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        case .unknown: return .gray
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: incident.status.icon)
                .font(.caption2)
            Text(incident.status.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(statusColor.opacity(0.15))
        .cornerRadius(CornerRadius.sm)
    }

    private var statusColor: Color {
        switch incident.status {
        case .open: return .red
        case .investigating: return .yellow
        case .resolved: return .green
        case .dismissed: return .gray
        case .unknown: return .gray
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SafetyIncidentRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            SafetyIncidentRow(incident: .samplePainThreshold) {}

            SafetyIncidentRow(incident: .sampleVitalAnomaly) {}

            SafetyIncidentRow(incident: .sampleCritical) {}

            CompactSafetyIncidentRow(incident: .sampleAIUncertainty) {}

            SafetyIncidentCard(
                incident: .samplePainThreshold,
                onInvestigate: {},
                onEscalate: {},
                onResolve: {}
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
