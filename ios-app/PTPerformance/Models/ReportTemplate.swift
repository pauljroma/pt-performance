//
//  ReportTemplate.swift
//  PTPerformance
//
//  Report template models for PDF generation
//  Supports multiple report types for therapist documentation
//

import Foundation
import SwiftUI

// MARK: - Report Type

/// Types of clinical reports available for generation
enum ReportType: String, CaseIterable, Identifiable, Codable {
    case progress = "progress"
    case session = "session"
    case compliance = "compliance"
    case discharge = "discharge"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .progress: return "Progress Report"
        case .session: return "Session Summary"
        case .compliance: return "Compliance Report"
        case .discharge: return "Discharge Summary"
        }
    }

    var description: String {
        switch self {
        case .progress:
            return "Weekly or monthly summary of patient progress including pain trends, adherence, and strength improvements"
        case .session:
            return "Detailed documentation of an individual therapy session including exercises performed and patient response"
        case .compliance:
            return "Prescription adherence metrics showing completed vs prescribed exercises over time"
        case .discharge:
            return "Comprehensive treatment summary including goals achieved, functional outcomes, and recommendations"
        }
    }

    var icon: String {
        switch self {
        case .progress: return "chart.line.uptrend.xyaxis"
        case .session: return "doc.text"
        case .compliance: return "checkmark.seal"
        case .discharge: return "checkmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .progress: return .blue
        case .session: return .green
        case .compliance: return .orange
        case .discharge: return .purple
        }
    }

    /// Default sections included in this report type
    var defaultSections: [ReportSection] {
        switch self {
        case .progress:
            return [.patientInfo, .diagnosis, .painTrend, .adherence, .strengthProgression, .therapistNotes, .goals]
        case .session:
            return [.patientInfo, .exerciseLogs, .painTrend, .therapistNotes]
        case .compliance:
            return [.patientInfo, .adherence, .exerciseLogs, .therapistNotes]
        case .discharge:
            return [.patientInfo, .diagnosis, .painTrend, .adherence, .strengthProgression, .goals, .outcomes, .therapistNotes]
        }
    }
}

// MARK: - Report Section

/// Sections that can be included in a report
enum ReportSection: String, CaseIterable, Identifiable, Codable {
    case patientInfo = "patient_info"
    case diagnosis = "diagnosis"
    case exerciseLogs = "exercise_logs"
    case painTrend = "pain_trend"
    case adherence = "adherence"
    case strengthProgression = "strength_progression"
    case therapistNotes = "therapist_notes"
    case goals = "goals"
    case outcomes = "outcomes"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .patientInfo: return "Patient Information"
        case .diagnosis: return "Diagnosis & History"
        case .exerciseLogs: return "Exercise Logs"
        case .painTrend: return "Pain Score Trend"
        case .adherence: return "Adherence Metrics"
        case .strengthProgression: return "Strength Progression"
        case .therapistNotes: return "Therapist Notes"
        case .goals: return "Goals & Objectives"
        case .outcomes: return "Functional Outcomes"
        }
    }

    var icon: String {
        switch self {
        case .patientInfo: return "person.fill"
        case .diagnosis: return "cross.case.fill"
        case .exerciseLogs: return "list.bullet.clipboard"
        case .painTrend: return "heart.fill"
        case .adherence: return "checkmark.circle.fill"
        case .strengthProgression: return "dumbbell.fill"
        case .therapistNotes: return "note.text"
        case .goals: return "target"
        case .outcomes: return "star.fill"
        }
    }
}

// MARK: - Report Date Range

/// Date range options for reports
enum ReportPeriod: Int, CaseIterable, Identifiable, Codable {
    case oneWeek = 7
    case twoWeeks = 14
    case oneMonth = 30
    case threeMonths = 90
    case sixMonths = 180
    case custom = -1

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .oneWeek: return "1 Week"
        case .twoWeeks: return "2 Weeks"
        case .oneMonth: return "1 Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .custom: return "Custom"
        }
    }

    var shortName: String {
        switch self {
        case .oneWeek: return "7d"
        case .twoWeeks: return "14d"
        case .oneMonth: return "30d"
        case .threeMonths: return "90d"
        case .sixMonths: return "180d"
        case .custom: return "Custom"
        }
    }
}

// MARK: - Report Configuration

/// Configuration for generating a report
struct ReportConfiguration: Codable, Equatable {
    let reportType: ReportType
    let patientId: UUID
    let startDate: Date
    let endDate: Date
    let includedSections: [ReportSection]
    let includeCharts: Bool
    let includeClinicBranding: Bool

    init(
        reportType: ReportType,
        patientId: UUID,
        startDate: Date,
        endDate: Date,
        includedSections: [ReportSection]? = nil,
        includeCharts: Bool = true,
        includeClinicBranding: Bool = true
    ) {
        self.reportType = reportType
        self.patientId = patientId
        self.startDate = startDate
        self.endDate = endDate
        self.includedSections = includedSections ?? reportType.defaultSections
        self.includeCharts = includeCharts
        self.includeClinicBranding = includeClinicBranding
    }

    /// Number of days in the report period
    var dayCount: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
}

// MARK: - Clinic Branding

/// Clinic/therapist branding information for reports
struct ClinicBranding: Codable, Equatable {
    let clinicName: String
    let therapistName: String
    let therapistCredentials: String?
    let clinicAddress: String?
    let clinicPhone: String?
    let clinicEmail: String?
    let logoData: Data?
    let accentColorHex: String?

