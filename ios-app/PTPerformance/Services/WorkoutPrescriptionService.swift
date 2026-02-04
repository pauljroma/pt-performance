//
//  WorkoutPrescriptionService.swift
//  PTPerformance
//
//  Service for managing workout prescriptions
//

import Foundation

/// Service for therapist workout prescriptions
class WorkoutPrescriptionService {
    private let supabase: PTSupabaseClient

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    // MARK: - Therapist Methods

    /// Create a new prescription for a patient
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

        let response = try await supabase.client
            .from("workout_prescriptions")
            .insert(dto)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(WorkoutPrescription.self, from: response.data)
    }

    /// Fetch prescriptions created by therapist
    func fetchTherapistPrescriptions(therapistId: UUID) async throws -> [WorkoutPrescription] {
        let response = try await supabase.client
            .from("workout_prescriptions")
            .select()
            .eq("therapist_id", value: therapistId.uuidString)
            .order("prescribed_at", ascending: false)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([WorkoutPrescription].self, from: response.data)
    }

    /// Fetch prescriptions for a specific patient (therapist view)
    func fetchPatientPrescriptions(patientId: UUID) async throws -> [WorkoutPrescription] {
        let response = try await supabase.client
            .from("workout_prescriptions")
            .select()
            .eq("patient_id", value: patientId.uuidString)
            .order("due_date", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([WorkoutPrescription].self, from: response.data)
    }

    /// Cancel a prescription
    func cancelPrescription(_ prescriptionId: UUID) async throws {
        try await supabase.client
            .from("workout_prescriptions")
            .update(["status": "cancelled"])
            .eq("id", value: prescriptionId.uuidString)
            .execute()
    }

    // MARK: - Therapist Dashboard Methods

    /// Fetch all prescriptions for therapist's patients with compliance data
    /// Used by the therapist prescription dashboard for tracking patient compliance
    func fetchTherapistDashboardPrescriptions(therapistId: UUID) async throws -> [WorkoutPrescription] {
        // Fetch prescriptions for all patients assigned to this therapist
        // Join through patients table to ensure HIPAA compliance (only therapist's patients)
        let response = try await supabase.client
            .from("workout_prescriptions")
            .select("*, patient:patients!inner(therapist_id)")
            .eq("patient.therapist_id", value: therapistId.uuidString)
            .order("due_date", ascending: true)
            .order("prescribed_at", ascending: false)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Handle empty response
        if let jsonString = String(data: response.data, encoding: .utf8),
           jsonString == "[]" || jsonString.isEmpty {
            return []
        }

        return try decoder.decode([WorkoutPrescription].self, from: response.data)
    }

    /// Fetch active prescriptions (pending, viewed, started) for therapist's patients
    func fetchActivePrescriptions(therapistId: UUID) async throws -> [WorkoutPrescription] {
        let response = try await supabase.client
            .from("workout_prescriptions")
            .select("*, patient:patients!inner(therapist_id)")
            .eq("patient.therapist_id", value: therapistId.uuidString)
            .in("status", values: ["pending", "viewed", "started"])
            .order("due_date", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([WorkoutPrescription].self, from: response.data)
    }

    /// Fetch overdue prescriptions for therapist's patients
    func fetchOverduePrescriptions(therapistId: UUID) async throws -> [WorkoutPrescription] {
        let now = ISO8601DateFormatter().string(from: Date())

        let response = try await supabase.client
            .from("workout_prescriptions")
            .select("*, patient:patients!inner(therapist_id)")
            .eq("patient.therapist_id", value: therapistId.uuidString)
            .in("status", values: ["pending", "viewed", "started"])
            .lt("due_date", value: now)
            .order("due_date", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([WorkoutPrescription].self, from: response.data)
    }

    /// Fetch recently completed prescriptions (last N days)
    func fetchRecentlyCompletedPrescriptions(therapistId: UUID, daysBack: Int = 7) async throws -> [WorkoutPrescription] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -daysBack, to: Date()) else {
            return []
        }
        let startDateString = ISO8601DateFormatter().string(from: startDate)

        let response = try await supabase.client
            .from("workout_prescriptions")
            .select("*, patient:patients!inner(therapist_id)")
            .eq("patient.therapist_id", value: therapistId.uuidString)
            .eq("status", value: "completed")
            .gte("completed_at", value: startDateString)
            .order("completed_at", ascending: false)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([WorkoutPrescription].self, from: response.data)
    }

    /// Fetch prescriptions due within a date range
    func fetchPrescriptionsDueInRange(therapistId: UUID, startDate: Date, endDate: Date) async throws -> [WorkoutPrescription] {
        let formatter = ISO8601DateFormatter()
        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: endDate)

        let response = try await supabase.client
            .from("workout_prescriptions")
            .select("*, patient:patients!inner(therapist_id)")
            .eq("patient.therapist_id", value: therapistId.uuidString)
            .gte("due_date", value: startString)
            .lte("due_date", value: endString)
            .in("status", values: ["pending", "viewed", "started"])
            .order("due_date", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([WorkoutPrescription].self, from: response.data)
    }

    /// Get compliance statistics for a specific patient
    func fetchPatientComplianceStats(patientId: UUID) async throws -> PatientPrescriptionStats {
        let response = try await supabase.client
            .from("workout_prescriptions")
            .select()
            .eq("patient_id", value: patientId.uuidString)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let prescriptions = try decoder.decode([WorkoutPrescription].self, from: response.data)

        return PatientPrescriptionStats(prescriptions: prescriptions)
    }

    /// Extend the due date of a prescription
    func extendPrescriptionDueDate(_ prescriptionId: UUID, newDueDate: Date) async throws {
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: newDueDate)

        try await supabase.client
            .from("workout_prescriptions")
            .update(["due_date": dateString])
            .eq("id", value: prescriptionId.uuidString)
            .execute()

        DebugLogger.shared.log("Extended prescription \(prescriptionId) due date to \(dateString)", level: .success)
    }

    /// Bulk update prescription status (for admin operations)
    func bulkUpdateStatus(prescriptionIds: [UUID], newStatus: PrescriptionStatus) async throws {
        let idStrings = prescriptionIds.map { $0.uuidString }

        try await supabase.client
            .from("workout_prescriptions")
            .update(["status": newStatus.rawValue])
            .in("id", values: idStrings)
            .execute()

        DebugLogger.shared.log("Bulk updated \(prescriptionIds.count) prescriptions to status: \(newStatus.rawValue)", level: .success)
    }

    // MARK: - Patient Methods

    /// Fetch pending prescriptions for patient
    func fetchMyPrescriptions(patientId: UUID) async throws -> [WorkoutPrescription] {
        let response = try await supabase.client
            .from("workout_prescriptions")
            .select()
            .eq("patient_id", value: patientId.uuidString)
            .in("status", values: ["pending", "viewed"])
            .order("due_date", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([WorkoutPrescription].self, from: response.data)
    }

    /// Mark prescription as viewed
    func markAsViewed(_ prescriptionId: UUID) async throws {
        let now = ISO8601DateFormatter().string(from: Date())
        try await supabase.client
            .from("workout_prescriptions")
            .update(["status": "viewed", "viewed_at": now])
            .eq("id", value: prescriptionId.uuidString)
            .eq("status", value: "pending")
            .execute()
    }

    /// Mark prescription as started and link to session
    func markAsStarted(_ prescriptionId: UUID, sessionId: UUID) async throws {
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
    }

    /// Mark prescription as completed
    func markAsCompleted(_ prescriptionId: UUID) async throws {
        let now = ISO8601DateFormatter().string(from: Date())
        try await supabase.client
            .from("workout_prescriptions")
            .update(["status": "completed", "completed_at": now])
            .eq("id", value: prescriptionId.uuidString)
            .execute()
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
