//
//  StrengthModeContentModifier.swift
//  PTPerformance
//
//  Strength Mode Content Modifier - Conditionally shows Strength-specific UI
//  Adds strength status card and PR celebration overlay when in Strength mode
//

import SwiftUI

/// View modifier that adds Strength-specific content when user is in Strength mode
struct StrengthModeContentModifier: ViewModifier {
    @ObservedObject private var modeService = ModeService.shared

    let patientId: UUID?

    // MARK: - State

    @State private var showStrengthStatusCard = true
    @State private var showStrengthDashboard = false
    @State private var prCelebrationData: PRCelebrationData?
    @State private var showPRHistory = false
    @State private var isLoadingStrengthData = false

    // Strength data state
    @State private var estimatedTotal: Double?
    @State private var topLifts: [TopLiftInfo] = []
    @State private var recentPRs: [RecentPRInfo] = []
    @State private var volumeTrend: VolumeTrend = .unknown
    @State private var currentStreak: Int = 0
    @State private var unit: String = WeightUnit.defaultUnit

    // MARK: - Body

    func body(content: Content) -> some View {
        if modeService.currentMode == .strength {
            content
                .safeAreaInset(edge: .top) {
                    if showStrengthStatusCard {
                        strengthStatusCardSection
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .sheet(isPresented: $showStrengthDashboard) {
                    strengthDashboardSheet
                }
                .sheet(isPresented: $showPRHistory) {
                    prHistorySheet
                }
                .fullScreenCover(item: $prCelebrationData) { data in
                    PRCelebrationView(
                        data: data,
                        onDismiss: {
                            prCelebrationData = nil
                        }
                    )
                }
                .overlay {
                    if isLoadingStrengthData {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .background(Color.clear)
                    }
                }
                .task {
                    await loadStrengthData()
                }
                .onReceive(NotificationCenter.default.publisher(for: .strengthPRHit)) { notification in
                    handlePRNotification(notification)
                }
        } else {
            content
        }
    }

    // MARK: - Strength Status Card Section

    private var strengthStatusCardSection: some View {
        VStack(spacing: 0) {
            StrengthModeStatusCard(
                estimatedTotal: estimatedTotal,
                topLifts: topLifts,
                recentPRs: recentPRs,
                volumeTrend: volumeTrend,
                currentStreak: currentStreak,
                unit: unit,
                onTapCard: {
                    HapticFeedback.light()
                    showStrengthDashboard = true
                },
                onViewPRs: {
                    HapticFeedback.light()
                    showPRHistory = true
                },
                onViewVolume: {
                    HapticFeedback.light()
                    showStrengthDashboard = true
                }
            )
            .padding(.horizontal)
            .padding(.top, Spacing.xs)
            .padding(.bottom, Spacing.sm)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Strength Dashboard Sheet

    @ViewBuilder
    private var strengthDashboardSheet: some View {
        if let patientId = patientId {
            NavigationStack {
                StrengthModeDashboardView(patientId: patientId)
            }
        } else {
            NavigationStack {
                Text("Unable to load dashboard")
                    .foregroundColor(.secondary)
                    .navigationTitle("Strength Dashboard")
            }
        }
    }

    // MARK: - PR History Sheet

    private var prHistorySheet: some View {
        NavigationStack {
            PRHistoryListView(patientId: patientId, recentPRs: recentPRs)
                .navigationTitle("Personal Records")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showPRHistory = false
                        }
                    }
                }
        }
    }

    // MARK: - Data Loading

    private func loadStrengthData() async {
        guard let patientId = patientId else { return }

        isLoadingStrengthData = true
        defer { isLoadingStrengthData = false }

        // Fetch big lifts summary once and share result across PR and top-lift processing
        let allSummaries: [BigLiftSummary]
        do {
            allSummaries = try await BigLiftsService.shared.fetchBigLiftsSummary(patientId: patientId)
        } catch {
            DebugLogger.shared.log("Failed to fetch big lifts summary: \(error)", level: .warning)
            allSummaries = []
        }

        // Run all four processing steps in parallel
        async let streakResult: Void = loadStreakData(for: patientId)
        async let prResult: Void = loadPRData(from: allSummaries)
        async let volumeResult: Void = loadVolumeData(for: patientId)
        async let topLiftsResult: Void = loadTopLifts(from: allSummaries, patientId: patientId)

        _ = await (streakResult, prResult, volumeResult, topLiftsResult)
    }

    private func loadStreakData(for patientId: UUID) async {
        do {
            let streakService = StreakTrackingService.shared
            if let streak = try await streakService.getCombinedStreak(for: patientId) {
                currentStreak = streak.currentStreak
            }
        } catch {
            DebugLogger.shared.log("Failed to load streak data: \(error)", level: .warning)
        }
    }

    private func loadPRData(from summaries: [BigLiftSummary]) async {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        recentPRs = summaries.compactMap { summary in
            guard let prDate = summary.lastPrDate, prDate >= sevenDaysAgo else {
                return nil
            }
            // Calculate improvement from the 30-day improvement percentage if available
            let improvement: Double? = summary.improvementPct30d.map { pct in
                summary.currentMaxWeight * pct / (100.0 + pct)
            }
            return RecentPRInfo(
                exerciseName: summary.exerciseName,
                weight: summary.currentMaxWeight,
                unit: summary.loadUnit,
                date: prDate,
                improvement: improvement
            )
        }
        .sorted { $0.date > $1.date }

        DebugLogger.shared.log("Loaded \(recentPRs.count) recent PRs", level: .diagnostic)
    }

    private func loadVolumeData(for patientId: UUID) async {
        do {
            let volumeService = VolumeAnalyticsService()
            // Fetch two weeks of volume data to compare current vs previous week
            let dataPoints = try await volumeService.fetchVolumeTimeSeries(
                patientId: patientId.uuidString,
                period: .month
            )

            // Need at least two data points (weeks) to compute a trend
            guard dataPoints.count >= 2 else {
                volumeTrend = .unknown
                return
            }

            let currentWeek = dataPoints[dataPoints.count - 1].totalVolume
            let previousWeek = dataPoints[dataPoints.count - 2].totalVolume

            if previousWeek > 0 {
                let percentageChange = ((currentWeek - previousWeek) / previousWeek) * 100.0
                if abs(percentageChange) < VolumeTrendThreshold.stablePercent {
                    volumeTrend = .stable
                } else if percentageChange > 0 {
                    volumeTrend = .up(percentage: percentageChange)
                } else {
                    volumeTrend = .down(percentage: percentageChange)
                }
            } else if currentWeek > 0 {
                volumeTrend = .up(percentage: 100.0)
            } else {
                volumeTrend = .unknown
            }

            DebugLogger.shared.log("Volume trend calculated: \(volumeTrend)", level: .diagnostic)
        } catch {
            DebugLogger.shared.log("Failed to load volume data: \(error)", level: .warning)
            volumeTrend = .unknown
        }
    }

    private func loadTopLifts(from allSummaries: [BigLiftSummary], patientId: UUID) async {
        // Filter to core lifts only from the already-fetched summaries
        let coreNames = ["Squat", "Back Squat", "Bench Press", "Deadlift"]
        let summaries = allSummaries.filter { summary in
            coreNames.contains(where: { summary.exerciseName.localizedCaseInsensitiveContains($0) })
        }

        // Convert to TopLiftInfo for display
        topLifts = summaries.map { lift in
            TopLiftInfo(
                exerciseName: lift.exerciseName,
                weight: lift.estimated1rm,
                unit: lift.loadUnit
            )
        }

        // Calculate estimated total from core lifts
        estimatedTotal = summaries.isEmpty ? nil : summaries.reduce(0) { $0 + $1.estimated1rm }

        // Use the unit from the first summary if available
        if let firstUnit = summaries.first?.loadUnit {
            unit = firstUnit
        }

        DebugLogger.shared.log("Loaded \(topLifts.count) top lifts, estimated total: \(estimatedTotal ?? 0)", level: .diagnostic)
    }

    // MARK: - PR Notification Handler

    private func handlePRNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let exerciseName = userInfo["exerciseName"] as? String,
              let newWeight = userInfo["newWeight"] as? Double else {
            return
        }

        let previousWeight = userInfo["previousWeight"] as? Double
        let improvement = userInfo["improvement"] as? Double
        let prUnit = userInfo["unit"] as? String ?? unit

        // Determine PR type
        let prType: PRCelebrationType
        if previousWeight == nil {
            prType = .firstPR
        } else if let imp = improvement, imp >= 20 {
            prType = .majorPR
        } else if isMilestoneWeight(newWeight, unit: prUnit) {
            prType = .milestonePR
        } else {
            prType = .newPR
        }

        // Create celebration data (setting this triggers the fullScreenCover via item binding)
        prCelebrationData = PRCelebrationData(
            exerciseName: exerciseName,
            newWeight: newWeight,
            previousWeight: previousWeight,
            improvement: improvement,
            unit: prUnit,
            type: prType
        )

        // Add to recent PRs
        let newPR = RecentPRInfo(
            exerciseName: exerciseName,
            weight: newWeight,
            unit: prUnit,
            date: Date(),
            improvement: improvement
        )
        recentPRs.insert(newPR, at: 0)

        // Keep only last 7 days of PRs
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        recentPRs = recentPRs.filter { $0.date >= sevenDaysAgo }
    }

