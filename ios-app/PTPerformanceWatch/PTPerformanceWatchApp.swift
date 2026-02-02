//
//  PTPerformanceWatchApp.swift
//  PTPerformanceWatch
//
//  Apple Watch standalone app for PT Performance
//  ACP-824: Standalone Watch App Implementation
//

import SwiftUI
import WatchKit

@main
struct PTPerformanceWatchApp: App {
    @StateObject private var sessionManager = WatchSessionManager.shared
    @StateObject private var workoutViewModel = WatchWorkoutViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchWorkoutListView(viewModel: workoutViewModel)
            }
            .environmentObject(sessionManager)
            .environmentObject(workoutViewModel)
            .onAppear {
                sessionManager.activateSession()
            }
        }
    }
}
