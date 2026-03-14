// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  TodayHubView.swift
//  PTPerformance
//
//  BUILD 318: Tab Consolidation - Today Hub
//  BUILD ACP-843: Added Weekly Summary integration
//  ACP-836: Added Streak Tracking integration
//  ACP-501: One-Tap Start Today's Workout integration
//  ACP-522: Added Arm Care Assessment integration
//  ACP-MODE: Added mode-specific dashboard navigation
//  Primary tab combining Today's workout, Quick Pick access, Timers, Readiness prompts, Streaks, and Arm Care
//

import SwiftUI

// MARK: - TodayHubViewState

/// Extracted state for TodayHubView - consolidates 14 @State properties into a single ObservableObject
@MainActor
class TodayHubViewState: ObservableObject {
    // Sheet presentation states
    @Published var showQuickPick = false
    @Published var showTimers = false
    @Published var showWeeklySummary = false
    @Published var showStreakDashboard = false
    @Published var showArmCareAssessment = false  // ACP-522: Arm Care Assessment
    @Published var showDailyCheckIn = false       // X2Index: Daily Check-in

    // ACP-MODE: Mode-specific dashboard navigation state
    @Published var showRehabDashboard = false
    @Published var showStrengthDashboard = false
    @Published var showPerformanceDashboard = false

    // ACP-501: Quick Start state
    @Published var showQuickStartWorkout = false
    @Published var quickStartSession: Session?
    @Published var quickStartExercises: [Exercise] = []
    @Published var quickStartError: String?
    @Published var showQuickStartError = false
}

/// Today Hub View - Primary tab for daily workout focus
/// Combines TodaySessionView with quick access to Quick Pick, Timers, Readiness, and Streaks
/// ACP-501: Integrates QuickStartService for one-tap workout start
struct TodayHubView: View {
    // MARK: - Environment

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var supabase: PTSupabaseClient
    @EnvironmentObject var storeKit: StoreKitService
    @EnvironmentObject private var modeService: ModeService

    // MARK: - State

    @StateObject private var state = TodayHubViewState()
    @StateObject private var streakViewModel = StreakIndicatorViewModel()

    // ACP-MODE: Mode-specific status card data
    @StateObject private var modeStatusViewModel = ModeStatusCardViewModel()

