//
//  EmailDelivery.swift
//  PTPerformance
//
//  Email delivery models for report distribution
//  Supports email composition, delivery tracking, and history
//

import Foundation

// MARK: - Email Delivery Status

/// Status of an email delivery attempt
enum EmailDeliveryStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case sending = "sending"
    case sent = "sent"
    case delivered = "delivered"
    case opened = "opened"
    case failed = "failed"
    case bounced = "bounced"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .sending: return "Sending..."
        case .sent: return "Sent"
        case .delivered: return "Delivered"
        case .opened: return "Opened"
        case .failed: return "Failed"
        case .bounced: return "Bounced"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .sending: return "arrow.up.circle"
        case .sent: return "paperplane.fill"
        case .delivered: return "checkmark.circle.fill"
        case .opened: return "envelope.open.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .bounced: return "arrow.uturn.left.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .pending: return "gray"
        case .sending: return "blue"
        case .sent: return "blue"
        case .delivered: return "green"
        case .opened: return "green"
        case .failed: return "red"
        case .bounced: return "orange"
        }
    }

    /// Whether the email was successfully delivered
    var isSuccess: Bool {
        switch self {
        case .sent, .delivered, .opened:
            return true
        case .pending, .sending, .failed, .bounced:
            return false
        }
    }

    /// Whether a resend is possible
    var canResend: Bool {
        switch self {
        case .failed, .bounced:
            return true
        case .pending, .sending, .sent, .delivered, .opened:
            return false
        }
    }
}

// MARK: - Email Request

/// Request payload for sending an email via edge function
struct EmailRequest: Codable {
    let to: String
    let cc: [String]?
    let subject: String
    let body: String
    let attachmentUrl: String?
    let attachmentName: String?
    let reportType: String
    let patientId: String
    let therapistId: String
    let reportId: String?

    enum CodingKeys: String, CodingKey {
        case to
        case cc
        case subject
        case body
        case attachmentUrl = "attachment_url"
        case attachmentName = "attachment_name"
        case reportType = "report_type"
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case reportId = "report_id"
    }

    init(
        to: String,
        cc: [String]? = nil,
        subject: String,
        body: String,
        attachmentUrl: String? = nil,
        attachmentName: String? = nil,
        reportType: String,
        patientId: String,
        therapistId: String,
        reportId: String? = nil
    ) {
        self.to = to
        self.cc = cc
        self.subject = subject
        self.body = body
        self.attachmentUrl = attachmentUrl
        self.attachmentName = attachmentName
        self.reportType = reportType
        self.patientId = patientId
        self.therapistId = therapistId
        self.reportId = reportId
    }
}

// MARK: - Email Response

/// Response from the email sending edge function
struct EmailResponse: Codable {
    let success: Bool
    let messageId: String?
    let error: String?
    let errorCode: String?

    enum CodingKeys: String, CodingKey {
        case success
        case messageId = "message_id"
        case error
        case errorCode = "error_code"
    }
}

// MARK: - Email History Item

/// Record of a sent email for tracking and history
struct EmailHistoryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let patientId: UUID
    let therapistId: UUID
    let recipientEmail: String
    let ccEmails: [String]?
    let subject: String
    let body: String
    let reportType: String
    let reportId: UUID?
    let attachmentName: String?
    let status: EmailDeliveryStatus
    let messageId: String?
    let sentAt: Date?
    let deliveredAt: Date?
    let openedAt: Date?
    let failedAt: Date?
    let errorMessage: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case recipientEmail = "recipient_email"
        case ccEmails = "cc_emails"
        case subject
        case body
        case reportType = "report_type"
        case reportId = "report_id"
        case attachmentName = "attachment_name"
        case status
        case messageId = "message_id"
        case sentAt = "sent_at"
        case deliveredAt = "delivered_at"
        case openedAt = "opened_at"
        case failedAt = "failed_at"
        case errorMessage = "error_message"
        case createdAt = "created_at"
    }

    /// Display-friendly date for the email
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: sentAt ?? createdAt)
    }

    /// Short date display (Today, Yesterday, or date)
    var shortDateDisplay: String {
        let calendar = Calendar.current
        let date = sentAt ?? createdAt

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Today, \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Yesterday, \(formatter.string(from: date))"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    static func == (lhs: EmailHistoryItem, rhs: EmailHistoryItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Email Delivery Record (for creation)

/// Record to insert when sending an email
struct EmailDeliveryRecord: Codable {
    let patientId: String
    let therapistId: String
    let recipientEmail: String
    let ccEmails: [String]?
    let subject: String
    let body: String
    let reportType: String
    let reportId: String?
    let attachmentName: String?
    let status: String
    let messageId: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case recipientEmail = "recipient_email"
        case ccEmails = "cc_emails"
        case subject
        case body
        case reportType = "report_type"
        case reportId = "report_id"
        case attachmentName = "attachment_name"
        case status
        case messageId = "message_id"
    }
}

// MARK: - Email Template

/// Pre-defined email templates for common scenarios
struct EmailTemplate: Identifiable {
    let id = UUID()
    let name: String
    let subject: String
    let body: String
    let icon: String

    static let progressReport = EmailTemplate(
        name: "Progress Update",
        subject: "Your Physical Therapy Progress Report",
        body: """
        Hi,

        Please find attached your progress report summarizing your physical therapy journey.

        This report includes:
        - Pain level trends
        - Exercise adherence metrics
        - Strength progression data
        - Therapist notes and recommendations

        Please review the report and let me know if you have any questions or concerns.

        Best regards,
        """
    )

    static let sessionSummary = EmailTemplate(
        name: "Session Summary",
        subject: "Today's Physical Therapy Session Summary",
        body: """
        Hi,

        Attached is a summary of today's physical therapy session.

        Please review the exercises we covered and continue with your home exercise program as discussed. If you experience any unusual discomfort, please don't hesitate to reach out.

        See you at our next session!

        Best regards,
        """
    )

