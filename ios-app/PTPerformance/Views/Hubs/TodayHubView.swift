//
//  TodayHubView.swift
//  PTPerformance
//
//  BUILD 318: Tab Consolidation - Today Hub
//  BUILD ACP-843: Added Weekly Summary integration
//  ACP-836: Added Streak Tracking integration
//  Primary tab combining Today's workout, Quick Pick access, Timers, Readiness prompts, and Streaks
//

import SwiftUI

/// Today Hub View - Primary tab for daily workout focus
/// Combines TodaySessionView with quick access to Quick Pick, Timers, Readiness, and Streaks
struct TodayHubView: View {
    // MARK: - Environment

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var supabase: PTSupabaseClient
    @EnvironmentObject var storeKit: StoreKitService

    // MARK: - State

    @State private var showQuickPick = false
    @State private var showTimers = false
    @State private var showReadinessCheckIn = false
    @State private var showWeeklySummary = false
    @State private var showStreakDashboard = false
    @StateObject private var streakViewModel = StreakIndicatorViewModel()

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
                .sheet(isPresented: $showQuickPick) {
                    WorkoutPickerView()
                        .environmentObject(appState)
                }
                .sheet(isPresented: $showTimers) {
                    if let patientIdString = supabase.userId,
                       let patientId = UUID(uuidString: patientIdString) {
                        NavigationStack {
                            TimerPickerView(patientId: patientId)
                        }
                    }
                }
                .sheet(isPresented: $showReadinessCheckIn) {
                    if let patientIdString = supabase.userId,
                       let patientId = UUID(uuidString: patientIdString) {
                        ReadinessCheckInView(patientId: patientId)
                    }
                }
                .sheet(isPresented: $showWeeklySummary) {
                    if let patientIdString = supabase.userId,
                       let patientId = UUID(uuidString: patientIdString) {
                        WeeklySummaryView(patientId: patientId)
                    }
                }
                .sheet(isPresented: $showStreakDashboard) {
                    if let patientIdString = supabase.userId,
                       let patientId = UUID(uuidString: patientIdString) {
                        NavigationStack {
                            StreakDashboardView(patientId: patientId)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .showWeeklySummary)) { _ in
                    showWeeklySummary = true
                }
                .task {
                    // Load streak data when view appears
                    if let patientIdString = supabase.userId,
                       let patientId = UUID(uuidString: patientIdString) {
                        await streakViewModel.loadData(for: patientId)
                    }
                }
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
                    .fill(Color(.systemGray6))
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

            Button(action: {
                HapticFeedback.light()
                showReadinessCheckIn = true
            }) {
                Label("Readiness Check-In", systemImage: "heart.text.square")
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
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 18))
                .foregroundColor(.primary)
        }
        .accessibilityLabel("Quick Actions")
        .accessibilityHint("Access Quick Pick, Timers, Readiness Check-In, Weekly Summary, and Streaks")
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
            #if DEBUG
            print("[StreakIndicator] Error loading streak: \(error)")
            #endif
        }
    }
}

// MARK: - Preview

#Preview {
    TodayHubView()
        .environmentObject(AppState())
        .environmentObject(PTSupabaseClient.shared)
        .environmentObject(StoreKitService.shared)
}
