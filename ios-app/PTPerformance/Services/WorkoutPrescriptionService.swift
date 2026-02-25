//
//  WorkoutPrescriptionService.swift
//  PTPerformance
//
//  Service for managing workout prescriptions.
//  Provides CRUD operations for therapist-assigned workout prescriptions
//  with compliance tracking and deadline management.
//

import Foundation

/// Service for therapist workout prescriptions.
///
/// Manages the full lifecycle of workout prescriptions from creation through
/// completion, including compliance tracking and overdue monitoring.
///
/// ## Thread Safety
/// All methods are async and safe to call from any context.
///
/// ## Error Handling
/// All database operations use proper do/catch with ErrorLogger integration.
/// Errors are re-thrown to allow caller handling.
class WorkoutPrescriptionService {
    private let supabase: PTSupabaseClient
    private let logger = DebugLogger.shared
    private let errorLogger = ErrorLogger.shared

    /// Initialize with a Supabase client.
    /// - Parameter supabase: The Supabase client to use (defaults to shared instance)
    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    // MARK: - Therapist Methods

    /// Create a new prescription for a patient.
    ///
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - therapistId: The therapist's UUID
    ///   - templateId: Optional template UUID the prescription is based on
    ///   - templateType: Optional template type identifier
    ///   - name: Display name for the prescription
    ///   - instructions: Optional instructions for the patient
    ///   - dueDate: Optional deadline for completion
    ///   - priority: Priority level (defaults to medium)
    /// - Returns: The created WorkoutPrescription
    /// - Throws: Database errors if the insert fails
    func createPrescription(
        patientId: UUID,
        therapistId: UUID,
        templateId: UUID?,
        templateType: String?,
        name: String,
        instructions: String?,
        dueDate: Date?,
        priority: PrescriptionPriority = .medium
    ) async throws -> WorkoutPrescription {
        logger.log("[WorkoutPrescriptionService] Creating prescription '\(name)' for patient: \(patientId)", level: .diagnostic)

        let dto = CreatePrescriptionDTO(
            patientId: patientId,
            therapistId: therapistId,
            templateId: templateId,
            templateType: templateType,
            name: name,
            instructions: instructions,
            dueDate: dueDate,
            priority: priority.rawValue
        )

        do {
            let response = try await supabase.client
                .from("workout_prescriptions")
                .insert(dto)
                .select()
                .single()
                .execute()

            let prescription = try PTSupabaseClient.flexibleDecoder.decode(WorkoutPrescription.self, from: response.data)

            logger.log("[WorkoutPrescriptionService] Prescription created with ID: \(prescription.id)", level: .success)
            return prescription
        } catch {
            errorLogger.logError(error, context: "WorkoutPrescriptionService.createPrescription", metadata: [
                "patient_id": patientId.uuidString,
                "therapist_id": therapistId.uuidString,
                "name": name
            ])
            throw error
        }
    }

    /// Fetch prescriptions created by therapist.
    ///
    /// - Parameter therapistId: The therapist's UUID
    /// - Returns: Array of prescriptions, ordered by prescribed date (newest first)
    /// - Throws: Database errors if the query fails
    func fetchTherapistPrescriptions(therapistId: UUID) async throws -> [WorkoutPrescription] {
        logger.log("[WorkoutPrescriptionService] Fetching prescriptions for therapist: \(therapistId)", level: .diagnostic)

        do {
            let response = try await supabase.client
                .from("workout_prescriptions")
                .select()
                .eq("therapist_id", value: therapistId.uuidString)
                .order("prescribed_at", ascending: false)
                .execute()

            let prescriptions = try PTSupabaseClient.flexibleDecoder.decode([WorkoutPrescription].self, from: response.data)

            logger.log("[WorkoutPrescriptionService] Fetched \(prescriptions.count) prescriptions", level: .success)
            return prescriptions
        } catch {
            errorLogger.logError(error, context: "WorkoutPrescriptionService.fetchTherapistPrescriptions", metadata: [
                "therapist_id": therapistId.uuidString
            ])
            throw error
        }
    }

