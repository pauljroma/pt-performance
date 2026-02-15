//
//  PremiumAddOn.swift
//  PTPerformance
//
//  ACP-1009: Premium Add-Ons — Individual feature purchases beyond subscription
//  Defines add-on products that users can purchase as non-consumable IAPs.
//

import Foundation

// MARK: - Add-On Category

/// Categories for premium add-on products
enum AddOnCategory: String, Codable, CaseIterable, Identifiable {
    case program = "program"
    case coaching = "coaching"
    case analytics = "analytics"
    case content = "content"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .program: return "Programs"
        case .coaching: return "Coaching"
        case .analytics: return "Analytics"
        case .content: return "Content"
        }
    }

    var icon: String {
        switch self {
        case .program: return "figure.run"
        case .coaching: return "person.2.fill"
        case .analytics: return "chart.bar.fill"
        case .content: return "book.fill"
        }
    }

    var sortOrder: Int {
        switch self {
        case .program: return 0
        case .coaching: return 1
        case .analytics: return 2
        case .content: return 3
        }
    }
}

// MARK: - Premium Add-On

/// Represents an individual premium feature that can be purchased beyond the base subscription.
///
/// Add-ons are non-consumable StoreKit 2 products. Once purchased, the user retains access
/// permanently. Examples include custom program builders, advanced analytics, and coaching sessions.
///
/// ## Usage
/// ```swift
/// let addOn = PremiumAddOn(
///     id: UUID().uuidString,
///     name: "Custom Program Builder",
///     description: "Design your own periodized training programs",
///     price: 9.99,
///     productId: "com.getmodus.app.addon.programbuilder",
///     iconName: "hammer.fill",
///     category: .program
/// )
/// ```
struct PremiumAddOn: Identifiable, Codable, Equatable, Hashable {
    /// Unique identifier for the add-on
    let id: String

    /// Display name shown in the store
    let name: String

    /// Short description for the card view
    let description: String

    /// Full description shown in the detail sheet
    let fullDescription: String

    /// Price in USD (display only; actual price comes from StoreKit)
    let price: Double

    /// App Store Connect product identifier for StoreKit 2
    let productId: String

    /// SF Symbol name for the add-on icon
    let iconName: String

    /// Category for filtering
    let category: AddOnCategory

    /// Whether this add-on is currently available for purchase
    let isAvailable: Bool

