//
//  FeatureVisibilityViewModel.swift
//  PTPerformance
//
//  Created by Claude (BUILD 115) on 2026-01-02.
//  Feature visibility logic based on patient mode
//

import Foundation
import Combine
import SwiftUI

/// Manages which features are visible based on patient mode
@MainActor
class FeatureVisibilityViewModel: ObservableObject {
    @Published var visibleFeatures: Set<String> = []
    @Published var currentMode: Mode = .rehab

    private let modeService = ModeService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Update visible features when mode changes
        modeService.$currentMode
            .sink { [weak self] mode in
                self?.currentMode = mode
                self?.updateVisibleFeatures()
            }
            .store(in: &cancellables)

        modeService.$modeFeatures
            .sink { [weak self] _ in
                self?.updateVisibleFeatures()
            }
            .store(in: &cancellables)
    }

    /// Update visible features based on current mode
    private func updateVisibleFeatures() {
        visibleFeatures = Set(modeService.modeFeatures.map { $0.featureKey })

        #if DEBUG
        print("✅ Visible features updated: \(visibleFeatures.count) for \(currentMode.displayName)")
        #endif
    }

    /// Check if a feature is visible
    func isVisible(_ featureKey: FeatureKey) -> Bool {
        return visibleFeatures.contains(featureKey.rawValue)
    }

    /// Check if a feature is visible (string-based for dynamic checks)
    func isVisible(_ featureKey: String) -> Bool {
        return visibleFeatures.contains(featureKey)
    }

    /// Get tab bar items for current mode
    func tabBarItems() -> [TabBarItem] {
        switch currentMode {
        case .rehab:
            return [
                TabBarItem(title: "Today", icon: "calendar", featureKey: nil),
                TabBarItem(title: "History", icon: "clock.arrow.circlepath", featureKey: nil),
                TabBarItem(title: "PT Chat", icon: "message.fill", featureKey: .ptMessaging),
                TabBarItem(title: "Help", icon: "questionmark.circle", featureKey: nil)
            ]

        case .strength:
            return [
                TabBarItem(title: "Today", icon: "calendar", featureKey: nil),
                TabBarItem(title: "PRs", icon: "trophy.fill", featureKey: .prTracking),
                TabBarItem(title: "History", icon: "chart.bar.fill", featureKey: .volumeTrends),
                TabBarItem(title: "Programs", icon: "list.bullet", featureKey: nil),
                TabBarItem(title: "Help", icon: "questionmark.circle", featureKey: nil)
            ]

        case .performance:
            return [
                TabBarItem(title: "Readiness", icon: "bolt.heart.fill", featureKey: .readinessScore),
                TabBarItem(title: "Today", icon: "calendar", featureKey: nil),
                TabBarItem(title: "Team", icon: "person.3.fill", featureKey: .teamManagement),
                TabBarItem(title: "Analytics", icon: "chart.xyaxis.line", featureKey: .advancedAnalytics),
                TabBarItem(title: "Programs", icon: "list.bullet", featureKey: nil)
            ]
        }
    }

    /// Get sections visible in History view for current mode
    func historyViewSections() -> [HistorySection] {
        var sections: [HistorySection] = [
            HistorySection(title: "Recent Sessions", icon: "clock", featureKey: nil)
        ]

        if isVisible(.painTracking) {
            sections.append(HistorySection(title: "Pain Trend", icon: "heart.text.square", featureKey: .painTracking))
        }

        if isVisible(.volumeTrends) {
            sections.append(HistorySection(title: "Volume Trends", icon: "chart.bar", featureKey: .volumeTrends))
        }

        if isVisible(.prTracking) {
            sections.append(HistorySection(title: "Personal Records", icon: "trophy", featureKey: .prTracking))
        }

        if isVisible(.readinessScore) {
            sections.append(HistorySection(title: "Readiness History", icon: "bolt.heart", featureKey: .readinessScore))
        }

        return sections
    }
}

/// Tab bar item definition
struct TabBarItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let featureKey: FeatureKey?  // nil = always visible

    var isVisible: Bool {
        guard let featureKey = featureKey else { return true }
        return ModeService.shared.isFeatureEnabled(featureKey)
    }
}

/// History section definition
struct HistorySection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let featureKey: FeatureKey?  // nil = always visible
}

/// SwiftUI View extension for conditional feature visibility
extension View {
    /// Show this view only if feature is enabled
    @ViewBuilder
    func visibleIf(_ featureKey: FeatureKey) -> some View {
        if ModeService.shared.isFeatureEnabled(featureKey) {
            self
        }
    }

    /// Show this view only if feature is enabled (with alternative view)
    @ViewBuilder
    func visibleIf(_ featureKey: FeatureKey, else alternativeView: @escaping () -> some View) -> some View {
        if ModeService.shared.isFeatureEnabled(featureKey) {
            self
        } else {
            alternativeView()
        }
    }
}
