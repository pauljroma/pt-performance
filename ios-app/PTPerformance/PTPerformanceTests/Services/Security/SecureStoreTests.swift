//
//  SecureStoreTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for SecureStore — the HIPAA-critical keychain
//  storage service. Tests cover singleton access, key constants, string/data
//  storage round-trips, deletion, migration logic, audit, containsValue,
//  biometric-protected storage fallback, error types, and edge cases.
//
//  NOTE: On the iOS Simulator the Keychain is functional but behaves slightly
//  differently than on-device (e.g., access-control flags may be ignored).
//  These tests focus on the logical contract of the API.
//

import XCTest
import Security
@testable import PTPerformance

// MARK: - SecureStoreError Tests

final class SecureStoreErrorTests: XCTestCase {

    // MARK: - Error Case Construction

    func testEncodingFailedError() {
        let error = SecureStoreError.encodingFailed
        XCTAssertNotNil(error)
    }

    func testStorageFailedContainsStatus() {
        let error = SecureStoreError.storageFailed(errSecDuplicateItem)
        if case .storageFailed(let status) = error {
            XCTAssertEqual(status, errSecDuplicateItem)
        } else {
            XCTFail("Expected .storageFailed case")
        }
    }

    func testRetrievalFailedContainsStatus() {
        let error = SecureStoreError.retrievalFailed(errSecAuthFailed)
        if case .retrievalFailed(let status) = error {
            XCTAssertEqual(status, errSecAuthFailed)
        } else {
            XCTFail("Expected .retrievalFailed case")
        }
    }

    func testDeletionFailedContainsStatus() {
        let error = SecureStoreError.deletionFailed(errSecInternalError)
        if case .deletionFailed(let status) = error {
            XCTAssertEqual(status, errSecInternalError)
        } else {
            XCTFail("Expected .deletionFailed case")
        }
    }

    func testItemNotFoundError() {
        let error = SecureStoreError.itemNotFound
        XCTAssertNotNil(error)
    }

    func testMigrationFailedContainsKeyAndStatus() {
        let error = SecureStoreError.migrationFailed(key: "test_key", underlyingStatus: errSecItemNotFound)
        if case .migrationFailed(let key, let status) = error {
            XCTAssertEqual(key, "test_key")
            XCTAssertEqual(status, errSecItemNotFound)
        } else {
            XCTFail("Expected .migrationFailed case")
        }
    }

    func testAllErrorCasesConformToError() {
        let errors: [Error] = [
            SecureStoreError.encodingFailed,
            SecureStoreError.storageFailed(0),
            SecureStoreError.retrievalFailed(0),
            SecureStoreError.deletionFailed(0),
            SecureStoreError.itemNotFound,
            SecureStoreError.migrationFailed(key: "k", underlyingStatus: 0)
        ]
        XCTAssertEqual(errors.count, 6, "All six error cases should be representable")
    }
}

// MARK: - SecureStore Keys Tests

final class SecureStoreKeysTests: XCTestCase {

    func testAuthTokenKeyValue() {
        XCTAssertEqual(SecureStore.Keys.authToken, "auth_token")
    }

    func testRefreshTokenKeyValue() {
        XCTAssertEqual(SecureStore.Keys.refreshToken, "refresh_token")
    }

    func testUserIdentifierKeyValue() {
        XCTAssertEqual(SecureStore.Keys.userIdentifier, "user_identifier")
    }

    func testWhoopAccessTokenKeyValue() {
        XCTAssertEqual(SecureStore.Keys.whoopAccessToken, "whoop_access_token")
    }

    func testWhoopRefreshTokenKeyValue() {
        XCTAssertEqual(SecureStore.Keys.whoopRefreshToken, "whoop_refresh_token")
    }

    func testSessionFingerprintKeyValue() {
        XCTAssertEqual(SecureStore.Keys.sessionFingerprint, "session_fingerprint")
    }

