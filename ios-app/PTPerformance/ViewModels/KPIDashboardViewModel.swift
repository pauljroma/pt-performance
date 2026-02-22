//
//  KPIDashboardViewModel.swift
//  PTPerformance
//
//  ViewModel for KPI Dashboard View
//  Loads dashboard data, filters by date range, and calculates trend directions
//

import Foundation
import Combine

// MARK: - KPI Dashboard ViewModel

/// ViewModel for the KPI Dashboard
/// Manages dashboard data loading, caching, and trend calculations
@MainActor
final class KPIDashboardViewModel: ObservableObject {

    // MARK: - Static Formatters
    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - Published Properties

    @Published var dashboard: KPIDashboard?
    @Published var openIncidents: [SafetyIncident] = []
    @Published var isLoading = false
    @Published var lastError: Error?

    // Trend data
    @Published var ptWauTrend: KPITrend?
    @Published var athleteWauTrend: KPITrend?
    @Published var citationTrend: KPITrend?
    @Published var latencyTrend: KPITrend?

    // MARK: - Private Properties

    private let kpiService: KPITrackingService
    private let safetyService: SafetyService
    private var currentPeriod: DateRangePeriod = .lastWeek
    private var lastRefreshDate: Date?
    private let cacheValidityDuration: TimeInterval = 60 // 1 minute cache

    // MARK: - Initialization

    init(kpiService: KPITrackingService = .shared, safetyService: SafetyService = .shared) {
        self.kpiService = kpiService
        self.safetyService = safetyService
    }

    // MARK: - Public Methods

    /// Load dashboard data for a specific period
    /// - Parameter period: The date range period to load
    func loadDashboard(period: DateRangePeriod) async {
        currentPeriod = period

        // Check cache validity
        if let lastRefresh = lastRefreshDate,
           Date().timeIntervalSince(lastRefresh) < cacheValidityDuration,
           dashboard != nil {
            return
        }

        isLoading = true
        lastError = nil

        do {
            // Try executive-dashboard edge function first for overview data
            let efLoaded = await loadFromExecutiveDashboardEF(period: period)

            if !efLoaded {
                // Fall back to existing KPITrackingService + SafetyService
                async let dashboardTask = kpiService.getDashboardWithTrends(periodDays: period.days)
                async let incidentsTask = safetyService.getOpenIncidents()

                let (result, incidents) = try await (dashboardTask, incidentsTask)

                dashboard = result.dashboard
                openIncidents = incidents.sorted { $0.severity.sortOrder < $1.severity.sortOrder }

                // Update trends
                ptWauTrend = result.trends.ptWauTrend
                athleteWauTrend = result.trends.athleteWauTrend
                citationTrend = result.trends.citationTrend
                latencyTrend = result.trends.latencyTrend
            }

            lastRefreshDate = Date()
        } catch {
            lastError = error
            ErrorLogger.shared.logError(error, context: "KPIDashboardViewModel.loadDashboard")
        }

        isLoading = false
    }

    /// Refresh dashboard data
    func refresh() async {
        lastRefreshDate = nil // Force refresh
        await loadDashboard(period: currentPeriod)
    }

    /// Filter incidents by severity
    /// - Parameter minSeverity: Minimum severity to include
    /// - Returns: Filtered incidents
    func filterIncidents(minSeverity: SafetyIncident.Severity) -> [SafetyIncident] {
        openIncidents.filter { $0.severity.sortOrder <= minSeverity.sortOrder }
    }

    /// Get incidents by type
    /// - Parameter type: Incident type to filter by
    /// - Returns: Filtered incidents
    func incidents(ofType type: SafetyIncident.IncidentType) -> [SafetyIncident] {
        openIncidents.filter { $0.incidentType == type }
    }

    /// Check if all guardrails are met
    var allGuardrailsMet: Bool {
        guard let dashboard = dashboard else { return false }
        return dashboard.ptMetrics.meetsTarget &&
               dashboard.athleteMetrics.meetsTarget &&
               dashboard.aiMetrics.citationMeetsTarget &&
               dashboard.aiMetrics.latencyMeetsTarget &&
               dashboard.safetyMetrics.meetsTarget
    }

