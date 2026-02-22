//
//  EdgeFunctionAnalyticsServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for EdgeFunctionAnalyticsService.
//  Tests singleton access, cache management, and basic service availability.
//  Network-dependent methods are not tested here.
//

import XCTest
@testable import PTPerformance

// MARK: - EdgeFunctionAnalyticsService Tests

@MainActor
final class EdgeFunctionAnalyticsServiceTests: XCTestCase {

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        let instance = EdgeFunctionAnalyticsService.shared
        XCTAssertNotNil(instance)
    }

    func testSharedInstanceReturnsSameObject() {
        let instance1 = EdgeFunctionAnalyticsService.shared
        let instance2 = EdgeFunctionAnalyticsService.shared
        XCTAssertTrue(instance1 === instance2, "shared should return the same instance")
    }

    // MARK: - Cache Tests

    func testClearCacheDoesNotThrow() {
        let service = EdgeFunctionAnalyticsService.shared
        service.clearCache()
        // Calling clearCache on an empty cache should not throw or crash
    }

    func testClearCacheCanBeCalledMultipleTimes() {
        let service = EdgeFunctionAnalyticsService.shared
        service.clearCache()
        service.clearCache()
        service.clearCache()
        // Multiple consecutive calls should be safe
    }

    // MARK: - ObservableObject Conformance

    func testServiceIsObservableObject() {
        let service = EdgeFunctionAnalyticsService.shared
        XCTAssertNotNil(service.objectWillChange, "Service should conform to ObservableObject")
    }
}
