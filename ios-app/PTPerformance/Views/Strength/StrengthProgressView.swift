import SwiftUI

/// Strength Progress View - Strength mode tab for volume and gains tracking
/// Loads real volume data from VolumeAnalyticsService
struct StrengthProgressView: View {
    @EnvironmentObject var storeKit: StoreKitService

    @State private var weeklyVolumeData: VolumeChartData?
    @State private var monthlyVolumeData: VolumeChartData?
    @State private var isLoading = true
    @State private var loadError: String?

    private let volumeService = VolumeAnalyticsService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    if isLoading {
                        ProgressView("Loading volume data...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let error = loadError {
                        // Error state with retry
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 36))
                                .foregroundColor(DesignTokens.statusWarning)
                            Text("Failed to Load Volume Data")
                                .font(.headline)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button {
                                Task { await loadVolumeData() }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Retry")
                                }
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.modusCyan)
                                .foregroundColor(.white)
                                .cornerRadius(CornerRadius.md)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .padding()
                    } else if weeklyVolumeData == nil && monthlyVolumeData == nil {
                        // Empty state
                        strengthEmptyState
                    } else {
                        // Volume overview card with real data
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .font(.title2)
                                    .foregroundColor(.modusCyan)
                                Text("Training Volume")
                                    .font(.headline)
                            }

                            HStack(spacing: Spacing.lg) {
                                StrengthVolumeMetricView(
                                    title: "This Week",
                                    volumeData: weeklyVolumeData
                                )

                                StrengthVolumeMetricView(
                                    title: "This Month",
                                    volumeData: monthlyVolumeData
                                )
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.lg)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
            .task {
                await loadVolumeData()
            }
            .refreshable {
                await loadVolumeData()
            }
        }
    }

    // MARK: - Empty State

    private var strengthEmptyState: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "chart.bar")
                    .font(.system(size: 48))
                    .foregroundColor(.modusCyan.opacity(0.5))

                Text("No Volume Data Yet")
                    .font(.headline)

                Text("Start logging workouts to track your training volume over time. Weekly and monthly totals will appear here automatically.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, Spacing.lg)
        }
    }

    // MARK: - Data Loading

    private func loadVolumeData() async {
        isLoading = true
        loadError = nil

        guard let patientId = PTSupabaseClient.shared.userId else {
            isLoading = false
            return
        }

        do {
            async let weekly = volumeService.calculateVolumeData(for: patientId, period: .week)
            async let monthly = volumeService.calculateVolumeData(for: patientId, period: .month)

            let (weeklyResult, monthlyResult) = try await (weekly, monthly)
            weeklyVolumeData = weeklyResult.totalVolume > 0 ? weeklyResult : nil
            monthlyVolumeData = monthlyResult.totalVolume > 0 ? monthlyResult : nil
        } catch {
            DebugLogger.shared.warning("StrengthProgressView", "Could not load volume data: \(error.localizedDescription)")
            loadError = error.localizedDescription
            weeklyVolumeData = nil
            monthlyVolumeData = nil
        }

        isLoading = false
    }
}

// MARK: - Strength Volume Metric View

struct StrengthVolumeMetricView: View {
    let title: String
    let volumeData: VolumeChartData?

    private var formattedVolume: String {
        guard let data = volumeData else { return "--" }
        let vol = data.totalVolume
        if vol >= 1_000_000 {
            return String(format: "%.1fM", vol / 1_000_000)
        } else if vol >= 1000 {
            return String(format: "%.1fK", vol / 1000)
        } else {
            return String(format: "%.0f", vol)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(formattedVolume)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(volumeData != nil ? .primary : .secondary)
                if volumeData != nil {
                    Text("lbs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if volumeData == nil {
                Text("No data yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let data = volumeData, !data.dataPoints.isEmpty {
                Text("\(data.dataPoints.count) week\(data.dataPoints.count == 1 ? "" : "s") tracked")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}
