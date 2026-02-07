import Foundation
import Supabase

// MARK: - RPC Parameter Structs

/// RPC parameters for creating a clinical assessment
private struct CreateClinicalAssessmentParams: Encodable {
    let pPatientId: String
    let pTherapistId: String
    let pAssessmentType: String
    let pAssessmentDate: String
    let pStatus: String

    enum CodingKeys: String, CodingKey {
        case pPatientId = "p_patient_id"
        case pTherapistId = "p_therapist_id"
        case pAssessmentType = "p_assessment_type"
        case pAssessmentDate = "p_assessment_date"
        case pStatus = "p_status"
    }
}

/// RPC parameters for fetching a clinical assessment by ID
private struct GetClinicalAssessmentParams: Encodable {
    let pAssessmentId: String

    enum CodingKeys: String, CodingKey {
        case pAssessmentId = "p_assessment_id"
    }
}

/// Service for managing clinical assessments
/// Provides CRUD operations for comprehensive clinical evaluations including ROM measurements and functional tests
@MainActor
class ClinicalAssessmentService: ObservableObject {
    // MARK: - Singleton

    static let shared = ClinicalAssessmentService()

    // MARK: - Properties

    nonisolated(unsafe) private let client: PTSupabaseClient
    @Published var isLoading = false
    @Published var error: Error?
    @Published var currentAssessment: ClinicalAssessment?

    // MARK: - Initialization

    nonisolated init(client: PTSupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Create Assessment

    /// Create a new clinical assessment
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - therapistId: Therapist UUID
    ///   - assessmentType: Type of assessment (intake, progress, discharge, follow_up)
    ///   - assessmentDate: Date of the assessment
    /// - Returns: Created ClinicalAssessment
    func createAssessment(
        patientId: UUID,
        therapistId: UUID,
        assessmentType: AssessmentType,
        assessmentDate: Date = Date()
    ) async throws -> ClinicalAssessment {
        isLoading = true
        defer { isLoading = false }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: assessmentDate)

        let input = ClinicalAssessmentInput(
            patientId: patientId.uuidString,
            therapistId: therapistId.uuidString,
            assessmentType: assessmentType.rawValue,
            assessmentDate: dateString,
            status: AssessmentStatus.draft.rawValue
        )

        // Validate input
        try input.validate()

        do {
            #if DEBUG
            print("Creating clinical assessment for patient: \(patientId.uuidString), type: \(assessmentType.rawValue)")
            #endif

            let response = try await client.client
                .from("clinical_assessments")
                .insert(input)
                .select()
                .single()
                .execute()

            let decoder = createDecoder()
            let assessment = try decoder.decode(ClinicalAssessment.self, from: response.data)

            #if DEBUG
            print("Clinical assessment created: \(assessment.id)")
            #endif

            currentAssessment = assessment
            return assessment
        } catch {
            DebugLogger.shared.error("ClinicalAssessmentService", "Error creating clinical assessment: \(error.localizedDescription)")
            self.error = error
            throw ClinicalAssessmentError.saveFailed
        }
    }

    // MARK: - Fetch Assessment

    /// Fetch a clinical assessment by ID
    /// - Parameter assessmentId: Assessment UUID
    /// - Returns: ClinicalAssessment or nil if not found
    func fetchAssessment(id assessmentId: UUID) async throws -> ClinicalAssessment? {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await client.client
                .from("clinical_assessments")
                .select()
                .eq("id", value: assessmentId.uuidString)
                .single()
                .execute()

            let decoder = createDecoder()
            let assessment = try decoder.decode(ClinicalAssessment.self, from: response.data)

            currentAssessment = assessment
            return assessment
        } catch {
            DebugLogger.shared.warning("ClinicalAssessmentService", "Error fetching clinical assessment: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Fetch Patient Assessments

    /// Fetch all assessments for a patient
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - limit: Maximum number of records (default 50)
    /// - Returns: Array of assessments ordered by date descending
    func fetchAssessments(
        for patientId: UUID,
        limit: Int = 50
    ) async throws -> [ClinicalAssessment] {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await client.client
                .from("clinical_assessments")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .order("assessment_date", ascending: false)
                .limit(limit)
                .execute()

            let decoder = createDecoder()
            return try decoder.decode([ClinicalAssessment].self, from: response.data)
        } catch {
            self.error = error
            throw ClinicalAssessmentError.fetchFailed
        }
    }

    /// Fetch assessments by type for a patient
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - type: Assessment type filter
    ///   - limit: Maximum number of records (default 20)
    /// - Returns: Array of assessments of the specified type
    func fetchAssessments(
        for patientId: UUID,
        type: AssessmentType,
        limit: Int = 20
    ) async throws -> [ClinicalAssessment] {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await client.client
                .from("clinical_assessments")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .eq("assessment_type", value: type.rawValue)
                .order("assessment_date", ascending: false)
                .limit(limit)
                .execute()

            let decoder = createDecoder()
            return try decoder.decode([ClinicalAssessment].self, from: response.data)
        } catch {
            self.error = error
            throw ClinicalAssessmentError.fetchFailed
        }
    }

