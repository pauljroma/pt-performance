//
//  KPITrackingService.swift
//  PTPerformance
//
//  KPI Tracking Service for X2Index
//  M10: KPI dashboard tracks PT prep time, WAU, adherence, citation coverage, latency, safety events
//
//  North Star Guardrails:
//  - PT weekly active usage >= 65%
//  - Athlete weekly active usage >= 60%
//  - Citation coverage for AI claims >= 95%
//  - p95 summary latency <= 5s
//  - Unresolved high-severity safety incidents = 0
//

import Foundation
import Supabase

// MARK: - KPI Tracking Service

/// Service for tracking KPI events and generating dashboards
/// Tracks all key performance indicators for the X2Index system
@MainActor
final class KPITrackingService: ObservableObject {

    // MARK: - Singleton

    static let shared = KPITrackingService()

    // MARK: - Published Properties

    @Published private(set) var currentDashboard: KPIDashboard?
    @Published private(set) var isLoading = false
    @Published var lastError: Error?

    // MARK: - Private Properties

    private let supabase: PTSupabaseClient
    private let safetyService: SafetyService
    private let errorLogger = ErrorLogger.shared

    // MARK: - Initialization

    init(supabase: PTSupabaseClient = .shared, safetyService: SafetyService = .shared) {
        self.supabase = supabase
        self.safetyService = safetyService
    }

    // MARK: - Event Tracking

    /// Track when a PT opens an athlete brief
    /// - Parameters:
    ///   - ptId: The PT's user ID
    ///   - athleteId: The athlete's ID
    ///   - durationMs: Time spent viewing the brief in milliseconds
    func trackBriefOpened(ptId: UUID, athleteId: UUID, durationMs: Int? = nil) async {
        await trackEvent(
            type: .briefOpened,
            userId: ptId,
            athleteId: athleteId,
            durationMs: durationMs,
            metadata: nil
        )
    }

    /// Track when an athlete completes a check-in
    /// - Parameters:
    ///   - athleteId: The athlete's ID
    ///   - durationMs: Time to complete check-in in milliseconds
    func trackCheckInCompleted(athleteId: UUID, durationMs: Int? = nil) async {
        await trackEvent(
            type: .checkInCompleted,
            userId: nil,
            athleteId: athleteId,
            durationMs: durationMs,
            metadata: nil
        )
    }

    /// Track when a PT assigns a plan to an athlete
    /// - Parameters:
    ///   - ptId: The PT's user ID
    ///   - athleteId: The athlete's ID
    func trackPlanAssigned(ptId: UUID, athleteId: UUID) async {
        await trackEvent(
            type: .planAssigned,
            userId: ptId,
            athleteId: athleteId,
            durationMs: nil,
            metadata: nil
        )
    }

    /// Track when an AI claim is generated
    /// - Parameters:
    ///   - claimId: The claim's ID
    ///   - hasCitations: Whether the claim has citations
    ///   - confidence: The AI confidence score (0.0-1.0)
    ///   - latencyMs: Time to generate the claim in milliseconds
    func trackAIClaim(claimId: UUID, hasCitations: Bool, confidence: Double, latencyMs: Int) async {
        let metadata: [String: AnyCodableValue] = [
            "claim_id": .string(claimId.uuidString),
            "has_citations": .bool(hasCitations),
            "confidence": .double(confidence),
            "latency_ms": .int(latencyMs),
            "abstained": .bool(safetyService.shouldAbstain(confidence: confidence)),
            "uncertainty_flagged": .bool(safetyService.shouldShowUncertainty(confidence: confidence))
        ]

        await trackEvent(
            type: .aiClaimGenerated,
            userId: nil,
            athleteId: nil,
            durationMs: latencyMs,
            metadata: metadata
        )
    }

    /// Track session started
    /// - Parameters:
    ///   - athleteId: The athlete's ID
    ///   - sessionId: The session ID
    func trackSessionStarted(athleteId: UUID, sessionId: UUID) async {
        await trackEvent(
            type: .sessionStarted,
            userId: nil,
            athleteId: athleteId,
            durationMs: nil,
            metadata: ["session_id": .string(sessionId.uuidString)]
        )
    }

