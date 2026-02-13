//
//  PerformanceModeDashboardView.swift
//  PTPerformance
//
//  Full dashboard view for Performance Mode
//  ACP-MODE: Comprehensive performance-focused dashboard with ACWR tracking,
//  readiness monitoring, and training load management
//

import SwiftUI

/// Performance Mode Dashboard View - Comprehensive performance monitoring
/// Displays ACWR trends, readiness scores, fatigue tracking, and training recommendations
struct PerformanceModeDashboardView: View {
    // MARK: - Properties

    let patientId: UUID

    // MARK: - Environment

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @StateObject private var viewModel = PerformanceModeDashboardViewModelLocal()
    @State private var showReadinessCheckIn = false
    @State private var showACWRDetails = false
    @State private var selectedTimeRange: PerformanceTimeRange = .week

    // MARK: - Initialization

    init(patientId: UUID) {
        self.patientId = patientId
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header section
                headerSection

                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(message: error)
                } else {
                    // ACWR Card
                    acwrCard

                    // Readiness Card
                    readinessCard

                    // Fatigue tracking section
                    fatigueSection

                    // Training load chart
                    trainingLoadSection

                    // Recommendations section
                    recommendationsSection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Performance Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .refreshableWithHaptic {
            await viewModel.refresh(patientId: patientId)
        }
        .task {
            await viewModel.loadData(patientId: patientId)
        }
        .sheetWithHaptic(isPresented: $showReadinessCheckIn) {
            ReadinessCheckInView(patientId: patientId)
        }
        .sheetWithHaptic(isPresented: $showACWRDetails) {
            ACWRDetailsSheet(acwr: viewModel.acwrValue, status: viewModel.acwrStatus)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Performance Metrics")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.modusDeepTeal)

                    Text(Date().formatted(date: .complete, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Check-in button
                Button(action: {
                    HapticFeedback.medium()
                    showReadinessCheckIn = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Check In")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.modusCyan)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.md)
                }
            }

            // Time range picker
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(PerformanceTimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading performance data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Unable to load data")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                HapticFeedback.light()
                Task { await viewModel.refresh(patientId: patientId) }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Spacing.xl)
        }
        .padding()
    }

    // MARK: - ACWR Card

    private var acwrCard: some View {
        Button(action: {
            HapticFeedback.light()
            showACWRDetails = true
        }) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text("Acute:Chronic Workload Ratio")
                        .font(.headline)
                        .foregroundColor(.modusDeepTeal)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: Spacing.lg) {
                    // ACWR gauge
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 80, height: 80)

                        Circle()
                            .trim(from: 0, to: min(1.0, viewModel.acwrValue / 2.0))
                            .stroke(viewModel.acwrColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 0) {
                            Text(String(format: "%.2f", viewModel.acwrValue))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(viewModel.acwrColor)
                                .monospacedDigit()

                            Text("ACWR")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Status and zones
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Image(systemName: viewModel.acwrStatusIcon)
                                .foregroundColor(viewModel.acwrColor)
                            Text(viewModel.acwrStatus.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(viewModel.acwrColor)
                        }

                        // Zone indicator
                        acwrZoneIndicator
                    }

                    Spacer()
                }
                .padding()
                .background(viewModel.acwrColor.opacity(0.1))
                .cornerRadius(CornerRadius.md)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var acwrZoneIndicator: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 2) {
                Rectangle().fill(Color.blue).frame(width: 20, height: 6)
                Rectangle().fill(Color.green).frame(width: 30, height: 6)
                Rectangle().fill(Color.yellow).frame(width: 15, height: 6)
                Rectangle().fill(Color.red).frame(width: 15, height: 6)
            }
            .cornerRadius(3)