    /// Fetch the most recent assessment for a patient
    /// - Parameter patientId: Patient UUID
    /// - Returns: Most recent assessment or nil if none found
    func fetchLatestAssessment(for patientId: UUID) async throws -> ClinicalAssessment? {
        let assessments = try await fetchAssessments(for: patientId, limit: 1)
        return assessments.first
    }

    // MARK: - Update Assessment

    /// Update an existing clinical assessment
    /// - Parameter assessment: Updated assessment data
    /// - Returns: Updated ClinicalAssessment
    func updateAssessment(_ assessment: ClinicalAssessment) async throws -> ClinicalAssessment {
        isLoading = true
        defer { isLoading = false }

        // Check if assessment can be edited
        guard assessment.status.isEditable else {
            throw ClinicalAssessmentError.cannotEditSigned
        }

        do {
            #if DEBUG
            print("Updating clinical assessment: \(assessment.id)")
            #endif

            // Create update payload
            var updateData: [String: AnyEncodable] = [
                "updated_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
            ]

            // Add optional fields if present
            if let romMeasurements = assessment.romMeasurements {
                updateData["rom_measurements"] = AnyEncodable(romMeasurements)
            }
            if let functionalTests = assessment.functionalTests {
                updateData["functional_tests"] = AnyEncodable(functionalTests)
            }
            if let painAtRest = assessment.painAtRest {
                updateData["pain_at_rest"] = AnyEncodable(painAtRest)
            }
            if let painWithActivity = assessment.painWithActivity {
                updateData["pain_with_activity"] = AnyEncodable(painWithActivity)
            }
            if let painWorst = assessment.painWorst {
                updateData["pain_worst"] = AnyEncodable(painWorst)
            }
            if let painLocations = assessment.painLocations {
                updateData["pain_locations"] = AnyEncodable(painLocations)
            }
            if let chiefComplaint = assessment.chiefComplaint {
                updateData["chief_complaint"] = AnyEncodable(chiefComplaint)
            }
            if let historyOfPresentIllness = assessment.historyOfPresentIllness {
                updateData["history_of_present_illness"] = AnyEncodable(historyOfPresentIllness)
            }
            if let pastMedicalHistory = assessment.pastMedicalHistory {
                updateData["past_medical_history"] = AnyEncodable(pastMedicalHistory)
            }
            if let functionalGoals = assessment.functionalGoals {
                updateData["functional_goals"] = AnyEncodable(functionalGoals)
            }
            if let objectiveFindings = assessment.objectiveFindings {
                updateData["objective_findings"] = AnyEncodable(objectiveFindings)
            }
            if let assessmentSummary = assessment.assessmentSummary {
                updateData["assessment_summary"] = AnyEncodable(assessmentSummary)
            }
            if let treatmentPlan = assessment.treatmentPlan {
                updateData["treatment_plan"] = AnyEncodable(treatmentPlan)
            }

            updateData["status"] = AnyEncodable(assessment.status.rawValue)

            let response = try await client.client
                .from("clinical_assessments")
                .update(updateData)
                .eq("id", value: assessment.id.uuidString)
                .select()
                .single()
                .execute()

            let decoder = createDecoder()
            let updatedAssessment = try decoder.decode(ClinicalAssessment.self, from: response.data)

            #if DEBUG
            print("Clinical assessment updated: \(updatedAssessment.id)")
            #endif

            currentAssessment = updatedAssessment
            return updatedAssessment
        } catch let assessmentError as ClinicalAssessmentError {
            throw assessmentError
        } catch {
            DebugLogger.shared.error("ClinicalAssessmentService", "Error updating clinical assessment: \(error.localizedDescription)")
            self.error = error
            throw ClinicalAssessmentError.saveFailed
        }
    }

    // MARK: - ROM Measurements

