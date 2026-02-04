import SwiftUI
import Charts

struct LabResultsView: View {
    @StateObject private var viewModel = LabResultsViewModel()
    @State private var showingPDFUpload = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading lab results...")
                } else if viewModel.labResults.isEmpty {
                    emptyState
                } else {
                    resultsList
                }
            }
            .navigationTitle("Lab Results")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingPDFUpload = true
                        } label: {
                            Label("Upload Lab PDF", systemImage: "doc.viewfinder")
                        }

                        Button {
                            viewModel.showingAddSheet = true
                        } label: {
                            Label("Enter Manually", systemImage: "pencil.line")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.modusCyan)
                    }
                    .accessibilityLabel("Add lab result")
                    .accessibilityHint("Opens options to upload PDF or enter manually")
                }
            }
            .sheet(isPresented: $showingPDFUpload) {
                LabPDFUploadView()
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                AddLabResultView(viewModel: viewModel, showingPDFUpload: $showingPDFUpload)
            }
            .sheet(isPresented: $viewModel.showingDetailSheet) {
                if let result = viewModel.selectedResult {
                    LabResultDetailView(result: result, viewModel: viewModel)
                }
            }
            .task {
                await viewModel.loadResults()
            }
            .refreshable {
                await viewModel.loadResults()
            }
            .onChange(of: showingPDFUpload) { _, isShowing in
                if !isShowing {
                    Task {
                        await viewModel.loadResults()
                    }
                }
            }
        }
        .tint(.modusCyan)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Lab Results", systemImage: "cross.case")
                .foregroundColor(.modusDeepTeal)
        } description: {
            Text("Upload your blood work and lab results to track your health markers over time.")
        } actions: {
            VStack(spacing: Spacing.sm) {
                Button {
                    showingPDFUpload = true
                } label: {
                    Label("Upload Lab PDF", systemImage: "doc.viewfinder")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    viewModel.showingAddSheet = true
                } label: {
                    Label("Enter Manually", systemImage: "pencil.line")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var resultsList: some View {
        List {
            ForEach(viewModel.groupedResults, id: \.0) { testType, results in
                Section(testType.displayName) {
                    ForEach(results) { result in
                        LabResultRow(result: result)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectResult(result)
                            }
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                await viewModel.deleteResult(results[index])
                            }
                        }
                    }
                }
            }
        }
    }
}

struct LabResultRow: View {
    let result: LabResult

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.testType.displayName)
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)
                Text(result.testDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status indicator
            if let abnormalCount = abnormalMarkers {
                if abnormalCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.caption)
                        Text("\(abnormalCount) flagged")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.caption)
                        Text("Normal")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.modusTealAccent.opacity(0.2))
                    .foregroundColor(.modusTealAccent)
                    .cornerRadius(8)
                }
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.modusCyan)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(result.testType.displayName), \(result.testDate.formatted(date: .abbreviated, time: .omitted)), \(statusAccessibilityLabel)")
        .accessibilityHint("Tap to view lab result details and get AI analysis")
    }

    private var abnormalMarkers: Int? {
        let abnormal = result.results.filter { $0.status != .normal }
        return abnormal.count
    }

    private var statusAccessibilityLabel: String {
        if let abnormalCount = abnormalMarkers {
            return abnormalCount > 0 ? "\(abnormalCount) markers flagged" : "all markers normal"
        }
        return ""
    }
}

struct LabResultDetailView: View {
    let result: LabResult
    @ObservedObject var viewModel: LabResultsViewModel
    @State private var selectedBiomarkerType: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection

                    // Markers
                    markersSection

                    // Biomarker Trend Chart (when a marker is selected)
                    if selectedBiomarkerType != nil {
                        trendChartSection
                    }

