//
//  PrivacyNoticeView.swift
//  PTPerformance
//
//  Created by BUILD 119 on 2026-01-03
//  Purpose: Privacy notice on first launch (HIPAA Privacy Rule requirement)
//

import SwiftUI

struct PrivacyNoticeView: View {

    @AppStorage("hasAcceptedPrivacyNotice") private var hasAccepted = false
    @State private var isAccepting = false
    @State private var errorMessage: String?

    let onAccept: () -> Void

    // MARK: - BUILD 121 Hotfix: Codable Models

    /// Codable struct for privacy consent insertion
    private struct PrivacyConsentInsert: Codable {
        let user_id: String
        let consented_at: String
        let app_version: String
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    privacyPolicyContent
                    consentSection
                }
                .padding()
            }
            .navigationTitle("Privacy Notice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isAccepting {
                        ProgressView()
                    }
                }
            }
        }
        .interactiveDismissDisabled() // Cannot dismiss without accepting
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            Text("Your Privacy Matters")
                .font(.title)
                .fontWeight(.bold)

            Text("Before you continue, please review our privacy practices.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var privacyPolicyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            privacySection(
                icon: "lock.shield.fill",
                title: "Protected Health Information",
                description: "Your workout data, health metrics, and personal information are protected under HIPAA regulations."
            )

            privacySection(
                icon: "eye.slash.fill",
                title: "Data Access Control",
                description: "Only you and your assigned therapist can access your data. We use role-based access control to protect your information."
            )

            privacySection(
                icon: "checkmark.seal.fill",
                title: "Secure Storage",
                description: "All data is encrypted at rest and in transit using AES-256 encryption and TLS 1.3."
            )

            privacySection(
                icon: "clock.fill",
                title: "Audit Logging",
                description: "All access to your data is logged for compliance and security purposes. You can request an accounting of disclosures at any time."
            )

            privacySection(
                icon: "trash.fill",
                title: "Right to Deletion",
                description: "You can request deletion of your account and all associated data at any time with a 30-day grace period."
            )

            Divider()
                .padding(.vertical)

            Text("By continuing, you acknowledge that you have read and understood our privacy practices.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var consentSection: some View {
        VStack(spacing: 16) {
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Button(action: acceptPrivacyNotice) {
                HStack {
                    if isAccepting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(isAccepting ? "Recording Consent..." : "I Accept")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isAccepting)

            Text("You must accept to use the app")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top)
    }

    private func privacySection(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func acceptPrivacyNotice() {
        isAccepting = true
        errorMessage = nil

        Task {
            // Try to record consent in database (optional - don't block user if it fails)
            do {
                try await recordConsent()
                DebugLogger.shared.log("✅ Privacy consent recorded in database", level: .success)
            } catch {
                DebugLogger.shared.log("⚠️ Failed to record consent in DB (non-blocking): \(error.localizedDescription)", level: .warning)
                // Don't block user - consent still valid locally
            }

            // Mark as accepted locally (always succeeds)
            hasAccepted = true

            // Notify parent and proceed
            await MainActor.run {
                isAccepting = false
                onAccept()
            }
        }
    }

    private func recordConsent() async throws {
        let client = PTSupabaseClient.shared.client

        let userId = try await client.auth.session.user.id

        // Create consent record using Codable struct (BUILD 121 fix)
        let consentData = PrivacyConsentInsert(
            user_id: userId.uuidString,
            consented_at: ISO8601DateFormatter().string(from: Date()),
            app_version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        )

        // Insert consent record
        try await client.from("privacy_consents")
            .insert(consentData)
            .execute()
    }
}

enum PrivacyNoticeError: Error {
    case notAuthenticated
}

#Preview {
    PrivacyNoticeView(onAccept: {})
}
