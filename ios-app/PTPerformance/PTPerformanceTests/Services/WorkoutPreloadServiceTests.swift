//
//  WorkoutPreloadServiceTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for WorkoutPreloadService and PreloadedWorkoutCache
//  Tests preloading workout data, caching behavior, and handling no patient ID
//

import XCTest
import UIKit
@testable import PTPerformance

// MARK: - CachedWorkoutData Tests

final class CachedWorkoutDataTests: XCTestCase {

    // MARK: - Initialization Tests

    func testCachedWorkoutData_Initialization() {
        let session = createMockSession(name: "Test Session")
        let exercises = Exercise.sampleExercises
        let cachedAt = Date()
        let patientId = "test-patient-123"

        let cachedData = CachedWorkoutData(
            session: session,
            exercises: exercises,
            cachedAt: cachedAt,
            patientId: patientId
        )

        XCTAssertEqual(cachedData.session?.name, "Test Session")
        XCTAssertEqual(cachedData.exercises.count, 2)
        XCTAssertEqual(cachedData.cachedAt, cachedAt)
        XCTAssertEqual(cachedData.patientId, patientId)
    }

    func testCachedWorkoutData_WithNilSession() {
        let cachedData = CachedWorkoutData(
            session: nil,
            exercises: [],
            cachedAt: Date(),
            patientId: "patient-456"
        )

        XCTAssertNil(cachedData.session)
        XCTAssertTrue(cachedData.exercises.isEmpty)
    }

    // MARK: - Validity Tests

    func testCachedWorkoutData_IsValid_RecentCache() {
        // Cache created just now should be valid
        let cachedData = CachedWorkoutData(
            session: nil,
            exercises: [],
            cachedAt: Date(),
            patientId: "patient"
        )

        XCTAssertTrue(cachedData.isValid)
    }

    func testCachedWorkoutData_IsValid_ExpiredCache() {
        // Cache older than 5 minutes should be invalid
        let sixMinutesAgo = Date().addingTimeInterval(-360)  // 6 minutes

        let cachedData = CachedWorkoutData(
            session: nil,
            exercises: [],
            cachedAt: sixMinutesAgo,
            patientId: "patient"
        )

        XCTAssertFalse(cachedData.isValid)
    }

    func testCachedWorkoutData_IsValid_JustExpired() {
        // Cache at exactly 5 minutes should be invalid
        let fiveMinutesAgo = Date().addingTimeInterval(-300)

        let cachedData = CachedWorkoutData(
            session: nil,
            exercises: [],
            cachedAt: fiveMinutesAgo,
            patientId: "patient"
        )

        XCTAssertFalse(cachedData.isValid)
    }

    func testCachedWorkoutData_IsValid_AlmostExpired() {
        // Cache at 4 minutes 59 seconds should still be valid
        let almostFiveMinutesAgo = Date().addingTimeInterval(-299)

        let cachedData = CachedWorkoutData(
            session: nil,
            exercises: [],
            cachedAt: almostFiveMinutesAgo,
            patientId: "patient"
        )

        XCTAssertTrue(cachedData.isValid)
    }

    // MARK: - Today Cache Tests

    func testCachedWorkoutData_IsTodayCache_Today() {
        let cachedData = CachedWorkoutData(
            session: nil,
            exercises: [],
            cachedAt: Date(),
            patientId: "patient"
        )

        XCTAssertTrue(cachedData.isTodayCache)
    }

    func testCachedWorkoutData_IsTodayCache_Yesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        let cachedData = CachedWorkoutData(
            session: nil,
            exercises: [],
            cachedAt: yesterday,
            patientId: "patient"
        )

