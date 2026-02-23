//
//  BiometricAuthServiceTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for BiometricAuthService — the HIPAA-critical
//  biometric authentication service for Face ID / Touch ID app access control.
//
//  Tests cover the BiometricType enum, BiometricLockTiming enum,
//  BiometricAuthError enum, singleton access, computed properties, state
//  management, app lifecycle lock/unlock logic, grace period behavior,
//  and configuration. Actual biometric hardware prompts are NOT invoked.
//

import XCTest
@testable import PTPerformance

// MARK: - BiometricType Tests

final class BiometricTypeTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testFaceIDRawValue() {
        XCTAssertEqual(BiometricType.faceID.rawValue, "Face ID")
    }

    func testTouchIDRawValue() {
        XCTAssertEqual(BiometricType.touchID.rawValue, "Touch ID")
    }

    func testNoneRawValue() {
        XCTAssertEqual(BiometricType.none.rawValue, "None")
    }

    func testInitFromRawValue() {
        XCTAssertEqual(BiometricType(rawValue: "Face ID"), .faceID)
        XCTAssertEqual(BiometricType(rawValue: "Touch ID"), .touchID)
        // BiometricType(rawValue: "None") returns .none which is a valid case
        let noneType = BiometricType(rawValue: "None")
        XCTAssertNotNil(noneType)
        XCTAssertEqual(noneType?.rawValue, "None")
    }

    func testInitFromInvalidRawValueReturnsNil() {
        // BiometricType has a `.none` case whose name collides with Optional.none.
        // We use an explicit Optional<BiometricType> binding to verify.
        let result: BiometricType? = BiometricType(rawValue: "Retina Scan")
        switch result {
        case .some(let value):
            XCTFail("Expected nil for invalid raw value 'Retina Scan', got \(value)")
        case .none:
            break // expected
        }
    }

    // MARK: - Icon Name Tests

    func testFaceIDIconName() {
        XCTAssertEqual(BiometricType.faceID.iconName, "faceid")
    }

    func testTouchIDIconName() {
        XCTAssertEqual(BiometricType.touchID.iconName, "touchid")
    }

    func testNoneIconName() {
        XCTAssertEqual(BiometricType.none.iconName, "lock.fill")
    }

    func testAllCasesHaveNonEmptyIconName() {
        let allCases: [BiometricType] = [.faceID, .touchID, .none]
        for biometricType in allCases {
            XCTAssertFalse(biometricType.iconName.isEmpty, "\(biometricType.rawValue) should have a non-empty icon name")
        }
    }
}

// MARK: - BiometricLockTiming Tests

final class BiometricLockTimingTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testImmediatelyRawValue() {
        XCTAssertEqual(BiometricLockTiming.immediately.rawValue, "Immediately")
    }

    func testAfter1MinuteRawValue() {
        XCTAssertEqual(BiometricLockTiming.after1Minute.rawValue, "After 1 minute")
    }

    func testAfter5MinutesRawValue() {
        XCTAssertEqual(BiometricLockTiming.after5Minutes.rawValue, "After 5 minutes")
    }

    func testAfter15MinutesRawValue() {
        XCTAssertEqual(BiometricLockTiming.after15Minutes.rawValue, "After 15 minutes")
    }

    func testInitFromRawValue() {
        XCTAssertEqual(BiometricLockTiming(rawValue: "Immediately"), .immediately)
        XCTAssertEqual(BiometricLockTiming(rawValue: "After 1 minute"), .after1Minute)
        XCTAssertEqual(BiometricLockTiming(rawValue: "After 5 minutes"), .after5Minutes)
        XCTAssertEqual(BiometricLockTiming(rawValue: "After 15 minutes"), .after15Minutes)
        XCTAssertNil(BiometricLockTiming(rawValue: "After 30 seconds"))
    }

    // MARK: - Duration Tests

    func testImmediatelyDuration() {
        XCTAssertEqual(BiometricLockTiming.immediately.duration, 0)
    }

    func testAfter1MinuteDuration() {
        XCTAssertEqual(BiometricLockTiming.after1Minute.duration, 60)
    }

    func testAfter5MinutesDuration() {
        XCTAssertEqual(BiometricLockTiming.after5Minutes.duration, 300)
    }

    func testAfter15MinutesDuration() {
        XCTAssertEqual(BiometricLockTiming.after15Minutes.duration, 900)
    }

    func testDurationsAreStrictlyIncreasing() {
        let allCases = BiometricLockTiming.allCases
        for i in 1..<allCases.count {
            XCTAssertGreaterThan(allCases[i].duration, allCases[i - 1].duration,
                "\(allCases[i].rawValue) duration should be greater than \(allCases[i - 1].rawValue)")
        }
    }

    // MARK: - CaseIterable Tests

    func testAllCasesCount() {
        XCTAssertEqual(BiometricLockTiming.allCases.count, 4)
    }

    func testAllCasesContainsAllValues() {
        let expected: Set<BiometricLockTiming> = [.immediately, .after1Minute, .after5Minutes, .after15Minutes]
        let actual = Set(BiometricLockTiming.allCases)
        XCTAssertEqual(actual, expected)
    }

    // MARK: - Identifiable Tests

    func testIdMatchesRawValue() {
        for timing in BiometricLockTiming.allCases {
            XCTAssertEqual(timing.id, timing.rawValue)
        }
    }

    func testAllIdsAreUnique() {
        let ids = BiometricLockTiming.allCases.map(\.id)
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "All lock timing IDs must be unique")
    }
}

