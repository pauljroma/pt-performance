//
//  EmailDeliveryService.swift
//  PTPerformance
//
//  Service for sending PDF reports via email to patients
//  Uses Supabase edge function for actual email delivery (SendGrid/Resend)
//

import Foundation
import Supabase

// MARK: - Email Delivery Service

/// Service for sending report emails and tracking delivery status
///
/// Thread-safe actor that handles:
/// - Sending PDF reports via backend edge function
/// - Tracking email delivery status
/// - Managing email history for patients
/// - Uploading report attachments to storage
///
/// ## Usage
/// ```swift
/// // Send a report email
/// let result = try await EmailDeliveryService.shared.sendReport(
///     report: generatedReport,
///     to: "patient@email.com",
///     subject: "Your Progress Report",
///     message: "Please find attached..."
/// )
///
/// // Check delivery status
/// let status = try await EmailDeliveryService.shared.getDeliveryStatus(reportId: reportId)
/// ```
actor EmailDeliveryService {

    // MARK: - Static Formatters

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        return f
    }()

    // MARK: - Singleton

    static let shared = EmailDeliveryService()

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let errorLogger: ErrorLogger
    private let debugLogger: DebugLogger

    // MARK: - Constants

    private enum Constants {
        static let edgeFunctionName = "send-report-email"
        static let storageBucket = "report-attachments"
        static let emailHistoryTable = "email_delivery_history"
        static let maxAttachmentSize = 10 * 1024 * 1024 // 10 MB
    }

    // MARK: - Initialization

    init(
        supabase: PTSupabaseClient = .shared,
        errorLogger: ErrorLogger = .shared,
        debugLogger: DebugLogger = .shared
    ) {
        self.supabase = supabase
        self.errorLogger = errorLogger
        self.debugLogger = debugLogger
    }

    // MARK: - Send Report

    /// Send a PDF report via email to a patient
    ///
    /// - Parameters:
    ///   - report: The generated report to send
    ///   - to: Recipient email address
    ///   - cc: Optional CC email addresses
    ///   - subject: Email subject line
    ///   - message: Email body message
    /// - Returns: The email history item for tracking
    /// - Throws: EmailDeliveryError if sending fails
    func sendReport(
        report: GeneratedReport,
        to recipientEmail: String,
        cc ccEmails: [String]? = nil,
        subject: String,
        message: String
    ) async throws -> EmailHistoryItem {
        #if DEBUG
        debugLogger.log("Sending report email to: \(recipientEmail)", level: .info)
        #endif

        // Validate recipient email
        guard validateEmail(recipientEmail) else {
            throw EmailDeliveryError.invalidEmail(recipientEmail)
        }

        // Validate CC emails if provided
        if let ccEmails = ccEmails {
            for email in ccEmails where !email.isEmpty {
                guard validateEmail(email) else {
                    throw EmailDeliveryError.invalidEmail(email)
                }
            }
        }

        // Get current therapist ID
        guard let therapistId = supabase.userId else {
            throw EmailDeliveryError.notAuthenticated
        }

        // Upload attachment to storage
        let attachmentUrl = try await uploadReportToStorage(report: report)

        // Build request payload
        let request = EmailRequest(
            to: recipientEmail,
            cc: ccEmails?.filter { !$0.isEmpty },
            subject: subject,
            body: message,
            attachmentUrl: attachmentUrl,
            attachmentName: report.fileName,
            reportType: report.configuration.reportType.rawValue,
            patientId: report.configuration.patientId.uuidString,
            therapistId: therapistId,
            reportId: report.id.uuidString
        )

        // Call edge function
        let response = try await callSendEmailFunction(request: request)

        guard response.success else {
            let errorMessage = response.error ?? "Unknown error"
            debugLogger.log("Email send failed: \(errorMessage)", level: .error)
            throw EmailDeliveryError.sendFailed(errorMessage)
        }

        debugLogger.log("Email sent successfully, messageId: \(response.messageId ?? "unknown")", level: .success)

        // Create and return history record
        let historyItem = try await createEmailHistoryRecord(
            request: request,
            messageId: response.messageId
        )

        // Track analytics
        trackEmailSent(reportType: report.configuration.reportType.rawValue)

        return historyItem
    }

    /// Send a report email with optional report data attachment
    ///
    /// - Parameters:
    ///   - pdfData: Raw PDF data to attach
    ///   - fileName: Name for the attachment file
    ///   - reportType: Type of report being sent
    ///   - patientId: ID of the patient
    ///   - to: Recipient email address
    ///   - cc: Optional CC email addresses
    ///   - subject: Email subject line
    ///   - message: Email body message
    /// - Returns: The email history item for tracking
    func sendReportData(
        pdfData: Data,
        fileName: String,
        reportType: ReportType,
        patientId: UUID,
        to recipientEmail: String,
        cc ccEmails: [String]? = nil,
        subject: String,
        message: String
    ) async throws -> EmailHistoryItem {
        #if DEBUG
        debugLogger.log("Sending report data email to: \(recipientEmail)", level: .info)
        #endif

        // Validate attachment size
        guard pdfData.count <= Constants.maxAttachmentSize else {
            throw EmailDeliveryError.attachmentTooLarge
        }

        // Validate recipient email
        guard validateEmail(recipientEmail) else {
            throw EmailDeliveryError.invalidEmail(recipientEmail)
        }

        // Get current therapist ID
        guard let therapistId = supabase.userId else {
            throw EmailDeliveryError.notAuthenticated
        }

        // Upload PDF data to storage
        let attachmentUrl = try await uploadPDFDataToStorage(data: pdfData, fileName: fileName)

        // Build request payload
        let request = EmailRequest(
            to: recipientEmail,
            cc: ccEmails?.filter { !$0.isEmpty },
            subject: subject,
            body: message,
            attachmentUrl: attachmentUrl,
            attachmentName: fileName,
            reportType: reportType.rawValue,
            patientId: patientId.uuidString,
            therapistId: therapistId,
            reportId: nil
        )

        // Call edge function
        let response = try await callSendEmailFunction(request: request)

        guard response.success else {
            throw EmailDeliveryError.sendFailed(response.error ?? "Unknown error")
        }

        // Create and return history record
        let historyItem = try await createEmailHistoryRecord(
            request: request,
            messageId: response.messageId
        )

        return historyItem
    }

    // MARK: - Delivery Status

    /// Get the current delivery status for a sent email
    ///
    /// - Parameter emailId: The ID of the email history record
    /// - Returns: The current delivery status
    func getDeliveryStatus(emailId: UUID) async throws -> EmailDeliveryStatus {
        debugLogger.log("Fetching delivery status for email: \(emailId)", level: .info)

        let response = try await supabase.client
            .from(Constants.emailHistoryTable)
            .select("status")
            .eq("id", value: emailId.uuidString)
            .single()
            .execute()

        struct StatusResponse: Codable {
            let status: EmailDeliveryStatus
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(StatusResponse.self, from: response.data)
        return result.status
    }

    /// Get the delivery status for a report by report ID
    ///
    /// - Parameter reportId: The ID of the report that was emailed
    /// - Returns: The current delivery status, or nil if not found
    func getDeliveryStatus(reportId: UUID) async throws -> EmailDeliveryStatus? {
        debugLogger.log("Fetching delivery status for report: \(reportId)", level: .info)

        let response: [EmailHistoryItem] = try await supabase.client
            .from(Constants.emailHistoryTable)
            .select()
            .eq("report_id", value: reportId.uuidString)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        return response.first?.status
    }

    // MARK: - Email History

    /// Get the email history for a specific patient
    ///
    /// - Parameters:
    ///   - patientId: The patient ID to fetch history for
    ///   - limit: Maximum number of records to return (default 50)
    /// - Returns: Array of email history items
    func getEmailHistory(patientId: UUID, limit: Int = 50) async throws -> [EmailHistoryItem] {
        #if DEBUG
        debugLogger.log("Fetching email history for patient: \(patientId)", level: .info)
        #endif

        let response: [EmailHistoryItem] = try await supabase.client
            .from(Constants.emailHistoryTable)
            .select()
            .eq("patient_id", value: patientId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        debugLogger.log("Found \(response.count) email history items", level: .success)
        return response
    }

    /// Get filtered email history for a patient
    ///
    /// - Parameters:
    ///   - patientId: The patient ID to fetch history for
    ///   - filter: Filter options for the query
    /// - Returns: Array of filtered email history items
    func getEmailHistory(patientId: UUID, filter: EmailHistoryFilter) async throws -> [EmailHistoryItem] {
        var query = supabase.client
            .from(Constants.emailHistoryTable)
            .select()
            .eq("patient_id", value: patientId.uuidString)

        // Apply date range filters
        if let startDate = filter.startDate {
            query = query.gte("created_at", value: Self.iso8601Formatter.string(from: startDate))
        }

        if let endDate = filter.endDate {
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: endDate) ?? endDate
            query = query.lt("created_at", value: Self.iso8601Formatter.string(from: endOfDay))
        }

        // Apply status filter
        if let status = filter.statusFilter {
            query = query.eq("status", value: status.rawValue)
        }

        let response: [EmailHistoryItem] = try await query
            .order("created_at", ascending: false)
            .execute()
            .value

        // Apply text search filter locally (Supabase doesn't support full-text search on all columns)
        if !filter.searchText.isEmpty {
            return response.filter { filter.matches($0) }
        }

        return response
    }

    /// Resend a failed email
    ///
    /// - Parameter emailId: The ID of the email to resend
    /// - Returns: New email history item for the resend attempt
    func resendEmail(emailId: UUID) async throws -> EmailHistoryItem {
        debugLogger.log("Resending email: \(emailId)", level: .info)

        // Fetch original email
        let originalEmails: [EmailHistoryItem] = try await supabase.client
            .from(Constants.emailHistoryTable)
            .select()
            .eq("id", value: emailId.uuidString)
            .execute()
            .value

        guard let original = originalEmails.first else {
            throw EmailDeliveryError.emailNotFound
        }

        // Verify it can be resent
        guard original.status.canResend else {
            throw EmailDeliveryError.cannotResend
        }

        // Get therapist ID
        guard let therapistId = supabase.userId else {
            throw EmailDeliveryError.notAuthenticated
        }

        // Build request from original
        let request = EmailRequest(
            to: original.recipientEmail,
            cc: original.ccEmails,
            subject: original.subject,
            body: original.body,
            attachmentUrl: nil, // Attachment URL may have expired
            attachmentName: original.attachmentName,
            reportType: original.reportType,
            patientId: original.patientId.uuidString,
            therapistId: therapistId,
            reportId: original.reportId?.uuidString
        )

        // Call edge function
        let response = try await callSendEmailFunction(request: request)

        guard response.success else {
            throw EmailDeliveryError.sendFailed(response.error ?? "Unknown error")
        }

        // Create new history record
        let historyItem = try await createEmailHistoryRecord(
            request: request,
            messageId: response.messageId
        )

        debugLogger.log("Email resent successfully", level: .success)
        return historyItem
    }

    // MARK: - Private Methods

    /// Validate an email address format
    private func validateEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let emailPattern = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailPattern)
        return emailPredicate.evaluate(with: trimmed)
    }

    /// Upload a report to Supabase storage
    private func uploadReportToStorage(report: GeneratedReport) async throws -> String {
        let fileName = "\(UUID().uuidString)_\(report.fileName)"
        let path = "reports/\(fileName)"

        debugLogger.log("Uploading report to storage: \(path)", level: .info)

        try await supabase.client.storage
            .from(Constants.storageBucket)
            .upload(
                path: path,
                file: report.pdfData,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: "application/pdf"
                )
            )

        // Get public URL
        let publicURL = try supabase.client.storage
            .from(Constants.storageBucket)
            .getPublicURL(path: path)

        return publicURL.absoluteString
    }

    /// Upload raw PDF data to storage
    private func uploadPDFDataToStorage(data: Data, fileName: String) async throws -> String {
        let path = "reports/\(UUID().uuidString)_\(fileName)"

        debugLogger.log("Uploading PDF data to storage: \(path)", level: .info)

        try await supabase.client.storage
            .from(Constants.storageBucket)
            .upload(
                path: path,
                file: data,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: "application/pdf"
                )
            )

        let publicURL = try supabase.client.storage
            .from(Constants.storageBucket)
            .getPublicURL(path: path)

        return publicURL.absoluteString
    }

    /// Call the send-email edge function
    private func callSendEmailFunction(request: EmailRequest) async throws -> EmailResponse {
        debugLogger.log("Calling edge function: \(Constants.edgeFunctionName)", level: .info)

        do {
            let encoder = JSONEncoder()
            let bodyData = try encoder.encode(request)

            let responseData: Data = try await supabase.client.functions.invoke(
                Constants.edgeFunctionName,
                options: FunctionInvokeOptions(body: bodyData)
            ) { data, _ in
                data
            }

            let decoder = JSONDecoder()
            return try decoder.decode(EmailResponse.self, from: responseData)
        } catch {
            errorLogger.logError(error, context: "EmailDeliveryService.callSendEmailFunction")
            throw EmailDeliveryError.networkError(error)
        }
    }

    /// Create an email history record in the database
    private func createEmailHistoryRecord(
        request: EmailRequest,
        messageId: String?
    ) async throws -> EmailHistoryItem {
        let record = EmailDeliveryRecord(
            patientId: request.patientId,
            therapistId: request.therapistId,
            recipientEmail: request.to,
            ccEmails: request.cc,
            subject: request.subject,
            body: request.body,
            reportType: request.reportType,
            reportId: request.reportId,
            attachmentName: request.attachmentName,
            status: EmailDeliveryStatus.sent.rawValue,
            messageId: messageId
        )

        let response: [EmailHistoryItem] = try await supabase.client
            .from(Constants.emailHistoryTable)
            .insert(record)
            .select()
            .execute()
            .value

        guard let historyItem = response.first else {
            throw EmailDeliveryError.recordCreationFailed
        }

        return historyItem
    }

    /// Track email sent analytics
    private func trackEmailSent(reportType: String) {
        AnalyticsTracker.shared.track(
            event: "report_email_sent",
            properties: [
                "report_type": reportType
            ]
        )
    }
}

