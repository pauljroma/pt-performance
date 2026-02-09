//
//  ProgramAnalyticsViewModel.swift
//  PTPerformance
//
//  ViewModel for the Program Analytics Dashboard
//  Aggregates program data, enrollments, and completion metrics for therapists
//

import SwiftUI
import Combine

// MARK: - Program Analytics Data Models

/// Analytics data for a single program
struct ProgramAnalytics: Identifiable {
    let id: UUID
    let programId: UUID
    let programName: String
    let category: String
    let durationWeeks: Int
    let enrollmentCount: Int
    let activeCount: Int
    let completedCount: Int
    let averageProgress: Double
    let completionRate: Double
    let createdAt: Date?

    /// Color based on completion rate
    var completionColor: Color {
        switch completionRate {
        case 80...: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }

    /// Display string for completion rate
    var formattedCompletionRate: String {
        "\(Int(completionRate))%"
    }

    /// Display string for average progress
    var formattedAverageProgress: String {
        "\(Int(averageProgress))%"
    }
}

/// Recent enrollment with patient details
struct RecentEnrollment: Identifiable {
    let id: UUID
    let enrollmentId: UUID
    let patientId: UUID
    let patientName: String
    let programId: UUID
    let programName: String
    let enrolledAt: Date
    let status: EnrollmentStatus
    let progressPercentage: Int
}

/// Summary stats for the analytics dashboard
struct ProgramAnalyticsSummary {
    let totalPrograms: Int
    let totalEnrollments: Int
    let activeEnrollments: Int
    let completedEnrollments: Int
    let averageCompletionRate: Double
    let averageProgress: Double

    static let empty = ProgramAnalyticsSummary(
        totalPrograms: 0,
        totalEnrollments: 0,
        activeEnrollments: 0,
        completedEnrollments: 0,
        averageCompletionRate: 0,
        averageProgress: 0
    )
}

// MARK: - ViewModel

@MainActor
class ProgramAnalyticsViewModel: ObservableObject {

    // MARK: - Published Properties

    /// All programs created by the therapist with analytics
    @Published var programs: [ProgramAnalytics] = []

    /// Recent enrollments across all programs
    @Published var recentEnrollments: [RecentEnrollment] = []

    /// Summary statistics
    @Published var summary: ProgramAnalyticsSummary = .empty

    /// Loading state
    @Published var isLoading = false

    /// Error message
    @Published var errorMessage: String?

    /// Selected time range for filtering
    @Published var selectedTimeRange: TimeRange = .allTime

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Enums

    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "This Week"
        case month = "This Month"
        case quarter = "This Quarter"
        case year = "This Year"
        case allTime = "All Time"

        var id: String { rawValue }