    /// Get count of guardrails not meeting targets
    var guardrailsNotMet: Int {
        guard let dashboard = dashboard else { return 5 }

        var count = 0
        if !dashboard.ptMetrics.meetsTarget { count += 1 }
        if !dashboard.athleteMetrics.meetsTarget { count += 1 }
        if !dashboard.aiMetrics.citationMeetsTarget { count += 1 }
        if !dashboard.aiMetrics.latencyMeetsTarget { count += 1 }
        if !dashboard.safetyMetrics.meetsTarget { count += 1 }
        return count
    }

    /// Get summary status text
    var summaryStatus: String {
        guard let dashboard = dashboard else { return "Loading..." }

        if allGuardrailsMet {
            return "All guardrails met"
        } else if guardrailsNotMet == 1 {
            return "1 guardrail needs attention"
        } else {
            return "\(guardrailsNotMet) guardrails need attention"
        }
    }

    /// Get high-priority incidents that need immediate attention
    var urgentIncidents: [SafetyIncident] {
        openIncidents.filter { $0.requiresUrgentAttention }
    }

    /// Get incidents requiring escalation
    var incidentsNeedingEscalation: [SafetyIncident] {
        openIncidents.filter { !$0.isEscalated && $0.isHighSeverity }
    }

    // MARK: - Edge Function Loading

    /// Attempt to load KPI overview from the executive-dashboard edge function.
    /// Maps the EF response into the existing `KPIDashboard` and trend properties.
    /// Returns `true` if the EF call succeeded and populated the dashboard.
    private func loadFromExecutiveDashboardEF(period: DateRangePeriod) async -> Bool {
        do {
            let response = try await EdgeFunctionAnalyticsService.shared.fetchExecutiveDashboard()

            guard let overview = response.overview else { return false }

            // Build KPIDashboard from EF response
            let ptMetrics = PTMetrics(
                totalPTs: overview.totalUsers ?? 0,
                weeklyActivePTs: overview.wau ?? 0,
                wauPercentage: overview.dauMauRatio ?? 0,
                avgPrepTimeSeconds: 0,
                briefsOpened: 0,
                plansAssigned: 0
            )

            let athleteMetrics = AthleteMetrics(
                totalAthletes: overview.mau ?? 0,
                weeklyActiveAthletes: overview.wau ?? 0,
                wauPercentage: overview.mau ?? 0 > 0 ? Double(overview.wau ?? 0) / Double(overview.mau ?? 1) : 0,
                checkInsCompleted: response.engagement?.totalSessionsThisWeek ?? 0,
                taskCompletionRate: 0,
                avgStreakDays: response.engagement?.avgStreakLength ?? 0
            )

            let aiMetrics = AIMetrics(
                claimsGenerated: 0,
                citationCoverage: 0,
                avgConfidence: 0,
                p95LatencyMs: 0,
                abstentions: 0,
                uncertaintyFlags: 0
            )

            let safetyMetrics = SafetyMetrics(
                totalIncidents: response.safety?.totalThisMonth ?? 0,
                unresolvedHighSeverity: response.safety?.totalOpen ?? 0,
                escalationsTriggered: 0,
                thresholdBreaches: 0
            )

            let periodEnd = Date()
            let periodStart = Calendar.current.date(byAdding: .day, value: -period.days, to: periodEnd) ?? periodEnd

            dashboard = KPIDashboard(
                periodStart: periodStart,
                periodEnd: periodEnd,
                ptMetrics: ptMetrics,
                athleteMetrics: athleteMetrics,
                aiMetrics: aiMetrics,
                safetyMetrics: safetyMetrics
            )

            // Map trends from EF response
            if let trends = response.trends {
                ptWauTrend = mapTrend(trends.dau)
                athleteWauTrend = mapTrend(trends.sessions)
                citationTrend = .stable
                latencyTrend = .stable
            }

            // Load incidents via safety service (EF does not include full incident list)
            let incidents = try await safetyService.getOpenIncidents()
            openIncidents = incidents.sorted { $0.severity.sortOrder < $1.severity.sortOrder }

            return true
        } catch {
            ErrorLogger.shared.logWarning("EF executive-dashboard failed, falling back to KPITrackingService: \(error.localizedDescription)")
            return false
        }
    }

