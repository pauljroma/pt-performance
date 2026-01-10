//
//  BackgroundTimerIntegration.swift
//  PTPerformance
//
//  Created by BUILD 116 - Agent 10
//  Example integration of BackgroundTimerManager with app lifecycle
//

import SwiftUI

// MARK: - Integration with PTPerformanceApp

/*

 To integrate BackgroundTimerManager with the app lifecycle,
 update PTPerformanceApp.swift as follows:

 @main
 struct PTPerformanceApp: App {
     @Environment(\.scenePhase) private var scenePhase
     @StateObject private var appState = AppState()
     @StateObject private var timerService = IntervalTimerService()
     @StateObject private var backgroundManager = BackgroundTimerManager.shared

     init() {
         // Existing initialization code...
         PerformanceMonitor.shared.trackAppLaunch()
         ErrorLogger.shared.logUserAction(...)

         // Request notification permissions on first launch
         Task {
             let granted = await backgroundManager.requestNotificationPermission()
             if granted {
                 DebugLogger.shared.info("DEBUG", 
                     "Notification permissions granted",
                 )
             }
         }
     }

     var body: some Scene {
         WindowGroup {
             RootView()
                 .environmentObject(appState)
                 .environmentObject(timerService)
                 .environmentObject(backgroundManager)
                 .onAppear {
                     PerformanceMonitor.shared.finishAppLaunch()
                 }
                 .onChange(of: scenePhase) { oldPhase, newPhase in
                     handleScenePhaseChange(from: oldPhase, to: newPhase)
                 }
         }
     }

     // MARK: - Scene Phase Handling

     private func handleScenePhaseChange(
         from oldPhase: ScenePhase,
         to newPhase: ScenePhase
     ) {
         switch newPhase {
         case .background:
             // App entering background
             DebugLogger.shared.info("DEBUG", 
                 "App entering background",
             )

             // Save timer state if active
             backgroundManager.handleAppDidEnterBackground(
                 timerService: timerService
             )

             // Track analytics
             ErrorLogger.shared.logUserAction(
                 action: "app_backgrounded",
                 properties: [
                     "has_active_timer": timerService.state == .running
                 ]
             )

         case .inactive:
             // App becoming inactive (phone call, notification, etc.)
             DebugLogger.shared.info("DEBUG", 
                 "App becoming inactive",
             )

         case .active:
             // App becoming active
             DebugLogger.shared.info("DEBUG", 
                 "App becoming active",
             )

             // Restore timer state if needed
             Task {
                 await backgroundManager.handleAppWillEnterForeground(
                     timerService: timerService
                 )
             }

             // Track analytics
             ErrorLogger.shared.logUserAction(
                 action: "app_foregrounded",
                 properties: [:]
             )

         @unknown default:
             break
         }
     }
 }

 */

// MARK: - Timer View Integration Example

/// Example timer view showing background continuation
struct ExampleTimerView: View {
    @EnvironmentObject var timerService: IntervalTimerService
    @EnvironmentObject var backgroundManager: BackgroundTimerManager
    @State private var showPermissionAlert = false

