//
//  ProgressChartsView.swift
//  PTPerformance
//
//  Created by Agent 1 - Volume/Strength Trend Charts
//  Main analytics dashboard with volume and strength charts
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
                        // Time period selector
                        periodPicker

                        if viewModel.isLoading && viewModel.isEmpty {
                            loadingView
                        } else if viewModel.isEmpty {
                            emptyState
                        } else {
                            // Summary cards
                            summaryCards

                            // Volume chart
                            volumeChartSection(patientId: patientId)

                            // Strength chart
                            strengthChartSection(patientId: patientId)
                        }
                    } else {
                        notSignedInView
                    }
                }
                .padding()
            }
            .navigationTitle(LocalizedStrings.NavigationTitles.progress)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("Time Period", selection: $viewModel.selectedPeriod) {
            Text(LocalizedStrings.TimePeriods.week).tag(TimePeriod.week)
            Text(LocalizedStrings.TimePeriods.month).tag(TimePeriod.month)
            Text(LocalizedStrings.TimePeriods.threeMonths).tag(TimePeriod.threeMonths)
            Text(LocalizedStrings.TimePeriods.year).tag(TimePeriod.year)
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: viewModel.selectedPeriod) { _, _ in
            Task {
                if let patientId = appState.userId {
                    await viewModel.periodChanged(for: patientId)
                }
            }
        }
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
                SummaryCard(
                    title: LocalizedStrings.Analytics.totalVolume,
                    value: volume.formattedTotal,
                    subtitle: viewModel.selectedPeriod.displayName,
                    icon: "scalemass.fill",
                    color: .blue
                )
            }

            // Average volume
            if let volume = viewModel.volumeData {
                SummaryCard(
                    title: LocalizedStrings.Analytics.avgVolume,
                    value: volume.formattedAverage,
                    subtitle: LocalizedStrings.Analytics.perWeek,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .cyan
                )
            }

            // Peak week
            if let volume = viewModel.volumeData, let peakDate = volume.peakDate {
                SummaryCard(
                    title: LocalizedStrings.Analytics.peakWeek,
                    value: String(format: "%.0f lbs", volume.peakVolume),
                    subtitle: peakDate.formatted(date: .abbreviated, time: .omitted),
                    icon: "arrow.up.circle.fill",
                    color: .purple
                )
            }

            // Strength improvement
            if let strength = viewModel.strengthData {
                SummaryCard(
                    title: LocalizedStrings.Analytics.strengthGain,
                    value: strength.improvementPercentage,
                    subtitle: strength.exerciseName,
                    icon: "figure.strengthtraining.traditional",
                    color: .green
                )
            }
        }
    }

    // MARK: - Volume Chart Section

    private func volumeChartSection(patientId: String) -> some View {
        Group {
            if let data = viewModel.volumeData {
                VolumeChart(dataPoints: data.dataPoints)
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
                    exerciseName: data.exerciseName
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
            iconColor: .green
        )
        .frame(height: 220)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            title: LocalizedStrings.EmptyStates.noAnalyticsDataYet,
            message: LocalizedStrings.EmptyStates.completeFirstWorkout + " Volume trends, strength gains, and performance insights will appear here.",
            icon: "chart.bar.xaxis",
            iconColor: .blue,
            action: nil
        )
        .padding(.vertical, 40)
    }

    // MARK: - Not Signed In View

    private var notSignedInView: some View {
        EmptyStateView(
            title: LocalizedStrings.EmptyStates.signInRequired,
            message: "Sign in to your account to view your progress analytics, track workout volume, and monitor strength gains.",
            icon: "person.crop.circle.badge.exclamationmark",
            iconColor: .orange,
            action: nil
        )
        .padding(.vertical, 40)
    }

    // MARK: - Section Error View

    private func sectionErrorView(_ section: String, error: String, retry: @escaping () -> Void) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundColor(.orange)

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

// MARK: - Summary Card

private struct SummaryCard: View {
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

// MARK: - View Model

@MainActor
class ProgressChartsViewModel: ObservableObject {
    @Published var selectedPeriod: TimePeriod = .month
    @Published var isLoading = false
    @Published var isLoadingStrength = false

    @Published var volumeData: VolumeChartData?
    @Published var volumeError: String?

    @Published var strengthData: StrengthChartData?
    @Published var strengthError: String?

    private let analyticsService = AnalyticsService.shared

    var isEmpty: Bool {
        volumeData == nil && strengthData == nil
    }

    func loadAnalytics(for patientId: String) async {
        isLoading = true
        defer { isLoading = false }

        // Load volume and strength data concurrently
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
            // For now, we use a default exercise ID - in a full implementation,
            // this would be the user's most trained exercise or a selected exercise
            // The service will find the most relevant exercise data
            let data = try await analyticsService.calculateStrengthData(
                for: patientId,
                exerciseId: "primary", // Special key to get primary exercise
                period: selectedPeriod
            )
            strengthData = data
        } catch AnalyticsError.noData {
            // No data is not an error state - just show empty
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
