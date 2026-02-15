// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  ConsentManager.swift
//  PTPerformance
//
//  ACP-1046: Granular Privacy Settings & ACP-1049: Consent Management
//  Centralized consent manager for tracking and managing user privacy consents
//

import Foundation
import SwiftUI

// MARK: - Consent Type

/// Types of consent the user can grant or withdraw
enum PrivacyConsentType: String, CaseIterable, Codable, Identifiable {
    case dataProcessing = "data_processing"
    case marketing = "marketing"
    case analytics = "analytics"
    case healthDataSharing = "health_data_sharing"
    case workoutSharing = "workout_sharing"
    case aiPersonalization = "ai_personalization"
    case crashReporting = "crash_reporting"
    case pushMarketing = "push_marketing"
    case therapistSharing = "therapist_sharing"

    var id: String { rawValue }

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .dataProcessing: return "Data Processing"
        case .marketing: return "Marketing Emails"
        case .analytics: return "Usage Analytics"
        case .healthDataSharing: return "Health Data Sharing"
        case .workoutSharing: return "Workout Data Sharing"
        case .aiPersonalization: return "AI Personalization"
        case .crashReporting: return "Crash Reporting"
        case .pushMarketing: return "Push Notifications (Marketing)"
        case .therapistSharing: return "Share with Therapist"
        }
    }

    /// Explanation of what this consent covers
    var explanation: String {
        switch self {
        case .dataProcessing:
            return "Allows us to process your data to provide core app functionality including workout tracking and progress monitoring."
        case .marketing:
            return "Receive occasional emails about new features, training tips, and special offers. You can unsubscribe at any time."
        case .analytics:
            return "Help us improve the app by sharing anonymized usage data such as feature usage patterns and session duration."
        case .healthDataSharing:
            return "Share health metrics like heart rate, sleep data, and recovery scores to enable personalized insights."
        case .workoutSharing:
            return "Share your workout history and exercise data to enable progress tracking and program recommendations."
        case .aiPersonalization:
            return "Allow AI to analyze your patterns and provide personalized training recommendations and insights."
        case .crashReporting:
            return "Automatically send crash reports to help us identify and fix bugs faster."
        case .pushMarketing:
            return "Receive push notifications about promotions, challenges, and community events."
        case .therapistSharing:
            return "Allow your linked therapist to view your workout data, progress, and health metrics for better care coordination."
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .dataProcessing: return "server.rack"
        case .marketing: return "envelope.fill"
        case .analytics: return "chart.bar.fill"
        case .healthDataSharing: return "heart.text.square.fill"
        case .workoutSharing: return "figure.run"
        case .aiPersonalization: return "brain.head.profile"
        case .crashReporting: return "ant.fill"
        case .pushMarketing: return "bell.badge.fill"
        case .therapistSharing: return "person.2.fill"
        }
    }

    /// Icon color for display
    var iconColor: Color {
        switch self {
        case .dataProcessing: return .modusCyan
        case .marketing: return .orange
        case .analytics: return .modusTealAccent
        case .healthDataSharing: return .red
        case .workoutSharing: return .modusCyan
        case .aiPersonalization: return .purple
        case .crashReporting: return .green
        case .pushMarketing: return .orange
        case .therapistSharing: return .modusDeepTeal
        }
    }

    /// Category grouping for UI display
    var category: PrivacyConsentCategory {
        switch self {
        case .workoutSharing, .healthDataSharing, .therapistSharing:
            return .dataSharing
        case .analytics, .aiPersonalization, .crashReporting:
            return .analyticsPersonalization
        case .marketing, .pushMarketing:
            return .marketing
        case .dataProcessing:
            return .dataSharing
        }
    }

    /// Whether this consent is required for core app functionality
    var isRequired: Bool {
        self == .dataProcessing
    }
}

// MARK: - Consent Category

/// Grouping categories for privacy consent toggles
enum PrivacyConsentCategory: String, CaseIterable {
    case dataSharing = "data_sharing"
    case analyticsPersonalization = "analytics_personalization"
    case marketing = "marketing"

    var displayName: String {
        switch self {
        case .dataSharing: return "Data Sharing"
        case .analyticsPersonalization: return "Analytics & Personalization"
        case .marketing: return "Marketing"
        }
    }

    var iconName: String {
        switch self {
        case .dataSharing: return "arrow.up.arrow.down.circle.fill"
        case .analyticsPersonalization: return "chart.bar.xaxis"
        case .marketing: return "megaphone.fill"
        }
    }

