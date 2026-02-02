//
//  ContentView.swift
//  PTPerformanceWatch
//
//  Root view for Watch app - redirects to workout list
//  ACP-824: Apple Watch Standalone App
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager
    @EnvironmentObject var workoutViewModel: WatchWorkoutViewModel

    var body: some View {
        NavigationStack {
            WatchWorkoutListView(viewModel: workoutViewModel)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchSessionManager.shared)
        .environmentObject(WatchWorkoutViewModel())
}
