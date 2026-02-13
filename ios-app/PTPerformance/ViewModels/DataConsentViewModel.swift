//
//  DataConsentViewModel.swift
//  PTPerformance
//
//  X2Index Phase 2 - Consent Management (M1)
//  ViewModel for managing data consent UI state
//

import SwiftUI

/// ViewModel for the Data Consent management view
/// Handles loading, toggling, and revoking consent for external data sources
@MainActor
class DataConsentViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var consents: [DataConsent] = []
    @Published var auditLog: [ConsentAuditEntry] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var isLoadingAuditLog = false
    @Published var error: AppError?
    @Published var showingSuccessAlert = false
    @Published var showingRevokeAllConfirmation = false
    @Published var showingAuditLog = false
    @Published var successMessage: String = ""

    /// Tracks which data sources are currently being toggled
    @Published var togglingDataSources: Set<DataSource> = []

    // MARK: - Private Properties

    private let consentService = ConsentService.shared
    private let supabase = PTSupabaseClient.shared

    // MARK: - Computed Properties

    /// Patient ID from the current session
    var patientId: UUID? {
        guard let idString = supabase.userId else { return nil }
        return UUID(uuidString: idString)
    }

    /// All available data sources
    var allDataSources: [DataSource] {
        DataSource.allCases
    }

    /// Data sources with active consent
    var activeConsents: [DataConsent] {
        consents.filter { $0.isActive }
    }

    /// Data sources with revoked consent
    var revokedConsents: [DataConsent] {
        consents.filter { $0.consentStatus == .revoked }
    }

    /// Count of active consents
    var activeConsentCount: Int {
        activeConsents.count
    }

    /// Whether any consents are active
    var hasAnyActiveConsent: Bool {
        !activeConsents.isEmpty
    }

    // MARK: - Data Loading

    /// Loads all consents for the current patient
    func loadConsents() async {
        guard let patientId = patientId else {
            error = AppError.custom("Not logged in")
            return
        }

        isLoading = true
        error = nil

        consents = await consentService.getConsents(for: patientId)

        isLoading = false

        DebugLogger.shared.log("[DataConsentViewModel] Loaded \(consents.count) consents", level: .success)
    }

    /// Loads the consent audit log
    func loadAuditLog() async {
        guard let patientId = patientId else {
            error = AppError.custom("Not logged in")
            return
        }

        isLoadingAuditLog = true

        auditLog = await consentService.getConsentAuditLog(patientId: patientId)

        isLoadingAuditLog = false

        DebugLogger.shared.log("[DataConsentViewModel] Loaded \(auditLog.count) audit entries", level: .success)
    }

    // MARK: - Consent Management

    /// Toggles consent for a data source
    /// - Parameter dataSource: The data source to toggle
    func toggleConsent(dataSource: DataSource) async {
        guard let patientId = patientId else {
            error = AppError.custom("Not logged in")
            return
        }

        // Mark as toggling
        togglingDataSources.insert(dataSource)

        do {
            // Check current status
            let currentConsent = consents.first { $0.dataSource == dataSource }
            let isCurrentlyGranted = currentConsent?.isActive ?? false

            if isCurrentlyGranted {
                // Revoke consent
                try await consentService.revokeConsent(patientId: patientId, dataSource: dataSource)
                successMessage = "\(dataSource.displayName) access revoked"
            } else {
                // Grant consent
                try await consentService.grantConsent(patientId: patientId, dataSource: dataSource)
                successMessage = "\(dataSource.displayName) access granted"
            }

            // Reload consents to get updated state
            await loadConsents()

            showingSuccessAlert = true

        } catch {
            self.error = AppError.from(error)
            DebugLogger.shared.log("[DataConsentViewModel] Error toggling consent: \(error.localizedDescription)", level: .error)
        }

        // Clear toggling state
        togglingDataSources.remove(dataSource)
    }

    /// Grants consent for a data source
    /// - Parameter dataSource: The data source to grant consent for
    func grantConsent(dataSource: DataSource) async {
        guard let patientId = patientId else {
            error = AppError.custom("Not logged in")
            return
        }

        togglingDataSources.insert(dataSource)

        do {
            try await consentService.grantConsent(patientId: patientId, dataSource: dataSource)
            await loadConsents()

            successMessage = "\(dataSource.displayName) access granted"
            showingSuccessAlert = true
        } catch {
            self.error = AppError.from(error)
        }

        togglingDataSources.remove(dataSource)
    }

    /// Revokes consent for a data source
    /// - Parameter dataSource: The data source to revoke consent for
    func revokeConsent(dataSource: DataSource) async {
        guard let patientId = patientId else {
            error = AppError.custom("Not logged in")
            return
        }

        togglingDataSources.insert(dataSource)

        do {
            try await consentService.revokeConsent(patientId: patientId, dataSource: dataSource)
            await loadConsents()

            successMessage = "\(dataSource.displayName) access revoked"
            showingSuccessAlert = true
        } catch {
            self.error = AppError.from(error)
        }

        togglingDataSources.remove(dataSource)
    }

    /// Revokes all active consents
    func revokeAll() async {
        guard let patientId = patientId else {
            error = AppError.custom("Not logged in")
            return
        }

        isSaving = true
        error = nil

        do {
            try await consentService.revokeAllConsents(patientId: patientId)
            await loadConsents()

            successMessage = "All data access revoked"
            showingSuccessAlert = true

            DebugLogger.shared.log("[DataConsentViewModel] Revoked all consents", level: .success)
        } catch {
            self.error = AppError.from(error)
            DebugLogger.shared.log("[DataConsentViewModel] Error revoking all: \(error.localizedDescription)", level: .error)
        }

        isSaving = false
        showingRevokeAllConfirmation = false
    }

    // MARK: - Helper Methods

    /// Gets the consent status for a data source
    /// - Parameter dataSource: The data source to check
    /// - Returns: The consent, or nil if not found
    func consent(for dataSource: DataSource) -> DataConsent? {
        consents.first { $0.dataSource == dataSource }
    }

    /// Checks if a data source has active consent
    /// - Parameter dataSource: The data source to check
    /// - Returns: True if consent is active
    func hasActiveConsent(for dataSource: DataSource) -> Bool {
        consent(for: dataSource)?.isActive ?? false
    }

    /// Checks if a data source is currently being toggled
    /// - Parameter dataSource: The data source to check
    /// - Returns: True if the source is being toggled
    func isToggling(dataSource: DataSource) -> Bool {
        togglingDataSources.contains(dataSource)
    }

    /// Gets the last updated date for a data source consent
    /// - Parameter dataSource: The data source to check
    /// - Returns: The last action date, or nil if not found
    func lastUpdated(for dataSource: DataSource) -> Date? {
        consent(for: dataSource)?.lastActionDate
    }

    /// Formats a date for display
    /// - Parameter date: The date to format
    /// - Returns: Formatted string
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Never" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Clears any error state
    func clearError() {
        error = nil
    }
}

// MARK: - Preview Support

#if DEBUG
extension DataConsentViewModel {
    /// Creates a preview view model with mock data
    static var preview: DataConsentViewModel {
        let viewModel = DataConsentViewModel()
        viewModel.consents = DataConsent.sampleConsents
        viewModel.auditLog = ConsentAuditEntry.sampleEntries
        return viewModel
    }

    /// Creates a loading preview view model
    static var loadingPreview: DataConsentViewModel {
        let viewModel = DataConsentViewModel()
        viewModel.isLoading = true
        return viewModel
    }

    /// Creates an empty preview view model
    static var emptyPreview: DataConsentViewModel {
        let viewModel = DataConsentViewModel()
        viewModel.consents = []
        return viewModel
    }
}
#endif