    var body: some View {
        VStack(spacing: 20) {
            // Timer display
            Text("Round \(timerService.currentRound)")
                .font(.title2)

            Text(formatTime(timerService.timeRemaining))
                .font(.system(size: 72, weight: .bold, design: .rounded))

            Text(timerService.currentPhase == .work ? "WORK" : "REST")
                .font(.title)
                .foregroundColor(timerService.currentPhase == .work ? .red : .green)

            // Controls
            HStack(spacing: 20) {
                Button("Start") {
                    checkPermissionAndStart()
                }
                .disabled(timerService.state == .running)

                Button("Pause") {
                    // Pause timer
                }
                .disabled(timerService.state != .running)

                Button("Reset") {
                    // Reset timer
                }
            }

            // Permission status
            HStack {
                Image(systemName: backgroundManager.hasPermission ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(backgroundManager.hasPermission ? .green : .red)

                Text(backgroundManager.hasPermission ? "Notifications enabled" : "Notifications disabled")
                    .font(.caption)
            }
            .padding()

            // Background continuation info
            VStack(alignment: .leading, spacing: 8) {
                Label("Background Continuation", systemImage: "app.badge")
                    .font(.headline)

                Text("Timer will continue when:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Label("Screen is locked", systemImage: "lock.fill")
                    Label("App is in background", systemImage: "square.stack.fill")
                    Label("Switching to another app", systemImage: "rectangle.stack.fill")
                }
                .font(.caption2)
                .foregroundColor(.secondary)

                Text("Notifications will alert you at each round")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .alert("Enable Notifications", isPresented: $showPermissionAlert) {
            Button("Enable") {
                Task {
                    await backgroundManager.requestNotificationPermission()
                }
            }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("To use background timer continuation, please enable notifications. You'll receive alerts when rounds complete.")
        }
    }

    private func checkPermissionAndStart() {
        if !backgroundManager.hasPermission {
            showPermissionAlert = true
        } else {
            // Start timer
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Testing Guide

/*

 # Testing Background Timer Continuation

 ## Manual Testing Steps

 ### 1. Test Background Continuation (Screen Lock)

 1. Start a timer (e.g., Tabata 20/10 × 8 rounds)
 2. Lock the iPhone screen (press power button)
 3. Wait for 30 seconds
 4. Unlock the screen
 5. Verify:
    ✅ Timer continued counting during lock
    ✅ Current round/phase is correct
    ✅ Notifications appeared (if enabled)

 ### 2. Test App Switching

 1. Start a timer
 2. Swipe up to app switcher
 3. Switch to another app (Settings, Safari, etc.)
 4. Wait 1-2 minutes
 5. Switch back to PTPerformance
 6. Verify:
    ✅ Timer continued in background
    ✅ State restored correctly
    ✅ UI updated to current round/phase

 ### 3. Test Notifications

 1. Ensure notifications are enabled
 2. Start a timer
 3. Lock screen or switch apps
 4. When work phase completes, verify:
    ✅ Notification appears ("Round X Work Complete")
    ✅ Notification sound plays
    ✅ Badge updated
 5. When rest phase completes, verify:
    ✅ Notification appears ("Round X Complete")
 6. When workout completes, verify:
    ✅ Final notification appears ("Workout Complete!")
    ✅ Badge cleared

 ### 4. Test State Persistence

 1. Start a timer
 2. Force-quit the app (swipe up in app switcher)
 3. Reopen the app
 4. Verify:
    ⚠️ Timer state cleared (expected - app killed)
    ⚠️ This is iOS limitation - background tasks don't survive force-quit

 ### 5. Test Permission Denied

 1. Go to Settings → PTPerformance → Notifications
 2. Disable notifications
 3. Start a timer
 4. Lock screen
 5. Verify:
    ✅ Timer continues (no notifications sent)
    ✅ App shows warning about disabled notifications

 ## Xcode Testing with Simulator

 ### Test Background Fetch

 1. Run app in simulator
 2. Start a timer
 3. In Xcode: Debug → Simulate Background Fetch
 4. Verify background task executes

 ### Test Local Notifications

 1. Run app in simulator
 2. Start a timer
 3. Lock simulator (Cmd+L)
 4. Verify notifications appear

 ## Expected Results

 ✅ Timer continues when app backgrounded
 ✅ Timer continues when screen locked
 ✅ Notifications appear at correct times
 ✅ State restores when app foregrounded
 ✅ UI updates correctly on restore
 ✅ Audio cues still work in foreground
 ✅ Haptics work in foreground only

 ## Known Limitations

 ⚠️ Background execution limited to ~30 seconds by iOS
 ⚠️ Notifications required for longer background periods
 ⚠️ Force-quit clears all background tasks
 ⚠️ Background refresh subject to system scheduling
 ⚠️ Battery optimization may affect background tasks

 */
