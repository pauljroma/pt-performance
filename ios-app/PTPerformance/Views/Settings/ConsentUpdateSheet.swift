// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  ConsentUpdateSheet.swift
//  PTPerformance
//
//  ACP-1049: Consent Management - Re-consent prompt
//  Shows when the consent policy version changes, requiring user acknowledgment
//

import SwiftUI

// MARK: - Consent Update Sheet

/// Full-screen sheet that prompts the user to review and acknowledge
/// updated privacy and consent terms. Presented when the consent version
/// changes (e.g., new data processing terms, updated privacy policy).
struct ConsentUpdateSheet: View {

    // MARK: - State

    @StateObject private var consentManager = ConsentManager.shared
    @State private var hasScrolledToBottom = false
    @State private var isAccepting = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    headerSection

                    // What changed
                    changesSection

                    // Consent summary
                    consentSummarySection

                    // Accept button
                    acceptSection

                    // Scroll indicator for tracking
                    Color.clear
                        .frame(height: 1)
                        .onAppear {
                            hasScrolledToBottom = true
                        }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Privacy Update")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.modusCyan.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                    .font(.system(size: 36))
                    .foregroundColor(.modusCyan)
            }
            .accessibilityHidden(true)

            Text("Our Privacy Terms Have Updated")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text("We have updated our privacy and data processing policies to version \(ConsentManager.currentConsentVersion). Please review the changes below before continuing.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Changes Section

    private var changesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("What Changed")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                changeItem(
                    icon: "brain.head.profile",
                    iconColor: .purple,
                    title: "AI Personalization Controls",
                    description: "New granular controls for how AI uses your data to provide personalized training recommendations."
                )

                Divider()
                    .padding(.leading, 52)

                changeItem(
                    icon: "figure.run",
                    iconColor: .modusCyan,
                    title: "Workout Data Sharing",
                    description: "Separate controls for sharing workout data with the platform and with your linked therapist."
                )

                Divider()
                    .padding(.leading, 52)

                changeItem(
                    icon: "chart.bar.fill",
                    iconColor: .modusTealAccent,
                    title: "Analytics Transparency",
                    description: "Clearer explanation of what analytics data is collected and how it is used to improve the app."
                )

                Divider()
                    .padding(.leading, 52)

                changeItem(
                    icon: "bell.badge.fill",
                    iconColor: .orange,
                    title: "Marketing Preferences",
                    description: "Separate opt-in controls for email and push notification marketing communications."
                )
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
    }

    private func changeItem(icon: String, iconColor: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 28)
                .padding(.top, 2)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Consent Summary Section

    private var consentSummarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Your Current Consents")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: Spacing.xs) {
                ForEach(PrivacyConsentType.allCases) { type in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: type.iconName)
                            .foregroundColor(type.iconColor)
                            .frame(width: 24)
                            .accessibilityHidden(true)

                        Text(type.displayName)
                            .font(.subheadline)

                        Spacer()

                        if type.isRequired {
                            Text("Required")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.modusCyan.opacity(0.2))
                                .foregroundColor(.modusCyan)
                                .cornerRadius(CornerRadius.xs)
                        } else {
                            Image(systemName: consentManager.isGranted(type) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(consentManager.isGranted(type) ? .green : .secondary)
                        }
                    }
                    .padding(.vertical, Spacing.xxs)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)

            Text("You can adjust individual consent settings at any time in Settings > Privacy & Data.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Accept Section

    private var acceptSection: some View {
        VStack(spacing: Spacing.sm) {
            // Accept and continue
            Button {
                acceptUpdate()
            } label: {
                HStack {
                    if isAccepting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(isAccepting ? "Updating..." : "I Acknowledge & Continue")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.modusCyan)
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.sm)
            }
            .disabled(isAccepting)
            .accessibilityLabel(isAccepting ? "Updating consents" : "Acknowledge and continue")
            .accessibilityHint("Acknowledges the updated privacy terms and continues to the app")

            // View full privacy policy
            Button {
                openPrivacyPolicy()
            } label: {
                HStack(spacing: Spacing.xxs) {
                    Text("View Full Privacy Policy")
                        .font(.subheadline)
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                }
                .foregroundColor(.modusCyan)
            }
            .accessibilityLabel("View full privacy policy")
            .accessibilityHint("Opens the complete privacy policy in your browser")

            Text("By continuing, you acknowledge that you have reviewed the updated privacy terms.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, Spacing.sm)
    }

    // MARK: - Actions

    private func acceptUpdate() {
        isAccepting = true
        HapticFeedback.success()

        // Small delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            consentManager.acknowledgeConsentVersion()
            isAccepting = false
        }
    }

    private func openPrivacyPolicy() {
        if let url = URL(string: "https://ptperformance.app/privacy") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ConsentUpdateSheet_Previews: PreviewProvider {
    static var previews: some View {
        ConsentUpdateSheet()
            .previewDisplayName("Consent Update Sheet")
    }
}
#endif
