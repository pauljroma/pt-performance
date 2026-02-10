import Foundation

// MARK: - Supplement Catalog (Database Supplements)

/// A supplement in the master catalog (reference data)
struct CatalogSupplement: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let brand: String?
    let category: SupplementCatalogCategory
    let benefits: [String]
    let evidenceRating: EvidenceRating
    let dosageRange: String
    let timing: [SupplementTiming]
    let contraindications: [String]
    let interactions: [String]
    let description: String?
    let imageUrl: String?
    let purchaseUrl: String?
    let averageCost: Double?
    let servingsPerContainer: Int?
    let isVerified: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, brand, category, benefits
        case evidenceRating = "evidence_rating"
        case dosageRange = "dosage_range"
        case timing, contraindications, interactions, description
        case imageUrl = "image_url"
        case purchaseUrl = "purchase_url"
        case averageCost = "average_cost"
        case servingsPerContainer = "servings_per_container"
        case isVerified = "is_verified"
        case createdAt = "created_at"
    }
}

// MARK: - Supplement Category (Catalog)

/// Categories for the supplement catalog
enum SupplementCatalogCategory: String, Codable, CaseIterable, Identifiable {
    case performance = "performance"
    case recovery = "recovery"
    case sleep = "sleep"
    case health = "health"
    case vitamin = "vitamin"
    case mineral = "mineral"
    case protein = "protein"
    case preworkout = "preworkout"
    case cognitive = "cognitive"
    case hormonal = "hormonal"
    case joint = "joint"
    case digestive = "digestive"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .performance: return "Performance"
        case .recovery: return "Recovery"
        case .sleep: return "Sleep"
        case .health: return "General Health"
        case .vitamin: return "Vitamins"
        case .mineral: return "Minerals"
        case .protein: return "Protein"
        case .preworkout: return "Pre-Workout"
        case .cognitive: return "Cognitive"
        case .hormonal: return "Hormonal Support"
        case .joint: return "Joint Health"
        case .digestive: return "Digestive"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .performance: return "bolt.fill"
        case .recovery: return "heart.fill"
        case .sleep: return "moon.fill"
        case .health: return "cross.case.fill"
        case .vitamin: return "pill.fill"
        case .mineral: return "leaf.fill"
        case .protein: return "figure.strengthtraining.traditional"
        case .preworkout: return "flame.fill"
        case .cognitive: return "brain.head.profile"
        case .hormonal: return "waveform.path.ecg"
        case .joint: return "figure.walk"
        case .digestive: return "stomach"
        case .other: return "pills.fill"
        }
    }

    var color: String {
        switch self {
        case .performance: return "orange"
        case .recovery: return "green"
        case .sleep: return "indigo"
        case .health: return "blue"
        case .vitamin: return "yellow"
        case .mineral: return "teal"
        case .protein: return "red"
        case .preworkout: return "pink"
        case .cognitive: return "purple"
        case .hormonal: return "mint"
        case .joint: return "brown"
        case .digestive: return "cyan"
        case .other: return "gray"
        }
    }
}

// MARK: - Evidence Rating

/// Evidence rating for supplement efficacy
enum EvidenceRating: String, Codable, CaseIterable, Comparable {
    case strong = "strong"
    case moderate = "moderate"
    case emerging = "emerging"
    case limited = "limited"

    var displayName: String {
        switch self {
        case .strong: return "Strong Evidence"
        case .moderate: return "Moderate Evidence"
        case .emerging: return "Emerging Research"
        case .limited: return "Limited Evidence"
        }
    }

    var shortName: String {
        switch self {
        case .strong: return "Strong"
        case .moderate: return "Moderate"
        case .emerging: return "Emerging"
        case .limited: return "Limited"
        }
    }

