//
//  TherapistIntelligenceViewModel.swift
//  PTPerformance
//
//  ViewModel for the Therapist Intelligence dashboard
//  Aggregates data from multiple services to provide practice-wide analytics
//

import SwiftUI
import Combine

// MARK: - Recent Activity Event

/// Represents a recent activity event in the practice
struct RecentActivityEvent: Identifiable {
    let id: UUID
    let patientId: UUID
    let patientName: String
    let eventType: EventType
    let timestamp: Date
    let details: String?

    enum EventType: String {
        case sessionCompleted = "completed"
        case personalRecord = "pr"
        case dropOff = "dropoff"
        case milestone = "milestone"
        case programStarted = "started"
        case flagRaised = "flag"

        var icon: String {
            switch self {
            case .sessionCompleted: return "checkmark.circle.fill"
            case .personalRecord: return "trophy.fill"
            case .dropOff: return "arrow.down.circle.fill"
            case .milestone: return "star.fill"
            case .programStarted: return "play.circle.fill"
            case .flagRaised: return "flag.fill"
            }
        }

        var color: Color {
            switch self {
            case .sessionCompleted: return .green
            case .personalRecord: return .yellow
            case .dropOff: return .red
            case .milestone: return .purple
            case .programStarted: return .blue
            case .flagRaised: return .orange
            }
        }

        var displayName: String {
            switch self {
            case .sessionCompleted: return "Session Completed"
            case .personalRecord: return "Personal Record"
            case .dropOff: return "Drop-off Warning"
            case .milestone: return "Milestone Reached"
            case .programStarted: return "Program Started"
            case .flagRaised: return "Flag Raised"
            }
        }
    }
}

// MARK: - Practice KPI

/// Represents a key performance indicator for the practice
struct PracticeKPI: Identifiable {
    let id: String
    let title: String
    let value: String
    let trend: Trend?
    let trendValue: String?
    let icon: String
    let color: Color

    struct Trend {
        let direction: Direction
        let percentage: Double
        let comparisonPeriod: String

        enum Direction {
            case up, down, neutral

            var icon: String {
                switch self {
                case .up: return "arrow.up.right"
                case .down: return "arrow.down.right"
                case .neutral: return "arrow.right"
                }
            }

            var color: Color {
                switch self {
                case .up: return .green
                case .down: return .red
                case .neutral: return .gray
                }
            }
        }
    }
}

// MARK: - At-Risk Patient

/// Represents a patient who is at risk based on adherence metrics
struct AtRiskPatient: Identifiable {
    let id: UUID
    let patient: Patient
    let adherencePercentage: Double
    let daysSinceLastActivity: Int
    let riskLevel: RiskLevel

    enum RiskLevel: Int, Comparable {
        case moderate = 1
        case high = 2
        case critical = 3

