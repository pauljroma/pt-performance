//
//  TimerPickerViewModel.swift
//  PTPerformance
//
//  Created by BUILD 116 Agent 13 (Timer Picker ViewModel)
//  ViewModel for browsing and selecting timer presets
//

import Foundation
import SwiftUI

/// ViewModel for timer preset picker
/// Handles preset loading, filtering, search, and selection
@MainActor
class TimerPickerViewModel: ObservableObject {
    // MARK: - Dependencies

    private let timerService: IntervalTimerService
    private let patientId: UUID

    // MARK: - Data State

    /// All timer presets loaded from database
    @Published var allPresets: [TimerPreset] = []

    /// Filtered presets based on category and search
    @Published var filteredPresets: [TimerPreset] = []

    // MARK: - UI State

    /// Loading state for preset fetch
    @Published var isLoading: Bool = false

    /// Error state
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""

    /// Category filter (nil = show all)
    @Published var selectedCategory: TimerCategory?

    /// Search query text
    @Published var searchText: String = "" {
        didSet {
            applyFilters()
        }
    }

    /// Currently selected preset
    @Published var selectedPreset: TimerPreset?

    // MARK: - Navigation State

    /// Show custom timer builder sheet
    @Published var showCustomBuilder: Bool = false

    /// Show active timer view
    @Published var showActiveTimer: Bool = false

    /// Show preset detail sheet
    @Published var showPresetDetail: Bool = false

    // MARK: - Computed Properties

    /// Presets grouped by category for sectioned display
    var categorizedPresets: [TimerCategory: [TimerPreset]] {
        Dictionary(grouping: filteredPresets) { $0.category }
    }

    /// Whether we have any filtered results
    var hasResults: Bool {
        !filteredPresets.isEmpty
    }

    /// Whether search is active
    var isSearching: Bool {
        !searchText.isEmpty
    }

    /// Count of filtered presets
    var presetCount: Int {
        filteredPresets.count
    }

    /// Category counts for badge display
    var categoryCounts: [TimerCategory: Int] {
        var counts: [TimerCategory: Int] = [:]
        for category in TimerCategory.allCases {
            counts[category] = allPresets.filter { $0.category == category }.count
        }
        return counts
    }

    // MARK: - Initialization

    @MainActor init(
        patientId: UUID,
        timerService: IntervalTimerService? = nil
    ) {
        self.patientId = patientId
        self.timerService = timerService ?? .shared
    }

    // MARK: - Load Presets

    /// Load all timer presets from database
    func loadPresets() async {
        isLoading = true
        showError = false

        // BUILD 133: Enhanced logging for timer screen errors
        DebugLogger.shared.info("TIMER_SCREEN", """
            Loading timer presets:
            Patient ID: \(patientId.uuidString)
            Current preset count: \(allPresets.count)
            """)

        do {
            allPresets = try await timerService.fetchPresets()
            applyFilters()

            DebugLogger.shared.success("TIMER_SCREEN", """
                Timer presets loaded successfully:
                Total presets: \(allPresets.count)
                Filtered presets: \(filteredPresets.count)
                Selected category: \(selectedCategory?.displayName ?? "All")
                """)
        } catch {
            errorMessage = error.localizedDescription
            showError = true

            // BUILD 133: Detailed error logging
            DebugLogger.shared.error("TIMER_SCREEN", """
                FAILED to load timer presets:
                Error: \(error.localizedDescription)
                Type: \(type(of: error))
                Patient ID: \(patientId.uuidString)
                This error will be shown to user
                """)
        }

        isLoading = false

        DebugLogger.shared.info("TIMER_SCREEN", """
            Preset loading complete:
            Loading: \(isLoading)
            Show error: \(showError)
            Error message: \(errorMessage)
            """)
    }

    // MARK: - Category Selection

    /// Select a category filter (nil to clear filter)
    func selectCategory(_ category: TimerCategory?) {
        selectedCategory = category
        applyFilters()

        #if DEBUG
        if let category = category {
            print("📁 Filtered to category: \(category.displayName)")
        } else {
            print("📁 Cleared category filter")
        }
        #endif
    }

    /// Toggle category selection (select if different, clear if same)
    func toggleCategory(_ category: TimerCategory) {
        if selectedCategory == category {
            selectCategory(nil)
        } else {
            selectCategory(category)
        }
    }

    /// Clear category filter
    func clearCategoryFilter() {
        selectCategory(nil)
    }

    // MARK: - Search

    /// Update search text (filtering happens automatically via didSet)
    func search(_ query: String) {
        searchText = query
    }

    /// Clear search text
    func clearSearch() {
        searchText = ""
    }

    /// Apply category and search filters to presets
    private func applyFilters() {
        var results = allPresets

        // Category filter
        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }

        // Search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            results = results.filter { preset in
                // Search in name
                if preset.name.lowercased().contains(query) {
                    return true
                }

                // Search in description
                if let description = preset.description,
                   description.lowercased().contains(query) {
                    return true
                }

                // Search in timer type
                if preset.templateJson.type.displayName.lowercased().contains(query) {
                    return true
                }

                // Search in difficulty
                if let difficulty = preset.templateJson.difficulty,
                   difficulty.displayName.lowercased().contains(query) {
                    return true
                }

                // Search in equipment
                if let equipment = preset.templateJson.equipment,
                   equipment.lowercased().contains(query) {
                    return true
                }

