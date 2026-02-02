//
//  UCLHealthService.swift
//  PTPerformance
//
//  ACP-544: UCL Health Service
//  Manages UCL health assessments, risk calculations, and alerts
//

import Foundation
import UserNotifications

/// Service for managing UCL health assessments and risk tracking
/// Thread-safe actor for database operations and notifications
actor UCLHealthService {

    // MARK: - Singleton

    static let shared = UCLHealthService()

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared.client
    private let notificationCenter = UNUserNotificationCenter.current()

    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // MARK: - Notification Identifiers

    private enum NotificationIdentifier {
        static let weeklyReminder = "com.ptperformance.ucl.weekly"
        static let elevatedRisk = "com.ptperformance.ucl.elevated"
        static let criticalAlert = "com.ptperformance.ucl.critical"
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Fetch Assessments

    /// Fetch UCL health assessments for a patient
    /// - Parameters:
    ///   - patientId: Patient UUID string
    ///   - limit: Maximum number of assessments to return (default 12)
    /// - Returns: Array of UCL assessments, ordered by date descending
    func fetchAssessments(for patientId: String, limit: Int = 12) async throws -> [UCLHealthAssessment] {
        do {
            let response = try await supabase
                .from("ucl_health_assessments")
                .select()
                .eq("patient_id", value: patientId)
                .order("assessment_date", ascending: false)
                .limit(limit)
                .execute()

            let decoder = createDecoder()
            return try decoder.decode([UCLHealthAssessment].self, from: response.data)
        } catch {
            DebugLogger.shared.log(
                "UCLHealthService: Failed to fetch assessments - \(error.localizedDescription)",
                level: .error
            )
            throw UCLHealthError.fetchFailed(error)
        }
    }

    /// Fetch the most recent assessment for a patient
    /// - Parameter patientId: Patient UUID string
    /// - Returns: Most recent assessment or nil if none exists
    func fetchLatestAssessment(for patientId: String) async throws -> UCLHealthAssessment? {
        let assessments = try await fetchAssessments(for: patientId, limit: 1)
        return assessments.first
    }

    /// Fetch assessments within a date range
    /// - Parameters:
    ///   - patientId: Patient UUID string
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Array of assessments within the range
    func fetchAssessments(
        for patientId: String,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [UCLHealthAssessment] {
        do {
            let startString = dateFormatter.string(from: startDate)
            let endString = dateFormatter.string(from: endDate)

            let response = try await supabase
                .from("ucl_health_assessments")
                .select()
                .eq("patient_id", value: patientId)
                .gte("assessment_date", value: startString)
                .lte("assessment_date", value: endString)
                .order("assessment_date", ascending: false)
                .execute()

            let decoder = createDecoder()
            return try decoder.decode([UCLHealthAssessment].self, from: response.data)
        } catch {
            throw UCLHealthError.fetchFailed(error)
        }
    }

    // MARK: - Submit Assessment

    /// Submit a new UCL health assessment
    /// - Parameters:
    ///   - input: Assessment input data
    ///   - symptomScore: Calculated symptom score
    ///   - workloadScore: Calculated workload score
    ///   - riskScore: Combined risk score
    ///   - riskLevel: Determined risk level
    /// - Returns: Created UCL assessment record
    func submitAssessment(
        input: UCLAssessmentInput,
        symptomScore: Double,
        workloadScore: Double,
        riskScore: Double,
        riskLevel: UCLRiskLevel
    ) async throws -> UCLHealthAssessment {
        do {
            // Create the full record with calculated scores
            let record = UCLAssessmentRecord(
                input: input,
                symptomScore: symptomScore,
                workloadScore: workloadScore,
                riskScore: riskScore,
                riskLevel: riskLevel.rawValue
            )

            let response = try await supabase
                .from("ucl_health_assessments")
                .insert(record)
                .select()
                .single()
                .execute()

            let decoder = createDecoder()
            let assessment = try decoder.decode(UCLHealthAssessment.self, from: response.data)

            DebugLogger.shared.log(
                "UCLHealthService: Assessment submitted - Risk: \(riskLevel.displayName) (\(Int(riskScore)))",
                level: .success
            )

            return assessment
        } catch {
            DebugLogger.shared.log(
                "UCLHealthService: Failed to submit assessment - \(error.localizedDescription)",
                level: .error
            )
            throw UCLHealthError.submitFailed(error)
        }
    }

    // MARK: - Risk Analysis

    /// Calculate cumulative risk score based on recent assessments
    /// - Parameters:
    ///   - patientId: Patient UUID string
    ///   - weeks: Number of weeks to analyze (default 4)
    /// - Returns: Cumulative risk analysis
    func calculateCumulativeRisk(
        for patientId: String,
        weeks: Int = 4
    ) async throws -> CumulativeRiskAnalysis {
        let startDate = Calendar.current.date(byAdding: .weekOfYear, value: -weeks, to: Date()) ?? Date()
        let assessments = try await fetchAssessments(for: patientId, from: startDate, to: Date())

        guard !assessments.isEmpty else {
            return CumulativeRiskAnalysis(
                averageRiskScore: 0,
                maxRiskScore: 0,
                elevatedRiskWeeks: 0,
                totalWeeks: 0,
                riskTrend: .stable,
                recommendation: "Complete your first UCL health assessment to begin tracking."
            )
        }

        let scores = assessments.map { $0.riskScore }
        let avgScore = scores.reduce(0, +) / Double(scores.count)
        let maxScore = scores.max() ?? 0
        let elevatedWeeks = assessments.filter { $0.riskLevel == .high || $0.riskLevel == .critical }.count

        // Determine trend
        let trend: CumulativeRiskAnalysis.RiskTrend
        if assessments.count >= 2 {
            let recentScore = assessments[0].riskScore
            let previousScore = assessments[1].riskScore

            if recentScore < previousScore - 10 {
                trend = .improving
            } else if recentScore > previousScore + 10 {
                trend = .worsening
            } else {
                trend = .stable
            }
        } else {
            trend = .stable
        }

        // Generate recommendation
        let recommendation = generateRecommendation(
            avgScore: avgScore,
            maxScore: maxScore,
            elevatedWeeks: elevatedWeeks,
            trend: trend
        )

        return CumulativeRiskAnalysis(
            averageRiskScore: avgScore,
            maxRiskScore: maxScore,
            elevatedRiskWeeks: elevatedWeeks,
            totalWeeks: assessments.count,
            riskTrend: trend,
            recommendation: recommendation
        )
    }

    /// Analyze throwing workload correlation with risk
    /// - Parameter patientId: Patient UUID string
    /// - Returns: Workload correlation analysis
    func analyzeWorkloadCorrelation(for patientId: String) async throws -> WorkloadCorrelation {
        let assessments = try await fetchAssessments(for: patientId, limit: 12)

        guard assessments.count >= 3 else {
            return WorkloadCorrelation(
                correlation: 0,
                highRiskPitchCount: nil,
                safetyThreshold: nil,
                recommendation: "Complete more assessments to analyze workload patterns."
            )
        }

        // Simple correlation analysis
        let withPitchCounts = assessments.compactMap { assessment -> (pitches: Int, risk: Double)? in
            guard let pitches = assessment.totalPitchCount else { return nil }
            return (pitches, assessment.riskScore)
        }

        guard withPitchCounts.count >= 3 else {
            return WorkloadCorrelation(
                correlation: 0,
                highRiskPitchCount: nil,
                safetyThreshold: nil,
                recommendation: "Log pitch counts consistently to track workload patterns."
            )
        }

        // Find pitch count where risk typically elevates
        let sorted = withPitchCounts.sorted { $0.risk > $1.risk }
        let highRiskAssessments = sorted.filter { $0.risk >= 50 }
        let highRiskPitchCount = highRiskAssessments.first?.pitches

        // Find safe threshold
        let lowRiskAssessments = sorted.filter { $0.risk < 25 }
        let avgSafePitches = lowRiskAssessments.isEmpty ? nil :
            lowRiskAssessments.map { $0.pitches }.reduce(0, +) / lowRiskAssessments.count

        // Simple correlation coefficient
        let pitches = withPitchCounts.map { Double($0.pitches) }
        let risks = withPitchCounts.map { $0.risk }
        let correlation = calculateCorrelation(pitches, risks)

        let recommendation = generateWorkloadRecommendation(
            correlation: correlation,
            highRiskPitchCount: highRiskPitchCount,
            safetyThreshold: avgSafePitches
        )

        return WorkloadCorrelation(
            correlation: correlation,
            highRiskPitchCount: highRiskPitchCount,
            safetyThreshold: avgSafePitches,
            recommendation: recommendation
        )
    }

    // MARK: - Alerts & Notifications

    /// Send elevated risk alert notification
    /// - Parameters:
    ///   - patientId: Patient UUID string
    ///   - riskLevel: Current risk level
    ///   - riskScore: Current risk score
    func sendElevatedRiskAlert(
        patientId: String,
        riskLevel: UCLRiskLevel,
        riskScore: Double
    ) async {
        // Check notification permission
        let settings = await notificationCenter.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        let content = UNMutableNotificationContent()

        switch riskLevel {
        case .high:
            content.title = "UCL Health Alert"
            content.body = "Your UCL risk score is elevated (\(Int(riskScore))). Consider reducing throwing workload and taking a rest day."
            content.sound = .default
        case .critical:
            content.title = "UCL Health - Critical Alert"
            content.body = "Your UCL risk is critical (\(Int(riskScore))). Stop throwing immediately and consult with sports medicine."
            content.sound = UNNotificationSound.defaultCritical
        default:
            return
        }

        content.badge = 1
        content.categoryIdentifier = "UCL_HEALTH_ALERT"

        // Schedule immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = "\(NotificationIdentifier.elevatedRisk).\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)

            // Log the alert
            try? await logNotification(
                patientId: patientId,
                type: riskLevel == .critical ? "ucl_critical" : "ucl_elevated",
                title: content.title,
                body: content.body
            )

            DebugLogger.shared.log(
                "UCLHealthService: Sent \(riskLevel.rawValue) risk alert for patient \(patientId)",
                level: .warning
            )
        } catch {
            DebugLogger.shared.log(
                "UCLHealthService: Failed to send alert - \(error.localizedDescription)",
                level: .error
            )
        }
    }

    /// Schedule weekly UCL check-in reminder
    /// - Parameters:
    ///   - patientId: Patient UUID string
    ///   - dayOfWeek: Day to remind (1=Sunday, 7=Saturday)
    ///   - hour: Hour to remind (0-23)
    func scheduleWeeklyReminder(
        patientId: String,
        dayOfWeek: Int = 1,  // Sunday
        hour: Int = 18  // 6 PM
    ) async throws {
        let settings = await notificationCenter.notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            throw UCLHealthError.notificationPermissionDenied
        }

        // Remove existing weekly reminders
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [NotificationIdentifier.weeklyReminder]
        )

        let content = UNMutableNotificationContent()
        content.title = "Weekly UCL Check-In"
        content.body = "Take a moment to assess your elbow health and track your throwing workload."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = dayOfWeek
        dateComponents.hour = hour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationIdentifier.weeklyReminder,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)

        DebugLogger.shared.log(
            "UCLHealthService: Weekly reminder scheduled for day \(dayOfWeek) at \(hour):00",
            level: .success
        )
    }

    /// Cancel weekly reminder
    func cancelWeeklyReminder() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [NotificationIdentifier.weeklyReminder]
        )
    }

    // MARK: - Private Helpers

    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with fractional seconds
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }

            // Try ISO8601 without fractional seconds
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }

            // Try date only format
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
        return decoder
    }

    private func generateRecommendation(
        avgScore: Double,
        maxScore: Double,
        elevatedWeeks: Int,
        trend: CumulativeRiskAnalysis.RiskTrend
    ) -> String {
        if avgScore >= 50 {
            return "Your average risk score is high. Significantly reduce throwing workload and consult with a sports medicine professional."
        } else if elevatedWeeks >= 2 {
            return "You've had \(elevatedWeeks) weeks with elevated risk. Consider implementing more rest days and monitoring symptoms closely."
        } else if trend == .worsening {
            return "Your risk trend is worsening. Take proactive steps to reduce throwing intensity and improve recovery."
        } else if trend == .improving {
            return "Great progress! Your risk trend is improving. Continue current recovery protocols."
        } else if avgScore < 25 {
            return "Excellent! Your UCL health indicators are strong. Maintain current training and recovery practices."
        } else {
            return "Your UCL health is stable. Continue monitoring weekly and adjust workload as needed."
        }
    }

    private func generateWorkloadRecommendation(
        correlation: Double,
        highRiskPitchCount: Int?,
        safetyThreshold: Int?
    ) -> String {
        if let threshold = safetyThreshold, let highRisk = highRiskPitchCount {
            return "Your data shows elevated risk above \(highRisk) pitches/week. Try to stay below \(threshold) pitches when possible."
        } else if correlation > 0.5 {
            return "Strong correlation between pitch count and risk. Monitor workload carefully."
        } else if correlation < -0.5 {
            return "Interesting pattern: lower workload correlates with higher risk. Ensure adequate conditioning."
        } else {
            return "Continue logging workload data to identify patterns."
        }
    }

    private func calculateCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count, x.count > 2 else { return 0 }

        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)

        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))

        guard denominator > 0 else { return 0 }
        return numerator / denominator
    }

    private func logNotification(
        patientId: String,
        type: String,
        title: String,
        body: String
    ) async throws {
        let record = NotificationLogRecord(
            patientId: patientId,
            notificationType: type,
            title: title,
            body: body,
            sentAt: dateFormatter.string(from: Date())
        )

        try await supabase
            .from("notification_history")
            .insert(record)
            .execute()
    }
}