    /// Optional badge text (e.g. "New", "Popular")
    let badgeText: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case fullDescription = "full_description"
        case price
        case productId = "product_id"
        case iconName = "icon_name"
        case category
        case isAvailable = "is_available"
        case badgeText = "badge_text"
    }

    /// Formatted price string for display
    var formattedPrice: String {
        String(format: "$%.2f", price)
    }

    // MARK: - Demo Add-Ons

    /// Pre-configured add-on catalog for development and fallback
    static let demoCatalog: [PremiumAddOn] = [
        PremiumAddOn(
            id: "addon-001",
            name: "Custom Program Builder",
            description: "Design your own periodized training programs with AI assistance",
            fullDescription: "Take full control of your training with our Custom Program Builder. Create periodized programs from scratch or modify existing templates. Features include block periodization, auto-regulation rules, exercise substitution suggestions, and AI-powered volume recommendations based on your recovery data.",
            price: 9.99,
            productId: "com.getmodus.app.addon.programbuilder",
            iconName: "hammer.fill",
            category: .program,
            isAvailable: true,
            badgeText: "Popular"
        ),
        PremiumAddOn(
            id: "addon-002",
            name: "Advanced Body Composition",
            description: "Detailed body comp tracking with trend analysis and predictions",
            fullDescription: "Go beyond basic weight tracking with Advanced Body Composition analytics. Track skinfold measurements, DEXA-equivalent estimates, and segmental analysis. Includes predictive modeling for body recomposition timelines, photo progress overlays, and exportable reports for your coach or healthcare provider.",
            price: 4.99,
            productId: "com.getmodus.app.addon.bodycomp",
            iconName: "figure.arms.open",
            category: .analytics,
            isAvailable: true,
            badgeText: nil
        ),
        PremiumAddOn(
            id: "addon-003",
            name: "1-on-1 Video Consult",
            description: "Schedule a live video session with a certified PT or coach",
            fullDescription: "Connect directly with a certified physical therapist or performance coach via live video. Sessions are 30 minutes and can cover program review, movement assessment, injury prevention strategies, or nutrition planning. Your session data is automatically shared with the coach for personalized guidance.",
            price: 49.99,
            productId: "com.getmodus.app.addon.videoconsult",
            iconName: "video.fill",
            category: .coaching,
            isAvailable: true,
            badgeText: "New"
        ),
        PremiumAddOn(
            id: "addon-004",
            name: "Nutrition Planning Pro",
            description: "Macro-optimized meal plans synced to your training schedule",
            fullDescription: "Unlock fully periodized nutrition plans that sync with your training calendar. Features include auto-adjusted macros based on training volume, meal prep shopping lists, restaurant menu suggestions, and integration with popular food tracking apps. Plans adapt weekly based on your progress and recovery metrics.",
            price: 7.99,
            productId: "com.getmodus.app.addon.nutritionpro",
            iconName: "fork.knife",
            category: .content,
            isAvailable: true,
            badgeText: nil
        ),
        PremiumAddOn(
            id: "addon-005",
            name: "HRV Deep Dive",
            description: "Advanced HRV analytics with readiness predictions",
            fullDescription: "Unlock granular heart rate variability analysis including time-domain metrics (RMSSD, SDNN), frequency-domain analysis, and Poincare plots. Includes 7-day readiness forecasting, training load optimization recommendations, and correlations between HRV trends and your performance data.",
            price: 5.99,
            productId: "com.getmodus.app.addon.hrvdeep",
            iconName: "heart.text.square.fill",
            category: .analytics,
            isAvailable: true,
            badgeText: nil
        ),
        PremiumAddOn(
            id: "addon-006",
            name: "Mobility Masterclass",
            description: "Guided mobility routines with video instruction",
            fullDescription: "Access a complete library of guided mobility routines with HD video instruction from certified movement specialists. Includes sport-specific warm-ups, post-training cooldowns, desk-worker recovery flows, and sleep-enhancing stretching sequences. New routines added monthly.",
            price: 6.99,
            productId: "com.getmodus.app.addon.mobility",
            iconName: "figure.flexibility",
            category: .content,
            isAvailable: true,
            badgeText: nil
        )
    ]
}

// MARK: - Limited Time Offer

/// A time-bound promotional offer for subscriptions or add-ons.
///
/// Fetched from Supabase and displayed as a banner. The offer automatically
/// expires based on `endDate` and includes countdown timer display support.
struct LimitedTimeOffer: Identifiable, Codable, Equatable {
    /// Unique identifier
    let id: String

    /// Offer headline (e.g. "Spring Training Sale")
    let title: String

    /// Offer body text
    let description: String

    /// Discount as integer percentage (e.g. 30 for 30% off)
    let discountPercent: Int

    /// The product ID this offer applies to
    let productId: String

    /// When the offer becomes active
    let startDate: Date

    /// When the offer expires
    let endDate: Date

    /// Hex color for the banner gradient (e.g. "#0891B2")
    let bannerColor: String

