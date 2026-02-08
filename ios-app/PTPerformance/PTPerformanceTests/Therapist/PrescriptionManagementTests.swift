//
//  PrescriptionManagementTests.swift
//  PTPerformanceTests
//
//  Comprehensive tests for prescription management functionality
//  Tests creating prescriptions, status updates, compliance tracking, and overdue handling
//

import XCTest
@testable import PTPerformance

// MARK: - TherapistPrescriptionDashboardViewModel Tests

@MainActor
final class TherapistPrescriptionDashboardViewModelTests: XCTestCase {

    var sut: TherapistPrescriptionDashboardViewModel!

    override func setUp() async throws {
        try await super.setUp()
        sut = TherapistPrescriptionDashboardViewModel()
    }

    override func tearDown() async throws {
        sut.stopAutoRefresh()
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_PrescriptionsIsEmpty() {
        XCTAssertTrue(sut.prescriptions.isEmpty)
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func testInitialState_ErrorMessageIsNil() {
        XCTAssertNil(sut.errorMessage)
    }

    func testInitialState_SearchTextIsEmpty() {
        XCTAssertTrue(sut.searchText.isEmpty)
    }

    func testInitialState_SelectedStatusFilterIsAll() {
        XCTAssertEqual(sut.selectedStatusFilter, .all)
    }

    func testInitialState_SelectedDateRangeIsAll() {
        XCTAssertEqual(sut.selectedDateRange, .all)
    }

    func testInitialState_SelectedPatientIdIsNil() {
        XCTAssertNil(sut.selectedPatientId)
    }

    func testInitialState_PatientsIsEmpty() {
        XCTAssertTrue(sut.patients.isEmpty)
    }

    func testInitialState_LastRefreshDateIsNil() {
        XCTAssertNil(sut.lastRefreshDate)
    }

    // MARK: - StatusFilter Enum Tests

    func testStatusFilter_AllCases() {
        let allCases = TherapistPrescriptionDashboardViewModel.StatusFilter.allCases
        XCTAssertEqual(allCases.count, 7)
    }

    func testStatusFilter_RawValues() {
        XCTAssertEqual(TherapistPrescriptionDashboardViewModel.StatusFilter.all.rawValue, "All")
        XCTAssertEqual(TherapistPrescriptionDashboardViewModel.StatusFilter.pending.rawValue, "Pending")
        XCTAssertEqual(TherapistPrescriptionDashboardViewModel.StatusFilter.viewed.rawValue, "Viewed")
        XCTAssertEqual(TherapistPrescriptionDashboardViewModel.StatusFilter.started.rawValue, "Started")
        XCTAssertEqual(TherapistPrescriptionDashboardViewModel.StatusFilter.completed.rawValue, "Completed")
        XCTAssertEqual(TherapistPrescriptionDashboardViewModel.StatusFilter.overdue.rawValue, "Overdue")
        XCTAssertEqual(TherapistPrescriptionDashboardViewModel.StatusFilter.cancelled.rawValue, "Cancelled")
    }

    func testStatusFilter_Icons() {
        XCTAssertEqual(TherapistPrescriptionDashboardViewModel.StatusFilter.all.icon, "list.bullet")
        XCTAssertEqual(TherapistPrescriptionDashboardViewModel.StatusFilter.pending.icon, "clock")
        XCTAssertEqual(TherapistPrescriptionDashboardViewModel.StatusFilter.viewed.icon, "eye")
        XCTAssertEqual(TherapistPrescriptionDashboardViewModel.StatusFilter.started.icon, "play.circle")
        XCTAssertEqual(TherapistPrescriptionDashboardViewModel.StatusFilter.completed.icon, "checkmark.circle")
        XCTAssertEqual(TherapistPrescriptionDashboardViewModel.StatusFilter.overdue.icon, "exclamationmark.triangle")
        XCTAssertEqual(TherapistPrescriptionDashboardViewModel.StatusFilter.cancelled.icon, "xmark.circle")
    }

    func testStatusFilter_Identifiable() {
        for filter in TherapistPrescriptionDashboardViewModel.StatusFilter.allCases {
            XCTAssertEqual(filter.id, filter.rawValue)
        }
    }

    // MARK: - DateRangeFilter Enum Tests

    func testDateRangeFilter_AllCases() {
        let allCases = TherapistPrescriptionDashboardViewModel.DateRangeFilter.allCases
        XCTAssertEqual(allCases.count, 5)
    }

    func testDateRangeFilter_RawValues() {
        XCTAssertEqual(TherapistPrescriptionDashboardViewModel.DateRangeFilter.all.rawValue, "All Time")
        XCTAssertEqual(TherapistPrescriptionDashboardViewModel.DateRangeFilter.today.rawValue, "Today")
        XCTAssertEqual(TherapistPrescriptionDashboardViewModel.DateRangeFilter.thisWeek.rawValue, "This Week")
        XCTAssertEqual(TherapistPrescriptionDashboardViewModel.DateRangeFilter.thisMonth.rawValue, "This Month")
        XCTAssertEqual(TherapistPrescriptionDashboardViewModel.DateRangeFilter.overdue.rawValue, "Overdue Only")
    }

    func testDateRangeFilter_Identifiable() {
        for filter in TherapistPrescriptionDashboardViewModel.DateRangeFilter.allCases {
            XCTAssertEqual(filter.id, filter.rawValue)
        }
    }

    // MARK: - Filtered Prescriptions Tests

    func testFilteredPrescriptions_EmptyWhenNoPrescriptions() {
        XCTAssertTrue(sut.filteredPrescriptions.isEmpty)
    }

    func testFilteredPrescriptions_SearchByPatientName() {
        sut.prescriptions = createMockPrescriptionsWithPatients()
        sut.searchText = "John"

        let filtered = sut.filteredPrescriptions
        XCTAssertTrue(filtered.allSatisfy { $0.patient.firstName.contains("John") })
    }

    func testFilteredPrescriptions_SearchByPrescriptionName() {
        sut.prescriptions = createMockPrescriptionsWithPatients()
        sut.searchText = "Workout"

        let filtered = sut.filteredPrescriptions
        XCTAssertFalse(filtered.isEmpty)
    }

    func testFilteredPrescriptions_CaseInsensitiveSearch() {
        sut.prescriptions = createMockPrescriptionsWithPatients()
        sut.searchText = "WORKOUT"

        XCTAssertFalse(sut.filteredPrescriptions.isEmpty)
    }

    func testFilteredPrescriptions_StatusFilterPending() {
        sut.prescriptions = createMockPrescriptionsWithPatients()
        sut.selectedStatusFilter = .pending

        let filtered = sut.filteredPrescriptions
        XCTAssertTrue(filtered.allSatisfy { $0.prescription.status == .pending })
    }

    func testFilteredPrescriptions_StatusFilterCompleted() {
        sut.prescriptions = createMockPrescriptionsWithPatients()
        sut.selectedStatusFilter = .completed

        let filtered = sut.filteredPrescriptions
        XCTAssertTrue(filtered.allSatisfy { $0.prescription.status == .completed })
    }

    func testFilteredPrescriptions_PatientIdFilter() {
        sut.prescriptions = createMockPrescriptionsWithPatients()
        guard let firstPatientId = sut.prescriptions.first?.patient.id else {
            XCTFail("No prescriptions")
            return
        }
        sut.selectedPatientId = firstPatientId

        let filtered = sut.filteredPrescriptions
        XCTAssertTrue(filtered.allSatisfy { $0.patient.id == firstPatientId })
    }

    // MARK: - Active Prescriptions Tests

    func testActivePrescriptions_IncludesPending() {
        sut.prescriptions = createMockPrescriptionsWithPatients()

        let active = sut.activePrescriptions
        let hasPending = sut.prescriptions.contains { $0.prescription.status == .pending }
        if hasPending {
            XCTAssertTrue(active.contains { $0.prescription.status == .pending })
        }
    }

    func testActivePrescriptions_IncludesViewed() {
        sut.prescriptions = createMockPrescriptionsWithPatients()

        let active = sut.activePrescriptions
        let hasViewed = sut.prescriptions.contains { $0.prescription.status == .viewed }
        if hasViewed {
            XCTAssertTrue(active.contains { $0.prescription.status == .viewed })
        }
    }

    func testActivePrescriptions_IncludesStarted() {
        sut.prescriptions = createMockPrescriptionsWithPatients()

        let active = sut.activePrescriptions
        let hasStarted = sut.prescriptions.contains { $0.prescription.status == .started }
        if hasStarted {
            XCTAssertTrue(active.contains { $0.prescription.status == .started })
        }
    }

    func testActivePrescriptions_ExcludesCompleted() {
        sut.prescriptions = createMockPrescriptionsWithPatients()

        let active = sut.activePrescriptions
        XCTAssertFalse(active.contains { $0.prescription.status == .completed })
    }

    func testActivePrescriptions_ExcludesCancelled() {
        sut.prescriptions = createMockPrescriptionsWithPatients()

        let active = sut.activePrescriptions
        XCTAssertFalse(active.contains { $0.prescription.status == .cancelled })
    }

    // MARK: - Overdue Prescriptions Tests

    func testOverduePrescriptions_EmptyWhenNoneOverdue() {
        sut.prescriptions = createMockPrescriptionsWithPatients()

        // Filter to non-overdue only
        let nonOverdue = sut.prescriptions.filter { !$0.prescription.isOverdue }
        sut.prescriptions = nonOverdue

        XCTAssertTrue(sut.overduePrescriptions.isEmpty)
    }

    func testOverduePrescriptions_IdentifiesOverdue() {
        sut.prescriptions = [createOverduePrescriptionWithPatient()]

        XCTAssertEqual(sut.overduePrescriptions.count, 1)
    }

    // MARK: - Recently Completed Prescriptions Tests

    func testRecentlyCompletedPrescriptions_EmptyWhenNoneCompleted() {
        sut.prescriptions = createMockPrescriptionsWithPatients().filter { $0.prescription.status != .completed }

        XCTAssertTrue(sut.recentlyCompletedPrescriptions.isEmpty)
    }

    // MARK: - Compliance Rate Tests

    func testOverallComplianceRate_ZeroWhenNoPrescriptions() {
        XCTAssertEqual(sut.overallComplianceRate, 0)
    }

    func testOverallComplianceRate_CalculatesCorrectly() {
        // Create prescriptions: 1 completed, 1 pending
        let prescriptions = [
            createPrescriptionWithPatient(status: .completed),
            createPrescriptionWithPatient(status: .pending)
        ]
        sut.prescriptions = prescriptions

        // 1 completed out of 2 total = 50%
        XCTAssertEqual(sut.overallComplianceRate, 50.0, accuracy: 0.1)
    }

    func testOverallComplianceRate_ExcludesCancelled() {
        let prescriptions = [
            createPrescriptionWithPatient(status: .completed),
            createPrescriptionWithPatient(status: .cancelled)
        ]
        sut.prescriptions = prescriptions

        // 1 completed out of 1 non-cancelled = 100%
        XCTAssertEqual(sut.overallComplianceRate, 100.0, accuracy: 0.1)
    }

    func testOverallComplianceRate_HundredPercentWhenAllCompleted() {
        let prescriptions = [
            createPrescriptionWithPatient(status: .completed),
            createPrescriptionWithPatient(status: .completed)
        ]
        sut.prescriptions = prescriptions

        XCTAssertEqual(sut.overallComplianceRate, 100.0, accuracy: 0.1)
    }

    // MARK: - Compliance By Patient Tests

    func testComplianceByPatient_EmptyWhenNoPrescriptions() {
        XCTAssertTrue(sut.complianceByPatient.isEmpty)
    }

    func testComplianceByPatient_GroupsByPatient() {
        let patient1 = createMockPatient(firstName: "John")
        let patient2 = createMockPatient(firstName: "Jane")

        sut.prescriptions = [
            PrescriptionWithPatient(prescription: createMockPrescription(status: .completed), patient: patient1),
            PrescriptionWithPatient(prescription: createMockPrescription(status: .pending), patient: patient1),
            PrescriptionWithPatient(prescription: createMockPrescription(status: .completed), patient: patient2)
        ]

        let compliance = sut.complianceByPatient
        XCTAssertEqual(compliance.count, 2)
    }

    func testComplianceByPatient_SortedByLowestComplianceFirst() {
        let patient1 = createMockPatient(firstName: "HighCompliance")
        let patient2 = createMockPatient(firstName: "LowCompliance")

        sut.prescriptions = [
            PrescriptionWithPatient(prescription: createMockPrescription(status: .completed), patient: patient1),
            PrescriptionWithPatient(prescription: createMockPrescription(status: .pending), patient: patient2)
        ]

        let compliance = sut.complianceByPatient
        if compliance.count >= 2 {
            XCTAssertLessThanOrEqual(compliance[0].complianceRate, compliance[1].complianceRate)
        }
    }

    // MARK: - Status Counts Tests

    func testStatusCounts_IncludesAllStatuses() {
        sut.prescriptions = createMockPrescriptionsWithPatients()

        let counts = sut.statusCounts
        XCTAssertNotNil(counts[.all])
        XCTAssertNotNil(counts[.pending])
        XCTAssertNotNil(counts[.completed])
    }

    func testStatusCounts_TotalEqualsAllCount() {
        sut.prescriptions = createMockPrescriptionsWithPatients()

        let counts = sut.statusCounts
        XCTAssertEqual(counts[.all], sut.prescriptions.count)
    }

    // MARK: - Clear Filters Tests

    func testClearFilters_ResetsSearchText() {
        sut.searchText = "Some search"

        sut.clearFilters()

        XCTAssertEqual(sut.searchText, "")
    }

    func testClearFilters_ResetsStatusFilter() {
        sut.selectedStatusFilter = .completed

        sut.clearFilters()

        XCTAssertEqual(sut.selectedStatusFilter, .all)
    }

    func testClearFilters_ResetsDateRange() {
        sut.selectedDateRange = .today

        sut.clearFilters()

        XCTAssertEqual(sut.selectedDateRange, .all)
    }

    func testClearFilters_ResetsPatientId() {
        sut.selectedPatientId = UUID()

        sut.clearFilters()

        XCTAssertNil(sut.selectedPatientId)
    }

    // MARK: - Auto Refresh Tests

    func testStartAutoRefresh_CanBeStopped() {
        sut.startAutoRefresh(therapistId: UUID().uuidString, interval: 60)

        // Should not throw
        sut.stopAutoRefresh()
    }

    func testStopAutoRefresh_SafeToCallMultipleTimes() {
        sut.stopAutoRefresh()
        sut.stopAutoRefresh()

        // Should not throw
        XCTAssertTrue(true)
    }

    // MARK: - Security Tests

    func testLoadPrescriptions_WithEmptyTherapistIdSetsError() async {
        await sut.loadPrescriptions(therapistId: "")

        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - Helper Methods

    private func createMockPatient(firstName: String = "Test", lastName: String = "Patient") -> Patient {
        Patient(
            id: UUID(),
            therapistId: UUID(),
            firstName: firstName,
            lastName: lastName,
            email: "\(firstName.lowercased())@example.com"
        )
    }

    private func createMockPrescription(status: PrescriptionStatus = .pending) -> WorkoutPrescription {
        WorkoutPrescription(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            templateId: nil,
            templateType: nil,
            name: "Test Workout",
            instructions: nil,
            dueDate: Date().addingTimeInterval(86400),
            priority: .medium,
            status: status,
            manualSessionId: nil,
            prescribedAt: Date(),
            viewedAt: nil,
            startedAt: nil,
            completedAt: status == .completed ? Date() : nil,
            createdAt: Date()
        )
    }

    private func createPrescriptionWithPatient(status: PrescriptionStatus = .pending) -> PrescriptionWithPatient {
        PrescriptionWithPatient(
            prescription: createMockPrescription(status: status),
            patient: createMockPatient()
        )
    }

    private func createMockPrescriptionsWithPatients() -> [PrescriptionWithPatient] {
        let patient1 = createMockPatient(firstName: "John")
        let patient2 = createMockPatient(firstName: "Jane")

        return [
            PrescriptionWithPatient(prescription: createMockPrescription(status: .pending), patient: patient1),
            PrescriptionWithPatient(prescription: createMockPrescription(status: .completed), patient: patient1),
            PrescriptionWithPatient(prescription: createMockPrescription(status: .started), patient: patient2)
        ]
    }

    private func createOverduePrescriptionWithPatient() -> PrescriptionWithPatient {
        let prescription = WorkoutPrescription(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            templateId: nil,
            templateType: nil,
            name: "Overdue Workout",
            instructions: nil,
            dueDate: Date().addingTimeInterval(-86400), // Yesterday
            priority: .high,
            status: .pending,
            manualSessionId: nil,
            prescribedAt: Date().addingTimeInterval(-172800),
            viewedAt: nil,
            startedAt: nil,
            completedAt: nil,
            createdAt: Date().addingTimeInterval(-172800)
        )

        return PrescriptionWithPatient(
            prescription: prescription,
            patient: createMockPatient()
        )
    }
}

// MARK: - WorkoutPrescription Model Tests

final class WorkoutPrescriptionModelTests: XCTestCase {

    // MARK: - Initialization Tests

    func testWorkoutPrescription_MemberwiseInit() {
        let id = UUID()
        let patientId = UUID()
        let therapistId = UUID()

        let prescription = WorkoutPrescription(
            id: id,
            patientId: patientId,
            therapistId: therapistId,
            templateId: nil,
            templateType: nil,
            name: "Test Workout",
            instructions: "Do this workout",
            dueDate: Date(),
            priority: .high,
            status: .pending,
            manualSessionId: nil,
            prescribedAt: Date(),
            viewedAt: nil,
            startedAt: nil,
            completedAt: nil,
            createdAt: Date()
        )

        XCTAssertEqual(prescription.id, id)
        XCTAssertEqual(prescription.patientId, patientId)
        XCTAssertEqual(prescription.therapistId, therapistId)
        XCTAssertEqual(prescription.name, "Test Workout")
        XCTAssertEqual(prescription.priority, .high)
        XCTAssertEqual(prescription.status, .pending)
    }

    // MARK: - IsOverdue Tests

    func testIsOverdue_TrueWhenPastDueAndNotCompleted() {
        let prescription = createPrescription(
            dueDate: Date().addingTimeInterval(-86400), // Yesterday
            status: .pending
        )

        XCTAssertTrue(prescription.isOverdue)
    }

    func testIsOverdue_FalseWhenCompleted() {
        let prescription = createPrescription(
            dueDate: Date().addingTimeInterval(-86400), // Yesterday
            status: .completed
        )

        XCTAssertFalse(prescription.isOverdue)
    }

    func testIsOverdue_FalseWhenCancelled() {
        let prescription = createPrescription(
            dueDate: Date().addingTimeInterval(-86400), // Yesterday
            status: .cancelled
        )

        XCTAssertFalse(prescription.isOverdue)
    }

    func testIsOverdue_FalseWhenNotPastDue() {
        let prescription = createPrescription(
            dueDate: Date().addingTimeInterval(86400), // Tomorrow
            status: .pending
        )

        XCTAssertFalse(prescription.isOverdue)
    }

    func testIsOverdue_FalseWhenNoDueDate() {
        let prescription = createPrescription(dueDate: nil, status: .pending)

        XCTAssertFalse(prescription.isOverdue)
    }

    // MARK: - DaysUntilDue Tests

    func testDaysUntilDue_PositiveForFutureDue() {
        let prescription = createPrescription(
            dueDate: Date().addingTimeInterval(86400 * 3), // 3 days from now
            status: .pending
        )

        XCTAssertNotNil(prescription.daysUntilDue)
        XCTAssertGreaterThan(prescription.daysUntilDue ?? 0, 0)
    }

    func testDaysUntilDue_NegativeForPastDue() {
        let prescription = createPrescription(
            dueDate: Date().addingTimeInterval(-86400 * 2), // 2 days ago
            status: .pending
        )

        XCTAssertNotNil(prescription.daysUntilDue)
        XCTAssertLessThan(prescription.daysUntilDue ?? 0, 0)
    }

    func testDaysUntilDue_NilWhenNoDueDate() {
        let prescription = createPrescription(dueDate: nil, status: .pending)

        XCTAssertNil(prescription.daysUntilDue)
    }

    // MARK: - Decoding Tests

    func testWorkoutPrescription_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "therapist_id": "770e8400-e29b-41d4-a716-446655440002",
            "template_id": null,
            "template_type": null,
            "name": "Morning Workout",
            "instructions": "Complete all exercises",
            "due_date": "2024-01-20T10:00:00Z",
            "priority": "high",
            "status": "pending",
            "manual_session_id": null,
            "prescribed_at": "2024-01-15T10:00:00Z",
            "viewed_at": null,
            "started_at": null,
            "completed_at": null,
            "created_at": "2024-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let prescription = try decoder.decode(WorkoutPrescription.self, from: json)

        XCTAssertEqual(prescription.name, "Morning Workout")
        XCTAssertEqual(prescription.priority, .high)
        XCTAssertEqual(prescription.status, .pending)
        XCTAssertEqual(prescription.instructions, "Complete all exercises")
    }

    func testWorkoutPrescription_DecodingWithDefaults() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "therapist_id": "770e8400-e29b-41d4-a716-446655440002",
            "name": null,
            "priority": "invalid_priority",
            "status": "invalid_status"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let prescription = try decoder.decode(WorkoutPrescription.self, from: json)

        // Should use defaults
        XCTAssertEqual(prescription.name, "Unnamed Prescription")
        XCTAssertEqual(prescription.priority, .medium)
        XCTAssertEqual(prescription.status, .pending)
    }

    // MARK: - Helper Methods

    private func createPrescription(dueDate: Date?, status: PrescriptionStatus) -> WorkoutPrescription {
        WorkoutPrescription(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            templateId: nil,
            templateType: nil,
            name: "Test",
            instructions: nil,
            dueDate: dueDate,
            priority: .medium,
            status: status,
            manualSessionId: nil,
            prescribedAt: Date(),
            viewedAt: nil,
            startedAt: nil,
            completedAt: nil,
            createdAt: Date()
        )
    }
}

// MARK: - PrescriptionPriority Tests

final class PrescriptionPriorityTests: XCTestCase {