    /// Fetch prescriptions for a specific patient (therapist view).
    ///
    /// - Parameter patientId: The patient's UUID
    /// - Returns: Array of prescriptions, ordered by due date (soonest first)
    /// - Throws: Database errors if the query fails
    func fetchPatientPrescriptions(patientId: UUID) async throws -> [WorkoutPrescription] {
        logger.log("[WorkoutPrescriptionService] Fetching prescriptions for patient: \(patientId)", level: .diagnostic)

        do {
            let response = try await supabase.client
                .from("workout_prescriptions")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .order("due_date", ascending: true)
                .execute()

            let prescriptions = try PTSupabaseClient.flexibleDecoder.decode([WorkoutPrescription].self, from: response.data)

            logger.log("[WorkoutPrescriptionService] Fetched \(prescriptions.count) patient prescriptions", level: .success)
            return prescriptions
        } catch {
            errorLogger.logError(error, context: "WorkoutPrescriptionService.fetchPatientPrescriptions", metadata: [
                "patient_id": patientId.uuidString
            ])
            throw error
        }
    }

    /// Cancel a prescription.
    ///
    /// Sets the prescription status to 'cancelled'. This action cannot be undone.
    ///
    /// - Parameter prescriptionId: The prescription's UUID
    /// - Throws: Database errors if the update fails
    func cancelPrescription(_ prescriptionId: UUID) async throws {
        logger.log("[WorkoutPrescriptionService] Cancelling prescription: \(prescriptionId)", level: .diagnostic)

        do {
            try await supabase.client
                .from("workout_prescriptions")
                .update(["status": "cancelled"])
                .eq("id", value: prescriptionId.uuidString)
                .execute()

            logger.log("[WorkoutPrescriptionService] Prescription cancelled successfully", level: .success)
        } catch {
            errorLogger.logError(error, context: "WorkoutPrescriptionService.cancelPrescription", metadata: [
                "prescription_id": prescriptionId.uuidString
            ])
            throw error
        }
    }

    // MARK: - Therapist Dashboard Methods

    /// Fetch all prescriptions for therapist's patients with compliance data.
    ///
    /// Used by the therapist prescription dashboard for tracking patient compliance.
    /// Joins through patients table to ensure HIPAA compliance (only therapist's patients).
    ///
    /// - Parameter therapistId: The therapist's UUID
    /// - Returns: Array of prescriptions for all assigned patients, empty if none found
    /// - Throws: Database errors if the query fails
    func fetchTherapistDashboardPrescriptions(therapistId: UUID) async throws -> [WorkoutPrescription] {
        logger.log("[WorkoutPrescriptionService] Fetching dashboard prescriptions for therapist: \(therapistId)", level: .diagnostic)

        do {
            let response = try await supabase.client
                .from("workout_prescriptions")
                .select("*, patient:patients!inner(therapist_id)")
                .eq("patient.therapist_id", value: therapistId.uuidString)
                .order("due_date", ascending: true)
                .order("prescribed_at", ascending: false)
                .execute()

            // Handle empty response gracefully
            guard let jsonString = String(data: response.data, encoding: .utf8),
                  !jsonString.isEmpty && jsonString != "[]" else {
                logger.log("[WorkoutPrescriptionService] No dashboard prescriptions found", level: .info)
                return []
            }

            let prescriptions = try PTSupabaseClient.flexibleDecoder.decode([WorkoutPrescription].self, from: response.data)
            logger.log("[WorkoutPrescriptionService] Fetched \(prescriptions.count) dashboard prescriptions", level: .success)
            return prescriptions
        } catch {
            errorLogger.logError(error, context: "WorkoutPrescriptionService.fetchTherapistDashboardPrescriptions", metadata: [
                "therapist_id": therapistId.uuidString
            ])
            throw error
        }
    }

    /// Fetch active prescriptions (pending, viewed, started) for therapist's patients.
    ///
    /// - Parameter therapistId: The therapist's UUID
    /// - Returns: Array of active prescriptions, ordered by due date
    /// - Throws: Database errors if the query fails
    func fetchActivePrescriptions(therapistId: UUID) async throws -> [WorkoutPrescription] {
        logger.log("[WorkoutPrescriptionService] Fetching active prescriptions for therapist: \(therapistId)", level: .diagnostic)

        do {
            let response = try await supabase.client
                .from("workout_prescriptions")
                .select("*, patient:patients!inner(therapist_id)")
                .eq("patient.therapist_id", value: therapistId.uuidString)
                .in("status", values: ["pending", "viewed", "started"])
                .order("due_date", ascending: true)
                .execute()

            let prescriptions = try PTSupabaseClient.flexibleDecoder.decode([WorkoutPrescription].self, from: response.data)

            logger.log("[WorkoutPrescriptionService] Fetched \(prescriptions.count) active prescriptions", level: .success)
            return prescriptions
        } catch {
            errorLogger.logError(error, context: "WorkoutPrescriptionService.fetchActivePrescriptions", metadata: [
                "therapist_id": therapistId.uuidString
            ])
            throw error
        }
    }