    /// Track session completed
    /// - Parameters:
    ///   - athleteId: The athlete's ID
    ///   - sessionId: The session ID
    ///   - durationMs: Session duration in milliseconds
    func trackSessionCompleted(athleteId: UUID, sessionId: UUID, durationMs: Int) async {
        await trackEvent(
            type: .sessionCompleted,
            userId: nil,
            athleteId: athleteId,
            durationMs: durationMs,
            metadata: ["session_id": .string(sessionId.uuidString)]
        )
    }

    /// Track task completed
    /// - Parameters:
    ///   - athleteId: The athlete's ID
    ///   - taskType: Type of task completed
    func trackTaskCompleted(athleteId: UUID, taskType: String) async {
        await trackEvent(
            type: .taskCompleted,
            userId: nil,
            athleteId: athleteId,
            durationMs: nil,
            metadata: ["task_type": .string(taskType)]
        )
    }

    /// Generic event tracking
    private func trackEvent(
        type: KPIEventType,
        userId: UUID?,
        athleteId: UUID?,
        durationMs: Int?,
        metadata: [String: AnyCodableValue]?
    ) async {
        do {
            var insertData: [String: AnyEncodable] = [
                "event_type": AnyEncodable(type.rawValue),
                "created_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
            ]

            if let userId = userId {
                insertData["user_id"] = AnyEncodable(userId.uuidString)
            }
            if let athleteId = athleteId {
                insertData["athlete_id"] = AnyEncodable(athleteId.uuidString)
            }
            if let durationMs = durationMs {
                insertData["duration_ms"] = AnyEncodable(durationMs)
            }
            if let metadata = metadata {
                insertData["metadata"] = AnyEncodable(metadata)
            }

            try await supabase.client
                .from("kpi_events")
                .insert(insertData)
                .execute()
        } catch {
            errorLogger.logError(error, context: "KPITrackingService.trackEvent(\(type.rawValue))")
        }
    }

    // MARK: - Dashboard Generation

    /// Get the KPI dashboard for a time period
    /// - Parameter periodDays: Number of days to include (default: 7)
    /// - Returns: KPI dashboard with all metrics
    func getDashboard(periodDays: Int = 7) async -> KPIDashboard {
        isLoading = true
        defer { isLoading = false }

        let periodEnd = Date()
        let periodStart = Calendar.current.date(byAdding: .day, value: -periodDays, to: periodEnd)!

        async let ptMetrics = fetchPTMetrics(from: periodStart, to: periodEnd)
        async let athleteMetrics = fetchAthleteMetrics(from: periodStart, to: periodEnd)
        async let aiMetrics = fetchAIMetrics(from: periodStart, to: periodEnd)
        async let safetyMetrics = fetchSafetyMetrics(from: periodStart, to: periodEnd)

        let dashboard = await KPIDashboard(
            periodStart: periodStart,
            periodEnd: periodEnd,
            ptMetrics: ptMetrics,
            athleteMetrics: athleteMetrics,
            aiMetrics: aiMetrics,
            safetyMetrics: safetyMetrics
        )

        currentDashboard = dashboard
        return dashboard
    }

    /// Refresh the current dashboard
    func refreshDashboard() async {
        _ = await getDashboard()
    }

    // MARK: - Metric Fetching

