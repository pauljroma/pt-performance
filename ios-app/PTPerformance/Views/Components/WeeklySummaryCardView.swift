// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  WeeklySummaryCardView.swift
//  PTPerformance
//
//  Created by BUILD ACP-843 - Weekly Progress Summary Feature
//  Enhanced by ACP-1028 - Weekly Summary Personalization
//  Compact card view with personalized highlights for home screen
//

import SwiftUI

/// Compact card view for weekly summary display on home/today screen
/// Enhanced with personalized highlight, mini progress ring, and Modus branding
struct WeeklySummaryCardView: View {
    // MARK: - Properties

    let patientId: UUID
    var userMode: Mode = .strength
    var onTap: (() -> Void)?

    // MARK: - State

    @State private var summary: WeeklySummary?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var showFullSummary = false
    @State private var animateRing = false

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
            WeeklySummaryView(patientId: patientId, userMode: userMode)
        }
        .task {
            await loadSummary()
            try? await Task.sleep(nanoseconds: 500_000_000)
            withAnimation(.easeOut(duration: 0.6)) {
                animateRing = true
            }
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
                // Header with mini adherence ring
                HStack {
                    HStack(spacing: Spacing.xs) {
                        // Mini progress ring
                        ZStack {
                            Circle()
                                .stroke(Color.modusCyan.opacity(0.15), lineWidth: 3)
                                .frame(width: 22, height: 22)

                            Circle()
                                .trim(from: 0, to: animateRing ? CGFloat(summary.adherenceProgress) : 0)
                                .stroke(Color.modusCyan, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .frame(width: 22, height: 22)
                                .rotationEffect(.degrees(-90))
                        }

                        Text(LocalizedStrings.TimePeriods.thisWeek)
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

                // Quick stats row with Modus colors
                HStack(spacing: Spacing.md) {
                    // Workouts
                    quickStat(
                        icon: "figure.run",
                        value: "\(summary.workoutsCompleted)/\(summary.workoutsScheduled)",
                        label: LocalizedStrings.Analytics.workouts,
                        color: summary.adherencePercentage >= 80 ? .modusTealAccent : .orange
                    )

                    Divider()
                        .frame(height: 32)

                    // Streak
                    quickStat(
                        icon: "flame.fill",
                        value: "\(summary.currentStreak)",
                        label: LocalizedStrings.Analytics.streak,
                        color: summary.streakMaintained ? .modusCyan : .secondary
                    )

                    Divider()
                        .frame(height: 32)

                    // Volume change with arrow
                    VStack(spacing: Spacing.xxs) {
                        HStack(spacing: 2) {
                            Image(systemName: summary.volumeChangePercent >= 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(summary.volumeChangePercent >= 0 ? .modusTealAccent : .red)
                            Text("\(summary.volumeChangePercent >= 0 ? "+" : "")\(Int(summary.volumeChangePercent))%")
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                        }
                        Text(LocalizedStrings.Analytics.volume)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                // Personalized highlight snippet (ACP-1028)
                personalizedSnippet(summary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .strokeBorder(
                                Color.modusCyan.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    /// Personalized highlight snippet at the bottom of the card
    private func personalizedSnippet(_ summary: WeeklySummary) -> some View {
        let highlight = summary.personalizedHighlight(for: userMode)

        return HStack(spacing: Spacing.xs) {
            Image(systemName: highlight.icon)
                .foregroundColor(highlight.accentColor)
                .font(.system(size: 12))

            Text(highlight.title)
                .font(.caption.bold())
                .foregroundColor(highlight.accentColor)

            Text("--")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(highlight.subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)

            Spacer()

            Text("View")
                .font(.caption.bold())
                .foregroundColor(.modusCyan)

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.modusCyan)
        }
        .padding(.top, Spacing.xxs)
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
                .tint(.modusCyan)
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
            .foregroundColor(.modusCyan)
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
                    .foregroundColor(.modusCyan)
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

/// Even more compact inline card for tight spaces with personalized hint
struct WeeklySummaryInlineCard: View {
    let patientId: UUID
    var userMode: Mode = .strength
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
                        .tint(.modusCyan)
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
                                .foregroundColor(.modusCyan)
                            Text("\(summary.currentStreak)")
                                .font(.caption.bold())
                        }
                    }

                    // Volume trend arrow
                    HStack(spacing: 2) {
                        Image(systemName: summary.volumeChangePercent >= 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(summary.volumeChangePercent >= 0 ? .modusTealAccent : .red)
                        Text("\(Int(abs(summary.volumeChangePercent)))%")
                            .font(.caption2.bold())
                            .foregroundColor(summary.volumeChangePercent >= 0 ? .modusTealAccent : .red)
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
            WeeklySummaryView(patientId: patientId, userMode: userMode)
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
        WeeklySummaryCardView(patientId: UUID(), userMode: .strength)
        WeeklySummaryCardView(patientId: UUID(), userMode: .rehab)
        WeeklySummaryInlineCard(patientId: UUID(), userMode: .performance)
    }
    .padding()
}
