//
//  SafetyIncidentDetailSheet.swift
//  PTPerformance
//
//  Safety Incident Detail Sheet for X2Index Command Center
//  Shows full details of a SafetyIncident and allows therapists to take action
//

import SwiftUI

// MARK: - Safety Incident Detail Sheet

/// Detail sheet for viewing and acting on a SafetyIncident
/// Provides incident information, patient context, and resolution options
struct SafetyIncidentDetailSheet: View {
    let incident: SafetyIncident
    var patientName: String? = nil
    var onAcknowledge: (() -> Void)?
    var onEscalate: (() -> Void)?
    var onDismiss: (() -> Void)?
    var onResolve: ((String) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var resolutionNotes = ""
    @State private var showResolutionForm = false
    @State private var showDismissConfirmation = false
    @State private var dismissReason = ""
    @State private var isPerformingAction = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Incident Header
                    incidentHeader

                    // Description Section
                    descriptionSection

                    // Trigger Data Section
                    if let triggerData = incident.triggerData, !triggerData.isEmpty {
                        triggerDataSection(triggerData)
                    }

                    // Patient Info Section
                    patientInfoSection

                    // Timeline Section
                    timelineSection

                    // Resolution Notes (if resolved)
                    if let notes = incident.resolutionNotes, !notes.isEmpty {
                        resolutionNotesSection(notes)
                    }

                    // Action Buttons
                    if incident.status.isActive {
                        actionButtonsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Incident Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showResolutionForm) {
                resolutionFormSheet
            }
            .confirmationDialog("Dismiss Incident", isPresented: $showDismissConfirmation, titleVisibility: .visible) {
                Button("Dismiss as False Positive", role: .destructive) {
                    onDismiss?()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will mark the incident as a false positive. Use this only when the alert was triggered incorrectly.")
            }
            .disabled(isPerformingAction)
        }
    }

    // MARK: - Incident Header