    /// Fetch overdue prescriptions for therapist's patients.
    ///
    /// - Parameter therapistId: The therapist's UUID
    /// - Returns: Array of overdue prescriptions, ordered by due date (oldest first)
    /// - Throws: Database errors if the query fails
    func fetchOverduePrescriptions(therapistId: UUID) async throws -> [WorkoutPrescription] {
        logger.log("[WorkoutPrescriptionService] Fetching overdue prescriptions for therapist: \(therapistId)", level: .diagnostic)

        do {
            let now = ISO8601DateFormatter().string(from: Date())

            let response = try await supabase.client
                .from("workout_prescriptions")
                .select("*, patient:patients!inner(therapist_id)")
                .eq("patient.therapist_id", value: therapistId.uuidString)
                .in("status", values: ["pending", "viewed", "started"])
                .lt("due_date", value: now)
                .order("due_date", ascending: true)
                .execute()

            let prescriptions = try PTSupabaseClient.flexibleDecoder.decode([WorkoutPrescription].self, from: response.data)

            logger.log("[WorkoutPrescriptionService] Fetched \(prescriptions.count) overdue prescriptions", level: .success)
            return prescriptions
        } catch {
            errorLogger.logError(error, context: "WorkoutPrescriptionService.fetchOverduePrescriptions", metadata: [
                "therapist_id": therapistId.uuidString
            ])
            throw error
        }
    }

    /// Fetch recently completed prescriptions (last N days).
    ///
    /// - Parameters:
    ///   - therapistId: The therapist's UUID
    ///   - daysBack: Number of days to look back (default: 7)
    /// - Returns: Array of completed prescriptions, ordered by completion date (newest first)
    /// - Throws: Database errors if the query fails
    func fetchRecentlyCompletedPrescriptions(therapistId: UUID, daysBack: Int = 7) async throws -> [WorkoutPrescription] {
        logger.log("[WorkoutPrescriptionService] Fetching recently completed prescriptions (last \(daysBack) days)", level: .diagnostic)

        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -daysBack, to: Date()) else {
            logger.log("[WorkoutPrescriptionService] Failed to calculate start date, returning empty", level: .warning)
            return []
        }
        let startDateString = ISO8601DateFormatter().string(from: startDate)

