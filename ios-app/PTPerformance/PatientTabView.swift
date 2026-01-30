import SwiftUI

struct PatientTabView: View {
    @StateObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @StateObject private var supabase = PTSupabaseClient.shared
    @EnvironmentObject var storeKit: StoreKitService

    // Track selected tab for haptic feedback
    @State private var selectedTab: Int = 0

    // BUILD 317: State-based refresh trigger for premium changes
    @State private var premiumRefreshID = UUID()

    var body: some View {
        // BUILD 317: Force TabView to re-render when premium status changes
        TabView(selection: $selectedTab) {
            TodaySessionView()
                .environmentObject(supabase)
                .tabItem {
                    Label("Today", systemImage: "list.bullet")
                }
                .tag(0)
                .accessibilityLabel("Today's Session")
                .accessibilityHint("View and start today's workout")

            if let patientId = supabase.userId {
                premiumGatedView(
                    premium: { HistoryView(patientId: patientId) },
                    locked: { PremiumLockedView(feature: "History", icon: "clock.arrow.circlepath", description: "Track all your sessions and see your workout history") }
                )
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(1)
                .accessibilityLabel("Workout History")
                .accessibilityHint("View past workouts and progress")
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
                .tag(2)
                .accessibilityLabel("Daily Readiness")
                .accessibilityHint("Check in with your daily wellness metrics")
            }

            if let patientIdString = supabase.userId,
               let patientId = UUID(uuidString: patientIdString) {
                TimerPickerView(patientId: patientId)
                    .tabItem {
                        Label("Timers", systemImage: "timer")
                    }
                    .tag(3)
                    .accessibilityLabel("Workout Timers")
                    .accessibilityHint("Access interval timers and stopwatch")
            }

            premiumGatedView(
                premium: { NutritionTabView() },
                locked: { PremiumLockedView(feature: "Nutrition", icon: "fork.knife", description: "Meal plans, food tracking, and nutrition guidance") }
            )
            .tabItem {
                Label("Nutrition", systemImage: "fork.knife")
            }
            .tag(4)
            .accessibilityLabel("Nutrition Tracking")
            .accessibilityHint("Log meals and track macros")

            premiumGatedView(
                premium: { AIChatView() },
                locked: { PremiumLockedView(feature: "AI Assistant", icon: "brain.head.profile", description: "AI-powered exercise recommendations and coaching") }
            )
            .tabItem {
                Label("AI Assistant", systemImage: "brain.head.profile")
            }
            .tag(5)
            .accessibilityLabel("AI Assistant")
            .accessibilityHint("Get AI-powered exercise recommendations")

            premiumGatedView(
                premium: { HelpView() },
                locked: { PremiumLockedView(feature: "Learn", icon: "book.fill", description: "Educational content and exercise technique guides") }
            )
            .tabItem {
                Label("Learn", systemImage: "book.fill")
            }
            .tag(6)
            .accessibilityLabel("Learning Center")
            .accessibilityHint("Access educational content and exercise guides")

            PatientSettingsView()
                .environmentObject(storeKit)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(7)
                .accessibilityLabel("Settings")
                .accessibilityHint("Manage app settings and account")
        }
        .id(premiumRefreshID)  // BUILD 317: Force TabView rebuild with UUID
        .onChange(of: selectedTab) { _, _ in
            // Haptic feedback for tab switching
            HapticFeedback.selectionChanged()
        }
        .onChange(of: storeKit.isPremium) { _, newValue in
            // BUILD 317: Force complete TabView rebuild when premium changes
            print("[PatientTabView] Premium changed to: \(newValue), refreshing tabs")
            premiumRefreshID = UUID()
        }
    }

    // BUILD 317: Helper function to create premium-gated views
    @ViewBuilder
    private func premiumGatedView<Premium: View, Locked: View>(
        @ViewBuilder premium: () -> Premium,
        @ViewBuilder locked: () -> Locked
    ) -> some View {
        // BUILD 317: Direct conditional without Group wrapper for cleaner state
        if storeKit.isPremium {
            premium()
        } else {
            locked()
                .environmentObject(storeKit)
        }
    }
}

// MARK: - Patient Settings View

struct PatientSettingsView: View {
    @StateObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @StateObject private var supabase = PTSupabaseClient.shared
    @StateObject private var therapistLinkingVM = TherapistLinkingViewModel()
    // BUILD 307: Use EnvironmentObject to share same instance with PatientTabView
    // Previously @StateObject created separate observation, so toggle didn't update tabs
    @EnvironmentObject var storeKit: StoreKitService
    @EnvironmentObject var appState: AppState

    // MARK: - Computed Properties

    /// Current subscription plan display text
    private var subscriptionPlanText: String {
        if storeKit.isPremium {
            if storeKit.purchasedProductIDs.contains("com.ptperformance.app.annual") {
                return "Annual Premium"
            } else if storeKit.purchasedProductIDs.contains("com.ptperformance.app.monthly") {
                return "Monthly Premium"
            } else {
                return "Premium Active"
            }
        } else {
            return "Free Plan"
        }
    }

    /// Therapist link status display text
    private var therapistLinkStatusText: String {
        if therapistLinkingVM.isLinked {
            return therapistLinkingVM.therapistName ?? "Linked"
        } else {
            return "Not linked"
        }
    }

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
                                .accessibilityHidden(true)
                            Text("View Tutorial")
                                .foregroundColor(.primary)
                        }
                    }
                    .accessibilityLabel("View Tutorial")
                    .accessibilityHint("Replays the app introduction walkthrough")
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
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Manage Subscription")
                                    .foregroundColor(.primary)
                                Text(subscriptionPlanText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section("Therapist") {
                    NavigationLink {
                        TherapistLinkingView()
                    } label: {
                        HStack {
                            Image(systemName: therapistLinkingVM.isLinked ? "person.2.fill" : "person.badge.plus")
                                .foregroundColor(therapistLinkingVM.isLinked ? .green : .blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Therapist Linking")
                                    .foregroundColor(.primary)
                                Text(therapistLinkStatusText)
                                    .font(.caption)
                                    .foregroundColor(therapistLinkingVM.isLinked ? .green : .secondary)
                            }
                        }
                    }
                }

                Section("Account") {
                    Button {
                        Task {
                            await logout()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.blue)
                            Text("Log Out")
                                .foregroundColor(.primary)
                        }
                    }
                    .accessibilityLabel("Log Out")
                    .accessibilityHint("Signs you out of the app")

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
                                .accessibilityHidden(true)
                            Text("Premium Features")
                        }
                    }
                    .accessibilityLabel("Premium Features")
                    .accessibilityValue(storeKit.isPremium ? "Enabled" : "Disabled")
                    .accessibilityHint("Toggle to test premium features")
                    if storeKit.debugPremiumOverride != nil {
                        Button("Reset to Real Status") {
                            storeKit.debugPremiumOverride = nil
                        }
                        .foregroundColor(.blue)
                        .accessibilityLabel("Reset to Real Status")
                        .accessibilityHint("Removes debug override and uses actual subscription status")
                    }
                }
            }
            .navigationTitle("Settings")
            .task {
                // Fetch therapist link status on view appear
                await therapistLinkingVM.checkLinkStatus()
            }
        }
    }

    // MARK: - Logout

    private func logout() async {
        do {
            try await PTSupabaseClient.shared.signOut()
            await MainActor.run {
                appState.isAuthenticated = false
                appState.userRole = nil
                appState.userId = nil
            }
        } catch {
            print("Logout error: \(error.localizedDescription)")
        }
    }
}
