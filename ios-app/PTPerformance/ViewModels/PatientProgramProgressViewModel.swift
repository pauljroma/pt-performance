//
//  PatientProgramProgressViewModel.swift
//  PTPerformance
//
//  ViewModel for displaying individual patient program progress to therapists.
//  Loads enrolled programs, workout completion history, and adherence metrics.
//

import SwiftUI
import Supabase

// MARK: - Data Models

/// Represents a completed workout within a program
struct CompletedWorkout: Identifiable, Codable {
    let id: UUID
    let name: String?
    let completedAt: Date
    let durationMinutes: Int?
    let totalVolume: Double?
    let avgRpe: Double?
    let sessionSource: SessionSource?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case completedAt = "completed_at"
        case durationMinutes = "duration_minutes"
        case totalVolume = "total_volume"
        case avgRpe = "avg_rpe"
        case sessionSource = "session_source"
    }

    var displayName: String {
        name ?? "Workout"
    }

    var formattedDuration: String {
        guard let minutes = durationMinutes else { return "N/A" }
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remaining = minutes % 60
            return remaining > 0 ? "\(hours)h \(remaining)m" : "\(hours)h"
        }
    }
}

/// Adherence metrics for a patient's program
struct ProgramAdherenceMetrics {
    let completedOnTime: Int
    let missedWorkouts: Int
    let totalScheduled: Int
    let adherenceRate: Double
    let currentStreak: Int
    let longestStreak: Int

    var completedPercentage: Double {
        guard totalScheduled > 0 else { return 0 }
        return Double(completedOnTime) / Double(totalScheduled) * 100
    }

    var missedPercentage: Double {
        guard totalScheduled > 0 else { return 0 }
        return Double(missedWorkouts) / Double(totalScheduled) * 100
    }
}

/// Patient's program enrollment with details for display
struct PatientProgramEnrollment: Identifiable {
    let id: UUID
    let enrollmentId: UUID
    let programLibraryId: UUID
    let programTitle: String
    let programCategory: String
    let durationWeeks: Int
    let difficultyLevel: String
    let enrolledAt: Date
    let startedAt: Date?
    let status: EnrollmentStatus
    let progressPercentage: Int
    let currentPhase: String?
    let currentWeek: Int
    let totalWorkouts: Int
    let completedWorkouts: Int

    var remainingWorkouts: Int {
        max(0, totalWorkouts - completedWorkouts)
    }

    var progress: Double {
        guard totalWorkouts > 0 else { return 0 }
        return Double(completedWorkouts) / Double(totalWorkouts)
    }
}

// MARK: - ViewModel

