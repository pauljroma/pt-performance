//
//  ReportPreviewView.swift
//  PTPerformance
//
//  Preview and share interface for generated PDF reports
//  Supports viewing, printing, emailing, and saving reports
//

import SwiftUI
import PDFKit

// MARK: - Report Preview View

struct ReportPreviewView: View {
    let report: GeneratedReport
    var patient: Patient?
    var therapistEmail: String?

    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var showEmailComposer = false
    @State private var showPrintOptions = false
    @State private var showSaveAlert = false
    @State private var saveError: String?
    @State private var showEmailSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Report info header
                reportInfoHeader

                // PDF preview
                PDFPreviewView(data: report.pdfData)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Action buttons
                actionButtonsBar
            }
            .navigationTitle("Report Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        shareMenuContent
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = report.fileURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showEmailComposer) {
                if let patient = patient {
                    EmailComposerSheet(
                        report: report,
                        patient: patient,
                        therapistEmail: therapistEmail,
                        onSuccess: { _ in
                            showEmailSuccess = true
                        }
                    )
                }
            }
            .alert("Report Saved", isPresented: $showSaveAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = saveError {
                    Text("Failed to save: \(error)")
                } else {
                    Text("The report has been saved to your Files.")
                }
            }
            .alert("Email Sent", isPresented: $showEmailSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The report has been emailed successfully.")
            }
        }
    }

    // MARK: - Report Info Header

    private var reportInfoHeader: some View {
        HStack(spacing: Spacing.md) {
            // Report type icon
            Image(systemName: report.configuration.reportType.icon)
                .font(.title2)
                .foregroundColor(report.configuration.reportType.color)
                .frame(width: 44, height: 44)
                .background(report.configuration.reportType.color.opacity(0.15))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(report.configuration.reportType.displayName)
                    .font(.headline)

                Text(report.patientName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: Spacing.sm) {
                    Label(formattedDate(report.generatedAt), systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label(report.fileSizeDisplay, systemImage: "doc")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(report.configuration.reportType.displayName) for \(report.patientName), generated \(formattedDate(report.generatedAt))")
    }

    // MARK: - Action Buttons Bar

    private var actionButtonsBar: some View {
        HStack(spacing: Spacing.md) {
            // Share button
            ActionIconButton(
                icon: "square.and.arrow.up",
                title: "Share",
                color: .blue
            ) {
                HapticFeedback.medium()
                showShareSheet = true
            }

            // Email button
            ActionIconButton(
                icon: "envelope.fill",
                title: "Email",
                color: .green
            ) {
                HapticFeedback.medium()
                if patient != nil {
                    showEmailComposer = true
                } else {
                    shareViaEmail()
                }
            }

            // Print button
            ActionIconButton(
                icon: "printer",
                title: "Print",
                color: .purple
            ) {
                HapticFeedback.medium()
                printReport()
            }

            // Save button
            ActionIconButton(
                icon: "square.and.arrow.down",
                title: "Save",
                color: .orange
            ) {
                HapticFeedback.medium()
                saveToFiles()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 4, y: -2)
    }

    // MARK: - Share Menu Content

    @ViewBuilder
    private var shareMenuContent: some View {
        Button {
            showShareSheet = true
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }

        Button {
            if patient != nil {
                showEmailComposer = true
            } else {
                shareViaEmail()
            }
        } label: {
            Label("Email Report", systemImage: "envelope.fill")
        }

        Button {
            printReport()
        } label: {
            Label("Print", systemImage: "printer")
        }

        Divider()

        Button {
            saveToFiles()
        } label: {
            Label("Save to Files", systemImage: "folder")
        }

        Button {
            copyToClipboard()
        } label: {
            Label("Copy to Clipboard", systemImage: "doc.on.clipboard")
        }
    }

    // MARK: - Actions

    private func shareViaEmail() {
        guard let url = report.fileURL else { return }
        showShareSheet = true
    }

    private func printReport() {
        guard let url = report.fileURL else { return }

        let printController = UIPrintInteractionController.shared

        printController.printingItem = url

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = report.fileName
        printInfo.outputType = .general
        printController.printInfo = printInfo

        printController.present(animated: true) { _, completed, error in
            if let error = error {
                #if DEBUG
                print("[ReportPreviewView] Print error: \(error.localizedDescription)")
                #endif
            }
        }
    }

    private func saveToFiles() {
        guard let url = report.fileURL else {
            saveError = "Report file not available"
            showSaveAlert = true
            return
        }

        // Create a document picker to save the file
        let documentPicker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
        documentPicker.shouldShowFileExtensions = true

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let viewController = windowScene.windows.first?.rootViewController {
            viewController.present(documentPicker, animated: true)
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.setData(report.pdfData, forPasteboardType: "com.adobe.pdf")
        HapticFeedback.success()
    }

    // MARK: - Helpers

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - PDF Preview View

struct PDFPreviewView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.systemGroupedBackground

        if let document = PDFDocument(data: data) {
            pdfView.document = document
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = PDFDocument(data: data) {
            uiView.document = document
        }
    }
}

// MARK: - Action Icon Button

struct ActionIconButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(color.opacity(0.1))
            .cornerRadius(CornerRadius.sm)
        }
        .accessibilityLabel(title)
        .accessibilityHint("\(title) this report")
    }
}

// MARK: - Quick Report Button (for PatientDetailView)

struct QuickReportButton: View {
    let patient: Patient

    @State private var showReportBuilder = false
    @State private var showQuickReportMenu = false

    var body: some View {
        Menu {
            Button {
                showReportBuilder = true
            } label: {
                Label("Custom Report", systemImage: "doc.badge.plus")
            }

            Divider()

            ForEach(ReportPreset.allPresets.prefix(3)) { preset in
                Button {
                    generateQuickReport(preset: preset)
                } label: {
                    Label(preset.name, systemImage: preset.icon)
                }
            }
        } label: {
            Label("Generate Report", systemImage: "doc.text.fill")
        }
        .sheet(isPresented: $showReportBuilder) {
            ReportBuilderView(patient: patient)
        }
    }

    private func generateQuickReport(preset: ReportPreset) {
        Task {
            do {
                let report = try await ReportGenerationService.shared.generateQuickReport(
                    preset: preset,
                    patient: patient
                )

                // Show preview
                await MainActor.run {
                    showQuickReportMenu = true
                }
            } catch {
                // Error handled by service
            }
        }
    }
}

// MARK: - Report Generation Progress View

struct ReportGenerationProgressView: View {
    @ObservedObject var reportService: ReportGenerationService

    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView(value: reportService.generationProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(.blue)

            HStack {
                if reportService.isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                }

                Text(reportService.currentStep)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(reportService.generationProgress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Report generation progress: \(Int(reportService.generationProgress * 100)) percent, \(reportService.currentStep)")
    }
}

// MARK: - Recent Reports List

struct RecentReportsListView: View {
    let patient: Patient
    var therapistEmail: String?

    @State private var recentReports: [GeneratedReport] = []
    @State private var selectedReport: GeneratedReport?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Recent Reports")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            if recentReports.isEmpty {
                EmptyReportsView()
            } else {
                ForEach(recentReports) { report in
                    RecentReportRow(report: report) {
                        selectedReport = report
                    }
                }
            }
        }
        .sheet(item: $selectedReport) { report in
            ReportPreviewView(
                report: report,
                patient: patient,
                therapistEmail: therapistEmail
            )
        }
    }
}

struct RecentReportRow: View {
    let report: GeneratedReport
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: report.configuration.reportType.icon)
                    .font(.title3)
                    .foregroundColor(report.configuration.reportType.color)
                    .frame(width: 32, height: 32)
                    .background(report.configuration.reportType.color.opacity(0.15))
                    .cornerRadius(6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(report.configuration.reportType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(formattedDate(report.generatedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(report.fileSizeDisplay)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.sm)
        }
        .accessibilityLabel("\(report.configuration.reportType.displayName), generated \(formattedDate(report.generatedAt))")
        .accessibilityHint("Tap to preview report")
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct EmptyReportsView: View {
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "doc.text")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No Recent Reports")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Generate a report to see it here")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// Note: ShareSheet is already defined in PatientProgressReportView.swift and is reused here

// MARK: - Preview

#if DEBUG
struct ReportPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        // Create sample report data
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

        ReportPreviewView(
            report: sampleReport,
            patient: Patient.samplePatients[0],
            therapistEmail: "therapist@clinic.com"
        )
    }
}
#endif
