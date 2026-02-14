// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  AccountDeletionView.swift
//  PTPerformance
//
//  Created by BUILD 119 on 2026-01-03
//  Purpose: Account deletion UI with confirmation flow
//

import SwiftUI

struct AccountDeletionView: View {

    @StateObject private var viewModel = AccountDeletionViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
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
                Text("Your account will be permanently deleted in 30 days. You can cancel this request within the grace period by logging in.")
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
        }
    }

    private var warningSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label("Warning", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundColor(DesignTokens.statusError)
                    .accessibilityLabel("Warning")

                Text("Deleting your account will:")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint("Permanently delete all your data")
                    bulletPoint("Remove all your workout history")
                    bulletPoint("Cancel any active programs")
                    bulletPoint("Delete all your progress and analytics")
                }

                Text("This action cannot be undone after the 30-day grace period.")
                    .font(.subheadline)
                    .foregroundColor(DesignTokens.statusError)
                    .fontWeight(.medium)
                    .padding(.top, Spacing.xs)

                Text("30-Day Grace Period: You can cancel this request within 30 days by logging in.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, Spacing.xs)
            }
            .padding(.vertical, Spacing.xs)
        }
    }

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
                    .foregroundColor(DesignTokens.statusError)
            }
        }
    }

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
            .foregroundColor(DesignTokens.buttonTextOnAccent)
            .listRowBackground(viewModel.isFormValid ? DesignTokens.statusError : Color(.secondaryLabel))
            .disabled(!viewModel.isFormValid || viewModel.isDeleting)
            .accessibilityLabel(viewModel.isDeleting ? "Deleting account" : "Delete My Account")
            .accessibilityHint(viewModel.isFormValid ? "Permanently deletes your account after confirmation" : "Complete password and confirmation fields to enable")
        }
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    AccountDeletionView()
}
