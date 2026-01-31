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

    // MARK: - Workout Completion Progress Tracking

    /// Check if a completed workout template is part of an enrolled program and update progress
    /// When a user completes a workout from their program, this calculates and updates their enrollment progress
    /// Progress = (completed workouts / total workouts in program) * 100
    ///
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - templateId: The system_workout_template ID that was just completed
    func recordWorkoutCompletion(patientId: String, templateId: UUID) async throws {
        let logger = DebugLogger.shared
        logger.log("Recording workout completion - patient: \(patientId), template: \(templateId)", level: .diagnostic)

        guard let patientUUID = UUID(uuidString: patientId) else {
            logger.log("Invalid patient ID format: \(patientId)", level: .error)
            return
        }

        // Step 1: Find active enrollment that contains this workout template
        // Query: vw_program_template_assignments (joins program_workout_assignments with program_library)
        do {
            // First, get the program_library_id(s) that contain this template
            struct AssignmentRow: Codable {
                let programLibraryId: UUID

                enum CodingKeys: String, CodingKey {
                    case programLibraryId = "program_library_id"
                }
            }

            // Use the view that joins program_workout_assignments with program_library
            let assignmentsResponse = try await supabase.client
                .from("vw_program_template_assignments")
                .select("program_library_id")
                .eq("template_id", value: templateId.uuidString)
                .execute()

            let decoder = JSONDecoder()
            let assignments = try decoder.decode([AssignmentRow].self, from: assignmentsResponse.data)

            if assignments.isEmpty {
                logger.log("No program assignments found for template \(templateId) - not a program workout", level: .diagnostic)
                return
            }

            logger.log("Found \(assignments.count) program(s) containing this template", level: .diagnostic)

            // Step 2: Check if patient is enrolled in any of these programs
            let programIds = assignments.map { $0.programLibraryId.uuidString }

            let enrollmentsResponse = try await supabase.client
                .from("program_enrollments")
                .select("id, program_library_id, progress_percentage")
                .eq("patient_id", value: patientId)
                .eq("status", value: "active")
                .in("program_library_id", values: programIds)
                .execute()

            let enrollments = try decoder.decode([ProgramEnrollment].self, from: enrollmentsResponse.data)

            if enrollments.isEmpty {
                logger.log("Patient not enrolled in any program containing this template", level: .diagnostic)
                return
            }

            // Step 3: For each matching enrollment, calculate and update progress
            for enrollment in enrollments {
                await updateEnrollmentProgress(enrollment: enrollment, patientId: patientUUID, completedTemplateId: templateId)
            }

        } catch {
            logger.log("Failed to record workout completion: \(error.localizedDescription)", level: .error)
            // Don't throw - progress tracking should not block workout completion
        }
    }

    /// Calculate and update progress for a specific enrollment
    private func updateEnrollmentProgress(enrollment: ProgramEnrollment, patientId: UUID, completedTemplateId: UUID) async {
        let logger = DebugLogger.shared
        logger.log("Updating progress for enrollment \(enrollment.id)", level: .diagnostic)

        do {
            // Get total workout count for this program
            struct CountRow: Codable {
                let count: Int
            }

            // Use the view for consistent column names
            let totalResponse = try await supabase.client
                .from("vw_program_template_assignments")
                .select("*", head: true, count: .exact)
                .eq("program_library_id", value: enrollment.programLibraryId.uuidString)
                .execute()

            let totalCount = totalResponse.count ?? 0

            if totalCount == 0 {
                logger.log("No workouts in program - skipping progress update", level: .warning)
                return
            }

            // Get all template IDs for this program
            struct TemplateRow: Codable {
                let templateId: UUID

                enum CodingKeys: String, CodingKey {
                    case templateId = "template_id"
                }
            }

            let templatesResponse = try await supabase.client
                .from("vw_program_template_assignments")
                .select("template_id")
                .eq("program_library_id", value: enrollment.programLibraryId.uuidString)
                .execute()

            let decoder = JSONDecoder()
            let templates = try decoder.decode([TemplateRow].self, from: templatesResponse.data)
            let templateIds = templates.map { $0.templateId.uuidString }

            // Count completed workouts by checking manual_sessions with matching source_template_id
            // A workout is completed if:
            // 1. It's a manual_session with source_template_id matching a program template
            // 2. The session is marked completed
            // 3. The session belongs to this patient
            let completedResponse = try await supabase.client
                .from("manual_sessions")
                .select("*", head: true, count: .exact)
                .eq("patient_id", value: patientId.uuidString)
                .eq("completed", value: true)
                .in("source_template_id", values: templateIds)
                .execute()

            let completedCount = completedResponse.count ?? 0

            // Calculate progress percentage
            let progressPercentage = min(100, Int((Double(completedCount) / Double(totalCount)) * 100))

            logger.log("Progress: \(completedCount)/\(totalCount) = \(progressPercentage)%", level: .diagnostic)

            // Update enrollment progress
            try await updateProgress(enrollmentId: enrollment.id, progress: progressPercentage)

            // If 100% complete, update status to completed
            if progressPercentage >= 100 {
                try await updateEnrollmentStatus(enrollmentId: enrollment.id, status: "completed")
                logger.log("Program completed! Enrollment status updated to 'completed'", level: .success)
            }

        } catch {
            logger.log("Failed to update enrollment progress: \(error.localizedDescription)", level: .error)
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

    // MARK: - Workout Schedule for Enrolled Programs

    /// Fetch the workout schedule for an enrolled program
    /// Returns workouts organized by week and day for the user to follow
    func fetchProgramWorkoutSchedule(programLibraryId: UUID) async throws -> [ProgramScheduleWeek] {
        let logger = DebugLogger.shared
        logger.log("Fetching workout schedule for program library: \(programLibraryId)", level: .diagnostic)

        // First get the program_id from program_library
        let programLibrary = try await fetchProgram(id: programLibraryId)
        let programId = programLibrary.programId

        do {
            // Fetch all workout assignments for this program with template details
            let response = try await supabase.client
                .from("program_workout_assignments")
                .select("""
                    id,
                    program_id,
                    template_id,
                    phase_id,
                    week_number,
                    day_of_week,
                    sequence,
                    notes,
                    system_workout_templates!inner(
                        id,
                        name,
                        description,
                        duration_minutes,
                        category,
                        difficulty
                    )
                """)
                .eq("program_id", value: programId.uuidString)
                .order("week_number", ascending: true)
                .order("day_of_week", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let assignments = try decoder.decode([ProgramWorkoutAssignmentWithTemplate].self, from: response.data)

            logger.log("Fetched \(assignments.count) workout assignments", level: .diagnostic)

            // Group by week
            let groupedByWeek = Dictionary(grouping: assignments) { $0.weekNumber }

            // Build week schedule
            var weeks: [ProgramScheduleWeek] = []

            for weekNumber in groupedByWeek.keys.sorted() {
                let weekAssignments = groupedByWeek[weekNumber] ?? []

                // Group by day within the week
                let groupedByDay = Dictionary(grouping: weekAssignments) { $0.dayOfWeek }

                var days: [ProgramScheduleDay] = []
                for dayNumber in 1...7 {
                    let dayAssignments = groupedByDay[dayNumber] ?? []
                    let workouts = dayAssignments.map { assignment -> ProgramScheduleWorkout in
                        ProgramScheduleWorkout(
                            assignmentId: assignment.id,
                            templateId: assignment.templateId,
                            name: assignment.template.name,
                            description: assignment.template.description,
                            durationMinutes: assignment.template.durationMinutes,
                            category: assignment.template.category,
                            difficulty: assignment.template.difficulty,
                            notes: assignment.notes
                        )
                    }

                    days.append(ProgramScheduleDay(
                        dayOfWeek: dayNumber,
                        dayName: dayName(for: dayNumber),
                        workouts: workouts
                    ))
                }

                weeks.append(ProgramScheduleWeek(
                    weekNumber: weekNumber,
                    days: days
                ))
            }

            logger.log("Organized into \(weeks.count) weeks", level: .success)
            return weeks
        } catch {
            logger.log("Failed to fetch workout schedule: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    private func dayName(for dayNumber: Int) -> String {
        switch dayNumber {
        case 1: return "Monday"
        case 2: return "Tuesday"
        case 3: return "Wednesday"
        case 4: return "Thursday"
        case 5: return "Friday"
        case 6: return "Saturday"
        case 7: return "Sunday"
        default: return "Day \(dayNumber)"
        }
    }

    // MARK: - Phase Preview

    /// Fetch phase preview data for a program to show users what's included before enrollment
    func fetchPhasePreview(programId: UUID) async throws -> [ProgramPhasePreview] {
        let logger = DebugLogger.shared
        logger.log("Fetching phase preview for program: \(programId)", level: .diagnostic)

        do {
            // Query the vw_phase_preview view
            let response = try await supabase.client
                .from("vw_phase_preview")
                .select()
                .eq("program_id", value: programId.uuidString)
                .order("phase_number", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            let phases = try decoder.decode([ProgramPhasePreview].self, from: response.data)

            logger.log("Fetched \(phases.count) phases for program preview", level: .success)
            return phases
        } catch {
            logger.log("Failed to fetch phase preview: \(error.localizedDescription)", level: .error)
            throw error
        }
    }
}