// MARK: - BiometricAuthError Tests

final class BiometricAuthErrorTests: XCTestCase {

    func testBiometryNotAvailableDescription() {
        let error = BiometricAuthError.biometryNotAvailable
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("not available") == true)
    }

    func testBiometryNotEnrolledDescription() {
        let error = BiometricAuthError.biometryNotEnrolled
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("enrolled") == true)
    }

    func testAuthenticationFailedDescription() {
        let error = BiometricAuthError.authenticationFailed
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("failed") == true)
    }

    func testUserCancelledDescription() {
        let error = BiometricAuthError.userCancelled
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("cancelled") == true)
    }

    func testSystemCancelledDescription() {
        let error = BiometricAuthError.systemCancelled
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("cancelled") == true)
    }

    func testPasscodeNotSetDescription() {
        let error = BiometricAuthError.passcodeNotSet
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("passcode") == true)
    }

    func testUnknownErrorDescription() {
        let underlying = NSError(domain: "LAErrorDomain", code: -99, userInfo: [NSLocalizedDescriptionKey: "something broke"])
        let error = BiometricAuthError.unknown(underlying)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("something broke") == true)
    }

    func testAllErrorCasesHaveDescriptions() {
        let errors: [BiometricAuthError] = [
            .biometryNotAvailable,
            .biometryNotEnrolled,
            .authenticationFailed,
            .userCancelled,
            .systemCancelled,
            .passcodeNotSet,
            .unknown(NSError(domain: "", code: 0))
        ]
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error \(error) should have a non-nil description")
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true, "Error description should not be empty")
        }
    }

    func testAllErrorCasesConformToLocalizedError() {
        let error: LocalizedError = BiometricAuthError.authenticationFailed
        XCTAssertNotNil(error.errorDescription)
    }
}

// MARK: - BiometricAuthService Tests

@MainActor
final class BiometricAuthServiceTests: XCTestCase {

    var sut: BiometricAuthService!

    override func setUp() {
        super.setUp()
        sut = BiometricAuthService.shared
        // Reset state for clean tests
        sut.resetState()
        sut.disableBiometricLock()
    }

    override func tearDown() {
        sut.resetState()
        sut.disableBiometricLock()
        // Clean up AppStorage values used in tests
        UserDefaults.standard.removeObject(forKey: "biometricLockEnabled")
        UserDefaults.standard.removeObject(forKey: "biometricSensitiveScreenLock")
        UserDefaults.standard.removeObject(forKey: "biometricLockTiming")
        sut = nil
        super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(BiometricAuthService.shared)
    }

    func testSharedInstanceReturnsSameObject() {
        let instance1 = BiometricAuthService.shared
        let instance2 = BiometricAuthService.shared
        XCTAssertTrue(instance1 === instance2, "shared should return the same instance")
    }