    var icon: String {
        switch self {
        case .strong: return "checkmark.seal.fill"
        case .moderate: return "checkmark.circle.fill"
        case .emerging: return "arrow.up.right.circle.fill"
        case .limited: return "questionmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .strong: return "green"
        case .moderate: return "blue"
        case .emerging: return "orange"
        case .limited: return "gray"
        }
    }

    var sortOrder: Int {
        switch self {
        case .strong: return 0
        case .moderate: return 1
        case .emerging: return 2
        case .limited: return 3
        }
    }

    static func < (lhs: EvidenceRating, rhs: EvidenceRating) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Supplement Timing

/// When to take a supplement during the day
enum SupplementTiming: String, Codable, CaseIterable, Identifiable, Hashable {
    case morning = "morning"
    case afternoon = "afternoon"
    case preWorkout = "pre_workout"
    case postWorkout = "post_workout"
    case evening = "evening"
    case beforeBed = "before_bed"
    case withMeal = "with_meal"
    case emptyStomach = "empty_stomach"  // Database: empty_stomach
    case anytime = "any_time"  // Database uses underscore: any_time

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .preWorkout: return "Pre-Workout"
        case .postWorkout: return "Post-Workout"
        case .evening: return "Evening"
        case .beforeBed: return "Before Bed"
        case .withMeal: return "With Meal"
        case .emptyStomach: return "Empty Stomach"
        case .anytime: return "Anytime"
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .preWorkout: return "figure.run"
        case .postWorkout: return "figure.cooldown"
        case .evening: return "sunset.fill"
        case .beforeBed: return "moon.fill"
        case .withMeal: return "fork.knife"
        case .emptyStomach: return "clock.fill"
        case .anytime: return "clock.badge.checkmark.fill"
        }
    }

    var sortOrder: Int {
        switch self {
        case .morning: return 0
        case .afternoon: return 1
        case .preWorkout: return 2
        case .postWorkout: return 3
        case .withMeal: return 4
        case .emptyStomach: return 5
        case .evening: return 6
        case .beforeBed: return 7
        case .anytime: return 8
        }
    }

    /// Approximate hour of the day for scheduling
    var approximateHour: Int {
        switch self {
        case .morning: return 7
        case .afternoon: return 14
        case .preWorkout: return 6
        case .postWorkout: return 8
        case .withMeal: return 12
        case .emptyStomach: return 15
        case .evening: return 18
        case .beforeBed: return 21
        case .anytime: return 12
        }
    }
}

// MARK: - Dosage Unit

/// Units for supplement dosage
enum DosageUnit: String, Codable, CaseIterable, Identifiable, Hashable {
    case mg = "mg"
    case g = "g"
    case mcg = "mcg"
    case iu = "IU"
    case ml = "ml"
    case capsule = "capsule"
    case capsules = "capsules"
    case tablet = "tablet"
    case tablets = "tablets"
    case scoop = "scoop"
    case scoops = "scoops"
    case serving = "serving"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mg: return "mg"
        case .g: return "g"
        case .mcg: return "mcg"
        case .iu: return "IU"
        case .ml: return "ml"
        case .capsule: return "capsule"
        case .capsules: return "capsules"
        case .tablet: return "tablet"
        case .tablets: return "tablets"
        case .scoop: return "scoop"
        case .scoops: return "scoops"
        case .serving: return "serving"
        }
    }

    var abbreviation: String { displayName }
}

// MARK: - Weekday

/// Days of the week for scheduling
enum Weekday: Int, Codable, CaseIterable, Identifiable, Hashable {
    case sunday = 0
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    var letter: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }
}

// MARK: - Dosage

/// Dosage amount with unit
struct Dosage: Codable, Hashable {
    var amount: Double
    var unit: DosageUnit

    var displayString: String {
        if amount == floor(amount) {
            return "\(Int(amount)) \(unit.displayName)"
        }
        return "\(amount) \(unit.displayName)"
    }
}

// MARK: - Supplement Stack