    /// Fetch PT metrics for a time period
    private func fetchPTMetrics(from periodStart: Date, to periodEnd: Date) async -> PTMetrics {
        do {
            // Get total PTs (users with therapist role)
            let totalResponse = try await supabase.client
                .from("user_roles")
                .select("user_id", head: false, count: .exact)
                .eq("role", value: "therapist")
                .execute()
            let totalPTs = totalResponse.count ?? 0

            // Get weekly active PTs (PTs who had any activity in the period)
            let startString = ISO8601DateFormatter().string(from: periodStart)
            let endString = ISO8601DateFormatter().string(from: periodEnd)

            let activeResponse = try await supabase.client
                .from("kpi_events")
                .select("user_id")
                .gte("created_at", value: startString)
                .lte("created_at", value: endString)
                .in("event_type", values: ["brief_opened", "plan_assigned"])
                .execute()

            // Parse unique user IDs
            let decoder = JSONDecoder()
            let events = try? decoder.decode([[String: String]].self, from: activeResponse.data)
            let uniquePTIds = Set(events?.compactMap { $0["user_id"] } ?? [])
            let weeklyActivePTs = uniquePTIds.count

            // Calculate WAU percentage
            let wauPercentage = totalPTs > 0 ? Double(weeklyActivePTs) / Double(totalPTs) : 0

            // Get briefs opened count
            let briefsResponse = try await supabase.client
                .from("kpi_events")
                .select("id", head: false, count: .exact)
                .eq("event_type", value: "brief_opened")
                .gte("created_at", value: startString)
                .lte("created_at", value: endString)
                .execute()
            let briefsOpened = briefsResponse.count ?? 0

            // Get plans assigned count
            let plansResponse = try await supabase.client
                .from("kpi_events")
                .select("id", head: false, count: .exact)
                .eq("event_type", value: "plan_assigned")
                .gte("created_at", value: startString)
                .lte("created_at", value: endString)
                .execute()
            let plansAssigned = plansResponse.count ?? 0

            // Get average prep time
            let prepTimeResponse = try await supabase.client
                .from("kpi_events")
                .select("duration_ms")
                .eq("event_type", value: "brief_opened")
                .gte("created_at", value: startString)
                .lte("created_at", value: endString)
                .not("duration_ms", operator: .is, value: "null")
                .execute()

            let prepTimes = try? decoder.decode([[String: Int]].self, from: prepTimeResponse.data)
            let durations = prepTimes?.compactMap { $0["duration_ms"] } ?? []
            let avgPrepTimeSeconds = durations.isEmpty ? 0 : Double(durations.reduce(0, +)) / Double(durations.count) / 1000

            return PTMetrics(
                totalPTs: totalPTs,
                weeklyActivePTs: weeklyActivePTs,
                wauPercentage: wauPercentage,
                avgPrepTimeSeconds: avgPrepTimeSeconds,
                briefsOpened: briefsOpened,
                plansAssigned: plansAssigned
            )
        } catch {
            errorLogger.logError(error, context: "KPITrackingService.fetchPTMetrics")
            return PTMetrics(
                totalPTs: 0,
                weeklyActivePTs: 0,
                wauPercentage: 0,
                avgPrepTimeSeconds: 0,
                briefsOpened: 0,
                plansAssigned: 0
            )
        }
    }

    /// Fetch athlete metrics for a time period
    private func fetchAthleteMetrics(from periodStart: Date, to periodEnd: Date) async -> AthleteMetrics {
        do {
            // Get total athletes
            let totalResponse = try await supabase.client
                .from("patients")
                .select("id", head: false, count: .exact)
                .execute()
            let totalAthletes = totalResponse.count ?? 0

            let startString = ISO8601DateFormatter().string(from: periodStart)
            let endString = ISO8601DateFormatter().string(from: periodEnd)

            // Get weekly active athletes
            let activeResponse = try await supabase.client
                .from("kpi_events")
                .select("athlete_id")
                .gte("created_at", value: startString)
                .lte("created_at", value: endString)
                .in("event_type", values: ["check_in_completed", "session_completed", "task_completed"])
                .execute()

            let decoder = JSONDecoder()
            let events = try? decoder.decode([[String: String]].self, from: activeResponse.data)
            let uniqueAthleteIds = Set(events?.compactMap { $0["athlete_id"] } ?? [])
            let weeklyActiveAthletes = uniqueAthleteIds.count

            // Calculate WAU percentage
            let wauPercentage = totalAthletes > 0 ? Double(weeklyActiveAthletes) / Double(totalAthletes) : 0

            // Get check-ins completed
            let checkInsResponse = try await supabase.client
                .from("kpi_events")
                .select("id", head: false, count: .exact)
                .eq("event_type", value: "check_in_completed")
                .gte("created_at", value: startString)
                .lte("created_at", value: endString)
                .execute()
            let checkInsCompleted = checkInsResponse.count ?? 0

            // Get task completion rate from session metrics
            let tasksResponse = try await supabase.client
                .from("kpi_events")
                .select("id", head: false, count: .exact)
                .eq("event_type", value: "task_completed")
                .gte("created_at", value: startString)
                .lte("created_at", value: endString)
                .execute()
            let tasksCompleted = tasksResponse.count ?? 0

            let sessionsResponse = try await supabase.client
                .from("kpi_events")
                .select("id", head: false, count: .exact)
                .eq("event_type", value: "session_started")
                .gte("created_at", value: startString)
                .lte("created_at", value: endString)
                .execute()
            let sessionsStarted = sessionsResponse.count ?? 0

            let taskCompletionRate = sessionsStarted > 0 ? min(1.0, Double(tasksCompleted) / Double(sessionsStarted)) : 0

            // Get average streak (simplified - would need streak table in production)
            let avgStreakDays = 3.5 // Placeholder

            return AthleteMetrics(
                totalAthletes: totalAthletes,
                weeklyActiveAthletes: weeklyActiveAthletes,
                wauPercentage: wauPercentage,
                checkInsCompleted: checkInsCompleted,
                taskCompletionRate: taskCompletionRate,
                avgStreakDays: avgStreakDays
            )
        } catch {
            errorLogger.logError(error, context: "KPITrackingService.fetchAthleteMetrics")
            return AthleteMetrics(
                totalAthletes: 0,
                weeklyActiveAthletes: 0,
                wauPercentage: 0,
                checkInsCompleted: 0,
                taskCompletionRate: 0,
                avgStreakDays: 0
            )
        }
    }