    /// Add ROM measurements to an assessment
    /// - Parameters:
    ///   - assessmentId: Assessment UUID
    ///   - measurements: Array of ROM measurements
    /// - Returns: Updated ClinicalAssessment
    func addROMMeasurements(
        to assessmentId: UUID,
        measurements: [ROMeasurement]
    ) async throws -> ClinicalAssessment {
        guard var assessment = try await fetchAssessment(id: assessmentId) else {
            throw ClinicalAssessmentError.assessmentNotFound
        }

        guard assessment.status.isEditable else {
            throw ClinicalAssessmentError.cannotEditSigned
        }

        // Append new measurements to existing ones
        var existingMeasurements = assessment.romMeasurements ?? []
        existingMeasurements.append(contentsOf: measurements)
        assessment.romMeasurements = existingMeasurements

        return try await updateAssessment(assessment)
    }

    /// Update a specific ROM measurement in an assessment
    /// - Parameters:
    ///   - assessmentId: Assessment UUID
    ///   - measurement: Updated ROM measurement
    /// - Returns: Updated ClinicalAssessment
    func updateROMMeasurement(
        in assessmentId: UUID,
        measurement: ROMeasurement
    ) async throws -> ClinicalAssessment {
        guard var assessment = try await fetchAssessment(id: assessmentId) else {
            throw ClinicalAssessmentError.assessmentNotFound
        }

        guard assessment.status.isEditable else {
            throw ClinicalAssessmentError.cannotEditSigned
        }

        guard var measurements = assessment.romMeasurements,
              let index = measurements.firstIndex(where: { $0.id == measurement.id }) else {
            throw ClinicalAssessmentError.assessmentNotFound
        }

        measurements[index] = measurement
        assessment.romMeasurements = measurements

        return try await updateAssessment(assessment)
    }

    /// Remove a ROM measurement from an assessment
    /// - Parameters:
    ///   - assessmentId: Assessment UUID
    ///   - measurementId: ROM measurement UUID to remove
    /// - Returns: Updated ClinicalAssessment
    func removeROMMeasurement(
        from assessmentId: UUID,
        measurementId: UUID
    ) async throws -> ClinicalAssessment {
        guard var assessment = try await fetchAssessment(id: assessmentId) else {
            throw ClinicalAssessmentError.assessmentNotFound
        }

        guard assessment.status.isEditable else {
            throw ClinicalAssessmentError.cannotEditSigned
        }

        assessment.romMeasurements?.removeAll { $0.id == measurementId }

        return try await updateAssessment(assessment)
    }

    // MARK: - Functional Tests

    /// Add functional tests to an assessment
    /// - Parameters:
    ///   - assessmentId: Assessment UUID
    ///   - tests: Array of functional tests
    /// - Returns: Updated ClinicalAssessment
    func addFunctionalTests(
        to assessmentId: UUID,
        tests: [FunctionalTest]
    ) async throws -> ClinicalAssessment {
        guard var assessment = try await fetchAssessment(id: assessmentId) else {
            throw ClinicalAssessmentError.assessmentNotFound
        }

        guard assessment.status.isEditable else {
            throw ClinicalAssessmentError.cannotEditSigned
        }

        // Append new tests to existing ones
        var existingTests = assessment.functionalTests ?? []
        existingTests.append(contentsOf: tests)
        assessment.functionalTests = existingTests

        return try await updateAssessment(assessment)
    }

    /// Update a specific functional test in an assessment
    /// - Parameters:
    ///   - assessmentId: Assessment UUID
    ///   - test: Updated functional test
    /// - Returns: Updated ClinicalAssessment
    func updateFunctionalTest(
        in assessmentId: UUID,
        test: FunctionalTest
    ) async throws -> ClinicalAssessment {
        guard var assessment = try await fetchAssessment(id: assessmentId) else {
            throw ClinicalAssessmentError.assessmentNotFound
        }

        guard assessment.status.isEditable else {
            throw ClinicalAssessmentError.cannotEditSigned
        }

        guard var tests = assessment.functionalTests,
              let index = tests.firstIndex(where: { $0.id == test.id }) else {
            throw ClinicalAssessmentError.assessmentNotFound
        }

        tests[index] = test
        assessment.functionalTests = tests

        return try await updateAssessment(assessment)
    }

    /// Remove a functional test from an assessment
    /// - Parameters:
    ///   - assessmentId: Assessment UUID
    ///   - testId: Functional test UUID to remove
    /// - Returns: Updated ClinicalAssessment
    func removeFunctionalTest(
        from assessmentId: UUID,
        testId: UUID
    ) async throws -> ClinicalAssessment {
        guard var assessment = try await fetchAssessment(id: assessmentId) else {
            throw ClinicalAssessmentError.assessmentNotFound
        }

        guard assessment.status.isEditable else {
            throw ClinicalAssessmentError.cannotEditSigned
        }

        assessment.functionalTests?.removeAll { $0.id == testId }

        return try await updateAssessment(assessment)
    }