/// A curated stack of supplements for a specific goal
struct SupplementStack: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let goal: SupplementStackGoal
    let items: [SupplementStackItem]
    let totalDailyCost: Double?
    let evidenceSummary: String?
    let warnings: [String]
    let isRecommended: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, description, goal, items
        case totalDailyCost = "total_daily_cost"
        case evidenceSummary = "evidence_summary"
        case warnings
        case isRecommended = "is_recommended"
        case createdAt = "created_at"
    }

    var itemCount: Int {
        items.count
    }
}

/// Goal for a supplement stack
enum SupplementStackGoal: String, Codable, CaseIterable, Identifiable {
    case muscleBuilding = "muscle_building"
    case fatLoss = "fat_loss"
    case recovery = "recovery"
    case sleep = "sleep"
    case energy = "energy"
    case cognitive = "cognitive"
    case longevity = "longevity"
    case general = "general"
    case athlete = "athlete"
    case pitcher = "pitcher"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .muscleBuilding: return "Muscle Building"
        case .fatLoss: return "Fat Loss"
        case .recovery: return "Recovery"
        case .sleep: return "Sleep Quality"
        case .energy: return "Energy & Focus"
        case .cognitive: return "Cognitive Performance"
        case .longevity: return "Longevity"
        case .general: return "General Health"
        case .athlete: return "Athlete Foundation"
        case .pitcher: return "Pitcher Protocol"
        }
    }

    var icon: String {
        switch self {
        case .muscleBuilding: return "figure.strengthtraining.traditional"
        case .fatLoss: return "flame.fill"
        case .recovery: return "heart.fill"
        case .sleep: return "moon.fill"
        case .energy: return "bolt.fill"
        case .cognitive: return "brain.head.profile"
        case .longevity: return "hourglass"
        case .general: return "cross.case.fill"
        case .athlete: return "figure.run"
        case .pitcher: return "baseball.fill"
        }
    }
}

/// An item within a supplement stack
struct SupplementStackItem: Identifiable, Codable, Hashable {
    let id: UUID
    let supplementId: UUID
    let supplementName: String
    let dosage: String
    let timing: SupplementTiming
    let notes: String?
    let isOptional: Bool
    let priority: Int

    enum CodingKeys: String, CodingKey {
        case id
        case supplementId = "supplement_id"
        case supplementName = "supplement_name"
        case dosage, timing, notes
        case isOptional = "is_optional"
        case priority
    }
}

// MARK: - Supplement Routine

/// A user's personalized daily supplement routine
struct SupplementRoutine: Identifiable, Codable, Hashable {
    let id: UUID
    let patientId: UUID
    let supplementId: UUID
    let supplement: RoutineSupplement?
    let dosage: String
    let timing: SupplementTiming
    let frequency: SupplementFrequency
    let withFood: Bool
    let notes: String?
    let isActive: Bool
    let startDate: Date
    let endDate: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case supplementId = "supplement_id"
        case supplement, dosage, timing, frequency
        case withFood = "with_food"
        case notes
        case isActive = "is_active"
        case startDate = "start_date"
        case endDate = "end_date"
        case createdAt = "created_at"
    }
}

/// Supplement data for routine display and editing
struct RoutineSupplement: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var brand: String?
    var category: SupplementCatalogCategory
    var dosage: Dosage?
    var timing: SupplementTiming?
    var days: [Weekday]?
    var withFood: Bool
    var reminderEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        category: SupplementCatalogCategory,
        dosage: Dosage? = nil,
        timing: SupplementTiming? = nil,
        days: [Weekday]? = nil,
        withFood: Bool = false,
        reminderEnabled: Bool = false
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.dosage = dosage
        self.timing = timing
        self.days = days
        self.withFood = withFood
        self.reminderEnabled = reminderEnabled
    }

    var displayName: String {
        if let brand = brand {
            return "\(brand) \(name)"
        }
        return name
    }

    enum CodingKeys: String, CodingKey {
        case id, name, brand, category, dosage, timing, days
        case withFood = "with_food"
        case reminderEnabled = "reminder_enabled"
    }
}

