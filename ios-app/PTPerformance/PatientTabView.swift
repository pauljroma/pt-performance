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
    @ObservedObject private var supabase = PTSupabaseClient.shared
    @EnvironmentObject var storeKit: StoreKitService
    @EnvironmentObject var appState: AppState
    @ObservedObject private var badgeManager = TabBarBadgeManager.shared
    @ObservedObject private var modeService = ModeService.shared
    @StateObject private var featureVisibility = FeatureVisibilityViewModel()

    // Track selected tab for haptic feedback
    @State private var selectedTab: ModeAwareTab = .today

    // Track visited tabs for lazy loading - only render tab content after it's been selected
    @State private var visitedTabs: Set<ModeAwareTab> = []

    // State-based refresh trigger for premium/mode changes
    @State private var tabRefreshVersion = 0

    // Flag to ensure tab bar appearance is only configured once
    @State private var hasConfiguredTabBarAppearance = false

    // Animation namespace for tab transitions
    @Namespace private var tabAnimation

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

    /// Current tabs based on mode
    private var currentTabs: [ModeAwareTab] {
        ModeAwareTab.tabs(for: modeService.currentMode)
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
                if let patientUUID = UUID(uuidString: patientId) {
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
            TodayHubView()  // Training uses same view as Today in performance mode
                .environmentObject(supabase)
                .environmentObject(storeKit)
                .environmentObject(appState)

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
            if storeKit.purchasedProductIDs.contains("com.getmodus.app.annual") {
                return "Annual Premium"
            } else if storeKit.purchasedProductIDs.contains("com.getmodus.app.monthly") {
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
                                .foregroundColor(.accentColor)
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

                    NavigationLink {
                        HealthHubView()
                            .environmentObject(storeKit)
                    } label: {
                        HStack {
                            Image(systemName: "heart.text.square.fill")
                                .foregroundColor(.cyan)
                            Text("Health Hub")
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
                                .background(Color(.secondarySystemGroupedBackground))
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
                                .foregroundColor(.accentColor)
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
                                .foregroundColor(.accentColor)
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
                                .foregroundColor(therapistLinkingVM.isLinked ? .green : .accentColor)
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
                                .foregroundColor(.accentColor)
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
                        .foregroundColor(.accentColor)
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

// MARK: - Mode-Specific Tab Views

// MARK: Rehab Mode Views

/// Pain Tracking View - Rehab mode tab for logging pain levels
struct PainTrackingView: View {
    @EnvironmentObject var storeKit: StoreKitService
    @ObservedObject private var supabase = PTSupabaseClient.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Pain logging card
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Image(systemName: "waveform.path.ecg")
                                .font(.title2)
                                .foregroundColor(.orange)
                            Text("Log Today's Pain")
                                .font(.headline)
                        }

                        Text("Track your pain levels to monitor recovery progress")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Placeholder for pain scale slider
                        VStack(spacing: Spacing.sm) {
                            HStack {
                                Text("0")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("10")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            // Visual pain scale
                            HStack(spacing: 4) {
                                ForEach(0..<11) { level in
                                    Circle()
                                        .fill(painLevelColor(level))
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Text("\(level)")
                                                .font(.caption2)
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.md)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)

                    // Pain history preview
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Recent History")
                            .font(.headline)

                        Text("Pain tracking history will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(CornerRadius.md)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Pain Tracking")
        }
    }

    private func painLevelColor(_ level: Int) -> Color {
        switch level {
        case 0...2: return .green
        case 3...4: return .yellow
        case 5...6: return .orange
        case 7...8: return .red
        default: return .purple
        }
    }
}

/// ROM Exercises View - Rehab mode tab for range of motion exercises
struct ROMExercisesView: View {
    @EnvironmentObject var storeKit: StoreKitService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // ROM assessment card
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Image(systemName: "figure.flexibility")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text("Range of Motion")
                                .font(.headline)
                        }

                        Text("Track your mobility and flexibility progress")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Quick assessment buttons
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                            ROMQuickButton(title: "Shoulder", icon: "figure.arms.open", color: .blue)
                            ROMQuickButton(title: "Hip", icon: "figure.walk", color: .green)
                            ROMQuickButton(title: "Knee", icon: "figure.run", color: .orange)
                            ROMQuickButton(title: "Ankle", icon: "figure.stand", color: .purple)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)

                    // ROM exercises list
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Prescribed Exercises")
                            .font(.headline)

                        Text("Your PT-assigned ROM exercises will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 150)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(CornerRadius.md)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ROM Exercises")
        }
    }
}

