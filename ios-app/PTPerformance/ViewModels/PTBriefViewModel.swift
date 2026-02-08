//
//  PTBriefViewModel.swift
//  PTPerformance
//
//  PT 60-Second Athlete Brief ViewModel
//  Core PT workflow for X2Index - provides actionable readiness in 60 seconds
//
//  M4 Product Plan: PT opens brief in <=2 taps
//  Includes: readiness score, key deltas, risks, next actions, all with citations
//

import SwiftUI
import Combine

// MARK: - Supporting Types

/// Represents a key change/delta since last session
struct PTBriefDelta: Identifiable, Equatable {
    let id: UUID
    let metricName: String
    let direction: DeltaDirection
    let magnitude: String
    let previousValue: String
    let currentValue: String
    let source: String
    let sourceType: DataSourceType
    let citationCount: Int
    let timestamp: Date

    enum DeltaDirection: String {
        case up = "up"
        case down = "down"
        case unchanged = "unchanged"

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .unchanged: return "arrow.right"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .orange
            case .unchanged: return .gray
            }
        }
    }

    enum DataSourceType: String {
        case wearable = "Wearable"
        case selfReport = "Self-Report"
        case assessment = "Assessment"
        case aiInference = "AI Inference"

        var icon: String {
            switch self {
            case .wearable: return "applewatch"
            case .selfReport: return "person.fill.questionmark"
            case .assessment: return "clipboard.fill"
            case .aiInference: return "sparkles"
            }
        }
    }
}

/// Represents a risk alert requiring PT attention
struct PTBriefRiskAlert: Identifiable, Equatable {
    let id: UUID
    let title: String
    let description: String
    let severity: RiskSeverity
    let thresholdValue: String
    let currentValue: String
    let source: String
    let citationCount: Int
    let requiresAcknowledgment: Bool
    let timestamp: Date

    enum RiskSeverity: Int, Comparable {
        case low = 1
        case moderate = 2
        case high = 3
        case critical = 4

        static func < (lhs: RiskSeverity, rhs: RiskSeverity) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        var color: Color {
            switch self {
            case .low: return .yellow
            case .moderate: return .orange
            case .high: return .red
            case .critical: return .red
            }
        }

        var displayName: String {
            switch self {
            case .low: return "Low"
            case .moderate: return "Moderate"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }

        var icon: String {
            switch self {
            case .low: return "exclamationmark.circle"
            case .moderate: return "exclamationmark.triangle"
            case .high: return "exclamationmark.triangle.fill"
            case .critical: return "exclamationmark.octagon.fill"
            }
        }
    }
}

/// Represents a suggested action/protocol recommendation
struct PTBriefAction: Identifiable, Equatable {
    let id: UUID
    let title: String
    let rationale: String
    let evidenceSummary: String
    let citationCount: Int
    let protocolId: UUID?
    let priority: ActionPriority
    var status: ActionStatus

    enum ActionPriority: Int, Comparable {
        case suggested = 1
        case recommended = 2
        case urgent = 3

        static func < (lhs: ActionPriority, rhs: ActionPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        var color: Color {
            switch self {
            case .suggested: return .blue
            case .recommended: return .modusCyan
            case .urgent: return .orange
            }
        }

        var displayName: String {
            switch self {
            case .suggested: return "Suggested"
            case .recommended: return "Recommended"
            case .urgent: return "Urgent"
            }
        }
    }

    enum ActionStatus: String {
        case pending = "pending"
        case approved = "approved"
        case rejected = "rejected"
    }
}

/// Readiness score with trend and confidence
struct PTBriefReadiness: Equatable {
    let score: Double
    let trend: ReadinessTrend
    let confidence: Double // 0.0 to 1.0
    let confidenceReason: String
    let lastUpdated: Date
    let citationCount: Int

    enum ReadinessTrend: String {
        case improving = "improving"
        case stable = "stable"
        case declining = "declining"

        var icon: String {
            switch self {
            case .improving: return "arrow.up.right"
            case .stable: return "arrow.right"
            case .declining: return "arrow.down.right"
            }
        }

        var color: Color {
            switch self {
            case .improving: return .green
            case .stable: return .gray
            case .declining: return .orange
            }
        }

        var displayName: String {
            switch self {
            case .improving: return "Improving"
            case .stable: return "Stable"
            case .declining: return "Declining"
            }
        }
    }

    var scoreColor: Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }

