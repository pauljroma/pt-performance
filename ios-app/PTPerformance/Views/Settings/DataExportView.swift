//
//  DataExportView.swift
//  PTPerformance
//
//  ACP-1047: Data Export (GDPR/CCPA)
//  Full data export view with category selection, format choice,
//  progress indicator, share sheet, and GDPR/CCPA rights explanation.
//

import SwiftUI

// MARK: - Data Export View

/// View for exporting all user data in GDPR/CCPA-compliant format.
///
/// Allows users to select which data categories to include,
/// choose between JSON and CSV formats, monitor export progress,
/// and share the resulting file via the system share sheet.
struct DataExportView: View {

    // MARK: - State

    @StateObject private var viewModel = DataExportViewModel()
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        List {
            // Rights explanation
            gdprInfoSection

            // Data categories
            dataCategoriesSection

            // Export format
            formatSelectionSection

            // Export history
            if viewModel.lastExportDate != nil {
                exportHistorySection
            }

            // Export button
            exportActionSection
        }
        .navigationTitle("Export My Data")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Export Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let url = viewModel.exportedFileURL {
                DataExportShareSheet(activityItems: [url])
            }
        }
        .overlay {
            if viewModel.isExporting {
                exportProgressOverlay
            }
        }
    }

    // MARK: - GDPR Info Section

    private var gdprInfoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.modusCyan)
                        .font(.title2)
                        .accessibilityHidden(true)
                    Text("Your Data Rights")
                        .font(.headline)
                }

                Text("Under GDPR and CCPA, you have the right to receive a copy of all personal data we hold about you in a portable, machine-readable format.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("This export includes all data stored in your Korza account. The file can be opened with any text editor or data analysis tool.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, Spacing.xs)
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: - Data Categories Section

    private var dataCategoriesSection: some View {
        Section {
            ForEach(DataExportService.DataCategory.allCases) { category in
                Toggle(isOn: viewModel.binding(for: category)) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: category.icon)
                            .foregroundColor(.modusCyan)
                            .frame(width: 28)
                            .accessibilityHidden(true)

                        Text(category.rawValue)
                    }
                }
                .tint(.modusCyan)
                .disabled(viewModel.isExporting)
                .accessibilityLabel(category.rawValue)
                .accessibilityValue(viewModel.selectedCategories.contains(category) ? "Included" : "Not included")
            }
        } header: {
            HStack {
                Image(systemName: "checklist")
                    .foregroundColor(.modusCyan)
                Text("Data to Include")
            }
            .accessibilityAddTraits(.isHeader)
        } footer: {
            HStack {
                Button {
                    viewModel.selectAll()
                } label: {
                    Text("Select All")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }

                Text(" | ")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    viewModel.deselectAll()
                } label: {
                    Text("Deselect All")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }
            }
        }
    }

    // MARK: - Format Selection Section

    private var formatSelectionSection: some View {
        Section {
            Picker("Export Format", selection: $viewModel.selectedFormat) {
                ForEach(DataExportService.ExportFormat.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.isExporting)
            .accessibilityLabel("Export format")

            VStack(alignment: .leading, spacing: Spacing.xs) {
                switch viewModel.selectedFormat {
                case .json:
                    Label {
                        Text("JSON is the recommended format for complete data portability. It preserves all data structure and relationships.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.modusCyan)
                    }
                case .csv:
                    Label {
                        Text("CSV can be opened in spreadsheet applications like Excel or Google Sheets. Complex data structures are flattened.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "tablecells.fill")
                            .foregroundColor(.modusCyan)
                    }
                }
            }
            .accessibilityElement(children: .combine)
        } header: {
            HStack {
                Image(systemName: "doc.badge.gearshape.fill")
                    .foregroundColor(.modusCyan)
                Text("Format")
            }
            .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: - Export History Section

    private var exportHistorySection: some View {
        Section {
            if let lastDate = viewModel.lastExportDate {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Last Export")
                            .font(.subheadline)
                        Text(lastDate, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        + Text(" ago")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Last export was \(lastDate, style: .relative) ago")
            }
        } header: {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.modusCyan)
                Text("Export History")
            }
            .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: - Export Action Section

    private var exportActionSection: some View {
        Section {
            Button {
                HapticFeedback.medium()
                Task {
                    await viewModel.startExport()
                }
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "square.and.arrow.up.fill")
                    Text("Export My Data")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.vertical, Spacing.sm)
                .foregroundStyle(.white)
                .background(
                    viewModel.canExport
                    ? Color.modusCyan
                    : Color.gray.opacity(0.5)
                )
                .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canExport || viewModel.isExporting)
            .accessibilityLabel("Export my data")
            .accessibilityHint(viewModel.canExport
                ? "Starts exporting selected data categories"
                : "Select at least one data category to export")
        } footer: {
            Text("Your data will be packaged into a single file that you can save or share. No data is sent to third parties during this process.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Progress Overlay

    private var exportProgressOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                ProgressView(value: viewModel.exportProgress) {
                    Text("Exporting Data...")
                        .font(.headline)
                } currentValueLabel: {
                    Text("\(Int(viewModel.exportProgress * 100))%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .progressViewStyle(LinearProgressViewStyle(tint: .modusCyan))
                .padding(.horizontal, Spacing.xl)

                Text(viewModel.exportStatusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 10)
            )
            .padding(.horizontal, Spacing.xl)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Exporting data, \(Int(viewModel.exportProgress * 100)) percent complete")
    }
}

// MARK: - Data Export View Model

@MainActor
final class DataExportViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var selectedCategories: Set<DataExportService.DataCategory> = Set(DataExportService.DataCategory.allCases)
    @Published var selectedFormat: DataExportService.ExportFormat = .json
    @Published var isExporting = false
    @Published var exportProgress: Double = 0
    @Published var exportStatusMessage = "Preparing..."
    @Published var exportedFileURL: URL?
    @Published var showShareSheet = false
    @Published var showError = false
    @Published var errorMessage = ""

    // MARK: - Computed Properties

    var canExport: Bool {
        !selectedCategories.isEmpty && !isExporting
    }

    var lastExportDate: Date? {
        DataExportService.shared.lastExportDate
    }

    // MARK: - Category Binding

    func binding(for category: DataExportService.DataCategory) -> Binding<Bool> {
        Binding(
            get: { self.selectedCategories.contains(category) },
            set: { isSelected in
                if isSelected {
                    self.selectedCategories.insert(category)
                } else {
                    self.selectedCategories.remove(category)
                }
            }
        )
    }

    // MARK: - Selection Helpers

    func selectAll() {
        selectedCategories = Set(DataExportService.DataCategory.allCases)
    }

    func deselectAll() {
        selectedCategories.removeAll()
    }

    // MARK: - Export

    func startExport() async {
        isExporting = true
        exportProgress = 0
        exportStatusMessage = "Preparing export..."

        do {
            let url = try await DataExportService.shared.exportAllData(
                format: selectedFormat,
                categories: selectedCategories
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.exportProgress = progress
                    self?.updateStatusMessage(for: progress)
                }
            }

            exportedFileURL = url
            exportProgress = 1.0
            exportStatusMessage = "Export complete!"
            HapticFeedback.success()

            // Short delay to show completion state, then show share sheet
            try? await Task.sleep(nanoseconds: 500_000_000)
            isExporting = false
            showShareSheet = true

        } catch {
            isExporting = false
            errorMessage = error.localizedDescription
            showError = true
            HapticFeedback.error()
            DebugLogger.shared.error("DataExportView", "Export failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Status Message

    private func updateStatusMessage(for progress: Double) {
        switch progress {
        case 0..<0.1:
            exportStatusMessage = "Connecting to server..."
        case 0.1..<0.3:
            exportStatusMessage = "Fetching profile and sessions..."
        case 0.3..<0.5:
            exportStatusMessage = "Fetching exercise and nutrition data..."
        case 0.5..<0.7:
            exportStatusMessage = "Fetching check-ins and conversations..."
        case 0.7..<0.9:
            exportStatusMessage = "Fetching achievements..."
        case 0.9..<1.0:
            exportStatusMessage = "Creating export file..."
        default:
            exportStatusMessage = "Export complete!"
        }
    }
}

// MARK: - Share Sheet (UIKit Bridge)

/// UIKit wrapper for UIActivityViewController to present the system share sheet.
private struct DataExportShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DataExportView()
    }
}