// MARK: - Supplement Log (Extended)

/// Extended supplement log with additional tracking data
struct SupplementLogEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let patientId: UUID
    let supplementId: UUID
    let routineId: UUID?
    let supplementName: String
    let dosage: String
    let timing: SupplementTiming
    let takenAt: Date
    let skipped: Bool
    let skipReason: String?
    let perceivedEffect: PerceivedEffect?
    let sideEffects: [String]?
    let notes: String?
    let createdAt: Date
    var supplement: RoutineSupplement?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case supplementId = "supplement_id"
        case routineId = "routine_id"
        case supplementName = "supplement_name"
        case dosage, timing
        case takenAt = "taken_at"
        case skipped
        case skipReason = "skip_reason"
        case perceivedEffect = "perceived_effect"
        case sideEffects = "side_effects"
        case notes
        case createdAt = "created_at"
        case supplement
    }
}

/// Data for a single day in the supplement history calendar
struct SupplementDayData: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let logs: [SupplementLogEntry]
    let complianceRate: Double
    let totalPlanned: Int
    let totalTaken: Int

    init(id: UUID = UUID(), date: Date, logs: [SupplementLogEntry] = [], complianceRate: Double = 0, totalPlanned: Int = 0, totalTaken: Int = 0) {
        self.id = id
        self.date = date
        self.logs = logs
        self.complianceRate = complianceRate
        self.totalPlanned = totalPlanned
        self.totalTaken = totalTaken
    }
}

/// Perceived effect rating for a supplement
enum PerceivedEffect: String, Codable, CaseIterable {
    case veryPositive = "very_positive"
    case positive = "positive"
    case neutral = "neutral"
    case negative = "negative"
    case veryNegative = "very_negative"

    var displayName: String {
        switch self {
        case .veryPositive: return "Very Positive"
        case .positive: return "Positive"
        case .neutral: return "Neutral"
        case .negative: return "Negative"
        case .veryNegative: return "Very Negative"
        }
    }

    var icon: String {
        switch self {
        case .veryPositive: return "face.smiling.fill"
        case .positive: return "hand.thumbsup.fill"
        case .neutral: return "minus.circle.fill"
        case .negative: return "hand.thumbsdown.fill"
        case .veryNegative: return "exclamationmark.triangle.fill"
        }
    }

    var color: String {
        switch self {
        case .veryPositive: return "green"
        case .positive: return "blue"
        case .neutral: return "gray"
        case .negative: return "orange"
        case .veryNegative: return "red"
        }
    }
}

// MARK: - Supplement Compliance

/// Daily compliance tracking for supplements
struct SupplementCompliance: Identifiable, Codable {
    let id: UUID
    let patientId: UUID
    let date: Date
    let plannedCount: Int
    let takenCount: Int
    let skippedCount: Int
    let complianceRate: Double
    let streakDays: Int

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case date
        case plannedCount = "planned_count"
        case takenCount = "taken_count"
        case skippedCount = "skipped_count"
        case complianceRate = "compliance_rate"
        case streakDays = "streak_days"
    }

    var formattedRate: String {
        "\(Int(complianceRate * 100))%"
    }

    var isComplete: Bool {
        takenCount >= plannedCount
    }
}

/// Weekly compliance summary
struct WeeklySupplementCompliance: Identifiable {
    let id = UUID()
    let weekStartDate: Date
    let dailyCompliance: [SupplementCompliance]

    var averageComplianceRate: Double {
        guard !dailyCompliance.isEmpty else { return 0 }
        return dailyCompliance.map { $0.complianceRate }.reduce(0, +) / Double(dailyCompliance.count)
    }

    var totalTaken: Int {
        dailyCompliance.map { $0.takenCount }.reduce(0, +)
    }

    var totalPlanned: Int {
        dailyCompliance.map { $0.plannedCount }.reduce(0, +)
    }

