//
//  ClinicalDocumentationDashboardViewModel.swift
//  PTPerformance
//
//  ViewModel for the clinical documentation dashboard providing an overview
//  of all documentation including pending drafts, recent assessments, and quick actions.
//

import SwiftUI
import Combine

// MARK: - Dashboard Item Models

/// Represents a pending draft item in the dashboard
struct PendingDraftItem: Identifiable {
    let id: UUID
    let type: DraftType
    let patientName: String
    let patientId: UUID
    let lastUpdated: Date
    let completionPercentage: Double

    enum DraftType: String {
        case assessment = "Assessment"
        case soapNote = "SOAP Note"
        case outcomeMeasure = "Outcome Measure"

        var iconName: String {
            switch self {
            case .assessment: return "clipboard"
            case .soapNote: return "doc.text"
            case .outcomeMeasure: return "chart.bar.doc.horizontal"
            }
        }

        var color: Color {
            switch self {
            case .assessment: return .blue
            case .soapNote: return .orange
            case .outcomeMeasure: return .purple
            }
        }
    }

    var formattedLastUpdated: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }

    var isStale: Bool {
        // Consider stale if not updated in 24 hours
        Date().timeIntervalSince(lastUpdated) > 86400
    }
}

/// Represents a recent assessment item
struct RecentAssessmentItem: Identifiable {
    let id: UUID
    let type: AssessmentType
    let patientName: String
    let patientId: UUID
    let date: Date
    let status: AssessmentStatus
    let painLevel: Int?

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

/// Represents a recent SOAP note item
struct RecentSOAPNoteItem: Identifiable {
    let id: UUID
    let patientName: String
    let patientId: UUID
    let date: Date
    let status: NoteStatus
    let previewText: String

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

/// Quick action for the dashboard
struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
    let color: Color
    let action: QuickActionType

    enum QuickActionType {
        case newIntakeAssessment
        case newProgressNote
        case newSOAPNote
        case newOutcomeMeasure
        case viewPendingDrafts
        case viewRecentPatients
    }
}

/// Dashboard statistics summary
struct DashboardStatistics {
    var pendingDraftsCount: Int = 0
    var documentsNeedingSignature: Int = 0
    var documentsSignedToday: Int = 0
    var assessmentsThisWeek: Int = 0
    var averagePainReduction: Double?
    var mcidAchievementRate: Double?
}

// MARK: - ClinicalDocumentationDashboardViewModel

/// ViewModel for the clinical documentation dashboard
@MainActor
class ClinicalDocumentationDashboardViewModel: ObservableObject {

    // MARK: - Published Properties - Data

    @Published var therapistId: UUID?
    @Published var pendingDrafts: [PendingDraftItem] = []
    @Published var recentAssessments: [RecentAssessmentItem] = []
    @Published var recentSOAPNotes: [RecentSOAPNoteItem] = []
    @Published var statistics = DashboardStatistics()
    @Published var quickActions: [QuickAction] = []

    // MARK: - Published Properties - UI State

    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?

    // Section-specific loading
    @Published var isLoadingDrafts = false
    @Published var isLoadingAssessments = false
    @Published var isLoadingSOAPNotes = false

    // Section-specific errors
    @Published var draftsError: String?
    @Published var assessmentsError: String?
    @Published var soapNotesError: String?

    // MARK: - Dependencies

    private let assessmentService: ClinicalAssessmentService
    private let soapNoteService: SOAPNoteService
    private let outcomeService: OutcomeMeasureService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Constants

    private enum Limits {
        static let pendingDrafts = 10
        static let recentAssessments = 5
        static let recentSOAPNotes = 5
    }

    // MARK: - Computed Properties

    /// Whether there are any pending drafts
    var hasPendingDrafts: Bool {
        !pendingDrafts.isEmpty
    }

    /// Count of stale drafts (not updated in 24+ hours)
    var staleDraftsCount: Int {
        pendingDrafts.filter { $0.isStale }.count
    }

    /// Whether there are documents needing signature
    var hasDocumentsNeedingSignature: Bool {
        statistics.documentsNeedingSignature > 0
    }

