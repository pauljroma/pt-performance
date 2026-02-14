// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  UnifiedSettingsView.swift
//  PTPerformance
//
//  ACP-1036: Settings Organization Overhaul
//  Reorganized settings with search, quick toggles, sync status, and logical grouping
//

import SwiftUI

// MARK: - Unified Settings View

/// Comprehensive settings view with search, quick toggles, and organized sections
struct UnifiedSettingsView: View {
    // MARK: - Environment

    @EnvironmentObject var storeKit: StoreKitService
    @EnvironmentObject var appState: AppState
    @ObservedObject private var supabase = PTSupabaseClient.shared
    @ObservedObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @ObservedObject private var modeService = ModeService.shared
    @StateObject private var therapistLinkingVM = TherapistLinkingViewModel()
    @StateObject private var healthKitService = HealthKitService.shared
    @StateObject private var settingsViewModel = SettingsViewModel()

    // MARK: - State

    @State private var searchText = ""
    @State private var showQuickSetup = false
    @State private var isRefreshingSyncStatus = false
    @State private var lastSyncTime: Date = Date()

    // MARK: - Computed Properties

    /// Filtered sections based on search text
    private var filteredSections: [SettingsSection] {
        if searchText.isEmpty {
            return allSections
        }

        return allSections.compactMap { section in
            let filteredItems = section.items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.subtitle?.localizedCaseInsensitiveContains(searchText) ?? false ||
                section.title.localizedCaseInsensitiveContains(searchText)
            }

            if filteredItems.isEmpty {
                return nil
            }

            return SettingsSection(
                id: section.id,
                title: section.title,
                icon: section.icon,
                items: filteredItems
            )
        }
    }

    /// Sync health status indicator
    private var syncHealthIndicator: (color: Color, label: String) {
        guard healthKitService.isAuthorized else {
            return (.gray, "Not Connected")
        }

        guard let lastSync = healthKitService.lastSyncDate else {
            return (.orange, "Never Synced")
        }

        let hoursSinceSync = Date().timeIntervalSince(lastSync) / 3600

        if hoursSinceSync < 6 {
            return (.green, "Healthy")
        } else if hoursSinceSync < 24 {
            return (.yellow, "Needs Sync")
        } else {
            return (.red, "Outdated")
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Quick Toggles Section (always visible at top, not searchable)
                if searchText.isEmpty {
                    quickTogglesSection
                }

                // Sync Status Card (always visible when health is connected)
                if searchText.isEmpty && healthKitService.isAuthorized {
                    syncStatusSection
                }

                // Filtered Settings Sections
                ForEach(filteredSections) { section in
                    settingsSection(section)
                }

                // No Results
                if filteredSections.isEmpty && !searchText.isEmpty {
                    noResultsView
                }
            }
            .searchable(text: $searchText, prompt: "Search settings...")
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await therapistLinkingVM.checkLinkStatus()
                settingsViewModel.loadPreferences()
            }
            .fullScreenCoverWithHaptic(isPresented: $showQuickSetup) {
                QuickSetupView()
            }
        }
    }

    // MARK: - Quick Toggles Section

    private var quickTogglesSection: some View {
        Section {
            VStack(spacing: Spacing.sm) {
                // Notifications Toggle
                QuickToggleRow(
                    icon: "bell.badge.fill",
                    iconColor: .modusCyan,
                    title: "Notifications",
                    isOn: $settingsViewModel.notificationsEnabled,
                    action: { await settingsViewModel.toggleNotifications() }
                )
                .accessibilityLabel("Notifications")
                .accessibilityValue(settingsViewModel.notificationsEnabled ? "On" : "Off")
                .accessibilityHint("Toggle to enable or disable push notifications")

                Divider()
                    .padding(.vertical, Spacing.xxs)

                // Haptic Feedback Toggle
                QuickToggleRow(
                    icon: "hand.tap.fill",
                    iconColor: .modusTealAccent,
                    title: "Haptic Feedback",
                    isOn: $settingsViewModel.hapticFeedbackEnabled,
                    action: { await settingsViewModel.toggleHapticFeedback() }
                )
                .accessibilityLabel("Haptic Feedback")
                .accessibilityValue(settingsViewModel.hapticFeedbackEnabled ? "On" : "Off")
                .accessibilityHint("Toggle to enable or disable haptic feedback throughout the app")

                Divider()
                    .padding(.vertical, Spacing.xxs)

                // Dark Mode Toggle (System vs Manual)
                QuickToggleRow(
                    icon: "moon.fill",
                    iconColor: .modusDeepTeal,
                    title: "Dark Mode",
                    isOn: $settingsViewModel.darkModeEnabled,
                    action: { await settingsViewModel.toggleDarkMode() }
                )
                .accessibilityLabel("Dark Mode")
                .accessibilityValue(settingsViewModel.darkModeEnabled ? "On" : "Off")
                .accessibilityHint("Toggle dark mode appearance")
            }
            .padding(.vertical, Spacing.xs)
        } header: {
            HStack {
                Image(systemName: "bolt.circle.fill")
                    .foregroundColor(.modusCyan)
                Text("Quick Toggles")
            }
            .accessibilityAddTraits(.isHeader)
        } footer: {
            Text("Quickly toggle commonly used preferences")
        }
    }

    // MARK: - Sync Status Section

    private var syncStatusSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .foregroundColor(.modusCyan)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Health Data Sync")
                            .font(.headline)
                        Text(healthKitService.isAuthorized ? "Connected to Apple Health" : "Not connected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .accessibilityElement(children: .combine)

                Divider()

                // Sync Health Indicator
                HStack {
                    Circle()
                        .fill(syncHealthIndicator.color)
                        .frame(width: 12, height: 12)
                    Text("Status: \(syncHealthIndicator.label)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .accessibilityLabel("Sync status: \(syncHealthIndicator.label)")

                // Last Sync Time
                if let lastSync = healthKitService.lastSyncDate {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text("Last synced \(lastSync, style: .relative)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .accessibilityElement(children: .combine)
                }

                // Manual Refresh Button
                Button {
                    HapticFeedback.medium()
                    Task {
                        await refreshSyncStatus()
                    }
                } label: {
                    HStack {
                        if isRefreshingSyncStatus {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Sync Now")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.modusCyan.opacity(0.1))
                    .foregroundColor(.modusCyan)
                    .cornerRadius(CornerRadius.sm)
                }
                .disabled(isRefreshingSyncStatus)
                .buttonStyle(.plain)
                .accessibilityLabel(isRefreshingSyncStatus ? "Syncing health data" : "Sync now")
                .accessibilityHint("Manually refresh health data from Apple Health")
            }
            .padding(.vertical, Spacing.xs)
        } header: {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.modusTealAccent)
                Text("Sync Status")
            }
            .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: - Settings Section

    private func settingsSection(_ section: SettingsSection) -> some View {
        Section {
            ForEach(section.items) { item in
                settingRow(item)
            }
        } header: {
            if !searchText.isEmpty || !section.title.isEmpty {
                HStack {
                    if let icon = section.icon {
                        Image(systemName: icon)
                            .foregroundColor(.modusCyan)
                    }
                    Text(section.title)
                }
                .accessibilityAddTraits(.isHeader)
            }
        }
    }

    // MARK: - Setting Row

    @ViewBuilder
    private func settingRow(_ item: SettingItem) -> some View {
        switch item.type {
        case .navigation(let destination):
            NavigationLink {
                destination
            } label: {
                settingLabel(item)
            }
            .accessibilityLabel(item.title)
            .accessibilityHint(item.subtitle ?? "")

        case .button(let action):
            Button {
                HapticFeedback.light()
                action()
            } label: {
                settingLabel(item)
            }
            .accessibilityLabel(item.title)
            .accessibilityHint(item.subtitle ?? "")

        case .toggle(let binding, let action):
            Toggle(isOn: Binding(
                get: { binding.wrappedValue },
                set: { newValue in
                    binding.wrappedValue = newValue
                    HapticFeedback.toggle()
                    if let action = action {
                        action(newValue)
                    }
                }
            )) {
                settingLabel(item)
            }
            .accessibilityLabel(item.title)
            .accessibilityValue(binding.wrappedValue ? "On" : "Off")
        }
    }

    // MARK: - Setting Label

    private func settingLabel(_ item: SettingItem) -> some View {
        HStack(spacing: Spacing.sm) {
            if let icon = item.icon {
                Image(systemName: icon)
                    .foregroundColor(item.iconColor ?? .modusCyan)
                    .frame(width: 28)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .foregroundColor(item.isDestructive ? .red : .primary)

                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let badge = item.badge {
                Text(badge)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(item.badgeColor?.opacity(0.2) ?? Color.orange.opacity(0.2))
                    .foregroundColor(item.badgeColor ?? .orange)
                    .cornerRadius(CornerRadius.xs)
                    .accessibilityHidden(true)
            }
        }
    }

    // MARK: - No Results View

    private var noResultsView: some View {
        Section {
            VStack(spacing: Spacing.md) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)

                Text("No Settings Found")
                    .font(.headline)

                Text("Try searching for something else")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xl)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("No settings found. Try searching for something else")
        }
    }

    // MARK: - Actions

    private func refreshSyncStatus() async {
        isRefreshingSyncStatus = true
        defer { isRefreshingSyncStatus = false }

        do {
            _ = try await healthKitService.syncTodayData()
            lastSyncTime = Date()
            HapticFeedback.success()
        } catch {
            HapticFeedback.error()
            DebugLogger.shared.error("UnifiedSettingsView", "Sync failed: \(error.localizedDescription)")
        }
    }

    private func logout() async {
        do {
            try await PTSupabaseClient.shared.signOut()
            await MainActor.run {
                appState.isAuthenticated = false
                appState.userRole = nil
                appState.userId = nil
            }
        } catch {
            DebugLogger.shared.error("UnifiedSettingsView", "Logout error: \(error.localizedDescription)")
        }
    }

    // MARK: - All Sections

    private var allSections: [SettingsSection] {
        [
            accountSection,
            preferencesSection,
            healthDataSection,
            supportSection,
            debugSection
        ].compactMap { $0 }
    }

    // MARK: - Account Section

    private var accountSection: SettingsSection {
        var items: [SettingItem] = []

        // Profile & Subscription
        items.append(SettingItem(
            id: "subscription",
            icon: "star.fill",
            iconColor: .yellow,
            title: "Subscription",
            subtitle: subscriptionPlanText,
            type: .navigation(
                AnyView(SubscriptionView().environmentObject(storeKit))
            )
        ))

        // Therapist Linking
        items.append(SettingItem(
            id: "therapist",
            icon: therapistLinkingVM.isLinked ? "person.2.fill" : "person.badge.plus",
            iconColor: therapistLinkingVM.isLinked ? .green : .modusCyan,
            title: "Therapist Linking",
            subtitle: therapistLinkStatusText,
            type: .navigation(
                AnyView(TherapistLinkingView())
            )
        ))

        // Sign Out
        items.append(SettingItem(
            id: "signout",
            icon: "rectangle.portrait.and.arrow.right",
            iconColor: .modusCyan,
            title: "Sign Out",
            type: .button({
                Task {
                    await logout()
                }
            })
        ))

        // Delete Account
        items.append(SettingItem(
            id: "delete",
            icon: "trash.fill",
            iconColor: .red,
            title: "Delete Account",
            isDestructive: true,
            type: .navigation(
                AnyView(AccountDeletionView())
            )
        ))

        return SettingsSection(
            id: "account",
            title: "Account",
            icon: "person.circle.fill",
            items: items
        )
    }

    // MARK: - Preferences Section

    private var preferencesSection: SettingsSection {
        var items: [SettingItem] = []

        // Units & Measurements
        items.append(SettingItem(
            id: "units",
            icon: "ruler",
            iconColor: .modusCyan,
            title: "Units & Measurements",
            subtitle: "Weight, distance, temperature",
            type: .navigation(
                AnyView(Text("Units Settings (To Be Implemented)"))
            )
        ))

        // Theme
        items.append(SettingItem(
            id: "theme",
            icon: "paintbrush.fill",
            iconColor: .modusTealAccent,
            title: "Appearance",
            subtitle: settingsViewModel.darkModeEnabled ? "Dark" : "Light",
            type: .navigation(
                AnyView(Text("Theme Settings (To Be Implemented)"))
            )
        ))

        // Notifications Detail
        items.append(SettingItem(
            id: "notifications",
            icon: "bell.fill",
            iconColor: .modusCyan,
            title: "Notification Settings",
            subtitle: "Smart timing, reminders, alerts",
            type: .navigation(
                AnyView(NotificationSettingsView())
            )
        ))

        // Video Settings
        items.append(SettingItem(
            id: "video",
            icon: "play.rectangle.fill",
            iconColor: .purple,
            title: "Video Settings",
            subtitle: "Quality, playback speed, captions",
            type: .navigation(
                AnyView(VideoSettingsView())
            )
        ))

        // Haptic Feedback Detail
        items.append(SettingItem(
            id: "haptics",
            icon: "hand.tap.fill",
            iconColor: .modusTealAccent,
            title: "Haptic Feedback",
            subtitle: settingsViewModel.hapticFeedbackEnabled ? "Enabled" : "Disabled",
            type: .navigation(
                AnyView(Text("Haptic Settings (To Be Implemented)"))
            )
        ))

        return SettingsSection(
            id: "preferences",
            title: "Preferences",
            icon: "slider.horizontal.3",
            items: items
        )
    }

    // MARK: - Health & Data Section

    private var healthDataSection: SettingsSection {
        var items: [SettingItem] = []

        // Apple Health
        items.append(SettingItem(
            id: "applehealth",
            icon: "heart.circle.fill",
            iconColor: .red,
            title: "Apple Health",
            subtitle: healthKitService.isAuthorized ? "Connected" : "Not connected",
            badge: healthKitService.isAuthorized ? nil : "Connect",
            badgeColor: .modusCyan,
            type: .navigation(
                AnyView(HealthKitSettingsView().environmentObject(healthKitService))
            )
        ))

        // Wearable Devices
        items.append(SettingItem(
            id: "wearables",
            icon: "applewatch",
            iconColor: .modusCyan,
            title: "Wearable Devices",
            subtitle: "Connect fitness trackers",
            type: .navigation(
                AnyView(WearableSettingsView().environmentObject(WearableConnectionManager.shared))
            )
        ))

        // Export My Data - Prominent button
        items.append(SettingItem(
            id: "export",
            icon: "square.and.arrow.up.fill",
            iconColor: .modusTealAccent,
            title: "Export My Data",
            subtitle: "Download all your workout data",
            badge: "Export",
            badgeColor: .modusTealAccent,
            type: .button({
                HapticFeedback.medium()
                Task {
                    await settingsViewModel.exportUserData()
                }
            })
        ))

        // Calendar Sync
        items.append(SettingItem(
            id: "calendar",
            icon: "calendar",
            iconColor: .orange,
            title: "Calendar Sync",
            subtitle: "Sync workouts with calendar",
            type: .navigation(
                AnyView(CalendarSettingsView())
            )
        ))

        return SettingsSection(
            id: "healthdata",
            title: "Health & Data",
            icon: "heart.text.square.fill",
            items: items
        )
    }

    // MARK: - Support Section

    private var supportSection: SettingsSection {
        var items: [SettingItem] = []

        // Help & Learn
        items.append(SettingItem(
            id: "help",
            icon: "book.fill",
            iconColor: .modusCyan,
            title: "Help & Learn",
            subtitle: "Guides and tutorials",
            badge: storeKit.isPremium ? nil : "PRO",
            badgeColor: .orange,
            type: .navigation(
                AnyView(premiumGatedView(
                    premium: { HelpView() },
                    locked: { PremiumLockedView(feature: "Help", icon: "book.fill", description: "Access comprehensive guides and tutorials") }
                ))
            )
        ))

        // Tutorial
        items.append(SettingItem(
            id: "tutorial",
            icon: "questionmark.circle.fill",
            iconColor: .modusCyan,
            title: "View Tutorial",
            subtitle: "Replay app walkthrough",
            type: .button({
                HapticFeedback.medium()
                onboardingCoordinator.resetOnboarding()
            })
        ))

        // Quick Setup
        items.append(SettingItem(
            id: "quicksetup",
            icon: "sparkles",
            iconColor: .modusCyan,
            title: "Quick Setup",
            subtitle: "Configure mode, goals, preferences",
            type: .button({
                HapticFeedback.light()
                showQuickSetup = true
            })
        ))

        // Feedback
        items.append(SettingItem(
            id: "feedback",
            icon: "envelope.fill",
            iconColor: .modusTealAccent,
            title: "Send Feedback",
            subtitle: "Help us improve the app",
            type: .button({
                HapticFeedback.medium()
                // Open feedback form or email
            })
        ))

        // Privacy Notice
        items.append(SettingItem(
            id: "privacy",
            icon: "hand.raised.fill",
            iconColor: .modusCyan,
            title: "Privacy Notice",
            type: .navigation(
                AnyView(PrivacyNoticeView(onAccept: {}))
            )
        ))

        // About
        items.append(SettingItem(
            id: "about",
            icon: "info.circle.fill",
            iconColor: .modusCyan,
            title: "About",
            subtitle: "Version \(settingsViewModel.appVersion)",
            type: .navigation(
                AnyView(AboutView())
            )
        ))

        return SettingsSection(
            id: "support",
            title: "Support",
            icon: "lifepreserver.fill",
            items: items
        )
    }

    // MARK: - Debug Section

    private var debugSection: SettingsSection? {
        #if DEBUG
        var items: [SettingItem] = []

        items.append(SettingItem(
            id: "debug_premium",
            icon: storeKit.isPremium ? "lock.open.fill" : "lock.fill",
            iconColor: storeKit.isPremium ? .green : .gray,
            title: "Premium Features",
            subtitle: storeKit.isPremium ? "Enabled" : "Disabled",
            type: .toggle(
                Binding(
                    get: { storeKit.debugPremiumOverride ?? false },
                    set: { storeKit.debugPremiumOverride = $0 }
                ),
                nil
            )
        ))

        if storeKit.debugPremiumOverride != nil {
            items.append(SettingItem(
                id: "debug_reset",
                icon: "arrow.counterclockwise",
                iconColor: .modusCyan,
                title: "Reset to Real Status",
                type: .button({
                    storeKit.debugPremiumOverride = nil
                })
            ))
        }

        items.append(SettingItem(
            id: "debug_logs",
            icon: "terminal.fill",
            iconColor: .green,
            title: "Debug Logs",
            type: .navigation(
                AnyView(DebugLogView())
            )
        ))

        return SettingsSection(
            id: "debug",
            title: "Debug",
            icon: "ladybug.fill",
            items: items
        )
        #else
        return nil
        #endif
    }

    // MARK: - Helper Properties

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

    private var therapistLinkStatusText: String {
        if therapistLinkingVM.isLinked {
            return therapistLinkingVM.therapistName ?? "Linked"
        } else {
            return "Not linked"
        }
    }

    // MARK: - Premium Gated View Helper

    @ViewBuilder
    private func premiumGatedView<Premium: View, Locked: View>(
        @ViewBuilder premium: () -> Premium,
        @ViewBuilder locked: () -> Locked
    ) -> some View {
        if storeKit.isPremium {
            premium()
        } else {
            locked()
                .environmentObject(storeKit)
        }
    }
}

// MARK: - Quick Toggle Row

private struct QuickToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    let action: () async -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 28)
                .accessibilityHidden(true)

            Text(title)
                .font(.body)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.modusCyan)
                .onChange(of: isOn) { _, _ in
                    Task {
                        await action()
                    }
                }
        }
    }
}