    func testPrescriptionPriority_AllCases() {
        XCTAssertEqual(PrescriptionPriority.allCases.count, 4)
    }

    func testPrescriptionPriority_RawValues() {
        XCTAssertEqual(PrescriptionPriority.low.rawValue, "low")
        XCTAssertEqual(PrescriptionPriority.medium.rawValue, "medium")
        XCTAssertEqual(PrescriptionPriority.high.rawValue, "high")
        XCTAssertEqual(PrescriptionPriority.urgent.rawValue, "urgent")
    }

    func testPrescriptionPriority_DisplayNames() {
        XCTAssertEqual(PrescriptionPriority.low.displayName, "Low")
        XCTAssertEqual(PrescriptionPriority.medium.displayName, "Medium")
        XCTAssertEqual(PrescriptionPriority.high.displayName, "High")
        XCTAssertEqual(PrescriptionPriority.urgent.displayName, "Urgent")
    }

    func testPrescriptionPriority_Colors() {
        XCTAssertEqual(PrescriptionPriority.low.color, "green")
        XCTAssertEqual(PrescriptionPriority.medium.color, "blue")
        XCTAssertEqual(PrescriptionPriority.high.color, "orange")
        XCTAssertEqual(PrescriptionPriority.urgent.color, "red")
    }