    /// Optional subtitle for additional context
    let subtitle: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case discountPercent = "discount_percent"
        case productId = "product_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case bannerColor = "banner_color"
        case subtitle
    }

    /// Whether the offer is currently active
    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }

    /// Time remaining until expiry
    var timeRemaining: TimeInterval {
        max(0, endDate.timeIntervalSince(Date()))
    }

    /// Formatted discount string
    var formattedDiscount: String {
        "\(discountPercent)% OFF"
    }

    /// Whether the offer has expired
    var hasExpired: Bool {
        Date() > endDate
    }

    // MARK: - Demo Offers

    static let demoOffer = LimitedTimeOffer(
        id: "lto-001",
        title: "Spring Training Sale",
        description: "Upgrade to Pro and unlock all premium features at a special rate",
        discountPercent: 30,
        productId: Config.Subscription.annualProductID,
        startDate: Date().addingTimeInterval(-86400),
        endDate: Date().addingTimeInterval(86400 * 3),
        bannerColor: "#0891B2",
        subtitle: "Limited time offer"
    )
}

// MARK: - Content Article

/// An educational article for the content marketing hub.
///
/// Articles are fetched from Supabase and displayed in the Content Hub.
/// Some articles are gated behind premium to encourage subscription conversion.
struct ContentArticle: Identifiable, Codable, Equatable, Hashable {
    /// Unique identifier
    let id: String

    /// Article title
    let title: String

    /// Short summary for list view
    let summary: String

    /// Content category for filtering
    let category: ContentCategory

    /// URL for the article thumbnail image
    let imageURL: String?

    /// Full article content (markdown or rich text)
    let content: String

    /// Estimated read time in minutes
    let readTimeMinutes: Int

    /// Whether this article requires a premium subscription
    let isPremium: Bool

    /// Author name
    let author: String?

    /// Publication date
    let publishedAt: Date

    /// Whether this article is featured
    let isFeatured: Bool

