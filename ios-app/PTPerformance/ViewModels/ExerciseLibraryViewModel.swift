//
//  ExerciseLibraryViewModel.swift
//  PTPerformance
//
//  ACP-1032: Exercise Search & Discovery
//  ViewModel for the enhanced exercise library with search, filters, and history
//

import SwiftUI
import Combine

// MARK: - Muscle Group

/// Muscle group categories for the visual browser
enum ExerciseMuscleGroup: String, CaseIterable, Identifiable, Hashable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case core = "Core"
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case fullBody = "Full Body"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .chest: return "figure.arms.open"
        case .back: return "figure.climbing"
        case .shoulders: return "figure.boxing"
        case .arms: return "figure.curling"
        case .core: return "figure.core.training"
        case .quads: return "figure.walk"
        case .hamstrings: return "figure.run"
        case .glutes: return "figure.step.training"
        case .calves: return "figure.stand"
        case .fullBody: return "figure.strengthtraining.traditional"
        }
    }

    var displayName: String { rawValue }

    /// Maps this muscle group to body region values from the database
    var bodyRegionMatches: [String] {
        switch self {
        case .chest: return ["chest", "upper", "push"]
        case .back: return ["back", "upper", "pull"]
        case .shoulders: return ["shoulders", "upper", "push"]
        case .arms: return ["arms", "upper", "biceps", "triceps"]
        case .core: return ["core", "abs", "abdominals"]
        case .quads: return ["quads", "lower", "legs", "quadriceps"]
        case .hamstrings: return ["hamstrings", "lower", "legs", "posterior"]
        case .glutes: return ["glutes", "lower", "hips", "hip"]
        case .calves: return ["calves", "lower", "legs"]
        case .fullBody: return ["full body", "full", "total body", "compound"]
        }
    }

    /// Maps this muscle group to category values from the database
    var categoryMatches: [String] {
        switch self {
        case .chest: return ["push", "chest", "bench"]
        case .back: return ["pull", "row", "back"]
        case .shoulders: return ["push", "press", "shoulder"]
        case .arms: return ["curl", "extension", "arm", "bicep", "tricep"]
        case .core: return ["core", "abs", "plank", "anti-rotation"]
        case .quads: return ["squat", "lunge", "leg press", "quad"]
        case .hamstrings: return ["hinge", "deadlift", "curl", "hamstring"]
        case .glutes: return ["hip thrust", "bridge", "glute"]
        case .calves: return ["calf", "raise"]
        case .fullBody: return ["clean", "snatch", "thruster", "burpee", "compound"]
        }
    }
}

// MARK: - Equipment Type

/// Equipment filter options
enum EquipmentType: String, CaseIterable, Identifiable, Hashable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case bodyweight = "Bodyweight"
    case cable = "Cable"
    case machine = "Machine"
    case bands = "Bands"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .barbell: return "figure.strengthtraining.traditional"
        case .dumbbell: return "dumbbell.fill"
        case .bodyweight: return "figure.stand"
        case .cable: return "cable.connector.horizontal"
        case .machine: return "gearshape.2.fill"
        case .bands: return "lasso"
        }
    }

    var displayName: String { rawValue }

    /// Keywords to match in exercise names or categories
    var matchKeywords: [String] {
        switch self {
        case .barbell: return ["barbell", "bar", "bb"]
        case .dumbbell: return ["dumbbell", "db", "dumbell"]
        case .bodyweight: return ["bodyweight", "bw", "calisthenics", "push-up", "pushup", "pull-up", "pullup", "dip", "plank"]
        case .cable: return ["cable"]
        case .machine: return ["machine", "smith", "leg press", "hack squat"]
        case .bands: return ["band", "resistance band", "tube"]
        }
    }
}

// MARK: - Difficulty Level

/// Difficulty level for exercises
enum ExerciseDifficulty: String, CaseIterable, Identifiable, Hashable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .beginner: return .modusTealAccent
        case .intermediate: return .modusCyan
        case .advanced: return .modusDeepTeal
        }
    }

    var iconName: String {
        switch self {
        case .beginner: return "1.circle.fill"
        case .intermediate: return "2.circle.fill"
        case .advanced: return "3.circle.fill"
        }
    }
}

// MARK: - Library Exercise Item

