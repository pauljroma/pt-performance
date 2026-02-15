//
//  SecureFileManager.swift
//  PTPerformance
//
//  ACP-1045: Secure Local Storage
//  Manages file protection attributes, secure temp files, and encrypted file I/O.
//

import Foundation

// MARK: - SecureFileError

/// Errors that can occur during secure file operations
enum SecureFileError: Error, LocalizedError {
    /// The target directory does not exist and could not be created
    case directoryNotFound(String)
    /// Failed to apply file protection attributes
    case fileProtectionFailed(String, Error)
    /// Failed to write encrypted file
    case writeFailed(String, Error)
    /// Failed to read encrypted file
    case readFailed(String, Error)
    /// Failed to securely delete a file
    case deleteFailed(String, Error)
    /// The file does not exist at the given path
    case fileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .directoryNotFound(let path):
            return "Directory not found: \(path)"
        case .fileProtectionFailed(let path, let error):
            return "Failed to apply file protection to \(path): \(error.localizedDescription)"
        case .writeFailed(let path, let error):
            return "Failed to write file at \(path): \(error.localizedDescription)"
        case .readFailed(let path, let error):
            return "Failed to read file at \(path): \(error.localizedDescription)"
        case .deleteFailed(let path, let error):
            return "Failed to delete file at \(path): \(error.localizedDescription)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        }
    }
}

// MARK: - SecureFileManager

/// Manages secure file operations including file protection, encrypted I/O,
/// and secure temporary file handling.
///
/// ## File Protection
/// Applies `NSFileProtectionComplete` to the app's Documents and Caches
/// directories on launch, ensuring files are only accessible when the device
/// is unlocked.
///
/// ## Encrypted Files
/// Uses `DataEncryptionService` to encrypt data before writing and decrypt
/// after reading, providing AES-256-GCM encryption at rest.
///
/// ## Secure Deletion
/// Overwrites file contents with random data before unlinking, making
/// recovery of sensitive data from flash storage more difficult.
final class SecureFileManager {

    // MARK: - Singleton

    static let shared = SecureFileManager()

    // MARK: - Properties

    private let fileManager = FileManager.default
    private let logger = DebugLogger.shared
    private let encryption = DataEncryptionService.shared

    /// Tracks temp files created by this service for cleanup
    private var activeTempFiles: [URL] = []
    private let tempFileLock = NSLock()

    // MARK: - Initialization

    private init() {}

    // MARK: - File Protection

    /// Applies `NSFileProtectionComplete` to all app-managed directories.
    ///
    /// Call this once during app launch. Protects:
    /// - Documents directory
    /// - Caches directory
    /// - Application Support directory
    /// - Temporary directory
    ///
    /// Files in protected directories are inaccessible when the device is locked.
    func applyFileProtection() {
        logger.info("[SecureFileManager] Applying file protection to app directories")

        var protectedCount = 0
        var failedCount = 0

        let directories: [(String, URL?)] = [
            ("Documents", fileManager.urls(for: .documentDirectory, in: .userDomainMask).first),
            ("Caches", fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first),
            ("ApplicationSupport", fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first),
            ("Temp", URL(fileURLWithPath: NSTemporaryDirectory()))
        ]

        for (name, url) in directories {
            guard let directoryURL = url else {
                logger.warning("[SecureFileManager] Could not resolve \(name) directory")
                failedCount += 1
                continue
            }

            // Create directory if it does not exist
            if !fileManager.fileExists(atPath: directoryURL.path) {
                do {
                    try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
                } catch {
                    logger.warning("[SecureFileManager] Could not create \(name) directory: \(error.localizedDescription)")
                    failedCount += 1
                    continue
                }
            }

            do {
                try fileManager.setAttributes(
                    [.protectionKey: FileProtectionType.complete],
                    ofItemAtPath: directoryURL.path
                )
                protectedCount += 1
            } catch {
                // This can fail in simulator — log but don't treat as fatal
                logger.warning("[SecureFileManager] Could not set file protection on \(name): \(error.localizedDescription)")
                failedCount += 1
            }
        }

        if failedCount == 0 {
            logger.success("[SecureFileManager] File protection applied to \(protectedCount) directories")
        } else {
            logger.warning("[SecureFileManager] File protection: \(protectedCount) succeeded, \(failedCount) failed (may be expected in Simulator)")
        }
    }

    // MARK: - Encrypted File I/O

