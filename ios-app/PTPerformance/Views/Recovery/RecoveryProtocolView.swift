import SwiftUI
import Charts

/// View showing current readiness with breakdown and workout recommendations
/// Part of Recovery Intelligence feature
struct RecoveryProtocolView: View {

    // MARK: - Properties

    let patientId: UUID

    @StateObject private var viewModel: ReadinessIntelligenceViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTab: RecoveryTab = .overview
    @State private var showAlternativeWorkout = false
    @State private var selectedAlternative: AlternativeWorkout?

    enum RecoveryTab: String, CaseIterable {
        case overview = "Overview"
        case breakdown = "Breakdown"
        case alternatives = "Alternatives"
        case tips = "Tips"
    }

    // MARK: - Initialization

    init(patientId: UUID) {
        self.patientId = patientId
        _viewModel = StateObject(wrappedValue: ReadinessIntelligenceViewModel(patientId: patientId))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Main readiness card
                readinessScoreCard

                // Tab selection
                tabPicker

                // Tab content
                tabContent
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
        .sheet(item: $selectedAlternative) { alternative in
            AlternativeWorkoutDetailSheet(workout: alternative)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }

    // MARK: - Readiness Score Card

    private var readinessScoreCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                // Score display
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Readiness")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        if viewModel.isLoadingReadiness {
                            ProgressView()
                                .scaleEffect(1.5)
                                .frame(width: 60, height: 60)
                        } else {
                            Text(viewModel.readinessScoreText)
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundColor(viewModel.readinessColor)

                            Text("%")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text(viewModel.confidenceDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Readiness gauge
                if let score = viewModel.compositeReadiness {
                    ReadinessGaugeView(
                        score: score.overallScore,
                        band: score.readinessBand
                    )
                    .frame(width: 80, height: 80)
                }
            }

            // Recommendation banner
            if let adaptation = viewModel.workoutAdaptation {
                RecommendationBanner(
                    type: adaptation.recommendationType,
                    message: adaptation.message
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.medium)
        )
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(RecoveryTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedTab == tab
                                        ? viewModel.readinessColor
                                        : Color(.tertiarySystemGroupedBackground)
                                    )
                            )
                            .foregroundColor(selectedTab == tab ? .white : .primary)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview:
            overviewTab
        case .breakdown:
            breakdownTab
        case .alternatives:
            alternativesTab
        case .tips:
            tipsTab
        }
    }

    // MARK: - Overview Tab

    private var overviewTab: some View {
        VStack(spacing: 16) {
            // Detailed recommendation
            if let adaptation = viewModel.workoutAdaptation {
                DetailedRecommendationCard(
                    recommendation: adaptation.detailedRecommendation,
                    scalingFactors: adaptation.scalingFactors
                )
            }

            // 3-day forecast
            if !viewModel.readinessForecasts.isEmpty {
                ForecastCard(forecasts: viewModel.readinessForecasts)
            }

            // Deload protocol if recommended
            if let deload = viewModel.workoutAdaptation?.deloadProtocol {
                DeloadProtocolCard(protocol: deload)
            }
        }
    }

    // MARK: - Breakdown Tab

    private var breakdownTab: some View {
        VStack(spacing: 16) {
            if let composite = viewModel.compositeReadiness {
                // Component scores
                ComponentScoresCard(score: composite)

                // Raw metrics
                RawMetricsCard(breakdown: composite.breakdown)
            } else {
                EmptyStateCard(
                    icon: "heart.text.square",
                    title: "No Readiness Data",
                    message: "Complete a readiness check-in and sync your health data to see the breakdown."
                )
            }
        }
    }

    // MARK: - Alternatives Tab

    private var alternativesTab: some View {
        VStack(spacing: 16) {
            if let alternatives = viewModel.workoutAdaptation?.alternativeWorkouts, !alternatives.isEmpty {
                ForEach(alternatives) { workout in
                    AlternativeWorkoutCard(workout: workout) {
                        selectedAlternative = workout
                    }
                }
            } else {
                EmptyStateCard(
                    icon: "figure.walk",
                    title: "No Alternatives Suggested",
                    message: "Your readiness is good enough for your planned workout. Keep it up!"
                )
            }
        }
    }

    // MARK: - Tips Tab

    private var tipsTab: some View {
        VStack(spacing: 16) {
            if let tips = viewModel.workoutAdaptation?.recoveryTips, !tips.isEmpty {
                ForEach(tips) { tip in
                    RecoveryTipCard(tip: tip)
                }
            } else {
                EmptyStateCard(
                    icon: "lightbulb",
                    title: "You're Doing Great!",
                    message: "No specific recovery tips needed right now. Keep up your current habits."
                )
            }
        }
    }
}

// MARK: - Readiness Gauge View

