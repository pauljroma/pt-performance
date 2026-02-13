// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  WeeklySummaryCardView.swift
//  PTPerformance
//
//  Created by BUILD ACP-843 - Weekly Progress Summary Feature
//  Compact card view for displaying weekly summary on home screen
//

import SwiftUI

/// Compact card view for weekly summary display on home/today screen
struct WeeklySummaryCardView: View {
    // MARK: - Properties

    let patientId: UUID
    var onTap: (() -> Void)?

    // MARK: - State

    @State private var summary: WeeklySummary?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var showFullSummary = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingCard
            } else if let summary = summary {
                summaryCard(summary)
            } else if error != nil {
                errorCard
            } else {
                emptyCard
            }
        }
        .sheet(isPresented: $showFullSummary) {
            WeeklySummaryView(patientId: patientId)
        }
        .task {
            await loadSummary()
        }
    }

    // MARK: - Summary Card

    private func summaryCard(_ summary: WeeklySummary) -> some View {
        Button {
            if let onTap = onTap {
                onTap()
            } else {
                showFullSummary = true
            }
        } label: {
            VStack(spacing: Spacing.sm) {
                // Header
                HStack {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.modusCyan)
                        Text("This Week")
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: summary.performanceCategory.emoji)
                            .font(.system(size: 12))
                            .foregroundColor(summary.performanceCategory.color)
                        Text(summary.performanceCategory.displayName)
                            .font(.caption.bold())
                            .foregroundColor(summary.performanceCategory.color)
                    }
                }

                // Quick stats row
                HStack(spacing: Spacing.md) {
                    // Workouts
                    quickStat(
                        icon: "figure.run",
                        value: "\(summary.workoutsCompleted)/\(summary.workoutsScheduled)",
                        label: "Workouts",
                        color: summary.adherencePercentage >= 80 ? .green : .orange
                    )

                    Divider()
                        .frame(height: 32)

                    // Streak
                    quickStat(
                        icon: "flame.fill",
                        value: "\(summary.currentStreak)",
                        label: "Streak",
                        color: summary.streakMaintained ? .orange : .gray
                    )

                    Divider()
                        .frame(height: 32)

                    // Volume change
                    quickStat(
                        icon: summary.volumeChangeEmoji,
                        value: "\(summary.volumeChangePercent >= 0 ? "+" : "")\(Int(summary.volumeChangePercent))%",
                        label: "Volume",
                        color: summary.volumeChangePercent >= 0 ? .green : .red
                    )
                }

                // Highlight win or improvement
                if let firstWin = summary.wins.first {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))

                        Text(firstWin)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        Spacer()

                        Text("View Details")
                            .font(.caption.bold())
                            .foregroundColor(.modusCyan)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.modusCyan)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }

    private func quickStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Loading Card

    private var loadingCard: some View {
        HStack {
            ProgressView()
            Spacer()
                .frame(width: 12)
            Text("Loading weekly summary...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Error Card

    private var errorCard: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text("Couldn't load summary")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Button("Retry") {
                Task {
                    await loadSummary()
                }
            }
            .font(.caption.bold())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Empty Card

    private var emptyCard: some View {
        Button {
            showFullSummary = true
        } label: {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.modusCyan)
                Text("View Your Weekly Summary")
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data Loading

    private func loadSummary() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            let fetchedSummary = try await WeeklySummaryService.shared.fetchCurrentWeekSummary(for: patientId)
            await MainActor.run {
                summary = fetchedSummary
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }
}

// MARK: - Compact Inline Card

/// Even more compact inline card for tight spaces
struct WeeklySummaryInlineCard: View {
    let patientId: UUID
    var onTap: (() -> Void)?

    @State private var summary: WeeklySummary?
    @State private var isLoading = true
    @State private var showFullSummary = false

    var body: some View {
        Button {
            if let onTap = onTap {
                onTap()
            } else {
                showFullSummary = true
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let summary = summary {
                    // Performance icon
                    Image(systemName: summary.performanceCategory.emoji)
                        .foregroundColor(summary.performanceCategory.color)

                    // Stats
                    Text("\(summary.workoutsCompleted)/\(summary.workoutsScheduled)")
                        .font(.subheadline.bold())

                    if summary.currentStreak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Text("\(summary.currentStreak)")
                                .font(.caption.bold())
                        }
                    }

                    Spacer()

                    Text("View")
                        .font(.caption.bold())
                        .foregroundColor(.modusCyan)
                } else {
                    Text("View Weekly Summary")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm + 2)
                    .fill(Color(.tertiarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showFullSummary) {
            WeeklySummaryView(patientId: patientId)
        }
        .task {
            await loadSummary()
        }
    }

    private func loadSummary() async {
        do {
            let fetchedSummary = try await WeeklySummaryService.shared.fetchCurrentWeekSummary(for: patientId)
            await MainActor.run {
                summary = fetchedSummary
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - Preview

#Preview("Card") {
    VStack(spacing: Spacing.md) {
        WeeklySummaryCardView(patientId: UUID())
        WeeklySummaryInlineCard(patientId: UUID())
    }
    .padding()
}
