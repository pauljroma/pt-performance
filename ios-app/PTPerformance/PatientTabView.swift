import SwiftUI

// Mode-Aware Tab Bar Architecture
// Shows different tabs based on patient's current mode (Rehab, Strength, Performance)
//
// REHAB MODE: Today, Pain Tracking, Progress, ROM, Settings
// STRENGTH MODE: Today, Workouts, PRs/Big Lifts, Progress, Settings
// PERFORMANCE MODE: Today, Training, Analytics, Recovery, Settings
//
// Common tabs (Today, Settings) always visible across all modes
//
// Tab Navigation Polish
// - Mode-aware tab visibility with smooth animations
// - Consistent SF Symbols with .medium weight
// - Subtle haptic feedback on tab switches
// - Dark mode adaptive styling
// - Badge support for notifications
// - Animated tab transitions when mode changes

struct PatientTabView: View {
    @StateObject private var supabase = PTSupabaseClient.shared
    @EnvironmentObject var storeKit: StoreKitService
    @EnvironmentObject var appState: AppState
    @EnvironmentObject private var badgeManager: TabBarBadgeManager
    @EnvironmentObject private var modeService: ModeService
    @StateObject private var featureVisibility = FeatureVisibilityViewModel()

    // Track selected tab for haptic feedback
    @State private var selectedTab: ModeAwareTab = .today

    // Track visited tabs for lazy loading - only render tab content after it's been selected
    @State private var visitedTabs: Set<ModeAwareTab> = []

    // State-based refresh trigger for premium/mode changes
    @State private var tabRefreshVersion = 0

    // Flag to ensure tab bar appearance is only configured once
    @State private var hasConfiguredTabBarAppearance = false

    // Deep link sheet presentation state
    @State private var showDeepLinkReadiness = false
    @State private var showDeepLinkUCLHealth = false
    @State private var showDeepLinkSchedule = false
    @State private var showDeepLinkRecovery = false

    // MARK: - Mode-Aware Tab Definitions

    /// Tab definitions that vary by mode
    enum ModeAwareTab: String, CaseIterable, Identifiable {
        // Common tabs (all modes)
        case today
        case settings

        // Rehab mode tabs
        case painTracking
        case romExercises
        case rehabProgress

        // Strength mode tabs
        case workouts
        case prTracking
        case strengthProgress

        // Performance mode tabs
        case training
        case analytics
        case recovery

        var id: String { rawValue }

        var title: String {
            switch self {
            case .today: return "Today"
            case .settings: return "Settings"
            case .painTracking: return "Pain"
            case .romExercises: return "ROM"
            case .rehabProgress: return "Progress"
            case .workouts: return "Workouts"
            case .prTracking: return "PRs"
            case .strengthProgress: return "Progress"
            case .training: return "Training"
            case .analytics: return "Analytics"
            case .recovery: return "Recovery"
            }
        }

        var iconName: String {
            switch self {
            case .today: return "calendar"
            case .settings: return "gearshape"
            case .painTracking: return "waveform.path.ecg"
            case .romExercises: return "figure.flexibility"
            case .rehabProgress: return "chart.line.uptrend.xyaxis"
            case .workouts: return "dumbbell"
            case .prTracking: return "trophy"
            case .strengthProgress: return "chart.bar"
            case .training: return "figure.run"
            case .analytics: return "chart.xyaxis.line"
            case .recovery: return "heart.text.square"
            }
        }

        var selectedIconName: String {
            switch self {
            case .today: return "calendar.circle.fill"
            case .settings: return "gearshape.fill"
            case .painTracking: return "waveform.path.ecg.rectangle.fill"
            case .romExercises: return "figure.flexibility"
            case .rehabProgress: return "chart.line.uptrend.xyaxis.circle.fill"
            case .workouts: return "dumbbell.fill"
            case .prTracking: return "trophy.fill"
            case .strengthProgress: return "chart.bar.fill"
            case .training: return "figure.run.circle.fill"
            case .analytics: return "chart.xyaxis.line"
            case .recovery: return "heart.text.square.fill"
            }
        }

        var accessibilityHint: String {
            switch self {
            case .today: return "Today's workout with quick access to timers and AI pick"
            case .settings: return "App settings, profile, and preferences"
            case .painTracking: return "Log and track pain levels during recovery"
            case .romExercises: return "Range of motion exercises and progress"
            case .rehabProgress: return "View your rehabilitation progress over time"
            case .workouts: return "Browse and start workouts from your library"
            case .prTracking: return "Track personal records and big lifts"
            case .strengthProgress: return "View volume trends and strength gains"
            case .training: return "Today's training plan and exercises"
            case .analytics: return "Advanced performance analytics and insights"
            case .recovery: return "Recovery tracking with readiness scores"
            }
        }

        /// MVP tabs: Today, Workouts, Recovery, Settings
        static var mvpTabs: [ModeAwareTab] {
            [.today, .workouts, .recovery, .settings]
        }

