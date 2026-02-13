//
//  ConsentService.swift
//  PTPerformance
//
//  X2Index Phase 2 - Consent Management (M1)
//  HIPAA-compliant consent service for managing data source permissions
//

import Foundation
import SwiftUI

/// Service for managing HIPAA-compliant consent for external data sources
/// Implements X2Index M1 requirements: consent before fetch, granular toggles, revocation, audit log
@MainActor
final class ConsentService: ObservableObject {

    // MARK: - Singleton

    static let shared = ConsentService()

    // MARK: - Published Properties

    @Published private(set) var consents: [DataSource: DataConsent] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var error: AppError?

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Fetches all consents for a patient
    /// - Parameter patientId: The patient's UUID
    /// - Returns: Array of DataConsent objects
    func getConsents(for patientId: UUID) async -> [DataConsent] {
        isLoading = true
        error = nil

        do {
            let fetchedConsents: [DataConsent] = try await supabase.client
                .from("data_consents")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .execute()
                .value

            // Update local cache
            var consentMap: [DataSource: DataConsent] = [:]
            for consent in fetchedConsents {
                consentMap[consent.dataSource] = consent
            }
            consents = consentMap

            isLoading = false

            DebugLogger.shared.log("[ConsentService] Loaded \(fetchedConsents.count) consents for patient \(patientId)", level: .success)

            return fetchedConsents
        } catch {
            self.error = AppError.from(error)
            ErrorLogger.shared.logError(error, context: "ConsentService.getConsents")
            isLoading = false

            DebugLogger.shared.log("[ConsentService] Error loading consents: \(error.localizedDescription)", level: .error)

            return []
        }
    }

    /// Grants consent for a specific data source
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - dataSource: The data source to grant consent for
    /// - Throws: Error if the operation fails
    func grantConsent(patientId: UUID, dataSource: DataSource) async throws {
        isLoading = true
        error = nil

        let now = Date()
        let deviceInfo = getDeviceInfo()

        do {
            // Check if consent record already exists
            if let existingConsent = consents[dataSource] {
                // Update existing consent
                let update = DataConsentUpdate(
                    consentStatus: .granted,
                    grantedAt: now,
                    revokedAt: nil,
                    ipAddress: deviceInfo.ipAddress,
                    userAgent: deviceInfo.userAgent,
                    updatedAt: now
                )

                try await supabase.client
                    .from("data_consents")
                    .update(update)
                    .eq("id", value: existingConsent.id.uuidString)
                    .execute()

                // Log audit entry
                try await logAuditEntry(
                    consentId: existingConsent.id,
                    patientId: patientId,
                    dataSource: dataSource,
                    previousStatus: existingConsent.consentStatus,
                    newStatus: .granted,
                    action: .granted,
                    deviceInfo: deviceInfo
                )
            } else {
                // Create new consent record
                let insert = DataConsentInsert(
                    patientId: patientId,
                    dataSource: dataSource,
                    consentStatus: .granted,
                    grantedAt: now,
                    ipAddress: deviceInfo.ipAddress,
                    userAgent: deviceInfo.userAgent
                )

                let insertedConsent: [DataConsent] = try await supabase.client
                    .from("data_consents")
                    .insert(insert)
                    .select()
                    .execute()
                    .value

                if let newConsent = insertedConsent.first {
                    // Log audit entry
                    try await logAuditEntry(
                        consentId: newConsent.id,
                        patientId: patientId,
                        dataSource: dataSource,
                        previousStatus: nil,
                        newStatus: .granted,
                        action: .created,
                        deviceInfo: deviceInfo
                    )
                }
            }

            // Refresh consents
            _ = await getConsents(for: patientId)

            HapticFeedback.success()

            DebugLogger.shared.log("[ConsentService] Granted consent for \(dataSource.displayName)", level: .success)
        } catch {
            self.error = AppError.from(error)
            ErrorLogger.shared.logError(error, context: "ConsentService.grantConsent")
            isLoading = false
            HapticFeedback.error()
            throw error
        }
    }

    /// Revokes consent for a specific data source
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - dataSource: The data source to revoke consent for
    /// - Throws: Error if the operation fails
    func revokeConsent(patientId: UUID, dataSource: DataSource) async throws {
        isLoading = true
        error = nil

        let now = Date()
        let deviceInfo = getDeviceInfo()

        do {
            guard let existingConsent = consents[dataSource] else {
                throw AppError.custom("No consent record found for \(dataSource.displayName)")
            }

            let update = DataConsentUpdate(
                consentStatus: .revoked,
                grantedAt: existingConsent.grantedAt,
                revokedAt: now,
                ipAddress: deviceInfo.ipAddress,
                userAgent: deviceInfo.userAgent,
                updatedAt: now
            )

            try await supabase.client
                .from("data_consents")
                .update(update)
                .eq("id", value: existingConsent.id.uuidString)
                .execute()

            // Log audit entry
            try await logAuditEntry(
                consentId: existingConsent.id,
                patientId: patientId,
                dataSource: dataSource,
                previousStatus: existingConsent.consentStatus,
                newStatus: .revoked,
                action: .revoked,
                deviceInfo: deviceInfo
            )

            // Refresh consents
            _ = await getConsents(for: patientId)

            HapticFeedback.warning()

            DebugLogger.shared.log("[ConsentService] Revoked consent for \(dataSource.displayName)", level: .success)
        } catch {
            self.error = AppError.from(error)
            ErrorLogger.shared.logError(error, context: "ConsentService.revokeConsent")
            isLoading = false
            HapticFeedback.error()
            throw error
        }
    }