@MainActor
class PatientProgramProgressViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var patient: Patient?
    @Published var enrolledPrograms: [PatientProgramEnrollment] = []
    @Published var selectedProgram: PatientProgramEnrollment?
    @Published var recentWorkouts: [CompletedWorkout] = []
    @Published var adherenceMetrics: ProgramAdherenceMetrics?
    @Published var weeklyCompletions: [WeeklyCompletion] = []

    @Published var isLoading = false
    @Published var isLoadingDetails = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let programService: ProgramLibraryService
    private let analyticsService: AnalyticsService

    // MARK: - Weekly Completion Model

    struct WeeklyCompletion: Identifiable {
        let id: Int
        let weekNumber: Int
        let scheduledCount: Int
        let completedCount: Int
        let startDate: Date

        var completionRate: Double {
            guard scheduledCount > 0 else { return 0 }
            return Double(completedCount) / Double(scheduledCount)
        }
    }

    // MARK: - Initialization

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
        self.programService = ProgramLibraryService(supabase: supabase)
        self.analyticsService = AnalyticsService(supabase: supabase)
    }

    // MARK: - Data Loading

    /// Load all program progress data for a patient
    func loadData(for patient: Patient) async {
        self.patient = patient
        isLoading = true
        errorMessage = nil

        DebugLogger.shared.log("Loading program progress for patient: \(patient.fullName)", level: .diagnostic)

        do {
            // Fetch enrolled programs
            try await loadEnrolledPrograms(patientId: patient.id)

            // Auto-select first active program if available
            if let firstProgram = enrolledPrograms.first(where: { $0.status == .active }) ?? enrolledPrograms.first {
                await selectProgram(firstProgram)
            }

            isLoading = false
            DebugLogger.shared.log("Successfully loaded \(enrolledPrograms.count) programs", level: .success)
        } catch {
            errorMessage = "Unable to load program progress"
            isLoading = false
            DebugLogger.shared.log("Failed to load program progress: \(error.localizedDescription)", level: .error)
        }
    }

    /// Load enrolled programs for the patient
    private func loadEnrolledPrograms(patientId: UUID) async throws {
        // Fetch enrollments with program details
        let response = try await supabase.client
            .from("program_enrollments")
            .select("""
                id,
                patient_id,
                program_library_id,
                enrolled_at,
                started_at,
                completed_at,
                status,
                progress_percentage,
                program_library!inner(
                    id,
                    title,
                    category,
                    duration_weeks,
                    difficulty_level,
                    program_id
                )
            """)
            .eq("patient_id", value: patientId.uuidString)
            .order("enrolled_at", ascending: false)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        struct EnrollmentRow: Codable {
            let id: UUID
            let patientId: UUID
            let programLibraryId: UUID
            let enrolledAt: Date
            let startedAt: Date?
            let status: String
            let progressPercentage: Int
            let programLibrary: ProgramLibraryInfo

            enum CodingKeys: String, CodingKey {
                case id
                case patientId = "patient_id"
                case programLibraryId = "program_library_id"
                case enrolledAt = "enrolled_at"
                case startedAt = "started_at"
                case status
                case progressPercentage = "progress_percentage"
                case programLibrary = "program_library"
            }

            struct ProgramLibraryInfo: Codable {
                let id: UUID
                let title: String
                let category: String?
                let durationWeeks: Int
                let difficultyLevel: String?
                let programId: UUID?

                enum CodingKeys: String, CodingKey {
                    case id
                    case title
                    case category
                    case durationWeeks = "duration_weeks"
                    case difficultyLevel = "difficulty_level"
                    case programId = "program_id"
                }
            }
        }

        let rows = try decoder.decode([EnrollmentRow].self, from: response.data)

        // Convert to display models
        var programs: [PatientProgramEnrollment] = []

        for row in rows {
            // Calculate current week based on start date
            let currentWeek = calculateCurrentWeek(startedAt: row.startedAt, durationWeeks: row.programLibrary.durationWeeks)

            // Get workout counts for this program
            let (total, completed) = try await getWorkoutCounts(
                patientId: patientId,
                programLibraryId: row.programLibraryId,
                programId: row.programLibrary.programId
            )

            let enrollment = PatientProgramEnrollment(
                id: row.id,
                enrollmentId: row.id,
                programLibraryId: row.programLibraryId,
                programTitle: row.programLibrary.title,
                programCategory: row.programLibrary.category ?? "General",
                durationWeeks: row.programLibrary.durationWeeks,
                difficultyLevel: row.programLibrary.difficultyLevel ?? "Beginner",
                enrolledAt: row.enrolledAt,
                startedAt: row.startedAt,
                status: EnrollmentStatus(rawValue: row.status) ?? .active,
                progressPercentage: row.progressPercentage,
                currentPhase: nil,
                currentWeek: currentWeek,
                totalWorkouts: total,
                completedWorkouts: completed
            )

            programs.append(enrollment)
        }

        enrolledPrograms = programs
    }

    /// Calculate the current week number based on start date
    private func calculateCurrentWeek(startedAt: Date?, durationWeeks: Int) -> Int {
        guard let startDate = startedAt else { return 1 }

        let calendar = Calendar.current
        let weeksSinceStart = calendar.dateComponents([.weekOfYear], from: startDate, to: Date()).weekOfYear ?? 0

        return max(1, min(weeksSinceStart + 1, durationWeeks))
    }

    /// Get total and completed workout counts for a program
    private func getWorkoutCounts(patientId: UUID, programLibraryId: UUID, programId: UUID?) async throws -> (total: Int, completed: Int) {
        guard let programId = programId else {
            return (0, 0)
        }

        // Get total workouts in program
        let totalResponse = try await supabase.client
            .from("program_workout_assignments")
            .select("*", head: true, count: .exact)
            .eq("program_id", value: programId.uuidString)
            .execute()

        let totalCount = totalResponse.count ?? 0

        if totalCount == 0 {
            return (0, 0)
        }

        // Get template IDs for this program
        struct TemplateRow: Codable {
            let templateId: UUID

            enum CodingKeys: String, CodingKey {
                case templateId = "template_id"
            }
        }

        let templatesResponse = try await supabase.client
            .from("program_workout_assignments")
            .select("template_id")
            .eq("program_id", value: programId.uuidString)
            .execute()

        let decoder = JSONDecoder()
        let templates = try decoder.decode([TemplateRow].self, from: templatesResponse.data)
        let templateIds = templates.map { $0.templateId.uuidString }

        // Count completed workouts
        let completedResponse = try await supabase.client
            .from("manual_sessions")
            .select("*", head: true, count: .exact)
            .eq("patient_id", value: patientId.uuidString)
            .eq("completed", value: true)
            .in("source_template_id", values: templateIds)
            .execute()

        let completedCount = completedResponse.count ?? 0

        return (totalCount, completedCount)
    }

    // MARK: - Program Selection

    /// Select a program and load its details
    func selectProgram(_ program: PatientProgramEnrollment) async {
        selectedProgram = program
        isLoadingDetails = true

        guard let patient = patient else {
            isLoadingDetails = false
            return
        }

        DebugLogger.shared.log("Loading details for program: \(program.programTitle)", level: .diagnostic)

        do {
            // Load recent completed workouts
            try await loadRecentWorkouts(patientId: patient.id, programLibraryId: program.programLibraryId)

            // Calculate adherence metrics
            adherenceMetrics = try await calculateAdherenceMetrics(
                patientId: patient.id,
                program: program
            )

            // Load weekly completion data
            try await loadWeeklyCompletions(patientId: patient.id, program: program)

            isLoadingDetails = false
        } catch {
            DebugLogger.shared.log("Failed to load program details: \(error.localizedDescription)", level: .error)
            isLoadingDetails = false
        }
    }

    /// Load recent completed workouts for a program
    private func loadRecentWorkouts(patientId: UUID, programLibraryId: UUID) async throws {
        // Get program_id from program_library
        let libraryResponse = try await supabase.client
            .from("program_library")
            .select("program_id")
            .eq("id", value: programLibraryId.uuidString)
            .single()
            .execute()

        struct LibraryRow: Codable {
            let programId: UUID?

            enum CodingKeys: String, CodingKey {
                case programId = "program_id"
            }
        }

        let decoder = JSONDecoder()
        let library = try decoder.decode(LibraryRow.self, from: libraryResponse.data)

        guard let programId = library.programId else {
            recentWorkouts = []
            return
        }

        // Get template IDs for this program
        struct TemplateRow: Codable {
            let templateId: UUID

            enum CodingKeys: String, CodingKey {
                case templateId = "template_id"
            }
        }

        let templatesResponse = try await supabase.client
            .from("program_workout_assignments")
            .select("template_id")
            .eq("program_id", value: programId.uuidString)
            .execute()

        let templates = try decoder.decode([TemplateRow].self, from: templatesResponse.data)
        let templateIds = templates.map { $0.templateId.uuidString }

        if templateIds.isEmpty {
            recentWorkouts = []
            return
        }

        // Fetch recent completed workouts
        let response = try await supabase.client
            .from("manual_sessions")
            .select("id, name, completed_at, duration_minutes, total_volume, avg_rpe, session_source")
            .eq("patient_id", value: patientId.uuidString)
            .eq("completed", value: true)
            .in("source_template_id", values: templateIds)
            .order("completed_at", ascending: false)
            .limit(5)
            .execute()

        decoder.dateDecodingStrategy = .iso8601
        recentWorkouts = try decoder.decode([CompletedWorkout].self, from: response.data)
    }

    /// Calculate adherence metrics for a program
    private func calculateAdherenceMetrics(patientId: UUID, program: PatientProgramEnrollment) async throws -> ProgramAdherenceMetrics {
        // Get adherence data from analytics service
        let adherence = try? await analyticsService.fetchAdherence(patientId: patientId.uuidString, days: 30)

        // Calculate based on program's completed vs total
        let completedOnTime = program.completedWorkouts
        let totalScheduled = program.totalWorkouts
        let missedWorkouts = max(0, calculateExpectedCompletions(program: program) - completedOnTime)

        let adherenceRate: Double
        if totalScheduled > 0 {
            adherenceRate = Double(completedOnTime) / Double(totalScheduled) * 100
        } else {
            adherenceRate = adherence?.adherencePercentage ?? 0
        }

        return ProgramAdherenceMetrics(
            completedOnTime: completedOnTime,
            missedWorkouts: missedWorkouts,
            totalScheduled: totalScheduled,
            adherenceRate: min(100, adherenceRate),
            currentStreak: 0,  // Could be enhanced with streak tracking
            longestStreak: 0
        )
    }

    /// Calculate expected completions based on program start date
    private func calculateExpectedCompletions(program: PatientProgramEnrollment) -> Int {
        guard let startDate = program.startedAt else { return 0 }
        guard program.totalWorkouts > 0 else { return 0 }

        let calendar = Calendar.current
        let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        let totalDays = program.durationWeeks * 7

        // Estimate expected completions based on progress through program
        let progressRatio = Double(daysSinceStart) / Double(totalDays)
        return Int(Double(program.totalWorkouts) * progressRatio)
    }

    /// Load weekly completion data for timeline visualization
    private func loadWeeklyCompletions(patientId: UUID, program: PatientProgramEnrollment) async throws {
        guard let startDate = program.startedAt else {
            weeklyCompletions = []
            return
        }

        let calendar = Calendar.current
        var completions: [WeeklyCompletion] = []

        // Generate weekly data points
        let workoutsPerWeek = program.totalWorkouts > 0 ? program.totalWorkouts / max(1, program.durationWeeks) : 3

        for week in 1...program.durationWeeks {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: week - 1, to: startDate) else { continue }

            // Determine completed count based on current progress
            let completedInWeek: Int
            if week < program.currentWeek {
                // Past weeks - assume completed based on overall rate
                completedInWeek = Int(Double(workoutsPerWeek) * program.progress)
            } else if week == program.currentWeek {
                // Current week - partial completion
                let remainingThisWeek = program.completedWorkouts % max(1, workoutsPerWeek)
                completedInWeek = remainingThisWeek
            } else {
                // Future weeks
                completedInWeek = 0
            }

            completions.append(WeeklyCompletion(
                id: week,
                weekNumber: week,
                scheduledCount: workoutsPerWeek,
                completedCount: min(completedInWeek, workoutsPerWeek),
                startDate: weekStart
            ))
        }

        weeklyCompletions = completions
    }

    // MARK: - Refresh

    /// Refresh all data
    func refresh() async {
        guard let patient = patient else { return }
        await loadData(for: patient)
    }

    // MARK: - Computed Properties

    /// Whether the patient has any enrolled programs
    var hasPrograms: Bool {
        !enrolledPrograms.isEmpty
    }

    /// Active programs count
    var activeProgramsCount: Int {
        enrolledPrograms.filter { $0.status == .active }.count
    }

    /// Overall adherence across all programs
    var overallAdherence: Double {
        guard !enrolledPrograms.isEmpty else { return 0 }

        let totalCompleted = enrolledPrograms.reduce(0) { $0 + $1.completedWorkouts }
        let totalWorkouts = enrolledPrograms.reduce(0) { $0 + $1.totalWorkouts }

        guard totalWorkouts > 0 else { return 0 }
        return Double(totalCompleted) / Double(totalWorkouts) * 100
    }
}
