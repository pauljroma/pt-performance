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
    @State private var showPRCelebration = false
    @State private var prCelebrationData: PRCelebrationData?
    @State private var showPRHistory = false
    @State private var isLoading = false

    // Strength data state
    @State private var estimatedTotal: Double?
    @State private var topLifts: [TopLiftInfo] = []
    @State private var recentPRs: [RecentPRInfo] = []
    @State private var volumeTrend: VolumeTrend = .unknown
    @State private var currentStreak: Int = 0
    @State private var unit: String = "lbs"

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
                .fullScreenCover(isPresented: $showPRCelebration) {
                    if let data = prCelebrationData {
                        PRCelebrationView(
                            data: data,
                            onDismiss: {
                                showPRCelebration = false
                                prCelebrationData = nil
                            },
                            onShare: {
                                // TODO: Implement share functionality
                                HapticFeedback.light()
                            }
                        )
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
                }
            )
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)
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

        isLoading = true
        defer { isLoading = false }

        // Load streak data
        await loadStreakData(for: patientId)

        // Load PR data
        await loadPRData(for: patientId)

        // Load volume comparison
        await loadVolumeData(for: patientId)

        // Load top lifts / estimated total
        await loadTopLifts(for: patientId)
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

    private func loadPRData(for patientId: UUID) async {
        // TODO: Implement actual PR data loading from StrengthAnalyticsService
        // For now, this would query recent PRs from the database
        // recentPRs = try await strengthService.getRecentPRs(for: patientId, withinDays: 7)
    }

    private func loadVolumeData(for patientId: UUID) async {
        // TODO: Implement actual volume comparison
        // let comparison = try await analyticsService.compareWeeklyVolume(for: patientId)
        // volumeTrend = comparison.trend
    }

    private func loadTopLifts(for patientId: UUID) async {
        // TODO: Implement actual top lifts loading
        // let lifts = try await strengthService.getTopLifts(for: patientId)
        // topLifts = lifts
        // estimatedTotal = lifts.reduce(0) { $0 + $1.weight }
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

        // Create celebration data
        prCelebrationData = PRCelebrationData(
            exerciseName: exerciseName,
            newWeight: newWeight,
            previousWeight: previousWeight,
            improvement: improvement,
            unit: prUnit,
            type: prType
        )

        // Show celebration
        showPRCelebration = true

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
        VStack(spacing: 16) {
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