// MARK: - Supporting Types

/// Full assessment record for database insertion
private struct UCLAssessmentRecord: Encodable {
    let patientId: String
    let assessmentDate: String

    let medialElbowPain: Bool
    let medialPainSeverity: Int?
    let painDuringThrowing: Bool
    let painAfterThrowing: Bool
    let painAtRest: Bool

    let valgusStressDiscomfort: Bool
    let elbowInstabilityFelt: Bool
    let decreasedVelocity: Bool
    let decreasedControlAccuracy: Bool

    let numbnessOrTingling: Bool
    let ringFingerNumbness: Bool
    let pinkyFingerNumbness: Bool

    let totalPitchCount: Int?
    let highIntensityThrows: Int?
    let throwingDays: Int?
    let longestSession: Int?

    let armFatigue: Int
    let recoveryQuality: Int
    let adequateRestDays: Bool

    let symptomScore: Double
    let workloadScore: Double
    let riskScore: Double
    let riskLevel: String

    let notes: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case assessmentDate = "assessment_date"
        case medialElbowPain = "medial_elbow_pain"
        case medialPainSeverity = "medial_pain_severity"
        case painDuringThrowing = "pain_during_throwing"
        case painAfterThrowing = "pain_after_throwing"
        case painAtRest = "pain_at_rest"
        case valgusStressDiscomfort = "valgus_stress_discomfort"
        case elbowInstabilityFelt = "elbow_instability_felt"
        case decreasedVelocity = "decreased_velocity"
        case decreasedControlAccuracy = "decreased_control_accuracy"
        case numbnessOrTingling = "numbness_or_tingling"
        case ringFingerNumbness = "ring_finger_numbness"
        case pinkyFingerNumbness = "pinky_finger_numbness"
        case totalPitchCount = "total_pitch_count"
        case highIntensityThrows = "high_intensity_throws"
        case throwingDays = "throwing_days"
        case longestSession = "longest_session"
        case armFatigue = "arm_fatigue"
        case recoveryQuality = "recovery_quality"
        case adequateRestDays = "adequate_rest_days"
        case symptomScore = "symptom_score"
        case workloadScore = "workload_score"
        case riskScore = "risk_score"
        case riskLevel = "risk_level"
        case notes
    }

    init(
        input: UCLAssessmentInput,
        symptomScore: Double,
        workloadScore: Double,
        riskScore: Double,
        riskLevel: String
    ) {
        self.patientId = input.patientId
        self.assessmentDate = input.assessmentDate
        self.medialElbowPain = input.medialElbowPain
        self.medialPainSeverity = input.medialPainSeverity
        self.painDuringThrowing = input.painDuringThrowing
        self.painAfterThrowing = input.painAfterThrowing
        self.painAtRest = input.painAtRest
        self.valgusStressDiscomfort = input.valgusStressDiscomfort
        self.elbowInstabilityFelt = input.elbowInstabilityFelt
        self.decreasedVelocity = input.decreasedVelocity
        self.decreasedControlAccuracy = input.decreasedControlAccuracy
        self.numbnessOrTingling = input.numbnessOrTingling
        self.ringFingerNumbness = input.ringFingerNumbness
        self.pinkyFingerNumbness = input.pinkyFingerNumbness
        self.totalPitchCount = input.totalPitchCount
        self.highIntensityThrows = input.highIntensityThrows
        self.throwingDays = input.throwingDays
        self.longestSession = input.longestSession
        self.armFatigue = input.armFatigue
        self.recoveryQuality = input.recoveryQuality
        self.adequateRestDays = input.adequateRestDays
        self.symptomScore = symptomScore
        self.workloadScore = workloadScore
        self.riskScore = riskScore
        self.riskLevel = riskLevel
        self.notes = input.notes
    }
}