        /// Returns tabs visible for a given mode
        static func tabs(for mode: Mode) -> [ModeAwareTab] {
            switch mode {
            case .rehab:
                return [.today, .painTracking, .rehabProgress, .romExercises, .settings]
            case .strength:
                return [.today, .workouts, .prTracking, .strengthProgress, .settings]
            case .performance:
                return [.today, .training, .analytics, .recovery, .settings]
            }
        }
    }

    /// Current tabs based on mode (MVP mode overrides all modes)
    private var currentTabs: [ModeAwareTab] {
        if Config.MVPConfig.isMVPMode {
            return ModeAwareTab.mvpTabs
        }
        return ModeAwareTab.tabs(for: modeService.currentMode)
    }

    var body: some View {
        // Mode-aware tab layout with animated transitions
        TabView(selection: $selectedTab) {
            ForEach(currentTabs) { tab in
                lazyTabContent(for: tab)
                    .tabItem {
                        Label {
                            Text(tab.title)
                        } icon: {
                            Image(systemName: selectedTab == tab ? tab.selectedIconName : tab.iconName)
                                .fontWeight(.medium)
                        }
                    }
                    .tag(tab)
                    .accessibilityIdentifier("tab_\(tab.rawValue)")
                    .accessibilityLabel(tab.title)
                    .accessibilityHint(tab.accessibilityHint)
            }
        }
        .id(tabRefreshVersion)  // Force TabView rebuild when mode/premium changes
        .tint(modeThemeColor)  // Mode-aware accent color
        .onChange(of: selectedTab) { _, newTab in
            // Mark tab as visited for lazy loading
            visitedTabs.insert(newTab)

            // Subtle haptic feedback for tab switching
            HapticFeedback.tabSwitch()

            // Clear badge when tab is selected
            if let tabIndex = currentTabs.firstIndex(of: newTab) {
                badgeManager.clearBadge(for: tabIndex)
            }
        }
        .onChange(of: storeKit.isPremium) { _, newValue in
            // Force complete TabView rebuild when premium changes
            DebugLogger.shared.log("[PatientTabView] Premium changed to: \(newValue), refreshing tabs", level: .diagnostic)
            tabRefreshVersion += 1
        }
        .onChange(of: modeService.currentMode) { oldMode, newMode in
            // Animate tab bar change when mode switches
            DebugLogger.shared.log("[PatientTabView] Mode changed from \(oldMode.displayName) to \(newMode.displayName)", level: .diagnostic)

            withAnimation(.easeInOut(duration: 0.3)) {
                // Reset to Today tab when mode changes (common across all modes)
                selectedTab = .today
                tabRefreshVersion += 1
            }

            // Provide haptic feedback for mode change
            HapticFeedback.medium()
        }
        .onAppear {
            // Initialize default tab as visited for lazy loading
            visitedTabs.insert(selectedTab)

            // Configure tab bar appearance for dark mode adaptation (only once)
            if !hasConfiguredTabBarAppearance {
                configureTabBarAppearance()
                hasConfiguredTabBarAppearance = true
            }
        }
        // Deep link handling for patient-level navigation
        .onChange(of: appState.pendingDeepLink) { _, newValue in
            guard let newValue else { return }

            // MVP mode guard: if the deep link targets a tab not in mvpTabs, redirect to .today
            if Config.MVPConfig.isMVPMode {
                let mvpTabs = ModeAwareTab.mvpTabs
                let isAllowedDeepLink: Bool
                switch newValue {
                case .workout, .startWorkout:
                    // .today is always in mvpTabs — workout deep links go to Today
                    isAllowedDeepLink = true
                case .recovery:
                    isAllowedDeepLink = mvpTabs.contains(.recovery)
                case .settings:
                    isAllowedDeepLink = mvpTabs.contains(.settings)
                case .readiness, .schedule, .uclHealth:
                    // These open sheets, allow them through
                    isAllowedDeepLink = true
                case .progress:
                    // Progress tabs (rehabProgress, strengthProgress, analytics) are not in MVP
                    isAllowedDeepLink = false
                default:
                    isAllowedDeepLink = false
                }

                if !isAllowedDeepLink {
                    appState.pendingDeepLink = nil
                    selectedTab = .today
                    return
                }
            }

            switch newValue {
            case .readiness:
                appState.pendingDeepLink = nil
                showDeepLinkReadiness = true

            case .recovery:
                appState.pendingDeepLink = nil
                // Switch to recovery tab if available (Performance mode), otherwise show sheet
                if currentTabs.contains(.recovery) {
                    selectedTab = .recovery
                } else {
                    showDeepLinkRecovery = true
                }

            case .progress:
                appState.pendingDeepLink = nil
                // Switch to the appropriate progress tab for the current mode
                if currentTabs.contains(.rehabProgress) {
                    selectedTab = .rehabProgress
                } else if currentTabs.contains(.strengthProgress) {
                    selectedTab = .strengthProgress
                } else if currentTabs.contains(.analytics) {
                    selectedTab = .analytics
                }

            case .schedule:
                appState.pendingDeepLink = nil
                showDeepLinkSchedule = true

            case .uclHealth:
                appState.pendingDeepLink = nil
                showDeepLinkUCLHealth = true

            case .settings:
                appState.pendingDeepLink = nil
                selectedTab = .settings

            case .workout:
                // Switch to today tab where workout context is handled
                appState.pendingDeepLink = nil
                selectedTab = .today

            default:
                // Other deep links handled by child views (e.g., TodayHubView)
                break
            }
        }
        // Deep link sheets for views not reachable via tab switching
        .sheetWithHaptic(isPresented: $showDeepLinkReadiness) {
            if let patientIdString = PTSupabaseClient.shared.userId,
               let patientId = UUID(uuidString: patientIdString) {
                NavigationStack {
                    ReadinessDashboardView(patientId: patientId)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") { showDeepLinkReadiness = false }
                            }
                        }
                }
            }
        }
        .sheetWithHaptic(isPresented: $showDeepLinkUCLHealth) {
            NavigationStack {
                UCLHealthView()
                    .environmentObject(appState)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showDeepLinkUCLHealth = false }
                        }
                    }
            }
        }
        .sheetWithHaptic(isPresented: $showDeepLinkSchedule) {
            NavigationStack {
                CalendarView { _ in }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showDeepLinkSchedule = false }
                        }
                    }
            }
        }
        .sheetWithHaptic(isPresented: $showDeepLinkRecovery) {
            NavigationStack {
                HealthHubView()
                    .environmentObject(storeKit)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showDeepLinkRecovery = false }
                        }
                    }
            }
        }
        .environmentObject(featureVisibility)
    }

    // MARK: - Mode Theme Color

    private var modeThemeColor: Color {
        ModeTheme.theme(for: modeService.currentMode).primaryColor
    }

    // MARK: - Lazy Tab Content Builder

    /// Lazily loads tab content - only renders real content if the tab has been visited
    /// This prevents all tabs from initializing and loading data on app launch
    @ViewBuilder
    private func lazyTabContent(for tab: ModeAwareTab) -> some View {
        if visitedTabs.contains(tab) || tab == selectedTab {
            tabContent(for: tab)
        } else {
            // Placeholder that will be replaced when tab is selected
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Tab Content Builder

    @ViewBuilder
    private func tabContent(for tab: ModeAwareTab) -> some View {
        switch tab {
        // Common tabs
        case .today:
            TodayHubView()
                .environmentObject(supabase)
                .environmentObject(storeKit)
                .environmentObject(appState)

        case .settings:
            ProfileHubView()
                .environmentObject(storeKit)
                .environmentObject(appState)

        // Rehab mode tabs
        case .painTracking:
            PainTrackingView()
                .environmentObject(storeKit)

        case .romExercises:
            ROMExercisesView()
                .environmentObject(storeKit)

        case .rehabProgress:
            RehabProgressView()
                .environmentObject(storeKit)

        // Strength mode tabs
        case .workouts:
            ProgramsHubView()
                .environmentObject(storeKit)

        case .prTracking:
            if let patientId = appState.userId {
                if UUID(uuidString: patientId) != nil {
                    BigLiftsScorecard(patientId: patientId)
                        .environmentObject(storeKit)
                } else {
                    // Invalid UUID format - log warning and show error state
                    let _ = DebugLogger.shared.log("[PatientTabView] Invalid patient UUID format: \(patientId)", level: .warning)
                    ContentUnavailableView(
                        "Unable to Load PRs",
                        systemImage: "exclamationmark.triangle",
                        description: Text("Invalid user ID format. Please sign out and sign back in.")
                    )
                }
            } else {
                ProgressView("Loading...")
            }

        case .strengthProgress:
            StrengthProgressView()
                .environmentObject(storeKit)

        // Performance mode tabs
        case .training:
            ProgramsHubView()  // Training tab shows workout programs, not a duplicate of Today
                .environmentObject(storeKit)

        case .analytics:
            PerformanceAnalyticsView()
                .environmentObject(storeKit)

        case .recovery:
            HealthHubView()
                .environmentObject(storeKit)
        }
    }

    // MARK: - Tab Bar Appearance Configuration

    /// Configures UITabBar appearance for consistent styling across light/dark mode
    /// Uses mode-aware colors for selected state
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

        // Configure selected state with mode-aware color
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(modeThemeColor)

        // Configure badge appearance
        appearance.stackedLayoutAppearance.normal.badgeBackgroundColor = UIColor.systemRed
        appearance.stackedLayoutAppearance.normal.badgeTextAttributes = [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: UIColor.white
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        // Configure UINavigationBar with Korza branding
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = .modusCyan
    }
}