    func testEncryptionKeyPrefixValue() {
        XCTAssertEqual(SecureStore.Keys.encryptionKeyPrefix, "com.getmodus.encryption.key.v")
    }

    func testEncryptionKeyVersionKeyValue() {
        XCTAssertEqual(SecureStore.Keys.encryptionKeyVersion, "com.getmodus.encryption.key.version")
    }

    func testEncryptionKeyPrefixFormatsVersionCorrectly() {
        let versionedKey = "\(SecureStore.Keys.encryptionKeyPrefix)1"
        XCTAssertEqual(versionedKey, "com.getmodus.encryption.key.v1")

        let v42 = "\(SecureStore.Keys.encryptionKeyPrefix)42"
        XCTAssertEqual(v42, "com.getmodus.encryption.key.v42")
    }

    func testAllKeysAreUnique() {
        let allKeys = [
            SecureStore.Keys.authToken,
            SecureStore.Keys.refreshToken,
            SecureStore.Keys.userIdentifier,
            SecureStore.Keys.whoopAccessToken,
            SecureStore.Keys.whoopRefreshToken,
            SecureStore.Keys.sessionFingerprint,
            SecureStore.Keys.encryptionKeyPrefix,
            SecureStore.Keys.encryptionKeyVersion
        ]
        let uniqueKeys = Set(allKeys)
        XCTAssertEqual(allKeys.count, uniqueKeys.count, "All key constants must be unique")
    }

    func testKeysDoNotContainWhitespace() {
        let allKeys = [
            SecureStore.Keys.authToken,
            SecureStore.Keys.refreshToken,
            SecureStore.Keys.userIdentifier,
            SecureStore.Keys.whoopAccessToken,
            SecureStore.Keys.whoopRefreshToken,
            SecureStore.Keys.sessionFingerprint,
            SecureStore.Keys.encryptionKeyPrefix,
            SecureStore.Keys.encryptionKeyVersion
        ]
        for key in allKeys {
            XCTAssertFalse(key.contains(" "), "Key '\(key)' should not contain spaces")
            XCTAssertFalse(key.contains("\n"), "Key '\(key)' should not contain newlines")
        }
    }
}

// MARK: - SecureStore Singleton & Keychain Tests

@MainActor
final class SecureStoreTests: XCTestCase {

    var sut: SecureStore!

    /// Unique key prefix for this test run to avoid collisions with real app data
    private let testKeyPrefix = "unit_test_\(UUID().uuidString.prefix(8))_"

    override func setUp() {
        super.setUp()
        sut = SecureStore.shared
    }

    override func tearDown() {
        // Clean up any test keys we created
        try? sut.delete(forKey: testKey("string"))
        try? sut.delete(forKey: testKey("data"))
        try? sut.delete(forKey: testKey("overwrite"))
        try? sut.delete(forKey: testKey("delete"))
        try? sut.delete(forKey: testKey("contains"))
        try? sut.delete(forKey: testKey("empty_string"))
        try? sut.delete(forKey: testKey("unicode"))
        try? sut.delete(forKey: testKey("large"))
        try? sut.delete(forKey: testKey("special_chars"))
        try? sut.delete(forKey: testKey("biometric"))
        try? sut.delete(forKey: testKey("biometric_string"))
        sut = nil
        super.tearDown()
    }

