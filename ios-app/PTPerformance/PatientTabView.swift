import SwiftUI

struct PatientTabView: View {
    @StateObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @StateObject private var supabase = PTSupabaseClient.shared

    var body: some View {
        TabView {
            TodaySessionView()
                .tabItem {
                    Label("Today", systemImage: "list.bullet")
                }

            // BUILD 113: Use real HistoryView with pain trends (was placeholder)
            if let patientId = supabase.userId {
                HistoryView(patientId: patientId)
                    .tabItem {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
            } else {
                PatientHistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
            }

            // BUILD 123: Restored Readiness tab with live score preview
            if let patientIdString = supabase.userId,
               let patientId = UUID(uuidString: patientIdString) {
                ReadinessCheckInView(patientId: patientId)
                    .tabItem {
                        Label("Readiness", systemImage: "battery.100")
                    }
            }

            // BUILD 123: Restored Timer tab
            if let patientIdString = supabase.userId,
               let patientId = UUID(uuidString: patientIdString) {
                TimerPickerView(patientId: patientId)
                    .tabItem {
                        Label("Timers", systemImage: "timer")
                    }
            }

            // BUILD 223: Full Nutrition tab with dashboard, meal plans, and food library
            NutritionTabView()
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife")
                }

            AIChatView()
                .tabItem {
                    Label("AI Assistant", systemImage: "brain.head.profile")
                }

            HelpView()
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }

            PatientSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

// MARK: - Patient Settings View

struct PatientSettingsView: View {
    @StateObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @StateObject private var supabase = PTSupabaseClient.shared

    var body: some View {
        NavigationStack {
            List {
                // BUILD 159: Removed Nutrition AI from Settings (now top-level tab)

                Section("Help & Support") {
                    Button {
                        onboardingCoordinator.resetOnboarding()
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                            Text("View Tutorial")
                                .foregroundColor(.primary)
                        }
                    }
                }

                Section("Privacy & Data") {
                    NavigationLink {
                        PrivacyNoticeView(onAccept: {})
                    } label: {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.blue)
                            Text("Privacy Notice")
                                .foregroundColor(.primary)
                        }
                    }
                }

                Section("Account") {
                    NavigationLink {
                        AccountDeletionView()
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("Delete Account")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