    /// Checks if a patient has active consent for a data source
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - dataSource: The data source to check
    /// - Returns: True if consent is granted, false otherwise
    func hasConsent(patientId: UUID, dataSource: DataSource) async -> Bool {
        // First check local cache
        if let consent = consents[dataSource] {
            return consent.isActive
        }

        // Fetch from server if not in cache
        let fetchedConsents = await getConsents(for: patientId)
        return fetchedConsents.first(where: { $0.dataSource == dataSource })?.isActive ?? false
    }

    /// Fetches the consent audit log for a patient
    /// - Parameter patientId: The patient's UUID
    /// - Returns: Array of ConsentAuditEntry objects sorted by timestamp descending
    func getConsentAuditLog(patientId: UUID) async -> [ConsentAuditEntry] {
        do {
            let entries: [ConsentAuditEntry] = try await supabase.client
                .from("consent_audit_log")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .order("timestamp", ascending: false)
                .execute()
                .value

            DebugLogger.shared.log("[ConsentService] Loaded \(entries.count) audit entries for patient \(patientId)", level: .success)

            return entries
        } catch {
            ErrorLogger.shared.logError(error, context: "ConsentService.getConsentAuditLog")
            DebugLogger.shared.log("[ConsentService] Error loading audit log: \(error.localizedDescription)", level: .error)
            return []
        }
    }

    /// Revokes all consents for a patient
    /// - Parameter patientId: The patient's UUID
    /// - Throws: Error if the operation fails
    func revokeAllConsents(patientId: UUID) async throws {
        isLoading = true
        error = nil

        let now = Date()
        let deviceInfo = getDeviceInfo()

        do {
            // Get all active consents
            let activeConsents = consents.values.filter { $0.consentStatus == .granted }

            for consent in activeConsents {
                let update = DataConsentUpdate(
                    consentStatus: .revoked,
                    grantedAt: consent.grantedAt,
                    revokedAt: now,
                    ipAddress: deviceInfo.ipAddress,
                    userAgent: deviceInfo.userAgent,
                    updatedAt: now
                )

                try await supabase.client
                    .from("data_consents")
                    .update(update)
                    .eq("id", value: consent.id.uuidString)
                    .execute()

                // Log audit entry
                try await logAuditEntry(
                    consentId: consent.id,
                    patientId: patientId,
                    dataSource: consent.dataSource,
                    previousStatus: consent.consentStatus,
                    newStatus: .revoked,
                    action: .revoked,
                    deviceInfo: deviceInfo
                )
            }

            // Refresh consents
            _ = await getConsents(for: patientId)

            HapticFeedback.warning()

            DebugLogger.shared.log("[ConsentService] Revoked all consents for patient \(patientId)", level: .success)
        } catch {
            self.error = AppError.from(error)
            ErrorLogger.shared.logError(error, context: "ConsentService.revokeAllConsents")
            isLoading = false
            HapticFeedback.error()
            throw error
        }
    }

    // MARK: - Private Methods

    /// Logs an audit entry for consent changes
    private func logAuditEntry(
        consentId: UUID,
        patientId: UUID,
        dataSource: DataSource,
        previousStatus: ConsentStatus?,
        newStatus: ConsentStatus,
        action: ConsentAction,
        deviceInfo: DeviceInfo
    ) async throws {
        struct AuditInsert: Codable {
            let consentId: UUID
            let patientId: UUID
            let dataSource: DataSource
            let previousStatus: ConsentStatus?
            let newStatus: ConsentStatus
            let action: ConsentAction
            let ipAddress: String?
            let userAgent: String?
            let timestamp: Date

            enum CodingKeys: String, CodingKey {
                case consentId = "consent_id"
                case patientId = "patient_id"
                case dataSource = "data_source"
                case previousStatus = "previous_status"
                case newStatus = "new_status"
                case action
                case ipAddress = "ip_address"
                case userAgent = "user_agent"
                case timestamp
            }
        }

        let insert = AuditInsert(
            consentId: consentId,
            patientId: patientId,
            dataSource: dataSource,
            previousStatus: previousStatus,
            newStatus: newStatus,
            action: action,
            ipAddress: deviceInfo.ipAddress,
            userAgent: deviceInfo.userAgent,
            timestamp: Date()
        )

        try await supabase.client
            .from("consent_audit_log")
            .insert(insert)
            .execute()
    }

    /// Gets device information for audit logging
    private func getDeviceInfo() -> DeviceInfo {
        let device = UIDevice.current
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let userAgent = "PTPerformance/\(appVersion).\(buildNumber) \(device.systemName)/\(device.systemVersion)"

        return DeviceInfo(
            ipAddress: getIPAddress(),
            userAgent: userAgent
        )
    }

    /// Gets the device's IP address for audit logging
    private func getIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }

            guard let interface = ptr?.pointee else { continue }
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en1" || name == "pdp_ip0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(
                        interface.ifa_addr,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        0,
                        NI_NUMERICHOST
                    )
                    address = String(cString: hostname)
                }
            }
        }

        return address
    }
}

// MARK: - Device Info

private struct DeviceInfo {
    let ipAddress: String?
    let userAgent: String
}

// MARK: - Preview Support

#if DEBUG
extension ConsentService {
    /// Creates a mock service for previews
    static func preview() -> ConsentService {
        let service = ConsentService.shared
        // In preview, we would populate with mock data
        return service
    }
}
#endif
