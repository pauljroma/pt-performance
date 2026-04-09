// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  PrivacySettingsView.swift
//  PTPerformance
//
//  ACP-1046: Granular Privacy Settings
//  User-controlled privacy toggles for workout data, health metrics, analytics, and more
//

import SwiftUI

// MARK: - Privacy Settings View

/// Granular privacy settings view with organized toggle sections,
/// clear explanations, data minimization info, and revoke-all capability.
struct PrivacySettingsView: View {

    // MARK: - State

    @StateObject private var consentManager = ConsentManager.shared
    @State private var showRevokeAllConfirmation = false
    @State private var showPrivacyPolicy = false

    // MARK: - Body

    var body: some View {
        List {
            // Status summary
            statusSection

            // Consent category sections
            ForEach(PrivacyConsentCategory.allCases, id: \.rawValue) { category in
                consentCategorySection(category)
            }

            // Data minimization info
            dataMinimizationSection

            // Privacy policy link
            privacyPolicySection

            // Revoke all
            revokeAllSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Privacy & Data")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog(
            "Revoke All Optional Consents",
            isPresented: $showRevokeAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Revoke All", role: .destructive) {
                HapticFeedback.warning()
                consentManager.withdrawAllOptionalConsents()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will withdraw all optional consents. Required consents for core app functionality will remain active. You can re-enable any consent at any time.")
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        Section {
            HStack(spacing: Spacing.md) {
                // Consent status circle
                ZStack {
                    Circle()
                        .fill(consentManager.allConsentsUpToDate ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: consentManager.allConsentsUpToDate ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .font(.title2)
                        .foregroundStyle(consentManager.allConsentsUpToDate ? .green : .orange)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Privacy Status")
                        .font(.headline)

                    Text(consentManager.statusSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Active count badge
                Text("\(consentManager.activeConsentCount)/\(consentManager.totalConsentCount)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxs)
                    .background(Color.modusCyan.opacity(0.15))
                    .foregroundColor(.modusCyan)
                    .cornerRadius(CornerRadius.xs)
            }
            .padding(.vertical, Spacing.xs)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Privacy status: \(consentManager.statusSummary)")
        } header: {
            HStack {
                Image(systemName: "hand.raised.fill")
                    .foregroundColor(.modusCyan)
                Text("Overview")
            }
            .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: - Consent Category Section

    private func consentCategorySection(_ category: PrivacyConsentCategory) -> some View {
        Section {
            ForEach(category.consentTypes) { consentType in
                consentToggleRow(consentType)
            }
        } header: {
            HStack {
                Image(systemName: category.iconName)
                    .foregroundColor(.modusCyan)
                Text(category.displayName)
            }
            .accessibilityAddTraits(.isHeader)
        } footer: {
            categoryFooterText(category)
        }
    }

    // MARK: - Consent Toggle Row

    private func consentToggleRow(_ type: PrivacyConsentType) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Toggle(isOn: consentManager.binding(for: type)) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: type.iconName)
                        .foregroundStyle(type.iconColor)
                        .frame(width: 28)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        HStack(spacing: Spacing.xs) {
                            Text(type.displayName)
                                .font(.body)

                            if type.isRequired {
                                Text("Required")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, Spacing.xxs)
                                    .padding(.vertical, Spacing.xxs)
                                    .background(Color.modusCyan.opacity(0.2))
                                    .foregroundColor(.modusCyan)
                                    .cornerRadius(CornerRadius.xs)
                            }
                        }

                        Text(type.explanation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .tint(.modusCyan)
            .disabled(type.isRequired)
            .onChange(of: consentManager.isGranted(type)) { _, _ in
                HapticFeedback.toggle()
            }

            // Show last action date if available
            if let record = consentManager.consents[type],
               let actionDate = record.isGranted ? record.grantedAt : record.withdrawnAt {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(record.isGranted ? "Granted" : "Withdrawn")
                        .font(.caption2)
                    Text(actionDate, style: .relative)
                        .font(.caption2)
                    Text("ago")
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
                .padding(.leading, Spacing.xl + Spacing.xs)
            }
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.displayName), \(consentManager.isGranted(type) ? "enabled" : "disabled")")
        .accessibilityHint(type.explanation)
    }

    // MARK: - Category Footer

    @ViewBuilder
    private func categoryFooterText(_ category: PrivacyConsentCategory) -> some View {
        switch category {
        case .dataSharing:
            Text("Controls what personal data is shared with the Korza platform and your care team. Disabling sharing may limit some features.")
        case .analyticsPersonalization:
            Text("Analytics data is anonymized and never sold to third parties. AI personalization uses your data only within the app.")
        case .marketing:
            Text("Marketing communications are always optional. You can unsubscribe from any channel at any time.")
        }
    }

    // MARK: - Data Minimization Section

    private var dataMinimizationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundColor(.modusCyan)
                        .font(.title3)
                        .accessibilityHidden(true)

                    Text("Data Minimization")
                        .font(.headline)
                }

                dataMinimizationItem(
                    title: "Workout Data",
                    detail: "Exercise names, sets, reps, weights, and duration. Used for progress tracking and program recommendations.",
                    icon: "dumbbell.fill"
                )

                dataMinimizationItem(
                    title: "Health Metrics",
                    detail: "Heart rate, sleep, recovery, and HRV when synced from Apple Health or wearables. Used for readiness scores.",
                    icon: "heart.fill"
                )

                dataMinimizationItem(
                    title: "Usage Analytics",
                    detail: "Feature usage frequency and session duration. Anonymized and aggregated. Never includes personal health data.",
                    icon: "chart.bar.fill"
                )

                dataMinimizationItem(
                    title: "Device Information",
                    detail: "Device model and OS version for crash reporting and compatibility. IP addresses are not permanently stored.",
                    icon: "iphone"
                )
            }
            .padding(.vertical, Spacing.xs)
        } header: {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(.modusTealAccent)
                Text("What We Collect")
            }
            .accessibilityAddTraits(.isHeader)
        } footer: {
            Text("We follow the principle of data minimization: we only collect what is necessary to provide our services. All data is encrypted at rest and in transit.")
        }
    }

    private func dataMinimizationItem(title: String, detail: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Privacy Policy Section

    private var privacyPolicySection: some View {
        Section {
            Button {
                HapticFeedback.light()
                openPrivacyPolicy()
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.modusDeepTeal)
                        .frame(width: 28)
                        .accessibilityHidden(true)

                    Text("View Full Privacy Policy")
                        .font(.body)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityLabel("View full privacy policy")
            .accessibilityHint("Opens the privacy policy in your browser")

            // HIPAA compliance note
            HStack(spacing: Spacing.sm) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.modusTealAccent)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("HIPAA Compliant")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("All health data is protected under HIPAA regulations with AES-256 encryption")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, Spacing.xxs)
            .accessibilityElement(children: .combine)
        } header: {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.modusDeepTeal)
                Text("Legal")
            }
            .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: - Revoke All Section

    private var revokeAllSection: some View {
        Section {
            Button {
                HapticFeedback.warning()
                showRevokeAllConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "xmark.shield")
                        .accessibilityHidden(true)
                    Text("Revoke All Optional Consents")
                }
                .font(.headline)
                .foregroundStyle(DesignTokens.statusError)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, Spacing.xs)
            }
            .accessibilityLabel("Revoke all optional consents")
            .accessibilityHint("Withdraws all non-required consents. You can re-enable them individually.")
        } footer: {
            Text("Required consents for core app functionality cannot be revoked. All other consents can be individually re-enabled at any time.")
        }
    }

    // MARK: - Helpers

    private func openPrivacyPolicy() {
        if let url = URL(string: "https://getmodus.app/privacy") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PrivacySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PrivacySettingsView()
        }
        .previewDisplayName("Privacy Settings")
    }
}
#endif
