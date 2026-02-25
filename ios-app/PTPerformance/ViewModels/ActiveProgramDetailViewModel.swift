//
//  ActiveProgramDetailViewModel.swift
//  PTPerformance
//
//  ViewModel for ActiveProgramDetailView - manages loading and displaying
//  enrolled program structure with phases, weeks, and workouts.
//

import SwiftUI

@MainActor
class ActiveProgramDetailViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var phases: [ProgramPhasePreview] = []
    @Published var weeks: [ProgramScheduleWeek] = []
    @Published var programStructure: BaseballProgramStructure?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var usesPhaseBasedStructure = false
    @Published var completedWorkoutIds: Set<UUID> = []

    // MARK: - Properties

    let enrollment: EnrollmentWithProgram
    private let programService: ProgramLibraryService
    private let supabase: PTSupabaseClient

    // MARK: - Initialization

    init(
        enrollment: EnrollmentWithProgram,
        programService: ProgramLibraryService = ProgramLibraryService(),
        supabase: PTSupabaseClient = .shared
    ) {
        self.enrollment = enrollment
        self.programService = programService
        self.supabase = supabase
    }

    // MARK: - Computed Properties

    /// Current week in the program
    var currentWeek: Int {
        guard let startedAt = enrollment.enrollment.startedAt ?? Optional(enrollment.enrollment.enrolledAt) else {
            return 1
        }

        let calendar = Calendar.current
        let weeks = calendar.dateComponents([.weekOfYear], from: startedAt, to: Date()).weekOfYear ?? 0
        return max(1, min(weeks + 1, enrollment.program.durationWeeks))
    }

    /// Current phase number (1-indexed)
    var currentPhase: Int {
        guard !phases.isEmpty else { return 1 }

        // Find which phase contains the current week
        for phase in phases {
            if currentWeek >= phase.weekStart && currentWeek <= phase.weekEnd {
                return phase.phaseNumber
            }
        }

        // Default to first phase
        return 1
    }

    /// Progress percentage (0-100)
    var progressPercentage: Int {
        let storedProgress = enrollment.enrollment.progressPercentage

        // If progress is stored and valid, use it
        if storedProgress > 0 {
            return storedProgress
        }

        // Otherwise calculate from time elapsed
        guard let startedAt = enrollment.enrollment.startedAt else {
            return 0
        }

        let calendar = Calendar.current
        let totalDays = enrollment.program.durationWeeks * 7
        let daysSinceStart = calendar.dateComponents([.day], from: startedAt, to: Date()).day ?? 0
        let timeBasedProgress = Int((Double(daysSinceStart) / Double(totalDays)) * 100)
        return max(0, min(100, timeBasedProgress))
    }

    /// Total number of workouts in the program
    var totalWorkouts: Int {
        if usesPhaseBasedStructure, let structure = programStructure {
            return structure.phases.reduce(0) { $0 + $1.sessions.count }
        }
        return weeks.reduce(0) { $0 + $1.workoutCount }
    }

    /// Number of completed workouts
    var completedWorkouts: Int {
        // If we have completion data, use it
        if !completedWorkoutIds.isEmpty {
            return completedWorkoutIds.count
        }

        // Otherwise estimate from progress
        let estimated = Int(Double(totalWorkouts) * Double(progressPercentage) / 100.0)
        return estimated
    }

    /// Number of remaining workouts
    var remainingWorkouts: Int {
        return max(0, totalWorkouts - completedWorkouts)
    }

    /// Whether the program has no content to display
    var isEmpty: Bool {
        !isLoading && phases.isEmpty && weeks.isEmpty && programStructure == nil
    }

    /// Empty state message for UI display
    var emptyStateMessage: String {
        if errorMessage != nil {
            return "Unable to load program details. Pull down to refresh."
        }
        return "This program doesn't have any workouts yet. Your therapist may still be setting it up."
    }

    /// Days remaining in program
    var daysRemaining: Int {
        guard let startedAt = enrollment.enrollment.startedAt else {
            return enrollment.program.durationWeeks * 7
        }

        let calendar = Calendar.current
        let totalDays = enrollment.program.durationWeeks * 7
        let daysSinceStart = calendar.dateComponents([.day], from: startedAt, to: Date()).day ?? 0
        return max(0, totalDays - daysSinceStart)
    }

    /// Formatted days remaining string
    var daysRemainingDisplay: String {
        let days = daysRemaining

        if days == 0 {
            return "Done!"
        } else if days == 1 {
            return "1 day"
        } else if days < 7 {
            return "\(days) days"
        } else {
            let weeks = days / 7
            return weeks == 1 ? "1 week" : "\(weeks) weeks"
        }
    }

    // MARK: - Data Loading

    /// Load the program structure including phases, weeks, and workouts
    func loadProgramStructure() async {
        isLoading = true
        errorMessage = nil

        let logger = DebugLogger.shared
        logger.log("Loading program structure for: \(enrollment.program.title)", level: .diagnostic)

        do {
            // Load phase previews first
            if let programId = enrollment.program.programId {
                phases = try await programService.fetchPhasePreview(programId: programId)
                logger.log("Loaded \(phases.count) phases", level: .diagnostic)
            }

            // Try loading workout schedule
            weeks = try await programService.fetchProgramWorkoutSchedule(programLibraryId: enrollment.program.id)

            // If no workouts found in standard schedule, try phase-based structure
            if weeks.isEmpty || weeks.allSatisfy({ $0.workoutCount == 0 }) {
                if let programId = enrollment.program.programId {
                    do {
                        let structure = try await BaseballPackService.shared.fetchProgramStructure(programId: programId)

                        if !structure.phases.isEmpty {
                            programStructure = structure
                            usesPhaseBasedStructure = true
                            weeks = []
                            logger.log("Using phase-based structure: \(structure.phases.count) phases", level: .diagnostic)
                        }
                    } catch {
                        logger.log("Phase-based structure not available: \(error.localizedDescription)", level: .warning)
                    }
                }
            }

            // Load completion data
            await loadCompletedWorkouts()

            isLoading = false
            logger.log("Program structure loaded successfully", level: .success)

        } catch {
            logger.log("Failed to load program structure: \(error.localizedDescription)", level: .error)
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    /// Load which workouts have been completed
    private func loadCompletedWorkouts() async {
        guard let patientId = supabase.userId else { return }

        let logger = DebugLogger.shared

        do {
            // Get all template IDs from this program
            var templateIds: [UUID] = []

            if usesPhaseBasedStructure, let structure = programStructure {
                // Collect template IDs from phase sessions
                for phase in structure.phases {
                    for session in phase.sessions {
                        for exercise in session.exercises {
                            templateIds.append(exercise.exerciseTemplateId)
                        }
                    }
                }
            } else {
                // Collect from weeks
                for week in weeks {
                    for day in week.days {
                        for workout in day.workouts {
                            templateIds.append(workout.templateId)
                        }
                    }
                }
            }

            guard !templateIds.isEmpty else { return }

            // Query completed sessions
            let response = try await supabase.client
                .from("manual_sessions")
                .select("source_template_id")
                .eq("patient_id", value: patientId)
                .eq("completed", value: true)
                .in("source_template_id", values: templateIds.map { $0.uuidString })
                .execute()

            struct CompletedSession: Codable {
                let sourceTemplateId: UUID?

                enum CodingKeys: String, CodingKey {
                    case sourceTemplateId = "source_template_id"
                }
            }

            let decoder = JSONDecoder()
            let sessions = try decoder.decode([CompletedSession].self, from: response.data)

            completedWorkoutIds = Set(sessions.compactMap { $0.sourceTemplateId })
            logger.log("Loaded \(completedWorkoutIds.count) completed workouts", level: .diagnostic)

        } catch {
            logger.log("Failed to load completed workouts: \(error.localizedDescription)", level: .warning)
        }
    }

    /// Check if a specific workout is completed
    func isWorkoutCompleted(_ templateId: UUID) -> Bool {
        return completedWorkoutIds.contains(templateId)
    }

    // MARK: - Actions

    /// Leave/unenroll from the program
    func leaveProgram() async {
        let logger = DebugLogger.shared
        logger.log("Leaving program: \(enrollment.program.title)", level: .diagnostic)

        do {
            try await programService.updateEnrollmentStatus(
                enrollmentId: enrollment.enrollment.id,
                status: "cancelled"
            )
            logger.log("Successfully left program", level: .success)
            HapticFeedback.success()
            // Notify Today tab to refresh enrolled programs list
            NotificationCenter.default.post(name: .enrolledProgramsDidChange, object: nil)
        } catch {
            logger.log("Failed to leave program: \(error.localizedDescription)", level: .error)
            errorMessage = "Unable to leave program. Please try again."
        }
    }
}
