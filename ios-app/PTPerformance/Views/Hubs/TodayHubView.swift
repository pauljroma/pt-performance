//
//  TodayHubView.swift
//  PTPerformance
//
//  BUILD 318: Tab Consolidation - Today Hub
//  BUILD ACP-843: Added Weekly Summary integration
//  ACP-836: Added Streak Tracking integration
//  ACP-501: One-Tap Start Today's Workout integration
//  ACP-522: Added Arm Care Assessment integration
//  Primary tab combining Today's workout, Quick Pick access, Timers, Readiness prompts, Streaks, and Arm Care
//

import SwiftUI

/// Today Hub View - Primary tab for daily workout focus
/// Combines TodaySessionView with quick access to Quick Pick, Timers, Readiness, and Streaks
/// ACP-501: Integrates QuickStartService for one-tap workout start
struct TodayHubView: View {
    // MARK: - Environment

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var supabase: PTSupabaseClient
    @EnvironmentObject var storeKit: StoreKitService

    // MARK: - State

    @State private var showQuickPick = false
    @State private var showTimers = false
    @State private var showWeeklySummary = false
    @State private var showStreakDashboard = false
    @State private var showArmCareAssessment = false  // ACP-522: Arm Care Assessment
    @State private var showDailyCheckIn = false       // X2Index: Daily Check-in
    @StateObject private var streakViewModel = StreakIndicatorViewModel()

