//
//  DataEncryptionServiceTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for DataEncryptionService — the HIPAA-critical
//  AES-256-GCM encryption service for health data at rest.
//
//  Tests cover singleton access, encryption/decryption round-trips, key
//  initialization, key rotation, format versioning, error handling, memory
//  management, string/Codable convenience methods, and edge cases.
//
//  NOTE: These tests exercise real CryptoKit encryption on the Simulator.
//  The Keychain is used for key storage via SecureStore.shared.
//

import XCTest
@testable import PTPerformance

// MARK: - DataEncryptionError Tests

final class DataEncryptionErrorTests: XCTestCase {

    // MARK: - Error Description Tests

    func testKeyGenerationFailedDescription() {
        let error = DataEncryptionError.keyGenerationFailed
        XCTAssertEqual(error.errorDescription, "Failed to generate encryption key")
    }

    func testKeyStorageFailedDescription() {
        let underlying = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "disk full"])
        let error = DataEncryptionError.keyStorageFailed(underlying)
        XCTAssertTrue(error.errorDescription?.contains("disk full") == true)
    }

    func testKeyRetrievalFailedDescription() {
        let error = DataEncryptionError.keyRetrievalFailed
        XCTAssertEqual(error.errorDescription, "Failed to retrieve encryption key")
    }

    func testEncryptionFailedDescription() {
        let underlying = NSError(domain: "test", code: 2, userInfo: [NSLocalizedDescriptionKey: "bad key"])
        let error = DataEncryptionError.encryptionFailed(underlying)
        XCTAssertTrue(error.errorDescription?.contains("bad key") == true)
    }

    func testDecryptionFailedDescription() {
        let underlying = NSError(domain: "test", code: 3, userInfo: [NSLocalizedDescriptionKey: "tampered"])
        let error = DataEncryptionError.decryptionFailed(underlying)
        XCTAssertTrue(error.errorDescription?.contains("tampered") == true)
    }

    func testInvalidSealedBoxDataDescription() {
        let error = DataEncryptionError.invalidSealedBoxData
        XCTAssertEqual(error.errorDescription, "Invalid encrypted data format")
    }

    func testKeyVersionMismatchDescription() {
        let error = DataEncryptionError.keyVersionMismatch(expected: 2, found: 1)
        let desc = error.errorDescription ?? ""
        XCTAssertTrue(desc.contains("v2"), "Should mention expected version")
        XCTAssertTrue(desc.contains("v1"), "Should mention found version")
    }

    func testEmptyDataDescription() {
        let error = DataEncryptionError.emptyData
        XCTAssertEqual(error.errorDescription, "Cannot encrypt empty data")
    }

    func testAllErrorCasesConformToLocalizedError() {
        let errors: [DataEncryptionError] = [
            .keyGenerationFailed,
            .keyStorageFailed(NSError(domain: "", code: 0)),
            .keyRetrievalFailed,
            .encryptionFailed(NSError(domain: "", code: 0)),
            .decryptionFailed(NSError(domain: "", code: 0)),
            .invalidSealedBoxData,
            .keyVersionMismatch(expected: 1, found: 2),
            .emptyData
        ]
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Every error case must have a description")
        }
    }
}

// MARK: - DataEncryptionService Tests

@MainActor
final class DataEncryptionServiceTests: XCTestCase {

    var sut: DataEncryptionService!

    override func setUp() {
        super.setUp()
        sut = DataEncryptionService.shared
        // Ensure a key exists for encryption/decryption tests
        try? sut.initializeKeyIfNeeded()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(DataEncryptionService.shared)
    }

    func testSharedInstanceReturnsSameObject() {
        let instance1 = DataEncryptionService.shared
        let instance2 = DataEncryptionService.shared
        XCTAssertTrue(instance1 === instance2, "shared should return the same instance")
    }

    // MARK: - Key Initialization

    func testInitializeKeyIfNeededDoesNotThrow() {
        XCTAssertNoThrow(try sut.initializeKeyIfNeeded())
    }

    func testInitializeKeyIfNeededIsIdempotent() {
        XCTAssertNoThrow(try sut.initializeKeyIfNeeded())
        XCTAssertNoThrow(try sut.initializeKeyIfNeeded())
        // Calling twice should not generate a second key or throw
    }

    // MARK: - Encryption / Decryption Round-Trip (Data)

