import SwiftUI

// MARK: - Evidence Grade Enum

/// Scientific evidence grade for supplement efficacy (A-D scale)
enum EvidenceGrade: String, Codable, CaseIterable, Comparable, Identifiable {
    case A = "A"
    case B = "B"
    case C = "C"
    case D = "D"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .A: return "Strong"
        case .B: return "Moderate"
        case .C: return "Preliminary"
        case .D: return "Weak"
        }
    }

    var fullDescription: String {
        switch self {
        case .A: return "Strong Evidence - Multiple high-quality studies support efficacy"
        case .B: return "Moderate Evidence - Some quality studies show benefits"
        case .C: return "Preliminary Evidence - Early research shows promise"
        case .D: return "Weak Evidence - Limited or conflicting research"
        }
    }

    var starCount: Int {
        switch self {
        case .A: return 5
        case .B: return 4
        case .C: return 3
        case .D: return 2
        }
    }

    var color: Color {
        switch self {
        case .A: return .modusTealAccent
        case .B: return .modusCyan
        case .C: return .orange
        case .D: return .gray
        }
    }

    var icon: String {
        switch self {
        case .A: return "checkmark.seal.fill"
        case .B: return "checkmark.circle.fill"
        case .C: return "arrow.up.right.circle.fill"
        case .D: return "questionmark.circle.fill"
        }
    }

    static func < (lhs: EvidenceGrade, rhs: EvidenceGrade) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    private var sortOrder: Int {
        switch self {
        case .A: return 0
        case .B: return 1
        case .C: return 2
        case .D: return 3
        }
    }

    /// Maps from EvidenceRating to EvidenceGrade
    static func from(_ rating: EvidenceRating) -> EvidenceGrade {
        switch rating {
        case .strong: return .A
        case .moderate: return .B
        case .emerging: return .C
        case .limited: return .D
        }
    }
}

// MARK: - Timing Group Enum

/// Groups supplements by time of day for organized display
enum SupplementTimingGroup: String, CaseIterable, Identifiable {
    case morning = "morning"
    case preWorkout = "pre_workout"
    case postWorkout = "post_workout"
    case withMeals = "with_meals"
    case evening = "evening"
    case beforeBed = "before_bed"
    case anytime = "anytime"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .morning: return "MORNING"
        case .preWorkout: return "PRE-WORKOUT"
        case .postWorkout: return "POST-WORKOUT"
        case .withMeals: return "WITH MEALS"
        case .evening: return "EVENING"
        case .beforeBed: return "BEFORE BED"
        case .anytime: return "ANYTIME"
        }
    }

    var subtitle: String {
        switch self {
        case .morning: return "with breakfast"
        case .preWorkout: return "30min before"
        case .postWorkout: return "within 1 hour"
        case .withMeals: return "with any meal"
        case .evening: return "with dinner"
        case .beforeBed: return "30-60min before sleep"
        case .anytime: return "when convenient"
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .preWorkout: return "figure.run"
        case .postWorkout: return "figure.cooldown"
        case .withMeals: return "fork.knife"
        case .evening: return "sunset.fill"
        case .beforeBed: return "moon.fill"
        case .anytime: return "clock.badge.checkmark.fill"
        }
    }

    var sortOrder: Int {
        switch self {
        case .morning: return 0
        case .preWorkout: return 1
        case .postWorkout: return 2
        case .withMeals: return 3
        case .evening: return 4
        case .beforeBed: return 5
        case .anytime: return 6
        }
    }

    /// Maps SupplementTiming to SupplementTimingGroup
    static func from(_ timing: SupplementTiming) -> SupplementTimingGroup {
        switch timing {
        case .morning: return .morning
        case .afternoon: return .withMeals
        case .preWorkout: return .preWorkout
        case .postWorkout: return .postWorkout
        case .withMeal, .emptyStomach: return .withMeals
        case .evening: return .evening
        case .beforeBed: return .beforeBed
        case .anytime: return .anytime
        }
    }
}

// MARK: - Goal-Based Recommendation

/// A supplement recommendation based on user goals
struct GoalBasedRecommendation: Identifiable, Hashable {
    let id: UUID
    let supplementName: String
    let category: SupplementCatalogCategory
    let evidenceGrade: EvidenceGrade
    let benefit: String
    let dosage: String
    let timing: SupplementTiming
    let isInStack: Bool
    let catalogSupplementId: UUID?

    init(
        id: UUID = UUID(),
        supplementName: String,
        category: SupplementCatalogCategory,
        evidenceGrade: EvidenceGrade,
        benefit: String,
        dosage: String,
        timing: SupplementTiming,
        isInStack: Bool = false,
        catalogSupplementId: UUID? = nil
    ) {
        self.id = id
        self.supplementName = supplementName
        self.category = category
        self.evidenceGrade = evidenceGrade
        self.benefit = benefit
        self.dosage = dosage
        self.timing = timing
        self.isInStack = isInStack
        self.catalogSupplementId = catalogSupplementId
    }
}