    /// Consent types belonging to this category
    var consentTypes: [PrivacyConsentType] {
        PrivacyConsentType.allCases.filter { $0.category == self }
    }
}

// MARK: - Consent Record

/// Represents the state of a single consent
struct ConsentRecord: Codable, Equatable {
    var isGranted: Bool
    var grantedAt: Date?
    var withdrawnAt: Date?
    var version: String

    /// Creates a default consent record (not granted)
    static func defaultRecord(version: String) -> ConsentRecord {
        ConsentRecord(
            isGranted: false,
            grantedAt: nil,
            withdrawnAt: nil,
            version: version
        )
    }
}

// MARK: - Consent Change Log Entry

/// Codable struct for syncing consent changes to Supabase
private struct PatientConsentInsert: Codable {
    let patient_id: String
    let consent_type: String
    let is_granted: Bool
    let consent_version: String
    let action: String
    let granted_at: String?
    let withdrawn_at: String?
    let ip_address: String?
    let user_agent: String?
    let created_at: String

    enum CodingKeys: String, CodingKey {
        case patient_id
        case consent_type
        case is_granted
        case consent_version
        case action
        case granted_at
        case withdrawn_at
        case ip_address
        case user_agent
        case created_at
    }
}

// MARK: - Consent Manager

/// Singleton that manages all privacy consent states
/// ACP-1046: Granular Privacy Settings
/// ACP-1049: Consent version tracking and re-consent prompts
@MainActor
final class ConsentManager: ObservableObject {

    // MARK: - Singleton

    static let shared = ConsentManager()

    // MARK: - Constants

    /// Current consent policy version. Increment when privacy terms change.
    static let currentConsentVersion = "2.0"

    /// UserDefaults key prefix for consent storage
    private static let storageKeyPrefix = "privacy_consent_"

    /// UserDefaults key for the stored consent version
    private static let storedVersionKey = "privacy_consent_version"

    // MARK: - Published Properties

    @Published private(set) var consents: [PrivacyConsentType: ConsentRecord] = [:]
    @Published private(set) var isSyncing = false
    @Published var showConsentUpdateSheet = false

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared
    private let defaults = UserDefaults.standard
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // MARK: - Initialization

    private init() {
        loadConsentsFromStorage()
    }

    // MARK: - Public Interface

    /// Whether the user needs to re-consent due to a version change
    func needsReConsent() -> Bool {
        let storedVersion = defaults.string(forKey: Self.storedVersionKey) ?? "0.0"
        return storedVersion < Self.currentConsentVersion
    }

    /// Whether a specific consent type is granted
    func isGranted(_ type: PrivacyConsentType) -> Bool {
        consents[type]?.isGranted ?? false
    }

    /// Grant consent for a specific type
    func grantConsent(type: PrivacyConsentType) {
        let now = Date()
        let record = ConsentRecord(
            isGranted: true,
            grantedAt: now,
            withdrawnAt: nil,
            version: Self.currentConsentVersion
        )

        consents[type] = record
        saveConsentToStorage(type: type, record: record)

        DebugLogger.shared.success("ConsentManager", "Consent granted for \(type.displayName)")

        // Sync to Supabase in background
        Task {
            await syncConsentChange(type: type, record: record, action: "granted")
        }
    }

    /// Withdraw consent for a specific type
    func withdrawConsent(type: PrivacyConsentType) {
        guard !type.isRequired else {
            DebugLogger.shared.warning("ConsentManager", "Cannot withdraw required consent: \(type.displayName)")
            return
        }

        let now = Date()
        let record = ConsentRecord(
            isGranted: false,
            grantedAt: consents[type]?.grantedAt,
            withdrawnAt: now,
            version: Self.currentConsentVersion
        )

        consents[type] = record
        saveConsentToStorage(type: type, record: record)

        DebugLogger.shared.success("ConsentManager", "Consent withdrawn for \(type.displayName)")

        // Sync to Supabase in background
        Task {
            await syncConsentChange(type: type, record: record, action: "withdrawn")
        }
    }

    /// Toggle consent for a type (convenience method for SwiftUI bindings)
    func toggleConsent(type: PrivacyConsentType) {
        if isGranted(type) {
            withdrawConsent(type: type)
        } else {
            grantConsent(type: type)
        }
    }

    /// Grant all consents (e.g., after re-consent acknowledgment)
    func grantAllConsents() {
        for type in PrivacyConsentType.allCases {
            grantConsent(type: type)
        }
        defaults.set(Self.currentConsentVersion, forKey: Self.storedVersionKey)

        DebugLogger.shared.success("ConsentManager", "All consents granted at version \(Self.currentConsentVersion)")
    }