            HStack {
                Text("<0.8")
                    .font(.system(size: 8))
                Spacer()
                Text("0.8-1.3")
                    .font(.system(size: 8))
                Spacer()
                Text(">1.5")
                    .font(.system(size: 8))
            }
            .foregroundColor(.secondary)
        }
        .frame(width: 100)
    }

    // MARK: - Readiness Card

    private var readinessCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Readiness Score")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            HStack(spacing: Spacing.lg) {
                // Score circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                        .frame(width: 70, height: 70)

                    Circle()
                        .trim(from: 0, to: viewModel.readinessScore / 100)
                        .stroke(viewModel.readinessColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text(String(format: "%.0f", viewModel.readinessScore))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(viewModel.readinessColor)

                        Text("%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Factors breakdown
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    readinessFactorRow(icon: "moon.fill", label: "Sleep", value: viewModel.sleepQuality)
                    readinessFactorRow(icon: "heart.fill", label: "HRV", value: viewModel.hrvStatus)
                    readinessFactorRow(icon: "figure.walk", label: "Recovery", value: viewModel.recoveryStatus)
                }

                Spacer()
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
    }

    private func readinessFactorRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }

    // MARK: - Fatigue Section

    private var fatigueSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "battery.50")
                    .foregroundColor(viewModel.fatigueBandColor)
                Text("Fatigue Level")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)
            }

            HStack(spacing: Spacing.md) {
                // Fatigue indicator
                VStack(spacing: 4) {
                    Image(systemName: viewModel.fatigueBand.icon)
                        .font(.title)
                        .foregroundColor(viewModel.fatigueBandColor)

                    Text(viewModel.fatigueBand.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(viewModel.fatigueBandColor)
                }
                .frame(width: 80)

                // Description
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.fatigueBand.description)
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    if viewModel.consecutiveLowReadinessDays > 0 {
                        Text("\(viewModel.consecutiveLowReadinessDays) consecutive low readiness days")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Spacer()
            }
            .padding()
            .background(viewModel.fatigueBandColor.opacity(0.1))
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Training Load Section

    private var trainingLoadSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.modusCyan)
                Text("Training Load")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)
            }

            VStack(spacing: Spacing.sm) {
                HStack {
                    loadMetricCard(title: "Acute (7d)", value: viewModel.acuteLoad)
                    loadMetricCard(title: "Chronic (28d)", value: viewModel.chronicLoad)
                }

                // Simple trend visualization
                trainingLoadTrend
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
    }

    private func loadMetricCard(title: String, value: Double) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(String(format: "%.0f", value))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .monospacedDigit()

            Text("AU")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
    }

    private var trainingLoadTrend: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(viewModel.weeklyLoadHistory.indices, id: \.self) { index in
                let load = viewModel.weeklyLoadHistory[index]
                let maxLoad = viewModel.weeklyLoadHistory.max() ?? 1
                let height = max(20, CGFloat(load / maxLoad) * 60)

                Rectangle()
                    .fill(Color.modusCyan.opacity(0.7))
                    .frame(width: 30, height: height)
                    .cornerRadius(4)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Recommendations")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)
            }

            ForEach(viewModel.recommendations, id: \.self) { recommendation in
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)

                    Text(recommendation)
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding(Spacing.sm)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.sm)
            }
        }
    }
}

// MARK: - Time Range Enum

private enum PerformanceTimeRange: String, CaseIterable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"

    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "3 Months"
        }
    }
}

// MARK: - Performance Dashboard ViewModel