    var completeDays: Int {
        dailyCompliance.filter { $0.isComplete }.count
    }
}

// MARK: - Today's Schedule

/// A scheduled supplement dose for today
struct TodaySupplementDose: Identifiable, Hashable {
    let id: UUID
    let routineId: UUID
    let supplementId: UUID
    let supplementName: String
    let brand: String?
    let category: SupplementCatalogCategory
    let dosage: String
    let timing: SupplementTiming
    let scheduledTime: Date
    let withFood: Bool
    var isTaken: Bool
    var takenAt: Date?
    var logId: UUID?

    var displayName: String {
        if let brand = brand {
            return "\(brand) \(supplementName)"
        }
        return supplementName
    }

    var isOverdue: Bool {
        !isTaken && Date() > scheduledTime.addingTimeInterval(3600) // 1 hour grace
    }

    var isPending: Bool {
        !isTaken && !isOverdue
    }
}

// MARK: - Analytics

/// Supplement analytics summary
struct SupplementAnalytics: Codable {
    let totalSupplements: Int
    let activeRoutines: Int
    let weeklyComplianceRate: Double
    let monthlyComplianceRate: Double
    let currentStreak: Int
    let longestStreak: Int
    let topCategories: [CategoryCount]
    let mostConsistent: [ConsistentSupplement]
    let leastConsistent: [ConsistentSupplement]

    enum CodingKeys: String, CodingKey {
        case totalSupplements = "total_supplements"
        case activeRoutines = "active_routines"
        case weeklyComplianceRate = "weekly_compliance_rate"
        case monthlyComplianceRate = "monthly_compliance_rate"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case topCategories = "top_categories"
        case mostConsistent = "most_consistent"
        case leastConsistent = "least_consistent"
    }
}

struct CategoryCount: Codable, Identifiable {
    var id: String { category.rawValue }
    let category: SupplementCatalogCategory
    let count: Int
}

struct ConsistentSupplement: Codable, Identifiable {
    let id: UUID
    let name: String
    let complianceRate: Double

    enum CodingKeys: String, CodingKey {
        case id, name
        case complianceRate = "compliance_rate"
    }

    var formattedRate: String {
        "\(Int(complianceRate * 100))%"
    }
}

// MARK: - Demo Data