    // MARK: - Pain Assessment

    /// Update pain assessment scores
    /// - Parameters:
    ///   - assessmentId: Assessment UUID
    ///   - painAtRest: Pain score at rest (0-10)
    ///   - painWithActivity: Pain score with activity (0-10)
    ///   - painWorst: Worst pain score (0-10)
    ///   - painLocations: Array of pain location strings
    /// - Returns: Updated ClinicalAssessment
    func updatePainAssessment(
        for assessmentId: UUID,
        painAtRest: Int?,
        painWithActivity: Int?,
        painWorst: Int?,
        painLocations: [String]?
    ) async throws -> ClinicalAssessment {
        guard var assessment = try await fetchAssessment(id: assessmentId) else {
            throw ClinicalAssessmentError.assessmentNotFound
        }

        guard assessment.status.isEditable else {
            throw ClinicalAssessmentError.cannotEditSigned
        }

        // Validate pain scores
        if let pain = painAtRest, !(0...10).contains(pain) {
            throw ClinicalAssessmentError.invalidPainScore("Pain at rest must be 0-10")
        }
        if let pain = painWithActivity, !(0...10).contains(pain) {
            throw ClinicalAssessmentError.invalidPainScore("Pain with activity must be 0-10")
        }
        if let pain = painWorst, !(0...10).contains(pain) {
            throw ClinicalAssessmentError.invalidPainScore("Worst pain must be 0-10")
        }

        assessment.painAtRest = painAtRest
        assessment.painWithActivity = painWithActivity
        assessment.painWorst = painWorst
        assessment.painLocations = painLocations

        return try await updateAssessment(assessment)
    }

    // MARK: - Status Management

    /// Mark assessment as complete
    /// - Parameter assessmentId: Assessment UUID
    /// - Returns: Updated ClinicalAssessment
    func completeAssessment(_ assessmentId: UUID) async throws -> ClinicalAssessment {
        guard var assessment = try await fetchAssessment(id: assessmentId) else {
            throw ClinicalAssessmentError.assessmentNotFound
        }

        guard assessment.status == .draft else {
            throw ClinicalAssessmentError.cannotEditSigned
        }

        assessment.status = .complete

        return try await updateAssessment(assessment)
    }

    /// Sign the assessment (locks it from further edits)
    /// - Parameter assessmentId: Assessment UUID
    /// - Returns: Updated ClinicalAssessment
    func signAssessment(_ assessmentId: UUID) async throws -> ClinicalAssessment {
        guard var assessment = try await fetchAssessment(id: assessmentId) else {
            throw ClinicalAssessmentError.assessmentNotFound
        }

        guard assessment.status == .complete else {
            throw ClinicalAssessmentError.missingRequiredFields
        }

        guard assessment.isReadyForSignature else {
            throw ClinicalAssessmentError.missingRequiredFields
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let now = Date()
            let updateData: [String: AnyEncodable] = [
                "status": AnyEncodable(AssessmentStatus.signed.rawValue),
                "signed_at": AnyEncodable(ISO8601DateFormatter().string(from: now)),
                "updated_at": AnyEncodable(ISO8601DateFormatter().string(from: now))
            ]

            let response = try await client.client
                .from("clinical_assessments")
                .update(updateData)
                .eq("id", value: assessmentId.uuidString)
                .select()
                .single()
                .execute()

            let decoder = createDecoder()
            let signedAssessment = try decoder.decode(ClinicalAssessment.self, from: response.data)

            #if DEBUG
            print("Clinical assessment signed: \(signedAssessment.id)")
            #endif

            currentAssessment = signedAssessment
            return signedAssessment
        } catch {
            DebugLogger.shared.error("ClinicalAssessmentService", "Error signing clinical assessment: \(error.localizedDescription)")
            self.error = error
            throw ClinicalAssessmentError.saveFailed
        }
    }

    // MARK: - Delete Assessment

    /// Delete an assessment (only drafts can be deleted)
    /// - Parameter assessmentId: Assessment UUID
    func deleteAssessment(_ assessmentId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }

        // Verify assessment exists and is deletable
        guard let assessment = try await fetchAssessment(id: assessmentId) else {
            throw ClinicalAssessmentError.assessmentNotFound
        }

        guard assessment.status == .draft else {
            throw ClinicalAssessmentError.cannotEditSigned
        }

