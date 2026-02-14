import SwiftUI
import Charts

/// Main view showing fatigue analysis and deload recommendations
/// Displays fatigue score, prescription details, contributing factors, and trends
struct DeloadRecommendationView: View {
    // MARK: - Properties

    let patientId: UUID

    @StateObject private var viewModel: DeloadRecommendationViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    init(patientId: UUID) {
        self.patientId = patientId
        _viewModel = StateObject(wrappedValue: DeloadRecommendationViewModel(patientId: patientId))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading && !viewModel.hasData {
                    loadingView
                } else if viewModel.hasData {
                    contentView
                } else {
                    emptyStateView
                }
            }
            .padding()
        }
        .navigationTitle("Recovery Status")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            HapticFeedback.light()
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadData()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Deload Activated", isPresented: $viewModel.showActivationSuccess) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Your deload period has been activated. Training loads will be automatically adjusted.")
        }
        .alert("Recommendation Dismissed", isPresented: $viewModel.showDismissalSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The deload recommendation has been dismissed. We'll continue monitoring your recovery.")
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        VStack(spacing: 20) {
            // Fatigue score card
            fatigueScoreCard

            // Deload prescription card (if recommended)
            if viewModel.deloadRecommended, let prescription = viewModel.prescription {
                deloadPrescriptionCard(prescription: prescription)
            }

            // ACP-1025: AI Transparency - reasoning and feedback card
            if viewModel.deloadRecommended {
                AIRecommendationTransparencyCard(
                    recommendationId: "deload-\(patientId.uuidString.prefix(8))-\(Date().formatted(.iso8601.year().month().day()))",
                    recommendationType: .deload,
                    reasoningSummary: viewModel.deloadReasoningSummary,
                    drivingFactors: viewModel.deloadDrivingFactors,
                    confidenceLevel: viewModel.deloadDataConfidence
                )
            }

            // Contributing factors section
            if !viewModel.contributingFactors.isEmpty {
                contributingFactorsSection
            }

            // Fatigue trend section
            if !viewModel.trendData.isEmpty {
                fatigueTrendSection
            }
        }
    }

    // MARK: - Fatigue Score Card

    private var fatigueScoreCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fatigue Score")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(viewModel.fatigueScoreText)
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(viewModel.fatigueColor)

                        Text("/ 100")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Fatigue band indicator
                if let band = viewModel.fatigueBand {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(band.color.opacity(0.2))
                                .frame(width: 64, height: 64)

                            Image(systemName: band.icon)
                                .font(.system(size: 28))
                                .foregroundColor(band.color)
                        }

                        Text(band.displayName)
                            .font(.caption.weight(.medium))
                            .foregroundColor(band.color)
                    }
                }
            }

            // Description
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.modusCyan)
                Text(viewModel.fatigueDescription)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.modusCyan.opacity(0.1))
            )

            // Metrics row
            if let summary = viewModel.fatigueSummary {
                HStack(spacing: 16) {
                    metricPill(
                        title: "Readiness",
                        value: String(format: "%.0f%%", summary.avgReadiness7d),
                        icon: "heart.fill",
                        color: summary.avgReadiness7d > 60 ? .modusTealAccent : DesignTokens.statusWarning
                    )

                    metricPill(
                        title: "ACR",
                        value: String(format: "%.2f", summary.acuteChronicRatio),
                        icon: "arrow.up.arrow.down",
                        color: summary.acuteChronicRatio > 1.3 ? DesignTokens.statusWarning : .modusTealAccent
                    )

                    metricPill(
                        title: "Low Days",
                        value: "\(summary.consecutiveLowDays)",
                        icon: "calendar.badge.exclamationmark",
                        color: summary.consecutiveLowDays > 2 ? DesignTokens.statusWarning : .modusTealAccent
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.medium)
        )
    }

    private func metricPill(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }

    // MARK: - Deload Prescription Card

    private func deloadPrescriptionCard(prescription: DeloadPrescription) -> some View {
        VStack(spacing: 16) {
            // Header with urgency indicator
            HStack {
                Image(systemName: viewModel.urgency.icon)
                    .font(.title2)
                    .foregroundColor(viewModel.urgency.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.urgency.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(viewModel.urgency.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Divider()

            // Prescription details
            VStack(spacing: 12) {
                prescriptionRow(
                    icon: "calendar",
                    title: "Duration",
                    value: "\(prescription.durationDays) days",
                    subtitle: prescription.dateRangeText
                )

                prescriptionRow(
                    icon: "scalemass",
                    title: "Load Reduction",
                    value: prescription.formattedLoadReduction,
                    subtitle: "Reduce weight/intensity"
                )

                prescriptionRow(
                    icon: "list.number",
                    title: "Volume Reduction",
                    value: prescription.formattedVolumeReduction,
                    subtitle: "Reduce sets/reps"
                )

                prescriptionRow(
                    icon: "target",
                    title: "Focus",
                    value: prescription.focus,
                    subtitle: nil
                )
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await viewModel.dismissRecommendation()
                    }
                }) {
                    HStack {
                        if viewModel.isDismissing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "xmark.circle")
                        }
                        Text("Dismiss")
                    }
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(viewModel.isDismissing || viewModel.isActivating)

                Button(action: {
                    Task {
                        await viewModel.activateDeload()
                    }
                }) {
                    HStack {
                        if viewModel.isActivating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text("Activate")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.urgency.color)
                    )
                }
                .disabled(viewModel.isDismissing || viewModel.isActivating)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.medium)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(viewModel.urgency.color.opacity(0.3), lineWidth: 2)
        )
    }

    private func prescriptionRow(icon: String, title: String, value: String, subtitle: String?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.modusCyan)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }

    // MARK: - Contributing Factors Section

    private var contributingFactorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contributing Factors")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 8) {
                ForEach(viewModel.contributingFactors, id: \.self) { factor in
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(DesignTokens.statusWarning)

                        Text(factor)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DesignTokens.statusWarning.opacity(0.1))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.medium)
        )
    }

    // MARK: - Fatigue Trend Section

    private var fatigueTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("7-Day Fatigue Trend")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text("Lower is better")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Chart(viewModel.trendData) { dataPoint in
                // Area gradient fill
                AreaMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value("Score", dataPoint.fatigueScore)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            dataPoint.band.color.opacity(0.3),
                            dataPoint.band.color.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Line
                LineMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value("Score", dataPoint.fatigueScore)
                )
                .foregroundStyle(dataPoint.band.color)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)

                // Point markers
                PointMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value("Score", dataPoint.fatigueScore)
                )
                .foregroundStyle(dataPoint.band.color)
                .symbolSize(50)
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.caption)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .background(
                        Color(.separator)
                    )
                    .cornerRadius(CornerRadius.sm)
            }
            // Reference lines for fatigue bands
            .chartOverlay { _ in
                GeometryReader { geometry in
                    // High threshold (70)
                    Rectangle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(height: 1)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height * 0.3
                        )

                    // Moderate threshold (50)
                    Rectangle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(height: 1)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height * 0.5
                        )
                }
            }
            .frame(height: 200)
            .accessibilityLabel("Fatigue trend chart")
            .accessibilityValue("Shows \(viewModel.trendData.count) days of fatigue data")

            // Legend
            HStack(spacing: 16) {
                legendItem(color: .green, label: "Low (0-50)")
                legendItem(color: .yellow, label: "Moderate (50-70)")
                legendItem(color: .orange, label: "High (70-85)")
                legendItem(color: .red, label: "Critical (85+)")
            }
            .font(.caption2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.medium)
        )
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Analyzing recovery data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 60))
                .foregroundColor(.modusTealAccent.opacity(0.6))

            Text("No Recovery Data")
                .font(.title2.bold())
                .foregroundColor(.primary)

            Text("Complete readiness check-ins and training sessions to start tracking your recovery status and receive personalized deload recommendations.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 60)
    }
}