extension CatalogSupplement {
    static let demoSupplements: [CatalogSupplement] = [
        CatalogSupplement(
            id: UUID(),
            name: "Creatine Monohydrate",
            brand: "Momentous",
            category: .performance,
            benefits: ["Increased strength", "Improved power output", "Enhanced recovery", "Cognitive support"],
            evidenceRating: .strong,
            dosageRange: "3-5g daily",
            timing: [.postWorkout, .morning],
            contraindications: ["Kidney disease"],
            interactions: [],
            description: "The most studied and effective performance supplement available.",
            imageUrl: nil,
            purchaseUrl: "https://www.livemomentous.com/creatine",
            averageCost: 0.50,
            servingsPerContainer: 60,
            isVerified: true,
            createdAt: Date()
        ),
        CatalogSupplement(
            id: UUID(),
            name: "Omega-3 Fish Oil",
            brand: "Momentous",
            category: .health,
            benefits: ["Reduced inflammation", "Heart health", "Brain function", "Joint support"],
            evidenceRating: .strong,
            dosageRange: "2-4g EPA+DHA daily",
            timing: [.withMeal],
            contraindications: ["Blood thinners"],
            interactions: ["Anticoagulants"],
            description: "Essential fatty acids for overall health and recovery.",
            imageUrl: nil,
            purchaseUrl: nil,
            averageCost: 0.80,
            servingsPerContainer: 90,
            isVerified: true,
            createdAt: Date()
        ),
        CatalogSupplement(
            id: UUID(),
            name: "Vitamin D3",
            brand: nil,
            category: .vitamin,
            benefits: ["Bone health", "Immune function", "Mood support", "Muscle function"],
            evidenceRating: .strong,
            dosageRange: "2000-5000 IU daily",
            timing: [.morning, .withMeal],
            contraindications: ["Hypercalcemia"],
            interactions: [],
            description: "Essential vitamin that most people are deficient in.",
            imageUrl: nil,
            purchaseUrl: nil,
            averageCost: 0.15,
            servingsPerContainer: 120,
            isVerified: true,
            createdAt: Date()
        ),
        CatalogSupplement(
            id: UUID(),
            name: "Magnesium Glycinate",
            brand: nil,
            category: .mineral,
            benefits: ["Sleep quality", "Muscle relaxation", "Stress reduction", "Recovery"],
            evidenceRating: .moderate,
            dosageRange: "200-400mg daily",
            timing: [.beforeBed, .evening],
            contraindications: ["Kidney disease"],
            interactions: ["Antibiotics"],
            description: "Highly bioavailable form of magnesium, great for sleep.",
            imageUrl: nil,
            purchaseUrl: nil,
            averageCost: 0.30,
            servingsPerContainer: 90,
            isVerified: true,
            createdAt: Date()
        ),
        CatalogSupplement(
            id: UUID(),
            name: "Ashwagandha",
            brand: nil,
            category: .cognitive,
            benefits: ["Stress reduction", "Cortisol management", "Sleep quality", "Recovery"],
            evidenceRating: .moderate,
            dosageRange: "300-600mg daily",
            timing: [.evening, .beforeBed],
            contraindications: ["Thyroid conditions", "Pregnancy"],
            interactions: ["Thyroid medications"],
            description: "Adaptogenic herb for stress management and recovery.",
            imageUrl: nil,
            purchaseUrl: nil,
            averageCost: 0.40,
            servingsPerContainer: 60,
            isVerified: true,
            createdAt: Date()
        ),
        CatalogSupplement(
            id: UUID(),
            name: "Whey Protein Isolate",
            brand: "Momentous",
            category: .protein,
            benefits: ["Muscle protein synthesis", "Recovery", "Convenient protein source"],
            evidenceRating: .strong,
            dosageRange: "20-40g per serving",
            timing: [.postWorkout, .emptyStomach],
            contraindications: ["Dairy allergy"],
            interactions: [],
            description: "Fast-digesting protein for post-workout recovery.",
            imageUrl: nil,
            purchaseUrl: nil,
            averageCost: 1.50,
            servingsPerContainer: 30,
            isVerified: true,
            createdAt: Date()
        )
    ]
}

