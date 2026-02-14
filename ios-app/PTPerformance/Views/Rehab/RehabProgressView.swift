import SwiftUI

/// Rehab Progress View - Rehab mode tab for recovery progress tracking
/// Loads real adherence data and shows honest loading/empty states
struct RehabProgressView: View {
    @EnvironmentObject var storeKit: StoreKitService

    @State private var adherenceData: AdherenceData?
    @State private var isLoading = true
    @State private var loadError: String?

    private let adherenceService = AdherenceService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    if isLoading {
                        ProgressView("Loading progress data...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let error = loadError {
                        // Error state with retry
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 36))
                                .foregroundColor(.orange)
                            Text("Failed to Load Progress")
                                .font(.headline)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button {
                                Task { await loadProgressData() }
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
                    } else {
                        // Progress overview card with real or empty data
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                Text("Recovery Progress")
                                    .font(.headline)
                            }

                            // Progress metrics - real data or empty state
                            HStack(spacing: Spacing.lg) {
                                RehabProgressMetricView(
                                    title: "Adherence",
                                    value: adherenceData.map { "\(Int($0.adherencePercentage))%" } ?? "--",
                                    subtitle: adherenceData != nil ? "Completion rate" : "No data yet",
                                    color: adherenceData != nil ? .green : .secondary,
                                    icon: adherenceData != nil ? "checkmark.circle" : "minus.circle"
                                )

                                RehabProgressMetricView(
                                    title: "Completed",
                                    value: adherenceData.map { "\($0.completedSessions)" } ?? "--",
                                    subtitle: adherenceData != nil ? "Sessions" : "No data yet",
                                    color: adherenceData != nil ? .blue : .secondary,
                                    icon: adherenceData != nil ? "figure.walk" : "minus.circle"
                                )

                                RehabProgressMetricView(
                                    title: "Scheduled",
                                    value: adherenceData.map { "\($0.totalSessions)" } ?? "--",
                                    subtitle: adherenceData != nil ? "Total" : "No data yet",
                                    color: adherenceData != nil ? .purple : .secondary,
                                    icon: adherenceData != nil ? "calendar" : "minus.circle"
                                )
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.lg)

                        // Recovery Milestones - only show when adherence data exists
                        // (This section is placeholder UI until real milestone tracking is built)
                        if adherenceData != nil {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Recovery Milestones")
                                    .font(.headline)

                                VStack(spacing: Spacing.sm) {
                                    Text("Your therapist will add milestones as you progress through recovery. Keep completing your scheduled sessions to track improvement.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, minHeight: 100)
                                .padding()
                                .background(Color(.tertiarySystemGroupedBackground))
                                .cornerRadius(CornerRadius.md)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(CornerRadius.lg)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
            .task {
                await loadProgressData()
            }
            .refreshable {
                await loadProgressData()
            }
        }
    }

    // MARK: - Data Loading

    private func loadProgressData() async {
        isLoading = true
        loadError = nil

        guard let patientId = PTSupabaseClient.shared.userId else {
            isLoading = false
            return
        }

        do {
            let data = try await adherenceService.fetchAdherence(patientId: patientId)
            adherenceData = data
        } catch {
            DebugLogger.shared.warning("RehabProgressView", "Could not load adherence: \(error.localizedDescription)")
            loadError = error.localizedDescription
            adherenceData = nil
        }

        isLoading = false
    }
}

// MARK: - Rehab Progress Metric View

struct RehabProgressMetricView: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
