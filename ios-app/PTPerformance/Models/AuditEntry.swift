//
//  AuditEntry.swift
//  PTPerformance
//
//  ACP-1051: Health Data Access Logging
//  Codable model for HIPAA-compliant audit log entries
//

import Foundation

// MARK: - Audit Event Types

/// Categories of auditable events for HIPAA compliance
enum AuditEventType: String, Codable, CaseIterable {
    /// Health data was read or viewed
    case dataAccess = "data_access"
    /// Health data was created or updated
    case dataModification = "data_modification"
    /// Login, logout, token refresh
    case authentication = "authentication"
    /// Permission checks, role changes
    case authorization = "authorization"
    /// Data exported to PDF, CSV, or shared
    case export = "export"
    /// Data or account deletion
    case deletion = "deletion"
    /// App or user settings changed
    case settingsChange = "settings_change"
    /// Security-related event (failed login, lockout, anomaly)
    case securityEvent = "security_event"

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .dataAccess: return "Data Access"
        case .dataModification: return "Data Modification"
        case .authentication: return "Authentication"
        case .authorization: return "Authorization"
        case .export: return "Export"
        case .deletion: return "Deletion"
        case .settingsChange: return "Settings Change"
        case .securityEvent: return "Security Event"
        }
    }
}

// MARK: - Audit Entry

/// A single audit log entry for HIPAA-compliant access tracking.
///
/// Records who accessed what data, when, and from where.
/// Never contains actual health data values -- only metadata about access.
struct AuditEntry: Codable, Identifiable {
    /// Unique identifier for this audit entry
    let id: UUID

    /// ISO 8601 timestamp of when the event occurred
    let timestamp: String

    /// ID of the user who performed the action (may be nil for system events)
    let userId: String?

    /// The action performed (e.g., "read", "sync", "export", "delete")
    let actionType: String

    /// The resource that was accessed (e.g., "health_kit_data", "patient_record")
    let resourceType: String

    /// Category of the event (maps to `operation` in the DB)
    let operation: AuditEventType

    /// Additional context about the event (never contains PHI)
    let details: String?

    /// Device identifier (hashed, for tracking unusual device access)
    let deviceId: String

    /// App version at time of event
    let appVersion: String

    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case userId = "user_id"
        case actionType = "action_type"
        case resourceType = "resource_type"
        case operation
        case details
        case deviceId = "device_id"
        case appVersion = "app_version"
    }
}

// MARK: - Supabase Insert Model

/// Lightweight model for inserting audit entries into Supabase audit_logs table
struct AuditEntryInsert: Encodable {
    let id: String
    let timestamp: String
    let userId: String?
    let actionType: String
    let resourceType: String
    let operation: String
    let details: String?
    let deviceId: String

    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case userId = "user_id"
        case actionType = "action_type"
        case resourceType = "resource_type"
        case operation
        case details
        case deviceId = "device_id"
    }

    init(from entry: AuditEntry) {
        self.id = entry.id.uuidString
        self.timestamp = entry.timestamp
        self.userId = entry.userId
        self.actionType = entry.actionType
        self.resourceType = entry.resourceType
        self.operation = entry.operation.rawValue
        self.details = entry.details
        self.deviceId = entry.deviceId
    }
}