extension SupplementStack {
    static let demoStacks: [SupplementStack] = [
        SupplementStack(
            id: UUID(),
            name: "Athlete Foundation",
            description: "Essential supplements for any serious athlete focusing on performance and recovery.",
            goal: .athlete,
            items: [
                SupplementStackItem(
                    id: UUID(),
                    supplementId: UUID(),
                    supplementName: "Creatine Monohydrate",
                    dosage: "5g",
                    timing: .postWorkout,
                    notes: "Take daily, timing doesn't matter much",
                    isOptional: false,
                    priority: 1
                ),
                SupplementStackItem(
                    id: UUID(),
                    supplementId: UUID(),
                    supplementName: "Omega-3 Fish Oil",
                    dosage: "3g EPA+DHA",
                    timing: .withMeal,
                    notes: "Take with largest meal for absorption",
                    isOptional: false,
                    priority: 2
                ),
                SupplementStackItem(
                    id: UUID(),
                    supplementId: UUID(),
                    supplementName: "Vitamin D3",
                    dosage: "5000 IU",
                    timing: .morning,
                    notes: "Take with breakfast",
                    isOptional: false,
                    priority: 3
                ),
                SupplementStackItem(
                    id: UUID(),
                    supplementId: UUID(),
                    supplementName: "Magnesium Glycinate",
                    dosage: "300mg",
                    timing: .beforeBed,
                    notes: "Supports sleep and recovery",
                    isOptional: true,
                    priority: 4
                )
            ],
            totalDailyCost: 2.75,
            evidenceSummary: "All supplements in this stack have strong to moderate evidence supporting their use in athletes.",
            warnings: [],
            isRecommended: true,
            createdAt: Date()
        ),
        SupplementStack(
            id: UUID(),
            name: "Sleep Optimization",
            description: "Supplements to improve sleep quality and recovery overnight.",
            goal: .sleep,
            items: [
                SupplementStackItem(
                    id: UUID(),
                    supplementId: UUID(),
                    supplementName: "Magnesium Glycinate",
                    dosage: "400mg",
                    timing: .beforeBed,
                    notes: "Take 30-60 min before bed",
                    isOptional: false,
                    priority: 1
                ),
                SupplementStackItem(
                    id: UUID(),
                    supplementId: UUID(),
                    supplementName: "Ashwagandha",
                    dosage: "300mg",
                    timing: .beforeBed,
                    notes: "Helps reduce cortisol",
                    isOptional: false,
                    priority: 2
                )
            ],
            totalDailyCost: 0.70,
            evidenceSummary: "Both supplements show moderate evidence for improving sleep quality metrics.",
            warnings: ["Check with doctor if you have thyroid conditions"],
            isRecommended: true,
            createdAt: Date()
        )
    ]
}

extension SupplementRoutine {
    static let demoRoutines: [SupplementRoutine] = [
        SupplementRoutine(
            id: UUID(),
            patientId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            supplementId: UUID(),
            supplement: RoutineSupplement(
                id: UUID(),
                name: "Creatine Monohydrate",
                brand: "Momentous",
                category: .performance
            ),
            dosage: "5g",
            timing: .postWorkout,
            frequency: .daily,
            withFood: false,
            notes: nil,
            isActive: true,
            startDate: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
            endDate: nil,
            createdAt: Date()
        ),
        SupplementRoutine(
            id: UUID(),
            patientId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            supplementId: UUID(),
            supplement: RoutineSupplement(
                id: UUID(),
                name: "Vitamin D3",
                brand: nil,
                category: .vitamin
            ),
            dosage: "5000 IU",
            timing: .morning,
            frequency: .daily,
            withFood: true,
            notes: "Take with breakfast",
            isActive: true,
            startDate: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
            endDate: nil,
            createdAt: Date()
        ),
        SupplementRoutine(
            id: UUID(),
            patientId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            supplementId: UUID(),
            supplement: RoutineSupplement(
                id: UUID(),
                name: "Magnesium Glycinate",
                brand: nil,
                category: .mineral
            ),
            dosage: "300mg",
            timing: .beforeBed,
            frequency: .daily,
            withFood: false,
            notes: "30 min before sleep",
            isActive: true,
            startDate: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
            endDate: nil,
            createdAt: Date()
        ),
        SupplementRoutine(
            id: UUID(),
            patientId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            supplementId: UUID(),
            supplement: RoutineSupplement(
                id: UUID(),
                name: "Omega-3 Fish Oil",
                brand: "Momentous",
                category: .health
            ),
            dosage: "3g",
            timing: .withMeal,
            frequency: .daily,
            withFood: true,
            notes: nil,
            isActive: true,
            startDate: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
            endDate: nil,
            createdAt: Date()
        ),
        SupplementRoutine(
            id: UUID(),
            patientId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            supplementId: UUID(),
            supplement: RoutineSupplement(
                id: UUID(),
                name: "Whey Protein",
                brand: "Momentous",
                category: .protein
            ),
            dosage: "25g",
            timing: .postWorkout,
            frequency: .trainingDaysOnly,
            withFood: false,
            notes: "Within 30 min of training",
            isActive: true,
            startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            endDate: nil,
            createdAt: Date()
        )
    ]
}