        do {
            let response = try await supabase.client
                .from("workout_prescriptions")
                .select("*, patient:patients!inner(therapist_id)")
                .eq("patient.therapist_id", value: therapistId.uuidString)
                .eq("status", value: "completed")
                .gte("completed_at", value: startDateString)
                .order("completed_at", ascending: false)
                .execute()

            let prescriptions = try PTSupabaseClient.flexibleDecoder.decode([WorkoutPrescription].self, from: response.data)

            logger.log("[WorkoutPrescriptionService] Fetched \(prescriptions.count) recently completed prescriptions", level: .success)
            return prescriptions
        } catch {
            errorLogger.logError(error, context: "WorkoutPrescriptionService.fetchRecentlyCompletedPrescriptions", metadata: [
                "therapist_id": therapistId.uuidString,
                "days_back": String(daysBack)
            ])
            throw error
        }
    }

    /// Fetch prescriptions due within a date range.
    ///
    /// - Parameters:
    ///   - therapistId: The therapist's UUID
    ///   - startDate: Start of the date range (inclusive)
    ///   - endDate: End of the date range (inclusive)
    /// - Returns: Array of prescriptions due within the range
    /// - Throws: Database errors if the query fails
    func fetchPrescriptionsDueInRange(therapistId: UUID, startDate: Date, endDate: Date) async throws -> [WorkoutPrescription] {
        let formatter = ISO8601DateFormatter()
        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: endDate)

        logger.log("[WorkoutPrescriptionService] Fetching prescriptions due between \(startString) and \(endString)", level: .diagnostic)

        do {
            let response = try await supabase.client
                .from("workout_prescriptions")
                .select("*, patient:patients!inner(therapist_id)")
                .eq("patient.therapist_id", value: therapistId.uuidString)
                .gte("due_date", value: startString)
                .lte("due_date", value: endString)
                .in("status", values: ["pending", "viewed", "started"])
                .order("due_date", ascending: true)
                .execute()

            let prescriptions = try PTSupabaseClient.flexibleDecoder.decode([WorkoutPrescription].self, from: response.data)

            logger.log("[WorkoutPrescriptionService] Fetched \(prescriptions.count) prescriptions in date range", level: .success)
            return prescriptions
        } catch {
            errorLogger.logError(error, context: "WorkoutPrescriptionService.fetchPrescriptionsDueInRange", metadata: [
                "therapist_id": therapistId.uuidString,
                "start_date": startString,
                "end_date": endString
            ])
            throw error
        }
    }

    /// Get compliance statistics for a specific patient.
    ///
    /// - Parameter patientId: The patient's UUID
    /// - Returns: Compliance statistics including completion rate and overdue count
    /// - Throws: Database errors if the query fails
    func fetchPatientComplianceStats(patientId: UUID) async throws -> PatientPrescriptionStats {
        logger.log("[WorkoutPrescriptionService] Fetching compliance stats for patient: \(patientId)", level: .diagnostic)

        do {
            let response = try await supabase.client
                .from("workout_prescriptions")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .execute()

            let prescriptions = try PTSupabaseClient.flexibleDecoder.decode([WorkoutPrescription].self, from: response.data)

            let stats = PatientPrescriptionStats(prescriptions: prescriptions)
            logger.log("[WorkoutPrescriptionService] Compliance rate: \(String(format: "%.1f", stats.complianceRate))%", level: .success)
            return stats
        } catch {
            errorLogger.logError(error, context: "WorkoutPrescriptionService.fetchPatientComplianceStats", metadata: [
                "patient_id": patientId.uuidString
            ])
            throw error
        }
    }

    /// Extend the due date of a prescription.
    ///
    /// - Parameters:
    ///   - prescriptionId: The prescription's UUID
    ///   - newDueDate: The new due date
    /// - Throws: Database errors if the update fails
    func extendPrescriptionDueDate(_ prescriptionId: UUID, newDueDate: Date) async throws {
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: newDueDate)

        logger.log("[WorkoutPrescriptionService] Extending due date for prescription: \(prescriptionId)", level: .diagnostic)

        do {
            try await supabase.client
                .from("workout_prescriptions")
                .update(["due_date": dateString])
                .eq("id", value: prescriptionId.uuidString)
                .execute()

            logger.log("[WorkoutPrescriptionService] Extended prescription due date to \(dateString)", level: .success)
        } catch {
            errorLogger.logError(error, context: "WorkoutPrescriptionService.extendPrescriptionDueDate", metadata: [
                "prescription_id": prescriptionId.uuidString,
                "new_due_date": dateString
            ])
            throw error
        }
    }

    /// Bulk update prescription status (for admin operations).
    ///
    /// - Parameters:
    ///   - prescriptionIds: Array of prescription UUIDs to update
    ///   - newStatus: The new status to apply
    /// - Throws: Database errors if the update fails
    func bulkUpdateStatus(prescriptionIds: [UUID], newStatus: PrescriptionStatus) async throws {
        guard !prescriptionIds.isEmpty else {
            logger.log("[WorkoutPrescriptionService] No prescription IDs provided for bulk update", level: .warning)
            return
        }

        let idStrings = prescriptionIds.map { $0.uuidString }

        logger.log("[WorkoutPrescriptionService] Bulk updating \(prescriptionIds.count) prescriptions to status: \(newStatus.rawValue)", level: .diagnostic)

        do {
            try await supabase.client
                .from("workout_prescriptions")
                .update(["status": newStatus.rawValue])
                .in("id", values: idStrings)
                .execute()

            logger.log("[WorkoutPrescriptionService] Bulk updated \(prescriptionIds.count) prescriptions successfully", level: .success)
        } catch {
            errorLogger.logError(error, context: "WorkoutPrescriptionService.bulkUpdateStatus", metadata: [
                "count": String(prescriptionIds.count),
                "new_status": newStatus.rawValue
            ])
            throw error
        }
    }

    // MARK: - Patient Methods

    /// Fetch pending prescriptions for patient.
    ///
    /// Returns prescriptions that the patient needs to view or complete.
    ///
    /// - Parameter patientId: The patient's UUID
    /// - Returns: Array of pending/viewed prescriptions, ordered by due date
    /// - Throws: Database errors if the query fails
    func fetchMyPrescriptions(patientId: UUID) async throws -> [WorkoutPrescription] {
        logger.log("[WorkoutPrescriptionService] Fetching my prescriptions for patient: \(patientId)", level: .diagnostic)

        do {
            let response = try await supabase.client
                .from("workout_prescriptions")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .in("status", values: ["pending", "viewed"])
                .order("due_date", ascending: true)
                .execute()

            let prescriptions = try PTSupabaseClient.flexibleDecoder.decode([WorkoutPrescription].self, from: response.data)

            logger.log("[WorkoutPrescriptionService] Fetched \(prescriptions.count) pending prescriptions", level: .success)
            return prescriptions
        } catch {
            errorLogger.logError(error, context: "WorkoutPrescriptionService.fetchMyPrescriptions", metadata: [
                "patient_id": patientId.uuidString
            ])
            throw error
        }
    }

    /// Mark prescription as viewed.
    ///
    /// Only updates if the current status is 'pending' to prevent race conditions.
    ///
    /// - Parameter prescriptionId: The prescription's UUID
    /// - Throws: Database errors if the update fails
    func markAsViewed(_ prescriptionId: UUID) async throws {
        logger.log("[WorkoutPrescriptionService] Marking prescription as viewed: \(prescriptionId)", level: .diagnostic)

        do {
            let now = ISO8601DateFormatter().string(from: Date())
            try await supabase.client
                .from("workout_prescriptions")
                .update(["status": "viewed", "viewed_at": now])
                .eq("id", value: prescriptionId.uuidString)
                .eq("status", value: "pending")
                .execute()

            logger.log("[WorkoutPrescriptionService] Prescription marked as viewed", level: .success)
        } catch {
            errorLogger.logError(error, context: "WorkoutPrescriptionService.markAsViewed", metadata: [
                "prescription_id": prescriptionId.uuidString
            ])
            throw error
        }
    }

    /// Mark prescription as started and link to session.
    ///
    /// - Parameters:
    ///   - prescriptionId: The prescription's UUID
    ///   - sessionId: The manual session UUID linked to this prescription
    /// - Throws: Database errors if the update fails
    func markAsStarted(_ prescriptionId: UUID, sessionId: UUID) async throws {
        logger.log("[WorkoutPrescriptionService] Marking prescription as started: \(prescriptionId)", level: .diagnostic)

        do {
            let now = ISO8601DateFormatter().string(from: Date())
            try await supabase.client
                .from("workout_prescriptions")
                .update([
                    "status": "started",
                    "started_at": now,
                    "manual_session_id": sessionId.uuidString
                ])
                .eq("id", value: prescriptionId.uuidString)
                .execute()

            logger.log("[WorkoutPrescriptionService] Prescription started with session: \(sessionId)", level: .success)
        } catch {
            errorLogger.logError(error, context: "WorkoutPrescriptionService.markAsStarted", metadata: [
                "prescription_id": prescriptionId.uuidString,
                "session_id": sessionId.uuidString
            ])
            throw error
        }
    }

    /// Mark prescription as completed.
    ///
    /// - Parameter prescriptionId: The prescription's UUID
    /// - Throws: Database errors if the update fails
    func markAsCompleted(_ prescriptionId: UUID) async throws {
        logger.log("[WorkoutPrescriptionService] Marking prescription as completed: \(prescriptionId)", level: .diagnostic)

        do {
            let now = ISO8601DateFormatter().string(from: Date())
            try await supabase.client
                .from("workout_prescriptions")
                .update(["status": "completed", "completed_at": now])
                .eq("id", value: prescriptionId.uuidString)
                .execute()

            logger.log("[WorkoutPrescriptionService] Prescription completed successfully", level: .success)
        } catch {
            errorLogger.logError(error, context: "WorkoutPrescriptionService.markAsCompleted", metadata: [
                "prescription_id": prescriptionId.uuidString
            ])
            throw error
        }
    }
}

// MARK: - Patient Prescription Stats

/// Statistics for a patient's prescription compliance
struct PatientPrescriptionStats {
    let totalPrescriptions: Int
    let completedPrescriptions: Int
    let activePrescriptions: Int
    let overduePrescriptions: Int
    let complianceRate: Double

    init(prescriptions: [WorkoutPrescription]) {
        let nonCancelled = prescriptions.filter { $0.status != .cancelled }
        self.totalPrescriptions = nonCancelled.count
        self.completedPrescriptions = nonCancelled.filter { $0.status == .completed }.count
        self.activePrescriptions = nonCancelled.filter {
            $0.status == .pending || $0.status == .viewed || $0.status == .started
        }.count
        self.overduePrescriptions = nonCancelled.filter { $0.isOverdue }.count

        if totalPrescriptions > 0 {
            self.complianceRate = Double(completedPrescriptions) / Double(totalPrescriptions) * 100
        } else {
            self.complianceRate = 0
        }
    }
}
