import Foundation
import Security
import LocalAuthentication

// MARK: - SecureStoreError

/// Errors that can occur during secure storage operations
enum SecureStoreError: Error {
    /// The value could not be encoded to UTF-8 data
    case encodingFailed
    /// Failed to store the item in the keychain (includes OSStatus for debugging)
    case storageFailed(OSStatus)
    /// Failed to retrieve the item from the keychain (includes OSStatus for debugging)
    case retrievalFailed(OSStatus)
    /// Failed to delete the item from the keychain (includes OSStatus for debugging)
    case deletionFailed(OSStatus)
    /// The requested item was not found in the keychain
    case itemNotFound
    /// Migration from old keychain access level failed
    case migrationFailed(key: String, underlyingStatus: OSStatus)
}

// MARK: - SecureStore

/// Secure keychain storage service for sensitive credentials
///
/// Provides a simple interface for storing, retrieving, and deleting
/// sensitive data in the iOS Keychain. All items are stored with
/// `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` accessibility,
/// ensuring data is only accessible when the device is actively unlocked.
///
/// ## Security Levels (ACP-1044)
/// - Auth tokens and credentials use `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
///   (more restrictive — only accessible while device is unlocked)
/// - Migration from `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` runs
///   automatically on first launch after upgrade
///
/// ## Usage Example
/// ```swift
/// let store = SecureStore.shared
///
/// // Store a token
/// try store.set("my-auth-token", forKey: SecureStore.Keys.authToken)
///
/// // Retrieve the token
/// if let token = try store.getString(forKey: SecureStore.Keys.authToken) {
///     print("Token: \(token)")
/// }
///
/// // Delete when done
/// try store.delete(forKey: SecureStore.Keys.authToken)
/// ```
final class SecureStore {

    // MARK: - Singleton

    static let shared = SecureStore()

    // MARK: - Properties

    private let service = "com.getmodus.app"

    /// UserDefaults key to track whether keychain migration has been completed
    private static let migrationVersionKey = "com.getmodus.securestore.migration_version"

    /// Current migration version. Increment when keychain access levels change.
    private static let currentMigrationVersion = 1

    /// Logger instance for keychain operations
    private let logger = DebugLogger.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - String Storage