    /// Fetch AI metrics for a time period
    private func fetchAIMetrics(from periodStart: Date, to periodEnd: Date) async -> AIMetrics {
        do {
            let startString = ISO8601DateFormatter().string(from: periodStart)
            let endString = ISO8601DateFormatter().string(from: periodEnd)

            // Get AI claim events
            let claimsResponse = try await supabase.client
                .from("kpi_events")
                .select("metadata, duration_ms")
                .eq("event_type", value: "ai_claim_generated")
                .gte("created_at", value: startString)
                .lte("created_at", value: endString)
                .execute()

            let decoder = JSONDecoder()

            // Parse claim data
            struct ClaimEvent: Codable {
                let metadata: ClaimMetadata?
                let durationMs: Int?

                enum CodingKeys: String, CodingKey {
                    case metadata
                    case durationMs = "duration_ms"
                }

                struct ClaimMetadata: Codable {
                    let hasCitations: Bool?
                    let confidence: Double?
                    let abstained: Bool?
                    let uncertaintyFlagged: Bool?

                    enum CodingKeys: String, CodingKey {
                        case hasCitations = "has_citations"
                        case confidence
                        case abstained
                        case uncertaintyFlagged = "uncertainty_flagged"
                    }
                }
            }

            let claimEvents = (try? decoder.decode([ClaimEvent].self, from: claimsResponse.data)) ?? []
            let claimsGenerated = claimEvents.count

            // Calculate citation coverage
            let claimsWithCitations = claimEvents.filter { $0.metadata?.hasCitations == true }.count
            let citationCoverage = claimsGenerated > 0 ? Double(claimsWithCitations) / Double(claimsGenerated) : 0

            // Calculate average confidence
            let confidences = claimEvents.compactMap { $0.metadata?.confidence }
            let avgConfidence = confidences.isEmpty ? 0 : confidences.reduce(0, +) / Double(confidences.count)

            // Calculate p95 latency
            let latencies = claimEvents.compactMap { $0.durationMs }.sorted()
            let p95Index = Int(Double(latencies.count) * 0.95)
            let p95LatencyMs = latencies.isEmpty ? 0 : latencies[min(p95Index, latencies.count - 1)]

            // Count abstentions
            let abstentions = claimEvents.filter { $0.metadata?.abstained == true }.count

            // Count uncertainty flags
            let uncertaintyFlags = claimEvents.filter { $0.metadata?.uncertaintyFlagged == true }.count

            return AIMetrics(
                claimsGenerated: claimsGenerated,
                citationCoverage: citationCoverage,
                avgConfidence: avgConfidence,
                p95LatencyMs: p95LatencyMs,
                abstentions: abstentions,
                uncertaintyFlags: uncertaintyFlags
            )
        } catch {
            errorLogger.logError(error, context: "KPITrackingService.fetchAIMetrics")
            return AIMetrics(
                claimsGenerated: 0,
                citationCoverage: 0,
                avgConfidence: 0,
                p95LatencyMs: 0,
                abstentions: 0,
                uncertaintyFlags: 0
            )
        }
    }

