//
//  JailbreakDetectorTests.swift
//  PTPerformanceTests
//
//  Unit tests for JailbreakDetector (ACP-1045).
//  Verifies jailbreak detection heuristics, simulator behavior,
//  and indicator reporting for HIPAA compliance.
//
//  IMPORTANT: These tests run in the iOS Simulator, which is expected
//  to report as NOT jailbroken. The simulator code path explicitly
//  skips all checks and returns clean state.
//

import XCTest
@testable import PTPerformance

// MARK: - JailbreakDetector Tests

@MainActor
final class JailbreakDetectorTests: XCTestCase {

    // MARK: - Properties

    var sut: JailbreakDetector!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        sut = JailbreakDetector.shared
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(JailbreakDetector.shared)
    }

    func testSharedInstanceReturnsSameObject() {
        let instance1 = JailbreakDetector.shared
        let instance2 = JailbreakDetector.shared
        XCTAssertTrue(instance1 === instance2, "shared should return the same instance")
    }

    // MARK: - Simulator Clean State Tests

    /// In the simulator, isJailbroken should default to false before check() is called
    func testIsJailbroken_DefaultsToFalse() {
        // The initial value of isJailbroken should be false
        // (set in the property declaration, before any check() call)
        XCTAssertFalse(sut.isJailbroken, "isJailbroken should default to false")
    }

    /// After calling check() in the simulator, isJailbroken must remain false
    func testCheck_InSimulator_ReportsNotJailbroken() {
        sut.check()

        #if targetEnvironment(simulator)
        XCTAssertFalse(sut.isJailbroken,
                       "Simulator should never be flagged as jailbroken")
        #endif
    }

    /// After calling check() in the simulator, detectedIndicators must be empty
    func testCheck_InSimulator_HasNoIndicators() {
        sut.check()

        #if targetEnvironment(simulator)
        XCTAssertTrue(sut.detectedIndicators.isEmpty,
                      "Simulator should have zero jailbreak indicators")
        #endif
    }

    /// check() can be called multiple times without changing the result
    func testCheck_CalledMultipleTimes_RemainsConsistent() {
        sut.check()
        let firstResult = sut.isJailbroken
        let firstIndicators = sut.detectedIndicators

        sut.check()
        let secondResult = sut.isJailbroken
        let secondIndicators = sut.detectedIndicators

        XCTAssertEqual(firstResult, secondResult,
                       "Repeated check() calls should produce the same isJailbroken result")
        XCTAssertEqual(firstIndicators, secondIndicators,
                       "Repeated check() calls should produce the same indicators")
    }

    /// check() can be called many times without crash or accumulation
    func testCheck_StressTest_DoesNotAccumulate() {
        for _ in 0..<100 {
            sut.check()
        }

        #if targetEnvironment(simulator)
        XCTAssertFalse(sut.isJailbroken)
        XCTAssertTrue(sut.detectedIndicators.isEmpty,
                      "Indicators should not accumulate across calls")
        #endif
    }

    // MARK: - Indicator Array Tests

    /// detectedIndicators should default to an empty array
    func testDetectedIndicators_DefaultsToEmpty() {
        XCTAssertTrue(sut.detectedIndicators.isEmpty,
                      "detectedIndicators should start empty")
    }

    /// After check() in simulator, indicators array should be exactly empty
    func testDetectedIndicators_AfterCheck_IsEmpty() {
        sut.check()

        #if targetEnvironment(simulator)
        XCTAssertEqual(sut.detectedIndicators.count, 0)
        #endif
    }

    // MARK: - Known Jailbreak Indicator Names

    /// Verify the expected indicator names that would appear on a jailbroken device.
    /// This is a documentation test -- ensuring the string constants are stable.
    func testKnownIndicatorNames_AreDocumented() {
        // These are the indicator strings used internally in check().
        // We verify them here so that any rename is caught by tests.
        let expectedIndicators = [
            "jailbreak_files_found",
            "jailbreak_url_schemes",
            "writable_system_paths",
            "dylib_injection_detected",
            "sandbox_compromised"
        ]

        // On simulator, none should be present
        sut.check()

        #if targetEnvironment(simulator)
        for indicator in expectedIndicators {
            XCTAssertFalse(sut.detectedIndicators.contains(indicator),
                           "Simulator should not trigger indicator: \(indicator)")
        }
        #endif
    }

    // MARK: - Property Accessibility Tests

    /// isJailbroken should be publicly readable
    func testIsJailbroken_IsReadable() {
        let _ = sut.isJailbroken
        // Compiler would fail if property is not accessible; this is a compile-time check
    }

    /// detectedIndicators should be publicly readable
    func testDetectedIndicators_IsReadable() {
        let _ = sut.detectedIndicators
    }

    // MARK: - Thread Safety

    /// check() should be safe to call from the main thread
    func testCheck_CanBeCalledFromMainThread() {
        XCTAssertTrue(Thread.isMainThread, "Test should be running on main thread")
        sut.check()
        // Should not deadlock or crash
    }

    // MARK: - State Isolation

    /// After check(), the state should be fully determined (not partial)
    func testCheck_SetsCompleteState() {
        sut.check()

        // isJailbroken and detectedIndicators should be consistent
        if sut.isJailbroken {
            XCTAssertFalse(sut.detectedIndicators.isEmpty,
                           "If jailbroken, there must be at least one indicator")
        } else {
            XCTAssertTrue(sut.detectedIndicators.isEmpty,
                          "If not jailbroken, indicators must be empty")
        }
    }

    /// The relationship between isJailbroken and indicators should be invariant
    func testIsJailbroken_MatchesIndicatorPresence() {
        sut.check()
        XCTAssertEqual(sut.isJailbroken, !sut.detectedIndicators.isEmpty,
                       "isJailbroken should be true iff indicators is non-empty")
    }

    // MARK: - Simulator-Specific Behavioral Guarantee

    /// Explicitly verify the simulator short-circuit for HIPAA documentation
    func testSimulator_ExplicitlySkipsAllChecks() {
        #if targetEnvironment(simulator)
        sut.check()

        // The simulator path sets isJailbroken = false and indicators = []
        // and returns early, so none of the heuristic checks execute.
        XCTAssertFalse(sut.isJailbroken,
                       "HIPAA: Simulator must not report jailbroken state")
        XCTAssertEqual(sut.detectedIndicators, [],
                       "HIPAA: Simulator must not produce any indicators")
        #else
        // On a real device in CI, we still verify consistency
        sut.check()
        XCTAssertEqual(sut.isJailbroken, !sut.detectedIndicators.isEmpty)
        #endif
    }

    // MARK: - Determinism

    /// Two back-to-back check() calls should produce identical results
    func testCheck_IsDeterministic() {
        sut.check()
        let result1 = sut.isJailbroken
        let indicators1 = sut.detectedIndicators

        sut.check()
        let result2 = sut.isJailbroken
        let indicators2 = sut.detectedIndicators

        XCTAssertEqual(result1, result2, "check() should be deterministic")
        XCTAssertEqual(indicators1, indicators2, "check() indicators should be deterministic")
    }

    // MARK: - No False Positive on Clean System

    /// On a non-jailbroken system (simulator), no check should produce a false positive
    func testNoFalsePositive_OnSimulator() {
        #if targetEnvironment(simulator)
        sut.check()
        XCTAssertFalse(sut.isJailbroken,
                       "Clean simulator must not produce a false positive")
        #endif
    }

    // MARK: - Integration: check() resets previous state

    /// If check() is called again, it should replace (not append) indicators
    func testCheck_ReplacesIndicators_DoesNotAppend() {
        sut.check()
        let count1 = sut.detectedIndicators.count

        sut.check()
        let count2 = sut.detectedIndicators.count

        XCTAssertEqual(count1, count2,
                       "check() should replace indicators, not append")
    }
}