    /// Withdraw all non-required consents
    func withdrawAllOptionalConsents() {
        for type in PrivacyConsentType.allCases where !type.isRequired {
            withdrawConsent(type: type)
        }

        DebugLogger.shared.success("ConsentManager", "All optional consents withdrawn")
    }

    /// Acknowledge the current consent version without changing individual consents
    func acknowledgeConsentVersion() {
        defaults.set(Self.currentConsentVersion, forKey: Self.storedVersionKey)
        showConsentUpdateSheet = false

        DebugLogger.shared.success("ConsentManager", "Consent version \(Self.currentConsentVersion) acknowledged")
    }

    /// Returns a binding for a consent toggle in SwiftUI
    func binding(for type: PrivacyConsentType) -> Binding<Bool> {
        Binding(
            get: { [weak self] in
                self?.isGranted(type) ?? false
            },
            set: { [weak self] newValue in
                guard let self else { return }
                if newValue {
                    self.grantConsent(type: type)
                } else {
                    self.withdrawConsent(type: type)
                }
            }
        )
    }

    /// Number of active (granted) consents
    var activeConsentCount: Int {
        consents.values.filter(\.isGranted).count
    }

    /// Total number of consent types
    var totalConsentCount: Int {
        PrivacyConsentType.allCases.count
    }

    /// Whether all consents are up to date with the current version
    var allConsentsUpToDate: Bool {
        !needsReConsent()
    }

    /// Consent status summary text
    var statusSummary: String {
        if needsReConsent() {
            return "Review Required"
        }
        return "\(activeConsentCount) of \(totalConsentCount) active"
    }

    // MARK: - Private Methods

    /// Load all consents from UserDefaults
    private func loadConsentsFromStorage() {
        for type in PrivacyConsentType.allCases {
            let key = Self.storageKeyPrefix + type.rawValue
            if let data = defaults.data(forKey: key),
               let record = try? JSONDecoder().decode(ConsentRecord.self, from: data) {
                consents[type] = record
            } else {
                // Default: data processing is granted (required), others not granted
                if type.isRequired {
                    let record = ConsentRecord(
                        isGranted: true,
                        grantedAt: Date(),
                        withdrawnAt: nil,
                        version: Self.currentConsentVersion
                    )
                    consents[type] = record
                    saveConsentToStorage(type: type, record: record)
                } else {
                    consents[type] = ConsentRecord.defaultRecord(version: Self.currentConsentVersion)
                }
            }
        }

        DebugLogger.shared.info("ConsentManager", "Loaded \(consents.count) consent records from storage")
    }

    /// Save a consent record to UserDefaults
    private func saveConsentToStorage(type: PrivacyConsentType, record: ConsentRecord) {
        let key = Self.storageKeyPrefix + type.rawValue
        if let data = try? JSONEncoder().encode(record) {
            defaults.set(data, forKey: key)
        }
    }

    /// Sync a consent change to the Supabase patient_consents table
    private func syncConsentChange(type: PrivacyConsentType, record: ConsentRecord, action: String) async {
        guard let userId = supabase.userId else {
            DebugLogger.shared.warning("ConsentManager", "Cannot sync consent - no user ID")
            return
        }

        isSyncing = true
        defer { isSyncing = false }

        let now = isoFormatter.string(from: Date())
        let grantedAt = record.grantedAt.map { isoFormatter.string(from: $0) }
        let withdrawnAt = record.withdrawnAt.map { isoFormatter.string(from: $0) }

        let device = await UIDevice.current
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let userAgent = "PTPerformance/\(appVersion).\(buildNumber) \(device.systemName)/\(device.systemVersion)"

        let insert = PatientConsentInsert(
            patient_id: userId,
            consent_type: type.rawValue,
            is_granted: record.isGranted,
            consent_version: record.version,
            action: action,
            granted_at: grantedAt,
            withdrawn_at: withdrawnAt,
            ip_address: nil,
            user_agent: userAgent,
            created_at: now
        )

        do {
            try await supabase.client
                .from("patient_consents")
                .insert(insert)
                .execute()

            DebugLogger.shared.success("ConsentManager", "Synced consent change to Supabase: \(type.displayName) -> \(action)")
        } catch {
            // Non-blocking: consent is still saved locally
            DebugLogger.shared.warning("ConsentManager", "Failed to sync consent to Supabase (non-blocking): \(error.localizedDescription)")
        }
    }
}
