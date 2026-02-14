//
//  ProgressChartsView.swift
//  PTPerformance
//
//  ACP-1026: Progress Charts Interactivity
//  Enhanced analytics dashboard with interactive charts, time range selector,
//  annotation management, metric comparison overlay, and chart image export.
//

import SwiftUI
import Charts

struct ProgressChartsView: View {

    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ProgressChartsViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let patientId = appState.userId {
                        // Time range selector (1W, 1M, 3M, 6M, 1Y, All)
                        timeRangeSelector

                        // Metric overlay toggle
                        metricOverlayToggle

                        if viewModel.isLoading && viewModel.isEmpty {
                            loadingView
                        } else if viewModel.isEmpty {
                            emptyState
                        } else {
                            // Summary cards
                            summaryCards

                            // Volume chart with annotations
                            volumeChartSection(patientId: patientId)

                            // Strength chart with annotations
                            strengthChartSection(patientId: patientId)

                            // Annotations section
                            annotationsSection
                        }
                    } else {
                        notSignedInView
                    }
                }
                .padding()
            }
            .navigationTitle(LocalizedStrings.NavigationTitles.progress)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Share chart image button
                    if !viewModel.isEmpty {
                        Button {
                            viewModel.showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.modusCyan)
                        }
                        .accessibilityLabel("Share chart as image")
                    }

                    // Add annotation button
                    if !viewModel.isEmpty {
                        Button {
                            viewModel.showAddAnnotation = true
                        } label: {
                            Image(systemName: "flag.badge.ellipsis")
                                .foregroundColor(.modusCyan)
                        }
                        .accessibilityLabel("Add life event annotation")
                    }

                    ContextualHelpButton(articleId: nil)
                }
            }
            .refreshable {
                if let patientId = appState.userId {
                    await viewModel.refresh(for: patientId)
                }
            }
            .task {
                if let patientId = appState.userId {
                    await viewModel.loadAnalytics(for: patientId)
                }
            }
            .sheet(isPresented: $viewModel.showAddAnnotation) {
                AddAnnotationSheet(onSave: { annotation in
                    viewModel.addAnnotation(annotation)
                })
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                chartShareSheet
            }
        }
    }

    // MARK: - Time Range Selector

    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time Range")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 0) {
                ForEach(TimePeriod.allCases, id: \.rawValue) { period in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedPeriod = period
                        }
                        Task {
                            if let patientId = appState.userId {
                                await viewModel.periodChanged(for: patientId)
                            }
                        }
                    } label: {
                        Text(period.shortLabel)
                            .font(.caption)
                            .fontWeight(viewModel.selectedPeriod == period ? .bold : .regular)
                            .foregroundColor(viewModel.selectedPeriod == period ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.xs)
                            .background(
                                viewModel.selectedPeriod == period
                                    ? Color.modusCyan
                                    : Color(.secondarySystemGroupedBackground)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .cornerRadius(CornerRadius.sm)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Time range selector")
        }
    }

    // MARK: - Metric Overlay Toggle

    private var metricOverlayToggle: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.on.square")
                .foregroundColor(.modusTealAccent)
                .font(.subheadline)

            Toggle(isOn: $viewModel.showMetricOverlay) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Compare Metrics")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Overlay strength on volume chart")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .tint(.modusCyan)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text(LocalizedStrings.LoadingStates.loadingAnalytics)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            // Total volume
            if let volume = viewModel.volumeData {
                ProgressSummaryCard(
                    title: LocalizedStrings.Analytics.totalVolume,
                    value: volume.formattedTotal,
                    subtitle: viewModel.selectedPeriod.displayName,
                    icon: "scalemass.fill",
                    color: .modusCyan
                )
            }

            // Average volume
            if let volume = viewModel.volumeData {
                ProgressSummaryCard(
                    title: LocalizedStrings.Analytics.avgVolume,
                    value: volume.formattedAverage,
                    subtitle: LocalizedStrings.Analytics.perWeek,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .modusTealAccent
                )
            }

            // Peak week
            if let volume = viewModel.volumeData, let peakDate = volume.peakDate {
                ProgressSummaryCard(
                    title: LocalizedStrings.Analytics.peakWeek,
                    value: String(format: "%.0f lbs", volume.peakVolume),
                    subtitle: peakDate.formatted(date: .abbreviated, time: .omitted),
                    icon: "arrow.up.circle.fill",
                    color: .modusDeepTeal
                )
            }

            // Strength improvement
            if let strength = viewModel.strengthData {
                ProgressSummaryCard(
                    title: LocalizedStrings.Analytics.strengthGain,
                    value: strength.improvementPercentage,
                    subtitle: strength.exerciseName,
                    icon: "figure.strengthtraining.traditional",
                    color: .modusTealAccent
                )
            }
        }
    }

    // MARK: - Volume Chart Section

    private func volumeChartSection(patientId: String) -> some View {
        Group {
            if let data = viewModel.volumeData {
                VolumeChart(
                    dataPoints: data.dataPoints,
                    annotations: viewModel.annotationsForPeriod,
                    overlayDataPoints: viewModel.showMetricOverlay ? (viewModel.strengthData?.dataPoints ?? []) : [],
                    overlayLabel: "Est. 1RM",
                    showOverlay: viewModel.showMetricOverlay
                )
            } else if let error = viewModel.volumeError {
                sectionErrorView("Volume", error: error) {
                    Task {
                        await viewModel.loadVolumeData(for: patientId)
                    }
                }
            }
        }
    }

    // MARK: - Strength Chart Section

    private func strengthChartSection(patientId: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let data = viewModel.strengthData {
                StrengthChart(
                    dataPoints: data.dataPoints,
                    exerciseName: data.exerciseName,
                    annotations: viewModel.annotationsForPeriod
                )
            } else if viewModel.isLoadingStrength {
                strengthLoadingView
            } else if let error = viewModel.strengthError {
                sectionErrorView("Strength", error: error) {
                    Task {
                        await viewModel.loadStrengthData(for: patientId)
                    }
                }
            } else {
                strengthEmptyState
            }
        }
    }

    // MARK: - Annotations Section

    private var annotationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Life Events")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button {
                    viewModel.showAddAnnotation = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(.subheadline)
                    .foregroundColor(.modusCyan)
                }
            }

            if viewModel.annotations.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "flag")
                            .font(.title2)
                            .foregroundColor(.secondary.opacity(0.5))

                        Text("No annotations yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("Mark vacations, injuries, or deloads to add context to your charts")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                ForEach(viewModel.annotations) { annotation in
                    annotationRow(annotation)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    private func annotationRow(_ annotation: ChartAnnotation) -> some View {
        HStack(spacing: 12) {
            Image(systemName: annotation.category.icon)
                .foregroundColor(annotation.category.color)
                .font(.body)
                .frame(width: 28, height: 28)
                .background(annotation.category.color.opacity(0.15))
                .cornerRadius(CornerRadius.xs)

            VStack(alignment: .leading, spacing: 2) {
                Text(annotation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(annotation.date, format: .dateTime.month(.abbreviated).day().year())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(annotation.category.displayName)
                .font(.caption2)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxs)
                .background(annotation.category.color.opacity(0.1))
                .foregroundColor(annotation.category.color)
                .cornerRadius(CornerRadius.xs)

            Button {
                withAnimation {
                    viewModel.removeAnnotation(annotation)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Chart Share Sheet

    private var chartShareSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Exporting chart image...")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                if let image = viewModel.generateChartImage(
                    volumeData: viewModel.volumeData,
                    strengthData: viewModel.strengthData,
                    period: viewModel.selectedPeriod,
                    annotations: viewModel.annotationsForPeriod,
                    colorScheme: colorScheme
                ) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(CornerRadius.md)
                        .padding()

                    Button {
                        viewModel.shareChartImage(image)
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Image")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.modusCyan)
                        .foregroundColor(.white)
                        .cornerRadius(CornerRadius.md)
                    }
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundColor(DesignTokens.statusWarning)
                        Text("Unable to generate chart image")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 40)
                }
            }
            .padding()
            .navigationTitle("Share Chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.showShareSheet = false
                    }
                }
            }
        }
    }

    // MARK: - Supporting Views

    private var strengthLoadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(LocalizedStrings.LoadingStates.loadingStrengthData)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    private var strengthEmptyState: some View {
        EmptyStateView(
            title: LocalizedStrings.EmptyStates.noStrengthData,
            message: LocalizedStrings.EmptyStates.logWeightedExercises + " Your personal records and improvement trends will appear here.",
            icon: "figure.strengthtraining.traditional",
            iconColor: .modusTealAccent
        )
        .frame(height: 220)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }

    private var emptyState: some View {
        EmptyStateView(
            title: LocalizedStrings.EmptyStates.noAnalyticsDataYet,
            message: LocalizedStrings.EmptyStates.completeFirstWorkout + " Volume trends, strength gains, and performance insights will appear here.",
            icon: "chart.bar.xaxis",
            iconColor: .modusCyan,
            action: nil
        )
        .padding(.vertical, 40)
    }

    private var notSignedInView: some View {
        EmptyStateView(
            title: LocalizedStrings.EmptyStates.signInRequired,
            message: "Sign in to your account to view your progress analytics, track workout volume, and monitor strength gains.",
            icon: "person.crop.circle.badge.exclamationmark",
            iconColor: DesignTokens.statusWarning,
            action: nil
        )
        .padding(.vertical, 40)
    }

    private func sectionErrorView(_ section: String, error: String, retry: @escaping () -> Void) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundColor(DesignTokens.statusWarning)

            Text("Unable to Load \(section) Data")
                .font(.headline)

            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(LocalizedStrings.ErrorStates.tryAgain) {
                retry()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }
}