// MARK: - Email Delivery Errors

/// Errors specific to email delivery operations
enum EmailDeliveryError: LocalizedError {
    case invalidEmail(String)
    case notAuthenticated
    case attachmentTooLarge
    case uploadFailed(Error)
    case sendFailed(String)
    case networkError(Error)
    case emailNotFound
    case cannotResend
    case recordCreationFailed
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .invalidEmail(let email):
            return "Invalid email address: \(email)"
        case .notAuthenticated:
            return "You must be logged in to send emails"
        case .attachmentTooLarge:
            return "The attachment is too large (max 10 MB)"
        case .uploadFailed:
            return "Failed to upload report attachment"
        case .sendFailed(let message):
            return "Failed to send email: \(message)"
        case .networkError:
            return "Network error occurred while sending email"
        case .emailNotFound:
            return "Email record not found"
        case .cannotResend:
            return "This email cannot be resent"
        case .recordCreationFailed:
            return "Failed to create email record"
        case .rateLimited:
            return "Too many emails sent. Please wait before sending more."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidEmail:
            return "Please check the email address and try again."
        case .notAuthenticated:
            return "Please log in and try again."
        case .attachmentTooLarge:
            return "Try generating a smaller report with fewer sections."
        case .uploadFailed, .networkError:
            return "Check your internet connection and try again."
        case .sendFailed:
            return "Please try again. If the problem persists, contact support."
        case .emailNotFound:
            return "The email may have been deleted."
        case .cannotResend:
            return "Only failed or bounced emails can be resent."
        case .recordCreationFailed:
            return "Please try again."
        case .rateLimited:
            return "Wait a few minutes before sending more emails."
        }
    }

    /// PII-safe error type for analytics tracking
    /// Does not include any email addresses, names, or other personal information
    var analyticsErrorType: String {
        switch self {
        case .invalidEmail:
            return "invalid_email"
        case .notAuthenticated:
            return "not_authenticated"
        case .attachmentTooLarge:
            return "attachment_too_large"
        case .uploadFailed:
            return "upload_failed"
        case .sendFailed:
            return "send_failed"
        case .networkError:
            return "network_error"
        case .emailNotFound:
            return "email_not_found"
        case .cannotResend:
            return "cannot_resend"
        case .recordCreationFailed:
            return "record_creation_failed"
        case .rateLimited:
            return "rate_limited"
        }
    }
}
