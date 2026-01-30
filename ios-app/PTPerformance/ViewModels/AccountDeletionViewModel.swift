//
//  AccountDeletionViewModel.swift
//  PTPerformance
//
//  Created by BUILD 119 on 2026-01-03
//  Purpose: Account deletion with 30-day grace period (GDPR Right to Erasure)
//

import Foundation
import SwiftUI
import Supabase

@MainActor
final class AccountDeletionViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var password = ""
    @Published var confirmationText = ""
    @Published var isDeleting = false
    @Published var errorMessage: String?
    @Published var showSuccessAlert = false

    // MARK: - Constants

    private let requiredConfirmationText = "DELETE"
    private let gracePeriodDays = 30

    // MARK: - Computed Properties

    var isFormValid: Bool {
        !password.isEmpty && confirmationText == requiredConfirmationText
    }

    // MARK: - Methods

    func deleteAccount() async {
        guard isFormValid else {
            errorMessage = "To confirm deletion, please enter your password and type 'DELETE' in the confirmation field."
            return
        }

        isDeleting = true
        errorMessage = nil

        do {
            // Step 1: Re-authenticate user with password
            try await reauthenticateUser(password: password)

            // Step 2: Mark account for deletion (30-day grace period)
            try await markAccountForDeletion()

            // Step 3: Show success message
            isDeleting = false
            showSuccessAlert = true

            // Step 4: Log out user after 3 seconds
            try await Task.sleep(nanoseconds: 3_000_000_000)
            await signOut()

        } catch {
            isDeleting = false
            errorMessage = handleError(error)
        }
    }

    private func reauthenticateUser(password: String) async throws {
        // Re-authenticate with Supabase
        let client = PTSupabaseClient.shared.client

        let session = try await client.auth.session

        let email = session.user.email ?? ""

        // Re-authenticate to confirm identity
        _ = try await client.auth.signIn(email: email, password: password)
    }

    private func markAccountForDeletion() async throws {
        let client = PTSupabaseClient.shared.client

        let userId = try await client.auth.session.user.id

        // Call edge function to mark account for deletion
        let bodyData = try JSONEncoder().encode([
            "user_id": userId.uuidString,
            "grace_period_days": String(gracePeriodDays)
        ])

        // Call edge function - if it throws, an error occurred
        try await client.functions.invoke(
            "delete-patient-account",
            options: FunctionInvokeOptions(body: bodyData)
        )
    }

    private func signOut() async {
        let client = PTSupabaseClient.shared.client
        try? await client.auth.signOut()

        // Stop session monitoring
        SessionManager.shared.stopMonitoring()
    }

    private func handleError(_ error: Error) -> String {
        if let deletionError = error as? AccountDeletionError {
            return deletionError.localizedDescription
        }
        return "We couldn't delete your account right now. Please try again or contact support for help."
    }

    func cancelDeletion() async throws {
        let client = PTSupabaseClient.shared.client

        let userId = try await client.auth.session.user.id

        // Call edge function to cancel deletion
        let bodyData = try JSONEncoder().encode(["user_id": userId.uuidString])
        _ = try await client.functions.invoke(
            "cancel-account-deletion",
            options: FunctionInvokeOptions(body: bodyData)
        )
    }
}

// MARK: - Error Types

enum AccountDeletionError: LocalizedError {
    case notAuthenticated
    case invalidPassword
    case deletionFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to delete your account."
        case .invalidPassword:
            return "The password you entered is incorrect. Please try again."
        case .deletionFailed:
            return "We couldn't delete your account. Please contact support for assistance."
        }
    }
}