                    // AI Analysis Section
                    aiAnalysisSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Lab Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        viewModel.clearAnalysis()
                        dismiss()
                    }
                }
            }
        }
        .tint(.modusCyan)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.testType.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.modusDeepTeal)
                    Text(result.testDate.formatted(date: .long, time: .omitted))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Health Score Badge (if analysis is available)
                if let analysis = viewModel.labAnalysis {
                    healthScoreBadge(score: analysis.overallHealthScore)
                }
            }
        }
        .padding(.horizontal)
    }

    private func healthScoreBadge(score: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(score)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(healthScoreColor(score))
            Text("Health Score")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(Spacing.sm)
        .background(healthScoreColor(score).opacity(0.15))
        .cornerRadius(CornerRadius.md)
    }

    private func healthScoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .modusTealAccent
        case 60..<80: return .orange
        default: return .red
        }
    }

    // MARK: - Markers Section

    private var markersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Results")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)
                .padding(.horizontal)

            ForEach(result.results) { marker in
                MarkerRow(marker: marker)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            // Toggle selection or select new
                            if selectedBiomarkerType == marker.name {
                                selectedBiomarkerType = nil
                            } else {
                                selectedBiomarkerType = marker.name
                                Task {
                                    await viewModel.fetchBiomarkerTrends(for: marker.name)
                                }
                            }
                        }
                    }
                    .background(selectedBiomarkerType == marker.name ? Color.modusCyan.opacity(0.1) : Color.clear)
            }
        }
    }

    // MARK: - Trend Chart Section

    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.isLoadingTrends {
                HStack {
                    ProgressView()
                    Text("Loading trend data...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                BiomarkerTrendChartView(
                    dataPoints: viewModel.biomarkerTrendData,
                    biomarkerName: selectedBiomarkerType ?? "Biomarker"
                )
            }
        }
        .padding(.horizontal)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - AI Analysis Section

    private var aiAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let analysis = viewModel.labAnalysis {
                // Full AI Analysis Display
                analysisResultsView(analysis)
            } else if let error = viewModel.analysisError {
                // Error State
                analysisErrorView(error)
            } else {
                // Analyze Button
                analyzeButton
            }
        }
        .padding(.horizontal)
    }

    private var analyzeButton: some View {
        Button {
            Task {
                do {
                    _ = try await viewModel.fetchAIAnalysis(for: result)
                } catch {
                    // Error is handled by viewModel
                }
            }
        } label: {
            HStack(spacing: 12) {
                if viewModel.isAnalyzing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "brain.head.profile")
                }
                Text(viewModel.isAnalyzing ? "Analyzing..." : "Analyze with AI")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.modusCyan, .modusTealAccent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.md)
        }
        .disabled(viewModel.isAnalyzing)
        .accessibilityLabel(viewModel.isAnalyzing ? "Analyzing lab results" : "Analyze with AI")
        .accessibilityHint("Uses AI to analyze your lab result markers and provide personalized insights")
    }

    private func analysisErrorView(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundColor(.orange)

            Text("Analysis Error")
                .font(.headline)

            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    do {
                        _ = try await viewModel.fetchAIAnalysis(for: result)
                    } catch {
                        // Error handled by viewModel
                    }
                }
            }
            .buttonStyle(.bordered)
            .tint(.modusCyan)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    private func analysisResultsView(_ analysis: LabAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Analysis Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.modusCyan)
                Text("AI Analysis")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                Spacer()

                if analysis.cached {
                    Text("Cached")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
            }

            // Main Analysis Text
            Text(analysis.analysisText)
                .font(.body)
                .foregroundColor(.primary)
                .padding()
                .background(Color.modusLightTeal)
                .cornerRadius(CornerRadius.md)

            // Concerning Biomarkers
            if !analysis.concerningBiomarkers.isEmpty {
                concerningBiomarkersSection(analysis.concerningBiomarkers)
            }

            // Recommendations
            if !analysis.recommendations.isEmpty {
                recommendationsSection(analysis.recommendations)
            }

            // Priority Actions
            if !analysis.priorityActions.isEmpty {
                priorityActionsSection(analysis.priorityActions)
            }

            // Training Correlations
            if !analysis.trainingCorrelations.isEmpty {
                correlationsSection(
                    title: "Training Correlations",
                    icon: "figure.run",
                    correlations: analysis.trainingCorrelations
                )
            }

            // Sleep Correlations
            if !analysis.sleepCorrelations.isEmpty {
                correlationsSection(
                    title: "Sleep Correlations",
                    icon: "bed.double",
                    correlations: analysis.sleepCorrelations
                )
            }

            // Medical Disclaimer
            disclaimerSection(analysis.medicalDisclaimer)
        }
    }

    private func concerningBiomarkersSection(_ biomarkers: [BiomarkerAnalysis]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "exclamationmark.circle")
                    .foregroundColor(.orange)
                Text("Markers Needing Attention")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            ForEach(biomarkers) { biomarker in
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: biomarker.status.iconName)
                        .foregroundColor(biomarker.status.statusColor)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(biomarker.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(String(format: "%.1f", biomarker.value)) \(biomarker.unit)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text(biomarker.interpretation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(biomarker.status.statusColor.opacity(0.1))
                .cornerRadius(CornerRadius.sm)
            }
        }
    }

    private func recommendationsSection(_ recommendations: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.modusTealAccent)
                Text("Recommendations")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            ForEach(Array(recommendations.enumerated()), id: \.offset) { index, recommendation in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.modusTealAccent)
                        .clipShape(Circle())

                    Text(recommendation)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    private func priorityActionsSection(_ actions: [String]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.modusCyan)
                Text("Priority Actions")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.modusCyan)

                    Text(action)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color.modusCyan.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }

    private func correlationsSection(title: String, icon: String, correlations: [TrainingCorrelation]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.modusCyan)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            ForEach(correlations) { correlation in
                VStack(alignment: .leading, spacing: 6) {
                    Text(correlation.factor)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.modusCyan)

                    Text(correlation.relationship)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle")
                            .font(.caption2)
                        Text(correlation.recommendation)
                            .font(.caption)
                    }
                    .foregroundColor(.modusTealAccent)
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(CornerRadius.sm)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    private func disclaimerSection(_ disclaimer: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                Text("Medical Disclaimer")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }

            Text(disclaimer)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(8)
    }

}

