import SwiftUI

struct LabResultsView: View {
    @StateObject private var viewModel = LabResultsViewModel()

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
                    Button {
                        viewModel.showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                AddLabResultView(viewModel: viewModel)
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
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Lab Results", systemImage: "cross.case")
        } description: {
            Text("Upload your blood work and lab results to track your health markers over time.")
        } actions: {
            Button("Add Lab Result") {
                viewModel.showingAddSheet = true
            }
            .buttonStyle(.borderedProminent)
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
                Text(result.testDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status indicator
            if let abnormalCount = abnormalMarkers {
                if abnormalCount > 0 {
                    Text("\(abnormalCount) flagged")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                } else {
                    Text("Normal")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                }
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var abnormalMarkers: Int? {
        let abnormal = result.results.filter { $0.status != .normal }
        return abnormal.count
    }
}

struct LabResultDetailView: View {
    let result: LabResult
    @ObservedObject var viewModel: LabResultsViewModel
    @State private var aiAnalysis: String?
    @State private var isAnalyzing = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(result.testType.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(result.testDate.formatted(date: .long, time: .omitted))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Markers
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Results")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(result.results) { marker in
                            MarkerRow(marker: marker)
                        }
                    }

                    // AI Analysis
                    if let analysis = aiAnalysis ?? result.aiAnalysis {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AI Analysis")
                                .font(.headline)
                            Text(analysis)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        Button {
                            Task {
                                isAnalyzing = true
                                aiAnalysis = await viewModel.getAIAnalysis(for: result)
                                isAnalyzing = false
                            }
                        } label: {
                            HStack {
                                if isAnalyzing {
                                    ProgressView()
                                        .padding(.trailing, 8)
                                }
                                Text(isAnalyzing ? "Analyzing..." : "Get AI Analysis")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isAnalyzing)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Lab Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct MarkerRow: View {
    let marker: LabMarker

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(marker.name)
                    .font(.subheadline)
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

            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(marker.status != .normal ? statusColor.opacity(0.1) : Color.clear)
    }

    private var statusColor: Color {
        switch marker.status {
        case .normal: return .green
        case .low, .high: return .orange
        case .critical: return .red
        }
    }
}

struct AddLabResultView: View {
    @ObservedObject var viewModel: LabResultsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var testType: LabTestType = .bloodPanel
    @State private var testDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Test Information") {
                    Picker("Test Type", selection: $testType) {
                        ForEach(LabTestType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    DatePicker("Test Date", selection: $testDate, displayedComponents: .date)
                }

                Section {
                    Text("Upload your lab results PDF or enter markers manually.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Upload PDF") {
                        // TODO: Implement PDF upload
                    }
                    .disabled(true) // Not implemented yet
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
    }
}