    /// Total pending items count
    var totalPendingCount: Int {
        statistics.pendingDraftsCount + statistics.documentsNeedingSignature
    }

    /// Whether any data has been loaded
    var hasData: Bool {
        !pendingDrafts.isEmpty || !recentAssessments.isEmpty || !recentSOAPNotes.isEmpty
    }

    /// Formatted MCID achievement rate
    var formattedMcidRate: String? {
        guard let rate = statistics.mcidAchievementRate else { return nil }
        return String(format: "%.0f%%", rate)
    }

    /// Formatted average pain reduction
    var formattedPainReduction: String? {
        guard let reduction = statistics.averagePainReduction else { return nil }
        let sign = reduction >= 0 ? "-" : "+"
        return "\(sign)\(String(format: "%.1f", abs(reduction)))"
    }

    // MARK: - Initialization

    init(
        assessmentService: ClinicalAssessmentService = ClinicalAssessmentService(),
        soapNoteService: SOAPNoteService = .shared,
        outcomeService: OutcomeMeasureService = .shared
    ) {
        self.assessmentService = assessmentService
        self.soapNoteService = soapNoteService
        self.outcomeService = outcomeService

        setupQuickActions()
    }

    // MARK: - Setup

    private func setupQuickActions() {
        quickActions = [
            QuickAction(
                title: "New Intake",
                iconName: "person.badge.plus",
                color: .blue,
                action: .newIntakeAssessment
            ),
            QuickAction(
                title: "Progress Note",
                iconName: "chart.line.uptrend.xyaxis",
                color: .orange,
                action: .newProgressNote
            ),
            QuickAction(
                title: "SOAP Note",
                iconName: "doc.text",
                color: .green,
                action: .newSOAPNote
            ),
            QuickAction(
                title: "Outcome Measure",
                iconName: "chart.bar.doc.horizontal",
                color: .purple,
                action: .newOutcomeMeasure
            )
        ]
    }

    // MARK: - Data Loading

    /// Initialize dashboard with therapist ID
    func initialize(therapistId: UUID) async {
        self.therapistId = therapistId
        await refreshDashboard()
    }

    /// Refresh all dashboard data
    func refreshDashboard() async {
        guard let therapistId = therapistId else {
            errorMessage = "Therapist ID required"
            return
        }

        isLoading = true
        isRefreshing = true
        errorMessage = nil

        // Clear previous errors
        draftsError = nil
        assessmentsError = nil
        soapNotesError = nil

        // Load data sections in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadPendingDrafts(therapistId: therapistId) }
            group.addTask { await self.loadRecentAssessments(therapistId: therapistId) }
            group.addTask { await self.loadRecentSOAPNotes(therapistId: therapistId) }
        }

        // Calculate statistics
        calculateStatistics()

        // Check if all sections failed
        if draftsError != nil && assessmentsError != nil && soapNotesError != nil {
            errorMessage = "Unable to load dashboard data. Please check your connection."
        }

        isLoading = false
        isRefreshing = false

        #if DEBUG
        print("[DashboardVM] Dashboard refresh complete")
        #endif
    }

    /// Load pending drafts
    private func loadPendingDrafts(therapistId: UUID) async {
        isLoadingDrafts = true

        do {
            // Fetch pending assessments
            let pendingAssessments = try await assessmentService.fetchPendingAssessments(for: therapistId)

            // Convert to dashboard items
            var drafts: [PendingDraftItem] = []

            for assessment in pendingAssessments.prefix(Limits.pendingDrafts) {
                // In real implementation, fetch patient name from patient service
                let item = PendingDraftItem(
                    id: assessment.id,
                    type: .assessment,
                    patientName: "Patient", // Would fetch from patient service
                    patientId: assessment.patientId,
                    lastUpdated: assessment.updatedAt,
                    completionPercentage: calculateAssessmentCompletion(assessment)
                )
                drafts.append(item)
            }

            // Also fetch pending SOAP notes
            let pendingNotes = soapNoteService.notes(byStatus: .draft)
            for note in pendingNotes.prefix(Limits.pendingDrafts - drafts.count) {
                let item = PendingDraftItem(
                    id: note.id,
                    type: .soapNote,
                    patientName: "Patient",
                    patientId: note.patientId,
                    lastUpdated: note.updatedAt,
                    completionPercentage: note.completenessPercentage
                )
                drafts.append(item)
            }

            pendingDrafts = drafts.sorted { $0.lastUpdated > $1.lastUpdated }

            #if DEBUG
            print("[DashboardVM] Loaded \(pendingDrafts.count) pending drafts")
            #endif
        } catch {
            draftsError = "Unable to load pending drafts"
            DebugLogger.shared.error("DashboardViewModel", "Drafts error: \(error)")
        }

        isLoadingDrafts = false
    }