        var startDate: Date? {
            let calendar = Calendar.current
            let now = Date()

            switch self {
            case .week:
                return calendar.date(byAdding: .day, value: -7, to: now)
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: now)
            case .quarter:
                return calendar.date(byAdding: .month, value: -3, to: now)
            case .year:
                return calendar.date(byAdding: .year, value: -1, to: now)
            case .allTime:
                return nil
            }
        }
    }

    // MARK: - Computed Properties

    /// Most popular programs sorted by enrollment count
    var popularPrograms: [ProgramAnalytics] {
        programs.sorted { $0.enrollmentCount > $1.enrollmentCount }
    }

    /// Top 5 most popular programs
    var topPrograms: [ProgramAnalytics] {
        Array(popularPrograms.prefix(5))
    }

    /// Programs with active enrollments
    var activePrograms: [ProgramAnalytics] {
        programs.filter { $0.activeCount > 0 }
    }

    // MARK: - Initialization

    init() {
        // No initialization needed - data loaded when view appears
    }

    // MARK: - Public Methods

    /// Load all analytics data for the therapist
    func loadAnalytics(therapistId: String) async {
        guard !therapistId.isEmpty else {
            DebugLogger.shared.log("SECURITY: Cannot load analytics without therapist ID", level: .error)
            errorMessage = "Unable to verify your account. Please sign in again."
            return
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            // Load programs created by this therapist from program_library
            async let programsTask = loadTherapistPrograms(therapistId: therapistId)

            // Load recent enrollments
            async let enrollmentsTask = loadRecentEnrollments(therapistId: therapistId)

            let (loadedPrograms, loadedEnrollments) = await (try programsTask, try enrollmentsTask)

            programs = loadedPrograms
            recentEnrollments = loadedEnrollments

            // Calculate summary statistics
            calculateSummary()

            DebugLogger.shared.log("Loaded analytics: \(programs.count) programs, \(recentEnrollments.count) recent enrollments", level: .success)

        } catch {
            DebugLogger.shared.log("Failed to load analytics: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to load analytics. Please try again."
        }
    }

    /// Refresh analytics data
    func refresh(therapistId: String) async {
        await loadAnalytics(therapistId: therapistId)
    }

    // MARK: - Private Methods

    /// Load programs with enrollment statistics
    private func loadTherapistPrograms(therapistId: String) async throws -> [ProgramAnalytics] {
        let logger = DebugLogger.shared
        logger.log("Loading therapist programs for analytics...", level: .diagnostic)

        // First, fetch all programs from program_library created by this therapist
        // Programs are linked via the author field which stores therapist ID
        let programsResponse = try await supabase.client
            .from("program_library")
            .select()
            .eq("author", value: therapistId)
            .order("created_at", ascending: false)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let libraryPrograms = try decoder.decode([ProgramLibrary].self, from: programsResponse.data)

        logger.log("Found \(libraryPrograms.count) programs by therapist", level: .diagnostic)

        if libraryPrograms.isEmpty {
            return []
        }

        // Fetch enrollment statistics for each program
        let programIds = libraryPrograms.map { $0.id.uuidString }

        let enrollmentsResponse = try await supabase.client
            .from("program_enrollments")
            .select("id, program_library_id, status, progress_percentage")
            .in("program_library_id", values: programIds)
            .execute()

        let enrollments = try decoder.decode([EnrollmentSummaryRow].self, from: enrollmentsResponse.data)

        // Group enrollments by program
        let enrollmentsByProgram = Dictionary(grouping: enrollments) { $0.programLibraryId }

        // Build analytics for each program
        let analytics = libraryPrograms.map { program -> ProgramAnalytics in
            let programEnrollments = enrollmentsByProgram[program.id] ?? []
            let activeCount = programEnrollments.filter { $0.status == "active" }.count
            let completedCount = programEnrollments.filter { $0.status == "completed" }.count
            let totalCount = programEnrollments.count

            let avgProgress: Double
            if !programEnrollments.isEmpty {
                avgProgress = Double(programEnrollments.reduce(0) { $0 + $1.progressPercentage }) / Double(programEnrollments.count)
            } else {
                avgProgress = 0
            }

            let completionRate: Double
            if totalCount > 0 {
                completionRate = Double(completedCount) / Double(totalCount) * 100
            } else {
                completionRate = 0
            }

            return ProgramAnalytics(
                id: UUID(),
                programId: program.id,
                programName: program.title,
                category: program.category,
                durationWeeks: program.durationWeeks,
                enrollmentCount: totalCount,
                activeCount: activeCount,
                completedCount: completedCount,
                averageProgress: avgProgress,
                completionRate: completionRate,
                createdAt: program.createdAt
            )
        }

        logger.log("Built analytics for \(analytics.count) programs", level: .success)
        return analytics
    }

    /// Load recent enrollments with patient details
    private func loadRecentEnrollments(therapistId: String) async throws -> [RecentEnrollment] {
        let logger = DebugLogger.shared
        logger.log("Loading recent enrollments...", level: .diagnostic)

        // Get patients for this therapist
        let patientsResponse = try await supabase.client
            .from("patients")
            .select("id, first_name, last_name")
            .eq("therapist_id", value: therapistId)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        struct PatientRow: Codable {
            let id: UUID
            let firstName: String
            let lastName: String

            enum CodingKeys: String, CodingKey {
                case id
                case firstName = "first_name"
                case lastName = "last_name"
            }

            var fullName: String {
                "\(firstName) \(lastName)"
            }
        }

        let patients = try decoder.decode([PatientRow].self, from: patientsResponse.data)
        let patientLookup = Dictionary(uniqueKeysWithValues: patients.map { ($0.id, $0) })
        let patientIds = patients.map { $0.id.uuidString }

        if patientIds.isEmpty {
            logger.log("No patients found for therapist", level: .diagnostic)
            return []
        }

        // Get recent enrollments for these patients
        let enrollmentsResponse = try await supabase.client
            .from("program_enrollments")
            .select("id, patient_id, program_library_id, enrolled_at, status, progress_percentage")
            .in("patient_id", values: patientIds)
            .order("enrolled_at", ascending: false)
            .limit(20)
            .execute()

        struct EnrollmentRow: Codable {
            let id: UUID
            let patientId: UUID
            let programLibraryId: UUID
            let enrolledAt: Date
            let status: String
            let progressPercentage: Int

            enum CodingKeys: String, CodingKey {
                case id
                case patientId = "patient_id"
                case programLibraryId = "program_library_id"
                case enrolledAt = "enrolled_at"
                case status
                case progressPercentage = "progress_percentage"
            }
        }

        let enrollmentRows = try decoder.decode([EnrollmentRow].self, from: enrollmentsResponse.data)

        // Get program names for these enrollments
        let programIds = Array(Set(enrollmentRows.map { $0.programLibraryId.uuidString }))

        if programIds.isEmpty {
            return []
        }

        let programsResponse = try await supabase.client
            .from("program_library")
            .select("id, title")
            .in("id", values: programIds)
            .execute()

        struct ProgramRow: Codable {
            let id: UUID
            let title: String
        }

        let programRows = try decoder.decode([ProgramRow].self, from: programsResponse.data)
        let programLookup = Dictionary(uniqueKeysWithValues: programRows.map { ($0.id, $0.title) })

        // Build recent enrollment list
        let recentEnrollments = enrollmentRows.compactMap { row -> RecentEnrollment? in
            guard let patient = patientLookup[row.patientId],
                  let programName = programLookup[row.programLibraryId] else {
                return nil
            }

            return RecentEnrollment(
                id: row.id,
                enrollmentId: row.id,
                patientId: row.patientId,
                patientName: patient.fullName,
                programId: row.programLibraryId,
                programName: programName,
                enrolledAt: row.enrolledAt,
                status: EnrollmentStatus(rawValue: row.status) ?? .active,
                progressPercentage: row.progressPercentage
            )
        }

        logger.log("Loaded \(recentEnrollments.count) recent enrollments", level: .success)
        return recentEnrollments
    }

    /// Calculate summary statistics from loaded data
    private func calculateSummary() {
        let totalPrograms = programs.count
        let totalEnrollments = programs.reduce(0) { $0 + $1.enrollmentCount }
        let activeEnrollments = programs.reduce(0) { $0 + $1.activeCount }
        let completedEnrollments = programs.reduce(0) { $0 + $1.completedCount }

        let avgCompletionRate: Double
        let avgProgress: Double

        if !programs.isEmpty {
            // Weighted average based on enrollment count
            let totalWeightedCompletion = programs.reduce(0.0) { $0 + ($1.completionRate * Double($1.enrollmentCount)) }
            let totalWeightedProgress = programs.reduce(0.0) { $0 + ($1.averageProgress * Double($1.enrollmentCount)) }

            if totalEnrollments > 0 {
                avgCompletionRate = totalWeightedCompletion / Double(totalEnrollments)
                avgProgress = totalWeightedProgress / Double(totalEnrollments)
            } else {
                avgCompletionRate = 0
                avgProgress = 0
            }
        } else {
            avgCompletionRate = 0
            avgProgress = 0
        }

        summary = ProgramAnalyticsSummary(
            totalPrograms: totalPrograms,
            totalEnrollments: totalEnrollments,
            activeEnrollments: activeEnrollments,
            completedEnrollments: completedEnrollments,
            averageCompletionRate: avgCompletionRate,
            averageProgress: avgProgress
        )
    }
}

// MARK: - Helper Types

/// Row for decoding enrollment summary data
private struct EnrollmentSummaryRow: Codable {
    let id: UUID
    let programLibraryId: UUID
    let status: String
    let progressPercentage: Int

    enum CodingKeys: String, CodingKey {
        case id
        case programLibraryId = "program_library_id"
        case status
        case progressPercentage = "progress_percentage"
    }
}