struct MarkerRow: View {
    let marker: LabMarker

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(marker.name)
                    .font(.subheadline)
                    .foregroundColor(.modusDeepTeal)
                if let min = marker.referenceMin, let max = marker.referenceMax {
                    Text("Ref: \(min, specifier: "%.1f") - \(max, specifier: "%.1f") \(marker.unit)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text("\(marker.value, specifier: "%.1f") \(marker.unit)")
                .font(.subheadline)
                .fontWeight(.medium)

            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .accessibilityHidden(true)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(marker.status != .normal ? statusColor.opacity(0.1) : Color.clear)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(marker.name), \(String(format: "%.1f", marker.value)) \(marker.unit), \(statusAccessibilityLabel)")
        .accessibilityHint("Tap to view trend chart for this biomarker")
    }

    private var statusColor: Color {
        switch marker.status {
        case .normal: return .modusTealAccent
        case .low, .high: return .orange
        case .critical: return .red
        }
    }

    private var statusIcon: String {
        switch marker.status {
        case .normal: return "checkmark.circle.fill"
        case .low: return "arrow.down.circle.fill"
        case .high: return "arrow.up.circle.fill"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }

    private var statusAccessibilityLabel: String {
        switch marker.status {
        case .normal: return "normal"
        case .low: return "low"
        case .high: return "high"
        case .critical: return "critical"
        }
    }
}

struct AddLabResultView: View {
    @ObservedObject var viewModel: LabResultsViewModel
    @Binding var showingPDFUpload: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var testType: LabTestType = .bloodPanel
    @State private var testDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // PDF Upload Option (Recommended)
                    Button {
                        dismiss()
                        // Delay to allow sheet to dismiss first
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingPDFUpload = true
                        }
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.modusCyan.opacity(0.15))
                                    .frame(width: 48, height: 48)

                                Image(systemName: "doc.viewfinder")
                                    .font(.title2)
                                    .foregroundColor(.modusCyan)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Upload Lab PDF")
                                    .font(.headline)
                                    .foregroundColor(.modusDeepTeal)

                                Text("AI extracts biomarkers automatically")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            HStack(spacing: 4) {
                                Text("Recommended")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .foregroundColor(.modusTealAccent)
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.modusLightTeal)
                    .accessibilityLabel("Upload Lab PDF")
                    .accessibilityHint("Opens PDF upload view to automatically extract biomarker values")

                } header: {
                    Text("Quick Add")
                } footer: {
                    Text("Upload your lab results PDF from Quest Diagnostics, LabCorp, or other providers. Our AI will extract all biomarker values automatically.")
                }

                Section("Manual Entry") {
                    Picker("Test Type", selection: $testType) {
                        ForEach(LabTestType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    DatePicker("Test Date", selection: $testDate, displayedComponents: .date)

                    Text("Manual entry of individual biomarkers coming soon.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                }
            }
            .navigationTitle("Add Lab Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .tint(.modusCyan)
    }
}