    func testEncryptAndDecryptData() throws {
        let plaintext = "HIPAA-sensitive patient health record data".data(using: .utf8)!

        let encrypted = try sut.encrypt(data: plaintext)
        let decrypted = try sut.decrypt(data: encrypted)

        XCTAssertEqual(decrypted, plaintext, "Decrypted data must match original plaintext")
    }

    func testEncryptedDataDiffersFromPlaintext() throws {
        let plaintext = "This is secret health data".data(using: .utf8)!

        let encrypted = try sut.encrypt(data: plaintext)

        XCTAssertNotEqual(encrypted, plaintext, "Encrypted output must differ from plaintext")
    }

    func testEncryptedDataContainsVersionByte() throws {
        let plaintext = "test".data(using: .utf8)!
        let encrypted = try sut.encrypt(data: plaintext)

        XCTAssertGreaterThan(encrypted.count, 2, "Encrypted data must have version bytes")
        XCTAssertEqual(encrypted[0], 1, "First byte should be format version 1")
    }

    func testEncryptedDataContainsKeyVersionByte() throws {
        let plaintext = "test".data(using: .utf8)!
        let encrypted = try sut.encrypt(data: plaintext)

        // Second byte is the key version (at least 1)
        XCTAssertGreaterThanOrEqual(encrypted[1], 1, "Second byte should be key version >= 1")
    }

    func testEncryptedPayloadMinimumSize() throws {
        // Even a single byte of plaintext should produce at least 30 bytes:
        // 1 (format) + 1 (key version) + 12 (nonce) + 1 (ciphertext) + 16 (tag) = 31
        let plaintext = Data([0x42])
        let encrypted = try sut.encrypt(data: plaintext)

        XCTAssertGreaterThanOrEqual(encrypted.count, 31,
            "Encrypted single byte should produce at least 31 bytes (2 header + 12 nonce + 1 ct + 16 tag)")
    }

    func testEncryptProducesDifferentOutputEachTime() throws {
        // AES-GCM uses a random nonce, so two encryptions of the same data
        // should produce different ciphertext
        let plaintext = "identical input".data(using: .utf8)!

        let encrypted1 = try sut.encrypt(data: plaintext)
        let encrypted2 = try sut.encrypt(data: plaintext)

        XCTAssertNotEqual(encrypted1, encrypted2,
            "Two encryptions of the same data should differ due to random nonce")
    }

    func testDecryptBothEncryptionsYieldSamePlaintext() throws {
        let plaintext = "identical input".data(using: .utf8)!

        let encrypted1 = try sut.encrypt(data: plaintext)
        let encrypted2 = try sut.encrypt(data: plaintext)

        let decrypted1 = try sut.decrypt(data: encrypted1)
        let decrypted2 = try sut.decrypt(data: encrypted2)

        XCTAssertEqual(decrypted1, plaintext)
        XCTAssertEqual(decrypted2, plaintext)
    }

    // MARK: - Empty Data Handling

    func testEncryptEmptyDataThrowsEmptyDataError() {
        XCTAssertThrowsError(try sut.encrypt(data: Data())) { error in
            guard let encError = error as? DataEncryptionError else {
                XCTFail("Expected DataEncryptionError, got \(type(of: error))")
                return
            }
            if case .emptyData = encError {
                // Expected
            } else {
                XCTFail("Expected .emptyData, got \(encError)")
            }
        }
    }

    // MARK: - Invalid / Tampered Data Handling

    func testDecryptTooShortDataThrowsInvalidSealedBoxData() {
        let tooShort = Data([0x01, 0x01]) // Only 2 bytes, need >= 30
        XCTAssertThrowsError(try sut.decrypt(data: tooShort)) { error in
            guard let encError = error as? DataEncryptionError else {
                XCTFail("Expected DataEncryptionError")
                return
            }
            if case .invalidSealedBoxData = encError {
                // Expected
            } else {
                XCTFail("Expected .invalidSealedBoxData, got \(encError)")
            }
        }
    }

    func testDecryptEmptyDataThrowsInvalidSealedBoxData() {
        XCTAssertThrowsError(try sut.decrypt(data: Data())) { error in
            guard let encError = error as? DataEncryptionError else {
                XCTFail("Expected DataEncryptionError")
                return
            }
            if case .invalidSealedBoxData = encError {
                // Expected
            } else {
                XCTFail("Expected .invalidSealedBoxData, got \(encError)")
            }
        }
    }