@MainActor
class PerformanceModeDashboardViewModelLocal: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var acwrValue: Double = 0
    @Published var acwrStatus: ACWRStatus = .unknown
    @Published var readinessScore: Double = 0
    @Published var fatigueBand: FatigueBand = .low
    @Published var acuteLoad: Double = 0
    @Published var chronicLoad: Double = 0
    @Published var weeklyLoadHistory: [Double] = []
    @Published var consecutiveLowReadinessDays: Int = 0
    @Published var recommendations: [String] = []

    // Readiness factors
    @Published var sleepQuality: String = "Good"
    @Published var hrvStatus: String = "Normal"
    @Published var recoveryStatus: String = "Recovered"

    private let fatigueService = FatigueTrackingService.shared
    private let readinessService = ReadinessService()

    var acwrColor: Color {
        switch acwrStatus {
        case .undertraining: return .blue
        case .optimal: return .green
        case .caution: return .yellow
        case .danger: return .red
        case .unknown: return .secondary
        }
    }

    var acwrStatusIcon: String {
        switch acwrStatus {
        case .undertraining: return "arrow.up.circle"
        case .optimal: return "checkmark.circle.fill"
        case .caution: return "exclamationmark.triangle"
        case .danger: return "exclamationmark.octagon"
        case .unknown: return "questionmark.circle"
        }
    }

    var readinessColor: Color {
        switch readinessScore {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }

    var fatigueBandColor: Color {
        fatigueBand.color
    }

    func loadData(patientId: UUID) async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        // Load fatigue data
        do {
            try await fatigueService.fetchCurrentFatigue(patientId: patientId)
            if let fatigue = fatigueService.currentFatigue {
                acwrValue = fatigue.acuteChronicRatio ?? 1.0
                acwrStatus = ACWRStatus.status(for: acwrValue)
                fatigueBand = fatigue.fatigueBand
                acuteLoad = fatigue.trainingLoad7d ?? 0
                chronicLoad = fatigue.trainingLoad14d ?? 0
                consecutiveLowReadinessDays = fatigue.consecutiveLowReadiness
            }
        } catch {
            DebugLogger.shared.log("[PerformanceDashboardVM] Failed to load fatigue: \(error)", level: .warning)
        }

        // Load readiness
        do {
            if let readiness = try await readinessService.getTodayReadiness(for: patientId) {
                readinessScore = readiness.readinessScore ?? 0
                updateReadinessFactors(from: readiness)
            }
        } catch {
            DebugLogger.shared.log("[PerformanceDashboardVM] Failed to load readiness: \(error)", level: .warning)
        }

        // Load sample data
        loadSampleData()
    }

    func refresh(patientId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        await loadData(patientId: patientId)
    }

    private func updateReadinessFactors(from readiness: DailyReadiness) {
        if let sleep = readiness.sleepHours {
            sleepQuality = sleep >= 7 ? "Good" : sleep >= 5 ? "Fair" : "Poor"
        }

        // Derive recovery status from energy and soreness levels
        if let energy = readiness.energyLevel, let soreness = readiness.sorenessLevel {
            let recoveryScore = (energy + (10 - soreness)) / 2  // Higher is better
            recoveryStatus = recoveryScore >= 7 ? "Recovered" : recoveryScore >= 5 ? "Moderate" : "Fatigued"
        } else if let energy = readiness.energyLevel {
            recoveryStatus = energy >= 7 ? "Recovered" : energy >= 5 ? "Moderate" : "Fatigued"
        }
    }

    private func loadSampleData() {
        // Sample weekly load history
        weeklyLoadHistory = [120, 145, 130, 160, 140, 155, 135]

        // Sample recommendations based on ACWR
        recommendations = [
            acwrStatus.recommendation,
            "Ensure 7-8 hours of quality sleep",
            "Monitor HRV trends for early fatigue detection",
            "Consider active recovery on rest days"
        ]
    }
}

// MARK: - ACWR Details Sheet

private struct ACWRDetailsSheet: View {
    let acwr: Double
    let status: ACWRStatus
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // ACWR gauge
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                            .frame(width: 150, height: 150)

                        Circle()
                            .trim(from: 0, to: min(1.0, acwr / 2.0))
                            .stroke(statusColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 150, height: 150)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 4) {
                            Text(String(format: "%.2f", acwr))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(statusColor)

                            Text("ACWR")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()

                    // Status
                    VStack(spacing: Spacing.sm) {
                        Text(status.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(statusColor)

                        Text(status.recommendation)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()

                    // Zone descriptions
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("ACWR Zones")
                            .font(.headline)
                            .foregroundColor(.modusDeepTeal)

                        zoneRow(color: .blue, range: "< 0.8", label: "Undertraining", description: "Training load may be too low")
                        zoneRow(color: .green, range: "0.8 - 1.3", label: "Optimal", description: "Sweet spot for adaptation")
                        zoneRow(color: .yellow, range: "1.3 - 1.5", label: "Caution", description: "Increased injury risk")
                        zoneRow(color: .red, range: "> 1.5", label: "Danger", description: "High injury risk, reduce load")
                    }
                    .padding()
                }
            }
            .navigationTitle("ACWR Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var statusColor: Color {
        switch status {
        case .undertraining: return .blue
        case .optimal: return .green
        case .caution: return .yellow
        case .danger: return .red
        case .unknown: return .secondary
        }
    }

    private func zoneRow(color: Color, range: String, label: String, description: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(range)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text("-")
                        .foregroundColor(.secondary)

                    Text(label)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                }

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(Spacing.sm)
        .background(color.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Preview

#if DEBUG
struct PerformanceModeDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PerformanceModeDashboardView(patientId: UUID())
                .environmentObject(AppState())
        }
    }
}
#endif