    private func isMilestoneWeight(_ weight: Double, unit: String) -> Bool {
        // Check for milestone weights (plates milestones)
        let milestones: [Double]
        if unit.lowercased().contains("kg") {
            milestones = [100, 140, 180, 200, 220, 250, 300] // kg milestones
        } else {
            milestones = [135, 225, 315, 405, 495, 585, 675] // lbs plate milestones
        }
        return milestones.contains(weight)
    }
}

// MARK: - View Extension

extension View {
    /// Adds Strength mode-specific content when the user is in Strength mode
    /// Shows strength status card, PR celebrations, and quick access to strength features
    func strengthModeContent(patientId: UUID?) -> some View {
        modifier(StrengthModeContentModifier(patientId: patientId))
    }
}

// MARK: - PR History List View

/// List view showing PR history
struct PRHistoryListView: View {
    let patientId: UUID?
    let recentPRs: [RecentPRInfo]

    var body: some View {
        List {
            if recentPRs.isEmpty {
                emptyState
            } else {
                ForEach(recentPRs) { pr in
                    PRHistoryRow(
                        exerciseName: pr.exerciseName,
                        currentPR: pr.weight,
                        previousPR: pr.improvement != nil ? pr.weight - (pr.improvement ?? 0) : nil,
                        date: pr.date,
                        unit: pr.unit
                    )
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "trophy")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Recent PRs")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Hit a new personal record and it will show up here!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Notification posted when a PR is hit during a workout
    static let strengthPRHit = Notification.Name("strengthPRHit")
}

// MARK: - Previews

#Preview("Strength Content Modifier") {
    NavigationStack {
        ScrollView {
            VStack(spacing: 16) {
                Text("Today's Workout")
                    .font(.title)

                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .frame(height: 80)
                        .overlay(Text("Exercise \(i + 1)"))
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Today")
    }
    .strengthModeContent(patientId: UUID())
}

#Preview("Strength Dashboard") {
    NavigationStack {
        StrengthModeDashboardView(patientId: UUID())
    }
}

#Preview("PR History") {
    NavigationStack {
        PRHistoryListView(
            patientId: UUID(),
            recentPRs: [
                RecentPRInfo(exerciseName: "Squat", weight: 455, unit: "lbs", date: Date(), improvement: 10),
                RecentPRInfo(exerciseName: "Bench Press", weight: 315, unit: "lbs", date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, improvement: 5),
                RecentPRInfo(exerciseName: "Deadlift", weight: 495, unit: "lbs", date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, improvement: 15)
            ]
        )
        .navigationTitle("Personal Records")
    }
}

#Preview("PR History Empty") {
    NavigationStack {
        PRHistoryListView(
            patientId: UUID(),
            recentPRs: []
        )
        .navigationTitle("Personal Records")
    }
}