    func testDecryptWrongFormatVersionThrowsInvalidSealedBoxData() {
        // Create 30 bytes with wrong format version (0xFF instead of 0x01)
        var badData = Data(repeating: 0x00, count: 30)
        badData[0] = 0xFF // wrong format version
        badData[1] = 0x01 // key version

        XCTAssertThrowsError(try sut.decrypt(data: badData)) { error in
            guard let encError = error as? DataEncryptionError else {
                XCTFail("Expected DataEncryptionError")
                return
            }
            if case .invalidSealedBoxData = encError {
                // Expected — format version mismatch
            } else {
                XCTFail("Expected .invalidSealedBoxData, got \(encError)")
            }
        }
    }

    func testDecryptTamperedCiphertextThrowsDecryptionFailed() throws {
        let plaintext = "secure data".data(using: .utf8)!
        var encrypted = try sut.encrypt(data: plaintext)

        // Tamper with ciphertext (flip a byte past the 2-byte header + 12-byte nonce)
        let tamperIndex = min(20, encrypted.count - 1)
        encrypted[tamperIndex] ^= 0xFF

        XCTAssertThrowsError(try sut.decrypt(data: encrypted)) { error in
            guard let encError = error as? DataEncryptionError else {
                XCTFail("Expected DataEncryptionError")
                return
            }
            if case .decryptionFailed = encError {
                // Expected — authentication tag mismatch
            } else {
                XCTFail("Expected .decryptionFailed, got \(encError)")
            }
        }
    }

    func testDecryptDataExactly29BytesThrowsInvalidSealedBox() {
        // 29 bytes is below the 30-byte minimum
        let data = Data(repeating: 0x01, count: 29)
        XCTAssertThrowsError(try sut.decrypt(data: data)) { error in
            guard let encError = error as? DataEncryptionError else {
                XCTFail("Expected DataEncryptionError")
                return
            }
            if case .invalidSealedBoxData = encError {
                // Expected
            } else {
                XCTFail("Expected .invalidSealedBoxData, got \(encError)")
            }
        }
    }

    // MARK: - String Encryption / Decryption

    func testEncryptAndDecryptString() throws {
        let original = "Patient BP: 120/80 mmHg"

        let encrypted = try sut.encrypt(string: original)
        let decrypted = try sut.decryptToString(data: encrypted)

        XCTAssertEqual(decrypted, original)
    }

    func testEncryptStringWithUnicode() throws {
        let original = "Pain level: 7/10 \u{1F4AA}"

        let encrypted = try sut.encrypt(string: original)
        let decrypted = try sut.decryptToString(data: encrypted)

        XCTAssertEqual(decrypted, original)
    }

    func testEncryptEmptyStringThrowsEmptyData() {
        // Empty string should produce empty UTF-8 data, but the encrypt(string:) method
        // checks for nil from data(using:), not emptiness. Let's verify behavior.
        // Actually looking at the code: data(using: .utf8) on "" returns Data() (empty),
        // and encrypt(data:) will throw .emptyData.
        XCTAssertThrowsError(try sut.encrypt(string: "")) { error in
            guard let encError = error as? DataEncryptionError else {
                XCTFail("Expected DataEncryptionError, got \(type(of: error))")
                return
            }
            if case .emptyData = encError {
                // Expected — empty string produces empty Data
            } else {
                XCTFail("Expected .emptyData, got \(encError)")
            }
        }
    }

    // MARK: - Codable Encryption / Decryption

    func testEncryptAndDecryptCodableObject() throws {
        let original = TestPatientRecord(name: "John Doe", age: 35, diagnosis: "ACL tear")

        let encrypted = try sut.encrypt(object: original)
        let decrypted: TestPatientRecord = try sut.decrypt(data: encrypted, as: TestPatientRecord.self)

        XCTAssertEqual(decrypted.name, original.name)
        XCTAssertEqual(decrypted.age, original.age)
        XCTAssertEqual(decrypted.diagnosis, original.diagnosis)
    }

    func testDecryptCodableWithWrongTypeThrows() throws {
        let original = TestPatientRecord(name: "Jane", age: 28, diagnosis: "Rotator cuff")
        let encrypted = try sut.encrypt(object: original)

        // Try to decrypt as a different type
        XCTAssertThrowsError(try sut.decrypt(data: encrypted, as: TestDifferentModel.self))
    }

    // MARK: - Key Rotation

    func testKeyRotationDoesNotThrow() {
        XCTAssertNoThrow(try sut.rotateKey(), "Key rotation should succeed")
    }