    /// Load recent assessments
    private func loadRecentAssessments(therapistId: UUID) async {
        isLoadingAssessments = true

        do {
            let assessments = try await assessmentService.fetchAssessmentsByTherapist(
                therapistId,
                limit: Limits.recentAssessments
            )

            recentAssessments = assessments.map { assessment in
                RecentAssessmentItem(
                    id: assessment.id,
                    type: assessment.assessmentType,
                    patientName: "Patient", // Would fetch from patient service
                    patientId: assessment.patientId,
                    date: assessment.assessmentDate,
                    status: assessment.status,
                    painLevel: assessment.painWithActivity
                )
            }

            #if DEBUG
            print("[DashboardVM] Loaded \(recentAssessments.count) recent assessments")
            #endif
        } catch {
            assessmentsError = "Unable to load recent assessments"
            DebugLogger.shared.error("DashboardViewModel", "Assessments error: \(error)")
        }

        isLoadingAssessments = false
    }

    /// Load recent SOAP notes
    private func loadRecentSOAPNotes(therapistId: UUID) async {
        isLoadingSOAPNotes = true

        do {
            let notes = try await soapNoteService.fetchNotesForTherapist(therapistId.uuidString)

            recentSOAPNotes = notes.prefix(Limits.recentSOAPNotes).map { note in
                RecentSOAPNoteItem(
                    id: note.id,
                    patientName: "Patient", // Would fetch from patient service
                    patientId: note.patientId,
                    date: note.noteDate,
                    status: note.status,
                    previewText: note.previewText
                )
            }

            #if DEBUG
            print("[DashboardVM] Loaded \(recentSOAPNotes.count) recent SOAP notes")
            #endif
        } catch {
            soapNotesError = "Unable to load recent SOAP notes"
            DebugLogger.shared.error("DashboardViewModel", "SOAP notes error: \(error)")
        }

        isLoadingSOAPNotes = false
    }

    // MARK: - Statistics Calculation

    /// Calculate dashboard statistics
    private func calculateStatistics() {
        var stats = DashboardStatistics()

        // Pending drafts count
        stats.pendingDraftsCount = pendingDrafts.count

        // Documents needing signature (complete but not signed)
        let completeAssessments = recentAssessments.filter { $0.status == .complete }
        let completeNotes = recentSOAPNotes.filter { $0.status == .complete }
        stats.documentsNeedingSignature = completeAssessments.count + completeNotes.count

        // Documents signed today
        let today = Calendar.current.startOfDay(for: Date())
        let signedAssessmentsToday = recentAssessments.filter {
            $0.status == .signed && Calendar.current.isDate($0.date, inSameDayAs: today)
        }
        let signedNotesToday = recentSOAPNotes.filter {
            $0.status == .signed && Calendar.current.isDate($0.date, inSameDayAs: today)
        }
        stats.documentsSignedToday = signedAssessmentsToday.count + signedNotesToday.count

        // Assessments this week
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        stats.assessmentsThisWeek = recentAssessments.filter { $0.date >= weekAgo }.count

        // Calculate average pain reduction (simplified - would need more data)
        if let firstAssessment = recentAssessments.last,
           let lastAssessment = recentAssessments.first,
           let firstPain = firstAssessment.painLevel,
           let lastPain = lastAssessment.painLevel {
            stats.averagePainReduction = Double(firstPain - lastPain)
        }

        statistics = stats
    }