    var scoreLabel: String {
        switch score {
        case 80...: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Moderate"
        default: return "Low"
        }
    }
}

// MARK: - ViewModel

/// PT Brief ViewModel - Core PT workflow for 60-second athlete review
/// Tracks KPI: "brief opened" time for M4 measurement
@MainActor
final class PTBriefViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var athlete: Patient?
    @Published var readinessScore: PTBriefReadiness?
    @Published var keyChanges: [PTBriefDelta] = []
    @Published var riskAlerts: [PTBriefRiskAlert] = []
    @Published var suggestedActions: [PTBriefAction] = []

    @Published var isLoading = false
    @Published var errorMessage: String?

    // Section-specific loading states
    @Published var isLoadingReadiness = false
    @Published var isLoadingDeltas = false
    @Published var isLoadingRisks = false
    @Published var isLoadingActions = false

    // KPI Tracking
    @Published private(set) var briefOpenedAt: Date?
    @Published private(set) var briefLoadedAt: Date?

    // Navigation state
    @Published var showScoreBreakdown = false
    @Published var showEvidenceDetail = false
    @Published var showProtocolBuilder = false
    @Published var selectedDelta: PTBriefDelta?
    @Published var selectedRisk: PTBriefRiskAlert?

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared
    private let analyticsService: AnalyticsService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    /// Whether there are any critical risks requiring acknowledgment
    var hasCriticalRisks: Bool {
        riskAlerts.contains { $0.severity >= .high && $0.requiresAcknowledgment }
    }

    /// Count of unacknowledged critical risks
    var criticalRiskCount: Int {
        riskAlerts.filter { $0.severity >= .high && $0.requiresAcknowledgment }.count
    }

    /// Top 3 key changes for the summary view
    var topChanges: [PTBriefDelta] {
        Array(keyChanges.prefix(3))
    }

    /// Whether all data is loaded
    var isFullyLoaded: Bool {
        !isLoadingReadiness && !isLoadingDeltas && !isLoadingRisks && !isLoadingActions
    }

    /// Time to load brief (KPI metric)
    var loadDurationSeconds: Double? {
        guard let opened = briefOpenedAt, let loaded = briefLoadedAt else { return nil }
        return loaded.timeIntervalSince(opened)
    }

