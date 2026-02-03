import SwiftUI

// Tab Consolidation - 4-tab layout
// Tab 1: Today (Today's workout + Quick Pick + Timers + Readiness access)
// Tab 2: Programs (Program Library + History)
// Tab 3: Health (Health Hub + Lab Results + Recovery + Fasting + Supplements + AI Coach)
// Tab 4: Profile (Settings + Nutrition + Learn + AI Assistant)
//
// Tab Navigation Polish
// - Consistent SF Symbols with .medium weight
// - Subtle haptic feedback on tab switches
// - Dark mode adaptive styling
// - Badge support for notifications
// - Smooth tab transition animations

struct PatientTabView: View {
    @ObservedObject private var supabase = PTSupabaseClient.shared
    @EnvironmentObject var storeKit: StoreKitService
    @EnvironmentObject var appState: AppState
    @ObservedObject private var badgeManager = TabBarBadgeManager.shared

    // Track selected tab for haptic feedback
    @State private var selectedTab: PatientTab = .today

    // State-based refresh trigger for premium changes
    @State private var premiumRefreshID = UUID()

    // MARK: - Tab Definitions

    enum PatientTab: Int, CaseIterable {
        case today = 0
        case programs = 1
        case health = 2
        case profile = 3

        var title: String {
            switch self {
            case .today: return "Today"
            case .programs: return "Programs"
            case .health: return "Health"
            case .profile: return "Profile"
            }
        }

        /// Consistent SF Symbol names with filled variants for selected state
        var iconName: String {
            switch self {
            case .today: return "figure.run"
            case .programs: return "list.bullet.rectangle.portrait"
            case .health: return "heart.text.square"
            case .profile: return "person.circle"
            }
        }

        var selectedIconName: String {
            switch self {
            case .today: return "figure.run"
            case .programs: return "list.bullet.rectangle.portrait.fill"
            case .health: return "heart.text.square.fill"
            case .profile: return "person.circle.fill"
            }
        }

        var accessibilityHint: String {
            switch self {
            case .today: return "Today's workout with quick access to timers and AI pick"
            case .programs: return "Browse programs and view workout history"
            case .health: return "Health intelligence with labs, recovery, fasting, and AI coach"
            case .profile: return "Settings, nutrition, AI assistant, and more"
            }
        }
    }

    var body: some View {
        // Consolidated 4-tab layout
        TabView(selection: $selectedTab) {
            // Tab 1: Today Hub - Primary workout focus
            TodayHubView()
                .environmentObject(supabase)
                .environmentObject(storeKit)
                .environmentObject(appState)
                .tabItem {
                    Label {
                        Text(PatientTab.today.title)
                    } icon: {
                        Image(systemName: selectedTab == .today ? PatientTab.today.selectedIconName : PatientTab.today.iconName)
                            .fontWeight(.medium)
                    }
                }
                .tag(PatientTab.today)
                .accessibilityLabel(PatientTab.today.title)
                .accessibilityHint(PatientTab.today.accessibilityHint)

            // Tab 2: Programs Hub - Library and History
            ProgramsHubView()
                .environmentObject(storeKit)
                .tabItem {
                    Label {
                        Text(PatientTab.programs.title)
                    } icon: {
                        Image(systemName: selectedTab == .programs ? PatientTab.programs.selectedIconName : PatientTab.programs.iconName)
                            .fontWeight(.medium)
                    }
                }
                .tag(PatientTab.programs)
                .badge(badgeManager.programsBadge)
                .accessibilityLabel(PatientTab.programs.title)
                .accessibilityHint(PatientTab.programs.accessibilityHint)

            // Tab 3: Health Hub - Health Intelligence
            HealthHubView()
                .environmentObject(storeKit)
                .tabItem {
                    Label {
                        Text(PatientTab.health.title)
                    } icon: {
                        Image(systemName: selectedTab == .health ? PatientTab.health.selectedIconName : PatientTab.health.iconName)
                            .fontWeight(.medium)
                    }
                }
                .tag(PatientTab.health)
                .accessibilityLabel(PatientTab.health.title)
                .accessibilityHint(PatientTab.health.accessibilityHint)

            // Tab 4: Profile Hub - Settings and Premium Features
            ProfileHubView()
                .environmentObject(storeKit)
                .environmentObject(appState)
                .tabItem {
                    Label {
                        Text(PatientTab.profile.title)
                    } icon: {
                        Image(systemName: selectedTab == .profile ? PatientTab.profile.selectedIconName : PatientTab.profile.iconName)
                            .fontWeight(.medium)
                    }
                }
                .tag(PatientTab.profile)
                .badge(badgeManager.profileBadge)
                .accessibilityLabel(PatientTab.profile.title)
                .accessibilityHint(PatientTab.profile.accessibilityHint)
        }
        .id(premiumRefreshID)  // Force TabView rebuild with UUID
        .tint(.accentColor)  // Ensure consistent tint color across light/dark mode
        .onChange(of: selectedTab) { oldTab, newTab in
            // Subtle haptic feedback for tab switching
            HapticFeedback.tabSwitch()

            // Clear badge when tab is selected
            badgeManager.clearBadge(for: newTab.rawValue)
        }
        .onChange(of: storeKit.isPremium) { _, newValue in
            // Force complete TabView rebuild when premium changes
            #if DEBUG
            print("[PatientTabView] Premium changed to: \(newValue), refreshing tabs")
            #endif
            premiumRefreshID = UUID()
        }
        .onAppear {
            // Configure tab bar appearance for dark mode adaptation
            configureTabBarAppearance()
        }
    }

    // MARK: - Tab Bar Appearance Configuration

    /// Configures UITabBar appearance for consistent styling across light/dark mode
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        // Use system background color for dark mode adaptation
        appearance.backgroundColor = UIColor.systemBackground

        // Configure normal state
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel

        // Configure selected state
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.accentColor)

        // Configure badge appearance
        appearance.stackedLayoutAppearance.normal.badgeBackgroundColor = UIColor.systemRed
        appearance.stackedLayoutAppearance.normal.badgeTextAttributes = [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: UIColor.white
        ]

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Patient Settings View

struct PatientSettingsView: View {
    @ObservedObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @ObservedObject private var supabase = PTSupabaseClient.shared
    @ObservedObject private var modeService = ModeService.shared  // ACP-479: Mode awareness
    @StateObject private var therapistLinkingVM = TherapistLinkingViewModel()
    // Use EnvironmentObject to share same instance with PatientTabView
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
                // Quick wins — Body Comp, Calculators, Goals
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
            DebugLogger.shared.error("PatientSettingsView", "Logout error: \(error.localizedDescription)")
        }
    }
}
