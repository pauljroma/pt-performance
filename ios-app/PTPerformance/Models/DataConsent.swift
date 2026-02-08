//
//  DataConsent.swift
//  PTPerformance
//
//  X2Index Phase 2 - Consent Management (M1)
//  HIPAA-compliant consent model for external data sources
//

import Foundation

// MARK: - Data Source Enum

/// External data sources that require user consent
enum DataSource: String, Codable, CaseIterable, Identifiable {
    case whoop = "whoop"
    case appleHealth = "apple_health"
    case labResults = "lab_results"
    case manualEntry = "manual_entry"

    var id: String { rawValue }

    /// Display name for the data source
    var displayName: String {
        switch self {
        case .whoop:
            return "WHOOP"
        case .appleHealth:
            return "Apple Health"
        case .labResults:
            return "Lab Results"
        case .manualEntry:
            return "Manual Entry"
        }
    }

    /// Description of what data is collected from this source
    var description: String {
        switch self {
        case .whoop:
            return "Recovery scores, strain, sleep, and HRV data from your WHOOP band"
        case .appleHealth:
            return "Heart rate, sleep, workouts, and activity data from Apple Health"
        case .labResults:
            return "Blood work, biomarkers, and clinical lab results"
        case .manualEntry:
            return "Manually entered health and performance data"
        }
    }

    /// SF Symbol icon for the data source
    var iconName: String {
        switch self {
        case .whoop:
            return "waveform.path.ecg.rectangle"
        case .appleHealth:
            return "heart.fill"
        case .labResults:
            return "flask.fill"
        case .manualEntry:
            return "square.and.pencil"
        }
    }

    /// Color associated with the data source
    var iconColor: String {
        switch self {
        case .whoop:
            return "modusCyan"
        case .appleHealth:
            return "red"
        case .labResults:
            return "modusTealAccent"
        case .manualEntry:
            return "modusDeepTeal"
        }
    }
}

// MARK: - Consent Status Enum

/// Status of user consent for a data source
enum ConsentStatus: String, Codable, CaseIterable {
    case granted = "granted"
    case revoked = "revoked"
    case pending = "pending"

    /// Display name for the status
    var displayName: String {
        switch self {
        case .granted:
            return "Granted"
        case .revoked:
            return "Revoked"
        case .pending:
            return "Pending"
        }
    }

    /// Whether data can be fetched with this status
    var allowsDataFetch: Bool {
        self == .granted
    }
}

// MARK: - Data Consent Model

/// Represents a user's consent for a specific data source
/// Stored in Supabase for HIPAA-compliant audit trail
struct DataConsent: Codable, Identifiable, Equatable {
    let id: UUID
    let patientId: UUID
    let dataSource: DataSource
    var consentStatus: ConsentStatus
    var grantedAt: Date?
    var revokedAt: Date?
    var ipAddress: String?
    var userAgent: String?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case dataSource = "data_source"
        case consentStatus = "consent_status"
        case grantedAt = "granted_at"
        case revokedAt = "revoked_at"
        case ipAddress = "ip_address"
        case userAgent = "user_agent"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Whether this consent allows data fetching
    var isActive: Bool {
        consentStatus == .granted
    }

    /// Formatted date string for last consent action
    var lastActionDate: Date? {
        switch consentStatus {
        case .granted:
            return grantedAt
        case .revoked:
            return revokedAt
        case .pending:
            return createdAt
        }
    }
}

// MARK: - Data Consent Insert DTO

/// Data transfer object for inserting new consent records
struct DataConsentInsert: Codable {
    let patientId: UUID
    let dataSource: DataSource
    let consentStatus: ConsentStatus
    let grantedAt: Date?
    let ipAddress: String?
    let userAgent: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case dataSource = "data_source"
        case consentStatus = "consent_status"
        case grantedAt = "granted_at"
        case ipAddress = "ip_address"
        case userAgent = "user_agent"
    }
}

// MARK: - Data Consent Update DTO

/// Data transfer object for updating consent records
struct DataConsentUpdate: Codable {
    let consentStatus: ConsentStatus
    let grantedAt: Date?
    let revokedAt: Date?
    let ipAddress: String?
    let userAgent: String?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case consentStatus = "consent_status"
        case grantedAt = "granted_at"
        case revokedAt = "revoked_at"
        case ipAddress = "ip_address"
        case userAgent = "user_agent"
        case updatedAt = "updated_at"
    }
}