    init(
        clinicName: String = "Physical Therapy Clinic",
        therapistName: String = "Licensed Physical Therapist",
        therapistCredentials: String? = "PT, DPT",
        clinicAddress: String? = nil,
        clinicPhone: String? = nil,
        clinicEmail: String? = nil,
        logoData: Data? = nil,
        accentColorHex: String? = nil
    ) {
        self.clinicName = clinicName
        self.therapistName = therapistName
        self.therapistCredentials = therapistCredentials
        self.clinicAddress = clinicAddress
        self.clinicPhone = clinicPhone
        self.clinicEmail = clinicEmail
        self.logoData = logoData
        self.accentColorHex = accentColorHex
    }

    var accentColor: Color {
        guard let hex = accentColorHex else { return .blue }
        return Color(hex: hex) ?? .blue
    }
}

// MARK: - Report Data

/// Aggregated data for report generation
struct ReportData {
    let patient: Patient
    let configuration: ReportConfiguration
    let branding: ClinicBranding?

    // Section data
    var diagnosis: String?
    var painTrend: [PainDataPoint]
    var adherence: AdherenceData?
    var exerciseLogs: [ExerciseLogDetail]
    var sessions: [SessionSummary]
    var strengthData: StrengthChartData?
    var volumeData: VolumeChartData?
    var notes: [SessionNote]
    var goals: [PatientGoal]

    // Computed properties
    var reportTitle: String {
        "\(configuration.reportType.displayName) - \(patient.fullName)"
    }

    var dateRangeDisplay: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: configuration.startDate)) - \(formatter.string(from: configuration.endDate))"
    }

    var avgPainScore: Double? {
        guard !painTrend.isEmpty else { return nil }
        return painTrend.map { $0.painScore }.reduce(0, +) / Double(painTrend.count)
    }

    var painChange: Double? {
        guard painTrend.count >= 2,
              let first = painTrend.first?.painScore,
              let last = painTrend.last?.painScore else { return nil }
        return last - first
    }

    var completedSessionCount: Int {
        sessions.filter { $0.completed }.count
    }

    var totalExerciseCount: Int {
        exerciseLogs.count
    }

    var activeGoalsCount: Int {
        goals.filter { $0.status == .active }.count
    }

    var completedGoalsCount: Int {
        goals.filter { $0.status == .completed }.count
    }

    init(
        patient: Patient,
        configuration: ReportConfiguration,
        branding: ClinicBranding? = nil
    ) {
        self.patient = patient
        self.configuration = configuration
        self.branding = branding
        self.painTrend = []
        self.exerciseLogs = []
        self.sessions = []
        self.notes = []
        self.goals = []
    }
}

// MARK: - Generated Report

/// Represents a generated PDF report
struct GeneratedReport: Identifiable {
    let id: UUID
    let configuration: ReportConfiguration
    let patientName: String
    let generatedAt: Date
    let pdfData: Data
    let fileURL: URL?

    var fileName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: generatedAt)
        let sanitizedName = patientName.replacingOccurrences(of: " ", with: "_")
        return "\(configuration.reportType.rawValue)_\(sanitizedName)_\(dateStr).pdf"
    }

    var fileSizeDisplay: String {
        let bytes = pdfData.count
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        }
    }
}

// MARK: - Report Preset

/// Quick preset configurations for common report scenarios
struct ReportPreset: Identifiable {
    let name: String
    let description: String
    let reportType: ReportType
    let period: ReportPeriod
    let sections: [ReportSection]
    let icon: String

    var id: String { "\(reportType.rawValue)-\(period.rawValue)-\(name)" }

    static let weeklyProgress = ReportPreset(
        name: "Weekly Progress",
        description: "7-day progress summary with pain and adherence trends",
        reportType: .progress,
        period: .oneWeek,
        sections: [.patientInfo, .painTrend, .adherence, .therapistNotes],
        icon: "calendar.badge.clock"
    )

    static let monthlyProgress = ReportPreset(
        name: "Monthly Progress",
        description: "30-day comprehensive progress with strength data",
        reportType: .progress,
        period: .oneMonth,
        sections: [.patientInfo, .diagnosis, .painTrend, .adherence, .strengthProgression, .goals, .therapistNotes],
        icon: "calendar"
    )

    static let sessionDocumentation = ReportPreset(
        name: "Session Documentation",
        description: "Individual session details for clinical records",
        reportType: .session,
        period: .oneWeek,
        sections: [.patientInfo, .exerciseLogs, .painTrend, .therapistNotes],
        icon: "doc.text"
    )

    static let complianceReview = ReportPreset(
        name: "Compliance Review",
        description: "Adherence analysis for insurance or case review",
        reportType: .compliance,
        period: .oneMonth,
        sections: [.patientInfo, .adherence, .exerciseLogs, .therapistNotes],
        icon: "checkmark.seal"
    )

    static let dischargeSummary = ReportPreset(
        name: "Discharge Summary",
        description: "Complete treatment summary for patient discharge",
        reportType: .discharge,
        period: .threeMonths,
        sections: ReportType.discharge.defaultSections,
        icon: "checkmark.circle"
    )

    static let allPresets: [ReportPreset] = [
        .weeklyProgress,
        .monthlyProgress,
        .sessionDocumentation,
        .complianceReview,
        .dischargeSummary
    ]
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
