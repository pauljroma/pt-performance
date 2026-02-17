//
//  NotificationPermissionView.swift
//  PTPerformance
//
//  ACP-1002: Push Notification Strategy
//  Pre-permission prompt shown during onboarding or after first workout
//  to explain notification benefits before triggering the system prompt.
//

import SwiftUI

// MARK: - Notification Permission View

/// Pre-permission screen that explains notification benefits before
/// asking the user for system notification permission.
///
/// This pattern avoids the "one-shot" denial problem: if the user
/// taps "Not Now" here, we never show the system prompt and can
/// ask again later. If they tap "Enable", we show the real system prompt.
struct NotificationPermissionView: View {

    // MARK: - Properties

    /// Callback when the user makes a decision (true = enabled, false = skipped).
    var onComplete: (Bool) -> Void

    @State private var isRequesting = false
    @State private var permissionGranted: Bool?
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Illustration
            illustrationSection

            Spacer()
                .frame(height: Spacing.xl)

            // Headline
            Text("Stay on Track")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
                .accessibilityAddTraits(.isHeader)

            Spacer()
                .frame(height: Spacing.sm)

            Text("Get timely reminders to keep your training consistent")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            Spacer()
                .frame(height: Spacing.xl)

            // Benefits list
            benefitsList

            Spacer()

            // Buttons
            buttonsSection
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.lg)
        .background(Color(.systemBackground))
    }

    // MARK: - Illustration

    private var illustrationSection: some View {
        ZStack {
            Circle()
                .fill(Color.modusCyan.opacity(0.12))
                .frame(width: 120, height: 120)

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.modusCyan)
                .symbolRenderingMode(.hierarchical)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Benefits List

    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            benefitRow(
                icon: "clock.fill",
                title: "Workout Reminders",
                description: "Never miss a scheduled session"
            )

            benefitRow(
                icon: "flame.fill",
                title: "Streak Alerts",
                description: "Get notified before your streak is at risk"
            )

            benefitRow(
                icon: "chart.bar.fill",
                title: "Progress Updates",
                description: "Weekly summaries of your achievements"
            )
        }
        .padding(.horizontal, Spacing.md)
    }

    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.modusCyan)
                .frame(width: 32, height: 32)
                .background(Color.modusCyan.opacity(0.1))
                .cornerRadius(CornerRadius.sm)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Buttons

    private var buttonsSection: some View {
        VStack(spacing: Spacing.sm) {
            // Primary CTA
            Button(action: handleEnableNotifications) {
                HStack {
                    if isRequesting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "bell.fill")
                        Text("Enable Notifications")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.modusCyan)
                .cornerRadius(CornerRadius.md)
            }
            .disabled(isRequesting)
            .accessibilityLabel("Enable Notifications")
            .accessibilityHint("Requests permission to send you push notifications")

            // Secondary link
            Button(action: handleSkip) {
                Text("Not Now")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, Spacing.xs)
            }
            .accessibilityLabel("Not Now")
            .accessibilityHint("Skip notification setup. You can enable later in Settings.")
        }
    }

    // MARK: - Actions

    private func handleEnableNotifications() {
        isRequesting = true
        HapticFeedback.medium()

        DebugLogger.shared.info("NotificationPermissionView", "User tapped Enable Notifications")

        Task {
            let granted = await PushNotificationService.shared.requestPermission()
            await MainActor.run {
                isRequesting = false
                permissionGranted = granted

                if granted {
                    HapticFeedback.success()
                    DebugLogger.shared.success("NotificationPermissionView", "Permission granted via pre-prompt")
                } else {
                    DebugLogger.shared.log("Permission denied via system prompt", level: .warning)
                }

                onComplete(granted)
            }
        }
    }

    private func handleSkip() {
        HapticFeedback.light()
        DebugLogger.shared.info("NotificationPermissionView", "User skipped notification permission")

        ErrorLogger.shared.logUserAction(
            action: "notification_permission_skipped",
            properties: [:]
        )

        onComplete(false)
    }
}

// MARK: - Preview

#if DEBUG
struct NotificationPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationPermissionView { _ in
        }
    }
}
#endif
