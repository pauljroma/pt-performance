//
//  WeeklySummaryView.swift
//  PTPerformance
//
//  Created by BUILD ACP-843 - Weekly Progress Summary Feature
//  Enhanced by ACP-1028 - Weekly Summary Personalization
//  Full weekly recap view with personalized highlights, key wins,
//  actionable focus areas, week-over-week comparison, and motivational insights
//

import SwiftUI

/// Full weekly summary view with personalized, mode-aware breakdown
struct WeeklySummaryView: View {
    // MARK: - Properties

    let patientId: UUID
    var userMode: Mode = .strength

    // MARK: - State

    @StateObject private var viewModel: WeeklySummaryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWeek: Int = 0  // 0 = current, 1 = last week
    @State private var animateProgressRings = false

    // MARK: - Init

    init(patientId: UUID, userMode: Mode = .strength) {
        self.patientId = patientId
        self.userMode = userMode
        self._viewModel = StateObject(wrappedValue: WeeklySummaryViewModel(patientId: patientId))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Week selector
                    weekSelector

                    if viewModel.isLoading {
                        loadingView
                    } else if let summary = viewModel.currentSummary {
                        // Performance header with progress rings
                        performanceHeaderWithRings(summary)

                        // Personalized highlight card (ACP-1028)
                        personalizedHighlightCard(summary)

                        // Week-over-week comparison (ACP-1028)
                        weekComparisonSection(summary)

                        // Key metrics mini chart strip
                        metricsGrid(summary)

                        // Key Wins section (ACP-1028)
                        keyWinsSection(summary)

                        // Areas to Focus with actionable suggestions (ACP-1028)
                        areasToFocusSection(summary)

                        // Next Week Plan (ACP-1028)
                        nextWeekPlanSection(summary)

                        // Motivational insight (ACP-1028)
                        motivationalInsightCard(summary)

                        // Notification settings
                        notificationSettings

                        // History link
                        historyButton
                    } else if let error = viewModel.error {
                        errorView(error)
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(LocalizedStrings.NavigationTitles.weeklySummary)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.Common.done) {
                        dismiss()
                    }
                    .foregroundColor(.modusCyan)
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
                // Delay ring animation for visual polish
                try? await Task.sleep(nanoseconds: 300_000_000)
                withAnimation(.easeOut(duration: 0.8)) {
                    animateProgressRings = true
                }
            }
        }
    }

    // MARK: - Week Selector

    private var weekSelector: some View {
        Picker("Week", selection: $selectedWeek) {
            Text(LocalizedStrings.TimePeriods.thisWeek).tag(0)
            Text(LocalizedStrings.TimePeriods.lastWeek).tag(1)
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedWeek) { _, newValue in
            animateProgressRings = false
            Task {
                await viewModel.selectWeek(offset: newValue)
                try? await Task.sleep(nanoseconds: 300_000_000)
                withAnimation(.easeOut(duration: 0.8)) {
                    animateProgressRings = true
                }
            }
        }
    }

    // MARK: - Performance Header with Progress Rings (ACP-1028)

    private func performanceHeaderWithRings(_ summary: WeeklySummary) -> some View {
        VStack(spacing: Spacing.md) {
            // Performance badge
            HStack(spacing: Spacing.xs) {
                Image(systemName: summary.performanceCategory.emoji)
                    .font(.system(size: 20))
                    .foregroundColor(summary.performanceCategory.color)
                    .accessibilityHidden(true)

                Text(summary.performanceCategory.displayName)
                    .font(.title3.bold())
                    .foregroundColor(summary.performanceCategory.color)
            }

            // Date range
            Text(summary.dateRangeString)
                .font(.caption)
                .foregroundColor(.secondary)

            // Progress rings row
            HStack(spacing: Spacing.xl) {
                progressRing(
                    value: animateProgressRings ? summary.workoutCompletionProgress : 0,
                    label: "Workouts",
                    valueText: "\(summary.workoutsCompleted)/\(summary.workoutsScheduled)",
                    color: .modusCyan
                )

                progressRing(
                    value: animateProgressRings ? summary.adherenceProgress : 0,
                    label: "Adherence",
                    valueText: "\(Int(summary.adherencePercentage))%",
                    color: .modusTealAccent
                )

                progressRing(
                    value: animateProgressRings ? summary.streakProgress : 0,
                    label: "Streak",
                    valueText: "\(summary.currentStreak)d",
                    color: .modusDeepTeal
                )
            }
            .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .padding(.horizontal, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.modusLightTeal)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.modusCyan.opacity(0.3), .modusTealAccent.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weekly performance: \(summary.performanceCategory.displayName), \(summary.dateRangeString)")
    }

    /// Reusable progress ring component
    private func progressRing(value: Double, label: String, valueText: String, color: Color) -> some View {
        VStack(spacing: Spacing.xxs) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 6)
                    .frame(width: 56, height: 56)

                // Progress ring
                Circle()
                    .trim(from: 0, to: CGFloat(value))
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: value)

                // Center text
                Text(valueText)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(valueText)")
    }

    // MARK: - Personalized Highlight Card (ACP-1028)

    private func personalizedHighlightCard(_ summary: WeeklySummary) -> some View {
        let highlight = summary.personalizedHighlight(for: userMode)

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(.modusCyan)
                Text(LocalizedStrings.SectionHeaders.personalizedForYou)
                    .font(.caption.bold())
                    .foregroundColor(.modusCyan)

                Spacer()

                Text(userMode.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color(.tertiarySystemBackground))
                    )
            }

            HStack(spacing: Spacing.sm) {
                // Highlight icon
                Image(systemName: highlight.icon)
                    .font(.system(size: 28))
                    .foregroundColor(highlight.accentColor)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(highlight.accentColor.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(highlight.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)

                    Text(highlight.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Personalized highlight: \(highlight.title). \(highlight.subtitle)")
    }

    // MARK: - Week-over-Week Comparison (ACP-1028)

    private func weekComparisonSection(_ summary: WeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(.modusDeepTeal)
                    .accessibilityHidden(true)
                Text(LocalizedStrings.SectionHeaders.weekOverWeek)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
            }

            HStack(spacing: Spacing.sm) {
                comparisonPill(
                    label: "Workouts",
                    current: "\(summary.workoutsCompleted)",
                    delta: summary.volumeChangePercent != 0 ? summary.workoutsCompleted - summary.workoutsScheduled : 0,
                    isPercentage: false
                )

                comparisonPill(
                    label: "Adherence",
                    current: "\(Int(summary.adherencePercentage))%",
                    delta: Int(summary.adherencePercentage) - 100,
                    isPercentage: false
                )

                comparisonPill(
                    label: "Volume",
                    current: summary.formattedVolume,
                    delta: Int(summary.volumeChangePercent),
                    isPercentage: true
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func comparisonPill(label: String, current: String, delta: Int, isPercentage: Bool) -> some View {
        VStack(spacing: Spacing.xxs) {
            Text(current)
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)

            // Delta indicator
            HStack(spacing: 2) {
                if delta > 0 {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.modusTealAccent)
                } else if delta < 0 {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.red)
                } else {
                    Image(systemName: "minus")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary)
                }

                Text(delta == 0 ? "Same" : "\(abs(delta))\(isPercentage ? "%" : "")")
                    .font(.caption2.bold())
                    .foregroundColor(delta > 0 ? .modusTealAccent : (delta < 0 ? .red : .secondary))
            }
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(delta > 0 ? Color.modusTealAccent.opacity(0.12) :
                          (delta < 0 ? Color.red.opacity(0.12) : Color(.tertiarySystemBackground)))
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(current), \(delta > 0 ? "up" : delta < 0 ? "down" : "unchanged") \(abs(delta))\(isPercentage ? " percent" : "")")
    }

    // MARK: - Metrics Grid

    private func metricsGrid(_ summary: WeeklySummary) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Spacing.md) {
            // Volume
            metricCard(
                title: LocalizedStrings.Analytics.volume,
                value: summary.formattedVolume,
                icon: "scalemass.fill",
                color: .modusCyan,
                changePercent: summary.volumeChangePercent
            )

            // Streak
            metricCard(
                title: LocalizedStrings.Analytics.streak,
                value: "\(summary.currentStreak) \(LocalizedStrings.Analytics.days)",
                icon: "flame.fill",
                color: summary.streakMaintained ? .modusTealAccent : .secondary,
                changePercent: nil
            )

            // Top exercise
            if let topEx = summary.topExercise {
                metricCard(
                    title: "Star Exercise",
                    value: topEx,
                    icon: "star.fill",
                    color: .modusCyan,
                    changePercent: nil,
                    isText: true
                )
            }

            // Volume change (mini chart style)
            metricCard(
                title: LocalizedStrings.Analytics.vsLastWeek,
                value: "\(summary.volumeChangePercent >= 0 ? "+" : "")\(Int(summary.volumeChangePercent))%",
                icon: summary.volumeChangeEmoji,
                color: summary.volumeChangePercent >= 0 ? .modusTealAccent : .red,
                changePercent: nil
            )
        }
    }

    private func metricCard(
        title: String,
        value: String,
        icon: String,
        color: Color,
        changePercent: Double?,
        isText: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // Inline change arrow if provided
                if let pct = changePercent {
                    HStack(spacing: 2) {
                        Image(systemName: pct >= 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 8, weight: .bold))
                        Text("\(Int(abs(pct)))%")
                            .font(.caption2.bold())
                    }
                    .foregroundColor(pct >= 0 ? .modusTealAccent : .red)
                }
            }

            if isText {
                Text(value)
                    .font(.footnote.bold())
                    .foregroundColor(.primary)
                    .lineLimit(2)
            } else {
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
            }

            // Mini volume bar
            if changePercent != nil {
                GeometryReader { geo in
                    let barWidth = min(max(CGFloat(abs(changePercent ?? 0)) / 30.0, 0.1), 1.0)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [(changePercent ?? 0) >= 0 ? Color.modusTealAccent : Color.red,
                                         (changePercent ?? 0) >= 0 ? Color.modusCyan : Color.red.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * barWidth, height: 3)
                }
                .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Key Wins Section (ACP-1028)

    private func keyWinsSection(_ summary: WeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.modusCyan)
                    .accessibilityHidden(true)
                Text(LocalizedStrings.SectionHeaders.keyWins)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
            }

            if summary.wins.isEmpty {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.secondary)
                    Text("Keep going -- your wins are building")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color(.secondarySystemBackground))
                )
            } else {
                VStack(spacing: Spacing.xs) {
                    ForEach(Array(summary.wins.enumerated()), id: \.element) { index, win in
                        HStack(spacing: Spacing.sm) {
                            // Numbered badge
                            ZStack {
                                Circle()
                                    .fill(Color.modusTealAccent.opacity(0.15))
                                    .frame(width: 28, height: 28)
                                Text("\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundColor(.modusTealAccent)
                            }
                            .accessibilityHidden(true)

                            Text(win)
                                .font(.subheadline)
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundColor(.modusTealAccent)
                                .accessibilityHidden(true)
                        }
                        .padding(.vertical, Spacing.xs)
                        .padding(.horizontal, Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .fill(Color.modusTealAccent.opacity(0.06))
                        )
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Win \(index + 1): \(win)")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Areas to Focus Section (ACP-1028)

    private func areasToFocusSection(_ summary: WeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "scope")
                    .foregroundColor(.modusDeepTeal)
                    .accessibilityHidden(true)
                Text(LocalizedStrings.SectionHeaders.areasToFocus)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
            }

            VStack(spacing: Spacing.xs) {
                ForEach(summary.improvementAreas, id: \.self) { area in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "target")
                            .foregroundColor(.modusDeepTeal)
                            .font(.system(size: 16))
                            .accessibilityHidden(true)

                        Text(area)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        Spacer()
                    }
                    .padding(.vertical, Spacing.xs)
                    .padding(.horizontal, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color.modusDeepTeal.opacity(0.06))
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Focus area: \(area)")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Next Week Plan (ACP-1028)

    private func nextWeekPlanSection(_ summary: WeeklySummary) -> some View {
        let suggestions = summary.nextWeekSuggestions(for: userMode)

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .foregroundColor(.modusCyan)
                    .accessibilityHidden(true)
                Text(LocalizedStrings.SectionHeaders.nextWeekPlan)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
            }

            VStack(spacing: Spacing.xs) {
                ForEach(suggestions) { suggestion in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: suggestion.icon)
                            .foregroundColor(suggestion.priority.color)
                            .font(.system(size: 16))
                            .frame(width: 24)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.text)
                                .font(.subheadline)
                                .foregroundColor(.primary)

                            Text(suggestion.priority.label)
                                .font(.caption2)
                                .foregroundColor(suggestion.priority.color)
                        }

                        Spacer()
                    }
                    .padding(.vertical, Spacing.xs)
                    .padding(.horizontal, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color(.secondarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.sm)
                                    .strokeBorder(suggestion.priority.color.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(suggestion.priority.label) suggestion: \(suggestion.text)")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Motivational Insight (ACP-1028)

    private func motivationalInsightCard(_ summary: WeeklySummary) -> some View {
        let insight = summary.motivationalInsight(for: userMode)

        return VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.modusCyan)
                Text(LocalizedStrings.SectionHeaders.weeklyInsight)
                    .font(.caption.bold())
                    .foregroundColor(.modusCyan)
                Spacer()
            }

            HStack(spacing: Spacing.sm) {
                Image(systemName: insight.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.modusTealAccent)
                    .frame(width: 36)
                    .accessibilityHidden(true)

                Text(insight.text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [Color.modusLightTeal, Color(.secondarySystemBackground)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .strokeBorder(Color.modusTealAccent.opacity(0.2), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weekly insight: \(insight.text)")
    }

    // MARK: - Notification Settings

    private var notificationSettings: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.modusDeepTeal)
                Text(LocalizedStrings.SectionHeaders.weeklyNotifications)
                    .font(.headline)
            }

            NavigationLink {
                WeeklySummaryPreferencesView(patientId: patientId)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(viewModel.preferences?.notificationEnabled == true ? LocalizedStrings.Status.enabled : LocalizedStrings.Status.disabled)
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)

                        if let prefs = viewModel.preferences, prefs.notificationEnabled {
                            Text(prefs.notificationTimeDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
    }

    // MARK: - History Button

    private var historyButton: some View {
        NavigationLink {
            WeeklySummaryHistoryView(patientId: patientId)
        } label: {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.modusCyan)
                Text(LocalizedStrings.Common.viewHistory)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.modusCyan)
            Text(LocalizedStrings.LoadingStates.loadingYourWeek)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Error View

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text(LocalizedStrings.ErrorStates.couldntLoadSummary)
                .font(.headline)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(LocalizedStrings.ErrorStates.tryAgain) {
                Task {
                    await viewModel.refresh()
                }
            }
            .buttonStyle(.bordered)
            .tint(.modusCyan)
        }
        .padding()
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label(LocalizedStrings.EmptyStates.noDataYet, systemImage: "figure.run")
        } description: {
            Text(LocalizedStrings.EmptyStates.completeWorkoutsToSee)
        } actions: {
            Button {
                dismiss()
            } label: {
                Label("Start Training", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.modusCyan)
        }
    }
}

// MARK: - ViewModel

@MainActor
class WeeklySummaryViewModel: ObservableObject {
    let patientId: UUID

    @Published var currentSummary: WeeklySummary?
    @Published var previousSummary: WeeklySummary?
    @Published var preferences: WeeklySummaryPreferences?
    @Published var isLoading = false
    @Published var error: Error?

    private var weekOffset: Int = 0

    init(patientId: UUID) {
        self.patientId = patientId
    }

    func loadData() async {
        isLoading = true
        error = nil

        do {
            async let summaryTask = WeeklySummaryService.shared.fetchCurrentWeekSummary(for: patientId)
            async let previousTask = WeeklySummaryService.shared.fetchPreviousWeekSummary(for: patientId)
            async let prefsTask = WeeklySummaryService.shared.fetchPreferences(for: patientId)

            let (summary, previous, prefs) = try await (summaryTask, previousTask, prefsTask)
            currentSummary = summary
            previousSummary = previous
            preferences = prefs
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func refresh() async {
        await loadData()
    }

    func selectWeek(offset: Int) async {
        weekOffset = offset
        isLoading = true
        error = nil

        do {
            if offset == 0 {
                currentSummary = try await WeeklySummaryService.shared.fetchCurrentWeekSummary(for: patientId)
            } else {
                currentSummary = try await WeeklySummaryService.shared.fetchPreviousWeekSummary(for: patientId)
            }
        } catch {
            self.error = error
        }

        isLoading = false
    }

    /// Week-over-week comparison data
    var weekComparison: WeekComparison {
        guard let current = currentSummary, let previous = previousSummary else {
            return .empty
        }
        return WeekComparison.compare(current: current, previous: previous)
    }
}

// MARK: - Preview

#Preview {
    WeeklySummaryView(patientId: UUID(), userMode: .strength)
}
