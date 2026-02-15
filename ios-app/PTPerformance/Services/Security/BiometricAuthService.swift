//
//  BiometricAuthService.swift
//  PTPerformance
//
//  ACP-1039: Biometric Authentication - Face ID / Touch ID for app access
//  Secure Enclave integration via LocalAuthentication framework
//

import Foundation
import LocalAuthentication
import SwiftUI

// MARK: - Biometric Type

/// Represents the biometric authentication type available on the device
enum BiometricType: String {
    case faceID = "Face ID"
    case touchID = "Touch ID"
    case none = "None"

    /// SF Symbol icon name for the biometric type
    var iconName: String {
        switch self {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .none: return "lock.fill"
        }
    }
}

// MARK: - Biometric Lock Timing

/// Controls when the biometric lock engages
enum BiometricLockTiming: String, CaseIterable, Identifiable {
    case immediately = "Immediately"
    case after1Minute = "After 1 minute"
    case after5Minutes = "After 5 minutes"
    case after15Minutes = "After 15 minutes"

    var id: String { rawValue }

    /// Duration in seconds before lock engages after backgrounding
    var duration: TimeInterval {
        switch self {
        case .immediately: return 0
        case .after1Minute: return 60
        case .after5Minutes: return 300
        case .after15Minutes: return 900
        }
    }
}

// MARK: - Biometric Auth Error

/// Errors that can occur during biometric authentication
enum BiometricAuthError: LocalizedError {
    case biometryNotAvailable
    case biometryNotEnrolled
    case authenticationFailed
    case userCancelled
    case systemCancelled
    case passcodeNotSet
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .biometryNotAvailable:
            return "Biometric authentication is not available on this device."
        case .biometryNotEnrolled:
            return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings."
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .userCancelled:
            return "Authentication was cancelled."
        case .systemCancelled:
            return "Authentication was cancelled by the system."
        case .passcodeNotSet:
            return "A device passcode is required to use biometric authentication."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}

// MARK: - BiometricAuthService

/// Singleton service for biometric authentication using the Secure Enclave
///
/// Provides Face ID / Touch ID authentication for app access and sensitive actions.
/// Integrates with the LocalAuthentication framework and uses the Secure Enclave
/// for biometric verification.
///
/// ## Usage Example
/// ```swift
/// let service = BiometricAuthService.shared
///
/// // Check if biometrics are available
/// if service.biometricType != .none {
///     let success = await service.authenticate(reason: "Unlock PT Performance")
/// }
/// ```
@MainActor
final class BiometricAuthService: ObservableObject {

    // MARK: - Singleton

    static let shared = BiometricAuthService()

    // MARK: - Published Properties

    /// Whether biometric lock is enabled by the user
    @AppStorage("biometricLockEnabled") var isBiometricLockEnabled = false

    /// Whether sensitive screen lock is enabled (labs, health data)
    @AppStorage("biometricSensitiveScreenLock") var isSensitiveScreenLockEnabled = false

    /// Lock timing preference
    @AppStorage("biometricLockTiming") private var lockTimingRawValue: String = BiometricLockTiming.immediately.rawValue

    /// Whether the app is currently locked
    @Published var isLocked = false

    /// The detected biometric type
    @Published private(set) var biometricType: BiometricType = .none

    // MARK: - Private Properties

    /// Timestamp of last successful authentication
    private var lastAuthenticationTime: Date?

    /// Grace period (5 minutes) to avoid re-prompting
    private static let gracePeriod: TimeInterval = 300

    /// Timestamp when app went to background
    private var backgroundedAt: Date?

    /// Logger
    private let debugLogger = DebugLogger.shared

    // MARK: - Computed Properties

    /// The current lock timing setting
    var lockTiming: BiometricLockTiming {
        get {
            BiometricLockTiming(rawValue: lockTimingRawValue) ?? .immediately
        }
        set {
            lockTimingRawValue = newValue.rawValue
        }
    }

    /// Whether biometric authentication is available on the device
    var isBiometryAvailable: Bool {
        biometricType != .none
    }

    /// Whether the user has recently authenticated (within grace period)
    var isWithinGracePeriod: Bool {
        guard let lastAuth = lastAuthenticationTime else { return false }
        return Date().timeIntervalSince(lastAuth) < Self.gracePeriod
    }

    // MARK: - Initialization

    private init() {
        detectBiometricType()
    }

    // MARK: - Public Methods