    /// Writes data to a file after encrypting it with AES-256-GCM.
    ///
    /// The file is also protected with `NSFileProtectionComplete` attributes.
    ///
    /// - Parameters:
    ///   - data: The plaintext data to encrypt and write.
    ///   - url: The destination file URL.
    /// - Throws: `SecureFileError` or `DataEncryptionError` on failure.
    func writeEncryptedFile(data: Data, to url: URL) throws {
        do {
            let encrypted = try encryption.encrypt(data: data)

            // Ensure parent directory exists
            let directory = url.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }

            try encrypted.write(to: url, options: [.atomic, .completeFileProtection])
        } catch let error as DataEncryptionError {
            throw error
        } catch {
            throw SecureFileError.writeFailed(url.path, error)
        }
    }

    /// Reads and decrypts a file that was written by `writeEncryptedFile(data:to:)`.
    ///
    /// - Parameter url: The file URL to read.
    /// - Returns: The decrypted plaintext data.
    /// - Throws: `SecureFileError` or `DataEncryptionError` on failure.
    func readEncryptedFile(from url: URL) throws -> Data {
        guard fileManager.fileExists(atPath: url.path) else {
            throw SecureFileError.fileNotFound(url.path)
        }

        do {
            let encrypted = try Data(contentsOf: url)
            return try encryption.decrypt(data: encrypted)
        } catch let error as DataEncryptionError {
            throw error
        } catch {
            throw SecureFileError.readFailed(url.path, error)
        }
    }

    /// Writes a `Codable` object as an encrypted JSON file.
    ///
    /// - Parameters:
    ///   - object: The encodable object.
    ///   - url: The destination file URL.
    func writeEncryptedObject<T: Encodable>(_ object: T, to url: URL) throws {
        let jsonData = try JSONEncoder().encode(object)
        try writeEncryptedFile(data: jsonData, to: url)
    }

    /// Reads and decodes an encrypted JSON file into a `Codable` object.
    ///
    /// - Parameters:
    ///   - type: The expected `Decodable` type.
    ///   - url: The file URL to read.
    /// - Returns: The decoded object.
    func readEncryptedObject<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        let data = try readEncryptedFile(from: url)
        return try JSONDecoder().decode(type, from: data)
    }

    // MARK: - Secure Temp Files

    /// Creates a secure temporary file with auto-cleanup tracking.
    ///
    /// The file is created in the system temp directory with file protection
    /// attributes. It is tracked for cleanup when `cleanupTempFiles()` is called
    /// or when the `SecureFileManager` is deinitialized.
    ///
    /// - Parameters:
    ///   - data: The data to write (will be encrypted).
    ///   - prefix: A filename prefix for identification.
    /// - Returns: The URL of the created temp file.
    func createSecureTempFile(data: Data, prefix: String = "modus_secure") throws -> URL {
        let tempDir = fileManager.temporaryDirectory
        let fileName = "\(prefix)_\(UUID().uuidString).tmp"
        let tempURL = tempDir.appendingPathComponent(fileName)

        try writeEncryptedFile(data: data, to: tempURL)

        tempFileLock.lock()
        activeTempFiles.append(tempURL)
        tempFileLock.unlock()

        logger.diagnostic("[SecureFileManager] Created secure temp file: \(fileName)")
        return tempURL
    }

    /// Securely deletes all tracked temporary files.
    ///
    /// Each file is overwritten with random bytes before deletion.
    func cleanupTempFiles() {
        tempFileLock.lock()
        let files = activeTempFiles
        activeTempFiles.removeAll()
        tempFileLock.unlock()

        var cleaned = 0
        for url in files {
            do {
                try secureDelete(at: url)
                cleaned += 1
            } catch {
                logger.warning("[SecureFileManager] Failed to clean up temp file: \(error.localizedDescription)")
            }
        }

        if cleaned > 0 {
            logger.diagnostic("[SecureFileManager] Cleaned up \(cleaned) temp file(s)")
        }
    }

    // MARK: - Secure Deletion

    /// Securely deletes a file by overwriting its contents before removing it.
    ///
    /// Writes random data over the file contents to make recovery from flash
    /// storage more difficult, then removes the file.
    ///
    /// - Parameter url: The file URL to securely delete.
    /// - Throws: `SecureFileError` on failure.
    func secureDelete(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else {
            // Already gone — not an error
            return
        }

        do {
            // Read file size to know how many random bytes to write
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int ?? 0

            if fileSize > 0 {
                // Overwrite with random data
                var randomBytes = [UInt8](repeating: 0, count: fileSize)
                let status = SecRandomCopyBytes(kSecRandomDefault, fileSize, &randomBytes)
                if status == errSecSuccess {
                    let randomData = Data(randomBytes)
                    try randomData.write(to: url, options: .atomic)
                }
                // Zero out the local buffer
                randomBytes.resetBytes(in: 0..<fileSize)
            }

            // Remove the file
            try fileManager.removeItem(at: url)
        } catch {
            throw SecureFileError.deleteFailed(url.path, error)
        }
    }

    // MARK: - Utility

    /// Returns the Documents directory URL with an optional subdirectory.
    ///
    /// Creates the subdirectory if it does not exist.
    func secureDocumentsURL(subdirectory: String? = nil) throws -> URL {
        guard var url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw SecureFileError.directoryNotFound("Documents")
        }

        if let sub = subdirectory {
            url = url.appendingPathComponent(sub)
            if !fileManager.fileExists(atPath: url.path) {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
                try fileManager.setAttributes(
                    [.protectionKey: FileProtectionType.complete],
                    ofItemAtPath: url.path
                )
            }
        }

        return url
    }
}
