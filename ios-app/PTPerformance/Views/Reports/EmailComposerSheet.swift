//
//  EmailComposerSheet.swift
//  PTPerformance
//
//  Email composition interface for sending PDF reports to patients
//  Supports pre-filled recipients, templates, and CC options
//

import SwiftUI
import PDFKit

// MARK: - Email Composer Sheet

struct EmailComposerSheet: View {
    let report: GeneratedReport
    let patient: Patient
    var therapistEmail: String?
    var clinicAdminEmail: String?
    var onSuccess: ((UUID) -> Void)?

    @StateObject private var viewModel: EmailComposerViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        report: GeneratedReport,
        patient: Patient,
        therapistEmail: String? = nil,
        clinicAdminEmail: String? = nil,
        onSuccess: ((UUID) -> Void)? = nil
    ) {
        self.report = report
        self.patient = patient
        self.therapistEmail = therapistEmail
        self.clinicAdminEmail = clinicAdminEmail
        self.onSuccess = onSuccess
        self._viewModel = StateObject(wrappedValue: EmailComposerViewModel(
            report: report,
            patient: patient,
            therapistEmail: therapistEmail,
            clinicAdminEmail: clinicAdminEmail
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Attachment preview
                    attachmentPreview

                    // Recipient section
                    recipientSection

                    // CC section
                    ccSection

                    // Subject section
                    subjectSection

                    // Message section
                    messageSection

                    // Template picker
                    templatePicker
                }
                .padding()
            }
            .navigationTitle("Email Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isSending)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    sendButton
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Email Sent", isPresented: $viewModel.showSuccess) {
                Button("Done") {
                    if let emailId = viewModel.sentEmailId {
                        onSuccess?(emailId)
                    }
                    dismiss()
                }
            } message: {
                Text("Your report has been sent to \(viewModel.recipientEmail)")
            }
            .interactiveDismissDisabled(viewModel.isSending)
        }
    }

    // MARK: - Attachment Preview

    private var attachmentPreview: some View {
        HStack(spacing: Spacing.md) {
            // PDF thumbnail
            PDFThumbnailView(data: report.pdfData)
                .frame(width: 60, height: 80)
                .cornerRadius(CornerRadius.sm)
                .shadow(color: Color(.systemGray4).opacity(0.1), radius: 2, y: 1)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(report.configuration.reportType.displayName)
                    .font(.headline)

                Text(report.fileName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: Spacing.sm) {
                    Label(report.fileSizeDisplay, systemImage: "doc")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label(formattedDate(report.generatedAt), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "paperclip")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Attachment: \(report.configuration.reportType.displayName), \(report.fileSizeDisplay)")
    }

    // MARK: - Recipient Section

    private var recipientSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("To")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            TextField("Patient email", text: $viewModel.recipientEmail)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .stroke(viewModel.recipientEmailError != nil ? Color.red : Color.clear, lineWidth: 1)
                )
                .onChange(of: viewModel.recipientEmail) { _, _ in
                    _ = viewModel.validateRecipientEmail()
                }
                .accessibilityLabel("Recipient email address")

            if let error = viewModel.recipientEmailError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .accessibilityLabel("Error: \(error)")
            }
        }
    }

    // MARK: - CC Section

    private var ccSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("CC")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button {
                    viewModel.addCCEmail()
                    HapticFeedback.light()
                } label: {
                    Label("Add", systemImage: "plus.circle")
                        .font(.subheadline)
                }
            }

            // Optional CC options
            if therapistEmail != nil || clinicAdminEmail != nil {
                VStack(spacing: Spacing.xs) {
                    if therapistEmail != nil {
                        Toggle(isOn: $viewModel.includeCCTherapist) {
                            Label("Copy yourself", systemImage: "person.fill")
                                .font(.subheadline)
                        }
                        .toggleStyle(.switch)
                        .tint(.blue)
                    }

                    if clinicAdminEmail != nil {
                        Toggle(isOn: $viewModel.includeCCClinicAdmin) {
                            Label("Copy clinic admin", systemImage: "building.2")
                                .font(.subheadline)
                        }
                        .toggleStyle(.switch)
                        .tint(.blue)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.sm)
            }

            // Custom CC emails
            ForEach(viewModel.ccEmails.indices, id: \.self) { index in
                HStack(spacing: Spacing.sm) {
                    TextField("CC email", text: Binding(
                        get: { viewModel.ccEmails[index] },
                        set: { viewModel.updateCCEmail($0, at: index) }
                    ))
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .stroke(viewModel.ccEmailErrors[index] != nil ? Color.red : Color.clear, lineWidth: 1)
                    )

                    Button {
                        viewModel.removeCCEmail(at: index)
                        HapticFeedback.light()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                    .accessibilityLabel("Remove CC email")
                }

                if let error = viewModel.ccEmailErrors[index] {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }

    // MARK: - Subject Section

    private var subjectSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Subject")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            TextField("Email subject", text: $viewModel.subject)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .stroke(viewModel.subjectError != nil ? Color.red : Color.clear, lineWidth: 1)
                )
                .onChange(of: viewModel.subject) { _, _ in
                    viewModel.validateSubject()
                }
                .accessibilityLabel("Email subject line")

            if let error = viewModel.subjectError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Message Section

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Message")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            TextEditor(text: $viewModel.messageBody)
                .frame(minHeight: 200)
                .padding(Spacing.sm)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .stroke(viewModel.bodyError != nil ? Color.red : Color.clear, lineWidth: 1)
                )
                .onChange(of: viewModel.messageBody) { _, _ in
                    viewModel.validateBody()
                }
                .accessibilityLabel("Email message body")

            if let error = viewModel.bodyError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Template Picker

    private var templatePicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Templates")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(EmailTemplate.allTemplates) { template in
                        TemplateChip(
                            template: template,
                            isSelected: viewModel.selectedTemplate?.id == template.id
                        ) {
                            viewModel.applyTemplate(template)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button {
            Task {
                await viewModel.sendEmail()
            }
        } label: {
            if viewModel.isSending {
                HStack(spacing: Spacing.xs) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)

                    Text(viewModel.sendingProgress)
                        .font(.subheadline)
                }
            } else {
                Label("Send", systemImage: "paperplane.fill")
            }
        }
        .disabled(!viewModel.isFormValid || viewModel.isSending)
        .accessibilityLabel(viewModel.isSending ? "Sending: \(viewModel.sendingProgress)" : "Send email")
        .accessibilityHint("Sends the report to the patient via email")
    }

    // MARK: - Helpers

    private static let shortDateShortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    private func formattedDate(_ date: Date) -> String {
        Self.shortDateShortTimeFormatter.string(from: date)
    }
}