// MARK: - FatigueScoreGauge Component

/// Circular gauge component displaying fatigue score (0-100)
/// Color-coded by fatigue band with animated progress ring
struct FatigueScoreGauge: View {
    let score: Double
    let band: FatigueBand

    @State private var animatedProgress: Double = 0

    private var progress: Double {
        score / 100.0
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    band.color.opacity(0.2),
                    lineWidth: 12
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    band.color,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Score and band label
            VStack(spacing: 4) {
                Text(String(format: "%.0f", score))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(band.color)

                Text(band.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 120, height: 120)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .accessibilityLabel("Fatigue score \(Int(score)) out of 100, \(band.displayName) level")
    }
}

// MARK: - DeloadPrescriptionCard Component

/// Card showing deload prescription details with activate/dismiss actions
struct DeloadPrescriptionCard: View {
    let urgency: DeloadUrgency
    let prescription: DeloadPrescription
    let isActivating: Bool
    let isDismissing: Bool
    let onActivate: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            // Header with urgency indicator
            HStack {
                Image(systemName: urgency.icon)
                    .font(.title2)
                    .foregroundColor(urgency.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(urgency.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(urgency.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Divider()

            // Prescription details
            VStack(spacing: 12) {
                PrescriptionDetailRow(
                    icon: "calendar",
                    title: "Duration",
                    value: "\(prescription.durationDays) days",
                    subtitle: prescription.dateRangeText
                )

                PrescriptionDetailRow(
                    icon: "scalemass",
                    title: "Load Reduction",
                    value: prescription.formattedLoadReduction,
                    subtitle: "Reduce weight/intensity"
                )

                PrescriptionDetailRow(
                    icon: "list.number",
                    title: "Volume Reduction",
                    value: prescription.formattedVolumeReduction,
                    subtitle: "Reduce sets/reps"
                )

                PrescriptionDetailRow(
                    icon: "target",
                    title: "Focus",
                    value: prescription.focus,
                    subtitle: nil
                )
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: onDismiss) {
                    HStack {
                        if isDismissing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "xmark.circle")
                        }
                        Text("Dismiss")
                    }
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(isDismissing || isActivating)

                Button(action: onActivate) {
                    HStack {
                        if isActivating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text("Activate")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(urgency.color)
                    )
                }
                .disabled(isDismissing || isActivating)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.medium)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(urgency.color.opacity(0.3), lineWidth: 2)
        )
    }
}

/// Row showing a single prescription detail
struct PrescriptionDetailRow: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.modusCyan)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }
}