    // ACP-501: Quick Start state
    @StateObject private var quickStartService = QuickStartService.shared
    @State private var showQuickStartWorkout = false
    @State private var quickStartSession: Session?
    @State private var quickStartExercises: [Exercise] = []
    @State private var quickStartError: String?
    @State private var showQuickStartError = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            TodaySessionView()
                .environmentObject(appState)
                .environmentObject(supabase)
                .toolbar {
                    // ACP-836: Streak indicator in leading position
                    ToolbarItem(placement: .navigationBarLeading) {
                        streakIndicatorButton
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        quickAccessMenu
                    }
                }
                .sheetWithHaptic(isPresented: $showQuickPick) {
                    WorkoutPickerView()
                        .environmentObject(appState)
                }
                .sheetWithHaptic(isPresented: $showTimers) {
                    if let patientIdString = supabase.userId,
                       let patientId = UUID(uuidString: patientIdString) {
                        NavigationStack {
                            TimerPickerView(patientId: patientId)
                        }
                    }
                }
                .sheetWithHaptic(isPresented: $showWeeklySummary) {
                    if let patientIdString = supabase.userId,
                       let patientId = UUID(uuidString: patientIdString) {
                        WeeklySummaryView(patientId: patientId)
                    }
                }
                .sheetWithHaptic(isPresented: $showStreakDashboard) {
                    if let patientIdString = supabase.userId,
                       let patientId = UUID(uuidString: patientIdString) {
                        NavigationStack {
                            StreakDashboardView(patientId: patientId)
                        }
                    }
                }
                // ACP-522: Arm Care Assessment sheet
                .sheetWithHaptic(isPresented: $showArmCareAssessment) {
                    if let patientIdString = supabase.userId,
                       let patientId = UUID(uuidString: patientIdString) {
                        ArmCareAssessmentView(patientId: patientId)
                    }
                }
                // X2Index: Daily Check-in - now uses compact ReadinessCheckInView
                .sheetWithHaptic(isPresented: $showDailyCheckIn) {
                    if let patientIdString = supabase.userId,
                       let patientId = UUID(uuidString: patientIdString) {
                        ReadinessCheckInView(patientId: patientId)
                    }
                }
                // ACP-501: Quick Start Workout Full Screen Cover
                .fullScreenCoverWithHaptic(isPresented: $showQuickStartWorkout) {
                    if let session = quickStartSession,
                       let patientIdString = supabase.userId,
                       let patientId = UUID(uuidString: patientIdString) {
                        ManualWorkoutExecutionView(
                            prescribedSession: session,
                            exercises: quickStartExercises,
                            patientId: patientId,
                            onComplete: {
                                showQuickStartWorkout = false
                                quickStartSession = nil
                                quickStartExercises = []
                                // Clear cache after workout completion
                                quickStartService.clearCache()
                            }
                        )
                        .environmentObject(supabase)
                    }
                }
                // ACP-501: Quick Start Error Alert
                .alert("Couldn't Start Workout", isPresented: $showQuickStartError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(quickStartError ?? "An unexpected error occurred.")
                }
                .onReceive(NotificationCenter.default.publisher(for: .showWeeklySummary)) { _ in
                    showWeeklySummary = true
                }
                // ACP-501: Listen for quick start deep link
                .onReceive(NotificationCenter.default.publisher(for: .quickStartWorkout)) { _ in
                    Task {
                        await handleQuickStart()
                    }
                }
                .task {
                    // Load streak data when view appears
                    if let patientIdString = supabase.userId,
                       let patientId = UUID(uuidString: patientIdString) {
                        await streakViewModel.loadData(for: patientId)
                    }

                    // ACP-501: Pre-load quick start data for faster response
                    _ = await quickStartService.prepareQuickStart()
                }
                // ACP-501: Handle deep link for starting workout
                .onChange(of: appState.pendingDeepLink) { _, newValue in
                    if case .startWorkout = newValue {
                        appState.pendingDeepLink = nil
                        Task {
                            await handleQuickStart()
                        }
                    }
                }
        }
    }

    // MARK: - ACP-501: Quick Start Handler

    /// Handle one-tap quick start - no dialogs, no confirmation
    private func handleQuickStart() async {
        HapticFeedback.medium()

        let result = await quickStartService.prepareQuickStart()

        switch result {
        case .ready(let session, let exercises):
            // Immediately start the workout - no confirmation needed
            quickStartSession = session
            quickStartExercises = exercises
            showQuickStartWorkout = true
            DebugLogger.shared.log("🚀 [QuickStart] Starting workout: \(session.name)", level: .success)

        case .multipleWorkouts(let session, let exercises, let remainingCount):
            // Start the first uncompleted workout, inform user about remaining
            quickStartSession = session
            quickStartExercises = exercises
            showQuickStartWorkout = true
            DebugLogger.shared.log("🚀 [QuickStart] Starting first of \(remainingCount + 1) workouts: \(session.name)", level: .success)

        case .noWorkoutToday:
            quickStartError = "No workout scheduled for today. Check your program schedule or start a manual workout."
            showQuickStartError = true

        case .alreadyCompleted(let session):
            quickStartError = "Great job! You've already completed \(session.name) today. Want to do another workout? Use the workout library."
            showQuickStartError = true

        case .error(let error):
            quickStartError = error.recoverySuggestion ?? error.localizedDescription
            showQuickStartError = true
        }
    }

    // MARK: - Streak Indicator Button

    private var streakIndicatorButton: some View {
        Button(action: {
            HapticFeedback.light()
            showStreakDashboard = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundColor(streakViewModel.isAtRisk ? .orange : .red)
                    .font(.system(size: 14))

                Text("\(streakViewModel.currentStreak)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .accessibilityLabel("Current streak: \(streakViewModel.currentStreak) days")
        .accessibilityHint("Tap to view streak dashboard")
    }

    // MARK: - Quick Access Menu

    private var quickAccessMenu: some View {
        Menu {
            Button(action: {
                HapticFeedback.light()
                showQuickPick = true
            }) {
                Label("AI Quick Pick", systemImage: "sparkles")
            }

            Button(action: {
                HapticFeedback.light()
                showTimers = true
            }) {
                Label("Timers", systemImage: "timer")
            }

            Divider()

            // Daily Check-in - uses compact ReadinessCheckInView
            Button(action: {
                HapticFeedback.light()
                showDailyCheckIn = true
            }) {
                Label("Daily Check-in", systemImage: "heart.text.square")
            }

            Button(action: {
                HapticFeedback.light()
                showWeeklySummary = true
            }) {
                Label("Weekly Summary", systemImage: "chart.bar.fill")
            }

            // ACP-836: Streak dashboard menu item
            Button(action: {
                HapticFeedback.light()
                showStreakDashboard = true
            }) {
                Label("Streak Dashboard", systemImage: "flame.fill")
            }

            Divider()

            // ACP-522: Arm Care Assessment menu item
            Button(action: {
                HapticFeedback.light()
                showArmCareAssessment = true
            }) {
                Label("Arm Care Check", systemImage: "figure.baseball")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 18))
                .foregroundColor(.primary)
        }
        .accessibilityLabel("Quick Actions")
        .accessibilityHint("Access Quick Pick, Timers, Daily Check-in, Weekly Summary, Streaks, and Arm Care")
    }
}

// MARK: - Streak Indicator ViewModel

@MainActor
class StreakIndicatorViewModel: ObservableObject {
    @Published var currentStreak = 0
    @Published var isAtRisk = true

    private let service = StreakTrackingService.shared

    func loadData(for patientId: UUID) async {
        do {
            if let streak = try await service.getCombinedStreak(for: patientId) {
                currentStreak = streak.currentStreak
                isAtRisk = streak.isAtRisk
            }
        } catch {
            DebugLogger.shared.warning("TodayHubView", "Error loading streak: \(error.localizedDescription)")
        }
    }
}

// MARK: - ACP-501: Quick Start Notification

extension Notification.Name {
    /// Notification to trigger quick start from external sources (widgets, Siri, etc.)
    static let quickStartWorkout = Notification.Name("quickStartWorkout")
}

// MARK: - Preview

#Preview {
    TodayHubView()
        .environmentObject(AppState())
        .environmentObject(PTSupabaseClient.shared)
        .environmentObject(StoreKitService.shared)
}