// MARK: - Progress Summary Card

private struct ProgressSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)

                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value), \(subtitle)")
    }
}

// MARK: - Add Annotation Sheet

struct AddAnnotationSheet: View {
    let onSave: (ChartAnnotation) -> Void

    @State private var title = ""
    @State private var note = ""
    @State private var date = Date()
    @State private var category: AnnotationCategory = .vacation
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Title", text: $title)

                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    Picker("Category", selection: $category) {
                        ForEach(AnnotationCategory.allCases) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                    .foregroundColor(cat.color)
                                Text(cat.displayName)
                            }
                            .tag(cat)
                        }
                    }
                }

                Section("Notes (Optional)") {
                    TextField("Add context about this event...", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    // Category preview
                    HStack(spacing: 12) {
                        Image(systemName: category.icon)
                            .foregroundColor(category.color)
                            .font(.title2)
                            .frame(width: 36, height: 36)
                            .background(category.color.opacity(0.15))
                            .cornerRadius(CornerRadius.sm)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(title.isEmpty ? "Event Title" : title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(title.isEmpty ? .secondary : .primary)

                            Text(date, format: .dateTime.month(.abbreviated).day().year())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(category.displayName)
                            .font(.caption2)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, Spacing.xxs)
                            .background(category.color.opacity(0.1))
                            .foregroundColor(category.color)
                            .cornerRadius(CornerRadius.xs)
                    }
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle("Add Life Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let annotation = ChartAnnotation(
                            date: date,
                            title: title,
                            note: note.isEmpty ? nil : note,
                            category: category
                        )
                        onSave(annotation)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - TimePeriod Extension for Short Labels

extension TimePeriod {
    var shortLabel: String {
        switch self {
        case .week: return "1W"
        case .month: return "1M"
        case .threeMonths: return "3M"
        case .sixMonths: return "6M"
        case .year: return "1Y"
        case .allTime: return "All"
        }
    }
}

// MARK: - View Model

@MainActor
class ProgressChartsViewModel: ObservableObject {
    @Published var selectedPeriod: TimePeriod = .month
    @Published var isLoading = false
    @Published var isLoadingStrength = false
    @Published var showMetricOverlay = false
    @Published var showAddAnnotation = false
    @Published var showShareSheet = false

    @Published var volumeData: VolumeChartData?
    @Published var volumeError: String?

    @Published var strengthData: StrengthChartData?
    @Published var strengthError: String?

    @Published var annotations: [ChartAnnotation] = []

    private let analyticsService = AnalyticsService.shared
    private let annotationsKey = "chart_annotations_v1"

    var isEmpty: Bool {
        volumeData == nil && strengthData == nil
    }

    /// Annotations filtered to fall within the currently selected time period
    var annotationsForPeriod: [ChartAnnotation] {
        let startDate = selectedPeriod.startDate
        return annotations.filter { $0.date >= startDate }
    }

    init() {
        loadAnnotationsFromStorage()
    }

    func loadAnalytics(for patientId: String) async {
        isLoading = true
        defer { isLoading = false }

        async let volumeTask: () = loadVolumeData(for: patientId)
        async let strengthTask: () = loadStrengthData(for: patientId)

        _ = await (volumeTask, strengthTask)
    }

    func loadVolumeData(for patientId: String) async {
        do {
            volumeError = nil
            let data = try await analyticsService.calculateVolumeData(
                for: patientId,
                period: selectedPeriod
            )
            volumeData = data
        } catch {
            volumeError = error.localizedDescription
        }
    }

    func loadStrengthData(for patientId: String) async {
        isLoadingStrength = true
        defer { isLoadingStrength = false }

        do {
            strengthError = nil
            let data = try await analyticsService.calculateStrengthData(
                for: patientId,
                exerciseId: "primary",
                period: selectedPeriod
            )
            strengthData = data
        } catch AnalyticsError.noData {
            strengthData = nil
            strengthError = nil
        } catch {
            strengthError = error.localizedDescription
        }
    }

    func periodChanged(for patientId: String) async {
        await loadAnalytics(for: patientId)
    }

    func refresh(for patientId: String) async {
        await loadAnalytics(for: patientId)
    }

    // MARK: - Annotation Management

    func addAnnotation(_ annotation: ChartAnnotation) {
        annotations.append(annotation)
        annotations.sort { $0.date > $1.date }
        saveAnnotationsToStorage()
    }

    func removeAnnotation(_ annotation: ChartAnnotation) {
        annotations.removeAll { $0.id == annotation.id }
        saveAnnotationsToStorage()
    }

    private func loadAnnotationsFromStorage() {
        if let data = UserDefaults.standard.data(forKey: annotationsKey),
           let decoded = try? JSONDecoder().decode([ChartAnnotation].self, from: data) {
            annotations = decoded.sorted { $0.date > $1.date }
        }
    }

    private func saveAnnotationsToStorage() {
        if let encoded = try? JSONEncoder().encode(annotations) {
            UserDefaults.standard.set(encoded, forKey: annotationsKey)
        }
    }

    // MARK: - Chart Image Export

    func generateChartImage(
        volumeData: VolumeChartData?,
        strengthData: StrengthChartData?,
        period: TimePeriod,
        annotations: [ChartAnnotation],
        colorScheme: ColorScheme
    ) -> UIImage? {
        let width: CGFloat = 390
        let height: CGFloat = 600

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))

        return renderer.image { context in
            let cgContext = context.cgContext

            // Background
            let bgColor = colorScheme == .dark
                ? UIColor.systemBackground
                : UIColor.white
            bgColor.setFill()
            cgContext.fill(CGRect(x: 0, y: 0, width: width, height: height))

            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: UIColor.modusDeepTeal
            ]
            let title = "Progress Report - \(period.displayName)"
            title.draw(at: CGPoint(x: 20, y: 20), withAttributes: titleAttributes)

            // Date
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let dateStr = Date().formatted(date: .long, time: .omitted)
            dateStr.draw(at: CGPoint(x: 20, y: 48), withAttributes: dateAttributes)

            // Volume summary
            var yOffset: CGFloat = 80

            let sectionAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: UIColor.modusCyan
            ]

            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                .foregroundColor: UIColor.label
            ]

            if let vol = volumeData {
                "Training Volume".draw(at: CGPoint(x: 20, y: yOffset), withAttributes: sectionAttributes)
                yOffset += 28

                "Total: \(vol.formattedTotal)".draw(at: CGPoint(x: 20, y: yOffset), withAttributes: bodyAttributes)
                yOffset += 22
                "Average: \(vol.formattedAverage)".draw(at: CGPoint(x: 20, y: yOffset), withAttributes: bodyAttributes)
                yOffset += 22
                "Peak: \(String(format: "%.0f lbs", vol.peakVolume))".draw(at: CGPoint(x: 20, y: yOffset), withAttributes: bodyAttributes)
                yOffset += 22
                "Data points: \(vol.dataPoints.count)".draw(at: CGPoint(x: 20, y: yOffset), withAttributes: bodyAttributes)
                yOffset += 36

                // Draw mini volume chart bar representation
                let barAreaWidth = width - 40
                let barHeight: CGFloat = 100
                let barWidth = max(4, barAreaWidth / CGFloat(vol.dataPoints.count) - 2)
                let maxVol = vol.dataPoints.map { $0.totalVolume }.max() ?? 1

                UIColor.modusCyan.withAlphaComponent(0.3).setFill()

                for (index, point) in vol.dataPoints.enumerated() {
                    let barH = CGFloat(point.totalVolume / maxVol) * barHeight
                    let x = 20 + CGFloat(index) * (barWidth + 2)
                    let y = yOffset + barHeight - barH
                    cgContext.fill(CGRect(x: x, y: y, width: barWidth, height: barH))
                }

                yOffset += barHeight + 20
            }

            if let str = strengthData {
                "Strength Progress (\(str.exerciseName))".draw(at: CGPoint(x: 20, y: yOffset), withAttributes: sectionAttributes)
                yOffset += 28

                "Current 1RM: \(str.formattedCurrentMax)".draw(at: CGPoint(x: 20, y: yOffset), withAttributes: bodyAttributes)
                yOffset += 22
                "Improvement: \(str.improvementPercentage)".draw(at: CGPoint(x: 20, y: yOffset), withAttributes: bodyAttributes)
                yOffset += 22
                "Data points: \(str.dataPoints.count)".draw(at: CGPoint(x: 20, y: yOffset), withAttributes: bodyAttributes)
                yOffset += 36
            }

            // Annotations
            if !annotations.isEmpty {
                "Life Events".draw(at: CGPoint(x: 20, y: yOffset), withAttributes: sectionAttributes)
                yOffset += 28

                for annotation in annotations.prefix(5) {
                    let annotationText = "\(annotation.category.displayName): \(annotation.title) (\(annotation.date.formatted(date: .abbreviated, time: .omitted)))"
                    annotationText.draw(at: CGPoint(x: 20, y: yOffset), withAttributes: bodyAttributes)
                    yOffset += 22
                }
                yOffset += 16
            }

            // Footer
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.tertiaryLabel
            ]
            "Generated by Modus".draw(at: CGPoint(x: 20, y: height - 30), withAttributes: footerAttributes)
        }
    }

    func shareChartImage(_ image: UIImage) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            return
        }

        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        // iPad popover support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        rootVC.present(activityVC, animated: true)
        showShareSheet = false
    }
}

// MARK: - Preview

#if DEBUG
struct ProgressChartsView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        appState.userId = "test-patient-id"
        appState.isAuthenticated = true

        return Group {
            ProgressChartsView()
                .environmentObject(appState)
                .previewDisplayName("Authenticated")

            ProgressChartsView()
                .environmentObject(AppState())
                .previewDisplayName("Not Authenticated")
        }
    }
}
#endif