private struct ROMQuickButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }
}

/// Rehab Progress View - Rehab mode tab for recovery progress tracking
struct RehabProgressView: View {
    @EnvironmentObject var storeKit: StoreKitService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Progress overview card
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.title2)
                                .foregroundColor(.green)
                            Text("Recovery Progress")
                                .font(.headline)
                        }

                        // Progress metrics
                        HStack(spacing: Spacing.lg) {
                            ProgressMetricView(
                                title: "Pain Trend",
                                value: "-2.5",
                                subtitle: "Last 7 days",
                                color: .green,
                                icon: "arrow.down"
                            )

                            ProgressMetricView(
                                title: "ROM Gain",
                                value: "+15%",
                                subtitle: "This month",
                                color: .blue,
                                icon: "arrow.up"
                            )

                            ProgressMetricView(
                                title: "Sessions",
                                value: "12",
                                subtitle: "Completed",
                                color: .purple,
                                icon: "checkmark"
                            )
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)

                    // Milestone tracking
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Recovery Milestones")
                            .font(.headline)

                        Text("Your progress milestones and PT notes will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 150)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(CornerRadius.md)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
        }
    }
}

private struct ProgressMetricView: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: Strength Mode Views

/// Strength Progress View - Strength mode tab for volume and gains tracking
struct StrengthProgressView: View {
    @EnvironmentObject var storeKit: StoreKitService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Volume overview card
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text("Training Volume")
                                .font(.headline)
                        }

                        // Volume metrics
                        HStack(spacing: Spacing.lg) {
                            VolumeMetricView(
                                title: "Weekly",
                                value: "45,000",
                                unit: "lbs",
                                trend: "+12%",
                                isPositive: true
                            )

                            VolumeMetricView(
                                title: "Monthly",
                                value: "180K",
                                unit: "lbs",
                                trend: "+8%",
                                isPositive: true
                            )
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)

                    // Muscle group breakdown
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Volume by Muscle Group")
                            .font(.headline)

                        Text("Detailed volume breakdown will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 150)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(CornerRadius.md)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)

                    // Strength trends
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Strength Trends")
                            .font(.headline)

                        Text("Long-term strength progress charts will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 150)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(CornerRadius.md)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
        }
    }
}

private struct VolumeMetricView: View {
    let title: String
    let value: String
    let unit: String
    let trend: String
    let isPositive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 2) {
                Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                    .font(.caption2)
                Text(trend)
                    .font(.caption)
            }
            .foregroundColor(isPositive ? .green : .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: Performance Mode Views

/// Performance Analytics View - Performance mode tab for advanced analytics
struct PerformanceAnalyticsView: View {
    @EnvironmentObject var storeKit: StoreKitService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Readiness overview
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.title2)
                                .foregroundColor(.cyan)
                            Text("Performance Analytics")
                                .font(.headline)
                        }

                        // Key metrics
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                            AnalyticsMetricCard(
                                title: "Readiness",
                                value: "82",
                                unit: "%",
                                icon: "bolt.heart.fill",
                                color: .green
                            )

                            AnalyticsMetricCard(
                                title: "Fatigue",
                                value: "Low",
                                unit: "",
                                icon: "battery.75percent",
                                color: .blue
                            )

                            AnalyticsMetricCard(
                                title: "Training Load",
                                value: "1.2",
                                unit: "ACWR",
                                icon: "chart.bar",
                                color: .orange
                            )

                            AnalyticsMetricCard(
                                title: "HRV Trend",
                                value: "+5",
                                unit: "ms",
                                icon: "heart.fill",
                                color: .red
                            )
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)

                    // Performance trends
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Performance Trends")
                            .font(.headline)

                        Text("Detailed performance analytics and trends will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(CornerRadius.md)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)

                    // Periodization view
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Training Periodization")
                            .font(.headline)

                        Text("Mesocycle and microcycle planning will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 150)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(CornerRadius.md)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Analytics")
        }
    }
}

private struct AnalyticsMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }
}