    /// Formatted last session date
    var lastSessionDateFormatted: String? {
        guard let lastSession = athlete?.lastSessionDate else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastSession, relativeTo: Date())
    }

    // MARK: - Initialization

    init(analyticsService: AnalyticsService? = nil) {
        self.analyticsService = analyticsService ?? AnalyticsService(supabase: PTSupabaseClient.shared)
    }

    // MARK: - Public Methods

    /// Load the complete brief for an athlete
    /// Tracks brief opened time for KPI measurement
    func loadBrief(athleteId: UUID) async {
        // Track KPI: when brief was opened
        briefOpenedAt = Date()
        briefLoadedAt = nil

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
            // Track KPI: when brief finished loading
            briefLoadedAt = Date()

            #if DEBUG
            if let duration = loadDurationSeconds {
                print("KPI [PTBrief] Load duration: \(String(format: "%.2f", duration))s")
            }
            #endif
        }

        // Load athlete first
        do {
            athlete = try await fetchAthlete(id: athleteId)
        } catch {
            ErrorLogger.shared.logError(error, context: "PTBriefViewModel.loadAthlete")
            errorMessage = "Unable to load athlete data. Please try again."
            return
        }

        // Load all sections in parallel with graceful degradation
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadReadinessSection(athleteId: athleteId) }
            group.addTask { await self.loadDeltasSection(athleteId: athleteId) }
            group.addTask { await self.loadRisksSection(athleteId: athleteId) }
            group.addTask { await self.loadActionsSection(athleteId: athleteId) }
        }
    }

    /// Refresh the brief
    func refresh(athleteId: UUID) async {
        await loadBrief(athleteId: athleteId)
    }

    /// Approve the current plan
    func approvePlan() async {
        HapticFeedback.success()

        // Mark all pending actions as approved
        for index in suggestedActions.indices {
            if suggestedActions[index].status == .pending {
                suggestedActions[index].status = .approved
            }
        }

        // TODO: Persist approval to backend
        #if DEBUG
        print("[PTBrief] Plan approved with \(suggestedActions.filter { $0.status == .approved }.count) actions")
        #endif
    }

    /// Open the protocol builder for plan adjustment
    func openProtocolBuilder() {
        showProtocolBuilder = true
        HapticFeedback.light()
    }

    /// Approve a specific action
    func approveAction(_ action: PTBriefAction) {
        if let index = suggestedActions.firstIndex(where: { $0.id == action.id }) {
            suggestedActions[index].status = .approved
            HapticFeedback.light()
        }
    }

    /// Reject a specific action
    func rejectAction(_ action: PTBriefAction) {
        if let index = suggestedActions.firstIndex(where: { $0.id == action.id }) {
            suggestedActions[index].status = .rejected
            HapticFeedback.light()
        }
    }

    /// Acknowledge a critical risk
    func acknowledgeRisk(_ risk: PTBriefRiskAlert) {
        // In production, this would record the acknowledgment
        #if DEBUG
        print("[PTBrief] Risk acknowledged: \(risk.title)")
        #endif
        HapticFeedback.medium()
    }

    // MARK: - Private Section Loaders

    private func loadReadinessSection(athleteId: UUID) async {
        isLoadingReadiness = true
        defer { isLoadingReadiness = false }

        do {
            readinessScore = try await fetchReadinessScore(athleteId: athleteId)
        } catch {
            ErrorLogger.shared.logError(error, context: "PTBriefViewModel.loadReadiness")
            // Readiness is critical - surface the error but continue loading other sections
            #if DEBUG
            print("[PTBrief] Readiness load error: \(error.localizedDescription)")
            #endif
        }
    }

    private func loadDeltasSection(athleteId: UUID) async {
        isLoadingDeltas = true
        defer { isLoadingDeltas = false }

        do {
            keyChanges = try await fetchKeyChanges(athleteId: athleteId)
        } catch {
            ErrorLogger.shared.logError(error, context: "PTBriefViewModel.loadDeltas")
            keyChanges = []
        }
    }

    private func loadRisksSection(athleteId: UUID) async {
        isLoadingRisks = true
        defer { isLoadingRisks = false }

        do {
            riskAlerts = try await fetchRiskAlerts(athleteId: athleteId)
        } catch {
            ErrorLogger.shared.logError(error, context: "PTBriefViewModel.loadRisks")
            riskAlerts = []
        }
    }

    private func loadActionsSection(athleteId: UUID) async {
        isLoadingActions = true
        defer { isLoadingActions = false }

        do {
            suggestedActions = try await fetchSuggestedActions(athleteId: athleteId)
        } catch {
            ErrorLogger.shared.logError(error, context: "PTBriefViewModel.loadActions")
            suggestedActions = []
        }
    }

    // MARK: - Data Fetchers

    private func fetchAthlete(id: UUID) async throws -> Patient {
        let response = try await supabase.client
            .from("patients")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Patient.self, from: response.data)
    }

    private func fetchReadinessScore(athleteId: UUID) async throws -> PTBriefReadiness {
        // TODO: Replace with actual API call
        // For now, generate representative mock data

        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)

        return PTBriefReadiness(
            score: Double.random(in: 55...95),
            trend: [.improving, .stable, .declining].randomElement()!,
            confidence: Double.random(in: 0.7...0.95),
            confidenceReason: "Based on 5 data sources, 3 days of history",
            lastUpdated: Date().addingTimeInterval(-Double.random(in: 3600...14400)),
            citationCount: Int.random(in: 3...8)
        )
    }

    private func fetchKeyChanges(athleteId: UUID) async throws -> [PTBriefDelta] {
        // TODO: Replace with actual API call
        // For now, generate representative mock data

        try await Task.sleep(nanoseconds: 150_000_000)

        let mockDeltas: [PTBriefDelta] = [
            PTBriefDelta(
                id: UUID(),
                metricName: "HRV",
                direction: .up,
                magnitude: "+15%",
                previousValue: "45 ms",
                currentValue: "52 ms",
                source: "Apple Watch",
                sourceType: .wearable,
                citationCount: 2,
                timestamp: Date().addingTimeInterval(-7200)
            ),
            PTBriefDelta(
                id: UUID(),
                metricName: "Sleep Quality",
                direction: .down,
                magnitude: "-12%",
                previousValue: "85%",
                currentValue: "75%",
                source: "Self-Report",
                sourceType: .selfReport,
                citationCount: 1,
                timestamp: Date().addingTimeInterval(-28800)
            ),
            PTBriefDelta(
                id: UUID(),
                metricName: "Arm Soreness",
                direction: .unchanged,
                magnitude: "0",
                previousValue: "3/10",
                currentValue: "3/10",
                source: "Daily Check-in",
                sourceType: .selfReport,
                citationCount: 1,
                timestamp: Date().addingTimeInterval(-3600)
            )
        ]

        return mockDeltas
    }

    private func fetchRiskAlerts(athleteId: UUID) async throws -> [PTBriefRiskAlert] {
        // TODO: Replace with actual API call

        try await Task.sleep(nanoseconds: 100_000_000)

        // Randomly return some risks or none
        if Bool.random() {
            return [
                PTBriefRiskAlert(
                    id: UUID(),
                    title: "Elevated Workload",
                    description: "Acute:chronic workload ratio exceeds recommended threshold",
                    severity: .moderate,
                    thresholdValue: "1.3",
                    currentValue: "1.45",
                    source: "Workload Calculator",
                    citationCount: 3,
                    requiresAcknowledgment: false,
                    timestamp: Date()
                )
            ]
        }

        return []
    }

    private func fetchSuggestedActions(athleteId: UUID) async throws -> [PTBriefAction] {
        // TODO: Replace with actual API call

        try await Task.sleep(nanoseconds: 180_000_000)

        return [
            PTBriefAction(
                id: UUID(),
                title: "Continue Current Program",
                rationale: "Readiness score is within target range. Current progression is appropriate.",
                evidenceSummary: "Based on HRV trend, sleep quality, and subjective readiness",
                citationCount: 4,
                protocolId: nil,
                priority: .recommended,
                status: .pending
            ),
            PTBriefAction(
                id: UUID(),
                title: "Add Recovery Session",
                rationale: "Sleep quality decline suggests additional recovery may benefit performance.",
                evidenceSummary: "Sleep score dropped 12% vs 7-day average",
                citationCount: 2,
                protocolId: UUID(),
                priority: .suggested,
                status: .pending
            )
        ]
    }
}

