import SwiftUI

struct PatientTabView: View {
    @StateObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @StateObject private var supabase = PTSupabaseClient.shared
    @EnvironmentObject var storeKit: StoreKitService

    var body: some View {
        TabView {
            TodaySessionView()
                .environmentObject(supabase)  // BUILD 265: Pass supabase environment object
                .tabItem {
                    Label("Today", systemImage: "list.bullet")
                }

            if let patientId = supabase.userId {
                Group {
                    if storeKit.isPremium {
                        HistoryView(patientId: patientId)
                    } else {
                        PremiumLockedView(feature: "History", icon: "clock.arrow.circlepath", description: "Track all your sessions and see your workout history")
                            .environmentObject(storeKit)
                    }
                }
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            }

            // BUILD 123: Restored Readiness tab with live score preview
            if let patientIdString = supabase.userId,
               let patientId = UUID(uuidString: patientIdString) {
                Group {
                    if storeKit.isPremium {
                        ReadinessCheckInView(patientId: patientId)
                    } else {
                        PremiumLockedView(feature: "Readiness", icon: "battery.100", description: "Daily readiness check-ins and recovery scoring")
                            .environmentObject(storeKit)
                    }
                }
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
            Group {
                if storeKit.isPremium {
                    NutritionTabView()
                } else {
                    PremiumLockedView(feature: "Nutrition", icon: "fork.knife", description: "Meal plans, food tracking, and nutrition guidance")
                        .environmentObject(storeKit)
                }
            }
            .tabItem {
                Label("Nutrition", systemImage: "fork.knife")
            }

            Group {
                if storeKit.isPremium {
                    AIChatView()
                } else {
                    PremiumLockedView(feature: "AI Assistant", icon: "brain.head.profile", description: "AI-powered exercise recommendations and coaching")
                        .environmentObject(storeKit)
                }
            }
            .tabItem {
                Label("AI Assistant", systemImage: "brain.head.profile")
            }

            Group {
                if storeKit.isPremium {
                    HelpView()
                } else {
                    PremiumLockedView(feature: "Learn", icon: "book.fill", description: "Educational content and exercise technique guides")
                        .environmentObject(storeKit)
                }
            }
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
    @StateObject private var storeKit = StoreKitService.shared

    var body: some View {
        NavigationStack {
            List {
                // BUILD 305: Quick wins — Body Comp, Calculators, Goals
                Section("Tools & Tracking") {
                    NavigationLink {
                        BodyCompositionTimelineView()
                    } label: {
                        HStack {
                            Image(systemName: "figure.stand")
                                .foregroundColor(.blue)
                            Text("Body Composition")
                                .foregroundColor(.primary)
                        }
                    }

                    NavigationLink {
                        CalculatorsMenuView()
                    } label: {
                        HStack {
                            Image(systemName: "function")
                                .foregroundColor(.green)
                            Text("Calculators")
                                .foregroundColor(.primary)
                        }
                    }

                    NavigationLink {
                        PatientGoalsView()
                    } label: {
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(.orange)
                            Text("My Goals")
                                .foregroundColor(.primary)
                        }
                    }
                }

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

                Section("Subscription") {
                    NavigationLink {
                        SubscriptionView()
                            .environmentObject(StoreKitService.shared)
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Manage Subscription")
                                .foregroundColor(.primary)
                        }
                    }
                }

                Section("Therapist") {
                    NavigationLink {
                        TherapistLinkingView()
                    } label: {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.blue)
                            Text("Therapist Linking")
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

                Section("Debug") {
                    Toggle(isOn: Binding(
                        get: { storeKit.debugPremiumOverride ?? false },
                        set: { storeKit.debugPremiumOverride = $0 }
                    )) {
                        HStack {
                            Image(systemName: storeKit.isPremium ? "lock.open.fill" : "lock.fill")
                                .foregroundColor(storeKit.isPremium ? .green : .gray)
                            Text("Premium Features")
                        }
                    }
                    if storeKit.debugPremiumOverride != nil {
                        Button("Reset to Real Status") {
                            storeKit.debugPremiumOverride = nil
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