    /// Tags for search and filtering
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case summary
        case category
        case imageURL = "image_url"
        case content
        case readTimeMinutes = "read_time_minutes"
        case isPremium = "is_premium"
        case author
        case publishedAt = "published_at"
        case isFeatured = "is_featured"
        case tags
    }

    /// Formatted read time string
    var formattedReadTime: String {
        "\(readTimeMinutes) min read"
    }

    // MARK: - Demo Articles

    static let demoArticles: [ContentArticle] = [
        ContentArticle(
            id: "article-001",
            title: "5 Recovery Strategies That Actually Work",
            summary: "Evidence-based recovery methods to maximize your training adaptation and reduce injury risk.",
            category: .recovery,
            imageURL: nil,
            content: "Recovery is where adaptation happens. Here are five strategies backed by research...\n\n## 1. Sleep Optimization\nAim for 7-9 hours of quality sleep. Sleep is the single most important recovery factor.\n\n## 2. Active Recovery\nLight movement on rest days increases blood flow without adding training stress.\n\n## 3. Nutrition Timing\nConsuming protein within 2 hours post-training supports muscle protein synthesis.\n\n## 4. Cold Water Immersion\n10-15 minutes at 10-15C can reduce inflammation after intense sessions.\n\n## 5. Stress Management\nChronic stress impairs recovery. Incorporate breathing exercises or meditation.",
            readTimeMinutes: 5,
            isPremium: false,
            author: "Dr. Sarah Chen",
            publishedAt: Date().addingTimeInterval(-86400 * 2),
            isFeatured: true,
            tags: ["recovery", "sleep", "nutrition"]
        ),
        ContentArticle(
            id: "article-002",
            title: "Progressive Overload: The Only Training Principle You Need",
            summary: "How to systematically increase training demands for continuous strength gains.",
            category: .trainingTips,
            imageURL: nil,
            content: "Progressive overload is the foundation of all strength training...\n\n## What Is Progressive Overload?\nIt means gradually increasing the demands placed on your body.\n\n## Methods of Progression\n- Add weight (most obvious)\n- Add reps\n- Add sets\n- Improve technique\n- Decrease rest periods\n\n## How Fast Should You Progress?\nAim for 2-5% load increases for upper body and 5-10% for lower body per week.",
            readTimeMinutes: 7,
            isPremium: false,
            author: "Coach Mike Torres",
            publishedAt: Date().addingTimeInterval(-86400 * 5),
            isFeatured: false,
            tags: ["training", "strength", "programming"]
        ),
        ContentArticle(
            id: "article-003",
            title: "Periodization for the Working Athlete",
            summary: "How to structure your training year when you have a full-time job and limited time.",
            category: .trainingTips,
            imageURL: nil,
            content: "You do not need to train like a full-time athlete to make great progress...\n\n## Block Periodization\nFocus on one quality per 3-4 week block.\n\n## Undulating Periodization\nVary intensity daily to manage fatigue.\n\n## Auto-Regulation\nUse RPE to adjust training based on daily readiness.",
            readTimeMinutes: 8,
            isPremium: true,
            author: "Dr. Sarah Chen",
            publishedAt: Date().addingTimeInterval(-86400 * 3),
            isFeatured: false,
            tags: ["periodization", "programming", "time-management"]
        ),
        ContentArticle(
            id: "article-004",
            title: "Nutrition for Muscle Growth: A Complete Guide",
            summary: "Everything you need to know about eating for hypertrophy, from macros to meal timing.",
            category: .nutrition,
            imageURL: nil,
            content: "Building muscle requires a strategic approach to nutrition...\n\n## Caloric Surplus\nAim for 200-500 calories above maintenance.\n\n## Protein Targets\n1.6-2.2g per kg of bodyweight daily.\n\n## Carbohydrates\nFuel your training with adequate carbs around workouts.\n\n## Meal Frequency\n3-5 meals with 20-40g protein each.",
            readTimeMinutes: 10,
            isPremium: true,
            author: "Registered Dietitian Amy Park",
            publishedAt: Date().addingTimeInterval(-86400 * 7),
            isFeatured: false,
            tags: ["nutrition", "muscle", "diet"]
        ),
        ContentArticle(
            id: "article-005",
            title: "Mobility vs Flexibility: What You Actually Need",
            summary: "Understanding the difference and building a practical mobility routine.",
            category: .mobility,
            imageURL: nil,
            content: "Mobility and flexibility are not the same thing...\n\n## Flexibility\nPassive range of motion. Think: touching your toes.\n\n## Mobility\nActive range of motion under control. Think: deep squat with upright torso.\n\n## What Matters More?\nMobility is more functional for training. Focus on active range of motion.",
            readTimeMinutes: 4,
            isPremium: false,
            author: "Dr. James Liu, DPT",
            publishedAt: Date().addingTimeInterval(-86400),
            isFeatured: false,
            tags: ["mobility", "flexibility", "warmup"]
        ),
        ContentArticle(
            id: "article-006",
            title: "Mental Performance: Training Your Mind Like Your Body",
            summary: "Sport psychology techniques to improve focus, confidence, and consistency.",
            category: .mentalHealth,
            imageURL: nil,
            content: "Your mind is part of your training toolkit...\n\n## Visualization\nMentally rehearse lifts before attempting them.\n\n## Self-Talk\nReplace negative thoughts with process-focused cues.\n\n## Goal Setting\nUse SMART goals tied to controllable behaviors.",
            readTimeMinutes: 6,
            isPremium: true,
            author: "Dr. Katie Brennan, PsyD",
            publishedAt: Date().addingTimeInterval(-86400 * 4),
            isFeatured: false,
            tags: ["mental-health", "psychology", "focus"]
        )
    ]
}

// MARK: - Content Category

/// Categories for content hub articles
enum ContentCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case trainingTips = "training_tips"
    case nutrition = "nutrition"
    case recovery = "recovery"
    case mobility = "mobility"
    case mentalHealth = "mental_health"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .trainingTips: return "Training Tips"
        case .nutrition: return "Nutrition"
        case .recovery: return "Recovery"
        case .mobility: return "Mobility"
        case .mentalHealth: return "Mental Health"
        }
    }

    var icon: String {
        switch self {
        case .trainingTips: return "dumbbell.fill"
        case .nutrition: return "fork.knife"
        case .recovery: return "bed.double.fill"
        case .mobility: return "figure.flexibility"
        case .mentalHealth: return "brain.head.profile"
        }
    }
}