/// Enriched exercise model for library display
struct LibraryExerciseItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let category: String?
    let bodyRegion: String?
    let videoUrl: String?
    let videoThumbnailUrl: String?
    let videoDuration: Int?
    let difficulty: ExerciseDifficulty
    let equipment: EquipmentType?
    let muscleGroup: ExerciseMuscleGroup?

    init(from template: ExerciseTemplateData) {
        self.id = template.id
        self.name = template.name
        self.category = template.category
        self.bodyRegion = template.bodyRegion
        self.videoUrl = template.videoUrl
        self.videoThumbnailUrl = template.videoThumbnailUrl
        self.videoDuration = template.videoDuration
        self.difficulty = Self.inferDifficulty(name: template.name, category: template.category)
        self.equipment = Self.inferEquipment(name: template.name)
        self.muscleGroup = Self.inferExerciseMuscleGroup(name: template.name, category: template.category, bodyRegion: template.bodyRegion)
    }

    var hasVideo: Bool { videoUrl != nil }

    var videoDurationDisplay: String? {
        guard let duration = videoDuration else { return nil }
        let minutes = duration / 60
        let seconds = duration % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }

    // MARK: - Inference Helpers

    static func inferDifficulty(name: String, category: String?) -> ExerciseDifficulty {
        let lowerName = name.lowercased()
        let lowerCategory = category?.lowercased() ?? ""

        // Advanced patterns
        let advancedKeywords = ["snatch", "clean and jerk", "muscle-up", "pistol squat",
                                "handstand", "planche", "front lever", "back lever",
                                "dragon flag", "olympic"]
        if advancedKeywords.contains(where: { lowerName.contains($0) || lowerCategory.contains($0) }) {
            return .advanced
        }

        // Beginner patterns
        let beginnerKeywords = ["bodyweight", "wall sit", "plank", "bird dog",
                                "dead bug", "glute bridge", "band", "assisted",
                                "machine", "seated", "leg press"]
        if beginnerKeywords.contains(where: { lowerName.contains($0) || lowerCategory.contains($0) }) {
            return .beginner
        }

        return .intermediate
    }

    static func inferEquipment(name: String) -> EquipmentType? {
        let lowerName = name.lowercased()
        for equipType in EquipmentType.allCases {
            if equipType.matchKeywords.contains(where: { lowerName.contains($0) }) {
                return equipType
            }
        }
        return nil
    }

    static func inferExerciseMuscleGroup(name: String, category: String?, bodyRegion: String?) -> ExerciseMuscleGroup? {
        let lowerName = name.lowercased()
        let lowerCategory = category?.lowercased() ?? ""
        let lowerRegion = bodyRegion?.lowercased() ?? ""

        for group in ExerciseMuscleGroup.allCases {
            // Check name matches
            if group.categoryMatches.contains(where: { lowerName.contains($0) }) {
                return group
            }
            // Check category matches
            if group.categoryMatches.contains(where: { lowerCategory.contains($0) }) {
                return group
            }
            // Check body region matches
            if group.bodyRegionMatches.contains(where: { lowerRegion == $0 }) {
                return group
            }
        }
        return nil
    }
}

// MARK: - Recently Viewed Manager

/// Manages recently viewed exercise history using UserDefaults
class RecentlyViewedManager {
    static let shared = RecentlyViewedManager()
    private let key = "com.ptperformance.recentlyViewedExercises"
    private let maxItems = 10

    private init() {}

