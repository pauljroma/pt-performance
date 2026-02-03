import Foundation
import Security

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
}

// MARK: - SecureStore

/// Secure keychain storage service for sensitive credentials
///
/// Provides a simple interface for storing, retrieving, and deleting
/// sensitive data in the iOS Keychain. All items are stored with
/// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` accessibility,
/// ensuring data is protected but available when the device is unlocked.
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

    private let service = "com.ptperformance.app"

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
    ///
    /// - Parameters:
    ///   - data: The data to store
    ///   - key: A unique key to identify this item
    ///
    /// - Throws: `SecureStoreError.storageFailed` if keychain storage fails
    func set(_ data: Data, forKey key: String) throws {
        // Delete existing item first
        try? delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
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
            throw SecureStoreError.deletionFailed(status)
        }
    }

    /// Clears all items stored by this service from the keychain
    ///
    /// Removes all items associated with the `com.ptperformance.app` service
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
            throw SecureStoreError.deletionFailed(status)
        }
    }
}

// MARK: - Convenience Keys

extension SecureStore {
    enum Keys {
        static let authToken = "auth_token"
        static let refreshToken = "refresh_token"
        static let userIdentifier = "user_identifier"
    }
}
