import SwiftUI

/// Performance Analytics View - Performance mode tab for advanced analytics
/// Loads real data from FatigueTrackingService and ReadinessService
struct PerformanceAnalyticsView: View {
    @EnvironmentObject var storeKit: StoreKitService

    @ObservedObject private var fatigueService = FatigueTrackingService.shared
    @State private var todayReadiness: DailyReadiness?
    @State private var isLoading = true
    @State private var loadError: String?

    private let readinessService = ReadinessService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    if isLoading {
                        ProgressView("Loading analytics...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let error = loadError, todayReadiness == nil && fatigueService.currentFatigue == nil {
                        // Full error state when no data loaded at all
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 36))
                                .foregroundColor(.orange)
                            Text("Failed to Load Analytics")
                                .font(.headline)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button {
                                Task { await loadAnalyticsData() }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Retry")
                                }
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(CornerRadius.md)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .padding()
                    } else {
                        // Analytics overview with real data
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack {
                                Image(systemName: "chart.xyaxis.line")
                                    .font(.title2)
                                    .foregroundColor(.cyan)
                                Text("Performance Analytics")
                                    .font(.headline)
                            }

                            // Key metrics from real services
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                                // Readiness - from ReadinessService
                                LiveAnalyticsMetricCard(
                                    title: "Readiness",
                                    value: todayReadiness?.readinessScore.map { "\(Int($0))" } ?? "--",
                                    unit: todayReadiness?.readinessScore != nil ? "%" : "",
                                    icon: "bolt.heart.fill",
                                    color: readinessColor,
                                    hasData: todayReadiness?.readinessScore != nil
                                )

                                // Fatigue - from FatigueTrackingService
                                LiveAnalyticsMetricCard(
                                    title: "Fatigue",
                                    value: fatigueService.currentFatigue?.fatigueBand.displayName ?? "--",
                                    unit: "",
                                    icon: fatigueService.currentFatigue?.fatigueBand.icon ?? "battery.100",
                                    color: fatigueService.currentFatigue?.fatigueBand.color ?? .secondary,
                                    hasData: fatigueService.currentFatigue != nil
                                )

                                // Training Load (ACWR) - from FatigueTrackingService
                                LiveAnalyticsMetricCard(
                                    title: "Training Load",
                                    value: fatigueService.currentFatigue?.acuteChronicRatio.map { String(format: "%.2f", $0) } ?? "--",
                                    unit: fatigueService.currentFatigue?.acuteChronicRatio != nil ? "ACWR" : "",
                                    icon: "chart.bar",
                                    color: acwrColor,
                                    hasData: fatigueService.currentFatigue?.acuteChronicRatio != nil
                                )

                                // Fatigue Score - from FatigueTrackingService
                                LiveAnalyticsMetricCard(
                                    title: "Fatigue Score",
                                    value: fatigueService.currentFatigue.map { String(format: "%.0f", $0.fatigueScore) } ?? "--",
                                    unit: fatigueService.currentFatigue != nil ? "/100" : "",
                                    icon: "gauge.with.dots.needle.33percent",
                                    color: fatigueService.currentFatigue?.fatigueBand.color ?? .secondary,
                                    hasData: fatigueService.currentFatigue != nil
                                )
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.lg)

                        // Deload recommendation if applicable
                        if let fatigue = fatigueService.currentFatigue, fatigue.deloadRecommended {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                HStack {
                                    Image(systemName: fatigue.deloadUrgency.icon)
                                        .foregroundColor(fatigue.deloadUrgency.color)
                                    Text(fatigue.deloadUrgency.title)
                                        .font(.headline)
                                        .foregroundColor(fatigue.deloadUrgency.color)
                                }

                                Text(fatigue.deloadUrgency.subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(fatigue.deloadUrgency.color.opacity(0.1))
                            .cornerRadius(CornerRadius.lg)
                        }
                    }

                    if let error = loadError, (todayReadiness != nil || fatigueService.currentFatigue != nil) {
                        // Partial error - some data loaded but not all
                        VStack(spacing: Spacing.sm) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text("Some data could not be loaded: \(error)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Button {
                                Task { await loadAnalyticsData() }
                            } label: {
                                Text("Retry")
                                    .font(.caption)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding()
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Analytics")
            .task {
                await loadAnalyticsData()
            }
            .refreshable {
                await loadAnalyticsData()
            }
        }
    }

    // MARK: - Computed Colors

    private var readinessColor: Color {
        guard let score = todayReadiness?.readinessScore else { return .secondary }
        if score >= 80 { return .green }
        if score >= 60 { return .yellow }
        if score >= 40 { return .orange }
        return .red
    }

    private var acwrColor: Color {
        guard let acwr = fatigueService.currentFatigue?.acuteChronicRatio else { return .secondary }
        return ACWRStatus.status(for: acwr).color
    }

    // MARK: - Data Loading

    private func loadAnalyticsData() async {
        isLoading = true
        loadError = nil

        guard let patientIdStr = PTSupabaseClient.shared.userId,
              let patientId = UUID(uuidString: patientIdStr) else {
            isLoading = false
            return
        }

        // Load readiness and fatigue concurrently
        async let readinessTask: () = loadReadiness(patientId: patientId)
        async let fatigueTask: () = loadFatigue(patientId: patientId)

        _ = await (readinessTask, fatigueTask)

        isLoading = false
    }

    private func loadReadiness(patientId: UUID) async {
        do {
            todayReadiness = try await readinessService.getTodayReadiness(for: patientId)
        } catch {
            DebugLogger.shared.warning("PerformanceAnalyticsView", "Could not load readiness: \(error.localizedDescription)")
            loadError = error.localizedDescription
            todayReadiness = nil
        }
    }

    private func loadFatigue(patientId: UUID) async {
        do {
            _ = try await fatigueService.fetchCurrentFatigue(patientId: patientId)
        } catch {
            DebugLogger.shared.warning("PerformanceAnalyticsView", "Could not load fatigue: \(error.localizedDescription)")
            // Only set loadError if readiness didn't already set it
            if loadError == nil {
                loadError = error.localizedDescription
            }
        }
    }
}

// MARK: - Live Analytics Metric Card

struct LiveAnalyticsMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let hasData: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(hasData ? color : .secondary)
                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(hasData ? .primary : .secondary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(hasData ? color.opacity(0.1) : Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}