// MARK: - Momentous Supplement Recommendation

/// A supplement recommendation from the Momentous partnership.
///
/// These are contextual recommendations based on the user's training goals
/// and recovery data. Each recommendation includes an affiliate link for
/// purchase tracking and revenue sharing.
struct MomentousRecommendation: Identifiable, Codable, Equatable, Hashable {
    /// Unique identifier
    let id: String

    /// Product name (e.g. "Creatine Monohydrate")
    let name: String

    /// Product description
    let description: String

    /// Key benefits as bullet points
    let benefits: [String]

    /// URL for the product image
    let imageURL: String?

    /// Base affiliate URL for Momentous store
    let affiliateURL: String

    /// Retail price in USD
    let price: Double

    /// Training context for this recommendation (e.g. "Recovery", "Performance")
    let context: String

    /// Evidence rating (1-5)
    let evidenceRating: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case benefits
        case imageURL = "image_url"
        case affiliateURL = "affiliate_url"
        case price
        case context
        case evidenceRating = "evidence_rating"
    }

    /// Formatted price string
    var formattedPrice: String {
        String(format: "$%.2f", price)
    }

    /// Star rating display string
    var evidenceStars: String {
        String(repeating: "\u{2605}", count: evidenceRating) +
        String(repeating: "\u{2606}", count: 5 - evidenceRating)
    }

    // MARK: - Demo Recommendations

    static let demoRecommendations: [MomentousRecommendation] = [
        MomentousRecommendation(
            id: "momentous-001",
            name: "Creatine Monohydrate",
            description: "Pharmaceutical-grade creatine for strength, power, and cognitive performance.",
            benefits: ["Increases strength output", "Supports muscle recovery", "Enhances cognitive function"],
            imageURL: nil,
            affiliateURL: "https://www.livemomentous.com/products/creatine",
            price: 34.95,
            context: "Performance",
            evidenceRating: 5
        ),
        MomentousRecommendation(
            id: "momentous-002",
            name: "Omega-3 Fish Oil",
            description: "High-potency EPA/DHA for inflammation management and joint health.",
            benefits: ["Reduces exercise-induced inflammation", "Supports joint mobility", "Promotes cardiovascular health"],
            imageURL: nil,
            affiliateURL: "https://www.livemomentous.com/products/omega3",
            price: 44.95,
            context: "Recovery",
            evidenceRating: 5
        ),
        MomentousRecommendation(
            id: "momentous-003",
            name: "Magnesium Threonate",
            description: "Optimized magnesium form for sleep quality and neural recovery.",
            benefits: ["Improves deep sleep duration", "Supports nervous system recovery", "Reduces muscle cramping"],
            imageURL: nil,
            affiliateURL: "https://www.livemomentous.com/products/magnesium",
            price: 39.95,
            context: "Sleep",
            evidenceRating: 4
        ),
        MomentousRecommendation(
            id: "momentous-004",
            name: "Whey Protein Isolate",
            description: "Grass-fed whey isolate with 25g protein per serving for muscle protein synthesis.",
            benefits: ["Fast-absorbing post-workout", "25g complete protein", "Low lactose content"],
            imageURL: nil,
            affiliateURL: "https://www.livemomentous.com/products/whey-protein",
            price: 54.95,
            context: "Performance",
            evidenceRating: 5
        ),
        MomentousRecommendation(
            id: "momentous-005",
            name: "Vitamin D3",
            description: "High-dose vitamin D3 for immune function and bone health.",
            benefits: ["Supports immune function", "Essential for bone density", "Improves mood and energy"],
            imageURL: nil,
            affiliateURL: "https://www.livemomentous.com/products/vitamin-d3",
            price: 24.95,
            context: "Recovery",
            evidenceRating: 4
        )
    ]
}