    func testPrescriptionPriority_Codable() throws {
        let priority = PrescriptionPriority.high

        let encoder = JSONEncoder()
        let data = try encoder.encode(priority)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PrescriptionPriority.self, from: data)

        XCTAssertEqual(decoded, priority)
    }
}

// MARK: - PrescriptionStatus Tests

final class PrescriptionStatusTests: XCTestCase {

    func testPrescriptionStatus_AllCases() {
        XCTAssertEqual(PrescriptionStatus.allCases.count, 6)
    }

    func testPrescriptionStatus_RawValues() {
        XCTAssertEqual(PrescriptionStatus.pending.rawValue, "pending")
        XCTAssertEqual(PrescriptionStatus.viewed.rawValue, "viewed")
        XCTAssertEqual(PrescriptionStatus.started.rawValue, "started")
        XCTAssertEqual(PrescriptionStatus.completed.rawValue, "completed")
        XCTAssertEqual(PrescriptionStatus.expired.rawValue, "expired")
        XCTAssertEqual(PrescriptionStatus.cancelled.rawValue, "cancelled")
    }

    func testPrescriptionStatus_DisplayNames() {
        XCTAssertEqual(PrescriptionStatus.pending.displayName, "Pending")
        XCTAssertEqual(PrescriptionStatus.viewed.displayName, "Viewed")
        XCTAssertEqual(PrescriptionStatus.started.displayName, "Started")
        XCTAssertEqual(PrescriptionStatus.completed.displayName, "Completed")
        XCTAssertEqual(PrescriptionStatus.expired.displayName, "Expired")
        XCTAssertEqual(PrescriptionStatus.cancelled.displayName, "Cancelled")
    }