    private var incidentHeader: some View {
        HStack(spacing: Spacing.md) {
            // Severity Badge
            VStack {
                Image(systemName: incident.severity.icon)
                    .font(.title)
                    .foregroundColor(severityColor)

                Text(incident.severity.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(severityColor)
            }
            .frame(width: 70)
            .padding(.vertical, Spacing.md)
            .background(severityColor.opacity(0.1))
            .cornerRadius(CornerRadius.md)

            VStack(alignment: .leading, spacing: 4) {
                // Incident Type
                HStack {
                    Image(systemName: incident.incidentType.icon)
                        .foregroundColor(.secondary)

                    Text(incident.incidentType.displayName)
                        .font(.headline)
                }

                // Status Badge
                HStack(spacing: 4) {
                    Image(systemName: incident.status.icon)
                        .font(.caption2)
                    Text(incident.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(statusColor)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxs)
                .background(statusColor.opacity(0.15))
                .cornerRadius(CornerRadius.sm)

                // Time since creation
                Text(incident.ageString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Escalation indicator
            if incident.isEscalated {
                VStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.purple)

                    Text("Escalated")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(severityColor.opacity(0.3), lineWidth: incident.isHighSeverity ? 2 : 1)
        )
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Description")
                .font(.headline)

            Text(incident.description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(incident.incidentType.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Trigger Data Section

    private func triggerDataSection(_ triggerData: [String: AnyCodableValue]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Trigger Details")
                .font(.headline)

            ForEach(Array(triggerData.keys.sorted()), id: \.self) { key in
                if let value = triggerData[key] {
                    HStack {
                        Text(formatKey(key))
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(formatValue(value))
                            .font(.subheadline.weight(.medium))
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Patient Info Section

    private var patientInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Patient Information")
                .font(.headline)

            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.modusCyan)

                VStack(alignment: .leading, spacing: 2) {
                    Text(patientName ?? "Unknown Patient")
                        .font(.subheadline.weight(.medium))

                    Text("ID: \(incident.athleteId.uuidString.prefix(8))...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    // Navigate to patient profile
                } label: {
                    Text("View Profile")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Timeline Section

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Timeline")
                .font(.headline)

            // Created
            TimelineRowView(
                icon: "plus.circle.fill",
                color: .modusCyan,
                title: "Created",
                date: incident.createdAt
            )

            // Escalated (if applicable)
            if incident.isEscalated {
                TimelineRowView(
                    icon: "arrow.up.circle.fill",
                    color: .purple,
                    title: "Escalated",
                    date: incident.createdAt // Note: Would need separate escalation date field
                )
            }

            // Resolved (if applicable)
            if let resolvedAt = incident.resolvedAt {
                TimelineRowView(
                    icon: incident.status == .dismissed ? "xmark.circle.fill" : "checkmark.circle.fill",
                    color: incident.status == .dismissed ? .gray : .green,
                    title: incident.status == .dismissed ? "Dismissed" : "Resolved",
                    date: resolvedAt
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Resolution Notes Section

    private func resolutionNotesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Resolution Notes")
                .font(.headline)

            Text(notes)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: Spacing.md) {
            // Primary action - Acknowledge (if open)
            if incident.status == .open {
                Button {
                    isPerformingAction = true
                    onAcknowledge?()
                    isPerformingAction = false
                } label: {
                    Label("Acknowledge & Investigate", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            // Secondary actions row
            HStack(spacing: Spacing.md) {
                // Escalate button
                if !incident.isEscalated {
                    Button {
                        isPerformingAction = true
                        onEscalate?()
                        isPerformingAction = false
                        dismiss()
                    } label: {
                        Label("Escalate", systemImage: "arrow.up.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.purple)
                }

                // Resolve button
                Button {
                    showResolutionForm = true
                } label: {
                    Label("Resolve", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.green)
            }

            // Dismiss button
            Button {
                showDismissConfirmation = true
            } label: {
                Label("Dismiss as False Positive", systemImage: "xmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
        }
        .padding(.top, Spacing.md)
    }

    // MARK: - Resolution Form Sheet

    private var resolutionFormSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $resolutionNotes)
                        .frame(minHeight: 120)
                } header: {
                    Text("Resolution Notes")
                } footer: {
                    Text("Describe how this incident was addressed and any follow-up actions taken.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(incident.incidentType.displayName, systemImage: incident.incidentType.icon)
                            .font(.subheadline)

                        Text(incident.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Incident Summary")
                }
            }
            .navigationTitle("Resolve Incident")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showResolutionForm = false
                        resolutionNotes = ""
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Resolve") {
                        onResolve?(resolutionNotes)
                        showResolutionForm = false
                        dismiss()
                    }
                    .disabled(resolutionNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    // MARK: - Helper Views & Functions

    private var severityColor: Color {
        switch incident.severity {
        case .low: return .gray
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        case .unknown: return .gray
        }
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

    private func formatKey(_ key: String) -> String {
        key.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func formatValue(_ value: AnyCodableValue) -> String {
        switch value {
        case .int(let v):
            return "\(v)"
        case .double(let v):
            return String(format: "%.1f", v)
        case .string(let v):
            return v
        case .bool(let v):
            return v ? "Yes" : "No"
        default:
            return "-"
        }
    }
}

// MARK: - Timeline Row View

private struct TimelineRowView: View {
    let icon: String
    let color: Color
    let title: String
    let date: Date

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))

                Text(date, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(date, format: .dateTime.month().day().hour().minute())
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SafetyIncidentDetailSheet_Previews: PreviewProvider {
    static var previews: some View {
        SafetyIncidentDetailSheet(
            incident: .samplePainThreshold,
            patientName: "John Smith",
            onAcknowledge: {},
            onEscalate: {},
            onDismiss: {},
            onResolve: { _ in }
        )

        SafetyIncidentDetailSheet(
            incident: .sampleCritical,
            patientName: "Jane Doe",
            onAcknowledge: {},
            onEscalate: {},
            onDismiss: {},
            onResolve: { _ in }
        )
        .previewDisplayName("Critical Incident")

        SafetyIncidentDetailSheet(
            incident: .sampleResolved,
            patientName: "Alex Johnson",
            onAcknowledge: nil,
            onEscalate: nil,
            onDismiss: nil,
            onResolve: nil
        )
        .previewDisplayName("Resolved Incident")
    }
}
#endif
