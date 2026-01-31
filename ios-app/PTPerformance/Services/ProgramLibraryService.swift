//
//  ProgramLibraryService.swift
//  PTPerformance
//
//  Service for managing program library browsing and enrollments
//

import Foundation
import Supabase

// MARK: - Input Models

/// Input for creating a program enrollment
struct CreateEnrollmentInput: Codable {
    let patientId: UUID
    let programLibraryId: UUID
    let status: String
    let progressPercentage: Int

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case programLibraryId = "program_library_id"
        case status
        case progressPercentage = "progress_percentage"
    }
}

/// Input for updating enrollment progress
struct UpdateProgressInput: Codable {
    let progressPercentage: Int

    enum CodingKeys: String, CodingKey {
        case progressPercentage = "progress_percentage"
    }
}

/// Input for updating enrollment status
struct UpdateStatusInput: Codable {
    let status: String
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case status
        case completedAt = "completed_at"
    }
}

// MARK: - Service

/// Service for managing program library browsing and enrollments
class ProgramLibraryService: ObservableObject {
    private let supabase: PTSupabaseClient

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    // MARK: - Fetch Programs

    /// Fetch all programs, optionally filtered by category, difficulty, or search term
    func fetchPrograms(
        category: String? = nil,
        difficulty: String? = nil,
        search: String? = nil
    ) async throws -> [ProgramLibrary] {
        let logger = DebugLogger.shared
        logger.log("Fetching programs with filters - category: \(category ?? "nil"), difficulty: \(difficulty ?? "nil"), search: \(search ?? "nil")", level: .diagnostic)

        var query = supabase.client
            .from("program_library")
            .select()

        if let category = category, !category.isEmpty {
            query = query.eq("category", value: category)
        }

        if let difficulty = difficulty, !difficulty.isEmpty {
            query = query.eq("difficulty_level", value: difficulty)
        }

        if let search = search, !search.isEmpty {
            query = query.ilike("title", pattern: "%\(search)%")
        }

        do {
            let response = try await query
                .order("title", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let programs = try decoder.decode([ProgramLibrary].self, from: response.data)

            logger.log("Fetched \(programs.count) programs", level: .success)
            return programs
        } catch {
            logger.log("Failed to fetch programs: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    /// Fetch featured programs
    func fetchFeaturedPrograms() async throws -> [ProgramLibrary] {
        let logger = DebugLogger.shared
        logger.log("Fetching featured programs...", level: .diagnostic)

        do {
            let response = try await supabase.client
                .from("program_library")
                .select()
                .eq("is_featured", value: true)
                .order("title", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let programs = try decoder.decode([ProgramLibrary].self, from: response.data)

            logger.log("Fetched \(programs.count) featured programs", level: .success)
            return programs
        } catch {
            logger.log("Failed to fetch featured programs: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    /// Fetch programs by category (e.g., for "Annuals" section)
    func fetchProgramsByCategory(_ category: String) async throws -> [ProgramLibrary] {
        let logger = DebugLogger.shared
        logger.log("Fetching programs for category: \(category)", level: .diagnostic)

        do {
            let response = try await supabase.client
                .from("program_library")
                .select()
                .eq("category", value: category)
                .order("title", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let programs = try decoder.decode([ProgramLibrary].self, from: response.data)

            logger.log("Fetched \(programs.count) programs for category '\(category)'", level: .success)
            return programs
        } catch {
            logger.log("Failed to fetch programs by category: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    // MARK: - Enrollments

    /// Enroll a patient in a program
    func enrollInProgram(patientId: String, programLibraryId: UUID) async throws -> ProgramEnrollment {
        let logger = DebugLogger.shared
        logger.log("Enrolling patient \(patientId) in program \(programLibraryId)", level: .diagnostic)

        guard let patientUUID = UUID(uuidString: patientId) else {
            logger.log("Invalid patient ID format: \(patientId)", level: .error)
            throw NSError(domain: "ProgramLibraryService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid patient ID format"])
        }

        let input = CreateEnrollmentInput(
            patientId: patientUUID,
            programLibraryId: programLibraryId,
            status: "active",
            progressPercentage: 0
        )

        do {
            let response = try await supabase.client
                .from("program_enrollments")
                .insert(input)
                .select()
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let enrollment = try decoder.decode(ProgramEnrollment.self, from: response.data)

            logger.log("Successfully enrolled in program with enrollment ID: \(enrollment.id)", level: .success)
            return enrollment
        } catch {
            logger.log("Failed to enroll in program: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    /// Get a patient's enrolled programs with optional status filter
    func getEnrolledPrograms(patientId: String, status: String? = nil) async throws -> [ProgramEnrollment] {
        let logger = DebugLogger.shared
        logger.log("Fetching enrolled programs for patient: \(patientId), status: \(status ?? "all")", level: .diagnostic)

        var query = supabase.client
            .from("program_enrollments")
            .select()
            .eq("patient_id", value: patientId)

        if let status = status, !status.isEmpty {
            query = query.eq("status", value: status)
        }

        do {
            let response = try await query
                .order("enrolled_at", ascending: false)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let enrollments = try decoder.decode([ProgramEnrollment].self, from: response.data)

            logger.log("Fetched \(enrollments.count) enrolled programs", level: .success)
            return enrollments
        } catch {
            logger.log("Failed to fetch enrolled programs: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    /// Update enrollment progress
    func updateProgress(enrollmentId: UUID, progress: Int) async throws {
        let logger = DebugLogger.shared
        logger.log("Updating progress for enrollment \(enrollmentId) to \(progress)%", level: .diagnostic)

        let clampedProgress = max(0, min(100, progress))
        let input = UpdateProgressInput(progressPercentage: clampedProgress)

        do {
            try await supabase.client
                .from("program_enrollments")
                .update(input)
                .eq("id", value: enrollmentId.uuidString)
                .execute()

            logger.log("Progress updated successfully to \(clampedProgress)%", level: .success)
        } catch {
            logger.log("Failed to update progress: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    /// Cancel or pause enrollment (update status)
    func updateEnrollmentStatus(enrollmentId: UUID, status: String) async throws {
        let logger = DebugLogger.shared
        logger.log("Updating enrollment \(enrollmentId) status to: \(status)", level: .diagnostic)

        // If completing, set completed_at timestamp
        let completedAt: String? = status == "completed" ? ISO8601DateFormatter().string(from: Date()) : nil

        let input = UpdateStatusInput(status: status, completedAt: completedAt)

        do {
            try await supabase.client
                .from("program_enrollments")
                .update(input)
                .eq("id", value: enrollmentId.uuidString)
                .execute()

            logger.log("Enrollment status updated to '\(status)'", level: .success)
        } catch {
            logger.log("Failed to update enrollment status: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    // MARK: - Combined Queries

    /// Fetch enrollments with their associated program details
    func getEnrolledProgramsWithDetails(patientId: String, status: String? = nil) async throws -> [EnrollmentWithProgram] {
        let logger = DebugLogger.shared
        logger.log("Fetching enrolled programs with details for patient: \(patientId)", level: .diagnostic)

        // First get enrollments
        let enrollments = try await getEnrolledPrograms(patientId: patientId, status: status)

        if enrollments.isEmpty {
            return []
        }

        // Get unique program IDs
        let programIds = enrollments.map { $0.programLibraryId.uuidString }

        // Fetch associated programs
        do {
            let response = try await supabase.client
                .from("program_library")
                .select()
                .in("id", values: programIds)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let programs = try decoder.decode([ProgramLibrary].self, from: response.data)

            // Create a lookup dictionary
            let programLookup = Dictionary(uniqueKeysWithValues: programs.map { ($0.id, $0) })

            // Combine enrollments with programs
            let combined = enrollments.compactMap { enrollment -> EnrollmentWithProgram? in
                guard let program = programLookup[enrollment.programLibraryId] else { return nil }
                return EnrollmentWithProgram(enrollment: enrollment, program: program)
            }

            logger.log("Fetched \(combined.count) enrolled programs with details", level: .success)
            return combined
        } catch {
            logger.log("Failed to fetch program details: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    /// Fetch a single program by ID
    func fetchProgram(id: UUID) async throws -> ProgramLibrary {
        let logger = DebugLogger.shared
        logger.log("Fetching program: \(id)", level: .diagnostic)

        do {
            let response = try await supabase.client
                .from("program_library")
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let program = try decoder.decode(ProgramLibrary.self, from: response.data)

            logger.log("Fetched program: \(program.title)", level: .success)
            return program
        } catch {
            logger.log("Failed to fetch program: \(error.localizedDescription)", level: .error)
            throw error
        }
    }
}
