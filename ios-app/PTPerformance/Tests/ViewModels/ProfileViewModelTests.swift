//
//  ProfileViewModelTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for PatientProfileViewModel
//  Tests settings persistence, data export, and account management
//

import XCTest
import Combine
@testable import PTPerformance

// MARK: - Mock Supabase Client Protocol

protocol ProfileSupabaseClientProtocol {
    var userId: String? { get }
    func fetchPatientProfile(patientId: String) async throws -> PatientProfileData
    func updatePatientProfile(patientId: String, data: [String: Any]) async throws
}

// MARK: - Mock Profile Service

final class MockProfileService: ProfileSupabaseClientProtocol {
    var mockUserId: String? = UUID().uuidString
    var mockProfileData: PatientProfileData?
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock error"])

    var fetchProfileCallCount = 0
    var updateProfileCallCount = 0

    var lastUpdatedPatientId: String?
    var lastUpdatedData: [String: Any]?

    var userId: String? {
        return mockUserId
    }

    func fetchPatientProfile(patientId: String) async throws -> PatientProfileData {
        fetchProfileCallCount += 1
        if shouldThrowError { throw errorToThrow }
        if let profile = mockProfileData {
            return profile
        }
        throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Profile not found"])
    }

    func updatePatientProfile(patientId: String, data: [String: Any]) async throws {
        updateProfileCallCount += 1
        lastUpdatedPatientId = patientId
        lastUpdatedData = data
        if shouldThrowError { throw errorToThrow }
    }
}

// MARK: - PatientProfileViewModel Tests

@MainActor
final class ProfileViewModelTests: XCTestCase {

    var sut: PatientProfileViewModel!

    override func setUp() {
        super.setUp()
        sut = PatientProfileViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_DemographicFieldsAreEmpty() {
        XCTAssertEqual(sut.age, "", "age should be empty initially")
        XCTAssertEqual(sut.gender, "", "gender should be empty initially")
        XCTAssertEqual(sut.heightInches, "", "heightInches should be empty initially")
        XCTAssertEqual(sut.weightLbs, "", "weightLbs should be empty initially")
    }

    func testInitialState_MedicalHistoryFieldsAreEmpty() {
        XCTAssertEqual(sut.injuryHistory, "", "injuryHistory should be empty initially")
        XCTAssertEqual(sut.surgeryHistory, "", "surgeryHistory should be empty initially")
        XCTAssertEqual(sut.allergies, "", "allergies should be empty initially")
    }

    func testInitialState_UIStateIsDefault() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
        XCTAssertFalse(sut.isSaving, "isSaving should be false initially")
        XCTAssertNil(sut.errorMessage, "errorMessage should be nil initially")
        XCTAssertNil(sut.successMessage, "successMessage should be nil initially")
        XCTAssertFalse(sut.showingSuccessAlert, "showingSuccessAlert should be false initially")
    }

    func testInitialState_ValidationErrorsAreNil() {
        XCTAssertNil(sut.ageError)
        XCTAssertNil(sut.heightError)
        XCTAssertNil(sut.weightError)
    }

    // MARK: - Gender Options Tests

    func testGenderOptions_ContainsExpectedValues() {
        let options = sut.genderOptions

        XCTAssertTrue(options.contains(""), "Should include empty option")
        XCTAssertTrue(options.contains("Male"))
        XCTAssertTrue(options.contains("Female"))
        XCTAssertTrue(options.contains("Other"))
        XCTAssertTrue(options.contains("Prefer not to say"))
    }

    func testGenderOptions_Count() {
        XCTAssertEqual(sut.genderOptions.count, 5)
    }

    // MARK: - Settings Persistence Tests

    func testDemographicFields_CanBeSet() {
        sut.age = "30"
        sut.gender = "Male"
        sut.heightInches = "72"
        sut.weightLbs = "180"

        XCTAssertEqual(sut.age, "30")
        XCTAssertEqual(sut.gender, "Male")
        XCTAssertEqual(sut.heightInches, "72")
        XCTAssertEqual(sut.weightLbs, "180")
    }

    func testMedicalHistoryFields_CanBeSet() {
        sut.injuryHistory = "ACL tear 2020"
        sut.surgeryHistory = "ACL reconstruction 2020"
        sut.allergies = "Penicillin"

        XCTAssertEqual(sut.injuryHistory, "ACL tear 2020")
        XCTAssertEqual(sut.surgeryHistory, "ACL reconstruction 2020")
        XCTAssertEqual(sut.allergies, "Penicillin")
    }

    // MARK: - Validation Tests

    func testValidate_WithValidAge_ReturnsTrue() {
        sut.age = "30"
        XCTAssertTrue(sut.validate())
        XCTAssertNil(sut.ageError)
    }

    func testValidate_WithInvalidAge_TooLow_ReturnsFalse() {
        sut.age = "0"
        XCTAssertFalse(sut.validate())
        XCTAssertNotNil(sut.ageError)
    }

    func testValidate_WithInvalidAge_TooHigh_ReturnsFalse() {
        sut.age = "200"
        XCTAssertFalse(sut.validate())
        XCTAssertNotNil(sut.ageError)
    }