        static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        var color: Color {
            switch self {
            case .moderate: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }

        var displayName: String {
            switch self {
            case .moderate: return "Moderate"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class TherapistIntelligenceViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var patients: [Patient] = []
    @Published var atRiskPatients: [AtRiskPatient] = []
    @Published var recentActivity: [RecentActivityEvent] = []
    @Published var practiceKPIs: [PracticeKPI] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Previous period data for trend calculations
    @Published private var previousPeriodAdherence: Double?
    @Published private var previousPeriodPatientCount: Int?

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared
    private var cancellables = Set<AnyCancellable>()

    deinit {
        cancellables.removeAll()
    }

    // MARK: - Computed Properties

    var totalActivePatients: Int {
        patients.count
    }

    var averageAdherence: Double? {
        let values = patients.compactMap { $0.adherencePercentage }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    var patientsAtRiskCount: Int {
        atRiskPatients.count
    }

    var programsInUse: Int {
        // Count unique injury types as a proxy for distinct programs,
        // since the Patient model does not carry a programId field
        Set(patients.compactMap { $0.injuryType }).count
    }

    var adherenceTrend: PracticeKPI.Trend? {
        guard let current = averageAdherence,
              let previous = previousPeriodAdherence else { return nil }

        let change = current - previous
        let percentChange = previous > 0 ? (change / previous) * 100 : 0

        let direction: PracticeKPI.Trend.Direction
        if abs(change) < 1 {
            direction = .neutral
        } else if change > 0 {
            direction = .up
        } else {
            direction = .down
        }

        return PracticeKPI.Trend(
            direction: direction,
            percentage: abs(percentChange),
            comparisonPeriod: "vs last week"
        )
    }

    // MARK: - Data Loading

    func loadData(therapistId: String) async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            // Load patients
            try await loadPatients(therapistId: therapistId)

            // Calculate at-risk patients (try EF first, fall back to local)
            await loadAtRiskPatientsFromEF()

            // Load recent activity
            await loadRecentActivity(therapistId: therapistId)

            // Build KPIs
            buildPracticeKPIs()

            // Update badge manager
            TabBarBadgeManager.shared.setIntelligenceBadge(patientsAtRiskCount)

        } catch {
            ErrorLogger.shared.logError(error, context: "TherapistIntelligenceViewModel.loadData")
            errorMessage = "Failed to load intelligence data. Please try again."
        }
    }

    func refresh(therapistId: String) async {
        await loadData(therapistId: therapistId)
    }

    // MARK: - Private Methods

    private func loadPatients(therapistId: String) async throws {
        let response = try await supabase.client
            .from("patients")
            .select()
            .eq("therapist_id", value: therapistId)
            .execute()

        let decoder = PTSupabaseClient.flexibleDecoder
        patients = try decoder.decode([Patient].self, from: response.data)

        // Load previous period data for trend calculation
        await loadPreviousPeriodData(therapistId: therapistId)
    }

    /// Load previous period patient data for trend calculations
    /// Queries the previous 7-day window to compare against current metrics
    private func loadPreviousPeriodData(therapistId: String) async {
        do {
            let calendar = Calendar.current
            let now = Date()
            guard let periodEnd = calendar.date(byAdding: .day, value: -7, to: now),
                  let periodStart = calendar.date(byAdding: .day, value: -14, to: now) else {
                previousPeriodAdherence = nil
                previousPeriodPatientCount = nil
                return
            }

            let formatter = ISO8601DateFormatter()
            let startString = formatter.string(from: periodStart)
            let endString = formatter.string(from: periodEnd)

            // Query patients that were active in the previous period
            let response = try await supabase.client
                .from("patients")
                .select()
                .eq("therapist_id", value: therapistId)
                .gte("last_session_date", value: startString)
                .lte("last_session_date", value: endString)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let previousPatients = try decoder.decode([Patient].self, from: response.data)

            previousPeriodPatientCount = previousPatients.count

            let adherenceValues = previousPatients.compactMap { $0.adherencePercentage }
            if !adherenceValues.isEmpty {
                previousPeriodAdherence = adherenceValues.reduce(0, +) / Double(adherenceValues.count)
            } else {
                previousPeriodAdherence = nil
            }
        } catch {
            ErrorLogger.shared.logWarning("Failed to load previous period data: \(error.localizedDescription)")
            previousPeriodAdherence = nil
            previousPeriodPatientCount = nil
        }
    }

    /// Load at-risk patients from the engagement-scoring edge function.
    /// Falls back to local `calculateAtRiskPatients()` on failure or empty data.
    private func loadAtRiskPatientsFromEF() async {
        do {
            let response = try await EdgeFunctionAnalyticsService.shared.fetchEngagementScores(atRisk: true, threshold: 50)
            guard let scores = response.data, !scores.isEmpty else {
                // Fall back to local calculation
                calculateAtRiskPatients()
                return
            }
            // Map EF scores to AtRiskPatient model
            atRiskPatients = scores.compactMap { score in
                guard let patientIdStr = score.patientId,
                      let patientId = UUID(uuidString: patientIdStr),
                      let patient = patients.first(where: { $0.id == patientId }) else { return nil }

                let riskLevel: AtRiskPatient.RiskLevel
                switch score.riskLevel {
                case "high_risk": riskLevel = .critical
                case "at_risk": riskLevel = .high
                default: riskLevel = .moderate
                }

                return AtRiskPatient(
                    id: patientId,
                    patient: patient,
                    adherencePercentage: score.score ?? 0,
                    daysSinceLastActivity: score.components?.recency?.daysSinceLastActivity ?? 0,
                    riskLevel: riskLevel
                )
            }.sorted { $0.riskLevel > $1.riskLevel }
        } catch {
            ErrorLogger.shared.logWarning("EF engagement-scoring failed, using local: \(error.localizedDescription)")
            calculateAtRiskPatients()
        }
    }

    private func calculateAtRiskPatients() {
        atRiskPatients = patients.compactMap { patient in
            let adherence = patient.adherencePercentage ?? 0
            let daysSince = patient.daysSinceLastSession

            // Only include patients with adherence < 60%
            guard adherence < 60 else { return nil }

            let riskLevel: AtRiskPatient.RiskLevel
            if adherence < 30 || daysSince > 14 || patient.hasHighSeverityFlags {
                riskLevel = .critical
            } else if adherence < 45 || daysSince > 7 {
                riskLevel = .high
            } else {
                riskLevel = .moderate
            }

            return AtRiskPatient(
                id: patient.id,
                patient: patient,
                adherencePercentage: adherence,
                daysSinceLastActivity: daysSince == Int.max ? 30 : daysSince,
                riskLevel: riskLevel
            )
        }
        .sorted { $0.riskLevel > $1.riskLevel }
    }

    private func loadRecentActivity(therapistId: String) async {
        // In production, this would fetch from a dedicated activity log table
        // For now, generate activity based on patient data
        recentActivity = generateRecentActivityFromPatients()
    }

    private func generateRecentActivityFromPatients() -> [RecentActivityEvent] {
        var events: [RecentActivityEvent] = []
        let calendar = Calendar.current

        for patient in patients.prefix(10) {
            // Add session completion events for active patients
            if let lastSession = patient.lastSessionDate,
               calendar.isDateInToday(lastSession) || calendar.isDateInYesterday(lastSession) {
                events.append(RecentActivityEvent(
                    id: UUID(),
                    patientId: patient.id,
                    patientName: patient.fullName,
                    eventType: .sessionCompleted,
                    timestamp: lastSession,
                    details: "Completed workout session"
                ))
            }

            // Add drop-off events for at-risk patients
            // Use lastSessionDate as the timestamp (the point at which they became inactive)
            if (patient.adherencePercentage ?? 100) < 50 {
                let dropOffTimestamp = patient.lastSessionDate ?? patient.createdAt
                events.append(RecentActivityEvent(
                    id: UUID(),
                    patientId: patient.id,
                    patientName: patient.fullName,
                    eventType: .dropOff,
                    timestamp: dropOffTimestamp,
                    details: "Adherence dropped below 50%"
                ))
            }

            // Add flag events for flagged patients
            // Use lastSessionDate as a proxy for when the flag was raised (during last session)
            if patient.hasHighSeverityFlags {
                let flagTimestamp = patient.lastSessionDate ?? patient.createdAt
                events.append(RecentActivityEvent(
                    id: UUID(),
                    patientId: patient.id,
                    patientName: patient.fullName,
                    eventType: .flagRaised,
                    timestamp: flagTimestamp,
                    details: "High severity flag requires attention"
                ))
            }
        }

        // Sort by timestamp descending
        return events.sorted { $0.timestamp > $1.timestamp }
    }

    private func buildPracticeKPIs() {
        practiceKPIs = [
            PracticeKPI(
                id: "active_patients",
                title: "Active Patients",
                value: "\(totalActivePatients)",
                trend: previousPeriodPatientCount.map { previous in
                    let change = totalActivePatients - previous
                    return PracticeKPI.Trend(
                        direction: change > 0 ? .up : (change < 0 ? .down : .neutral),
                        percentage: previous > 0 ? Double(abs(change)) / Double(previous) * 100 : 0,
                        comparisonPeriod: "vs last week"
                    )
                },
                trendValue: nil,
                icon: "person.2.fill",
                color: .blue
            ),
            PracticeKPI(
                id: "avg_adherence",
                title: "Avg Adherence",
                value: averageAdherence.map { "\(Int($0))%" } ?? "N/A",
                trend: adherenceTrend,
                trendValue: adherenceTrend.map { "\(String(format: "%.1f", $0.percentage))%" },
                icon: "checkmark.circle.fill",
                color: adherenceColor(for: averageAdherence)
            ),
            PracticeKPI(
                id: "at_risk",
                title: "At Risk",
                value: "\(patientsAtRiskCount)",
                trend: nil,
                trendValue: nil,
                icon: "exclamationmark.triangle.fill",
                color: patientsAtRiskCount > 0 ? .red : .green
            ),
            PracticeKPI(
                id: "programs",
                title: "Programs",
                value: "\(programsInUse)",
                trend: nil,
                trendValue: nil,
                icon: "list.bullet.rectangle.portrait.fill",
                color: .purple
            )
        ]
    }

    private func adherenceColor(for percentage: Double?) -> Color {
        guard let percentage = percentage else { return .gray }
        switch percentage {
        case 80...: return .green
        case 60..<80: return .yellow
        default: return .red
        }
    }

    // MARK: - Actions

    func sendReminder(to patient: Patient) async {
        // In production, this would send a push notification or email
        DebugLogger.shared.log("Sending reminder to \(patient.fullName)")
        HapticFeedback.success()
    }
}
