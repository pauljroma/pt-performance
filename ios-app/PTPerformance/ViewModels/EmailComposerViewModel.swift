//
//  EmailComposerViewModel.swift
//  PTPerformance
//
//  ViewModel for composing and sending report emails
//  Handles validation, template selection, and sending state
//

import Foundation
import SwiftUI
import Combine

// MARK: - Email Composer View Model

/// View model for the email composer sheet
@MainActor
final class EmailComposerViewModel: ObservableObject {

    // MARK: - Static Formatters
    private static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    // MARK: - Published Properties

    // Recipient fields
    @Published var recipientEmail: String = ""
    @Published var ccEmails: [String] = []
    @Published var includeCCTherapist: Bool = false
    @Published var includeCCClinicAdmin: Bool = false

    // Email content
    @Published var subject: String = ""
    @Published var messageBody: String = ""
    @Published var selectedTemplate: EmailTemplate?

    // Validation
    @Published var recipientEmailError: String?
    @Published var ccEmailErrors: [Int: String] = [:]
    @Published var subjectError: String?
    @Published var bodyError: String?

    // UI State
    @Published var isSending: Bool = false
    @Published var sendingProgress: String = ""
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var showSuccess: Bool = false
    @Published var sentEmailId: UUID?

    // MARK: - Dependencies

    private let emailService: EmailDeliveryService
    private let report: GeneratedReport
    private let patient: Patient
    private let therapistEmail: String?
    private let clinicAdminEmail: String?

    // MARK: - Computed Properties

    /// Whether the form is valid for sending
    var isFormValid: Bool {
        validateRecipientEmail().isValid &&
        validateAllCCEmails() &&
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !messageBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Get all CC emails including optional therapist/admin
    var allCCEmails: [String] {
        var emails = ccEmails.filter { !$0.isEmpty }

        if includeCCTherapist, let therapistEmail = therapistEmail {
            emails.append(therapistEmail)
        }

        if includeCCClinicAdmin, let adminEmail = clinicAdminEmail {
            emails.append(adminEmail)
        }

        return emails
    }

    /// Default subject line based on report type
    var defaultSubject: String {
        let reportType = report.configuration.reportType
        let patientName = patient.firstName
        let dateStr = formattedDate(Date())

        switch reportType {
        case .progress:
            return "Your Progress Report - \(dateStr)"
        case .session:
            return "Session Summary - \(dateStr)"
        case .compliance:
            return "Exercise Compliance Report - \(dateStr)"
        case .discharge:
            return "Discharge Summary - \(report.patientName)"
        }
    }

    // MARK: - Initialization

    @MainActor
    init(
        report: GeneratedReport,
        patient: Patient,
        therapistEmail: String? = nil,
        clinicAdminEmail: String? = nil,
        emailService: EmailDeliveryService = .shared
    ) {
        self.report = report
        self.patient = patient
        self.therapistEmail = therapistEmail
        self.clinicAdminEmail = clinicAdminEmail
        self.emailService = emailService

        // Pre-fill recipient email
        self.recipientEmail = patient.email

        // Set default subject
        self.subject = defaultSubject

        // Set default message based on report type
        applyDefaultTemplate()
    }

    // MARK: - Template Management

    /// Apply a template to the email content
    func applyTemplate(_ template: EmailTemplate) {
        selectedTemplate = template

        if !template.subject.isEmpty {
            subject = template.subject
        }

        if !template.body.isEmpty {
            messageBody = template.body + "\n\n" + therapistSignature
        }

        HapticFeedback.selectionChanged()
    }

    /// Apply default template based on report type
    private func applyDefaultTemplate() {
        let template: EmailTemplate

        switch report.configuration.reportType {
        case .progress:
            template = .progressReport
        case .session:
            template = .sessionSummary
        case .compliance:
            template = .complianceReport
        case .discharge:
            template = .dischargeReport
        }

        messageBody = template.body + "\n\n" + therapistSignature
        selectedTemplate = template
    }

    /// Therapist signature for emails
    private var therapistSignature: String {
        if let therapistEmail = therapistEmail {
            return "Your Physical Therapist"
        }
        return "Your Physical Therapy Team"
    }

    // MARK: - CC Email Management

    /// Add a new CC email field
    func addCCEmail() {
        ccEmails.append("")
    }

    /// Remove a CC email at index
    func removeCCEmail(at index: Int) {
        guard index < ccEmails.count else { return }
        ccEmails.remove(at: index)
        ccEmailErrors.removeValue(forKey: index)
    }

    /// Update CC email at index
    func updateCCEmail(_ email: String, at index: Int) {
        guard index < ccEmails.count else { return }
        ccEmails[index] = email
        validateCCEmail(at: index)
    }

    // MARK: - Validation

    /// Validate the recipient email
    func validateRecipientEmail() -> EmailValidationResult {
        let trimmed = recipientEmail.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            recipientEmailError = "Email address is required"
            return .invalid("Email address is required")
        }

        let emailPattern = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailPattern)