    /// Fetch safety metrics for a time period
    private func fetchSafetyMetrics(from periodStart: Date, to periodEnd: Date) async -> SafetyMetrics {
        do {
            let startString = ISO8601DateFormatter().string(from: periodStart)

            // Get total incidents in period
            let totalResponse = try await supabase.client
                .from("safety_incidents")
                .select("id", head: false, count: .exact)
                .gte("created_at", value: startString)
                .execute()
            let totalIncidents = totalResponse.count ?? 0

            // Get unresolved high severity count
            let unresolvedHighSeverity = await safetyService.getUnresolvedHighSeverityCount()

            // Get escalations triggered
            let escalationsResponse = try await supabase.client
                .from("safety_incidents")
                .select("id", head: false, count: .exact)
                .not("escalated_to", operator: .is, value: "null")
                .gte("created_at", value: startString)
                .execute()
            let escalationsTriggered = escalationsResponse.count ?? 0

            // Get threshold breaches (all incidents are threshold breaches)
            let thresholdBreaches = totalIncidents

            return SafetyMetrics(
                totalIncidents: totalIncidents,
                unresolvedHighSeverity: unresolvedHighSeverity,
                escalationsTriggered: escalationsTriggered,
                thresholdBreaches: thresholdBreaches
            )
        } catch {
            errorLogger.logError(error, context: "KPITrackingService.fetchSafetyMetrics")
            return SafetyMetrics(
                totalIncidents: 0,
                unresolvedHighSeverity: 0,
                escalationsTriggered: 0,
                thresholdBreaches: 0
            )
        }
    }

    // MARK: - Trend Calculation

    /// Calculate trend direction for a metric
    /// - Parameters:
    ///   - current: Current value
    ///   - previous: Previous value
    /// - Returns: Trend direction
    func calculateTrend(current: Double, previous: Double) -> KPITrend {
        let change = current - previous
        let threshold = 0.02 // 2% change threshold

        if change > threshold {
            return .up
        } else if change < -threshold {
            return .down
        } else {
            return .stable
        }
    }

    /// Get dashboard with trends compared to previous period
    /// - Parameter periodDays: Number of days per period
    /// - Returns: Tuple of current dashboard and trends
    func getDashboardWithTrends(periodDays: Int = 7) async -> (dashboard: KPIDashboard, trends: DashboardTrends) {
        let currentDashboard = await getDashboard(periodDays: periodDays)

        // Get previous period
        let previousEnd = Calendar.current.date(byAdding: .day, value: -periodDays, to: Date())!
        let previousStart = Calendar.current.date(byAdding: .day, value: -periodDays, to: previousEnd)!

        async let previousPT = fetchPTMetrics(from: previousStart, to: previousEnd)
        async let previousAthlete = fetchAthleteMetrics(from: previousStart, to: previousEnd)
        async let previousAI = fetchAIMetrics(from: previousStart, to: previousEnd)

        let (prevPT, prevAthlete, prevAI) = await (previousPT, previousAthlete, previousAI)

        let trends = DashboardTrends(
            ptWauTrend: calculateTrend(current: currentDashboard.ptMetrics.wauPercentage, previous: prevPT.wauPercentage),
            athleteWauTrend: calculateTrend(current: currentDashboard.athleteMetrics.wauPercentage, previous: prevAthlete.wauPercentage),
            citationTrend: calculateTrend(current: currentDashboard.aiMetrics.citationCoverage, previous: prevAI.citationCoverage),
            latencyTrend: calculateTrend(current: Double(prevAI.p95LatencyMs), previous: Double(currentDashboard.aiMetrics.p95LatencyMs)) // Inverted - lower is better
        )

        return (currentDashboard, trends)
    }
}

// MARK: - Dashboard Trends

/// Trend directions for dashboard metrics
struct DashboardTrends: Sendable {
    let ptWauTrend: KPITrend
    let athleteWauTrend: KPITrend
    let citationTrend: KPITrend
    let latencyTrend: KPITrend
}

// MARK: - AnyEncodable Helper

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
