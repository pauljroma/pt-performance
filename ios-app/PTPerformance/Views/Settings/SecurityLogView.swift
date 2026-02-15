//
//  SecurityLogView.swift
//  PTPerformance
//
//  ACP-1051 / ACP-1056: Security audit log viewer and security alerts dashboard
//  Available in DEBUG builds from Settings
//

import SwiftUI

#if DEBUG

// MARK: - Security Log View

/// Debug view showing recent audit log entries and security alerts.
/// Accessible from Settings in DEBUG builds only.
struct SecurityLogView: View {

    @StateObject private var securityMonitor = SecurityMonitor.shared
    @State private var auditEntries: [AuditEntry] = []
    @State private var selectedTab: SecurityTab = .auditLog
    @State private var selectedEventFilter: AuditEventType? = nil
    @State private var searchText = ""
    @State private var entryCount: Int = 0

    enum SecurityTab: String, CaseIterable {
        case auditLog = "Audit Log"
        case alerts = "Alerts"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("View", selection: $selectedTab) {
                ForEach(SecurityTab.allCases, id: \.self) { tab in
                    HStack {
                        Text(tab.rawValue)
                        if tab == .alerts && securityMonitor.unacknowledgedAlertCount > 0 {
                            Text("(\(securityMonitor.unacknowledgedAlertCount))")
                        }
                    }
                    .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, Spacing.xs)

            switch selectedTab {
            case .auditLog:
                auditLogTab
            case .alerts:
                alertsTab
            }
        }
        .navigationTitle("Security Log")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadAuditEntries()
        }
    }

    // MARK: - Audit Log Tab

    private var auditLogTab: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                TextField("Search audit log...", text: $searchText)
                    .textFieldStyle(.plain)
                    .accessibilityLabel("Search audit log")
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, Spacing.xs)
            .background(Color(.tertiarySystemGroupedBackground))

            // Event type filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    filterChip("All", isSelected: selectedEventFilter == nil) {
                        selectedEventFilter = nil
                        Task { await loadAuditEntries() }
                    }

                    ForEach(AuditEventType.allCases, id: \.self) { eventType in
                        filterChip(eventType.displayName, isSelected: selectedEventFilter == eventType) {
                            selectedEventFilter = eventType
                            Task { await loadAuditEntries() }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, Spacing.xs)
            }

            // Stats bar
            HStack {
                Text("\(filteredEntries.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Total on disk: \(entryCount)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, Spacing.xxs)
            .background(Color.gray.opacity(0.05))

            Divider()

            // Entries list
            if filteredEntries.isEmpty {
                emptyStateView(
                    icon: "shield.lefthalf.filled",
                    title: "No Audit Entries",
                    subtitle: searchText.isEmpty ? "Audit events will appear here as they occur" : "No entries match your search"
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredEntries) { entry in
                            auditEntryRow(entry)
                            Divider()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Alerts Tab

    private var alertsTab: some View {
        VStack(spacing: 0) {
            if securityMonitor.securityAlerts.isEmpty {
                emptyStateView(
                    icon: "checkmark.shield.fill",
                    title: "No Security Alerts",
                    subtitle: "All clear. No suspicious activity detected."
                )
            } else {
                // Actions bar
                HStack {
                    Text("\(securityMonitor.unacknowledgedAlertCount) unacknowledged")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Dismiss Reviewed") {
                        securityMonitor.dismissAcknowledgedAlerts()
                    }
                    .font(.caption)
                    .foregroundColor(.modusCyan)
                    .disabled(securityMonitor.securityAlerts.allSatisfy { !$0.acknowledged })
                }
                .padding(.horizontal)
                .padding(.vertical, Spacing.xs)
                .background(Color.gray.opacity(0.05))

                Divider()

                ScrollView {
                    LazyVStack(spacing: Spacing.xs) {
                        ForEach(securityMonitor.securityAlerts) { alert in
                            alertRow(alert)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, Spacing.xs)
                }
            }
        }
    }

    // MARK: - Subviews

    private func auditEntryRow(_ entry: AuditEntry) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack {
                eventTypeBadge(entry.eventType)
                Spacer()
                Text(formatTimestamp(entry.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(entry.action)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)

            HStack(spacing: Spacing.xs) {
                Label(entry.resource, systemImage: "doc")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let details = entry.details, !details.isEmpty {
                    Text(details)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
    }

    private func alertRow(_ alert: SecurityAlert) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: alert.severity.icon)
                .foregroundStyle(alert.severity.color)
                .font(.title3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack {
                    Text(alert.severity.rawValue)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(alert.severity.color)
                    Spacer()
                    Text(alert.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(alert.message)
                    .font(.subheadline)
                    .foregroundStyle(alert.acknowledged ? .secondary : .primary)

                if !alert.acknowledged {
                    Button("Acknowledge") {
                        securityMonitor.acknowledgeAlert(alert.id)
                    }
                    .font(.caption)
                    .foregroundColor(.modusCyan)
                } else {
                    Text("Acknowledged")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(alert.acknowledged ? Color.gray.opacity(0.05) : alert.severity.color.opacity(0.08))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(alert.severity.rawValue) alert: \(alert.message)")
    }

    private func filterChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(isSelected ? Color.modusCyan.opacity(0.2) : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .modusCyan : .secondary)
                .cornerRadius(CornerRadius.sm)
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func eventTypeBadge(_ eventType: AuditEventType) -> some View {
        Text(eventType.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, Spacing.xxs)
            .padding(.vertical, Spacing.xxs)
            .background(colorForEventType(eventType).opacity(0.15))
            .foregroundStyle(colorForEventType(eventType))
            .cornerRadius(CornerRadius.xs)
    }

    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Helpers

    private var filteredEntries: [AuditEntry] {
        if searchText.isEmpty {
            return auditEntries
        }

        return auditEntries.filter { entry in
            entry.action.localizedCaseInsensitiveContains(searchText) ||
            entry.resource.localizedCaseInsensitiveContains(searchText) ||
            (entry.details?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            entry.eventType.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func loadAuditEntries() async {
        let entries = await AuditLogger.shared.getRecentEntries(
            limit: 200,
            eventType: selectedEventFilter
        )
        let count = await AuditLogger.shared.getEntryCount()

        await MainActor.run {
            self.auditEntries = entries
            self.entryCount = count
        }
    }

    /// Cached ISO8601 formatter for parsing audit log timestamps
    private static let iso8601Formatter = ISO8601DateFormatter()

    /// Cached DateFormatter for displaying audit log timestamps
    private static let displayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, HH:mm:ss"
        return f
    }()

    private func formatTimestamp(_ isoString: String) -> String {
        guard let date = Self.iso8601Formatter.date(from: isoString) else { return isoString }
        return Self.displayDateFormatter.string(from: date)
    }

    private func colorForEventType(_ eventType: AuditEventType) -> Color {
        switch eventType {
        case .dataAccess: return .modusCyan
        case .dataModification: return .orange
        case .authentication: return .green
        case .authorization: return .purple
        case .export: return .teal
        case .deletion: return .red
        case .settingsChange: return .gray
        case .securityEvent: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SecurityLogView()
    }
}

#endif
