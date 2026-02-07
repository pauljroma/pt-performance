//
//  EnrolledProgramsViewModel.swift
//  PTPerformance
//
//  ViewModel for displaying enrolled programs on the Today tab
//

import SwiftUI

// MARK: - ViewModel

@MainActor
class EnrolledProgramsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var enrolledPrograms: [EnrollmentWithProgram] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let service: ProgramLibraryService
    private let supabase: PTSupabaseClient

    // MARK: - Initialization

    @MainActor
    init(service: ProgramLibraryService = ProgramLibraryService(), supabase: PTSupabaseClient = .shared) {
        self.service = service
        self.supabase = supabase
    }

    // MARK: - Computed Properties

    /// Whether the user has any active enrolled programs
    var hasEnrolledPrograms: Bool {
        !enrolledPrograms.isEmpty
    }

    /// Number of active enrollments
    var activeEnrollmentCount: Int {
        enrolledPrograms.count
    }

    // MARK: - Data Fetching

    /// Load enrolled programs for the current user (active status only)
    /// Build 448: Enhanced logging to debug enrollment visibility issue
    func loadEnrolledPrograms() async {
        guard let patientId = supabase.userId else {
            DebugLogger.shared.log("❌ [EnrolledPrograms] No patient ID available", level: .warning)
            #if DEBUG
            print("❌ [EnrolledPrograms] supabase.userId is nil!")
            #endif
            return
        }

        #if DEBUG
        print("📱 [EnrolledPrograms] Loading for patientId: \(patientId)")
        #endif
        DebugLogger.shared.log("📱 [EnrolledPrograms] Loading for patientId: \(patientId)", level: .diagnostic)

        isLoading = true
        errorMessage = nil

        do {
            // Fetch active enrollments with program details
            // Build 447+: Uses RPC get_my_enrolled_programs() internally
            enrolledPrograms = try await service.getEnrolledProgramsWithDetails(
                patientId: patientId,
                status: "active"
            )

            #if DEBUG
            print("✅ [EnrolledPrograms] Loaded \(enrolledPrograms.count) programs")
            for program in enrolledPrograms {
                print("   - \(program.program.title) (\(program.enrollment.status))")
            }
            #endif
            DebugLogger.shared.log("✅ [EnrolledPrograms] Loaded \(enrolledPrograms.count) programs", level: .success)
            isLoading = false
        } catch {
            #if DEBUG
            print("❌ [EnrolledPrograms] Error: \(error)")
            #endif
            DebugLogger.shared.log("❌ [EnrolledPrograms] Failed: \(error.localizedDescription)", level: .error)
            errorMessage = "Unable to load your programs"
            isLoading = false
        }
    }

    /// Refresh enrolled programs
    func refresh() async {
        await loadEnrolledPrograms()
    }

    // MARK: - Progress Helpers

    /// Calculate the current week number for an enrollment
    func currentWeek(for enrollment: EnrollmentWithProgram) -> Int {
        guard let startedAt = enrollment.enrollment.startedAt else {
            // If not started, show week 1
            return 1
        }

        let calendar = Calendar.current
        let weeks = calendar.dateComponents([.weekOfYear], from: startedAt, to: Date()).weekOfYear ?? 0
        // Clamp to valid range (1 to durationWeeks)
        return max(1, min(weeks + 1, enrollment.program.durationWeeks))
    }

    /// Calculate days remaining for a program enrollment
    func daysRemaining(for enrollment: EnrollmentWithProgram) -> Int {
        guard let startedAt = enrollment.enrollment.startedAt else {
            // If not started, return total days
            return enrollment.program.durationWeeks * 7
        }

        let calendar = Calendar.current
        let totalDays = enrollment.program.durationWeeks * 7
        let daysSinceStart = calendar.dateComponents([.day], from: startedAt, to: Date()).day ?? 0
        let remaining = totalDays - daysSinceStart

        return max(0, remaining)
    }

    /// Format days remaining as a display string
    func daysRemainingDisplay(for enrollment: EnrollmentWithProgram) -> String {
        let days = daysRemaining(for: enrollment)

        if days == 0 {
            return "Complete!"
        } else if days == 1 {
            return "1 day left"
        } else if days < 7 {
            return "\(days) days left"
        } else {
            let weeks = days / 7
            if weeks == 1 {
                return "1 week left"
            } else {
                return "\(weeks) weeks left"
            }
        }
    }

    /// Get progress percentage (0-100) for an enrollment
    func progressPercentage(for enrollment: EnrollmentWithProgram) -> Int {
        // Use the stored progress if available
        let progress = enrollment.enrollment.progressPercentage

        // If progress is 0 but enrollment has started, calculate based on time
        if progress == 0, let startedAt = enrollment.enrollment.startedAt {
            let calendar = Calendar.current
            let totalDays = enrollment.program.durationWeeks * 7
            let daysSinceStart = calendar.dateComponents([.day], from: startedAt, to: Date()).day ?? 0
            let timeBasedProgress = Int((Double(daysSinceStart) / Double(totalDays)) * 100)
            return max(0, min(100, timeBasedProgress))
        }

        return progress
    }

    // MARK: - Enrollment Actions

    /// Disenroll (cancel) from a program
    func disenrollFromProgram(_ enrollment: EnrollmentWithProgram) async -> Bool {
        DebugLogger.shared.log("Disenrolling from program: \(enrollment.program.title)", level: .diagnostic)

        do {
            try await service.updateEnrollmentStatus(
                enrollmentId: enrollment.enrollment.id,
                status: "cancelled"
            )

            // Remove from local list
            enrolledPrograms.removeAll { $0.id == enrollment.id }

            DebugLogger.shared.log("Successfully disenrolled from program", level: .success)
            return true
        } catch {
            DebugLogger.shared.log("Failed to disenroll: \(error.localizedDescription)", level: .error)
            errorMessage = "Unable to leave program. Please try again."
            return false
        }
    }

    /// Pause an enrollment (can be resumed later)
    func pauseEnrollment(_ enrollment: EnrollmentWithProgram) async -> Bool {
        DebugLogger.shared.log("Pausing enrollment: \(enrollment.program.title)", level: .diagnostic)

        do {
            try await service.updateEnrollmentStatus(
                enrollmentId: enrollment.enrollment.id,
                status: "paused"
            )

            // Remove from active list (will show in paused programs)
            enrolledPrograms.removeAll { $0.id == enrollment.id }

            DebugLogger.shared.log("Successfully paused enrollment", level: .success)
            return true
        } catch {
            DebugLogger.shared.log("Failed to pause enrollment: \(error.localizedDescription)", level: .error)
            errorMessage = "Unable to pause program. Please try again."
            return false
        }
    }
}
