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

    // MARK: - State

    @StateObject private var viewModel = PerformanceModeDashboardViewModel()
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
        .task(id: selectedTimeRange) {
            await viewModel.loadData(patientId: patientId, timeRange: selectedTimeRange)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Acute Chronic Workload Ratio")
        .accessibilityValue("\(String(format: "%.2f", viewModel.acwrValue)), status: \(viewModel.acwrStatus.rawValue)")
        .accessibilityHint("Tap for ACWR details")
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
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Readiness score")
            .accessibilityValue("\(String(format: "%.0f", viewModel.readinessScore)) percent. Sleep: \(viewModel.sleepQuality). Recovery: \(viewModel.recoveryStatus)")
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
                    loadMetricCard(title: "Chronic (14d)", value: viewModel.chronicLoad)
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
        Group {
            if viewModel.fatigueTrend.isEmpty {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Daily load breakdown not available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Check in regularly to build your training load history")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
            } else {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(viewModel.fatigueTrend.indices, id: \.self) { index in
                        let entry = viewModel.fatigueTrend[index]
                        let maxScore = max(1.0, viewModel.fatigueTrend.map(\.fatigueScore).max() ?? 1)
                        let height = max(20, CGFloat(entry.fatigueScore / maxScore) * 60)

                        VStack(spacing: 2) {
                            Rectangle()
                                .fill(entry.fatigueBand.color.opacity(0.7))
                                .frame(width: 30, height: height)
                                .cornerRadius(4)

                            Text(entry.calculationDate.formatted(.dateTime.weekday(.abbreviated)))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
            }
        }
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

            if viewModel.recommendations.isEmpty {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    Text("No specific recommendations right now. Keep up the good work!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(Spacing.sm)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.sm)
            } else {
                ForEach(viewModel.recommendations) { rec in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: rec.icon)
                            .font(.caption)
                            .foregroundColor(rec.color)

                        Text(rec.text)
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
}

// MARK: - Preview

#if DEBUG
struct PerformanceModeDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PerformanceModeDashboardView(patientId: UUID())
        }
    }
}
#endif
