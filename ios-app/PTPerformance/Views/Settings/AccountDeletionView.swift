// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  AccountDeletionView.swift
//  PTPerformance
//
//  Created by BUILD 119 on 2026-01-03
//  Purpose: Account deletion UI with confirmation flow
//  ACP-1048: Enhanced with data download prompt and deletion certificate
//

import SwiftUI

struct AccountDeletionView: View {

    @StateObject private var viewModel = AccountDeletionViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                downloadDataSection
                gracePeriodSection
                warningSection
                confirmationSection
                actionSection
            }
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Closes without deleting account")
                }
            }
            .alert("Account Scheduled for Deletion", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your account has been scheduled for deletion.\n\nReference: \(viewModel.deletionReferenceId)\nPermanent deletion: \(viewModel.permanentDeletionDateText)\n\nYou can cancel this request within the 30-day grace period by logging back in.")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .alert("Download Your Data First?", isPresented: $viewModel.showDownloadDataPrompt) {
                Button("Download My Data") {
                    Task {
                        await settingsViewModel.exportUserData()
                    }
                }
                Button("Skip, Continue to Delete", role: .destructive) {
                    // User chose to skip download
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("We recommend downloading a copy of your data before deleting your account. Once deleted, your data cannot be recovered after the 30-day grace period.")
            }
        }
    }

    // MARK: - Download Data Section

    private var downloadDataSection: some View {
        Section {
            Button {
                viewModel.promptDownloadData()
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "square.and.arrow.down.fill")
                        .foregroundColor(.modusCyan)
                        .frame(width: 28)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Download My Data")
                            .font(.body)
                            .foregroundStyle(.primary)
                        Text("Export a copy of all your data before deletion")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel("Download My Data")
            .accessibilityHint("Export a copy of all your data before deleting your account")
        } header: {
            Text("Before You Go")
        } footer: {
            Text("We recommend downloading your data before proceeding. This includes your workout history, progress, and health data.")
        }
    }

    // MARK: - Grace Period Section

    private var gracePeriodSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(DesignTokens.statusInfo)
                        .font(.title2)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("30-Day Grace Period")
                            .font(.headline)
                        Text("Your account will not be immediately deleted")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    gracePeriodStep(number: "1", text: "Account is marked for deletion today")
                    gracePeriodStep(number: "2", text: "You have 30 days to change your mind")
                    gracePeriodStep(number: "3", text: "Log back in anytime to cancel deletion")
                    gracePeriodStep(number: "4", text: "After 30 days, all data is permanently removed")
                }
                .padding(.top, Spacing.xxs)
            }
            .padding(.vertical, Spacing.xs)
        } header: {
            Text("How It Works")
        }
    }

    // MARK: - Warning Section

    private var warningSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Warning", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundColor(DesignTokens.statusError)
                    .accessibilityLabel("Warning")

                Text("Deleting your account will:")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    bulletPoint("Permanently delete all your data")
                    bulletPoint("Remove all your workout history")
                    bulletPoint("Cancel any active programs")
                    bulletPoint("Delete all your progress and analytics")
                    bulletPoint("Revoke all therapist access to your data")
                }

                Text("This action cannot be undone after the 30-day grace period.")
                    .font(.subheadline)
                    .foregroundStyle(DesignTokens.statusError)
                    .fontWeight(.medium)
                    .padding(.top, Spacing.xs)
            }
            .padding(.vertical, Spacing.xs)
        }
    }

    // MARK: - Confirmation Section

    private var confirmationSection: some View {
        Section(header: Text("Confirmation Required")) {
            SecureField("Enter your password", text: $viewModel.password)
                .textContentType(.password)
                .autocapitalization(.none)
                .accessibilityLabel("Password")
                .accessibilityHint("Enter your password to confirm account deletion")

            TextField("Type 'DELETE' to confirm", text: $viewModel.confirmationText)
                .autocapitalization(.allCharacters)
                .autocorrectionDisabled()
                .accessibilityLabel("Confirmation text")
                .accessibilityHint("Type DELETE in capital letters to confirm account deletion")

            if !viewModel.confirmationText.isEmpty && viewModel.confirmationText != "DELETE" {
                Text("Must type 'DELETE' exactly")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.statusError)
            }
        }
    }

    // MARK: - Action Section

    private var actionSection: some View {
        Section {
            Button(action: {
                Task {
                    await viewModel.deleteAccount()
                }
            }) {
                HStack {
                    if viewModel.isDeleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .accessibilityHidden(true)
                    }
                    Text(viewModel.isDeleting ? "Deleting..." : "Delete My Account")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .foregroundStyle(DesignTokens.buttonTextOnAccent)
            .listRowBackground(viewModel.isFormValid ? DesignTokens.statusError : Color(.secondaryLabel))
            .disabled(!viewModel.isFormValid || viewModel.isDeleting)
            .accessibilityLabel(viewModel.isDeleting ? "Deleting account" : "Delete My Account")
            .accessibilityHint(viewModel.isFormValid ? "Permanently deletes your account after confirmation" : "Complete password and confirmation fields to enable")
        }
    }

    // MARK: - Helper Views

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Text("\u{2022}")
            Text(text)
                .font(.subheadline)
        }
    }

    private func gracePeriodStep(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text(number)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(DesignTokens.statusInfo)
                .clipShape(Circle())
                .accessibilityHidden(true)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    AccountDeletionView()
}