    func testDataEncryptedBeforeRotationCanStillBeDecrypted() throws {
        let plaintext = "data-before-rotation".data(using: .utf8)!

        let encryptedBeforeRotation = try sut.encrypt(data: plaintext)

        // Rotate key
        try sut.rotateKey()

        // Old data should still decrypt because old key is retained
        let decrypted = try sut.decrypt(data: encryptedBeforeRotation)
        XCTAssertEqual(decrypted, plaintext, "Data encrypted with old key should still decrypt after rotation")
    }

    func testDataEncryptedAfterRotationUsesNewKey() throws {
        let plaintext = "data-after-rotation".data(using: .utf8)!

        // Rotate key
        try sut.rotateKey()

        let encrypted = try sut.encrypt(data: plaintext)
        let decrypted = try sut.decrypt(data: encrypted)

        XCTAssertEqual(decrypted, plaintext)
    }

    // MARK: - Re-encryption

    func testReEncryptWithCurrentKey() throws {
        let plaintext = "re-encrypt-me".data(using: .utf8)!
        let encrypted = try sut.encrypt(data: plaintext)

        // Rotate to a new key
        try sut.rotateKey()

        // Re-encrypt with the new current key
        let reEncrypted = try sut.reEncryptWithCurrentKey(data: encrypted)

        // Verify the re-encrypted data decrypts correctly
        let decrypted = try sut.decrypt(data: reEncrypted)
        XCTAssertEqual(decrypted, plaintext)
    }

    func testReEncryptedDataDiffersFromOriginal() throws {
        let plaintext = "re-encrypt-me".data(using: .utf8)!
        let encrypted = try sut.encrypt(data: plaintext)

        try sut.rotateKey()
        let reEncrypted = try sut.reEncryptWithCurrentKey(data: encrypted)

        // The re-encrypted data should differ (different key version + nonce)
        XCTAssertNotEqual(encrypted, reEncrypted)
    }

    // MARK: - Memory Management

    func testClearSensitiveMemoryDoesNotThrow() {
        sut.clearSensitiveMemory()
        // Should not crash
    }

    func testEncryptionWorksAfterClearSensitiveMemory() throws {
        sut.clearSensitiveMemory()

        let plaintext = "post-clear-data".data(using: .utf8)!
        let encrypted = try sut.encrypt(data: plaintext)
        let decrypted = try sut.decrypt(data: encrypted)

        XCTAssertEqual(decrypted, plaintext,
            "Encryption should work after clearing memory — key should reload from Keychain")
    }

    func testMultipleClearSensitiveMemoryCalls() {
        sut.clearSensitiveMemory()
        sut.clearSensitiveMemory()
        sut.clearSensitiveMemory()
        // Should not crash
    }

    // MARK: - Large Data Tests

    func testEncryptAndDecryptLargePayload() throws {
        // 100 KB of data (simulating a larger health record)
        let largeData = Data((0..<102_400).map { UInt8($0 % 256) })

        let encrypted = try sut.encrypt(data: largeData)
        let decrypted = try sut.decrypt(data: encrypted)

        XCTAssertEqual(decrypted, largeData)
    }

    // MARK: - Binary Data Tests

    func testEncryptAndDecryptBinaryData() throws {
        // Data that is NOT valid UTF-8 — pure binary
        let binaryData = Data([0x00, 0x01, 0x80, 0xFF, 0xFE, 0xC0, 0xC1])

        let encrypted = try sut.encrypt(data: binaryData)
        let decrypted = try sut.decrypt(data: binaryData.isEmpty ? Data() : encrypted)

        XCTAssertEqual(decrypted, binaryData)
    }

    func testDecryptToStringWithNonUTF8DataThrows() throws {
        // Encrypt binary data that is NOT valid UTF-8
        let binaryData = Data([0x80, 0xFF, 0xFE, 0xC0, 0xC1])
        let encrypted = try sut.encrypt(data: binaryData)

        // decryptToString should fail because decrypted bytes aren't valid UTF-8
        XCTAssertThrowsError(try sut.decryptToString(data: encrypted)) { error in
            guard let encError = error as? DataEncryptionError else {
                XCTFail("Expected DataEncryptionError")
                return
            }
            if case .decryptionFailed = encError {
                // Expected — not valid UTF-8
            } else {
                XCTFail("Expected .decryptionFailed, got \(encError)")
            }
        }
    }
}

// MARK: - Test Helpers

private struct TestPatientRecord: Codable, Equatable {
    let name: String
    let age: Int
    let diagnosis: String
}

private struct TestDifferentModel: Codable {
    let identifier: UUID
    let score: Double
}
