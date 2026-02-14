// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  DataConsentView.swift
//  PTPerformance
//
//  X2Index Phase 2 - Consent Management (M1)
//  Full-screen consent management view for HIPAA-compliant data access control
//

import SwiftUI

/// Full-screen view for managing consent for external data sources
/// Implements X2Index M1 requirements: granular toggles, revocation, privacy policy link
struct DataConsentView: View {

    // MARK: - State

    @StateObject private var viewModel = DataConsentViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    headerSection

                    // Status summary
                    statusSummaryCard

                    // Data sources list
                    dataSourcesSection

                    // Privacy section
                    privacySection

                    // Revoke all button
                    if viewModel.hasAnyActiveConsent {
                        revokeAllSection
                    }

                    // Audit log link
                    auditLogSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Data Access")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadConsents()
            }
            .refreshableWithHaptic {
                await viewModel.loadConsents()
            }
            .alert("Success", isPresented: $viewModel.showingSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.successMessage)
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.clearError() } }
            )) {
                Button("OK", role: .cancel) {
                    viewModel.clearError()
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
            .confirmationDialog(
                "Revoke All Access",
                isPresented: $viewModel.showingRevokeAllConfirmation,
                titleVisibility: .visible
            ) {
                Button("Revoke All", role: .destructive) {
                    Task {
                        await viewModel.revokeAll()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will immediately revoke access to all connected data sources. You can re-enable them at any time.")
            }
            .sheet(isPresented: $viewModel.showingAuditLog) {
                ConsentAuditLogView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 48))
                .foregroundColor(Color.modusCyan)
                .accessibilityHidden(true)

            Text("Control Your Data")
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            Text("Choose which external sources can share data with Modus. You can change these settings at any time.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Status Summary Card

    private var statusSummaryCard: some View {
        HStack(spacing: Spacing.lg) {
            // Active connections
            VStack(spacing: Spacing.xxs) {
                Text("\(viewModel.activeConsentCount)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color.modusCyan)

                Text("Active")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            // Total sources
            VStack(spacing: Spacing.xxs) {
                Text("\(viewModel.allDataSources.count)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)

                Text("Available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.activeConsentCount) of \(viewModel.allDataSources.count) data sources connected")
    }

    // MARK: - Data Sources Section

    private var dataSourcesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Data Sources")
                .font(.headline)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, Spacing.xxs)

            if viewModel.isLoading {
                loadingView
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(viewModel.allDataSources) { dataSource in
                        ConsentToggleRow(
                            dataSource: dataSource,
                            isEnabled: viewModel.hasActiveConsent(for: dataSource),
                            isToggling: viewModel.isToggling(dataSource: dataSource),
                            lastUpdated: viewModel.lastUpdated(for: dataSource),
                            onToggle: {
                                Task {
                                    await viewModel.toggleConsent(dataSource: dataSource)
                                }
                            }
                        )
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ForEach(0..<4) { _ in
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(height: 100)
                    .shimmer(isAnimating: true)
            }
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Privacy & Security")
                .font(.headline)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, Spacing.xxs)

            VStack(spacing: 0) {
                // HIPAA compliance note
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(Color.modusTealAccent)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("HIPAA Compliant")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("Your health data is encrypted and securely stored")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()

                Divider()
                    .padding(.leading, 52)

                // Data usage
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .foregroundColor(Color.modusCyan)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Data Usage")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("Used only for personalized training insights")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()

                Divider()
                    .padding(.leading, 52)

                // Privacy policy link
                Button {
                    openPrivacyPolicy()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "doc.text")
                            .foregroundColor(Color.modusDeepTeal)
                            .frame(width: 28)

                        Text("Privacy Policy")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                .accessibilityLabel("View Privacy Policy")
                .accessibilityHint("Opens privacy policy in browser")
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Revoke All Section

    private var revokeAllSection: some View {
        VStack(spacing: Spacing.sm) {
            Button {
                HapticFeedback.warning()
                viewModel.showingRevokeAllConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "xmark.shield")
                    Text("Revoke All Access")
                }
                .font(.headline)
                .foregroundColor(DesignTokens.statusError)
                .frame(maxWidth: .infinity)
                .padding()
                .background(DesignTokens.statusError.opacity(0.1))
                .cornerRadius(CornerRadius.md)
            }
            .disabled(viewModel.isSaving)

            Text("This will disconnect all data sources immediately")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Audit Log Section

    private var auditLogSection: some View {
        Button {
            HapticFeedback.light()
            Task {
                await viewModel.loadAuditLog()
                viewModel.showingAuditLog = true
            }
        } label: {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .foregroundColor(Color.modusCyan)

                Text("View Consent History")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
        .accessibilityLabel("View consent history")
        .accessibilityHint("Shows a log of all consent changes")
    }

    // MARK: - Helper Methods

    private func openPrivacyPolicy() {
        if let url = URL(string: "https://ptperformance.app/privacy") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Consent Audit Log View

/// Sheet view displaying the consent audit log
struct ConsentAuditLogView: View {

    @ObservedObject var viewModel: DataConsentViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingAuditLog {
                    ProgressView("Loading history...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.auditLog.isEmpty {
                    emptyState
                } else {
                    auditLogList
                }
            }
            .navigationTitle("Consent History")
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

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No History Yet")
                .font(.headline)

            Text("Consent changes will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var auditLogList: some View {
        List {
            ForEach(viewModel.auditLog) { entry in
                auditLogRow(entry: entry)
            }
        }
        .listStyle(.insetGrouped)
    }

    private func auditLogRow(entry: ConsentAuditEntry) -> some View {
        HStack(spacing: Spacing.sm) {
            // Action icon
            actionIcon(for: entry.action)
                .frame(width: 32, height: 32)
                .background(actionBackgroundColor(for: entry.action))
                .cornerRadius(CornerRadius.sm)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.actionDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(formatTimestamp(entry.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let ip = entry.ipAddress {
                    Text("IP: \(ip)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func actionIcon(for action: ConsentAction) -> some View {
        Image(systemName: actionIconName(for: action))
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(actionIconColor(for: action))
    }

    private func actionIconName(for action: ConsentAction) -> String {
        switch action {
        case .granted:
            return "checkmark"
        case .revoked:
            return "xmark"
        case .created:
            return "plus"
        }
    }

    private func actionIconColor(for action: ConsentAction) -> Color {
        switch action {
        case .granted:
            return DesignTokens.statusSuccess
        case .revoked:
            return DesignTokens.statusError
        case .created:
            return DesignTokens.statusInfo
        }
    }

    private func actionBackgroundColor(for action: ConsentAction) -> Color {
        switch action {
        case .granted:
            return DesignTokens.statusSuccess.opacity(0.15)
        case .revoked:
            return DesignTokens.statusError.opacity(0.15)
        case .created:
            return DesignTokens.statusInfo.opacity(0.15)
        }
    }

    private static let mediumDateShortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private func formatTimestamp(_ date: Date) -> String {
        Self.mediumDateShortTimeFormatter.string(from: date)
    }
}

// Note: Using ShimmerModifier from Utils/LoadingStateView.swift

// MARK: - Preview

#if DEBUG
struct DataConsentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DataConsentView()
                .previewDisplayName("Default")

            DataConsentView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
#endif
