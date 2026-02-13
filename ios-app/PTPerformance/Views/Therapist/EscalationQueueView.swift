// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  EscalationQueueView.swift
//  PTPerformance
//
//  Full escalation management queue for therapists
//  Part of Risk Escalation System (M4) - X2Index Command Center
//

import SwiftUI

// MARK: - Escalation Queue View

/// Full-screen view for managing all patient risk escalations
struct EscalationQueueView: View {
    @StateObject private var viewModel = EscalationQueueViewModel()
    @State private var showFilterSheet = false
    @State private var selectedEscalation: RiskEscalation?
    @State private var showResolveSheet = false
    @State private var showDismissSheet = false
    @State private var resolutionNotes = ""
    @State private var dismissReason = ""

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.escalations.isEmpty {
                    loadingView
                } else if viewModel.escalations.isEmpty {
                    emptyStateView
                } else {
                    escalationsList
                }
            }
            .navigationTitle("Safety Alerts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: Spacing.sm) {
                        filterButton
                        bulkAcknowledgeButton
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showFilterSheet) {
                EscalationFilterSheet(filter: $viewModel.filter)
            }
            .sheet(item: $selectedEscalation) { escalation in
                EscalationDetailSheet(
                    escalation: escalation,
                    patient: viewModel.patient(for: escalation.patientId),
                    onAcknowledge: {
                        Task {
                            await viewModel.acknowledge(escalation.id)
                        }
                    },
                    onResolve: {
                        showResolveSheet = true
                    },
                    onDismiss: {
                        showDismissSheet = true
                    }
                )
            }
            .sheet(isPresented: $showResolveSheet) {
                resolveSheet
            }
            .sheet(isPresented: $showDismissSheet) {
                dismissSheet
            }
            .task {
                await viewModel.loadEscalations()
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
            Text("Loading safety alerts...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("All Clear")
                .font(.title2.weight(.semibold))

            Text("No active safety alerts requiring attention")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var escalationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Summary header
                summaryHeader
                    .padding(.horizontal)
                    .padding(.bottom, Spacing.md)

                // Grouped by severity
                ForEach(EscalationSeverity.allCases.reversed(), id: \.self) { severity in
                    let escalationsForSeverity = viewModel.filteredEscalations.filter { $0.severity == severity }

                    if !escalationsForSeverity.isEmpty {
                        Section {
                            ForEach(escalationsForSeverity) { escalation in
                                EscalationQueueRow(
                                    escalation: escalation,
                                    patientName: viewModel.patient(for: escalation.patientId)?.fullName,
                                    isSelected: viewModel.selectedIds.contains(escalation.id),
                                    onTap: {
                                        if viewModel.isSelectionMode {
                                            viewModel.toggleSelection(escalation.id)
                                        } else {
                                            selectedEscalation = escalation
                                        }
                                    },
                                    onLongPress: {
                                        viewModel.isSelectionMode = true
                                        viewModel.toggleSelection(escalation.id)
                                    }
                                )
                                .padding(.horizontal)

                                if escalation.id != escalationsForSeverity.last?.id {
                                    Divider()
                                        .padding(.leading, 60)
                                }
                            }
                        } header: {
                            SeveritySectionHeader(severity: severity, count: escalationsForSeverity.count)
                                .padding(.horizontal)
                                .padding(.top, Spacing.md)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private var summaryHeader: some View {
        VStack(spacing: Spacing.md) {
            // Stats row
            HStack(spacing: Spacing.lg) {
                EscalationStatBox(
                    value: "\(viewModel.summary.totalActive)",
                    label: "Active",
                    color: .blue
                )

                EscalationStatBox(
                    value: "\(viewModel.summary.unacknowledgedCount)",
                    label: "Pending",
                    color: .orange
                )

                EscalationStatBox(
                    value: "\(viewModel.summary.patientsAffected)",
                    label: "Patients",
                    color: .purple
                )
            }

            // Filter indicator
            if viewModel.filter.isFiltered {
                HStack {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .foregroundColor(.blue)

                    Text("Filters active")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Clear") {
                        viewModel.filter.reset()
                    }
                    .font(.caption.weight(.medium))
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(CornerRadius.sm)
            }
        }
    }

    private var filterButton: some View {
        Button {
            showFilterSheet = true
        } label: {
            Image(systemName: viewModel.filter.isFiltered
                  ? "line.3.horizontal.decrease.circle.fill"
                  : "line.3.horizontal.decrease.circle")
        }
    }

    private var bulkAcknowledgeButton: some View {
        Group {
            if viewModel.isSelectionMode {
                Button {
                    Task {
                        await viewModel.bulkAcknowledge()
                    }
                } label: {
                    Text("Acknowledge (\(viewModel.selectedIds.count))")
                        .font(.subheadline.weight(.medium))
                }
                .disabled(viewModel.selectedIds.isEmpty)
            } else if viewModel.summary.unacknowledgedCount > 0 {
                Menu {
                    Button {
                        viewModel.isSelectionMode = true
                    } label: {
                        Label("Select Multiple", systemImage: "checkmark.circle")
                    }

                    Button {
                        Task {
                            await viewModel.acknowledgeAll()
                        }
                    } label: {
                        Label("Acknowledge All", systemImage: "eye.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private var resolveSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $resolutionNotes)
                        .frame(minHeight: 100)
                } header: {
                    Text("Resolution Notes")
                } footer: {
                    Text("Describe how this issue was addressed")
                }
            }
            .navigationTitle("Resolve Escalation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showResolveSheet = false
                        resolutionNotes = ""
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Resolve") {
                        Task {
                            if let escalation = selectedEscalation {
                                await viewModel.resolve(escalation.id, notes: resolutionNotes)
                            }
                            showResolveSheet = false
                            selectedEscalation = nil
                            resolutionNotes = ""
                        }
                    }
                    .disabled(resolutionNotes.isEmpty)
                }
            }
        }
    }

    private var dismissSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Reason for dismissal", text: $dismissReason)
                } header: {
                    Text("Dismissal Reason")
                } footer: {
                    Text("This helps improve future alert accuracy")
                }

                Section {
                    Text("Dismissing an alert marks it as a false positive. Use this only when the alert was triggered incorrectly.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Dismiss Escalation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showDismissSheet = false
                        dismissReason = ""
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Dismiss") {
                        Task {
                            if let escalation = selectedEscalation {
                                await viewModel.dismiss(escalation.id, reason: dismissReason)
                            }
                            showDismissSheet = false
                            selectedEscalation = nil
                            dismissReason = ""
                        }
                    }
                    .disabled(dismissReason.isEmpty)
                }
            }
        }
    }
}