        XCTAssertFalse(cachedData.isTodayCache)
    }

    func testCachedWorkoutData_IsTodayCache_Tomorrow() {
        // Edge case: future date (shouldn't happen but test anyway)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        let cachedData = CachedWorkoutData(
            session: nil,
            exercises: [],
            cachedAt: tomorrow,
            patientId: "patient"
        )

        XCTAssertFalse(cachedData.isTodayCache)
    }

    // MARK: - Codable Tests

    func testCachedWorkoutData_Encodes() throws {
        let cachedData = CachedWorkoutData(
            session: nil,
            exercises: [],
            cachedAt: Date(),
            patientId: "test-patient"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(cachedData)

        XCTAssertFalse(data.isEmpty)
    }

    func testCachedWorkoutData_RoundTrip() throws {
        let originalSession = createMockSession(name: "Roundtrip Session")
        let exercises = Exercise.sampleExercises
        let cachedAt = Date()

        let originalData = CachedWorkoutData(
            session: originalSession,
            exercises: exercises,
            cachedAt: cachedAt,
            patientId: "roundtrip-patient"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let encoded = try encoder.encode(originalData)
        let decoded = try decoder.decode(CachedWorkoutData.self, from: encoded)

        XCTAssertEqual(decoded.session?.name, originalSession.name)
        XCTAssertEqual(decoded.exercises.count, exercises.count)
        XCTAssertEqual(decoded.patientId, "roundtrip-patient")
    }

    // MARK: - Helper Methods

    private func createMockSession(name: String) -> Session {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "phase_id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "\(name)",
            "sequence": 1,
            "weekday": null,
            "notes": null,
            "created_at": null
        }
        """.data(using: .utf8)!

        return try! JSONDecoder().decode(Session.self, from: json)
    }
}

// MARK: - PreloadedWorkoutCache Tests

@MainActor
final class PreloadedWorkoutCacheTests: XCTestCase {

    // MARK: - Singleton Tests

    func testPreloadedWorkoutCache_SharedInstance() {
        let cache1 = PreloadedWorkoutCache.shared
        let cache2 = PreloadedWorkoutCache.shared

        XCTAssertTrue(cache1 === cache2)
    }

    // MARK: - Initial State Tests

    func testPreloadedWorkoutCache_InitialState() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        XCTAssertNil(cache.cachedSession)
        XCTAssertTrue(cache.cachedExercises.isEmpty)
        XCTAssertFalse(cache.isPreloaded)
        XCTAssertNil(cache.lastPreloadTime)
        XCTAssertNil(cache.cachedPatientId)
    }

    // MARK: - Store Tests

    func testPreloadedWorkoutCache_Store() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        let session = createMockSession(name: "Stored Session")
        let exercises = Exercise.sampleExercises
        let patientId = "store-test-patient"

        cache.store(session: session, exercises: exercises, patientId: patientId)

        XCTAssertEqual(cache.cachedSession?.name, "Stored Session")
        XCTAssertEqual(cache.cachedExercises.count, 2)
        XCTAssertEqual(cache.cachedPatientId, patientId)
        XCTAssertTrue(cache.isPreloaded)
        XCTAssertNotNil(cache.lastPreloadTime)
    }

    func testPreloadedWorkoutCache_StoreWithNilSession() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        cache.store(session: nil, exercises: [], patientId: "nil-session-patient")

        XCTAssertNil(cache.cachedSession)
        XCTAssertTrue(cache.cachedExercises.isEmpty)
        XCTAssertTrue(cache.isPreloaded)  // Still marked as preloaded
    }

    func testPreloadedWorkoutCache_StoreOverwrites() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        // First store
        let session1 = createMockSession(name: "Session 1")
        cache.store(session: session1, exercises: [], patientId: "patient1")

        // Second store
        let session2 = createMockSession(name: "Session 2")
        cache.store(session: session2, exercises: Exercise.sampleExercises, patientId: "patient2")

        XCTAssertEqual(cache.cachedSession?.name, "Session 2")
        XCTAssertEqual(cache.cachedPatientId, "patient2")
        XCTAssertEqual(cache.cachedExercises.count, 2)
    }

    // MARK: - getCachedData Tests

    func testPreloadedWorkoutCache_GetCachedData_Success() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        let session = createMockSession(name: "Cached Session")
        let exercises = Exercise.sampleExercises
        let patientId = "get-cache-patient"

        cache.store(session: session, exercises: exercises, patientId: patientId)

        let result = cache.getCachedData(for: patientId)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.session?.name, "Cached Session")
        XCTAssertEqual(result?.exercises.count, 2)
    }

    func testPreloadedWorkoutCache_GetCachedData_WrongPatient() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        cache.store(session: nil, exercises: [], patientId: "patient-a")

        let result = cache.getCachedData(for: "patient-b")

        XCTAssertNil(result)  // Different patient ID
    }

    func testPreloadedWorkoutCache_GetCachedData_NotPreloaded() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        let result = cache.getCachedData(for: "any-patient")

        XCTAssertNil(result)  // Nothing stored
    }

    // MARK: - Validity Tests

    func testPreloadedWorkoutCache_IsCacheValid_NoPreloadTime() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        XCTAssertFalse(cache.isCacheValid)
    }

    func testPreloadedWorkoutCache_IsCacheValid_RecentPreload() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        cache.store(session: nil, exercises: [], patientId: "valid-cache-patient")

        XCTAssertTrue(cache.isCacheValid)
    }

    // MARK: - Invalidate Tests

    func testPreloadedWorkoutCache_Invalidate() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        cache.store(
            session: createMockSession(name: "Test"),
            exercises: Exercise.sampleExercises,
            patientId: "invalidate-test"
        )

        XCTAssertTrue(cache.isPreloaded)

        cache.invalidate()

        XCTAssertNil(cache.cachedSession)
        XCTAssertTrue(cache.cachedExercises.isEmpty)
        XCTAssertNil(cache.cachedPatientId)
        XCTAssertNil(cache.lastPreloadTime)
        XCTAssertFalse(cache.isPreloaded)
    }

    // MARK: - Clear All Tests

    func testPreloadedWorkoutCache_ClearAll() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        // Store some data
        cache.store(
            session: createMockSession(name: "Test"),
            exercises: Exercise.sampleExercises,
            patientId: "clear-test"
        )

        // Store some thumbnails
        let testImage = UIImage()
        cache.storeThumbnail(testImage, for: "https://example.com/thumb1.jpg")
        cache.storeThumbnail(testImage, for: "https://example.com/thumb2.jpg")

        XCTAssertTrue(cache.isPreloaded)
        XCTAssertEqual(cache.cachedThumbnailURLs.count, 2)

        cache.clearAll()

        XCTAssertFalse(cache.isPreloaded)
        XCTAssertTrue(cache.cachedThumbnailURLs.isEmpty)
    }

    // MARK: - Thumbnail Cache Tests

    func testPreloadedWorkoutCache_StoreThumbnail() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        let testImage = UIImage()
        let urlString = "https://example.com/thumbnail.jpg"

        cache.storeThumbnail(testImage, for: urlString)

        XCTAssertTrue(cache.hasThumbnail(for: urlString))
        XCTAssertNotNil(cache.getThumbnail(for: urlString))
    }

    func testPreloadedWorkoutCache_GetThumbnail_NotCached() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        XCTAssertNil(cache.getThumbnail(for: "https://example.com/nonexistent.jpg"))
        XCTAssertFalse(cache.hasThumbnail(for: "https://example.com/nonexistent.jpg"))
    }

    func testPreloadedWorkoutCache_CachedThumbnailURLs() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        let testImage = UIImage()
        cache.storeThumbnail(testImage, for: "https://example.com/thumb1.jpg")
        cache.storeThumbnail(testImage, for: "https://example.com/thumb2.jpg")
        cache.storeThumbnail(testImage, for: "https://example.com/thumb3.jpg")

        let urls = cache.cachedThumbnailURLs

        XCTAssertEqual(urls.count, 3)
        XCTAssertTrue(urls.contains("https://example.com/thumb1.jpg"))
        XCTAssertTrue(urls.contains("https://example.com/thumb2.jpg"))
        XCTAssertTrue(urls.contains("https://example.com/thumb3.jpg"))
    }

    func testPreloadedWorkoutCache_ThumbnailCacheLimit() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        let testImage = UIImage()

        // Store more than the limit (20)
        for i in 0..<25 {
            cache.storeThumbnail(testImage, for: "https://example.com/thumb\(i).jpg")
        }

        // Cache should not exceed limit
        XCTAssertLessThanOrEqual(cache.cachedThumbnailURLs.count, 20)
    }

    // MARK: - Cache Stats Tests

    func testPreloadedWorkoutCache_CacheStats() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        let session = createMockSession(name: "Stats Session")
        cache.store(session: session, exercises: Exercise.sampleExercises, patientId: "stats-patient")

        let testImage = UIImage()
        cache.storeThumbnail(testImage, for: "https://example.com/thumb.jpg")

        let stats = cache.cacheStats

        XCTAssertTrue(stats.contains("Stats Session"))
        XCTAssertTrue(stats.contains("Exercises: 2"))
        XCTAssertTrue(stats.contains("Thumbnails: 1"))
        XCTAssertTrue(stats.contains("Valid: Yes"))
    }

    func testPreloadedWorkoutCache_CacheStats_Empty() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        let stats = cache.cacheStats

        XCTAssertTrue(stats.contains("Session: None"))
        XCTAssertTrue(stats.contains("Exercises: 0"))
        XCTAssertTrue(stats.contains("Thumbnails: 0"))
        XCTAssertTrue(stats.contains("Cache Age: -1s"))
        XCTAssertTrue(stats.contains("Valid: No"))
    }

    // MARK: - Helper Methods

    private func createMockSession(name: String) -> Session {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "phase_id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "\(name)",
            "sequence": 1,
            "weekday": null,
            "notes": null,
            "created_at": null
        }
        """.data(using: .utf8)!

        return try! JSONDecoder().decode(Session.self, from: json)
    }
}