    /// Detects the available biometric type on the device
    func detectBiometricType() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID:
                biometricType = .faceID
            case .touchID:
                biometricType = .touchID
            case .opticID:
                biometricType = .faceID // Treat opticID as faceID for display
            @unknown default:
                biometricType = .none
            }
            debugLogger.log("[BiometricAuthService] Detected biometric type: \(biometricType.rawValue)", level: .success)
        } else {
            biometricType = .none
            if let error = error {
                debugLogger.log("[BiometricAuthService] Biometry not available: \(error.localizedDescription)", level: .warning)
            }
        }
    }

    /// Authenticate using biometrics (Face ID / Touch ID)
    ///
    /// - Parameter reason: The reason string displayed to the user
    /// - Returns: `true` if authentication succeeded
    func authenticate(reason: String = "Unlock PT Performance") async -> Bool {
        // Skip if within grace period
        if isWithinGracePeriod {
            debugLogger.log("[BiometricAuthService] Within grace period, skipping authentication", level: .diagnostic)
            return true
        }

        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            if success {
                lastAuthenticationTime = Date()
                debugLogger.log("[BiometricAuthService] Biometric authentication succeeded", level: .success)
            }

            return success
        } catch {
            debugLogger.log("[BiometricAuthService] Biometric authentication failed: \(error.localizedDescription)", level: .warning)
            return false
        }
    }

    /// Authenticate with fallback to device passcode
    ///
    /// Uses `deviceOwnerAuthentication` policy which includes biometrics + passcode fallback.
    /// This is used for sensitive actions where we must verify identity.
    ///
    /// - Parameter reason: The reason string displayed to the user
    /// - Returns: `true` if authentication succeeded
    func authenticateWithPasscodeFallback(reason: String = "Verify your identity") async -> Bool {
        // Skip if within grace period
        if isWithinGracePeriod {
            debugLogger.log("[BiometricAuthService] Within grace period, skipping authentication", level: .diagnostic)
            return true
        }

        let context = LAContext()

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )

            if success {
                lastAuthenticationTime = Date()
                debugLogger.log("[BiometricAuthService] Authentication with passcode fallback succeeded", level: .success)
            }

            return success
        } catch {
            debugLogger.log("[BiometricAuthService] Authentication with passcode fallback failed: \(error.localizedDescription)", level: .warning)
            return false
        }
    }

    /// Confirm a destructive or sensitive action with biometric verification
    ///
    /// - Parameter actionDescription: Description of the action being confirmed
    /// - Returns: `true` if the user confirmed the action via biometrics/passcode
    func confirmAction(_ actionDescription: String) async -> Bool {
        let reason = "Confirm: \(actionDescription)"
        return await authenticateWithPasscodeFallback(reason: reason)
    }

    /// Enable biometric lock — requires successful biometric auth first
    ///
    /// - Returns: `true` if biometric lock was successfully enabled
    func enableBiometricLock() async -> Bool {
        let success = await authenticate(reason: "Enable \(biometricType.rawValue) lock")
        if success {
            isBiometricLockEnabled = true
            debugLogger.log("[BiometricAuthService] Biometric lock enabled", level: .success)
        }
        return success
    }

    /// Disable biometric lock
    func disableBiometricLock() {
        isBiometricLockEnabled = false
        isLocked = false
        debugLogger.log("[BiometricAuthService] Biometric lock disabled", level: .info)
    }

    // MARK: - App Lifecycle Methods

    /// Called when app enters background — records the background timestamp
    func handleAppBackgrounded() {
        guard isBiometricLockEnabled else { return }
        backgroundedAt = Date()
        debugLogger.log("[BiometricAuthService] App backgrounded, lock will engage after \(lockTiming.rawValue)", level: .diagnostic)
    }

    /// Called when app enters foreground — checks if lock should engage
    func handleAppForegrounded() {
        guard isBiometricLockEnabled else {
            isLocked = false
            return
        }

        // If recently authenticated (grace period), don't lock
        if isWithinGracePeriod {
            debugLogger.log("[BiometricAuthService] Within grace period, staying unlocked", level: .diagnostic)
            return
        }

        // Check if enough time has passed based on lock timing
        if let backgroundedAt = backgroundedAt {
            let elapsed = Date().timeIntervalSince(backgroundedAt)
            if elapsed >= lockTiming.duration {
                isLocked = true
                debugLogger.log("[BiometricAuthService] Lock engaged after \(Int(elapsed))s in background", level: .info)
            }
        } else {
            // No background timestamp — lock if biometric is enabled
            isLocked = true
        }
    }

    /// Unlock the app after successful biometric authentication
    func unlock() async -> Bool {
        let success = await authenticateWithPasscodeFallback(reason: "Unlock PT Performance")
        if success {
            isLocked = false
            lastAuthenticationTime = Date()
            HapticFeedback.success()
            debugLogger.log("[BiometricAuthService] App unlocked successfully", level: .success)
        } else {
            HapticFeedback.error()
        }
        return success
    }

    /// Reset authentication state (e.g., on logout)
    func resetState() {
        isLocked = false
        lastAuthenticationTime = nil
        backgroundedAt = nil
        debugLogger.log("[BiometricAuthService] Authentication state reset", level: .diagnostic)
    }
}
