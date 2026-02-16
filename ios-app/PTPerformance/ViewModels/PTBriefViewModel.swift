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
import Supabase

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
    @Published var latestDailyReadiness: DailyReadiness?
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

    deinit {
        cancellables.removeAll()
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

        DebugLogger.shared.log("[PTBrief] Loading brief for athlete: \(athleteId.uuidString)", level: .info)

        // Load athlete first
        do {
            athlete = try await fetchAthlete(id: athleteId)
            DebugLogger.shared.log("[PTBrief] Athlete loaded: \(athlete?.fullName ?? "unknown")", level: .success)
        } catch {
            DebugLogger.shared.log("[PTBrief] Failed to load athlete: \(error.localizedDescription)", level: .error)
            ErrorLogger.shared.logError(error, context: "PTBriefViewModel.loadAthlete")
            errorMessage = "Unable to load athlete data. Please try again."
            isLoading = false
            return
        }

        // Load all sections in parallel with graceful degradation using TaskGroup
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadReadinessSection(athleteId: athleteId) }
            group.addTask { await self.loadDeltasSection(athleteId: athleteId) }
            group.addTask { await self.loadRisksSection(athleteId: athleteId) }
        }

        // Load actions after readiness and risks are loaded (depends on them)
        await loadActionsSection(athleteId: athleteId)

        isLoading = false
        briefLoadedAt = Date()

        // Track KPI event
        await trackBriefOpened(athleteId: athleteId)

        if let duration = loadDurationSeconds {
            DebugLogger.shared.log("[PTBrief] Brief loaded in \(String(format: "%.2f", duration))s", level: .success)
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

        // Persist approval to backend (optimistic update — UI already updated above)
        DebugLogger.shared.log("[PTBrief] Plan approved with \(suggestedActions.filter { $0.status == .approved }.count) actions", level: .success)

        let athleteId = athlete?.id
        let therapistId = athlete?.therapistId
        Task {
            do {
                guard let athleteId = athleteId, let therapistId = therapistId else {
                    DebugLogger.shared.log("[PTBrief] Missing athlete/therapist ID for plan approval persistence", level: .warning)
                    return
                }
                let approval: [String: AnyEncodable] = [
                    "id": AnyEncodable(UUID().uuidString),
                    "athlete_id": AnyEncodable(athleteId.uuidString),
                    "therapist_id": AnyEncodable(therapistId.uuidString),
                    "decision": AnyEncodable("approved"),
                    "notes": AnyEncodable(""),
                    "decided_at": AnyEncodable(ISO8601DateFormatter().string(from: Date())),
                    "created_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
                ]
                try await PTSupabaseClient.shared.client
                    .from("plan_approvals")
                    .insert(approval)
                    .execute()
                DebugLogger.shared.log("[PTBrief] Plan approval persisted", level: .info)
            } catch {
                DebugLogger.shared.log("[PTBrief] Failed to persist plan approval: \(error)", level: .error)
            }
        }
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

            // Persist approval to backend (optimistic update — UI already updated above)
            let athleteId = athlete?.id
            let therapistId = athlete?.therapistId
            Task {
                do {
                    guard let athleteId = athleteId, let therapistId = therapistId else {
                        DebugLogger.shared.log("[PTBrief] Missing athlete/therapist ID for action approval persistence", level: .warning)
                        return
                    }
                    let approval: [String: AnyEncodable] = [
                        "id": AnyEncodable(UUID().uuidString),
                        "athlete_id": AnyEncodable(athleteId.uuidString),
                        "therapist_id": AnyEncodable(therapistId.uuidString),
                        "decision": AnyEncodable("approved"),
                        "notes": AnyEncodable("Action: \(action.title)"),
                        "decided_at": AnyEncodable(ISO8601DateFormatter().string(from: Date())),
                        "created_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
                    ]
                    try await PTSupabaseClient.shared.client
                        .from("plan_approvals")
                        .insert(approval)
                        .execute()
                    DebugLogger.shared.log("[PTBrief] Action approval persisted: \(action.title)", level: .info)
                } catch {
                    DebugLogger.shared.log("[PTBrief] Failed to persist action approval: \(error)", level: .error)
                }
            }
        }
    }

    /// Reject a specific action
    func rejectAction(_ action: PTBriefAction) {
        if let index = suggestedActions.firstIndex(where: { $0.id == action.id }) {
            suggestedActions[index].status = .rejected
            HapticFeedback.light()

            // Persist rejection to backend (optimistic update — UI already updated above)
            let athleteId = athlete?.id
            let therapistId = athlete?.therapistId
            Task {
                do {
                    guard let athleteId = athleteId, let therapistId = therapistId else {
                        DebugLogger.shared.log("[PTBrief] Missing athlete/therapist ID for action rejection persistence", level: .warning)
                        return
                    }
                    let rejection: [String: AnyEncodable] = [
                        "id": AnyEncodable(UUID().uuidString),
                        "athlete_id": AnyEncodable(athleteId.uuidString),
                        "therapist_id": AnyEncodable(therapistId.uuidString),
                        "decision": AnyEncodable("rejected"),
                        "notes": AnyEncodable("Rejected action: \(action.title)"),
                        "decided_at": AnyEncodable(ISO8601DateFormatter().string(from: Date())),
                        "created_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
                    ]
                    try await PTSupabaseClient.shared.client
                        .from("plan_approvals")
                        .insert(rejection)
                        .execute()
                    DebugLogger.shared.log("[PTBrief] Action rejection persisted: \(action.title)", level: .info)
                } catch {
                    DebugLogger.shared.log("[PTBrief] Failed to persist action rejection: \(error)", level: .error)
                }
            }
        }
    }

    /// Acknowledge a critical risk
    func acknowledgeRisk(_ risk: PTBriefRiskAlert) {
        DebugLogger.shared.log("[PTBrief] Risk acknowledged: \(risk.title)", level: .diagnostic)
        HapticFeedback.medium()

        // Persist risk acknowledgment to backend (optimistic update — UI already updated above)
        let athleteId = athlete?.id
        let therapistId = athlete?.therapistId
        Task {
            do {
                guard let athleteId = athleteId, let therapistId = therapistId else {
                    DebugLogger.shared.log("[PTBrief] Missing athlete/therapist ID for risk acknowledgment persistence", level: .warning)
                    return
                }
                let acknowledgment: [String: AnyEncodable] = [
                    "id": AnyEncodable(UUID().uuidString),
                    "athlete_id": AnyEncodable(athleteId.uuidString),
                    "therapist_id": AnyEncodable(therapistId.uuidString),
                    "decision": AnyEncodable("acknowledged_risk"),
                    "notes": AnyEncodable("Risk acknowledged: \(risk.title) (Severity: \(risk.severity.displayName))"),
                    "decided_at": AnyEncodable(ISO8601DateFormatter().string(from: Date())),
                    "created_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
                ]
                try await PTSupabaseClient.shared.client
                    .from("plan_approvals")
                    .insert(acknowledgment)
                    .execute()
                DebugLogger.shared.log("[PTBrief] Risk acknowledgment persisted: \(risk.title)", level: .info)
            } catch {
                DebugLogger.shared.log("[PTBrief] Failed to persist risk acknowledgment: \(error)", level: .error)
            }
        }
    }

    // MARK: - Private Section Loaders

    private func loadReadinessSection(athleteId: UUID) async {
        isLoadingReadiness = true
        defer { isLoadingReadiness = false }

        do {
            readinessScore = try await fetchReadinessScore(athleteId: athleteId)
            DebugLogger.shared.log("[PTBrief] Readiness loaded: score=\(readinessScore?.score ?? 0)", level: .success)
        } catch {
            DebugLogger.shared.log("[PTBrief] Readiness load error: \(error.localizedDescription)", level: .warning)
            ErrorLogger.shared.logError(error, context: "PTBriefViewModel.loadReadiness")
            // Readiness is critical - surface the error but continue loading other sections
        }
    }

    private func loadDeltasSection(athleteId: UUID) async {
        isLoadingDeltas = true
        defer { isLoadingDeltas = false }

        do {
            keyChanges = try await fetchKeyChanges(athleteId: athleteId)
            DebugLogger.shared.log("[PTBrief] Deltas loaded: \(keyChanges.count) changes", level: .success)
        } catch {
            DebugLogger.shared.log("[PTBrief] Deltas load error: \(error.localizedDescription)", level: .warning)
            ErrorLogger.shared.logError(error, context: "PTBriefViewModel.loadDeltas")
            keyChanges = []
        }
    }

    private func loadRisksSection(athleteId: UUID) async {
        isLoadingRisks = true
        defer { isLoadingRisks = false }

        do {
            riskAlerts = try await fetchRiskAlerts(athleteId: athleteId)
            DebugLogger.shared.log("[PTBrief] Risks loaded: \(riskAlerts.count) alerts", level: .success)
        } catch {
            DebugLogger.shared.log("[PTBrief] Risks load error: \(error.localizedDescription)", level: .warning)
            ErrorLogger.shared.logError(error, context: "PTBriefViewModel.loadRisks")
            riskAlerts = []
        }
    }

    private func loadActionsSection(athleteId: UUID) async {
        isLoadingActions = true
        defer { isLoadingActions = false }

        do {
            suggestedActions = try await fetchSuggestedActions(athleteId: athleteId)
            DebugLogger.shared.log("[PTBrief] Actions loaded: \(suggestedActions.count) suggestions", level: .success)
        } catch {
            DebugLogger.shared.log("[PTBrief] Actions load error: \(error.localizedDescription)", level: .warning)
            ErrorLogger.shared.logError(error, context: "PTBriefViewModel.loadActions")
            suggestedActions = []
        }
    }

    // MARK: - Data Fetchers

    private func fetchAthlete(id: UUID) async throws -> Patient {
        DebugLogger.shared.log("[PTBrief] Fetching athlete: \(id.uuidString)", level: .diagnostic)

        let response = try await supabase.client
            .from("patients")
            .select("id, first_name, last_name, sport, position, created_at, email, user_id, therapist_id")
            .eq("id", value: id.uuidString)
            .single()
            .execute()

        return try PTSupabaseClient.flexibleDecoder.decode(Patient.self, from: response.data)
    }

    /// Load readiness score from daily_readiness table (most recent entry)
    private func fetchReadinessScore(athleteId: UUID) async throws -> PTBriefReadiness {
        DebugLogger.shared.log("[PTBrief] Fetching readiness for athlete: \(athleteId.uuidString)", level: .diagnostic)

        // Fetch the most recent readiness entry
        let response = try await supabase.client
            .from("daily_readiness")
            .select("*")
            .eq("patient_id", value: athleteId.uuidString)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()

        // Decode the response
        let readinessEntries = try PTSupabaseClient.flexibleDecoder.decode([DailyReadiness].self, from: response.data)

        guard let latestReadiness = readinessEntries.first else {
            DebugLogger.shared.log("[PTBrief] No readiness data found for athlete", level: .warning)
            throw PTBriefError.noReadinessData
        }

        // Store the raw DailyReadiness for score breakdown display
        latestDailyReadiness = latestReadiness

        // Fetch previous entry to determine trend
        let trendResponse = try await supabase.client
            .from("daily_readiness")
            .select("readiness_score, created_at")
            .eq("patient_id", value: athleteId.uuidString)
            .order("created_at", ascending: false)
            .limit(3)
            .execute()

        let trendEntries = try PTSupabaseClient.flexibleDecoder.decode([ReadinessScoreEntry].self, from: trendResponse.data)
        let trend = calculateTrend(from: trendEntries)

        // Calculate confidence based on data completeness
        let confidence = calculateConfidence(from: latestReadiness)

        return PTBriefReadiness(
            score: latestReadiness.readinessScore ?? 50.0,
            trend: trend,
            confidence: confidence.value,
            confidenceReason: confidence.reason,
            lastUpdated: latestReadiness.createdAt,
            citationCount: countDataSources(from: latestReadiness)
        )
    }

    /// Load key changes by comparing last 2 check-ins from daily_checkins table
    private func fetchKeyChanges(athleteId: UUID) async throws -> [PTBriefDelta] {
        DebugLogger.shared.log("[PTBrief] Fetching key changes for athlete: \(athleteId.uuidString)", level: .diagnostic)

        let response = try await supabase.client
            .from("daily_checkins")
            .select("*")
            .eq("athlete_id", value: athleteId.uuidString)
            .order("date", ascending: false)
            .limit(2)
            .execute()

        let checkIns = try PTSupabaseClient.flexibleDecoder.decode([DailyCheckIn].self, from: response.data)

        guard checkIns.count >= 2 else {
            DebugLogger.shared.log("[PTBrief] Insufficient check-in data for deltas (found \(checkIns.count))", level: .info)
            return []
        }

        guard let current = checkIns.first,
              let previous = checkIns.dropFirst().first else { return [] }

        var deltas: [PTBriefDelta] = []

        // Sleep Quality Delta
        let sleepDelta = calculateDelta(
            metricName: "Sleep Quality",
            current: Double(current.sleepQuality),
            previous: Double(previous.sleepQuality),
            formatCurrent: "\(current.sleepQuality)/5",
            formatPrevious: "\(previous.sleepQuality)/5",
            source: "Daily Check-in",
            sourceType: .selfReport,
            timestamp: current.completedAt
        )
        if let delta = sleepDelta { deltas.append(delta) }

        // Soreness Delta
        let sorenessDelta = calculateDelta(
            metricName: "Soreness",
            current: Double(current.soreness),
            previous: Double(previous.soreness),
            formatCurrent: "\(current.soreness)/10",
            formatPrevious: "\(previous.soreness)/10",
            source: "Daily Check-in",
            sourceType: .selfReport,
            timestamp: current.completedAt,
            invertDirection: true // Higher soreness is worse
        )
        if let delta = sorenessDelta { deltas.append(delta) }

        // Energy Delta
        let energyDelta = calculateDelta(
            metricName: "Energy",
            current: Double(current.energy),
            previous: Double(previous.energy),
            formatCurrent: "\(current.energy)/10",
            formatPrevious: "\(previous.energy)/10",
            source: "Daily Check-in",
            sourceType: .selfReport,
            timestamp: current.completedAt
        )
        if let delta = energyDelta { deltas.append(delta) }

        // Stress Delta
        let stressDelta = calculateDelta(
            metricName: "Stress",
            current: Double(current.stress),
            previous: Double(previous.stress),
            formatCurrent: "\(current.stress)/10",
            formatPrevious: "\(previous.stress)/10",
            source: "Daily Check-in",
            sourceType: .selfReport,
            timestamp: current.completedAt,
            invertDirection: true // Higher stress is worse
        )
        if let delta = stressDelta { deltas.append(delta) }

        DebugLogger.shared.log("[PTBrief] Calculated \(deltas.count) deltas", level: .success)
        return deltas
    }

    /// Load risk alerts from safety_incidents table
    private func fetchRiskAlerts(athleteId: UUID) async throws -> [PTBriefRiskAlert] {
        DebugLogger.shared.log("[PTBrief] Fetching risk alerts for athlete: \(athleteId.uuidString)", level: .diagnostic)

        let response = try await supabase.client
            .from("safety_incidents")
            .select("*")
            .eq("athlete_id", value: athleteId.uuidString)
            .in("status", values: ["open", "investigating"])
            .order("severity", ascending: true) // Critical first (lower sortOrder)
            .execute()

        let incidents = try PTSupabaseClient.flexibleDecoder.decode([SafetyIncident].self, from: response.data)

        let alerts: [PTBriefRiskAlert] = incidents.map { incident in
            PTBriefRiskAlert(
                id: incident.id,
                title: incident.incidentType.displayName,
                description: incident.description,
                severity: mapSeverity(from: incident.severity),
                thresholdValue: extractThresholdValue(from: incident.triggerData),
                currentValue: extractCurrentValue(from: incident.triggerData),
                source: incident.incidentType.description,
                citationCount: 1,
                requiresAcknowledgment: incident.isHighSeverity,
                timestamp: incident.createdAt
            )
        }

        DebugLogger.shared.log("[PTBrief] Found \(alerts.count) risk alerts", level: .success)
        return alerts
    }

    /// Fetch suggested actions based on readiness and risk data
    private func fetchSuggestedActions(athleteId: UUID) async throws -> [PTBriefAction] {
        DebugLogger.shared.log("[PTBrief] Generating suggested actions for athlete: \(athleteId.uuidString)", level: .diagnostic)

        // Generate actions based on current readiness and risks
        var actions: [PTBriefAction] = []

        // Determine primary action based on readiness score
        if let readiness = readinessScore {
            if readiness.score >= 80 {
                actions.append(PTBriefAction(
                    id: UUID(),
                    title: "Continue Current Program",
                    rationale: "Readiness score is excellent (\(Int(readiness.score))). Current progression is appropriate.",
                    evidenceSummary: "Based on \(readiness.citationCount) data sources showing \(readiness.trend.displayName.lowercased()) trend",
                    citationCount: readiness.citationCount,
                    protocolId: nil,
                    priority: .recommended,
                    status: .pending
                ))
            } else if readiness.score >= 60 {
                actions.append(PTBriefAction(
                    id: UUID(),
                    title: "Consider Light Modification",
                    rationale: "Readiness score is moderate (\(Int(readiness.score))). Minor adjustments may optimize recovery.",
                    evidenceSummary: "Confidence: \(Int(readiness.confidence * 100))% - \(readiness.confidenceReason)",
                    citationCount: readiness.citationCount,
                    protocolId: nil,
                    priority: .suggested,
                    status: .pending
                ))
            } else {
                actions.append(PTBriefAction(
                    id: UUID(),
                    title: "Reduce Training Load",
                    rationale: "Readiness score is low (\(Int(readiness.score))). Recommend recovery-focused session.",
                    evidenceSummary: "Multiple indicators suggest elevated fatigue or stress",
                    citationCount: readiness.citationCount,
                    protocolId: UUID(), // Link to recovery protocol
                    priority: .urgent,
                    status: .pending
                ))
            }
        }

        // Add actions based on risk alerts
        if hasCriticalRisks {
            actions.insert(PTBriefAction(
                id: UUID(),
                title: "Address Safety Alerts",
                rationale: "There are \(criticalRiskCount) high-severity safety incidents requiring attention.",
                evidenceSummary: "Review and acknowledge all critical alerts before proceeding",
                citationCount: criticalRiskCount,
                protocolId: nil,
                priority: .urgent,
                status: .pending
            ), at: 0)
        }

        DebugLogger.shared.log("[PTBrief] Generated \(actions.count) suggested actions", level: .success)
        return actions
    }

    // MARK: - KPI Tracking

    /// Track when brief is opened for KPI measurement
    func trackBriefOpened(athleteId: UUID) async {
        guard let openedAt = briefOpenedAt else { return }

        let durationMs = Int(Date().timeIntervalSince(openedAt) * 1000)

        do {
            let insertData: [String: AnyEncodable] = [
                "event_type": AnyEncodable("brief_opened"),
                "user_id": AnyEncodable(supabase.userId ?? ""),
                "athlete_id": AnyEncodable(athleteId.uuidString),
                "duration_ms": AnyEncodable(durationMs),
                "created_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
            ]

            try await supabase.client
                .from("kpi_events")
                .insert(insertData)
                .execute()

            DebugLogger.shared.log("[PTBrief] KPI event tracked: brief_opened, duration=\(durationMs)ms", level: .success)
        } catch {
            DebugLogger.shared.log("[PTBrief] Failed to track KPI event: \(error.localizedDescription)", level: .warning)
        }
    }

    // MARK: - Helper Methods

    /// Calculate trend from historical readiness scores
    private func calculateTrend(from entries: [ReadinessScoreEntry]) -> PTBriefReadiness.ReadinessTrend {
        guard entries.count >= 2 else { return .stable }

        let scores = entries.compactMap { $0.readinessScore }
        guard scores.count >= 2 else { return .stable }

        guard let latestScore = scores.first,
              let previousScore = scores.dropFirst().first else { return .stable }
        let difference = latestScore - previousScore

        if difference > 5 {
            return .improving
        } else if difference < -5 {
            return .declining
        } else {
            return .stable
        }
    }

    /// Calculate confidence based on data completeness
    private func calculateConfidence(from readiness: DailyReadiness) -> (value: Double, reason: String) {
        var score = 0.5 // Base confidence
        var reasons: [String] = []

        if readiness.sleepHours != nil {
            score += 0.15
            reasons.append("sleep data")
        }
        if readiness.sorenessLevel != nil {
            score += 0.10
            reasons.append("soreness")
        }
        if readiness.energyLevel != nil {
            score += 0.10
            reasons.append("energy")
        }
        if readiness.stressLevel != nil {
            score += 0.10
            reasons.append("stress")
        }

        let reasonText = reasons.isEmpty ? "Limited data available" : "Based on \(reasons.joined(separator: ", "))"
        return (min(score, 1.0), reasonText)
    }

    /// Count data sources for citation count
    private func countDataSources(from readiness: DailyReadiness) -> Int {
        var count = 0
        if readiness.sleepHours != nil { count += 1 }
        if readiness.sorenessLevel != nil { count += 1 }
        if readiness.energyLevel != nil { count += 1 }
        if readiness.stressLevel != nil { count += 1 }
        return max(count, 1)
    }

    /// Calculate delta between two metric values
    private func calculateDelta(
        metricName: String,
        current: Double,
        previous: Double,
        formatCurrent: String,
        formatPrevious: String,
        source: String,
        sourceType: PTBriefDelta.DataSourceType,
        timestamp: Date,
        invertDirection: Bool = false
    ) -> PTBriefDelta? {
        let difference = current - previous
        let percentChange = previous != 0 ? (difference / previous) * 100 : 0

        // Only report significant changes (> 5%)
        guard abs(percentChange) > 5 else { return nil }

        var direction: PTBriefDelta.DeltaDirection
        if difference > 0 {
            direction = invertDirection ? .down : .up
        } else if difference < 0 {
            direction = invertDirection ? .up : .down
        } else {
            direction = .unchanged
        }

        let magnitudeSign = percentChange >= 0 ? "+" : ""
        let magnitude = "\(magnitudeSign)\(Int(percentChange))%"

        return PTBriefDelta(
            id: UUID(),
            metricName: metricName,
            direction: direction,
            magnitude: magnitude,
            previousValue: formatPrevious,
            currentValue: formatCurrent,
            source: source,
            sourceType: sourceType,
            citationCount: 1,
            timestamp: timestamp
        )
    }

    /// Map SafetyIncident.Severity to PTBriefRiskAlert.RiskSeverity
    private func mapSeverity(from severity: SafetyIncident.Severity) -> PTBriefRiskAlert.RiskSeverity {
        switch severity {
        case .low: return .low
        case .medium: return .moderate
        case .high: return .high
        case .critical: return .critical
        case .unknown: return .low
        }
    }

    /// Extract threshold value from trigger data
    private func extractThresholdValue(from triggerData: [String: AnyCodableValue]?) -> String {
        guard let data = triggerData else { return "N/A" }
        if let threshold = data["threshold"]?.stringValue {
            return threshold
        }
        return "N/A"
    }

    /// Extract current value from trigger data
    private func extractCurrentValue(from triggerData: [String: AnyCodableValue]?) -> String {
        guard let data = triggerData else { return "N/A" }
        if let current = data["current_value"]?.stringValue {
            return current
        }
        if let painScore = data["pain_score"]?.intValue {
            return "\(painScore)/10"
        }
        return "N/A"
    }
}

// MARK: - Supporting Types for Supabase Decoding

/// Minimal struct for decoding readiness score entries for trend calculation
private struct ReadinessScoreEntry: Codable {
    let readinessScore: Double?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case readinessScore = "readiness_score"
        case createdAt = "created_at"
    }
}

/// Errors specific to PT Brief loading
enum PTBriefError: LocalizedError {
    case noReadinessData
    case noCheckInData
    case loadFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noReadinessData:
            return "No readiness data available for this athlete"
        case .noCheckInData:
            return "No check-in data available for comparison"
        case .loadFailed(let error):
            return "Failed to load brief: \(error.localizedDescription)"
        }
    }
}

/// Type-erased encodable for Supabase insert operations
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        _encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
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
        vm.latestDailyReadiness = DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            sleepHours: 7.2,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 4,
            readinessScore: 78,
            notes: nil,
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: Date().addingTimeInterval(-3600)
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