// MARK: - Preview Support

#if DEBUG
extension PTBriefViewModel {
    static var preview: PTBriefViewModel {
        let vm = PTBriefViewModel()

        vm.athlete = Patient.samplePatients.first
        vm.readinessScore = PTBriefReadiness(
            score: 78,
            trend: .improving,
            confidence: 0.85,
            confidenceReason: "5 data sources, high consistency",
            lastUpdated: Date().addingTimeInterval(-3600),
            citationCount: 6
        )
        vm.keyChanges = [
            PTBriefDelta(
                id: UUID(),
                metricName: "HRV",
                direction: .up,
                magnitude: "+15%",
                previousValue: "45 ms",
                currentValue: "52 ms",
                source: "Apple Watch",
                sourceType: .wearable,
                citationCount: 2,
                timestamp: Date()
            ),
            PTBriefDelta(
                id: UUID(),
                metricName: "Sleep",
                direction: .down,
                magnitude: "-12%",
                previousValue: "85%",
                currentValue: "75%",
                source: "Self-Report",
                sourceType: .selfReport,
                citationCount: 1,
                timestamp: Date()
            ),
            PTBriefDelta(
                id: UUID(),
                metricName: "Soreness",
                direction: .unchanged,
                magnitude: "0",
                previousValue: "3/10",
                currentValue: "3/10",
                source: "Check-in",
                sourceType: .selfReport,
                citationCount: 1,
                timestamp: Date()
            )
        ]
        vm.riskAlerts = [
            PTBriefRiskAlert(
                id: UUID(),
                title: "Elevated Workload Ratio",
                description: "ACWR exceeds recommended threshold",
                severity: .moderate,
                thresholdValue: "1.3",
                currentValue: "1.45",
                source: "Workload Calculator",
                citationCount: 3,
                requiresAcknowledgment: false,
                timestamp: Date()
            )
        ]
        vm.suggestedActions = [
            PTBriefAction(
                id: UUID(),
                title: "Continue Current Program",
                rationale: "Readiness within target range",
                evidenceSummary: "HRV, sleep, subjective all stable",
                citationCount: 4,
                protocolId: nil,
                priority: .recommended,
                status: .pending
            ),
            PTBriefAction(
                id: UUID(),
                title: "Add Recovery Session",
                rationale: "Compensate for sleep decline",
                evidenceSummary: "Sleep -12% vs 7-day avg",
                citationCount: 2,
                protocolId: UUID(),
                priority: .suggested,
                status: .pending
            )
        ]

        return vm
    }
}
#endif