    /// Map an EF TrendMetric to the existing KPITrend enum
    func mapTrend(_ metric: EFTrendMetric?) -> KPITrend {
        guard let metric = metric, let changePct = metric.changePct else { return .stable }
        if changePct > 1.0 { return .up }
        if changePct < -1.0 { return .down }
        return .stable
    }

    // MARK: - Export

    /// Generate export data for the dashboard
    /// - Returns: Dictionary suitable for JSON export
    func generateExportData() -> [String: Any]? {
        guard let dashboard = dashboard else { return nil }

        return [
            "period_start": ISO8601DateFormatter().string(from: dashboard.periodStart),
            "period_end": ISO8601DateFormatter().string(from: dashboard.periodEnd),
            "generated_at": ISO8601DateFormatter().string(from: Date()),
            "pt_metrics": [
                "total_pts": dashboard.ptMetrics.totalPTs,
                "weekly_active_pts": dashboard.ptMetrics.weeklyActivePTs,
                "wau_percentage": dashboard.ptMetrics.wauPercentage,
                "meets_target": dashboard.ptMetrics.meetsTarget,
                "briefs_opened": dashboard.ptMetrics.briefsOpened,
                "plans_assigned": dashboard.ptMetrics.plansAssigned
            ],
            "athlete_metrics": [
                "total_athletes": dashboard.athleteMetrics.totalAthletes,
                "weekly_active_athletes": dashboard.athleteMetrics.weeklyActiveAthletes,
                "wau_percentage": dashboard.athleteMetrics.wauPercentage,
                "meets_target": dashboard.athleteMetrics.meetsTarget,
                "check_ins_completed": dashboard.athleteMetrics.checkInsCompleted,
                "task_completion_rate": dashboard.athleteMetrics.taskCompletionRate
            ],
            "ai_metrics": [
                "claims_generated": dashboard.aiMetrics.claimsGenerated,
                "citation_coverage": dashboard.aiMetrics.citationCoverage,
                "citation_meets_target": dashboard.aiMetrics.citationMeetsTarget,
                "p95_latency_ms": dashboard.aiMetrics.p95LatencyMs,
                "latency_meets_target": dashboard.aiMetrics.latencyMeetsTarget,
                "abstentions": dashboard.aiMetrics.abstentions,
                "uncertainty_flags": dashboard.aiMetrics.uncertaintyFlags
            ],
            "safety_metrics": [
                "total_incidents": dashboard.safetyMetrics.totalIncidents,
                "unresolved_high_severity": dashboard.safetyMetrics.unresolvedHighSeverity,
                "meets_target": dashboard.safetyMetrics.meetsTarget,
                "escalations_triggered": dashboard.safetyMetrics.escalationsTriggered
            ],
            "open_incidents": openIncidents.map { incident in
                [
                    "id": incident.id.uuidString,
                    "type": incident.incidentType.rawValue,
                    "severity": incident.severity.rawValue,
                    "status": incident.status.rawValue,
                    "description": incident.description,
                    "age_seconds": incident.age
                ]
            }
        ]
    }

    /// Generate text summary for sharing
    func generateTextSummary() -> String {
        guard let dashboard = dashboard else { return "Dashboard not available" }

        var lines: [String] = []
        lines.append("X2Index KPI Dashboard Report")
        lines.append("Period: \(formatDate(dashboard.periodStart)) - \(formatDate(dashboard.periodEnd))")
        lines.append("")

        lines.append("NORTH STAR GUARDRAILS")
        lines.append("- PT WAU: \(Int(dashboard.ptMetrics.wauPercentage * 100))% (target: 65%) \(dashboard.ptMetrics.meetsTarget ? "[OK]" : "[BELOW]")")
        lines.append("- Athlete WAU: \(Int(dashboard.athleteMetrics.wauPercentage * 100))% (target: 60%) \(dashboard.athleteMetrics.meetsTarget ? "[OK]" : "[BELOW]")")
        lines.append("- Citation Coverage: \(Int(dashboard.aiMetrics.citationCoverage * 100))% (target: 95%) \(dashboard.aiMetrics.citationMeetsTarget ? "[OK]" : "[BELOW]")")
        lines.append("- p95 Latency: \(dashboard.aiMetrics.p95LatencyMs)ms (target: 5000ms) \(dashboard.aiMetrics.latencyMeetsTarget ? "[OK]" : "[ABOVE]")")
        lines.append("- Unresolved High-Severity: \(dashboard.safetyMetrics.unresolvedHighSeverity) (target: 0) \(dashboard.safetyMetrics.meetsTarget ? "[OK]" : "[ABOVE]")")
        lines.append("")

        lines.append("SUMMARY")
        lines.append("- Total PTs: \(dashboard.ptMetrics.totalPTs)")
        lines.append("- Total Athletes: \(dashboard.athleteMetrics.totalAthletes)")
        lines.append("- AI Claims: \(dashboard.aiMetrics.claimsGenerated)")
        lines.append("- Safety Incidents: \(dashboard.safetyMetrics.totalIncidents)")
        lines.append("")

        if !openIncidents.isEmpty {
            lines.append("OPEN INCIDENTS (\(openIncidents.count))")
            for incident in openIncidents.prefix(5) {
                lines.append("- [\(incident.severity.rawValue.uppercased())] \(incident.incidentType.displayName): \(incident.description)")
            }
            if openIncidents.count > 5 {
                lines.append("  ... and \(openIncidents.count - 5) more")
            }
        }

        lines.append("")
        lines.append("Generated: \(formatDate(Date()))")

        return lines.joined(separator: "\n")
    }