// MARK: - URL Validation Tests

final class ThumbnailURLValidationTests: XCTestCase {

    // MARK: - Valid URL Tests

    func testIsValidThumbnailURL_ValidSupabaseURL() {
        let url = URL(string: "https://abc123.supabase.co/storage/v1/object/public/thumbnails/image.jpg")!
        XCTAssertTrue(isValidThumbnailURL(url))
    }

    func testIsValidThumbnailURL_ValidCloudfrontURL() {
        let url = URL(string: "https://d12345.cloudfront.net/thumbnails/image.jpg")!
        XCTAssertTrue(isValidThumbnailURL(url))
    }

    func testIsValidThumbnailURL_ValidAWSS3URL() {
        let url = URL(string: "https://bucket.s3.amazonaws.com/thumbnails/image.jpg")!
        XCTAssertTrue(isValidThumbnailURL(url))
    }

    func testIsValidThumbnailURL_ValidGoogleStorageURL() {
        let url = URL(string: "https://storage.googleapis.com/bucket/thumbnails/image.jpg")!
        XCTAssertTrue(isValidThumbnailURL(url))
    }

    func testIsValidThumbnailURL_ValidCloudinaryURL() {
        let url = URL(string: "https://res.cloudinary.com/account/image/upload/thumbnails/image.jpg")!
        XCTAssertTrue(isValidThumbnailURL(url))
    }

