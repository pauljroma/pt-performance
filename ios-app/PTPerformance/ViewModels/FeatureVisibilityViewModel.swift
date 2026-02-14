//
//  FeatureVisibilityViewModel.swift
//  PTPerformance
//
//  Feature visibility logic based on patient mode
//

import Combine
import SwiftUI

/// Manages which features are visible based on patient mode.
///
/// Architecture note: This ViewModel provides an `@EnvironmentObject`-compatible wrapper
/// around `ModeService.shared` for views that need reactive feature-visibility state
/// (e.g. published `visibleFeatures` set). The companion `visibleIf(_:)` View extension
/// is a lightweight convenience that reads the same `ModeService.shared` source of truth
/// directly, avoiding the need to inject an environment object for simple show/hide logic.
/// Both paths resolve to the same underlying data; they are complementary, not redundant.
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

        DebugLogger.shared.log("[FeatureVisibility] Visible features updated: \(visibleFeatures.count) for \(currentMode.displayName)", level: .diagnostic)
    }

    /// Check if a feature is visible
    func isVisible(_ featureKey: FeatureKey) -> Bool {
        return visibleFeatures.contains(featureKey.rawValue)
    }

}

/// SwiftUI View extension for conditional feature visibility
extension View {
    /// Show this view only if feature is enabled
    @MainActor @ViewBuilder
    func visibleIf(_ featureKey: FeatureKey) -> some View {
        if ModeService.shared.isFeatureEnabled(featureKey) {
            self
        }
    }

    /// Show this view only if feature is enabled (with alternative view)
    @MainActor @ViewBuilder
    func visibleIf(_ featureKey: FeatureKey, else alternativeView: @escaping () -> some View) -> some View {
        if ModeService.shared.isFeatureEnabled(featureKey) {
            self
        } else {
            alternativeView()
        }
    }
}