    /// Returns the IDs of recently viewed exercises (most recent first)
    var recentIds: [UUID] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let strings = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return strings.compactMap { UUID(uuidString: $0) }
    }

    /// Records a view of an exercise
    func recordView(exerciseId: UUID) {
        var ids = recentIds.map { $0.uuidString }
        ids.removeAll { $0 == exerciseId.uuidString }
        ids.insert(exerciseId.uuidString, at: 0)
        if ids.count > maxItems {
            ids = Array(ids.prefix(maxItems))
        }
        if let data = try? JSONEncoder().encode(ids) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// Clears the recently viewed list
    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

// MARK: - Exercise Library ViewModel

@MainActor
class ExerciseLibraryViewModel: ObservableObject {
    // MARK: - Published State

    /// All available exercises
    @Published var allExercises: [LibraryExerciseItem] = [] {
        didSet {
            recomputeExerciseCountsByGroup()
            recomputeFilteredExercises()
        }
    }

    /// Search text with debounce
    @Published var searchText: String = ""

    /// Active muscle group filter
    @Published var selectedExerciseMuscleGroup: ExerciseMuscleGroup? = nil {
        didSet { recomputeFilteredExercises() }
    }

    /// Active equipment filters (multi-select)
    @Published var selectedEquipment: Set<EquipmentType> = [] {
        didSet { recomputeFilteredExercises() }
    }

    /// Active difficulty filter
    @Published var selectedDifficulty: ExerciseDifficulty? = nil {
        didSet { recomputeFilteredExercises() }
    }

    /// Currently selected exercise for detail view
    @Published var selectedExercise: LibraryExerciseItem? = nil {
        didSet { recomputeCachedSimilarExercises() }
    }

    /// Recently viewed exercises
    @Published var recentlyViewed: [LibraryExerciseItem] = []

    /// Loading state
    @Published var isLoading = false

    /// Error message
    @Published var errorMessage: String?

    /// Popular exercises (most commonly used)
    @Published var popularExercises: [LibraryExerciseItem] = []

    /// Cached filtered exercises list (Fix 2: avoids recomputing on every access)
    @Published private(set) var cachedFilteredExercises: [LibraryExerciseItem] = []

    /// Pre-computed exercise counts per muscle group (Fix 3: avoids O(N*M) per render)
    @Published var exerciseCountsByGroup: [ExerciseMuscleGroup: Int] = [:]

    /// Cached similar exercises for the selected exercise (Fix 9: avoids recomputing on every access)
    @Published private(set) var cachedSimilarExercises: [LibraryExerciseItem] = []

    // MARK: - Private

    private var cancellables = Set<AnyCancellable>()
    private let recentManager = RecentlyViewedManager.shared
    private let logger = DebugLogger.shared

    // MARK: - Computed Properties

    /// Filtered exercise list based on active filters (delegates to cached version)
    var filteredExercises: [LibraryExerciseItem] {
        cachedFilteredExercises
    }

    /// Recomputes the cached filtered exercises list. Called from didSet of filter properties
    /// and from the search debounce pipeline. (Fix 2)
    private func recomputeFilteredExercises() {
        var results = allExercises

        // Apply muscle group filter
        if let group = selectedExerciseMuscleGroup {
            results = results.filter { exercise in
                if let mg = exercise.muscleGroup, mg == group {
                    return true
                }
                // Fallback: check body region and category
                let lowerName = exercise.name.lowercased()
                let lowerCategory = exercise.category?.lowercased() ?? ""
                let lowerRegion = exercise.bodyRegion?.lowercased() ?? ""
                return group.bodyRegionMatches.contains(where: { lowerRegion.contains($0) })
                    || group.categoryMatches.contains(where: { lowerCategory.contains($0) || lowerName.contains($0) })
            }
        }

        // Apply equipment filter
        if !selectedEquipment.isEmpty {
            results = results.filter { exercise in
                if let eq = exercise.equipment, selectedEquipment.contains(eq) {
                    return true
                }
                // Fallback: keyword match on exercise name
                let lowerName = exercise.name.lowercased()
                return selectedEquipment.contains(where: { equip in
                    equip.matchKeywords.contains(where: { lowerName.contains($0) })
                })
            }
        }

        // Apply difficulty filter
        if let difficulty = selectedDifficulty {
            results = results.filter { $0.difficulty == difficulty }
        }

        // Apply search text
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            results = results.filter { exercise in
                exercise.name.lowercased().contains(searchLower)
                    || (exercise.category?.lowercased().contains(searchLower) ?? false)
                    || (exercise.bodyRegion?.lowercased().contains(searchLower) ?? false)
            }
        }

        cachedFilteredExercises = results.sorted { $0.name < $1.name }
    }

    /// Pre-computes exercise counts per muscle group (Fix 3)
    private func recomputeExerciseCountsByGroup() {
        var counts: [ExerciseMuscleGroup: Int] = [:]
        for group in ExerciseMuscleGroup.allCases {
            counts[group] = allExercises.filter { exercise in
                if let mg = exercise.muscleGroup, mg == group { return true }
                let lowerName = exercise.name.lowercased()
                let lowerCategory = exercise.category?.lowercased() ?? ""
                let lowerRegion = exercise.bodyRegion?.lowercased() ?? ""
                return group.bodyRegionMatches.contains(where: { lowerRegion.contains($0) })
                    || group.categoryMatches.contains(where: { lowerCategory.contains($0) || lowerName.contains($0) })
            }.count
        }
        exerciseCountsByGroup = counts
    }

    /// Recomputes cached similar exercises when selectedExercise changes (Fix 9)
    private func recomputeCachedSimilarExercises() {
        guard let selected = selectedExercise else {
            cachedSimilarExercises = []
            return
        }
        cachedSimilarExercises = allExercises
            .filter { $0.id != selected.id }
            .filter { exercise in
                // Match on same muscle group
                if let selectedGroup = selected.muscleGroup,
                   let exerciseGroup = exercise.muscleGroup,
                   selectedGroup == exerciseGroup {
                    return true
                }
                // Match on same category
                if let selectedCat = selected.category?.lowercased(),
                   let exerciseCat = exercise.category?.lowercased(),
                   selectedCat == exerciseCat {
                    return true
                }
                // Match on same body region
                if let selectedRegion = selected.bodyRegion?.lowercased(),
                   let exerciseRegion = exercise.bodyRegion?.lowercased(),
                   selectedRegion == exerciseRegion {
                    return true
                }
                return false
            }
            .prefix(6)
            .map { $0 }
    }

    /// Whether any filters are active
    var hasActiveFilters: Bool {
        selectedExerciseMuscleGroup != nil || !selectedEquipment.isEmpty || selectedDifficulty != nil
    }

    /// Count of active filters
    var activeFilterCount: Int {
        var count = 0
        if selectedExerciseMuscleGroup != nil { count += 1 }
        count += selectedEquipment.count
        if selectedDifficulty != nil { count += 1 }
        return count
    }

    /// Similar exercises to the selected one (delegates to cached version, Fix 9)
    var similarExercises: [LibraryExerciseItem] {
        cachedSimilarExercises
    }

    // MARK: - Initialization

    init() {
        // Set up search debounce - recompute filtered exercises when search text changes
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.recomputeFilteredExercises()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    /// Loads all exercise templates from Supabase
    func loadExercises() async {
        guard allExercises.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            logger.info("EXERCISE_LIBRARY", "Loading exercise templates for library")

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let result = try await PTSupabaseClient.shared.client
                .from("exercise_templates")
                .select()
                .order("name")
                .execute()

            let templates = try decoder.decode([ExerciseTemplateData].self, from: result.data)
            let items = templates.map { LibraryExerciseItem(from: $0) }

            allExercises = items
            loadRecentlyViewed()
            loadPopularExercises()

            logger.success("EXERCISE_LIBRARY", "Loaded \(items.count) exercises")
        } catch {
            logger.error("EXERCISE_LIBRARY", "Failed to load exercises: \(error)")
            errorMessage = "Unable to load exercises. Please try again."
        }

        isLoading = false
    }

    /// Records that the user viewed an exercise
    func recordExerciseView(_ exercise: LibraryExerciseItem) {
        recentManager.recordView(exerciseId: exercise.id)
        loadRecentlyViewed()
    }

    /// Clears all active filters
    func clearFilters() {
        selectedExerciseMuscleGroup = nil
        selectedEquipment = []
        selectedDifficulty = nil
        searchText = ""
    }

    /// Toggles an equipment filter
    func toggleEquipment(_ equipment: EquipmentType) {
        if selectedEquipment.contains(equipment) {
            selectedEquipment.remove(equipment)
        } else {
            selectedEquipment.insert(equipment)
        }
    }

    // MARK: - Private Helpers

    private func loadRecentlyViewed() {
        let recentIds = recentManager.recentIds
        recentlyViewed = recentIds.compactMap { id in
            allExercises.first { $0.id == id }
        }
    }

    private func loadPopularExercises() {
        // Show curated popular exercises based on common names
        let popularNames = ["bench press", "squat", "deadlift", "overhead press",
                           "pull-up", "row", "lunge", "plank",
                           "curl", "push-up"]
        var popular: [LibraryExerciseItem] = []
        for keyword in popularNames {
            if let match = allExercises.first(where: { $0.name.lowercased().contains(keyword) }) {
                if !popular.contains(where: { $0.id == match.id }) {
                    popular.append(match)
                }
            }
        }
        // If we don't have enough from keywords, fill with first exercises
        if popular.count < 8 {
            for exercise in allExercises.prefix(20) {
                if popular.count >= 8 { break }
                if !popular.contains(where: { $0.id == exercise.id }) {
                    popular.append(exercise)
                }
            }
        }
        popularExercises = Array(popular.prefix(8))
    }
}