    private func testKey(_ name: String) -> String {
        return "\(testKeyPrefix)\(name)"
    }

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(SecureStore.shared)
    }

    func testSharedInstanceReturnsSameObject() {
        let instance1 = SecureStore.shared
        let instance2 = SecureStore.shared
        XCTAssertTrue(instance1 === instance2, "shared should return the same instance")
    }

    // MARK: - String Storage Round-Trip

    func testSetAndGetString() throws {
        let key = testKey("string")
        let value = "test-auth-token-12345"

        try sut.set(value, forKey: key)
        let retrieved = try sut.getString(forKey: key)

        XCTAssertEqual(retrieved, value)
    }

    func testGetStringReturnsNilForMissingKey() throws {
        let result = try sut.getString(forKey: testKey("nonexistent_key_\(UUID().uuidString)"))
        XCTAssertNil(result, "getString should return nil for a key that does not exist")
    }

    func testSetStringOverwritesExistingValue() throws {
        let key = testKey("overwrite")

        try sut.set("first-value", forKey: key)
        try sut.set("second-value", forKey: key)

        let retrieved = try sut.getString(forKey: key)
        XCTAssertEqual(retrieved, "second-value", "Latest value should overwrite the previous one")
    }

    func testSetAndGetEmptyString() throws {
        let key = testKey("empty_string")

        try sut.set("", forKey: key)
        let retrieved = try sut.getString(forKey: key)

        // Empty string encodes to zero-length UTF-8 data, which is valid
        XCTAssertEqual(retrieved, "")
    }

    func testSetAndGetUnicodeString() throws {
        let key = testKey("unicode")
        let value = "Patient data: \u{1F3CB}\u{FE0F} 180kg squat \u{2764}\u{FE0F}"

        try sut.set(value, forKey: key)
        let retrieved = try sut.getString(forKey: key)

        XCTAssertEqual(retrieved, value)
    }

    // MARK: - Data Storage Round-Trip

    func testSetAndGetData() throws {
        let key = testKey("data")
        let originalData = Data([0x00, 0x01, 0x02, 0xFF, 0xFE, 0xFD])

        try sut.set(originalData, forKey: key)
        let retrieved = try sut.getData(forKey: key)

        XCTAssertEqual(retrieved, originalData)
    }

    func testGetDataReturnsNilForMissingKey() throws {
        let result = try sut.getData(forKey: testKey("nonexistent_data_\(UUID().uuidString)"))
        XCTAssertNil(result)
    }

    func testSetLargeData() throws {
        let key = testKey("large")
        // 10 KB of random-ish data
        let largeData = Data((0..<10_240).map { UInt8($0 % 256) })

        try sut.set(largeData, forKey: key)
        let retrieved = try sut.getData(forKey: key)

        XCTAssertEqual(retrieved, largeData)
    }

    // MARK: - Deletion Tests

    func testDeleteExistingItem() throws {
        let key = testKey("delete")
        try sut.set("to-be-deleted", forKey: key)

        try sut.delete(forKey: key)

        let result = try sut.getString(forKey: key)
        XCTAssertNil(result, "Deleted item should no longer be retrievable")
    }

    func testDeleteNonExistentItemDoesNotThrow() {
        XCTAssertNoThrow(
            try sut.delete(forKey: testKey("never_existed_\(UUID().uuidString)")),
            "Deleting a non-existent key should not throw"
        )
    }

    func testClearAllDoesNotThrow() {
        // clearAll removes all items for the service; should not throw even if empty
        XCTAssertNoThrow(try sut.clearAll())
    }

    // MARK: - containsValue Tests

    func testContainsValueReturnsTrueForExistingItem() throws {
        let key = testKey("contains")
        try sut.set("present", forKey: key)

        XCTAssertTrue(sut.containsValue(forKey: key))
    }

    func testContainsValueReturnsFalseForMissingItem() {
        XCTAssertFalse(sut.containsValue(forKey: testKey("missing_\(UUID().uuidString)")))
    }

    func testContainsValueReturnsFalseAfterDeletion() throws {
        let key = testKey("contains")
        try sut.set("temporary", forKey: key)
        try sut.delete(forKey: key)

        XCTAssertFalse(sut.containsValue(forKey: key))
    }

    // MARK: - clearAuthCredentials Tests

    func testClearAuthCredentialsDoesNotThrow() {
        // Should safely iterate and delete, even if keys don't exist
        sut.clearAuthCredentials()
        // No assertion needed — just verifying it doesn't crash
    }

    func testClearAuthCredentialsClearsAuthToken() throws {
        try sut.set("test-token", forKey: SecureStore.Keys.authToken)

        sut.clearAuthCredentials()

        let result = try sut.getString(forKey: SecureStore.Keys.authToken)
        XCTAssertNil(result, "Auth token should be cleared after clearAuthCredentials()")
    }

    func testClearAuthCredentialsClearsRefreshToken() throws {
        try sut.set("test-refresh", forKey: SecureStore.Keys.refreshToken)

        sut.clearAuthCredentials()

        let result = try sut.getString(forKey: SecureStore.Keys.refreshToken)
        XCTAssertNil(result, "Refresh token should be cleared")
    }

    func testClearAuthCredentialsClearsSessionFingerprint() throws {
        try sut.set("fingerprint-abc", forKey: SecureStore.Keys.sessionFingerprint)

        sut.clearAuthCredentials()

        let result = try sut.getString(forKey: SecureStore.Keys.sessionFingerprint)
        XCTAssertNil(result, "Session fingerprint should be cleared")
    }

    func testClearAuthCredentialsPreservesEncryptionKeys() throws {
        // Store an encryption key
        let encKey = "\(SecureStore.Keys.encryptionKeyPrefix)1"
        try sut.set("enc-key-data", forKey: encKey)

        sut.clearAuthCredentials()

        let result = try sut.getString(forKey: encKey)
        XCTAssertEqual(result, "enc-key-data", "Encryption keys should NOT be cleared by clearAuthCredentials")

        // Clean up
        try? sut.delete(forKey: encKey)
    }

    // MARK: - Migration Tests

    func testMigrateIfNeededDoesNotThrow() {
        // Should complete without error, regardless of current migration state
        sut.migrateIfNeeded()
    }

    func testMigrateIfNeededSetsVersionInUserDefaults() {
        let migrationKey = "com.getmodus.securestore.migration_version"

        // Clear existing migration version
        UserDefaults.standard.removeObject(forKey: migrationKey)

        sut.migrateIfNeeded()

        let version = UserDefaults.standard.integer(forKey: migrationKey)
        XCTAssertEqual(version, 1, "Migration should set version to 1")
    }

    func testMigrateIfNeededIsIdempotent() {
        // Run migration twice — the second call should be a no-op
        sut.migrateIfNeeded()
        sut.migrateIfNeeded()
        // No crash or error expected
    }

    // MARK: - Audit Tests

    func testAuditKeychainItemsDoesNotThrow() {
        // Should complete without crash regardless of keychain state
        sut.auditKeychainItems()
    }

    // MARK: - Biometric Storage Fallback Tests

    func testSetWithBiometricDataFallsBackOnSimulator() throws {
        // On Simulator, biometrics are unavailable, so this should fall back
        // to standard keychain storage
        let key = testKey("biometric")
        let data = "biometric-test-data".data(using: .utf8)!

        try sut.setWithBiometric(data, forKey: key)

        // The data should still be retrievable via standard getData
        let retrieved = try sut.getData(forKey: key)
        XCTAssertEqual(retrieved, data, "Biometric fallback should store data in standard keychain")
    }

    func testSetWithBiometricStringFallsBackOnSimulator() throws {
        let key = testKey("biometric_string")
        let value = "biometric-secret-string"

        try sut.setWithBiometric(value, forKey: key)

        let retrieved = try sut.getString(forKey: key)
        XCTAssertEqual(retrieved, value, "Biometric string fallback should store via standard keychain")
    }

    // MARK: - Special Character Key Tests

    func testKeyWithSpecialCharacters() throws {
        let key = testKey("special_chars")
        let value = "value-for-special-key"

        try sut.set(value, forKey: key)
        let retrieved = try sut.getString(forKey: key)

        XCTAssertEqual(retrieved, value)
    }

    // MARK: - Rapid Overwrite Stability

    func testRapidOverwriteStability() throws {
        let key = testKey("overwrite")

        for i in 0..<20 {
            try sut.set("value-\(i)", forKey: key)
        }

        let finalValue = try sut.getString(forKey: key)
        XCTAssertEqual(finalValue, "value-19", "Final value should be the last one written")
    }
}