    // MARK: - ObservableObject Conformance

    func testServiceIsObservableObject() {
        XCTAssertNotNil(sut.objectWillChange, "Service should conform to ObservableObject")
    }

    // MARK: - Initial State Tests

    func testInitialBiometricLockIsDisabled() {
        // After our setUp resets, lock should be disabled
        XCTAssertFalse(sut.isBiometricLockEnabled)
    }

    func testInitialIsLockedIsFalse() {
        XCTAssertFalse(sut.isLocked, "App should not be locked after reset")
    }

    // MARK: - Biometric Type Detection

    func testBiometricTypeIsSetAfterInit() {
        // On Simulator, biometrics are not available — type should be .none
        // On device, it could be .faceID or .touchID
        // We verify the property is accessible and has a valid value
        let biometricType = sut.biometricType
        XCTAssertNotNil(biometricType)

        // Simulator check
        #if targetEnvironment(simulator)
        XCTAssertEqual(biometricType, .none, "Biometric type should be .none on Simulator")
        #endif
    }

    func testDetectBiometricTypeDoesNotCrash() {
        sut.detectBiometricType()
        // Verify the property is still valid after re-detection
        let _ = sut.biometricType
    }

    // MARK: - isBiometryAvailable Computed Property

    func testIsBiometryAvailableMatchesBiometricType() {
        // isBiometryAvailable should be true when biometricType != .none
        if sut.biometricType == .none {
            XCTAssertFalse(sut.isBiometryAvailable)
        } else {
            XCTAssertTrue(sut.isBiometryAvailable)
        }
    }

    #if targetEnvironment(simulator)
    func testIsBiometryAvailableIsFalseOnSimulator() {
        XCTAssertFalse(sut.isBiometryAvailable, "Biometry should not be available on Simulator")
    }
    #endif

    // MARK: - Grace Period Tests

    func testIsWithinGracePeriodIsFalseInitially() {
        // After resetState(), lastAuthenticationTime is nil
        XCTAssertFalse(sut.isWithinGracePeriod, "Should not be in grace period when never authenticated")
    }

    // MARK: - Lock Timing Computed Property

    func testDefaultLockTimingIsImmediately() {
        // After clearing AppStorage, default should be .immediately
        UserDefaults.standard.removeObject(forKey: "biometricLockTiming")
        let timing = sut.lockTiming
        XCTAssertEqual(timing, .immediately)
    }

    func testSetLockTiming() {
        sut.lockTiming = .after5Minutes
        XCTAssertEqual(sut.lockTiming, .after5Minutes)
    }

    func testSetLockTimingAfter1Minute() {
        sut.lockTiming = .after1Minute
        XCTAssertEqual(sut.lockTiming, .after1Minute)
    }

    func testSetLockTimingAfter15Minutes() {
        sut.lockTiming = .after15Minutes
        XCTAssertEqual(sut.lockTiming, .after15Minutes)
    }

    func testLockTimingPersistsViaAppStorage() {
        sut.lockTiming = .after5Minutes

        // Read the raw value directly from UserDefaults
        let rawValue = UserDefaults.standard.string(forKey: "biometricLockTiming")
        XCTAssertEqual(rawValue, "After 5 minutes")
    }

    func testInvalidLockTimingRawValueDefaultsToImmediately() {
        // Write an invalid raw value directly
        UserDefaults.standard.set("After 42 seconds", forKey: "biometricLockTiming")

        let timing = sut.lockTiming
        XCTAssertEqual(timing, .immediately, "Invalid raw value should fall back to .immediately")
    }

    // MARK: - disableBiometricLock Tests

    func testDisableBiometricLockSetsEnabledToFalse() {
        sut.isBiometricLockEnabled = true
        sut.disableBiometricLock()

        XCTAssertFalse(sut.isBiometricLockEnabled)
    }

    func testDisableBiometricLockSetsLockedToFalse() {
        sut.isLocked = true
        sut.disableBiometricLock()

        XCTAssertFalse(sut.isLocked)
    }

