//
//  TodayHubView.swift
//  PTPerformance
//
//  BUILD 318: Tab Consolidation - Today Hub
//  Primary tab combining Today's workout, Quick Pick access, Timers, and Readiness prompts
//

import SwiftUI

/// Today Hub View - Primary tab for daily workout focus
/// Combines TodaySessionView with quick access to Quick Pick, Timers, and Readiness
struct TodayHubView: View {
    // MARK: - Environment

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var supabase: PTSupabaseClient
    @EnvironmentObject var storeKit: StoreKitService

    // MARK: - State

    @State private var showQuickPick = false
    @State private var showTimers = false
    @State private var showReadinessCheckIn = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            TodaySessionView()
                .environmentObject(appState)
                .environmentObject(supabase)
                .toolbar {
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
        }
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
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 18))
                .foregroundColor(.primary)
        }
        .accessibilityLabel("Quick Actions")
        .accessibilityHint("Access Quick Pick, Timers, and Readiness Check-In")
    }
}

// MARK: - Preview

#Preview {
    TodayHubView()
        .environmentObject(AppState())
        .environmentObject(PTSupabaseClient.shared)
        .environmentObject(StoreKitService.shared)
}