// MARK: - Consent Audit Entry

/// Audit log entry for consent changes (HIPAA compliance)
struct ConsentAuditEntry: Codable, Identifiable, Equatable {
    let id: UUID
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
        case id
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

    /// Formatted description of the audit action
    var actionDescription: String {
        switch action {
        case .granted:
            return "Consent granted for \(dataSource.displayName)"
        case .revoked:
            return "Consent revoked for \(dataSource.displayName)"
        case .created:
            return "Consent record created for \(dataSource.displayName)"
        }
    }
}

// MARK: - Consent Action Enum

/// Actions that can be taken on consent records
enum ConsentAction: String, Codable {
    case granted = "granted"
    case revoked = "revoked"
    case created = "created"
}

// MARK: - Preview Support

#if DEBUG
extension DataConsent {
    /// Sample consent for previews - granted WHOOP
    static var sampleGranted: DataConsent {
        DataConsent(
            id: UUID(),
            patientId: UUID(),
            dataSource: .whoop,
            consentStatus: .granted,
            grantedAt: Date().addingTimeInterval(-86400 * 7), // 7 days ago
            revokedAt: nil,
            ipAddress: "192.168.1.1",
            userAgent: "PTPerformance/1.0 iOS/17.0",
            createdAt: Date().addingTimeInterval(-86400 * 30),
            updatedAt: Date().addingTimeInterval(-86400 * 7)
        )
    }

    /// Sample consent for previews - revoked Apple Health
    static var sampleRevoked: DataConsent {
        DataConsent(
            id: UUID(),
            patientId: UUID(),
            dataSource: .appleHealth,
            consentStatus: .revoked,
            grantedAt: Date().addingTimeInterval(-86400 * 30),
            revokedAt: Date().addingTimeInterval(-86400 * 2),
            ipAddress: "192.168.1.1",
            userAgent: "PTPerformance/1.0 iOS/17.0",
            createdAt: Date().addingTimeInterval(-86400 * 30),
            updatedAt: Date().addingTimeInterval(-86400 * 2)
        )
    }

    /// Sample consent for previews - pending lab results
    static var samplePending: DataConsent {
        DataConsent(
            id: UUID(),
            patientId: UUID(),
            dataSource: .labResults,
            consentStatus: .pending,
            grantedAt: nil,
            revokedAt: nil,
            ipAddress: nil,
            userAgent: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    /// Sample consents array for previews
    static var sampleConsents: [DataConsent] {
        [sampleGranted, sampleRevoked, samplePending]
    }
}

extension ConsentAuditEntry {
    /// Sample audit entry for previews
    static var sampleEntry: ConsentAuditEntry {
        ConsentAuditEntry(
            id: UUID(),
            consentId: UUID(),
            patientId: UUID(),
            dataSource: .whoop,
            previousStatus: nil,
            newStatus: .granted,
            action: .granted,
            ipAddress: "192.168.1.1",
            userAgent: "PTPerformance/1.0 iOS/17.0",
            timestamp: Date().addingTimeInterval(-86400)
        )
    }

    /// Sample audit entries array for previews
    static var sampleEntries: [ConsentAuditEntry] {
        [
            ConsentAuditEntry(
                id: UUID(),
                consentId: UUID(),
                patientId: UUID(),
                dataSource: .whoop,
                previousStatus: nil,
                newStatus: .granted,
                action: .granted,
                ipAddress: "192.168.1.1",
                userAgent: "PTPerformance/1.0 iOS/17.0",
                timestamp: Date().addingTimeInterval(-86400 * 7)
            ),
            ConsentAuditEntry(
                id: UUID(),
                consentId: UUID(),
                patientId: UUID(),
                dataSource: .appleHealth,
                previousStatus: .granted,
                newStatus: .revoked,
                action: .revoked,
                ipAddress: "192.168.1.1",
                userAgent: "PTPerformance/1.0 iOS/17.0",
                timestamp: Date().addingTimeInterval(-86400 * 2)
            )
        ]
    }
}
#endif