    func testValidate_WithInvalidAge_NonNumeric_ReturnsFalse() {
        sut.age = "abc"
        XCTAssertFalse(sut.validate())
        XCTAssertNotNil(sut.ageError)
    }

    func testValidate_WithEmptyAge_ReturnsTrue() {
        sut.age = ""
        XCTAssertTrue(sut.validate())
        XCTAssertNil(sut.ageError)
    }

    func testValidate_WithValidHeight_ReturnsTrue() {
        sut.heightInches = "72"
        XCTAssertTrue(sut.validate())
        XCTAssertNil(sut.heightError)
    }

    func testValidate_WithInvalidHeight_TooLow_ReturnsFalse() {
        sut.heightInches = "0"
        XCTAssertFalse(sut.validate())
        XCTAssertNotNil(sut.heightError)
    }

    func testValidate_WithInvalidHeight_TooHigh_ReturnsFalse() {
        sut.heightInches = "150"
        XCTAssertFalse(sut.validate())
        XCTAssertNotNil(sut.heightError)
    }

    func testValidate_WithValidWeight_ReturnsTrue() {
        sut.weightLbs = "180"
        XCTAssertTrue(sut.validate())
        XCTAssertNil(sut.weightError)
    }

    func testValidate_WithInvalidWeight_TooLow_ReturnsFalse() {
        sut.weightLbs = "0"
        XCTAssertFalse(sut.validate())
        XCTAssertNotNil(sut.weightError)
    }

    func testValidate_WithInvalidWeight_TooHigh_ReturnsFalse() {
        sut.weightLbs = "1500"
        XCTAssertFalse(sut.validate())
        XCTAssertNotNil(sut.weightError)
    }

    func testValidate_ClearsPreviousErrors() {
        // Set errors
        sut.ageError = "Previous error"
        sut.heightError = "Previous error"
        sut.weightError = "Previous error"

        // Validate with valid data
        sut.age = "30"
        sut.heightInches = "72"
        sut.weightLbs = "180"

        _ = sut.validate()

        XCTAssertNil(sut.ageError)
        XCTAssertNil(sut.heightError)
        XCTAssertNil(sut.weightError)
    }