    func testPrescriptionStatus_Codable() throws {
        let status = PrescriptionStatus.completed

        let encoder = JSONEncoder()
        let data = try encoder.encode(status)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PrescriptionStatus.self, from: data)

        XCTAssertEqual(decoded, status)
    }
}

// MARK: - PrescriptionWithPatient Tests

final class PrescriptionWithPatientTests: XCTestCase {

    func testPrescriptionWithPatient_IdMatchesPrescriptionId() {
        let prescription = createPrescription()
        let patient = createPatient()

        let combined = PrescriptionWithPatient(prescription: prescription, patient: patient)

        XCTAssertEqual(combined.id, prescription.id)
    }

    func testPrescriptionWithPatient_Identifiable() {
        let combined = PrescriptionWithPatient(
            prescription: createPrescription(),
            patient: createPatient()
        )

        XCTAssertNotNil(combined.id)
    }

    private func createPrescription() -> WorkoutPrescription {
        WorkoutPrescription(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            templateId: nil,
            templateType: nil,
            name: "Test",
            instructions: nil,
            dueDate: nil,
            priority: .medium,
            status: .pending,
            manualSessionId: nil,
            prescribedAt: Date(),
            viewedAt: nil,
            startedAt: nil,
            completedAt: nil,
            createdAt: Date()
        )
    }