// MARK: - User Goal

/// Represents a user's fitness/health goal for recommendations
enum UserGoal: String, CaseIterable, Identifiable {
    case buildStrength = "build_strength"
    case buildMuscle = "build_muscle"
    case improveRecovery = "improve_recovery"
    case betterSleep = "better_sleep"
    case moreEnergy = "more_energy"
    case fatLoss = "fat_loss"
    case generalHealth = "general_health"
    case cognition = "cognition"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .buildStrength: return "Build Strength"
        case .buildMuscle: return "Build Muscle"
        case .improveRecovery: return "Improve Recovery"
        case .betterSleep: return "Better Sleep"
        case .moreEnergy: return "More Energy"
        case .fatLoss: return "Fat Loss"
        case .generalHealth: return "General Health"
        case .cognition: return "Cognitive Performance"
        }
    }

    var icon: String {
        switch self {
        case .buildStrength: return "figure.strengthtraining.traditional"
        case .buildMuscle: return "figure.arms.open"
        case .improveRecovery: return "heart.fill"
        case .betterSleep: return "moon.fill"
        case .moreEnergy: return "bolt.fill"
        case .fatLoss: return "flame.fill"
        case .generalHealth: return "cross.case.fill"
        case .cognition: return "brain.head.profile"
        }
    }
}

// MARK: - ViewModel for Supplement Dashboard View

@MainActor
final class SupplementDashboardViewModel: ObservableObject {
    @Published var todayChecklist: [SupplementChecklistItem] = []
    @Published var myStack: [RoutineSupplement] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedSupplementForLog: RoutineSupplement?

    /// Grouped checklist items by timing
    @Published var groupedChecklist: [SupplementTimingGroup: [SupplementChecklistItem]] = [:]

    /// Goal-based recommendations
    @Published var recommendations: [GoalBasedRecommendation] = []
    @Published var essentialRecommendations: [GoalBasedRecommendation] = []
    @Published var helpfulRecommendations: [GoalBasedRecommendation] = []

    /// User's primary goal
    @Published var userGoal: UserGoal = .buildStrength

    /// Swipe-to-log state
    @Published var isLoggingItem: UUID?

    private let service = SupplementService.shared

    // MARK: - Computed Properties

    var completedCount: Int {
        todayChecklist.filter { $0.isTaken }.count
    }

    var totalCount: Int {
        todayChecklist.count
    }

    var complianceProgress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var currentStreak: Int {
        service.todayCompliance?.streakDays ?? 0
    }

    var bestStreak: Int {
        service.analytics?.longestStreak ?? currentStreak
    }