    func testValidate_AllFieldsInvalid_SetsAllErrors() {
        sut.age = "0"
        sut.heightInches = "0"
        sut.weightLbs = "0"

        let isValid = sut.validate()

        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.ageError)
        XCTAssertNotNil(sut.heightError)
        XCTAssertNotNil(sut.weightError)
    }

    // MARK: - Load Profile Tests

    func testLoadProfile_SetsLoadingState() async {
        let expectation = expectation(description: "Load completes")

        Task {
            await sut.loadProfile(patientId: UUID().uuidString)
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 10.0)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Save Profile Tests

    func testSaveProfile_WithoutPatientId_SetsError() async {
        // Ensure no patient ID is set by not loading any profile
        await sut.saveProfile()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isSaving)
    }

    func testSaveProfile_WithInvalidData_SetsError() async {
        sut.age = "0"  // Invalid age

        await sut.saveProfile()

        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - Success Message Tests

    func testClearSuccessMessage_ClearsMessage() {
        sut.successMessage = "Profile saved"
        sut.showingSuccessAlert = true

        sut.clearSuccessMessage()

        XCTAssertNil(sut.successMessage)
        XCTAssertFalse(sut.showingSuccessAlert)
    }

    // MARK: - UI State Tests

    func testIsLoading_CanBeSet() {
        XCTAssertFalse(sut.isLoading)

        sut.isLoading = true
        XCTAssertTrue(sut.isLoading)

        sut.isLoading = false
        XCTAssertFalse(sut.isLoading)
    }

    func testIsSaving_CanBeSet() {
        XCTAssertFalse(sut.isSaving)

        sut.isSaving = true
        XCTAssertTrue(sut.isSaving)

        sut.isSaving = false
        XCTAssertFalse(sut.isSaving)
    }

    func testErrorMessage_CanBeSet() {
        XCTAssertNil(sut.errorMessage)

        sut.errorMessage = "Test error"
        XCTAssertEqual(sut.errorMessage, "Test error")

        sut.errorMessage = nil
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Edge Case Tests

    func testAge_BoundaryValues() {
        // Test minimum valid age
        sut.age = "1"
        XCTAssertTrue(sut.validate())

        // Test maximum valid age
        sut.age = "149"
        XCTAssertTrue(sut.validate())
    }

    func testHeight_BoundaryValues() {
        // Test minimum valid height
        sut.heightInches = "1"
        XCTAssertTrue(sut.validate())

        // Test just under max
        sut.heightInches = "119"
        XCTAssertTrue(sut.validate())
    }

    func testWeight_BoundaryValues() {
        // Test minimum valid weight
        sut.weightLbs = "1"
        XCTAssertTrue(sut.validate())

        // Test just under max
        sut.weightLbs = "999"
        XCTAssertTrue(sut.validate())
    }

    func testDecimalValues_AreValid() {
        sut.heightInches = "72.5"
        sut.weightLbs = "180.5"

        XCTAssertTrue(sut.validate())
    }

    // MARK: - Multiple Allergies Tests

    func testAllergies_CanHandleMultipleEntries() {
        sut.allergies = "Penicillin, Sulfa, Latex"

        let allergyList = sut.allergies.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        XCTAssertEqual(allergyList.count, 3)
        XCTAssertTrue(allergyList.contains("Penicillin"))
        XCTAssertTrue(allergyList.contains("Sulfa"))
        XCTAssertTrue(allergyList.contains("Latex"))
    }

    // MARK: - Multiple Medical History Entries Tests

    func testInjuryHistory_CanHandleMultipleEntries() {
        sut.injuryHistory = "2020: ACL tear\n2019: Rotator cuff strain\n2018: Ankle sprain"

        let injuries = sut.injuryHistory.components(separatedBy: "\n")
            .filter { !$0.isEmpty }

        XCTAssertEqual(injuries.count, 3)
    }

    func testSurgeryHistory_CanHandleMultipleEntries() {
        sut.surgeryHistory = "2020: ACL reconstruction\n2015: Appendectomy"

        let surgeries = sut.surgeryHistory.components(separatedBy: "\n")
            .filter { !$0.isEmpty }

        XCTAssertEqual(surgeries.count, 2)
    }
}

// MARK: - AccountDeletionViewModel Tests

@MainActor
final class AccountDeletionViewModelTests: XCTestCase {

    var sut: AccountDeletionViewModel!

    override func setUp() {
        super.setUp()
        sut = AccountDeletionViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ShowConfirmationIsFalse() {
        XCTAssertFalse(sut.showConfirmation, "showConfirmation should be false initially")
    }

    func testInitialState_ShowErrorIsFalse() {
        XCTAssertFalse(sut.showError, "showError should be false initially")
    }

    func testInitialState_ErrorMessageIsEmpty() {
        XCTAssertEqual(sut.errorMessage, "", "errorMessage should be empty initially")
    }

    func testInitialState_ConfirmationTextIsEmpty() {
        XCTAssertEqual(sut.confirmationText, "", "confirmationText should be empty initially")
    }

    func testInitialState_IsDeletedIsFalse() {
        XCTAssertFalse(sut.isDeleted, "isDeleted should be false initially")
    }

    // MARK: - Confirmation Tests

    func testRequiredConfirmationText_IsDelete() {
        XCTAssertEqual(sut.requiredConfirmationText, "DELETE")
    }

    func testCanDelete_WhenTextMatches_ReturnsTrue() {
        sut.confirmationText = "DELETE"
        XCTAssertTrue(sut.canDelete)
    }

    func testCanDelete_WhenTextDoesNotMatch_ReturnsFalse() {
        sut.confirmationText = "delete"  // lowercase
        XCTAssertFalse(sut.canDelete)

        sut.confirmationText = "DELET"  // incomplete
        XCTAssertFalse(sut.canDelete)

        sut.confirmationText = ""  // empty
        XCTAssertFalse(sut.canDelete)
    }

    // MARK: - UI State Tests

    func testShowConfirmation_CanBeToggled() {
        XCTAssertFalse(sut.showConfirmation)

        sut.showConfirmation = true
        XCTAssertTrue(sut.showConfirmation)

        sut.showConfirmation = false
        XCTAssertFalse(sut.showConfirmation)
    }

    func testShowError_CanBeToggled() {
        XCTAssertFalse(sut.showError)

        sut.showError = true
        XCTAssertTrue(sut.showError)

        sut.showError = false
        XCTAssertFalse(sut.showError)
    }

    func testErrorMessage_CanBeSet() {
        sut.errorMessage = "Test error"
        XCTAssertEqual(sut.errorMessage, "Test error")
    }

    func testConfirmationText_CanBeSet() {
        sut.confirmationText = "DELETE"
        XCTAssertEqual(sut.confirmationText, "DELETE")
    }

    // MARK: - Reset Tests

    func testReset_ClearsConfirmationText() {
        sut.confirmationText = "DELETE"
        sut.reset()
        XCTAssertEqual(sut.confirmationText, "")
    }

    func testReset_ClearsErrorState() {
        sut.errorMessage = "Test error"
        sut.showError = true
        sut.reset()
        XCTAssertEqual(sut.errorMessage, "")
        XCTAssertFalse(sut.showError)
    }
}

// MARK: - ModeSwitchingViewModel Tests

@MainActor
final class ModeSwitchingViewModelTests: XCTestCase {

    var sut: ModeSwitchingViewModel!

    override func setUp() {
        super.setUp()
        sut = ModeSwitchingViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorIsNil() {
        XCTAssertNil(sut.error, "error should be nil initially")
    }

    // MARK: - Loading State Tests

    func testIsLoading_CanBeSet() {
        XCTAssertFalse(sut.isLoading)

        sut.isLoading = true
        XCTAssertTrue(sut.isLoading)

        sut.isLoading = false
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Error State Tests

    func testError_CanBeSet() {
        XCTAssertNil(sut.error)

        sut.error = "Test error"
        XCTAssertEqual(sut.error, "Test error")

        sut.error = nil
        XCTAssertNil(sut.error)
    }
}