    // ACP-501: Quick Start service
    @StateObject private var quickStartService = QuickStartService.shared

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
                }
                .sheetWithHaptic(isPresented: $state.showQuickPick) {
                    WorkoutPickerView()
                        .environmentObject(appState)
                }
                .sheetWithHaptic(isPresented: $state.showTimers) {
                    if let patientIdString = supabase.userId,
                       let patientId = UUID(uuidString: patientIdString) {
                        NavigationStack {
                            TimerPickerView(patientId: patientId)
                        }
                    }
                }
                .sheetWithHaptic(isPresented: $state.showWeeklySummary) {
                    if let patientIdString = supabase.userId,
                       let patientId = UUID(uuidString: patientIdString) {
                        WeeklySummaryView(patientId: patientId)
                    }
                }
                .sheetWithHaptic(isPresented: $state.showStreakDashboard) {
                    if let patientIdString = supabase.userId,
                       let patientId = UUID(uuidString: patientIdString) {
                        NavigationStack {
                            StreakDashboardView(patientId: patientId)
                        }
                    }
                }
                // ACP-522: Arm Care Assessment sheet
                .sheetWithHaptic(isPresented: $state.showArmCareAssessment) {
                    if let patientIdString = supabase.userId,
                       let patientId = UUID(uuidString: patientIdString) {
                        ArmCareAssessmentView(patientId: patientId)
                    }
                }
                // X2Index: Daily Check-in - now uses compact ReadinessCheckInView
                .sheetWithHaptic(isPresented: $state.showDailyCheckIn) {
                    if let patientIdString = supabase.userId,
                       let patientId = UUID(uuidString: patientIdString) {
                        ReadinessCheckInView(patientId: patientId)
                    }
                }
                // ACP-MODE: Mode-specific dashboard sheets (gated by feature flag)
                .sheetWithHaptic(isPresented: Binding(
                    get: { Config.MVPConfig.modeDashboardsEnabled && state.showRehabDashboard },
                    set: { state.showRehabDashboard = $0 }
                )) {
                    NavigationStack {
                        RehabModeDashboardView()
                            .environmentObject(appState)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") {
                                        state.showRehabDashboard = false
                                    }
                                }
                            }
                    }
                }
                .sheetWithHaptic(isPresented: Binding(
                    get: { Config.MVPConfig.modeDashboardsEnabled && state.showStrengthDashboard },
                    set: { state.showStrengthDashboard = $0 }
                )) {
                    if let patientIdString = supabase.userId,
                       let patientId = UUID(uuidString: patientIdString) {
                        NavigationStack {
                            StrengthModeDashboardView(patientId: patientId)
                                .environmentObject(appState)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button("Done") {
                                            state.showStrengthDashboard = false
                                        }
                                    }
                                }
                        }
                    }
                }
                .sheetWithHaptic(isPresented: Binding(
                    get: { Config.MVPConfig.modeDashboardsEnabled && state.showPerformanceDashboard },
                    set: { state.showPerformanceDashboard = $0 }
                )) {
                    if let patientIdString = supabase.userId,
                       let patientId = UUID(uuidString: patientIdString) {
                        NavigationStack {
                            PerformanceModeDashboardView(patientId: patientId)
                                .environmentObject(appState)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button("Done") {
                                            state.showPerformanceDashboard = false
                                        }
                                    }
                                }
                        }
                    }
                }
                // ACP-501: Quick Start Workout Full Screen Cover
                .fullScreenCoverWithHaptic(isPresented: $state.showQuickStartWorkout) {
                    if let session = state.quickStartSession,
                       let patientIdString = supabase.userId,
                       let patientId = UUID(uuidString: patientIdString) {
                        ManualWorkoutExecutionView(
                            prescribedSession: session,
                            exercises: state.quickStartExercises,
                            patientId: patientId,
                            onComplete: {
                                state.showQuickStartWorkout = false
                                state.quickStartSession = nil
                                state.quickStartExercises = []
                                // Clear cache after workout completion
                                quickStartService.clearCache()
                            }
                        )
                        .environmentObject(supabase)
                    }
                }
                // ACP-501: Quick Start Error Alert
                .alert("Couldn't Start Workout", isPresented: $state.showQuickStartError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(state.quickStartError ?? "An unexpected error occurred.")
                }
                .onReceive(NotificationCenter.default.publisher(for: .showWeeklySummary)) { _ in
                    state.showWeeklySummary = true
                }
                // ACP-501: Listen for quick start deep link
                .onReceive(NotificationCenter.default.publisher(for: .quickStartWorkout)) { _ in
                    Task {
                        await handleQuickStart()
                    }
                }
                .task(id: supabase.userId) {
                    guard let patientIdString = supabase.userId,
                          let patientId = UUID(uuidString: patientIdString) else { return }
                    // Load streak data, mode status, and quick start in parallel
                    async let a: () = streakViewModel.loadData(for: patientId)
                    // ACP-MODE: Load mode-specific status card data
                    async let b: () = modeStatusViewModel.loadData(for: patientId)
                    // ACP-501: Pre-load quick start data for faster response
                    async let c: Void = { _ = await quickStartService.prepareQuickStart() }()
                    _ = await (a, b, c)
                }
                // ACP-501: Handle deep links for Today Hub context
                .onChange(of: appState.pendingDeepLink) { _, newValue in
                    guard let newValue else { return }

                    switch newValue {
                    case .startWorkout:
                        appState.pendingDeepLink = nil
                        Task {
                            await handleQuickStart()
                        }

                    case .streak:
                        appState.pendingDeepLink = nil
                        state.showStreakDashboard = true

                    case .today:
                        // Already on Today tab — just consume the deep link
                        appState.pendingDeepLink = nil

                    case .logExercise:
                        appState.pendingDeepLink = nil
                        state.showQuickPick = true

                    case .restTimer:
                        appState.pendingDeepLink = nil
                        state.showTimers = true

                    default:
                        // Other deep links handled by PatientTabView
                        break
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
            state.quickStartSession = session
            state.quickStartExercises = exercises
            state.showQuickStartWorkout = true
            DebugLogger.shared.log("🚀 [QuickStart] Starting workout: \(session.name)", level: .success)

        case .multipleWorkouts(let session, let exercises, let remainingCount):
            // Start the first uncompleted workout, inform user about remaining
            state.quickStartSession = session
            state.quickStartExercises = exercises
            state.showQuickStartWorkout = true
            DebugLogger.shared.log("🚀 [QuickStart] Starting first of \(remainingCount + 1) workouts: \(session.name)", level: .success)

        case .noWorkoutToday:
            state.quickStartError = "No workout scheduled for today. Check your program schedule or start a manual workout."
            state.showQuickStartError = true

        case .alreadyCompleted(let session):
            state.quickStartError = "Great job! You've already completed \(session.name) today. Want to do another workout? Use the workout library."
            state.showQuickStartError = true

        case .error(let error):
            state.quickStartError = error.recoverySuggestion ?? error.localizedDescription
            state.showQuickStartError = true
        }
    }

    // MARK: - Streak Indicator Button

    private var streakIndicatorButton: some View {
        Button(action: {
            HapticFeedback.light()
            state.showStreakDashboard = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundColor(streakViewModel.isAtRisk ? .orange : .modusTealAccent)
                    .font(.system(size: 14))

                Text("\(streakViewModel.currentStreak)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.modusDeepTeal)
            }
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(
                Capsule()
                    .fill(Color.modusSurface)
                    .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
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
                state.showQuickPick = true
            }) {
                Label("AI Quick Pick", systemImage: "sparkles")
            }

            Button(action: {
                HapticFeedback.light()
                state.showTimers = true
            }) {
                Label("Timers", systemImage: "timer")
            }

            Divider()

            // Daily Check-in - uses compact ReadinessCheckInView
            Button(action: {
                HapticFeedback.light()
                state.showDailyCheckIn = true
            }) {
                Label("Daily Check-in", systemImage: "heart.text.square")
            }

            Button(action: {
                HapticFeedback.light()
                state.showWeeklySummary = true
            }) {
                Label("Weekly Summary", systemImage: "chart.bar.fill")
            }

            // ACP-836: Streak dashboard menu item
            Button(action: {
                HapticFeedback.light()
                state.showStreakDashboard = true
            }) {
                Label("Streak Dashboard", systemImage: "flame.fill")
            }

            // ACP-522: Arm Care Assessment menu item - Rehab mode feature
            if Config.MVPConfig.armCareEnabled {
                Divider()

                Button(action: {
                    HapticFeedback.light()
                    state.showArmCareAssessment = true
                }) {
                    Label("Arm Care Check", systemImage: "figure.baseball")
                }
                .visibleIf(.romExercises)
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
        } catch where error.isCancellation {
            DebugLogger.shared.log("Streak load cancelled (navigation)", level: .diagnostic)
        } catch {
            DebugLogger.shared.warning("TodayHubView", "Error loading streak: \(error.localizedDescription)")
        }
    }
}

// NOTE: ModeStatusCardViewModel is defined in ViewModels/ModeStatusCardViewModel.swift

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
        .environmentObject(ModeService.shared)
}