        if !emailPredicate.evaluate(with: trimmed) {
            recipientEmailError = "Please enter a valid email address"
            return .invalid("Please enter a valid email address")
        }

        recipientEmailError = nil
        return .valid
    }

    /// Validate a CC email at a specific index
    func validateCCEmail(at index: Int) {
        guard index < ccEmails.count else { return }
        let email = ccEmails[index]

        // Empty CC emails are allowed (user hasn't filled it yet)
        if email.isEmpty {
            ccEmailErrors.removeValue(forKey: index)
            return
        }

        let emailPattern = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailPattern)

        if !emailPredicate.evaluate(with: email.trimmingCharacters(in: .whitespacesAndNewlines)) {
            ccEmailErrors[index] = "Invalid email"
        } else {
            ccEmailErrors.removeValue(forKey: index)
        }
    }

    /// Validate all CC emails
    func validateAllCCEmails() -> Bool {
        for (index, email) in ccEmails.enumerated() where !email.isEmpty {
            let emailPattern = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailPattern)

            if !emailPredicate.evaluate(with: email.trimmingCharacters(in: .whitespacesAndNewlines)) {
                ccEmailErrors[index] = "Invalid email"
                return false
            }
        }
        return true
    }

    /// Validate subject line
    func validateSubject() {
        if subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            subjectError = "Subject is required"
        } else {
            subjectError = nil
        }
    }

    /// Validate message body
    func validateBody() {
        if messageBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            bodyError = "Message is required"
        } else {
            bodyError = nil
        }
    }

    /// Perform full validation
    func validateAll() -> Bool {
        _ = validateRecipientEmail()
        _ = validateAllCCEmails()
        validateSubject()
        validateBody()

        return isFormValid
    }

    // MARK: - Send Email

    /// Send the email with the report attached
    func sendEmail() async -> Bool {
        guard validateAll() else {
            HapticFeedback.error()
            return false
        }

        isSending = true
        sendingProgress = "Preparing email..."
        showError = false
        errorMessage = ""

        do {
            sendingProgress = "Uploading report..."

            let historyItem = try await emailService.sendReport(
                report: report,
                to: recipientEmail.trimmingCharacters(in: .whitespacesAndNewlines),
                cc: allCCEmails.isEmpty ? nil : allCCEmails,
                subject: subject.trimmingCharacters(in: .whitespacesAndNewlines),
                message: messageBody.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            sendingProgress = "Email sent!"
            sentEmailId = historyItem.id
            showSuccess = true
            isSending = false

            HapticFeedback.success()

            // Track success
            AnalyticsTracker.shared.track(
                event: "email_composer_sent",
                properties: [
                    "report_type": report.configuration.reportType.rawValue,
                    "has_cc": !allCCEmails.isEmpty
                ]
            )

            return true

        } catch let error as EmailDeliveryError {
            handleSendError(error)
            return false

        } catch {
            handleSendError(EmailDeliveryError.networkError(error))
            return false
        }
    }

    /// Handle send error
    private func handleSendError(_ error: EmailDeliveryError) {
        isSending = false
        sendingProgress = ""
        errorMessage = error.localizedDescription
        showError = true
        HapticFeedback.error()

        AnalyticsTracker.shared.track(
            event: "email_composer_error",
            properties: [
                "error": error.localizedDescription
            ]
        )
    }

    // MARK: - Helpers

    /// Format date for display
    private func formattedDate(_ date: Date) -> String {
        Self.mediumDateFormatter.string(from: date)
    }

    /// Reset the form for a new email
    func resetForm() {
        recipientEmail = patient.email
        ccEmails = []
        includeCCTherapist = false
        includeCCClinicAdmin = false
        subject = defaultSubject
        applyDefaultTemplate()

        recipientEmailError = nil
        ccEmailErrors = [:]
        subjectError = nil
        bodyError = nil

        isSending = false
        sendingProgress = ""
        showError = false
        errorMessage = ""
        showSuccess = false
        sentEmailId = nil
    }
}

// MARK: - Email Composer State Extension

extension EmailComposerViewModel {

    /// Get the current state as EmailComposerState
    var state: EmailComposerState {
        EmailComposerState(
            recipientEmail: recipientEmail,
            ccEmails: ccEmails,
            subject: subject,
            body: messageBody,
            selectedTemplate: selectedTemplate,
            includeCCTherapist: includeCCTherapist,
            includeCCClinicAdmin: includeCCClinicAdmin
        )
    }
}
