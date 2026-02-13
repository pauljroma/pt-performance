// DARK MODE: See ModeThemeModifier.swift for central theme control
import SwiftUI
import UIKit
import UniformTypeIdentifiers

// ============================================================================
// Lab PDF Upload View
// Allows users to upload, parse, review, and save lab results from PDFs
// ============================================================================

struct LabPDFUploadView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LabPDFUploadViewModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Upload Lab Results")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .disabled(viewModel.state == .uploading)
                    }

                    if viewModel.state == .reviewing {
                        ToolbarItem(placement: .primaryAction) {
                            Button("Save") {
                                Task {
                                    await viewModel.saveResults()
                                }
                            }
                            .fontWeight(.semibold)
                            .disabled(viewModel.selectedBiomarkerCount == 0 || viewModel.isSaving)
                        }
                    }
                }
                .fileImporter(
                    isPresented: $viewModel.showingFilePicker,
                    allowedContentTypes: [UTType.pdf],
                    allowsMultipleSelection: false
                ) { result in
                    Task {
                        await viewModel.handleFileSelection(result)
                    }
                }
                .alert("Error", isPresented: $viewModel.showingError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.errorMessage)
                }
                .alert("Success", isPresented: $viewModel.showingSaveSuccess) {
                    Button("Done") {
                        dismiss()
                    }
                } message: {
                    Text("Lab results saved successfully with \(viewModel.selectedBiomarkerCount) biomarkers.")
                }
                .interactiveDismissDisabled(viewModel.state == .uploading)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .initial:
            initialStateView
        case .uploading:
            uploadingView
        case .reviewing:
            reviewingView
        case .saving:
            savingView
        }
    }

    // MARK: - Initial State

    private var initialStateView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.modusLightTeal)
                    .frame(width: 120, height: 120)

                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 48))
                    .foregroundColor(.modusCyan)
            }

            // Instructions
            VStack(spacing: 12) {
                Text("Upload Lab PDF")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.modusDeepTeal)

                Text("Select a PDF of your lab results from Quest Diagnostics, LabCorp, or another provider. We'll extract the biomarker values automatically.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // Supported providers
            HStack(spacing: 24) {
                providerBadge(name: "Quest", icon: "building.2")
                providerBadge(name: "LabCorp", icon: "building")
                providerBadge(name: "Other", icon: "doc.text")
            }

            Spacer()

            // Upload button
            Button {
                viewModel.showingFilePicker = true
            } label: {
                Label("Select PDF", systemImage: "doc.badge.plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.modusCyan)
                    .cornerRadius(CornerRadius.md)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .accessibilityLabel("Select PDF file to upload")
            .accessibilityHint("Opens file picker to select a lab results PDF")
        }
    }

    private func providerBadge(name: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.modusCyan)

            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 70)
    }

    // MARK: - Uploading State

    private var uploadingView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animated icon
            ZStack {
                Circle()
                    .stroke(Color.modusLightTeal, lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: viewModel.uploadProgress)
                    .stroke(Color.modusCyan, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.3), value: viewModel.uploadProgress)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 32))
                    .foregroundColor(.modusCyan)
            }

            VStack(spacing: 8) {
                Text("Analyzing PDF...")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                Text("Claude AI is extracting your biomarker values")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("\(Int(viewModel.uploadProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.modusCyan)
                    .monospacedDigit()
            }

            Spacer()
        }
    }

    // MARK: - Reviewing State

    private var reviewingView: some View {
        VStack(spacing: 0) {
            // Header info
            reviewHeader

            Divider()

            // Biomarker list
            biomarkerList

            Divider()

            // Test type and date picker
            testDetailsSection
        }
    }

    private var reviewHeader: some View {
        VStack(spacing: 12) {
            HStack {
                // Provider badge
                if let provider = viewModel.parsedResult?.provider {
                    HStack(spacing: 6) {
                        Image(systemName: "building.2")
                            .font(.caption)
                        Text(provider.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.modusLightTeal)
                    .foregroundColor(.modusDeepTeal)
                    .cornerRadius(CornerRadius.sm)
                }

                Spacer()

                // Confidence indicator
                if let confidence = viewModel.parsedResult?.confidence {
                    HStack(spacing: 4) {
                        Image(systemName: confidence.iconName)
                            .font(.caption)
                        Text(confidence.displayName)
                            .font(.caption)
                    }
                    .foregroundColor(confidenceColor(confidence))
                }
            }

            // Summary
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.biomarkerCount) biomarkers found")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("\(viewModel.selectedBiomarkerCount) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Select all / deselect all
                Button {
                    viewModel.toggleSelectAll()
                } label: {
                    Text(viewModel.allSelected ? "Deselect All" : "Select All")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }

    private var biomarkerList: some View {
        List {
            ForEach(viewModel.groupedBiomarkers, id: \.0) { category, biomarkers in
                Section(category) {
                    ForEach(biomarkers) { biomarker in
                        BiomarkerEditRow(
                            biomarker: binding(for: biomarker),
                            onDelete: {
                                viewModel.removeBiomarker(biomarker)
                            }
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func binding(for biomarker: ParsedBiomarker) -> Binding<ParsedBiomarker> {
        Binding(
            get: { biomarker },
            set: { viewModel.updateBiomarker($0) }
        )
    }

    private var testDetailsSection: some View {
        VStack(spacing: 16) {
            // Test type picker
            HStack {
                Text("Test Type")
                    .font(.subheadline)

                Spacer()

                Picker("Test Type", selection: $viewModel.selectedTestType) {
                    ForEach(LabTestType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .tint(.modusCyan)
            }

            // Date picker
            DatePicker(
                "Test Date",
                selection: $viewModel.testDate,
                displayedComponents: .date
            )
            .font(.subheadline)
            .tint(.modusCyan)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Saving State

    private var savingView: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)

            Text("Saving lab results...")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            Spacer()
        }
    }

    // MARK: - Helpers

    private func confidenceColor(_ confidence: ParsingConfidence) -> Color {
        switch confidence {
        case .high: return .modusTealAccent
        case .medium: return .orange
        case .low: return .red
        }
    }
}

// ============================================================================
// Biomarker Edit Row
// ============================================================================

struct BiomarkerEditRow: View {
    @Binding var biomarker: ParsedBiomarker
    let onDelete: () -> Void

    @State private var isEditing = false
    @State private var editedValue: String = ""

    private let selectionFeedback = UISelectionFeedbackGenerator()

    var body: some View {
        HStack(spacing: 12) {
            // Selection toggle
            Button {
                selectionFeedback.selectionChanged()
                withAnimation(.easeInOut(duration: 0.2)) {
                    biomarker.isSelected.toggle()
                }
            } label: {
                Image(systemName: biomarker.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(biomarker.isSelected ? .modusCyan : .secondary)
                    .scaleEffect(biomarker.isSelected ? 1.0 : 0.9)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(biomarker.isSelected ? "Selected" : "Not selected")
            .accessibilityHint("Double tap to toggle selection")

            // Biomarker info
            VStack(alignment: .leading, spacing: 4) {
                Text(biomarker.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(biomarker.isSelected ? .primary : .secondary)

                if let refRange = biomarker.referenceRange {
                    Text("Ref: \(refRange) \(biomarker.unit)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Value and flag
            HStack(spacing: 8) {
                if isEditing {
                    TextField("Value", text: $editedValue)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .onSubmit {
                            saveEditedValue()
                        }

                    Button {
                        saveEditedValue()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.modusTealAccent)
                    }
                } else {
                    Button {
                        editedValue = String(format: "%.2f", biomarker.value)
                        isEditing = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(String(format: "%.2f", biomarker.value))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .monospacedDigit()

                            Text(biomarker.unit)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(biomarker.isSelected ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Value: \(String(format: "%.2f", biomarker.value)) \(biomarker.unit)")
                    .accessibilityHint("Double tap to edit value")
                }

                // Flag indicator
                if let flag = biomarker.flag, flag != .normal {
                    Image(systemName: flag.iconName)
                        .font(.caption)
                        .foregroundColor(flagColor(flag))
                        .accessibilityLabel(flag.displayName)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(biomarker.isSelected ? 1.0 : 0.6)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func saveEditedValue() {
        if let newValue = Double(editedValue) {
            biomarker.value = newValue

            // Recalculate flag based on new value
            if let low = biomarker.referenceLow, let high = biomarker.referenceHigh {
                if newValue < low {
                    biomarker.flag = .low
                } else if newValue > high {
                    biomarker.flag = .high
                } else {
                    biomarker.flag = .normal
                }
            }
        }
        isEditing = false
    }

    private func flagColor(_ flag: BiomarkerFlag) -> Color {
        switch flag {
        case .normal: return .modusTealAccent
        case .low: return .orange
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// ============================================================================
// View Model
// ============================================================================

@MainActor
final class LabPDFUploadViewModel: ObservableObject {
    enum UploadState {
        case initial
        case uploading
        case reviewing
        case saving
    }

    @Published var state: UploadState = .initial
    @Published var showingFilePicker = false
    @Published var showingError = false
    @Published var showingSaveSuccess = false
    @Published var errorMessage = ""
    @Published var uploadProgress: Double = 0

    @Published var parsedResult: ParsedLabResult?
    @Published var selectedTestType: LabTestType = .bloodPanel
    @Published var testDate: Date = Date()
    @Published var isSaving = false

    private let labResultService = LabResultService.shared
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    // MARK: - Computed Properties

    var biomarkerCount: Int {
        parsedResult?.biomarkers.count ?? 0
    }

    var selectedBiomarkerCount: Int {
        parsedResult?.biomarkers.filter { $0.isSelected }.count ?? 0
    }

    var allSelected: Bool {
        parsedResult?.biomarkers.allSatisfy { $0.isSelected } ?? false
    }

    var groupedBiomarkers: [(String, [ParsedBiomarker])] {
        guard let biomarkers = parsedResult?.biomarkers else { return [] }

        let grouped = Dictionary(grouping: biomarkers) { $0.category ?? "Other" }
        return grouped.sorted { $0.key < $1.key }
    }

    // MARK: - Actions

    func handleFileSelection(_ result: Result<[URL], Error>) async {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                showError("Unable to access the selected file.")
                return
            }

            defer {
                url.stopAccessingSecurityScopedResource()
            }

            do {
                let pdfData = try Data(contentsOf: url)
                await uploadPDF(pdfData)
            } catch {
                showError("Failed to read PDF file: \(error.localizedDescription)")
            }

        case .failure(let error):
            showError("File selection failed: \(error.localizedDescription)")
        }
    }

    func uploadPDF(_ pdfData: Data) async {
        state = .uploading
        uploadProgress = 0
        hapticFeedback.prepare()

        // Track upload progress using weak self to prevent retain cycles
        let progressTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                guard let self = self else { return }
                await MainActor.run {
                    self.uploadProgress = self.labResultService.uploadProgress
                }
            }
        }

        do {
            DebugLogger.shared.info("LabPDFUpload", "Calling uploadLabPDF...")
            let result = try await labResultService.uploadLabPDF(pdfData)
            progressTask.cancel()

            DebugLogger.shared.info("LabPDFUpload", "Upload returned with \(result.biomarkers.count) biomarkers")
            DebugLogger.shared.info("LabPDFUpload", "Provider: \(result.provider.displayName)")
            DebugLogger.shared.info("LabPDFUpload", "Confidence: \(result.confidence.displayName)")

            parsedResult = result
            testDate = result.testDate ?? Date()

            // Auto-detect test type based on biomarkers
            selectedTestType = detectTestType(from: result.biomarkers)

            DebugLogger.shared.info("LabPDFUpload", "Transitioning to reviewing state...")
            state = .reviewing
            DebugLogger.shared.info("LabPDFUpload", "State is now: \(state)")

            // Success haptic feedback
            notificationFeedback.notificationOccurred(.success)

        } catch {
            progressTask.cancel()
            DebugLogger.shared.error("LabPDFUpload", "Upload failed: \(error.localizedDescription)")
            state = .initial
            showError(error.localizedDescription)

            // Error haptic feedback
            notificationFeedback.notificationOccurred(.error)
        }
    }

    func saveResults() async {
        guard let parsedResult = parsedResult else { return }

        state = .saving
        isSaving = true
        notificationFeedback.prepare()

        do {
            _ = try await labResultService.saveParsedLabResult(
                parsedResult,
                testType: selectedTestType,
                testDate: testDate
            )

            isSaving = false
            showingSaveSuccess = true

            // Success haptic feedback
            notificationFeedback.notificationOccurred(.success)

        } catch {
            isSaving = false
            state = .reviewing
            showError(error.localizedDescription)

            // Error haptic feedback
            notificationFeedback.notificationOccurred(.error)
        }
    }

    func toggleSelectAll() {
        guard var result = parsedResult else { return }

        let newValue = !allSelected
        result.biomarkers = result.biomarkers.map { biomarker in
            var updated = biomarker
            updated.isSelected = newValue
            return updated
        }
        parsedResult = result

        // Selection haptic feedback
        hapticFeedback.impactOccurred()
    }

    func updateBiomarker(_ biomarker: ParsedBiomarker) {
        guard var result = parsedResult else { return }

        if let index = result.biomarkers.firstIndex(where: { $0.id == biomarker.id }) {
            result.biomarkers[index] = biomarker
            parsedResult = result
        }
    }

    func removeBiomarker(_ biomarker: ParsedBiomarker) {
        guard var result = parsedResult else { return }

        result.biomarkers.removeAll { $0.id == biomarker.id }
        parsedResult = result
    }

    // MARK: - Helpers

    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }

    private func detectTestType(from biomarkers: [ParsedBiomarker]) -> LabTestType {
        let categories = Set(biomarkers.compactMap { $0.category?.lowercased() })
        let names = Set(biomarkers.map { $0.name.lowercased() })

        // Check for specific panel types
        if categories.contains("lipid") || names.contains { $0.contains("cholesterol") || $0.contains("triglyceride") } {
            return .lipidPanel
        }

        if categories.contains("thyroid") || names.contains { $0.contains("tsh") || $0.contains("t3") || $0.contains("t4") } {
            return .thyroid
        }

        if categories.contains("hormone") || names.contains { $0.contains("testosterone") || $0.contains("estradiol") } {
            return .hormonePanel
        }

        if names.contains { $0.contains("vitamin d") } {
            return .vitaminD
        }

        if names.contains { $0.contains("iron") || $0.contains("ferritin") } {
            return .iron
        }

        if categories.contains("cbc") || names.contains { $0.contains("wbc") || $0.contains("rbc") || $0.contains("hemoglobin") } {
            return .cbc
        }

        if categories.contains("metabolic") || names.contains { $0.contains("glucose") || $0.contains("creatinine") } {
            return .metabolicPanel
        }

        return .bloodPanel
    }
}

// MARK: - Preview

#Preview {
    LabPDFUploadView()
}