    /// Calculate assessment completion percentage
    private func calculateAssessmentCompletion(_ assessment: ClinicalAssessment) -> Double {
        var filled = 0
        let total = 7

        if assessment.chiefComplaint != nil { filled += 1 }
        if assessment.historyOfPresentIllness != nil { filled += 1 }
        if assessment.painAtRest != nil || assessment.painWithActivity != nil { filled += 1 }
        if assessment.romMeasurements?.isEmpty == false { filled += 1 }
        if assessment.objectiveFindings != nil { filled += 1 }
        if assessment.assessmentSummary != nil { filled += 1 }
        if assessment.treatmentPlan != nil { filled += 1 }

        return Double(filled) / Double(total) * 100
    }

    // MARK: - Actions

    /// Delete a pending draft
    func deleteDraft(_ draft: PendingDraftItem) async {
        do {
            switch draft.type {
            case .assessment:
                try await assessmentService.deleteAssessment(draft.id)
            case .soapNote:
                try await soapNoteService.deleteNote(id: draft.id.uuidString)
            case .outcomeMeasure:
                try await outcomeService.deleteOutcomeMeasure(id: draft.id)
            }

            // Remove from local list
            pendingDrafts.removeAll { $0.id == draft.id }
            statistics.pendingDraftsCount = pendingDrafts.count

            #if DEBUG
            print("[DashboardVM] Deleted draft: \(draft.id)")
            #endif
        } catch {
            errorMessage = "Failed to delete draft: \(error.localizedDescription)"
        }
    }

    /// Get all drafts for a specific type
    func getDrafts(ofType type: PendingDraftItem.DraftType) -> [PendingDraftItem] {
        pendingDrafts.filter { $0.type == type }
    }

    /// Get assessments needing signature
    func getAssessmentsNeedingSignature() -> [RecentAssessmentItem] {
        recentAssessments.filter { $0.status == .complete }
    }

    /// Get SOAP notes needing signature
    func getSOAPNotesNeedingSignature() -> [RecentSOAPNoteItem] {
        recentSOAPNotes.filter { $0.status == .complete }
    }

    // MARK: - Helpers

    /// Clear error messages
    func clearErrors() {
        errorMessage = nil
        draftsError = nil
        assessmentsError = nil
        soapNotesError = nil
    }

    /// Force refresh
    func forceRefresh() async {
        await refreshDashboard()
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension ClinicalDocumentationDashboardViewModel {
    static var preview: ClinicalDocumentationDashboardViewModel {
        let viewModel = ClinicalDocumentationDashboardViewModel()
        viewModel.therapistId = UUID()

        // Sample pending drafts
        viewModel.pendingDrafts = [
            PendingDraftItem(
                id: UUID(),
                type: .assessment,
                patientName: "John Smith",
                patientId: UUID(),
                lastUpdated: Date().addingTimeInterval(-3600),
                completionPercentage: 75
            ),
            PendingDraftItem(
                id: UUID(),
                type: .soapNote,
                patientName: "Jane Doe",
                patientId: UUID(),
                lastUpdated: Date().addingTimeInterval(-86400),
                completionPercentage: 50
            )
        ]

        // Sample recent assessments
        viewModel.recentAssessments = [
            RecentAssessmentItem(
                id: UUID(),
                type: .intake,
                patientName: "John Smith",
                patientId: UUID(),
                date: Date(),
                status: .complete,
                painLevel: 4
            ),
            RecentAssessmentItem(
                id: UUID(),
                type: .progress,
                patientName: "Jane Doe",
                patientId: UUID(),
                date: Date().addingTimeInterval(-86400),
                status: .signed,
                painLevel: 3
            )
        ]

        // Sample recent SOAP notes
        viewModel.recentSOAPNotes = [
            RecentSOAPNoteItem(
                id: UUID(),
                patientName: "John Smith",
                patientId: UUID(),
                date: Date(),
                status: .signed,
                previewText: "Patient reports decreased shoulder pain..."
            )
        ]

        // Sample statistics
        viewModel.statistics = DashboardStatistics(
            pendingDraftsCount: 2,
            documentsNeedingSignature: 1,
            documentsSignedToday: 3,
            assessmentsThisWeek: 8,
            averagePainReduction: 2.5,
            mcidAchievementRate: 75
        )

        return viewModel
    }
}
#endif