// MARK: - Settings Models

struct SettingsSection: Identifiable {
    let id: String
    let title: String
    let icon: String?
    let items: [SettingItem]
}

struct SettingItem: Identifiable {
    let id: String
    let icon: String?
    let iconColor: Color?
    let title: String
    let subtitle: String?
    let badge: String?
    let badgeColor: Color?
    let isDestructive: Bool
    let type: SettingItemType

    init(
        id: String,
        icon: String? = nil,
        iconColor: Color? = nil,
        title: String,
        subtitle: String? = nil,
        badge: String? = nil,
        badgeColor: Color? = nil,
        isDestructive: Bool = false,
        type: SettingItemType
    ) {
        self.id = id
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.badgeColor = badgeColor
        self.isDestructive = isDestructive
        self.type = type
    }
}

enum SettingItemType {
    case navigation(AnyView)
    case button(() -> Void)
    case toggle(Binding<Bool>, ((Bool) -> Void)?)
}

// MARK: - Settings View Model

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled = true
    @Published var hapticFeedbackEnabled = true
    @Published var darkModeEnabled = false
    @Published var appVersion = "1.0"

    @Published var isExportingData = false
    @Published var exportError: String?

    init() {
        loadPreferences()
        loadAppVersion()
    }

    func loadPreferences() {
        // Load from UserDefaults or service
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        hapticFeedbackEnabled = UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled")
        darkModeEnabled = UserDefaults.standard.bool(forKey: "darkModeEnabled")
    }

    func toggleNotifications() async {
        notificationsEnabled.toggle()
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")

        if notificationsEnabled {
            HapticFeedback.success()
        } else {
            HapticFeedback.light()
        }
    }

    func toggleHapticFeedback() async {
        hapticFeedbackEnabled.toggle()
        UserDefaults.standard.set(hapticFeedbackEnabled, forKey: "hapticFeedbackEnabled")

        if hapticFeedbackEnabled {
            HapticFeedback.success()
        }
    }

    func toggleDarkMode() async {
        darkModeEnabled.toggle()
        UserDefaults.standard.set(darkModeEnabled, forKey: "darkModeEnabled")
        HapticFeedback.toggle()
    }

    func exportUserData() async {
        isExportingData = true
        defer { isExportingData = false }

        do {
            // Implement data export logic
            // This would gather all user data and create a downloadable file
            try await Task.sleep(nanoseconds: 2_000_000_000) // Simulate export
            HapticFeedback.success()
        } catch {
            exportError = error.localizedDescription
            HapticFeedback.error()
        }
    }

    private func loadAppVersion() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            appVersion = "\(version) (\(build))"
        }
    }
}

// MARK: - About View (Placeholder)

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .center, spacing: Spacing.md) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.modusCyan)
                        .accessibilityHidden(true)

                    Text("PT Performance")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Modus")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .accessibilityElement(children: .combine)
            }

            Section("Information") {
                HStack {
                    Text("Version")
                    Spacer()
                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        Text(version)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Text("Build")
                    Spacer()
                    if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                        Text(build)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section("Legal") {
                Link("Terms of Service", destination: URL(string: "https://getmodus.com/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://getmodus.com/privacy")!)
            }

            Section {
                Text("© 2026 Modus. All rights reserved.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    UnifiedSettingsView()
        .environmentObject(StoreKitService.shared)
        .environmentObject(AppState())
}
