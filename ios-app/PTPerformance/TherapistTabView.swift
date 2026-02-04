import SwiftUI

// Tab Navigation Polish
// - Consistent SF Symbols with .medium weight
// - Subtle haptic feedback on tab switches
// - Dark mode adaptive styling
// - Badge support for notifications
// - Smooth tab transition animations

struct TherapistTabView: View {
    @ObservedObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @ObservedObject private var badgeManager = TabBarBadgeManager.shared

    // Track selected tab for haptic feedback and icon state
    @State private var selectedTab: TherapistTab = .patients

    // MARK: - Tab Definitions

    enum TherapistTab: Int, CaseIterable {
        case patients = 0
        case intelligence = 1
        case programs = 2
        case prescriptions = 3
        case schedule = 4
        case reports = 5
        case settings = 6

        var title: String {
            switch self {
            case .patients: return "Patients"
            case .intelligence: return "Intelligence"
            case .programs: return "Programs"
            case .prescriptions: return "Rx"
            case .schedule: return "Schedule"
            case .reports: return "Reports"
            case .settings: return "Settings"
            }
        }

        /// SF Symbol names with consistent styling
        var iconName: String {
            switch self {
            case .patients: return "person.3"
            case .intelligence: return "brain.head.profile"
            case .programs: return "list.bullet.rectangle.portrait"
            case .prescriptions: return "doc.badge.clock"
            case .schedule: return "calendar"
            case .reports: return "chart.bar"
            case .settings: return "gearshape"
            }
        }

        /// Filled variant for selected state
        var selectedIconName: String {
            switch self {
            case .patients: return "person.3.fill"
            case .intelligence: return "brain.head.profile.fill"
            case .programs: return "list.bullet.rectangle.portrait.fill"
            case .prescriptions: return "doc.badge.clock.fill"
            case .schedule: return "calendar"
            case .reports: return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            }
        }

        var accessibilityHint: String {
            switch self {
            case .patients: return "View and manage your patients"
            case .intelligence: return "Practice intelligence with cohort analytics and reporting"
            case .programs: return "Create and manage exercise programs"
            case .prescriptions: return "Track workout prescription compliance"
            case .schedule: return "View and manage appointments"
            case .reports: return "View patient progress reports"
            case .settings: return "App settings and account management"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TherapistDashboardView()
                .tabItem {
                    Label {
                        Text(TherapistTab.patients.title)
                    } icon: {
                        Image(systemName: selectedTab == .patients ? TherapistTab.patients.selectedIconName : TherapistTab.patients.iconName)
                            .fontWeight(.medium)
                    }
                }
                .tag(TherapistTab.patients)
                .badge(badgeManager.patientsBadge)
                .accessibilityLabel(TherapistTab.patients.title)
                .accessibilityHint(TherapistTab.patients.accessibilityHint)

            TherapistIntelligenceView()
                .tabItem {
                    Label {
                        Text(TherapistTab.intelligence.title)
                    } icon: {
                        Image(systemName: selectedTab == .intelligence ? TherapistTab.intelligence.selectedIconName : TherapistTab.intelligence.iconName)
                            .fontWeight(.medium)
                    }
                }
                .tag(TherapistTab.intelligence)
                .badge(badgeManager.intelligenceBadge)
                .accessibilityLabel(TherapistTab.intelligence.title)
                .accessibilityHint(TherapistTab.intelligence.accessibilityHint)

            TherapistProgramsView()
                .tabItem {
                    Label {
                        Text(TherapistTab.programs.title)
                    } icon: {
                        Image(systemName: selectedTab == .programs ? TherapistTab.programs.selectedIconName : TherapistTab.programs.iconName)
                            .fontWeight(.medium)
                    }
                }
                .tag(TherapistTab.programs)
                .accessibilityLabel(TherapistTab.programs.title)
                .accessibilityHint(TherapistTab.programs.accessibilityHint)

            TherapistPrescriptionDashboardView()
                .tabItem {
                    Label {
                        Text(TherapistTab.prescriptions.title)
                    } icon: {
                        Image(systemName: selectedTab == .prescriptions ? TherapistTab.prescriptions.selectedIconName : TherapistTab.prescriptions.iconName)
                            .fontWeight(.medium)
                    }
                }
                .tag(TherapistTab.prescriptions)
                .badge(badgeManager.prescriptionsBadge)
                .accessibilityLabel(TherapistTab.prescriptions.title)
                .accessibilityHint(TherapistTab.prescriptions.accessibilityHint)

            TherapistSchedulingView()
                .tabItem {
                    Label {
                        Text(TherapistTab.schedule.title)
                    } icon: {
                        Image(systemName: selectedTab == .schedule ? TherapistTab.schedule.selectedIconName : TherapistTab.schedule.iconName)
                            .fontWeight(.medium)
                    }
                }
                .tag(TherapistTab.schedule)
                .badge(badgeManager.scheduleBadge)
                .accessibilityLabel(TherapistTab.schedule.title)
                .accessibilityHint(TherapistTab.schedule.accessibilityHint)

            TherapistReportingView()
                .tabItem {
                    Label {
                        Text(TherapistTab.reports.title)
                    } icon: {
                        Image(systemName: selectedTab == .reports ? TherapistTab.reports.selectedIconName : TherapistTab.reports.iconName)
                            .fontWeight(.medium)
                    }
                }
                .tag(TherapistTab.reports)
                .badge(badgeManager.reportsBadge)
                .accessibilityLabel(TherapistTab.reports.title)
                .accessibilityHint(TherapistTab.reports.accessibilityHint)

            TherapistSettingsView()
                .tabItem {
                    Label {
                        Text(TherapistTab.settings.title)
                    } icon: {
                        Image(systemName: selectedTab == .settings ? TherapistTab.settings.selectedIconName : TherapistTab.settings.iconName)
                            .fontWeight(.medium)
                    }
                }
                .tag(TherapistTab.settings)
                .accessibilityLabel(TherapistTab.settings.title)
                .accessibilityHint(TherapistTab.settings.accessibilityHint)
        }
        .tint(.accentColor)  // Consistent tint color across light/dark mode
        .onChange(of: selectedTab) { oldTab, newTab in
            // Subtle haptic feedback for tab switching
            HapticFeedback.tabSwitch()

            // Clear badge when tab is selected
            badgeManager.clearBadge(for: newTab.rawValue)
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

// MARK: - Therapist Settings View

struct TherapistSettingsView: View {
    @ObservedObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @EnvironmentObject var appState: AppState
    @State private var showingLogoutConfirmation = false
    @State private var isLoggingOut = false

    var body: some View {
        NavigationStack {
            List {
                Section("Help & Support") {
                    Button {
                        onboardingCoordinator.resetOnboarding()
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.accentColor)
                            Text("View Tutorial")
                                .foregroundColor(.primary)
                        }
                    }
                }

                Section("Account") {
                    Button(role: .destructive) {
                        showingLogoutConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log Out")
                            Spacer()
                            if isLoggingOut {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isLoggingOut)
                }
            }
            .navigationTitle("Settings")
            .alert("Log Out", isPresented: $showingLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    performLogout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }

    private func performLogout() {
        isLoggingOut = true
        Task {
            do {
                try await PTSupabaseClient.shared.signOut()
                await MainActor.run {
                    appState.isAuthenticated = false
                    appState.userRole = nil
                    appState.userId = nil
                    isLoggingOut = false
                }
            } catch {
                await MainActor.run {
                    isLoggingOut = false
                }
                DebugLogger.shared.error("TherapistSettingsView", "Logout failed: \(error.localizedDescription)")
            }
        }
    }
}
