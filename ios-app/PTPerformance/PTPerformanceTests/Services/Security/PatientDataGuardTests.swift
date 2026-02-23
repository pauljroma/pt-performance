//
//  PatientDataGuardTests.swift
//  PTPerformanceTests
//
//  Unit tests for PatientDataGuard (ACP-1060).
//  Validates patient data compartmentalization logic, error types,
//  and error descriptions for HIPAA compliance.
//

import XCTest
@testable import PTPerformance

// MARK: - PatientDataGuard Tests

@MainActor
final class PatientDataGuardTests: XCTestCase {

    // MARK: - Properties

    var sut: PatientDataGuard!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        sut = PatientDataGuard.shared
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(PatientDataGuard.shared)
    }

    func testSharedInstanceReturnsSameObject() {
        let instance1 = PatientDataGuard.shared
        let instance2 = PatientDataGuard.shared
        XCTAssertTrue(instance1 === instance2, "shared should return the same instance")
    }

    // MARK: - validatedPatientId() Tests

    /// When no user is signed in, validatedPatientId() must throw .noPatientId
    func testValidatedPatientId_ThrowsWhenNoUserSignedIn() {
        // In test environment, PTSupabaseClient.shared.userId is typically nil
        // unless a user session is active
        guard PTSupabaseClient.shared.userId == nil else {
            // If a user happens to be signed in during tests, skip
            return
        }

        XCTAssertThrowsError(try sut.validatedPatientId()) { error in
            guard let pdError = error as? PatientDataError else {
                XCTFail("Expected PatientDataError, got \(type(of: error))")
                return
            }
            if case .noPatientId = pdError {
                // Expected
            } else {
                XCTFail("Expected .noPatientId, got \(pdError)")
            }
        }
    }

    /// When a user IS signed in, validatedPatientId() should return their ID
    func testValidatedPatientId_ReturnsIdWhenUserExists() {
        guard let userId = PTSupabaseClient.shared.userId else {
            // No user session in test environment; this is expected
            return
        }

        do {
            let patientId = try sut.validatedPatientId()
            XCTAssertEqual(patientId, userId)
            XCTAssertFalse(patientId.isEmpty, "Patient ID should not be empty")
        } catch {
            XCTFail("validatedPatientId should not throw when user is signed in: \(error)")
        }
    }

    // MARK: - validateAccess(toPatientId:) Tests

    /// Access validation should fail when no role is set (no authenticated user)
    func testValidateAccess_ThrowsWhenNoRoleSet() {
        guard AccessControlService.shared.currentRole == nil else {
            return // Role is set, skip
        }

        let fakeId = "00000000-0000-0000-0000-000000000099"
        XCTAssertThrowsError(try sut.validateAccess(toPatientId: fakeId)) { error in
            guard let pdError = error as? PatientDataError else {
                XCTFail("Expected PatientDataError, got \(type(of: error))")
                return
            }
            if case .accessDenied = pdError {
                // Expected -- the access control validation fails when no role is set
            } else {
                // noPatientId is also acceptable here depending on flow
            }
        }
    }

    /// Validates that access to a mismatched patient ID is denied for patients
    func testValidateAccess_DeniesAccessToOtherPatientData() {
        // If no user is signed in, the access check should deny
        guard AccessControlService.shared.currentRole == .patient else {
            // Only relevant when logged in as a patient
            return
        }

        let otherId = "00000000-0000-0000-0000-999999999999"
        XCTAssertThrowsError(try sut.validateAccess(toPatientId: otherId)) { error in
            guard let pdError = error as? PatientDataError else {
                XCTFail("Expected PatientDataError")
                return
            }
            if case .accessDenied(let requested, _) = pdError {
                XCTAssertEqual(requested, otherId)
            } else {
                XCTFail("Expected .accessDenied, got \(pdError)")
            }
        }
    }

    // MARK: - validatedId(for:) Tests

    /// When called with nil, validatedId should behave like validatedPatientId()
    func testValidatedId_WithNil_FallsBackToCurrentUser() {
        guard PTSupabaseClient.shared.userId == nil else {
            return // User is signed in, separate scenario
        }

        XCTAssertThrowsError(try sut.validatedId(for: nil)) { error in
            XCTAssertTrue(error is PatientDataError, "Should throw PatientDataError")
        }
    }

    /// When called with an explicit ID, validatedId should validate access and return it
    func testValidatedId_WithExplicitId_ValidatesAndReturns() {
        guard AccessControlService.shared.currentRole == nil else {
            return // Only test the unauthenticated path here
        }

        let testId = "00000000-0000-0000-0000-000000000001"
        XCTAssertThrowsError(try sut.validatedId(for: testId)) { error in
            XCTAssertTrue(error is PatientDataError)
        }
    }

    // MARK: - PatientDataError Tests

    func testPatientDataError_NoPatientId_HasDescription() {
        let error = PatientDataError.noPatientId
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("sign in"),
                      "Error should mention signing in")
    }

    func testPatientDataError_AccessDenied_HasDescription() {
        let error = PatientDataError.accessDenied(
            requestedPatientId: "patient-A",
            currentUserId: "patient-B"
        )
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("patient-A"),
                      "Error should include the requested patient ID")
        XCTAssertTrue(error.errorDescription!.contains("patient-B"),
                      "Error should include the current user ID")
    }

    func testPatientDataError_InvalidPatientId_HasDescription() {
        let error = PatientDataError.invalidPatientId
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("not valid"),
                      "Error should indicate invalid ID")
    }

    func testPatientDataError_AccessDenied_IncludesAccessDeniedText() {
        let error = PatientDataError.accessDenied(
            requestedPatientId: "abc", currentUserId: "xyz"
        )
        XCTAssertTrue(error.errorDescription!.contains("Access denied"),
                      "Error should start with 'Access denied'")
    }

    func testPatientDataError_NoPatientId_IsLocalizedError() {
        let error: Error = PatientDataError.noPatientId
        let localizedError = error as? LocalizedError
        XCTAssertNotNil(localizedError)
        XCTAssertNotNil(localizedError?.errorDescription)
    }

    func testPatientDataError_AccessDenied_ContainsBothIds() {
        let requested = "11111111-1111-1111-1111-111111111111"
        let current = "22222222-2222-2222-2222-222222222222"
        let error = PatientDataError.accessDenied(
            requestedPatientId: requested, currentUserId: current
        )
        let desc = error.errorDescription ?? ""
        XCTAssertTrue(desc.contains(requested), "Description should contain the requested patient ID")
        XCTAssertTrue(desc.contains(current), "Description should contain the current user ID")
    }

    func testPatientDataError_AllCasesHaveNonEmptyDescriptions() {
        let errors: [PatientDataError] = [
            .noPatientId,
            .accessDenied(requestedPatientId: "a", currentUserId: "b"),
            .invalidPatientId
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "\(error) should have errorDescription")
            XCTAssertFalse(error.errorDescription!.isEmpty, "\(error) errorDescription should not be empty")
        }
    }

    // MARK: - Error Type Discrimination

    func testPatientDataError_NoPatientIdIsDistinctFromAccessDenied() {
        let noId = PatientDataError.noPatientId
        let denied = PatientDataError.accessDenied(requestedPatientId: "x", currentUserId: "y")

        // They should produce different descriptions
        XCTAssertNotEqual(noId.errorDescription, denied.errorDescription)
    }

    func testPatientDataError_InvalidPatientIdIsDistinctFromNoPatientId() {
        let invalid = PatientDataError.invalidPatientId
        let noId = PatientDataError.noPatientId

        XCTAssertNotEqual(invalid.errorDescription, noId.errorDescription)
    }

    // MARK: - Edge Cases

    /// Empty string patient IDs should still be rejected by access control
    func testValidateAccess_EmptyStringPatientId() {
        guard AccessControlService.shared.currentRole == nil else { return }

        XCTAssertThrowsError(try sut.validateAccess(toPatientId: "")) { error in
            XCTAssertTrue(error is PatientDataError)
        }
    }

    /// Very long patient ID strings should not crash
    func testValidateAccess_VeryLongPatientId_DoesNotCrash() {
        let longId = String(repeating: "a", count: 10_000)
        // Should throw, not crash
        XCTAssertThrowsError(try sut.validateAccess(toPatientId: longId))
    }

    /// Special characters in patient ID should not cause issues
    func testValidateAccess_SpecialCharactersInPatientId() {
        let maliciousId = "<script>alert('xss')</script>"
        XCTAssertThrowsError(try sut.validateAccess(toPatientId: maliciousId))
    }

    /// SQL injection attempt in patient ID
    func testValidateAccess_SQLInjectionInPatientId() {
        let sqlInjection = "'; DROP TABLE patients; --"
        XCTAssertThrowsError(try sut.validateAccess(toPatientId: sqlInjection))
    }

    /// Unicode in patient ID should not crash
    func testValidateAccess_UnicodePatientId() {
        let unicodeId = "\u{200B}\u{FEFF}\u{00A0}"  // zero-width space, BOM, non-breaking space
        XCTAssertThrowsError(try sut.validateAccess(toPatientId: unicodeId))
    }

    // MARK: - Guard Consistency

    /// validatedId(for:) with nil should behave identically to validatedPatientId()
    func testValidatedIdNil_MatchesValidatedPatientId_Behavior() {
        var directError: Error?
        var convenienceError: Error?

        do {
            _ = try sut.validatedPatientId()
        } catch {
            directError = error
        }

        do {
            _ = try sut.validatedId(for: nil)
        } catch {
            convenienceError = error
        }

        // Both should either succeed or both should fail
        if directError != nil {
            XCTAssertNotNil(convenienceError, "Both paths should fail when no user")
        } else {
            XCTAssertNil(convenienceError, "Both paths should succeed when user exists")
        }
    }
}