    /// Returns sorted timing groups that have items
    var sortedTimingGroups: [SupplementTimingGroup] {
        groupedChecklist.keys
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Returns items for a specific timing group
    func items(for group: SupplementTimingGroup) -> [SupplementChecklistItem] {
        groupedChecklist[group] ?? []
    }

    /// Returns completion status for a timing group
    func isGroupComplete(_ group: SupplementTimingGroup) -> Bool {
        let items = groupedChecklist[group] ?? []
        return !items.isEmpty && items.allSatisfy { $0.isTaken }
    }

    /// Returns the count of completed items in a group
    func completedCount(for group: SupplementTimingGroup) -> Int {
        (groupedChecklist[group] ?? []).filter { $0.isTaken }.count
    }

    /// Returns total count for a group
    func totalCount(for group: SupplementTimingGroup) -> Int {
        (groupedChecklist[group] ?? []).count
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        error = nil

        await service.fetchRoutines()
        await service.calculateTodayCompliance()

        // Build checklist from today's doses
        todayChecklist = service.todayDoses.map { dose in
            SupplementChecklistItem(
                id: dose.id,
                supplement: RoutineSupplement(
                    id: dose.supplementId,
                    name: dose.supplementName,
                    brand: dose.brand,
                    category: dose.category,
                    dosage: Dosage(amount: Double(dose.dosage.filter { $0.isNumber || $0 == "." }) ?? 0, unit: .mg),
                    timing: dose.timing,
                    days: nil,
                    withFood: dose.withFood,
                    reminderEnabled: false
                ),
                timing: dose.timing,
                dosage: dose.dosage,
                isTaken: dose.isTaken,
                takenAt: dose.takenAt,
                logId: dose.logId
            )
        }

        // Group checklist by timing
        buildGroupedChecklist()

        // Build my stack from routines
        myStack = service.routines.filter { $0.isActive }.compactMap { routine in
            guard let supplement = routine.supplement else { return nil }
            return RoutineSupplement(
                id: routine.id,
                name: supplement.name,
                brand: supplement.brand,
                category: supplement.category,
                dosage: Dosage(amount: Double(routine.dosage.filter { $0.isNumber || $0 == "." }) ?? 0, unit: .mg),
                timing: routine.timing,
                days: nil,
                withFood: routine.withFood,
                reminderEnabled: false
            )
        }

        // Generate goal-based recommendations
        await generateRecommendations()

        if let serviceError = service.error {
            error = serviceError.localizedDescription
        }

        isLoading = false
    }

    /// Groups checklist items by timing
    private func buildGroupedChecklist() {
        var grouped: [SupplementTimingGroup: [SupplementChecklistItem]] = [:]

        for item in todayChecklist {
            let group = SupplementTimingGroup.from(item.timing)
            if grouped[group] == nil {
                grouped[group] = []
            }
            grouped[group]?.append(item)
        }

        // Sort items within each group by supplement name
        for (group, items) in grouped {
            grouped[group] = items.sorted { $0.supplement.name < $1.supplement.name }
        }

        groupedChecklist = grouped
    }

    /// Generates goal-based recommendations
    private func generateRecommendations() async {
        // Fetch catalog for recommendations
        await service.fetchCatalog()

        let catalog = service.catalog
        let currentSupplementIds = Set(myStack.map { $0.id })

        // Build recommendations based on user goal
        var allRecommendations: [GoalBasedRecommendation] = []

        for catalogItem in catalog {
            let evidenceGrade = EvidenceGrade.from(catalogItem.evidenceRating)
            let isInStack = currentSupplementIds.contains(catalogItem.id)

            // Get benefit string based on user goal
            let benefit = getBenefit(for: catalogItem, goal: userGoal)

            guard !benefit.isEmpty else { continue }

            let recommendation = GoalBasedRecommendation(
                supplementName: catalogItem.name,
                category: catalogItem.category,
                evidenceGrade: evidenceGrade,
                benefit: benefit,
                dosage: catalogItem.dosageRange,
                timing: catalogItem.timing.first ?? .anytime,
                isInStack: isInStack,
                catalogSupplementId: catalogItem.id
            )

            allRecommendations.append(recommendation)
        }

        // Sort by evidence grade
        allRecommendations.sort { $0.evidenceGrade < $1.evidenceGrade }

        // Split into essential (A/B) and helpful (C/D)
        essentialRecommendations = allRecommendations.filter { $0.evidenceGrade == .A || $0.evidenceGrade == .B }
        helpfulRecommendations = allRecommendations.filter { $0.evidenceGrade == .C || $0.evidenceGrade == .D }

        recommendations = allRecommendations
    }

    /// Returns benefit text for a supplement based on user goal
    private func getBenefit(for supplement: CatalogSupplement, goal: UserGoal) -> String {
        switch goal {
        case .buildStrength:
            if supplement.name.lowercased().contains("creatine") {
                return "+12-20% strength gains"
            } else if supplement.name.lowercased().contains("caffeine") {
                return "+3-5% performance"
            } else if supplement.name.lowercased().contains("beta-alanine") {
                return "Endurance boost for high-rep sets"
            } else if supplement.category == .protein {
                return "Hit 1.6g/kg daily for muscle"
            }

        case .buildMuscle:
            if supplement.name.lowercased().contains("creatine") {
                return "+5-10% lean mass gains"
            } else if supplement.category == .protein {
                return "Essential for muscle protein synthesis"
            } else if supplement.name.lowercased().contains("hmb") {
                return "Reduces muscle breakdown"
            }

        case .improveRecovery:
            if supplement.name.lowercased().contains("omega") {
                return "Reduces inflammation"
            } else if supplement.name.lowercased().contains("magnesium") {
                return "Muscle relaxation & repair"
            } else if supplement.category == .protein {
                return "Speeds muscle repair"
            }

        case .betterSleep:
            if supplement.name.lowercased().contains("magnesium") {
                return "Improves sleep quality"
            } else if supplement.name.lowercased().contains("ashwagandha") {
                return "Reduces cortisol for better rest"
            } else if supplement.name.lowercased().contains("glycine") {
                return "Enhances deep sleep"
            }

        case .moreEnergy:
            if supplement.name.lowercased().contains("caffeine") {
                return "Sustained energy boost"
            } else if supplement.name.lowercased().contains("b12") || supplement.name.lowercased().contains("b-complex") {
                return "Supports energy metabolism"
            } else if supplement.name.lowercased().contains("iron") {
                return "Prevents fatigue from deficiency"
            }

        case .fatLoss:
            if supplement.name.lowercased().contains("caffeine") {
                return "Boosts metabolism 3-11%"
            } else if supplement.category == .protein {
                return "Preserves muscle during deficit"
            } else if supplement.name.lowercased().contains("green tea") {
                return "Supports fat oxidation"
            }

        case .generalHealth:
            if supplement.name.lowercased().contains("vitamin d") {
                return "Essential for immune function"
            } else if supplement.name.lowercased().contains("omega") {
                return "Heart & brain health"
            } else if supplement.name.lowercased().contains("magnesium") {
                return "300+ enzymatic reactions"
            }

        case .cognition:
            if supplement.name.lowercased().contains("omega") {
                return "Supports brain function"
            } else if supplement.name.lowercased().contains("creatine") {
                return "+5-15% cognitive performance"
            } else if supplement.name.lowercased().contains("caffeine") {
                return "Enhanced focus & alertness"
            }
        }

        // Generic benefits from supplement data
        if let firstBenefit = supplement.benefits.first {
            return firstBenefit
        }

        return ""
    }

    // MARK: - Actions

    func toggleItem(_ item: SupplementChecklistItem) {
        guard let index = todayChecklist.firstIndex(where: { $0.id == item.id }) else { return }

        isLoggingItem = item.id

        Task { [weak self] in
            guard let self else { return }
            if let dose = service.todayDoses.first(where: { $0.id == item.id }) {
                if item.isTaken {
                    if let logId = item.logId {
                        do {
                            try await service.undoLog(logId)
                        } catch {
                            self.error = error.localizedDescription
                        }
                    }
                } else {
                    do {
                        try await service.logSupplement(dose: dose)
                    } catch {
                        self.error = error.localizedDescription
                    }
                }
                await loadData()
            }
            isLoggingItem = nil
        }
    }

    /// Logs a single supplement via swipe gesture
    func logSupplementViaSwipe(_ item: SupplementChecklistItem) {
        guard !item.isTaken else { return }

        isLoggingItem = item.id
        HapticFeedback.success()

        Task { [weak self] in
            guard let self else { return }
            if let dose = service.todayDoses.first(where: { $0.id == item.id }) {
                do {
                    try await service.logSupplement(dose: dose)
                } catch {
                    self.error = error.localizedDescription
                    HapticFeedback.error()
                }
                await loadData()
            }
            isLoggingItem = nil
        }
    }

    func markAllAsTaken() {
        Task { [weak self] in
            guard let self else { return }
            for dose in service.todayDoses where !dose.isTaken {
                do {
                    try await service.logSupplement(dose: dose)
                } catch {
                    self.error = error.localizedDescription
                }
            }
            await loadData()
        }
    }

    /// Logs all supplements in a specific timing group
    func logAllInGroup(_ group: SupplementTimingGroup) {
        let items = groupedChecklist[group] ?? []
        let unloggedItems = items.filter { !$0.isTaken }

        guard !unloggedItems.isEmpty else { return }

        HapticFeedback.success()

        Task { [weak self] in
            guard let self else { return }
            for item in unloggedItems {
                if let dose = service.todayDoses.first(where: { $0.id == item.id }) {
                    do {
                        try await service.logSupplement(dose: dose)
                    } catch {
                        self.error = error.localizedDescription
                    }
                }
            }
            await loadData()
        }
    }

    /// Updates the user's primary goal and regenerates recommendations
    func updateGoal(_ goal: UserGoal) {
        userGoal = goal
        Task {
            await generateRecommendations()
        }
    }

    /// Adds a recommended supplement to the user's stack
    func addRecommendationToStack(_ recommendation: GoalBasedRecommendation) async {
        guard let catalogId = recommendation.catalogSupplementId else { return }

        do {
            try await service.addToRoutine(
                supplementId: catalogId,
                supplementName: recommendation.supplementName,
                brand: nil,
                category: recommendation.category,
                dosage: recommendation.dosage,
                timing: recommendation.timing
            )
            await loadData()
            HapticFeedback.success()
        } catch {
            self.error = error.localizedDescription
            HapticFeedback.error()
        }
    }

    func saveLog(_ log: SupplementLogEntry) async {
        // Log already saved through toggleItem
        await loadData()
    }
}

// MARK: - Checklist Item

/// Checklist item for supplement dashboard
struct SupplementChecklistItem: Identifiable, Hashable {
    let id: UUID
    let supplement: RoutineSupplement
    let timing: SupplementTiming
    let dosage: String
    var isTaken: Bool
    var takenAt: Date?
    var logId: UUID?

    static func == (lhs: SupplementChecklistItem, rhs: SupplementChecklistItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