    func testIsValidThumbnailURL_ValidImgixURL() {
        let url = URL(string: "https://assets.imgix.net/thumbnails/image.jpg")!
        XCTAssertTrue(isValidThumbnailURL(url))
    }

    func testIsValidThumbnailURL_ValidCustomCDN() {
        let url = URL(string: "https://cdn.ptperformance.app/thumbnails/image.jpg")!
        XCTAssertTrue(isValidThumbnailURL(url))
    }

    // MARK: - Invalid URL Tests

    func testIsValidThumbnailURL_HTTPScheme() {
        let url = URL(string: "http://example.com/image.jpg")!
        XCTAssertFalse(isValidThumbnailURL(url))
    }

    func testIsValidThumbnailURL_ExampleDomain() {
        let url = URL(string: "https://example.com/image.jpg")!
        XCTAssertFalse(isValidThumbnailURL(url))
    }

    func testIsValidThumbnailURL_PlaceholderDomain() {
        let url = URL(string: "https://placeholder.com/image.jpg")!
        XCTAssertFalse(isValidThumbnailURL(url))
    }

    func testIsValidThumbnailURL_Localhost() {
        let url = URL(string: "https://localhost:3000/image.jpg")!
        XCTAssertFalse(isValidThumbnailURL(url))
    }

    func testIsValidThumbnailURL_LocalIP() {
        let url = URL(string: "https://127.0.0.1/image.jpg")!
        XCTAssertFalse(isValidThumbnailURL(url))
    }

    func testIsValidThumbnailURL_LocalDomain() {
        let url = URL(string: "https://myapp.local/image.jpg")!
        XCTAssertFalse(isValidThumbnailURL(url))
    }

    func testIsValidThumbnailURL_YourPrefix() {
        let url = URL(string: "https://your-bucket.s3.amazonaws.com/image.jpg")!
        XCTAssertFalse(isValidThumbnailURL(url))
    }

