import SwiftUI

// BUILD 318: Tab Consolidation - Reduced from 10 tabs to 3
// Tab 1: Today (Today's workout + Quick Pick + Timers + Readiness access)
// Tab 2: Programs (Program Library + History)
// Tab 3: Profile (Settings + Nutrition + Learn + AI Assistant)

struct PatientTabView: View {
    @ObservedObject private var supabase = PTSupabaseClient.shared
    @EnvironmentObject var storeKit: StoreKitService
    @EnvironmentObject var appState: AppState

    // Track selected tab for haptic feedback
    @State private var selectedTab: Int = 0

    // BUILD 317: State-based refresh trigger for premium changes
    @State private var premiumRefreshID = UUID()

    var body: some View {
        // BUILD 318: Consolidated 3-tab layout
        TabView(selection: $selectedTab) {
            // Tab 1: Today Hub - Primary workout focus
            TodayHubView()
                .environmentObject(supabase)
                .environmentObject(storeKit)
                .environmentObject(appState)
                .tabItem {
                    Label("Today", systemImage: "figure.run")
                }
                .tag(0)
                .accessibilityLabel("Today")
                .accessibilityHint("Today's workout with quick access to timers and AI pick")

            // Tab 2: Programs Hub - Library and History
            ProgramsHubView()
                .environmentObject(storeKit)
                .tabItem {
                    Label("Programs", systemImage: "list.bullet.rectangle")
                }
                .tag(1)
                .accessibilityLabel("Programs")
                .accessibilityHint("Browse programs and view workout history")

            // Tab 3: Profile Hub - Settings and Premium Features
            ProfileHubView()
                .environmentObject(storeKit)
                .environmentObject(appState)
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(2)
                .accessibilityLabel("Profile")
                .accessibilityHint("Settings, nutrition, AI assistant, and more")
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
}

// MARK: - Patient Settings View

struct PatientSettingsView: View {
    @ObservedObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @ObservedObject private var supabase = PTSupabaseClient.shared
    @ObservedObject private var modeService = ModeService.shared  // ACP-479: Mode awareness
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

    // ACP-479: Mode theme color
    private var modeThemeColor: Color {
        ModeTheme.theme(for: modeService.currentMode).primaryColor
    }

    // ACP-479: Mode badge text
    private var modeBadgeText: String {
        switch modeService.currentMode {
        case .rehab:
            return "PT-SET"
        case .strength:
            return "PT-SET"
        case .performance:
            return "PT-SET"
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
                        BodyCompGoalsView()
                    } label: {
                        HStack {
                            Image(systemName: "figure.arms.open")
                                .foregroundColor(.purple)
                            Text("Body Comp Goals")
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

                // ACP-479: Training Mode indicator (PT-controlled)
                Section("Training Mode") {
                    HStack {
                        Image(systemName: modeService.currentMode.iconName)
                            .font(.title2)
                            .foregroundColor(modeThemeColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(modeService.currentMode.displayName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(modeService.currentMode.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        // Mode badge
                        Text(modeBadgeText)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(modeThemeColor.opacity(0.15))
                            .foregroundColor(modeThemeColor)
                            .cornerRadius(4)
                    }
                    .padding(.vertical, 4)

                    // Primary metrics for current mode
                    HStack(spacing: 12) {
                        ForEach(modeService.currentMode.primaryMetrics, id: \.self) { metric in
                            Text(metric)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.vertical, 2)
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