    private func createPatient() -> Patient {
        Patient(
            id: UUID(),
            therapistId: UUID(),
            firstName: "Test",
            lastName: "Patient",
            email: "test@example.com"
        )
    }
}

// MARK: - PatientCompliance Tests

final class PatientComplianceTests: XCTestCase {

    func testPatientCompliance_IdMatchesPatientId() {
        let patient = createPatient()
        let compliance = PatientCompliance(
            patient: patient,
            complianceRate: 85.0,
            totalPrescriptions: 10,
            completedPrescriptions: 8,
            overduePrescriptions: 1
        )

        XCTAssertEqual(compliance.id, patient.id)
    }

    func testPatientCompliance_ComplianceColor_Good() {
        let compliance = createCompliance(rate: 85.0)

        XCTAssertEqual(compliance.complianceColor, .green)
    }

    func testPatientCompliance_ComplianceColor_NeedsAttention() {
        let compliance = createCompliance(rate: 65.0)

        XCTAssertEqual(compliance.complianceColor, .orange)
    }

    func testPatientCompliance_ComplianceColor_AtRisk() {
        let compliance = createCompliance(rate: 40.0)

        XCTAssertEqual(compliance.complianceColor, .red)
    }

    func testPatientCompliance_ComplianceLabel_Good() {
        let compliance = createCompliance(rate: 90.0)

        XCTAssertEqual(compliance.complianceLabel, "Good")
    }