                return false
            }
        }

        filteredPresets = results

        #if DEBUG
        print("🔍 Filtered: \(filteredPresets.count) results (category: \(selectedCategory?.rawValue ?? "all"), search: '\(searchText)')")
        #endif
    }

    // MARK: - Preset Selection

    /// Select a preset
    func selectPreset(_ preset: TimerPreset) {
        selectedPreset = preset

        #if DEBUG
        print("✅ Selected preset: \(preset.name)")
        #endif
    }

    /// Show preset detail
    func showDetail(for preset: TimerPreset) {
        selectedPreset = preset
        showPresetDetail = true
    }

    /// Clear preset selection
    func clearSelection() {
        selectedPreset = nil
        showPresetDetail = false
    }

    // MARK: - Start Timer

    /// Start timer with selected preset
    func startTimer(with preset: TimerPreset) async {
        do {
            // Convert preset to interval template
            let template = preset.toIntervalTemplate()

            // Start timer via service
            try await timerService.startTimer(template: template, patientId: patientId)

            // Navigate to active timer
            showActiveTimer = true

            #if DEBUG
            print("▶️ Started timer: \(preset.name)")
            #endif

        } catch {
            errorMessage = error.localizedDescription
            showError = true

            DebugLogger.shared.error("TIMER_START", """
                Failed to start timer:
                Preset: \(preset.name)
                Error: \(error.localizedDescription)
                Type: \(type(of: error))
                Patient ID: \(patientId.uuidString)
                """)
        }
    }

    /// Quick start timer with currently selected preset
    func quickStart() async {
        guard let preset = selectedPreset else {
            errorMessage = "Please select a timer preset first, then tap Start."
            showError = true
            return
        }

        await startTimer(with: preset)
    }

    // MARK: - Custom Timer Builder

    /// Show custom timer builder
    func showCustomTimerBuilder() {
        showCustomBuilder = true

        #if DEBUG
        print("🔨 Opening custom timer builder")
        #endif
    }

    // MARK: - Refresh

    /// Refresh presets from database
    func refresh() async {
        await loadPresets()
    }

    // MARK: - Sorting

    /// Sort presets by name (A-Z)
    func sortByName() {
        filteredPresets.sort { $0.name < $1.name }
    }

    /// Sort presets by duration (shortest first)
    func sortByDuration() {
        filteredPresets.sort(by: { preset1, preset2 in
            let duration1 = preset1.templateJson.totalDuration ?? preset1.templateJson.calculatedDuration
            let duration2 = preset2.templateJson.totalDuration ?? preset2.templateJson.calculatedDuration
            return duration1 < duration2
        })
    }

    /// Sort presets by difficulty (easiest first)
    func sortByDifficulty() {
        let difficultyOrder: [TimerPreset.TemplateJSON.Difficulty] = [.easy, .moderate, .hard, .veryHard]
        filteredPresets.sort { preset1, preset2 in
            guard let diff1 = preset1.templateJson.difficulty,
                  let diff2 = preset2.templateJson.difficulty else {
                return false  // Put presets without difficulty at the end
            }
            let index1 = difficultyOrder.firstIndex(of: diff1) ?? 0
            let index2 = difficultyOrder.firstIndex(of: diff2) ?? 0
            return index1 < index2
        }
    }

    // MARK: - Filtering Helpers

    /// Get presets for specific category
    func presets(for category: TimerCategory) -> [TimerPreset] {
        allPresets.filter { $0.category == category }
    }

    /// Get presets by difficulty
    func presets(difficulty: TimerPreset.TemplateJSON.Difficulty) -> [TimerPreset] {
        allPresets.filter { $0.templateJson.difficulty == difficulty }
    }

    /// Get presets by timer type
    func presets(type: TimerType) -> [TimerPreset] {
        allPresets.filter { $0.templateJson.type == type }
    }

    /// Get quick start presets (popular/recommended)
    /// Returns first preset from each category
    func quickStartPresets() -> [TimerPreset] {
        var quick: [TimerPreset] = []
        for category in TimerCategory.allCases {
            if let first = allPresets.first(where: { $0.category == category }) {
                quick.append(first)
            }
        }
        return quick
    }

    // MARK: - Error Handling

    /// Dismiss error alert
    func dismissError() {
        showError = false
        errorMessage = ""
    }
}

// MARK: - Preview Support

extension TimerPickerViewModel {
    /// Preview instance with mock data
    static var preview: TimerPickerViewModel {
        let vm = TimerPickerViewModel(
            patientId: UUID(),
            timerService: .shared
        )

        // Mock presets for preview
        vm.allPresets = TimerPreset.samples
        vm.filteredPresets = TimerPreset.samples

        return vm
    }

    /// Preview instance with loading state
    static var previewLoading: TimerPickerViewModel {
        let vm = TimerPickerViewModel(
            patientId: UUID(),
            timerService: .shared
        )

        vm.isLoading = true

        return vm
    }

    /// Preview instance with error state
    static var previewError: TimerPickerViewModel {
        let vm = TimerPickerViewModel(
            patientId: UUID(),
            timerService: .shared
        )

        vm.showError = true
        vm.errorMessage = "Unable to load timer options. Pull down to refresh."

        return vm
    }

    /// Preview instance with filtered results
    static var previewFiltered: TimerPickerViewModel {
        let vm = TimerPickerViewModel(
            patientId: UUID(),
            timerService: .shared
        )

        vm.allPresets = TimerPreset.samples
        vm.selectedCategory = TimerCategory.cardio
        vm.filteredPresets = TimerPreset.samples.filter { $0.category == .cardio }

        return vm
    }
}