    /// Stores a string value securely in the keychain
    ///
    /// The string is encoded to UTF-8 data before storage. If an item with
    /// the same key already exists, it will be replaced.
    ///
    /// - Parameters:
    ///   - value: The string value to store
    ///   - key: A unique key to identify this item
    ///
    /// - Throws: `SecureStoreError.encodingFailed` if UTF-8 encoding fails,
    ///           `SecureStoreError.storageFailed` if keychain storage fails
    func set(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw SecureStoreError.encodingFailed
        }
        try set(data, forKey: key)
    }

    /// Retrieves a string value from the keychain
    ///
    /// - Parameter key: The key used when storing the item
    ///
    /// - Returns: The stored string value, or `nil` if no item exists for the key
    ///
    /// - Throws: `SecureStoreError.retrievalFailed` if keychain access fails
    func getString(forKey key: String) throws -> String? {
        guard let data = try getData(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Data Storage

    /// Stores binary data securely in the keychain
    ///
    /// This is the underlying storage method used by `set(_:forKey:)` for strings.
    /// If an item with the same key already exists, it will be replaced.
    /// Items are stored with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (ACP-1044).
    ///
    /// - Parameters:
    ///   - data: The data to store
    ///   - key: A unique key to identify this item
    ///
    /// - Throws: `SecureStoreError.storageFailed` if keychain storage fails
    func set(_ data: Data, forKey key: String) throws {
        // Delete existing item first (required for access level changes)
        try? delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            logger.error("SecureStore", "Failed to store item for key '\(key)': OSStatus \(status)")
            throw SecureStoreError.storageFailed(status)
        }
    }

    /// Retrieves binary data from the keychain
    ///
    /// - Parameter key: The key used when storing the item
    ///
    /// - Returns: The stored data, or `nil` if no item exists for the key
    ///
    /// - Throws: `SecureStoreError.retrievalFailed` if keychain access fails
    func getData(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            logger.error("SecureStore", "Failed to retrieve item for key '\(key)': OSStatus \(status)")
            throw SecureStoreError.retrievalFailed(status)
        }

        return result as? Data
    }

    // MARK: - Deletion

    /// Deletes a stored value from the keychain
    ///
    /// If no item exists for the given key, this method completes successfully
    /// without throwing an error.
    ///
    /// - Parameter key: The key of the item to delete
    ///
    /// - Throws: `SecureStoreError.deletionFailed` if keychain deletion fails
    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            logger.error("SecureStore", "Failed to delete item for key '\(key)': OSStatus \(status)")
            throw SecureStoreError.deletionFailed(status)
        }
    }

    /// Clears all items stored by this service from the keychain
    ///
    /// Removes all items associated with the `com.getmodus.app` service
    /// identifier. Use with caution as this cannot be undone.
    ///
    /// - Throws: `SecureStoreError.deletionFailed` if keychain deletion fails
    func clearAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            logger.error("SecureStore", "Failed to clear all keychain items: OSStatus \(status)")
            throw SecureStoreError.deletionFailed(status)
        }
    }

    /// Clears only authentication credentials, preserving encryption keys and other non-auth data.
    /// Use this for session expiry / logout instead of clearAll().
    func clearAuthCredentials() {
        let authKeys = [
            Keys.authToken,
            Keys.refreshToken,
            Keys.userIdentifier,
            Keys.whoopAccessToken,
            Keys.whoopRefreshToken,
            Keys.sessionFingerprint
        ]
        for key in authKeys {
            try? delete(forKey: key)
        }
        logger.diagnostic("SecureStore: Cleared auth credentials (encryption keys preserved)")
    }

    // MARK: - Keychain Migration (ACP-1044)

    /// Migrates keychain items from old access levels to the current secure level.
    ///
    /// This method handles upgrading from `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`
    /// to `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. Changing the accessibility level
    /// on an existing keychain item requires deleting and re-adding it.
    ///
    /// Should be called once on app launch. Uses a version number in UserDefaults
    /// to track whether migration has already been performed.
    func migrateIfNeeded() {
        let currentVersion = UserDefaults.standard.integer(forKey: Self.migrationVersionKey)

        guard currentVersion < Self.currentMigrationVersion else {
            logger.diagnostic("[SecureStore] Keychain migration already at version \(currentVersion), skipping")
            return
        }

        logger.log("[SecureStore] Starting keychain migration from version \(currentVersion) to \(Self.currentMigrationVersion)", level: .info)

        // Keys that need to be migrated to the new access level
        let keysToMigrate = [
            Keys.authToken,
            Keys.refreshToken,
            Keys.userIdentifier,
            Keys.whoopAccessToken,
            Keys.whoopRefreshToken,
            Keys.sessionFingerprint
        ]

        var migratedCount = 0
        var failedCount = 0

        for key in keysToMigrate {
            do {
                // Read existing value (works with any access level)
                guard let existingData = try getData(forKey: key) else {
                    // No data for this key — nothing to migrate
                    continue
                }

                // Delete old item and re-add with new access level
                // The set() method already deletes first, then adds with the new level
                try set(existingData, forKey: key)
                migratedCount += 1
                logger.diagnostic("[SecureStore] Migrated key '\(key)' to WhenUnlockedThisDeviceOnly")
            } catch {
                failedCount += 1
                logger.error("SecureStore", "Failed to migrate key '\(key)': \(error.localizedDescription)")
                // Continue migrating other keys — don't fail the whole migration
            }
        }

        // Mark migration as complete even if some items failed
        // (failed items may not exist yet, which is fine)
        UserDefaults.standard.set(Self.currentMigrationVersion, forKey: Self.migrationVersionKey)

        logger.log("[SecureStore] Keychain migration complete: \(migratedCount) migrated, \(failedCount) failed", level: .success)
    }

    // MARK: - Keychain Audit (ACP-1044)

    /// Audits all keychain items stored by this service and logs the keys (never values).
    ///
    /// This provides visibility into what credentials are currently stored without
    /// exposing any sensitive data. Useful for debugging and compliance verification.
    func auditKeychainItems() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            logger.log("[SecureStore Audit] No keychain items found for service '\(service)'", level: .info)
            return
        }

        guard status == errSecSuccess, let items = result as? [[String: Any]] else {
            logger.error("SecureStore", "Audit failed: OSStatus \(status)")
            return
        }

        logger.log("[SecureStore Audit] Found \(items.count) keychain item(s) for service '\(service)':", level: .info)

        for item in items {
            if let account = item[kSecAttrAccount as String] as? String {
                let accessible = item[kSecAttrAccessible as String]
                let accessLevel: String
                if let acc = accessible as? String {
                    if acc == kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String {
                        accessLevel = "WhenUnlockedThisDeviceOnly"
                    } else if acc == kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String {
                        accessLevel = "AfterFirstUnlockThisDeviceOnly (needs migration)"
                    } else {
                        accessLevel = "Other: \(acc)"
                    }
                } else {
                    accessLevel = "unknown"
                }
                logger.log("[SecureStore Audit]   - key: '\(account)', access: \(accessLevel)", level: .diagnostic)
            }
        }
    }

    // MARK: - Key Existence Check

    /// Checks whether a value exists in the keychain for the given key
    /// without retrieving the actual data.
    ///
    /// - Parameter key: The key to check
    /// - Returns: `true` if a value exists, `false` otherwise
    func containsValue(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Biometric-Protected Storage (ACP-1043)

    /// Stores data with biometric (Face ID / Touch ID) protection.
    ///
    /// Items stored with this method require biometric authentication
    /// each time they are accessed. Use this for the most sensitive items
    /// such as auth tokens. Falls back to standard storage if biometric
    /// hardware is unavailable (e.g., Simulator).
    ///
    /// - Parameters:
    ///   - data: The data to store.
    ///   - key: A unique key to identify this item.
    /// - Throws: `SecureStoreError` on failure.
    func setWithBiometric(_ data: Data, forKey key: String) throws {
        // Delete existing item first
        try? delete(forKey: key)

        // Check if biometric authentication is available
        let context = LAContext()
        var authError: NSError?
        let canUseBiometrics = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &authError
        )

        if canUseBiometrics {
            // Create access control requiring biometric authentication
            guard let accessControl = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryCurrentSet,
                nil
            ) else {
                logger.warning("SecureStore", "Could not create biometric access control, falling back to standard storage")
                try set(data, forKey: key)
                return
            }

            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
                kSecValueData as String: data,
                kSecAttrAccessControl as String: accessControl
            ]

            let status = SecItemAdd(query as CFDictionary, nil)
            guard status == errSecSuccess else {
                logger.error("SecureStore", "Failed to store biometric-protected item for key '\(key)': OSStatus \(status)")
                throw SecureStoreError.storageFailed(status)
            }

            logger.diagnostic("[SecureStore] Stored key '\(key)' with biometric protection")
        } else {
            // Biometrics not available — fall back to standard storage
            logger.info("SecureStore", "Biometrics unavailable (\(authError?.localizedDescription ?? "unknown")), using standard keychain for '\(key)'")
            try set(data, forKey: key)
        }
    }

    /// Stores a string with biometric protection.
    ///
    /// - Parameters:
    ///   - value: The string to store.
    ///   - key: A unique key to identify this item.
    /// - Throws: `SecureStoreError` on failure.
    func setWithBiometric(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw SecureStoreError.encodingFailed
        }
        try setWithBiometric(data, forKey: key)
    }
}

// MARK: - Convenience Keys

extension SecureStore {
    enum Keys {
        static let authToken = "auth_token"
        static let refreshToken = "refresh_token"
        static let userIdentifier = "user_identifier"

        // WHOOP Integration tokens (Build 40)
        static let whoopAccessToken = "whoop_access_token"
        static let whoopRefreshToken = "whoop_refresh_token"

        // Session security (ACP-1040)
        static let sessionFingerprint = "session_fingerprint"

        // ACP-1043: Data encryption key management
        /// Prefix for versioned encryption keys (append version number)
        static let encryptionKeyPrefix = "com.getmodus.encryption.key.v"
        /// Stores the current encryption key version number
        static let encryptionKeyVersion = "com.getmodus.encryption.key.version"
    }
}