    func testPatientCompliance_ComplianceLabel_NeedsAttention() {
        let compliance = createCompliance(rate: 60.0)

        XCTAssertEqual(compliance.complianceLabel, "Needs Attention")
    }

    func testPatientCompliance_ComplianceLabel_AtRisk() {
        let compliance = createCompliance(rate: 30.0)

        XCTAssertEqual(compliance.complianceLabel, "At Risk")
    }

    func testPatientCompliance_BoundaryValue_80Percent() {
        let compliance = createCompliance(rate: 80.0)

        XCTAssertEqual(compliance.complianceColor, .green)
        XCTAssertEqual(compliance.complianceLabel, "Good")
    }

    func testPatientCompliance_BoundaryValue_50Percent() {
        let compliance = createCompliance(rate: 50.0)

        XCTAssertEqual(compliance.complianceColor, .orange)
        XCTAssertEqual(compliance.complianceLabel, "Needs Attention")
    }

    private func createPatient() -> Patient {
        Patient(
            id: UUID(),
            therapistId: UUID(),
            firstName: "Test",
            lastName: "Patient",
            email: "test@example.com"
        )
    }

    private func createCompliance(rate: Double) -> PatientCompliance {
        PatientCompliance(
            patient: createPatient(),
            complianceRate: rate,
            totalPrescriptions: 10,
            completedPrescriptions: Int(rate / 10),
            overduePrescriptions: 0
        )
    }
}

// MARK: - CreatePrescriptionDTO Tests

final class CreatePrescriptionDTOTests: XCTestCase {

    func testCreatePrescriptionDTO_Encodable() throws {
        let dto = CreatePrescriptionDTO(
            patientId: UUID(),
            therapistId: UUID(),
            templateId: nil,
            templateType: nil,
            name: "New Prescription",
            instructions: "Follow these instructions",
            dueDate: Date(),
            priority: "high"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(dto)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("patient_id"))
        XCTAssertTrue(jsonString.contains("therapist_id"))
        XCTAssertTrue(jsonString.contains("name"))
        XCTAssertTrue(jsonString.contains("priority"))
    }

    func testCreatePrescriptionDTO_WithOptionalFields() throws {
        let dto = CreatePrescriptionDTO(
            patientId: UUID(),
            therapistId: UUID(),
            templateId: UUID(),
            templateType: "strength",
            name: "Detailed Prescription",
            instructions: nil,
            dueDate: nil,
            priority: "medium"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(dto)

        XCTAssertNotNil(data)
    }
}