        do {
            try await client.client
                .from("clinical_assessments")
                .delete()
                .eq("id", value: assessmentId.uuidString)
                .execute()

            #if DEBUG
            print("Clinical assessment deleted: \(assessmentId)")
            #endif

            if currentAssessment?.id == assessmentId {
                currentAssessment = nil
            }
        } catch {
            DebugLogger.shared.error("ClinicalAssessmentService", "Error deleting clinical assessment: \(error.localizedDescription)")
            self.error = error
            throw error
        }
    }

    // MARK: - Therapist Assessments

    /// Fetch all assessments by a therapist
    /// - Parameters:
    ///   - therapistId: Therapist UUID
    ///   - limit: Maximum number of records (default 50)
    /// - Returns: Array of assessments ordered by date descending
    func fetchAssessmentsByTherapist(
        _ therapistId: UUID,
        limit: Int = 50
    ) async throws -> [ClinicalAssessment] {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await client.client
                .from("clinical_assessments")
                .select()
                .eq("therapist_id", value: therapistId.uuidString)
                .order("assessment_date", ascending: false)
                .limit(limit)
                .execute()

            let decoder = createDecoder()
            return try decoder.decode([ClinicalAssessment].self, from: response.data)
        } catch {
            self.error = error
            throw ClinicalAssessmentError.fetchFailed
        }
    }

    /// Fetch pending (draft) assessments for a therapist
    /// - Parameter therapistId: Therapist UUID
    /// - Returns: Array of draft assessments
    func fetchPendingAssessments(for therapistId: UUID) async throws -> [ClinicalAssessment] {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await client.client
                .from("clinical_assessments")
                .select()
                .eq("therapist_id", value: therapistId.uuidString)
                .eq("status", value: AssessmentStatus.draft.rawValue)
                .order("assessment_date", ascending: false)
                .execute()

            let decoder = createDecoder()
            return try decoder.decode([ClinicalAssessment].self, from: response.data)
        } catch {
            self.error = error
            throw ClinicalAssessmentError.fetchFailed
        }
    }

    // MARK: - Private Methods

    /// Create decoder for clinical assessments
    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with fractional seconds
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // Try ISO8601 without fractional seconds
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // Try DATE format (YYYY-MM-DD)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(dateString)"
            )
        }
        return decoder
    }
}

// MARK: - Convenience Extensions

extension ClinicalAssessmentService {
    /// Check if a patient has any completed assessments
    /// - Parameter patientId: Patient UUID
    /// - Returns: True if at least one completed assessment exists
    func hasCompletedAssessments(patientId: UUID) async -> Bool {
        do {
            let assessments = try await fetchAssessments(for: patientId, limit: 1)
            return assessments.contains { $0.status != .draft }
        } catch {
            return false
        }
    }

    /// Get the most recent intake assessment for a patient
    /// - Parameter patientId: Patient UUID
    /// - Returns: Most recent intake assessment or nil
    func getLatestIntakeAssessment(for patientId: UUID) async throws -> ClinicalAssessment? {
        let assessments = try await fetchAssessments(for: patientId, type: .intake, limit: 1)
        return assessments.first
    }

    /// Get comprehensive assessment summary for a patient
    /// - Parameter patientId: Patient UUID
    /// - Returns: Summary including latest assessment and ROM statistics
    func getAssessmentSummary(for patientId: UUID) async throws -> ClinicalAssessmentSummary {
        async let latestAssessment = fetchLatestAssessment(for: patientId)
        async let allAssessments = fetchAssessments(for: patientId, limit: 10)

        let latest = try await latestAssessment
        let assessments = try await allAssessments

        return ClinicalAssessmentSummary(
            latestAssessment: latest,
            totalAssessments: assessments.count,
            draftCount: assessments.filter { $0.status == .draft }.count,
            signedCount: assessments.filter { $0.status == .signed }.count
        )
    }
}

// MARK: - Assessment Summary

/// Summary of patient's clinical assessments
struct ClinicalAssessmentSummary {
    let latestAssessment: ClinicalAssessment?
    let totalAssessments: Int
    let draftCount: Int
    let signedCount: Int

    var hasAssessments: Bool {
        totalAssessments > 0
    }

    var hasPendingDrafts: Bool {
        draftCount > 0
    }

    var currentStatus: AssessmentStatus? {
        latestAssessment?.status
    }

    var averagePainScore: Double? {
        latestAssessment?.averagePainScore
    }

    var romLimitationsCount: Int {
        latestAssessment?.romLimitationsCount ?? 0
    }
}

// MARK: - AnyEncodable Helper

/// Type-erased Encodable wrapper for dynamic dictionary encoding
private struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
