//
//  DataEncryptionService.swift
//  PTPerformance
//
//  ACP-1043: End-to-End Data Encryption
//  Provides AES-256-GCM encryption for sensitive health data at rest.
//

import Foundation
import CryptoKit

// MARK: - DataEncryptionError

/// Errors that can occur during encryption/decryption operations
enum DataEncryptionError: Error, LocalizedError {
    /// Failed to generate a new encryption key
    case keyGenerationFailed
    /// Failed to store the encryption key in Keychain
    case keyStorageFailed(Error)
    /// Failed to retrieve the encryption key from Keychain
    case keyRetrievalFailed
    /// Encryption operation failed
    case encryptionFailed(Error)
    /// Decryption operation failed
    case decryptionFailed(Error)
    /// The sealed box data format is invalid
    case invalidSealedBoxData
    /// Key version mismatch — data was encrypted with a different key version
    case keyVersionMismatch(expected: Int, found: Int)
    /// The input data is empty
    case emptyData

    var errorDescription: String? {
        switch self {
        case .keyGenerationFailed:
            return "Failed to generate encryption key"
        case .keyStorageFailed(let error):
            return "Failed to store encryption key: \(error.localizedDescription)"
        case .keyRetrievalFailed:
            return "Failed to retrieve encryption key"
        case .encryptionFailed(let error):
            return "Encryption failed: \(error.localizedDescription)"
        case .decryptionFailed(let error):
            return "Decryption failed: \(error.localizedDescription)"
        case .invalidSealedBoxData:
            return "Invalid encrypted data format"
        case .keyVersionMismatch(let expected, let found):
            return "Key version mismatch: expected v\(expected), found v\(found)"
        case .emptyData:
            return "Cannot encrypt empty data"
        }
    }
}

// MARK: - DataEncryptionService

/// Singleton service for encrypting and decrypting sensitive health data at rest.
///
/// Uses AES-256-GCM via Apple's CryptoKit framework. The symmetric encryption key
/// is generated once and stored securely in the iOS Keychain via `SecureStore`.
///
/// ## Encrypted Data Format
/// ```
/// [version: 1 byte][nonce: 12 bytes][ciphertext: N bytes][tag: 16 bytes]
/// ```
///
/// ## Key Rotation
/// Keys are versioned. When rotating, the old key is retained so existing data
/// can still be decrypted. New encryptions always use the latest key version.
///
/// ## Usage
/// ```swift
/// let service = DataEncryptionService.shared
///
/// // Encrypt
/// let encrypted = try service.encrypt(data: sensitiveData)
///
/// // Decrypt
/// let decrypted = try service.decrypt(data: encrypted)
/// ```
final class DataEncryptionService {

    // MARK: - Singleton

    static let shared = DataEncryptionService()

    // MARK: - Constants

    private enum Constants {
        /// Keychain key prefix for encryption keys
        static let keyPrefix = "com.getmodus.encryption.key.v"
        /// Keychain key for the current key version number
        static let keyVersionKey = "com.getmodus.encryption.key.version"
        /// Current format version byte written at the start of every sealed payload
        static let formatVersion: UInt8 = 1
    }

    // MARK: - Properties

    /// In-memory cache of the current encryption key to avoid repeated Keychain reads.
    /// Cleared when the app receives a memory warning via `clearSensitiveMemory()`.
    private var cachedKey: SymmetricKey?

    /// The current key version. Incremented on each key rotation.
    private var currentKeyVersion: Int = 1

    private let logger = DebugLogger.shared
    private let store = SecureStore.shared

    // MARK: - Initialization

    private init() {
        loadKeyVersion()
    }

    // MARK: - Public API

    /// Initializes the encryption key if one does not already exist.
    ///
    /// Call this once during app startup (e.g. on first launch). If a key already
    /// exists in the Keychain, this method does nothing.
    func initializeKeyIfNeeded() throws {
        if let _ = try? retrieveKey(version: currentKeyVersion) {
            logger.diagnostic("[DataEncryptionService] Encryption key v\(currentKeyVersion) already exists")
            return
        }

        logger.info("[DataEncryptionService] Generating new encryption key v\(currentKeyVersion)")
        let key = SymmetricKey(size: .bits256)
        try storeKey(key, version: currentKeyVersion)
        cachedKey = key
        logger.success("[DataEncryptionService] Encryption key v\(currentKeyVersion) created and stored")
    }

