import SwiftUI

/// Prompt shown before first AI feature use to get explicit consent
/// per Apple guideline 5.1.1(i) / 5.1.2(i)
struct AIConsentPromptView: View {
    @Environment(\.dismiss) private var dismiss
    let onConsent: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.purple)
                    }
                    .padding(.top, Spacing.lg)
                    .accessibilityHidden(true)

                    Text("AI-Powered Coaching")
                        .font(.title2.bold())

                    Text("This feature uses AI to provide personalized training recommendations based on your data.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)

                    // Data disclosure
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        disclosureRow(
                            icon: "doc.text",
                            title: "What data is sent",
                            detail: "Your workout history, readiness scores, recovery metrics, and health goals are sent to generate coaching insights."
                        )

                        disclosureRow(
                            icon: "building.2",
                            title: "Who receives it",
                            detail: "Data is processed by OpenAI's API through our secure server. It is not used to train AI models."
                        )

                        disclosureRow(
                            icon: "lock.shield",
                            title: "How it's protected",
                            detail: "Data is encrypted in transit and not stored by OpenAI. You can revoke access at any time in Settings > Data Access."
                        )
                    }
                    .padding(Spacing.md)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)
                    .padding(.horizontal, Spacing.md)

                    // Privacy policy link
                    Link(destination: URL(string: "https://getmodus.app/privacy")!) {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "doc.text")
                                .font(.caption)
                            Text("View Privacy Policy")
                                .font(.footnote)
                        }
                        .foregroundColor(.modusCyan)
                    }

                    Spacer().frame(height: Spacing.sm)

                    // Consent button
                    Button {
                        HapticFeedback.medium()
                        ConsentManager.shared.grantConsent(type: .aiPersonalization)
                        onConsent()
                        dismiss()
                    } label: {
                        Text("Allow AI Coaching")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.purple)
                            .foregroundStyle(.white)
                            .cornerRadius(CornerRadius.lg)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .accessibilityLabel("Allow AI coaching with OpenAI data processing")

                    // Decline
                    Button {
                        HapticFeedback.light()
                        dismiss()
                    } label: {
                        Text("Not Now")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, Spacing.lg)
                    .accessibilityLabel("Decline AI coaching")
                }
            }
            .navigationTitle("AI Data Usage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }

    private func disclosureRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.purple)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