    static let dischargeReport = EmailTemplate(
        name: "Discharge Summary",
        subject: "Physical Therapy Discharge Summary",
        body: """
        Hi,

        Congratulations on completing your physical therapy program! Please find attached your discharge summary.

        This report documents:
        - Your treatment progress and outcomes
        - Goals achieved during therapy
        - Recommendations for continued home exercises
        - Guidelines for maintaining your progress

        It has been a pleasure working with you. Please don't hesitate to reach out if you have any questions or need follow-up care.

        Wishing you continued health and wellness,
        """
    )

    static let complianceReport = EmailTemplate(
        name: "Compliance Report",
        subject: "Exercise Compliance Report",
        body: """
        Hi,

        Please find attached your exercise compliance report for your records.

        This report shows your adherence to the prescribed exercise program. Consistent participation is key to achieving your therapy goals.

        Please let me know if you have any questions or if there's anything I can do to help support your progress.

        Best regards,
        """
    )

    static let custom = EmailTemplate(
        name: "Custom",
        subject: "",
        body: "",
        icon: "square.and.pencil"
    )

    static let allTemplates: [EmailTemplate] = [
        .progressReport,
        .sessionSummary,
        .dischargeReport,
        .complianceReport,
        .custom
    ]

    init(name: String, subject: String, body: String, icon: String = "envelope") {
        self.name = name
        self.subject = subject
        self.body = body
        self.icon = icon
    }
}

// MARK: - Email Validation

/// Email address validation result
struct EmailValidationResult {
    let isValid: Bool
    let errorMessage: String?

    static let valid = EmailValidationResult(isValid: true, errorMessage: nil)

    static func invalid(_ message: String) -> EmailValidationResult {
        EmailValidationResult(isValid: false, errorMessage: message)
    }
}

// MARK: - Email Composer State

/// State for email composition
struct EmailComposerState {
    var recipientEmail: String = ""
    var ccEmails: [String] = []
    var subject: String = ""
    var body: String = ""
    var selectedTemplate: EmailTemplate?
    var includeCCTherapist: Bool = false
    var includeCCClinicAdmin: Bool = false

    var isValid: Bool {
        !recipientEmail.isEmpty &&
        !subject.isEmpty &&
        !body.isEmpty &&
        validateEmail(recipientEmail).isValid
    }

    func validateEmail(_ email: String) -> EmailValidationResult {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return .invalid("Email address is required")
        }

        let emailPattern = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailPattern)

        if !emailPredicate.evaluate(with: trimmed) {
            return .invalid("Please enter a valid email address")
        }

        return .valid
    }

    func validateAllCCEmails() -> EmailValidationResult {
        for email in ccEmails where !email.isEmpty {
            let result = validateEmail(email)
            if !result.isValid {
                return .invalid("Invalid CC email: \(email)")
            }
        }
        return .valid
    }
}

// MARK: - Email Filter Options

/// Filter options for email history
struct EmailHistoryFilter {
    var startDate: Date?
    var endDate: Date?
    var statusFilter: EmailDeliveryStatus?
    var searchText: String = ""

    var hasActiveFilters: Bool {
        startDate != nil || endDate != nil || statusFilter != nil || !searchText.isEmpty
    }

    func matches(_ item: EmailHistoryItem) -> Bool {
        // Date range filter
        if let start = startDate {
            let itemDate = item.sentAt ?? item.createdAt
            if itemDate < start {
                return false
            }
        }

        if let end = endDate {
            let itemDate = item.sentAt ?? item.createdAt
            // Add 1 day to end date to include the entire day
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: end) ?? end
            if itemDate > endOfDay {
                return false
            }
        }

        // Status filter
        if let status = statusFilter, item.status != status {
            return false
        }

        // Search text filter
        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            let matchesRecipient = item.recipientEmail.lowercased().contains(lowercasedSearch)
            let matchesSubject = item.subject.lowercased().contains(lowercasedSearch)
            if !matchesRecipient && !matchesSubject {
                return false
            }
        }

        return true
    }
}

// MARK: - Supabase Edge Function Spec

/// Documentation for the Supabase edge function interface
///
/// ## Endpoint
/// `POST /send-report-email`
///
/// ## Request Body (EmailRequest)
/// ```json
/// {
///   "to": "patient@example.com",
///   "cc": ["therapist@clinic.com"],
///   "subject": "Your Progress Report",
///   "body": "Please find attached...",
///   "attachment_url": "https://storage.example.com/reports/abc123.pdf",
///   "attachment_name": "progress_report_2024-01-15.pdf",
///   "report_type": "progress",
///   "patient_id": "uuid",
///   "therapist_id": "uuid",
///   "report_id": "uuid"
/// }
/// ```
///
/// ## Response (EmailResponse)
/// ```json
/// {
///   "success": true,
///   "message_id": "msg_abc123",
///   "error": null,
///   "error_code": null
/// }
/// ```
///
/// ## Error Codes
/// - `INVALID_EMAIL`: Invalid recipient email address
/// - `ATTACHMENT_NOT_FOUND`: Attachment URL is invalid or inaccessible
/// - `RATE_LIMITED`: Too many emails sent in a short period
/// - `PROVIDER_ERROR`: Email provider (SendGrid/Resend) error
/// - `UNAUTHORIZED`: Invalid or missing authorization
///
/// ## Implementation Notes
/// - Uses SendGrid or Resend for actual email delivery
/// - Stores delivery record in `email_delivery_history` table
/// - Webhooks update status (delivered, opened, bounced)
/// - Rate limited to 10 emails per minute per therapist
enum EmailEdgeFunctionSpec {}