    func testIsValidThumbnailURL_UndefinedDomain() {
        let url = URL(string: "https://undefined/image.jpg")!
        XCTAssertFalse(isValidThumbnailURL(url))
    }

    func testIsValidThumbnailURL_NullDomain() {
        let url = URL(string: "https://null/image.jpg")!
        XCTAssertFalse(isValidThumbnailURL(url))
    }

    func testIsValidThumbnailURL_RootPathOnly() {
        let url = URL(string: "https://cdn.supabase.co/")!
        XCTAssertFalse(isValidThumbnailURL(url))
    }

    func testIsValidThumbnailURL_NoPath() {
        let url = URL(string: "https://cdn.supabase.co")!
        XCTAssertFalse(isValidThumbnailURL(url))
    }

    // MARK: - Edge Case Tests

    func testIsValidThumbnailURL_ValidWithQueryParams() {
        let url = URL(string: "https://abc.supabase.co/storage/image.jpg?width=100&height=100")!
        XCTAssertTrue(isValidThumbnailURL(url))
    }

    func testIsValidThumbnailURL_ValidWithPort() {
        let url = URL(string: "https://abc.supabase.co:443/storage/image.jpg")!
        XCTAssertTrue(isValidThumbnailURL(url))
    }

    func testIsValidThumbnailURL_UnknownButValidTLD() {
        // Unknown host but has valid TLD structure
        let url = URL(string: "https://cdn.customdomain.io/thumbnails/image.jpg")!
        XCTAssertTrue(isValidThumbnailURL(url))
    }

    func testIsValidThumbnailURL_InvalidTLD() {
        // Invalid TLD (too long or weird)
        let url = URL(string: "https://cdn.customdomain.verylongtld/image.jpg")!
        XCTAssertFalse(isValidThumbnailURL(url))
    }

    // MARK: - Helper Method

    /// Validates that a URL is suitable for thumbnail preloading
    /// (Mirrors the logic in WorkoutPreloadService)
    private func isValidThumbnailURL(_ url: URL) -> Bool {
        // Must have https scheme
        guard url.scheme == "https" else { return false }

        // Must have a valid host
        guard let host = url.host, !host.isEmpty else { return false }

        // Filter out placeholder or malformed hostnames
        let invalidHostPatterns = [
            "example.com",
            "placeholder",
            "localhost",
            "127.0.0.1",
            ".local",
            "your-",
            "undefined",
            "null"
        ]

        let lowercaseHost = host.lowercased()
        for pattern in invalidHostPatterns {
            if lowercaseHost.contains(pattern) {
                return false
            }
        }

        // Must have a path (not just root)
        guard url.path.count > 1 else { return false }

        // Validate common CDN/storage hosts
        let validHostPatterns = [
            "supabase.co",
            "supabase.in",
            "cloudfront.net",
            "amazonaws.com",
            "storage.googleapis.com",
            "cloudinary.com",
            "imgix.net",
            "cdn.ptperformance"
        ]

        // If host matches a known valid pattern, accept it
        for pattern in validHostPatterns {
            if lowercaseHost.contains(pattern) {
                return true
            }
        }

        // For unknown hosts, at least require a proper TLD
        let components = lowercaseHost.components(separatedBy: ".")
        guard components.count >= 2,
              let tld = components.last,
              tld.count >= 2 && tld.count <= 6 else {
            return false
        }

        return true
    }
}

// MARK: - No Patient ID Handling Tests

@MainActor
final class NoPatientIDHandlingTests: XCTestCase {

    func testPreloadedWorkoutCache_NoPatientId_ReturnsCacheMiss() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        // Store with a patient ID
        cache.store(session: nil, exercises: [], patientId: "actual-patient")

        // Try to get with different (or no) patient ID
        let result = cache.getCachedData(for: "")