    func testDisableBiometricLockCanBeCalledWhenAlreadyDisabled() {
        sut.disableBiometricLock()
        sut.disableBiometricLock() // should not crash
        XCTAssertFalse(sut.isBiometricLockEnabled)
    }

    // MARK: - resetState Tests

    func testResetStateSetsLockedToFalse() {
        sut.isLocked = true
        sut.resetState()
        XCTAssertFalse(sut.isLocked)
    }

    func testResetStateClearsGracePeriod() {
        sut.resetState()
        XCTAssertFalse(sut.isWithinGracePeriod, "Grace period should be cleared after reset")
    }

    func testResetStateIsIdempotent() {
        sut.resetState()
        sut.resetState()
        sut.resetState()
        XCTAssertFalse(sut.isLocked)
    }

    // MARK: - handleAppBackgrounded Tests

    func testHandleAppBackgroundedWhenLockDisabledIsNoOp() {
        sut.isBiometricLockEnabled = false
        sut.handleAppBackgrounded()
        // Should not crash, and isLocked should remain false
        XCTAssertFalse(sut.isLocked)
    }

    func testHandleAppBackgroundedWhenLockEnabledDoesNotImmediatelyLock() {
        sut.isBiometricLockEnabled = true
        sut.handleAppBackgrounded()
        // Backgrounding alone does not lock — foregrounding does
        XCTAssertFalse(sut.isLocked)
    }

    // MARK: - handleAppForegrounded Tests

    func testHandleAppForegroundedWhenLockDisabledKeepsUnlocked() {
        sut.isBiometricLockEnabled = false
        sut.isLocked = true // force locked state

        sut.handleAppForegrounded()

        XCTAssertFalse(sut.isLocked, "Should unlock when biometric lock is disabled")
    }

    func testHandleAppForegroundedWithNoBackgroundTimestampLocksWhenEnabled() {
        sut.isBiometricLockEnabled = true
        sut.resetState() // clears backgroundedAt

        sut.handleAppForegrounded()

        // With no background timestamp and no grace period, it should lock
        XCTAssertTrue(sut.isLocked, "Should lock when no background timestamp is recorded")
    }

    func testHandleAppForegroundedImmediatelyAfterBackgroundLocksWithImmediateTiming() {
        sut.isBiometricLockEnabled = true
        sut.lockTiming = .immediately

        sut.handleAppBackgrounded()
        // No delay — immediately foreground
        sut.handleAppForegrounded()

        // With .immediately timing (0 seconds), should lock
        XCTAssertTrue(sut.isLocked)
    }

    // MARK: - Sensitive Screen Lock

    func testSensitiveScreenLockDefaultsToFalse() {
        UserDefaults.standard.removeObject(forKey: "biometricSensitiveScreenLock")
        // Re-check via fresh read
        let value = UserDefaults.standard.bool(forKey: "biometricSensitiveScreenLock")
        XCTAssertFalse(value)
    }

    func testSensitiveScreenLockCanBeEnabled() {
        sut.isSensitiveScreenLockEnabled = true
        XCTAssertTrue(sut.isSensitiveScreenLockEnabled)
    }

    func testSensitiveScreenLockCanBeDisabled() {
        sut.isSensitiveScreenLockEnabled = true
        sut.isSensitiveScreenLockEnabled = false
        XCTAssertFalse(sut.isSensitiveScreenLockEnabled)
    }

    // MARK: - confirmAction Configuration Tests

    // NOTE: We do NOT call confirmAction/authenticate/unlock directly in tests
    // because LAContext.evaluatePolicy can crash the test runner on Simulator
    // when there is no enrolled biometric or passcode. Instead we test the
    // guard logic (grace period, lock state) and public configuration.

    // MARK: - Published Property Tests

    func testIsLockedCanBeSetDirectly() {
        sut.isLocked = true
        XCTAssertTrue(sut.isLocked)

        sut.isLocked = false
        XCTAssertFalse(sut.isLocked)
    }

    func testBiometricTypeIsReadOnly() {
        // biometricType is `private(set)` — we can read but not set from outside.
        // This is a compile-time guarantee, so we just verify we can read it.
        let type = sut.biometricType
        XCTAssertNotNil(type)
    }
}