// MARK: - PDF Thumbnail View

struct PDFThumbnailView: View {
    let data: Data

    var body: some View {
        if let pdfDocument = PDFDocument(data: data),
           let page = pdfDocument.page(at: 0) {
            PDFPageThumbnail(page: page)
        } else {
            // Fallback placeholder
            Rectangle()
                .fill(Color(.systemGray5))
                .overlay(
                    Image(systemName: "doc.fill")
                        .foregroundColor(.secondary)
                )
        }
    }
}

struct PDFPageThumbnail: UIViewRepresentable {
    let page: PDFPage

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor.white

        let pageRect = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let image = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)
            ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
        imageView.image = image

        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}
}

// MARK: - Template Chip

struct TemplateChip: View {
    let template: EmailTemplate
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: template.icon)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .blue)

                Text(template.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .stroke(isSelected ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .accessibilityLabel("\(template.name) template")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Quick Email Button

/// Button to quickly open email composer from report preview
struct QuickEmailButton: View {
    let report: GeneratedReport
    let patient: Patient
    var therapistEmail: String?

    @State private var showEmailComposer = false

    var body: some View {
        Button {
            HapticFeedback.medium()
            showEmailComposer = true
        } label: {
            Label("Email Report", systemImage: "envelope.fill")
        }
        .sheet(isPresented: $showEmailComposer) {
            EmailComposerSheet(
                report: report,
                patient: patient,
                therapistEmail: therapistEmail
            )
        }
    }
}

// MARK: - Preview

#if DEBUG
struct EmailComposerSheet_Previews: PreviewProvider {
    static var previews: some View {
        // Create sample data
        let sampleData = "Sample PDF content".data(using: .utf8) ?? Data()
        let config = ReportConfiguration(
            reportType: .progress,
            patientId: UUID(),
            startDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
            endDate: Date()
        )

        let sampleReport = GeneratedReport(
            id: UUID(),
            configuration: config,
            patientName: "John Brebbia",
            generatedAt: Date(),
            pdfData: sampleData,
            fileURL: nil
        )

        EmailComposerSheet(
            report: sampleReport,
            patient: Patient.samplePatients[0],
            therapistEmail: "therapist@clinic.com"
        )
    }
}
#endif