    /// Encrypts arbitrary data using AES-256-GCM.
    ///
    /// - Parameter data: The plaintext data to encrypt. Must not be empty.
    /// - Returns: The encrypted payload including version byte, nonce, ciphertext, and auth tag.
    /// - Throws: `DataEncryptionError` if encryption fails.
    func encrypt(data: Data) throws -> Data {
        guard !data.isEmpty else {
            throw DataEncryptionError.emptyData
        }

        let key = try getOrCreateKey()

        do {
            let sealedBox = try AES.GCM.seal(data, using: key)

            guard let combined = sealedBox.combined else {
                throw DataEncryptionError.encryptionFailed(
                    NSError(domain: "DataEncryptionService", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to produce combined sealed box"])
                )
            }

            // Prepend format version and key version
            var payload = Data()
            payload.append(Constants.formatVersion)
            payload.append(UInt8(currentKeyVersion))
            payload.append(combined)
            return payload
        } catch let error as DataEncryptionError {
            throw error
        } catch {
            throw DataEncryptionError.encryptionFailed(error)
        }
    }

    /// Decrypts data that was previously encrypted by this service.
    ///
    /// - Parameter data: The encrypted payload (version + nonce + ciphertext + tag).
    /// - Returns: The original plaintext data.
    /// - Throws: `DataEncryptionError` if decryption fails or the data format is invalid.
    func decrypt(data: Data) throws -> Data {
        // Minimum: 1 (format version) + 1 (key version) + 12 (nonce) + 16 (tag) = 30 bytes
        guard data.count >= 30 else {
            throw DataEncryptionError.invalidSealedBoxData
        }

        let formatVersion = data[data.startIndex]
        guard formatVersion == Constants.formatVersion else {
            throw DataEncryptionError.invalidSealedBoxData
        }

        let keyVersion = Int(data[data.startIndex + 1])
        let sealedData = data.dropFirst(2)

        let key = try retrieveKey(version: keyVersion)

        do {
            let sealedBox = try AES.GCM.SealedBox(combined: sealedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            throw DataEncryptionError.decryptionFailed(error)
        }
    }

    /// Encrypts a `String` value.
    ///
    /// - Parameter string: The plaintext string.
    /// - Returns: Encrypted data.
    func encrypt(string: String) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw DataEncryptionError.emptyData
        }
        return try encrypt(data: data)
    }

    /// Decrypts data back into a `String`.
    ///
    /// - Parameter data: The encrypted payload.
    /// - Returns: The original plaintext string.
    func decryptToString(data: Data) throws -> String {
        let decrypted = try decrypt(data: data)
        guard let string = String(data: decrypted, encoding: .utf8) else {
            throw DataEncryptionError.decryptionFailed(
                NSError(domain: "DataEncryptionService", code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "Decrypted data is not valid UTF-8"])
            )
        }
        return string
    }

    /// Encrypts a `Codable` object to `Data`.
    ///
    /// - Parameter object: The encodable object.
    /// - Returns: Encrypted data.
    func encrypt<T: Encodable>(object: T) throws -> Data {
        let jsonData = try JSONEncoder().encode(object)
        return try encrypt(data: jsonData)
    }

    /// Decrypts data back into a `Codable` object.
    ///
    /// - Parameters:
    ///   - data: The encrypted payload.
    ///   - type: The expected `Decodable` type.
    /// - Returns: The decoded object.
    func decrypt<T: Decodable>(data: Data, as type: T.Type) throws -> T {
        let decrypted = try decrypt(data: data)
        return try JSONDecoder().decode(type, from: decrypted)
    }

    // MARK: - Key Rotation

    /// Rotates the encryption key.
    ///
    /// Generates a new key and increments the version. The old key is retained
    /// in the Keychain so that data encrypted with the previous version can still
    /// be decrypted. New encryptions will use the new key.
    func rotateKey() throws {
        let newVersion = currentKeyVersion + 1
        logger.info("[DataEncryptionService] Rotating encryption key to v\(newVersion)")

        let newKey = SymmetricKey(size: .bits256)
        try storeKey(newKey, version: newVersion)

        currentKeyVersion = newVersion
        cachedKey = newKey
        saveKeyVersion()

        logger.success("[DataEncryptionService] Key rotation complete — now using v\(newVersion)")
    }

    /// Re-encrypts data from its current key version to the latest key version.
    ///
    /// - Parameter data: Encrypted data that may use an older key.
    /// - Returns: Data re-encrypted with the current key version.
    func reEncryptWithCurrentKey(data: Data) throws -> Data {
        let decrypted = try decrypt(data: data)
        return try encrypt(data: decrypted)
    }

    // MARK: - Memory Management

    /// Clears the cached encryption key from memory.
    ///
    /// Call this when the app enters the background or receives a memory warning.
    /// The key will be re-read from the Keychain on the next encrypt/decrypt call.
    func clearSensitiveMemory() {
        cachedKey = nil
        logger.diagnostic("[DataEncryptionService] Cleared cached encryption key from memory")
    }

    // MARK: - Private Helpers

    /// Returns the cached key or loads it from Keychain. Creates a new key if none exists.
    private func getOrCreateKey() throws -> SymmetricKey {
        if let cached = cachedKey {
            return cached
        }

        if let existing = try? retrieveKey(version: currentKeyVersion) {
            cachedKey = existing
            return existing
        }

        // First launch — generate and store
        try initializeKeyIfNeeded()
        guard let key = cachedKey else {
            throw DataEncryptionError.keyGenerationFailed
        }
        return key
    }

    /// Stores a symmetric key in the Keychain.
    private func storeKey(_ key: SymmetricKey, version: Int) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        let keychainKey = "\(Constants.keyPrefix)\(version)"
        do {
            try store.set(keyData, forKey: keychainKey)
        } catch {
            throw DataEncryptionError.keyStorageFailed(error)
        }
    }

    /// Retrieves a symmetric key from the Keychain by version.
    private func retrieveKey(version: Int) throws -> SymmetricKey {
        let keychainKey = "\(Constants.keyPrefix)\(version)"
        guard let keyData = try store.getData(forKey: keychainKey), !keyData.isEmpty else {
            throw DataEncryptionError.keyRetrievalFailed
        }
        return SymmetricKey(data: keyData)
    }

    /// Persists the current key version number in the Keychain.
    private func saveKeyVersion() {
        try? store.set("\(currentKeyVersion)", forKey: Constants.keyVersionKey)
    }

    /// Loads the current key version number from the Keychain.
    private func loadKeyVersion() {
        if let versionString = try? store.getString(forKey: Constants.keyVersionKey),
           let version = Int(versionString) {
            currentKeyVersion = version
        }
    }
}