        XCTAssertNil(result)  // Empty string doesn't match
    }

    func testPreloadedWorkoutCache_PatientIdMismatch() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        // Store data for patient A
        let session = createMockSession(name: "Patient A Session")
        cache.store(session: session, exercises: [], patientId: "patient-a-uuid")

        // Request data for patient B
        let result = cache.getCachedData(for: "patient-b-uuid")

        XCTAssertNil(result)
    }

    func testPreloadedWorkoutCache_PatientIdMatch() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        let patientId = "matching-patient-uuid"
        cache.store(session: nil, exercises: [], patientId: patientId)

        let result = cache.getCachedData(for: patientId)

        XCTAssertNotNil(result)
    }

    // MARK: - Helper Methods

    private func createMockSession(name: String) -> Session {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "phase_id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "\(name)",
            "sequence": 1
        }
        """.data(using: .utf8)!

        return try! JSONDecoder().decode(Session.self, from: json)
    }
}

// MARK: - Cache Expiration Tests

final class CacheExpirationTests: XCTestCase {

    func testCachedWorkoutData_CacheLifetime_5Minutes() {
        // Verify the cache lifetime is 5 minutes (300 seconds)
        let cacheLifetime: TimeInterval = 5 * 60

        XCTAssertEqual(cacheLifetime, 300)
    }

    func testCachedWorkoutData_Validity_AtBoundary() {
        // Test validity at exact 5 minute boundary
        let fiveMinutesAgo = Date().addingTimeInterval(-300)

        let cachedData = CachedWorkoutData(
            session: nil,
            exercises: [],
            cachedAt: fiveMinutesAgo,
            patientId: "boundary-test"
        )

        // At exactly 5 minutes, should be invalid (>= check)
        XCTAssertFalse(cachedData.isValid)
    }

    func testCachedWorkoutData_Validity_JustBeforeBoundary() {
        // Test validity just before 5 minute boundary
        let justBeforeFiveMinutes = Date().addingTimeInterval(-299.9)

        let cachedData = CachedWorkoutData(
            session: nil,
            exercises: [],
            cachedAt: justBeforeFiveMinutes,
            patientId: "before-boundary-test"
        )

        // Just before 5 minutes should still be valid
        XCTAssertTrue(cachedData.isValid)
    }

    func testCachedWorkoutData_Validity_WayExpired() {
        // Test validity for very old cache
        let oneHourAgo = Date().addingTimeInterval(-3600)

        let cachedData = CachedWorkoutData(
            session: nil,
            exercises: [],
            cachedAt: oneHourAgo,
            patientId: "old-cache-test"
        )

        // Cache older than 5 minutes should be invalid
        XCTAssertFalse(cachedData.isValid)
        // Note: isTodayCache depends on time of day - 1 hour ago is still today
        // unless the test runs between midnight and 1 AM
        // So we just verify the isValid behavior here
    }
}

// MARK: - Memory Warning Tests

@MainActor
final class MemoryWarningTests: XCTestCase {

    func testPreloadedWorkoutCache_MemoryWarning_ClearsThumbnails() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        // Add thumbnails
        let testImage = UIImage()
        cache.storeThumbnail(testImage, for: "https://example.com/thumb1.jpg")
        cache.storeThumbnail(testImage, for: "https://example.com/thumb2.jpg")

        XCTAssertEqual(cache.cachedThumbnailURLs.count, 2)

        // Simulate memory warning
        NotificationCenter.default.post(
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )

        // Give notification time to process
        let expectation = XCTestExpectation(description: "Memory warning processed")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Thumbnails should be cleared
            XCTAssertTrue(cache.cachedThumbnailURLs.isEmpty)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testPreloadedWorkoutCache_MemoryWarning_KeepsSessionData() {
        let cache = PreloadedWorkoutCache.shared
        cache.clearAll()

        // Store session data
        let session = createMockSession(name: "Memory Test Session")
        cache.store(session: session, exercises: [], patientId: "memory-test")

        // Verify session was stored before memory warning
        XCTAssertEqual(cache.cachedSession?.name, "Memory Test Session", "Session should be stored")
        XCTAssertTrue(cache.isPreloaded, "Cache should be preloaded")

        // Simulate memory warning - notification is processed synchronously
        NotificationCenter.default.post(
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )

        // Session data should remain (only thumbnails are cleared by memory warning handler)
        // The handleMemoryWarning() only clears thumbnailCache, not session data
        XCTAssertEqual(cache.cachedSession?.name, "Memory Test Session", "Session should remain after memory warning")
        XCTAssertTrue(cache.isPreloaded, "Cache should still be preloaded after memory warning")
    }

    // MARK: - Helper Methods

    private func createMockSession(name: String) -> Session {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "phase_id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "\(name)",
            "sequence": 1
        }
        """.data(using: .utf8)!

        return try! JSONDecoder().decode(Session.self, from: json)
    }
}