// MARK: - ContributingFactorRow Component

/// Single row displaying a contributing factor to fatigue
struct ContributingFactorRow: View {
    let factor: String
    var icon: String = "exclamationmark.triangle.fill"
    var iconColor: Color = DesignTokens.statusWarning

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(iconColor)

            Text(factor)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(iconColor.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Contributing factor: \(factor)")
    }
}

// MARK: - FatigueTrendChart Component

/// Simple sparkline chart showing fatigue score trend over time
struct FatigueTrendChart: View {
    let dataPoints: [FatigueTrendPoint]
    var height: CGFloat = 200

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(dataPoints.count)-Day Fatigue Trend")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text("Lower is better")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if dataPoints.isEmpty {
                emptyState
            } else {
                chartContent
            }

            // Legend
            HStack(spacing: 16) {
                legendItem(color: .green, label: "Low (0-50)")
                legendItem(color: .yellow, label: "Moderate (50-70)")
                legendItem(color: .orange, label: "High (70-85)")
                legendItem(color: .red, label: "Critical (85+)")
            }
            .font(.caption2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.medium)
        )
    }

    private var chartContent: some View {
        Chart(dataPoints) { dataPoint in
            // Area gradient fill
            AreaMark(
                x: .value("Date", dataPoint.date, unit: .day),
                y: .value("Score", dataPoint.fatigueScore)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        dataPoint.band.color.opacity(0.3),
                        dataPoint.band.color.opacity(0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Line
            LineMark(
                x: .value("Date", dataPoint.date, unit: .day),
                y: .value("Score", dataPoint.fatigueScore)
            )
            .foregroundStyle(dataPoint.band.color)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .interpolationMethod(.catmullRom)

            // Point markers
            PointMark(
                x: .value("Date", dataPoint.date, unit: .day),
                y: .value("Score", dataPoint.fatigueScore)
            )
            .foregroundStyle(dataPoint.band.color)
            .symbolSize(50)
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                            .font(.caption)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
        .chartPlotStyle { plotArea in
            plotArea
                .background(
                    Color(.separator)
                )
                .cornerRadius(CornerRadius.sm)
        }
        .frame(height: height)
        .accessibilityLabel("Fatigue trend chart")
        .accessibilityValue("Shows \(dataPoints.count) days of fatigue data")
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title)
                .foregroundColor(.secondary)

            Text("Not enough data for trend")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Component Previews

#Preview("FatigueScoreGauge - Low") {
    FatigueScoreGauge(score: 35, band: .low)
        .padding()
}

#Preview("FatigueScoreGauge - High") {
    FatigueScoreGauge(score: 78, band: .high)
        .padding()
}

#Preview("DeloadPrescriptionCard") {
    DeloadPrescriptionCard(
        urgency: .recommended,
        prescription: DeloadPrescription.sample,
        isActivating: false,
        isDismissing: false,
        onActivate: { print("Activate") },
        onDismiss: { print("Dismiss") }
    )
    .padding()
}

#Preview("ContributingFactorRow") {
    VStack(spacing: 8) {
        ContributingFactorRow(factor: "Elevated acute:chronic workload ratio")
        ContributingFactorRow(factor: "Consecutive low readiness days")
        ContributingFactorRow(factor: "High average RPE in recent sessions")
    }
    .padding()
}

#Preview("FatigueTrendChart") {
    let calendar = Calendar.current
    let trendData = (0..<7).map { daysAgo in
        let date = calendar.date(byAdding: .day, value: -6 + daysAgo, to: Date()) ?? Date()
        let score = 45.0 + Double(daysAgo) * 5.0 + Double.random(in: -5...5)
        let band: FatigueBand = score > 70 ? .high : (score > 50 ? .moderate : .low)
        return FatigueTrendPoint(date: date, fatigueScore: score, band: band)
    }

    return FatigueTrendChart(dataPoints: trendData)
        .padding()
}

// MARK: - Previews

#Preview("With Deload Recommended") {
    NavigationStack {
        DeloadRecommendationView(patientId: UUID())
    }
}

#Preview("No Deload Needed") {
    NavigationStack {
        DeloadRecommendationView(patientId: UUID())
    }
}

#Preview("Loading") {
    NavigationStack {
        DeloadRecommendationView(patientId: UUID())
    }
}

#Preview("Empty State") {
    NavigationStack {
        DeloadRecommendationView(patientId: UUID())
    }
}