    private func formatDate(_ date: Date) -> String {
        Self.dateTimeFormatter.string(from: date)
    }
}

// MARK: - KPI Alert

/// Alert for KPI guardrail breaches
struct KPIAlert: Identifiable, Sendable {
    var id: String { "\(guardrail)-\(currentValue)-\(targetValue)" }
    let guardrail: String
    let currentValue: String
    let targetValue: String
    let severity: KPIStatus
    let message: String
}

// MARK: - ViewModel Extensions

extension KPIDashboardViewModel {
    /// Get alerts for guardrails not meeting targets
    var guardrailAlerts: [KPIAlert] {
        guard let dashboard = dashboard else { return [] }

        var alerts: [KPIAlert] = []

        if !dashboard.ptMetrics.meetsTarget {
            alerts.append(KPIAlert(
                guardrail: "PT Weekly Active Usage",
                currentValue: "\(Int(dashboard.ptMetrics.wauPercentage * 100))%",
                targetValue: "\(Int(KPITargets.ptWauTarget * 100))%",
                severity: dashboard.ptMetrics.status,
                message: "PT engagement is below target. Consider outreach to inactive PTs."
            ))
        }

        if !dashboard.athleteMetrics.meetsTarget {
            alerts.append(KPIAlert(
                guardrail: "Athlete Weekly Active Usage",
                currentValue: "\(Int(dashboard.athleteMetrics.wauPercentage * 100))%",
                targetValue: "\(Int(KPITargets.athleteWauTarget * 100))%",
                severity: dashboard.athleteMetrics.status,
                message: "Athlete engagement is below target. Review notification and reminder strategies."
            ))
        }

        if !dashboard.aiMetrics.citationMeetsTarget {
            alerts.append(KPIAlert(
                guardrail: "AI Citation Coverage",
                currentValue: "\(Int(dashboard.aiMetrics.citationCoverage * 100))%",
                targetValue: "\(Int(KPITargets.citationCoverageTarget * 100))%",
                severity: dashboard.aiMetrics.citationStatus,
                message: "Citation coverage is below target. Review AI claim generation pipeline."
            ))
        }

        if !dashboard.aiMetrics.latencyMeetsTarget {
            alerts.append(KPIAlert(
                guardrail: "p95 Summary Latency",
                currentValue: "\(dashboard.aiMetrics.p95LatencyMs)ms",
                targetValue: "\(KPITargets.p95LatencyTargetMs)ms",
                severity: dashboard.aiMetrics.latencyStatus,
                message: "AI latency is above target. Review infrastructure and optimization opportunities."
            ))
        }

        if !dashboard.safetyMetrics.meetsTarget {
            alerts.append(KPIAlert(
                guardrail: "Unresolved High-Severity Incidents",
                currentValue: "\(dashboard.safetyMetrics.unresolvedHighSeverity)",
                targetValue: "0",
                severity: .critical,
                message: "There are unresolved high-severity safety incidents requiring immediate attention."
            ))
        }

        return alerts
    }
}
