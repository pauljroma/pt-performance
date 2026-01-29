import SwiftUI

struct PatientTabView: View {
    @StateObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @StateObject private var supabase = PTSupabaseClient.shared
    @EnvironmentObject var storeKit: StoreKitService

    // BUILD 312: Computed property to ensure views re-evaluate on premium change
    private var premiumKey: String {
        "premium-\(storeKit.isPremium)"
    }

    var body: some View {
        // BUILD 312: Force TabView to re-render when premium status changes
        TabView {
            TodaySessionView()
                .environmentObject(supabase)
                .tabItem {
                    Label("Today", systemImage: "list.bullet")
                }

            if let patientId = supabase.userId {
                premiumGatedView(
                    premium: { HistoryView(patientId: patientId) },
                    locked: { PremiumLockedView(feature: "History", icon: "clock.arrow.circlepath", description: "Track all your sessions and see your workout history") }
                )
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            }

            if let patientIdString = supabase.userId,
               let patientId = UUID(uuidString: patientIdString) {
                premiumGatedView(
                    premium: { ReadinessCheckInView(patientId: patientId) },
                    locked: { PremiumLockedView(feature: "Readiness", icon: "battery.100", description: "Daily readiness check-ins and recovery scoring") }
                )
                .tabItem {
                    Label("Readiness", systemImage: "battery.100")
                }
            }

            if let patientIdString = supabase.userId,
               let patientId = UUID(uuidString: patientIdString) {
                TimerPickerView(patientId: patientId)
                    .tabItem {
                        Label("Timers", systemImage: "timer")
                    }
            }

            premiumGatedView(
                premium: { NutritionTabView() },
                locked: { PremiumLockedView(feature: "Nutrition", icon: "fork.knife", description: "Meal plans, food tracking, and nutrition guidance") }
            )
            .tabItem {
                Label("Nutrition", systemImage: "fork.knife")
            }

            premiumGatedView(
                premium: { AIChatView() },
                locked: { PremiumLockedView(feature: "AI Assistant", icon: "brain.head.profile", description: "AI-powered exercise recommendations and coaching") }
            )
            .tabItem {
                Label("AI Assistant", systemImage: "brain.head.profile")
            }

            premiumGatedView(
                premium: { HelpView() },
                locked: { PremiumLockedView(feature: "Learn", icon: "book.fill", description: "Educational content and exercise technique guides") }
            )
            .tabItem {
                Label("Learn", systemImage: "book.fill")
            }

            PatientSettingsView()
                .environmentObject(storeKit)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .id(premiumKey)  // BUILD 312: Force TabView rebuild with string key
    }

    // BUILD 312: Helper function to create premium-gated views with proper IDs
    @ViewBuilder
    private func premiumGatedView<Premium: View, Locked: View>(
        @ViewBuilder premium: () -> Premium,
        @ViewBuilder locked: () -> Locked
    ) -> some View {
        Group {
            if storeKit.isPremium {
                premium()
            } else {
                locked()
                    .environmentObject(storeKit)
            }
        }
        .id(premiumKey)  // Force each tab to rebuild on premium change
    }
}

// MARK: - Patient Settings View

struct PatientSettingsView: View {
    @StateObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @StateObject private var supabase = PTSupabaseClient.shared
    // BUILD 307: Use EnvironmentObject to share same instance with PatientTabView
    // Previously @StateObject created separate observation, so toggle didn't update tabs
    @EnvironmentObject var storeKit: StoreKitService

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
