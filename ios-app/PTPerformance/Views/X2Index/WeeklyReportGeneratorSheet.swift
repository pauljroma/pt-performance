//
//  WeeklyReportGeneratorSheet.swift
//  PTPerformance
//
//  Phase 3 Integration - Weekly Report Generator
//  Generates weekly progress reports for therapist caseload
//

import SwiftUI

// MARK: - Weekly Report Generator Sheet

struct WeeklyReportGeneratorSheet: View {

    // MARK: - State

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = WeeklyReportGeneratorViewModel()
    @State private var selectedPatients: Set<UUID> = []
    @State private var dateRange: ReportDateRange = .lastWeek
    @State private var includeCharts = true
    @State private var includeRecommendations = true
    @State private var exportFormat: ExportFormat = .pdf
    @State private var isGenerating = false
    @State private var generationProgress: Double = 0
    @State private var generationComplete = false
    @State private var showPatientPicker = false
    @State private var generationTimer: Timer?

    // MARK: - Enums

    enum ReportDateRange: String, CaseIterable {
        case lastWeek = "Last 7 Days"
        case last2Weeks = "Last 14 Days"
        case lastMonth = "Last 30 Days"
        case custom = "Custom Range"

        var days: Int {
            switch self {
            case .lastWeek: return 7
            case .last2Weeks: return 14
            case .lastMonth: return 30
            case .custom: return 7
            }
        }
    }

    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case html = "HTML"
        case email = "Email"

        var icon: String {
            switch self {
            case .pdf: return "doc.fill"
            case .html: return "globe"
            case .email: return "envelope.fill"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if generationComplete {
                    completionView
                } else if isGenerating {
                    generatingView
                } else {
                    configurationView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Generate Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isGenerating)
                }
            }
            .onDisappear {
                generationTimer?.invalidate()
                generationTimer = nil
            }
        }
    }

    // MARK: - Configuration View

    private var configurationView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Date range selection
                dateRangeSection

                // Patient selection
                patientSelectionSection

                // Report options
                reportOptionsSection

                // Export format
                exportFormatSection

                // Generate button
                generateButton
            }
            .padding()
        }
    }

    // MARK: - Date Range Section

    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date Range")
                .font(.headline)
                .foregroundColor(.primary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(ReportDateRange.allCases, id: \.self) { range in
                    dateRangeButton(range)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private func dateRangeButton(_ range: ReportDateRange) -> some View {
        let isSelected = dateRange == range

        return Button {
            withAnimation(.spring(response: 0.3)) {
                HapticService.selection()
                dateRange = range
            }
        } label: {
            VStack(spacing: 4) {
                Text(range.rawValue)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(isSelected ? .white : .primary)

                if range != .custom {
                    Text("\(range.days) days")
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? Color.modusCyan : Color(.tertiarySystemFill))
            .cornerRadius(CornerRadius.sm)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Patient Selection Section

    private var patientSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Patients")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Button {
                    showPatientPicker = true
                } label: {
                    Label("Select", systemImage: "person.crop.circle.badge.plus")
                        .font(.subheadline)
                }
            }

            if selectedPatients.isEmpty {
                Text("All patients will be included")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, Spacing.xs)
            } else {
                Text("\(selectedPatients.count) patients selected")
                    .font(.subheadline)
                    .foregroundColor(.modusCyan)
                    .padding(.vertical, Spacing.xs)
            }

            Button {
                withAnimation {
                    selectedPatients.removeAll()
                }
            } label: {
                Text("Include All Patients")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Report Options Section

    private var reportOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Include in Report")
                .font(.headline)
                .foregroundColor(.primary)

            Toggle(isOn: $includeCharts) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.modusCyan)
                    Text("Progress Charts")
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .modusCyan))

            Toggle(isOn: $includeRecommendations) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("AI Recommendations")
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .modusCyan))
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Export Format Section

    private var exportFormatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Format")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 12) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    exportFormatButton(format)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private func exportFormatButton(_ format: ExportFormat) -> some View {
        let isSelected = exportFormat == format

        return Button {
            withAnimation(.spring(response: 0.3)) {
                HapticService.selection()
                exportFormat = format
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: format.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .modusCyan)

                Text(format.rawValue)
                    .font(.caption.weight(.medium))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(isSelected ? Color.modusCyan : Color(.tertiarySystemFill))
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            generateReport()
        } label: {
            HStack {
                Image(systemName: "doc.badge.gearshape.fill")
                Text("Generate Report")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.modusCyan)
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Generating View

    private var generatingView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated document icon
            ZStack {
                Circle()
                    .fill(Color.modusCyan.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "doc.text.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.modusCyan)
                    .scaleEffect(generationProgress < 1 ? 1.0 + (0.1 * sin(generationProgress * .pi * 4)) : 1.0)
                    .animation(.linear(duration: 0.25), value: generationProgress)
            }

            VStack(spacing: 8) {
                Text("Generating Report...")
                    .font(.title2.weight(.bold))

                Text("Analyzing \(dateRange.days) days of data")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Progress bar
            VStack(spacing: 8) {
                ProgressView(value: generationProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .modusCyan))
                    .scaleEffect(y: 2)

                Text("\(Int(generationProgress * 100))%")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .padding()
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
            }

            VStack(spacing: 8) {
                Text("Report Ready!")
                    .font(.title2.weight(.bold))

                Text("Your weekly progress report has been generated")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Action buttons
            VStack(spacing: 12) {
                Button {
                    HapticService.light()
                    // Share action
                } label: {
                    Label("Share Report", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.modusCyan)
                        .foregroundColor(.white)
                        .cornerRadius(CornerRadius.md)
                }

                Button {
                    HapticService.light()
                    // View action
                } label: {
                    Label("View Report", systemImage: "eye")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .foregroundColor(.modusCyan)
                        .cornerRadius(CornerRadius.md)
                }

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    // MARK: - Actions

    private func generateReport() {
        isGenerating = true
        generationProgress = 0
        HapticService.medium()

        // Simulate report generation
        generationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            withAnimation(.linear(duration: 0.1)) {
                generationProgress += 0.05
            }

            if generationProgress >= 1.0 {
                timer.invalidate()
                generationTimer = nil
                HapticService.success()

                withAnimation(.spring(response: 0.4)) {
                    generationComplete = true
                }

                // Post notification
                NotificationCenter.default.post(name: .reportGenerated, object: nil)
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class WeeklyReportGeneratorViewModel: ObservableObject {
    @Published var patients: [Patient] = []
    @Published var isLoading = false

    func loadPatients(therapistId: String) async {
        // Load patients for selection
    }
}

// MARK: - Preview

#if DEBUG
struct WeeklyReportGeneratorSheet_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyReportGeneratorSheet()
    }
}
#endif
