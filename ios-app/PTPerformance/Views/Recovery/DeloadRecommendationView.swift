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
                    .foregroundColor(.blue)
                Text(viewModel.fatigueDescription)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
            )

            // Metrics row
            if let summary = viewModel.fatigueSummary {
                HStack(spacing: 16) {
                    metricPill(
                        title: "Readiness",
                        value: String(format: "%.0f%%", summary.avgReadiness7d),
                        icon: "heart.fill",
                        color: summary.avgReadiness7d > 60 ? .green : .orange
                    )

                    metricPill(
                        title: "ACR",
                        value: String(format: "%.2f", summary.acuteChronicRatio),
                        icon: "arrow.up.arrow.down",
                        color: summary.acuteChronicRatio > 1.3 ? .orange : .green
                    )

                    metricPill(
                        title: "Low Days",
                        value: "\(summary.consecutiveLowDays)",
                        icon: "calendar.badge.exclamationmark",
                        color: summary.consecutiveLowDays > 2 ? .orange : .green
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
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
        .padding(.vertical, 12)
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
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
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
                .foregroundColor(.blue)
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
                            .foregroundColor(.orange)

                        Text(factor)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
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
                AxisMarks(values: .stride(by: .day, count: 1)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .background(
                        Color(colorScheme == .dark ? .systemGray6 : .systemGray6).opacity(0.3)
                    )
                    .cornerRadius(8)
            }
            // Reference lines for fatigue bands
            .chartOverlay { proxy in
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
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
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
                .foregroundColor(.green.opacity(0.6))

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