/// Notification log record for database
private struct NotificationLogRecord: Encodable {
    let patientId: String
    let notificationType: String
    let title: String
    let body: String
    let sentAt: String

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case notificationType = "notification_type"
        case title
        case body
        case sentAt = "sent_at"
    }
}

/// Cumulative risk analysis result
struct CumulativeRiskAnalysis {
    let averageRiskScore: Double
    let maxRiskScore: Double
    let elevatedRiskWeeks: Int
    let totalWeeks: Int
    let riskTrend: RiskTrend
    let recommendation: String

    enum RiskTrend {
        case improving
        case stable
        case worsening
    }
}

/// Workload correlation analysis result
struct WorkloadCorrelation {
    let correlation: Double
    let highRiskPitchCount: Int?
    let safetyThreshold: Int?
    let recommendation: String
}

// MARK: - Errors

enum UCLHealthError: LocalizedError {
    case fetchFailed(Error)
    case submitFailed(Error)
    case notificationPermissionDenied
    case calculationFailed

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Unable to load UCL assessments"
        case .submitFailed:
            return "Unable to save assessment"
        case .notificationPermissionDenied:
            return "Notification permission required"
        case .calculationFailed:
            return "Risk calculation failed"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fetchFailed:
            return "Please check your connection and try again."
        case .submitFailed:
            return "Please check your connection and try again."
        case .notificationPermissionDenied:
            return "Enable notifications in Settings to receive UCL health alerts."
        case .calculationFailed:
            return "Please try submitting the assessment again."
        }
    }

    var underlyingError: Error? {
        switch self {
        case .fetchFailed(let error), .submitFailed(let error):
            return error
        default:
            return nil
        }
    }
}