// MARK: - Escalation Stat Box

struct EscalationStatBox: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(color.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Severity Section Header

struct SeveritySectionHeader: View {
    let severity: EscalationSeverity
    let count: Int

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(severity.color)
                .frame(width: 10, height: 10)

            Text(severity.displayName)
                .font(.headline)
                .foregroundColor(severity.color)

            Text("(\(count))")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(severity.responseTimeDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Escalation Queue Row

struct EscalationQueueRow: View {
    let escalation: RiskEscalation
    let patientName: String?
    let isSelected: Bool
    var onTap: (() -> Void)?
    var onLongPress: (() -> Void)?

    @State private var isPressed = false

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: Spacing.md) {
                // Selection indicator or severity
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .frame(width: 36)
                } else {
                    ZStack {
                        Circle()
                            .fill(escalation.severity.color.opacity(0.2))
                            .frame(width: 36, height: 36)

                        Image(systemName: escalation.escalationType.iconName)
                            .font(.subheadline)
                            .foregroundColor(escalation.severity.color)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(patientName ?? "Unknown Patient")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)

                        Spacer()

                        Text(escalation.timeSinceCreationText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(escalation.escalationType.displayName)
                        .font(.caption)
                        .foregroundColor(escalation.escalationType.color)

                    Text(escalation.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Status and chevron
                VStack(spacing: 4) {
                    if !escalation.isAcknowledged {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, Spacing.md)
            .contentShape(Rectangle())
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onLongPress?()
        }
    }
}

// MARK: - Escalation Detail Sheet

struct EscalationDetailSheet: View {
    let escalation: RiskEscalation
    let patient: Patient?
    var onAcknowledge: (() -> Void)?
    var onResolve: (() -> Void)?
    var onDismiss: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Header card
                    SafetyAlertCard(
                        escalation: escalation,
                        patient: patient,
                        onAcknowledge: onAcknowledge,
                        onCallPatient: {
                            if let patient = patient,
                               let url = URL(string: "tel://\(patient.email)") {
                                UIApplication.shared.open(url)
                            }
                        },
                        onViewDetails: nil
                    )

                    // Trigger data
                    if !escalation.triggerData.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Trigger Details")
                                .font(.headline)

                            ForEach(Array(escalation.triggerData.keys.sorted()), id: \.self) { key in
                                if let value = escalation.triggerData[key] {
                                    HStack {
                                        Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
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

                    // Timeline
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Timeline")
                            .font(.headline)

                        TimelineRow(
                            icon: "plus.circle.fill",
                            color: .blue,
                            title: "Created",
                            date: escalation.createdAt
                        )

                        if let acknowledgedAt = escalation.acknowledgedAt {
                            TimelineRow(
                                icon: "eye.fill",
                                color: .orange,
                                title: "Acknowledged",
                                date: acknowledgedAt
                            )
                        }

                        if let resolvedAt = escalation.resolvedAt {
                            TimelineRow(
                                icon: "checkmark.circle.fill",
                                color: .green,
                                title: escalation.status == .dismissed ? "Dismissed" : "Resolved",
                                date: resolvedAt
                            )
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.md)

                    // Resolution notes
                    if let notes = escalation.resolutionNotes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Resolution Notes")
                                .font(.headline)

                            Text(notes)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.md)
                    }

                    // Action buttons
                    if escalation.isActive {
                        VStack(spacing: Spacing.md) {
                            if !escalation.isAcknowledged {
                                Button {
                                    onAcknowledge?()
                                    dismiss()
                                } label: {
                                    Label("Acknowledge", systemImage: "eye.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                            }

                            HStack(spacing: Spacing.md) {
                                Button {
                                    onResolve?()
                                } label: {
                                    Label("Resolve", systemImage: "checkmark.circle.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)

                                Button {
                                    onDismiss?()
                                } label: {
                                    Label("Dismiss", systemImage: "xmark.circle.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(.secondary)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Escalation Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
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

// MARK: - Timeline Row

struct TimelineRow: View {
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

// MARK: - Escalation Filter Sheet

struct EscalationFilterSheet: View {
    @Binding var filter: EscalationFilter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Severity") {
                    ForEach(EscalationSeverity.allCases, id: \.self) { severity in
                        Toggle(isOn: Binding(
                            get: { filter.severities.contains(severity) },
                            set: { isOn in
                                if isOn {
                                    filter.severities.insert(severity)
                                } else {
                                    filter.severities.remove(severity)
                                }
                            }
                        )) {
                            HStack {
                                Circle()
                                    .fill(severity.color)
                                    .frame(width: 12, height: 12)

                                Text(severity.displayName)
                            }
                        }
                    }
                }

                Section("Type") {
                    ForEach(EscalationType.allCases, id: \.self) { type in
                        Toggle(isOn: Binding(
                            get: { filter.types.contains(type) },
                            set: { isOn in
                                if isOn {
                                    filter.types.insert(type)
                                } else {
                                    filter.types.remove(type)
                                }
                            }
                        )) {
                            HStack {
                                Image(systemName: type.iconName)
                                    .foregroundColor(type.color)
                                    .frame(width: 24)

                                Text(type.displayName)
                            }
                        }
                    }
                }

                Section("Status") {
                    ForEach([EscalationStatus.pending, .acknowledged], id: \.self) { status in
                        Toggle(isOn: Binding(
                            get: { filter.statuses.contains(status) },
                            set: { isOn in
                                if isOn {
                                    filter.statuses.insert(status)
                                } else {
                                    filter.statuses.remove(status)
                                }
                            }
                        )) {
                            HStack {
                                Image(systemName: status.iconName)
                                    .foregroundColor(status.color)
                                    .frame(width: 24)

                                Text(status.displayName)
                            }
                        }
                    }
                }

                Section {
                    Button("Reset Filters") {
                        filter.reset()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filter Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct EscalationQueueView_Previews: PreviewProvider {
    static var previews: some View {
        EscalationQueueView()
    }
}
#endif