struct ReadinessGaugeView: View {
    let score: Double
    let band: ReadinessBand

    @State private var animatedProgress: Double = 0

    private var progress: Double {
        score / 100.0
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(band.color.opacity(0.2), lineWidth: 8)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    band.color,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Band icon
            Image(systemName: band == .green ? "checkmark" :
                    band == .yellow ? "minus" :
                    band == .orange ? "exclamationmark" : "xmark")
                .font(.title2.weight(.bold))
                .foregroundColor(band.color)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
    }
}

// MARK: - Recommendation Banner

struct RecommendationBanner: View {
    let type: WorkoutAdaptation.AdaptationType
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.title2)
                .foregroundColor(.white)

            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(type.color.gradient)
        )
    }
}

// MARK: - Detailed Recommendation Card

struct DetailedRecommendationCard: View {
    let recommendation: String
    let scalingFactors: ScalingFactors

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Recommendation")
                .font(.headline)

            Text(recommendation)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            // Scaling factors
            HStack(spacing: 20) {
                ScalingFactorPill(
                    title: "Intensity",
                    value: scalingFactors.intensityReductionText,
                    icon: "scalemass"
                )

                ScalingFactorPill(
                    title: "Volume",
                    value: scalingFactors.volumeReductionText,
                    icon: "list.number"
                )

                if let rpe = scalingFactors.rpeTarget {
                    ScalingFactorPill(
                        title: "Target RPE",
                        value: "\(rpe)",
                        icon: "gauge"
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

struct ScalingFactorPill: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)

            Text(value)
                .font(.caption.weight(.semibold))

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Forecast Card

struct ForecastCard: View {
    let forecasts: [ReadinessForecast]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.blue)
                Text("3-Day Forecast")
                    .font(.headline)
            }

            HStack(spacing: 12) {
                ForEach(forecasts, id: \.date) { forecast in
                    ForecastDayView(forecast: forecast)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

struct ForecastDayView: View {
    let forecast: ReadinessForecast

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: forecast.date)
    }

    private var band: ReadinessBand {
        if forecast.predictedScore >= 80 { return .green }
        if forecast.predictedScore >= 60 { return .yellow }
        if forecast.predictedScore >= 40 { return .orange }
        return .red
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(dayName)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)

            ZStack {
                Circle()
                    .fill(band.color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Text(String(format: "%.0f", forecast.predictedScore))
                    .font(.headline)
                    .foregroundColor(band.color)
            }

            // Confidence indicator
            HStack(spacing: 2) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Double(i) < forecast.confidence * 3 ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 4, height: 4)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Component Scores Card

struct ComponentScoresCard: View {
    let score: CompositeReadinessScore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Components")
                .font(.headline)

            VStack(spacing: 12) {
                if let hrv = score.hrvScore {
                    ComponentRow(
                        title: "HRV",
                        score: hrv,
                        icon: "heart.fill",
                        color: .red
                    )
                }

                if let sleep = score.sleepScore {
                    ComponentRow(
                        title: "Sleep",
                        score: sleep,
                        icon: "moon.fill",
                        color: .indigo
                    )
                }

                if let rhr = score.restingHRScore {
                    ComponentRow(
                        title: "Resting HR",
                        score: rhr,
                        icon: "waveform.path.ecg",
                        color: .pink
                    )
                }

                if let subjective = score.subjectiveScore {
                    ComponentRow(
                        title: "Check-in",
                        score: subjective,
                        icon: "person.fill.checkmark",
                        color: .blue
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

struct ComponentRow: View {
    let title: String
    let score: Double
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)

            Spacer()

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(scoreColor(for: score))
                        .frame(width: geometry.size.width * min(score / 100, 1))
                }
            }
            .frame(width: 100, height: 8)

            Text(String(format: "%.0f", score))
                .font(.subheadline.monospacedDigit())
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
        }
    }

    private func scoreColor(for score: Double) -> Color {
        if score >= 80 { return .green }
        if score >= 60 { return .yellow }
        if score >= 40 { return .orange }
        return .red
    }
}

// MARK: - Raw Metrics Card

struct RawMetricsCard: View {
    let breakdown: CompositeReadinessScore.ReadinessBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Raw Metrics")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if let hrv = breakdown.hrvValue {
                    MetricCell(
                        title: "HRV",
                        value: String(format: "%.0f ms", hrv),
                        subtitle: breakdown.hrvBaseline.map { "Baseline: \(String(format: "%.0f", $0))" },
                        icon: "heart.fill",
                        color: .red
                    )
                }

                if let sleep = breakdown.sleepHours {
                    MetricCell(
                        title: "Sleep",
                        value: String(format: "%.1f hrs", sleep),
                        subtitle: breakdown.sleepEfficiency.map { "Efficiency: \(String(format: "%.0f%%", $0))" },
                        icon: "moon.fill",
                        color: .indigo
                    )
                }

                if let rhr = breakdown.restingHR {
                    MetricCell(
                        title: "Resting HR",
                        value: String(format: "%.0f bpm", rhr),
                        subtitle: nil,
                        icon: "waveform.path.ecg",
                        color: .pink
                    )
                }

                if let energy = breakdown.energyLevel {
                    MetricCell(
                        title: "Energy",
                        value: "\(energy)/10",
                        subtitle: nil,
                        icon: "bolt.fill",
                        color: .yellow
                    )
                }

                if let soreness = breakdown.sorenessLevel {
                    MetricCell(
                        title: "Soreness",
                        value: "\(soreness)/10",
                        subtitle: nil,
                        icon: "figure.arms.open",
                        color: .orange
                    )
                }

                if let stress = breakdown.stressLevel {
                    MetricCell(
                        title: "Stress",
                        value: "\(stress)/10",
                        subtitle: nil,
                        icon: "brain.head.profile",
                        color: .purple
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

struct MetricCell: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.headline)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Alternative Workout Card

struct AlternativeWorkoutCard: View {
    let workout: AlternativeWorkout
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: workout.type.icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Label("\(workout.duration) min", systemImage: "clock")
                        Label(workout.intensity.displayName, systemImage: "gauge")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Alternative Workout Detail Sheet

struct AlternativeWorkoutDetailSheet: View {
    let workout: AlternativeWorkout
    var onStartWorkout: ((AlternativeWorkout) -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 60, height: 60)

                            Image(systemName: workout.type.icon)
                                .font(.title)
                                .foregroundColor(.blue)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(workout.name)
                                .font(.title2.bold())

                            HStack(spacing: 12) {
                                Label("\(workout.duration) min", systemImage: "clock")
                                Label(workout.intensity.displayName, systemImage: "gauge")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)

                        Text(workout.description)
                            .foregroundColor(.secondary)
                    }

                    // Benefits
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Benefits")
                            .font(.headline)

                        ForEach(workout.benefits, id: \.self) { benefit in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(benefit)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    // Start button
                    Button {
                        if let onStart = onStartWorkout {
                            // Call the handler and dismiss - parent will handle navigation
                            onStart(workout)
                            dismiss()
                        } else {
                            // No handler provided - just dismiss with info message
                            DebugLogger.shared.log("Alternative workout selected: \(workout.name) - navigate from Today tab to start", level: .info)
                            dismiss()
                        }
                    } label: {
                        Label("Start Workout", systemImage: "play.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Alternative Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Recovery Tip Card

struct RecoveryTipCard: View {
    let tip: RecoveryTip

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(tip.category.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: tip.category.icon)
                    .foregroundColor(tip.category.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(tip.title)
                        .font(.headline)

                    if tip.priority == .high {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }

                Text(tip.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Deload Protocol Card

struct DeloadProtocolCard: View {
    let `protocol`: DeloadProtocol

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.down.to.line")
                        .foregroundColor(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Deload Recommended")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("\(`protocol`.durationDays) days - \(`protocol`.focus.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()

                // Reduction details
                HStack(spacing: 20) {
                    VStack {
                        Text(String(format: "%.0f%%", `protocol`.loadReduction * 100))
                            .font(.headline)
                            .foregroundColor(.orange)
                        Text("Load")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack {
                        Text(String(format: "%.0f%%", `protocol`.volumeReduction * 100))
                            .font(.headline)
                            .foregroundColor(.orange)
                        Text("Volume")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack {
                        Text("\(`protocol`.durationDays)")
                            .font(.headline)
                            .foregroundColor(.orange)
                        Text("Days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                // Focus description
                Text(`protocol`.focus.description)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Schedule preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Schedule Preview")
                        .font(.subheadline.weight(.medium))

                    ForEach(`protocol`.weeklySchedule.prefix(5), id: \.dayNumber) { day in
                        HStack {
                            Text("Day \(day.dayNumber)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 50, alignment: .leading)

                            Text(day.activity)
                                .font(.caption)

                            Spacer()

                            if let duration = day.duration {
                                Text("\(duration) min")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Empty State Card

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Previews

#Preview("Recovery Protocol View") {
    NavigationStack {
        RecoveryProtocolView(patientId: UUID())
    }
}

#Preview("Readiness Gauge") {
    HStack(spacing: 20) {
        ReadinessGaugeView(score: 85, band: .green)
            .frame(width: 80, height: 80)
        ReadinessGaugeView(score: 65, band: .yellow)
            .frame(width: 80, height: 80)
        ReadinessGaugeView(score: 35, band: .orange)
            .frame(width: 80, height: 80)
    }
    .padding()
}
