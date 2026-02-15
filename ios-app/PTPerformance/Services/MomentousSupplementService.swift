//
//  MomentousSupplementService.swift
//  PTPerformance
//
//  ACP-1008: Momentous Supplement Revenue — Supplement partnership integration
//  Contextual supplement recommendations with affiliate link tracking.
//

import Foundation

// MARK: - Training Goal Context

/// Training goals used to contextualize supplement recommendations.
/// Maps user activity patterns to relevant Momentous products.
enum TrainingGoalContext: String, CaseIterable, Identifiable {
    case performance = "performance"
    case recovery = "recovery"
    case sleep = "sleep"
    case endurance = "endurance"
    case strength = "strength"
    case generalWellness = "general_wellness"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .performance: return "Performance"
        case .recovery: return "Recovery"
        case .sleep: return "Sleep"
        case .endurance: return "Endurance"
        case .strength: return "Strength"
        case .generalWellness: return "General Wellness"
        }
    }
}

// MARK: - Momentous Supplement Service

/// Manages the Momentous supplement partnership integration.
///
/// Provides contextual supplement recommendations based on the user's training
/// goals and recovery data. Tracks affiliate link clicks for revenue attribution
/// and syncs click events to Supabase for analytics.
///
/// ## Partner Content Transparency
/// All recommendations are clearly labeled as "Partner Content" to maintain
/// user trust and comply with FTC disclosure guidelines.
///
/// ## Usage
/// ```swift
/// let service = MomentousSupplementService.shared
/// let recs = service.getRecommendations(for: .recovery)
/// // Display in SupplementRecommendationView
/// service.recordSupplementClick(recs.first!)
/// ```
@MainActor
class MomentousSupplementService: ObservableObject {

    // MARK: - Singleton

    static let shared = MomentousSupplementService()

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let logger: DebugLogger

    // MARK: - Constants

    private enum Constants {
        static let affiliateParam = "ref"
        static let affiliateCode = "modus_app"
        static let clickTrackingTable = "supplement_click_events"
        static let recommendationsTable = "momentous_recommendations"
        static let userDefaultsClickCountKey = "momentous_click_count"
    }

    // MARK: - Published Properties

    /// All available Momentous recommendations
    @Published var recommendations: [MomentousRecommendation] = []

    /// Loading state
    @Published var isLoading = false

    /// Error state
    @Published var errorMessage: String?

    /// Total click count for analytics
    @Published private(set) var totalClickCount: Int = 0

    // MARK: - Initialization

    init(
        supabase: PTSupabaseClient = .shared,
        logger: DebugLogger = .shared
    ) {
        self.supabase = supabase
        self.logger = logger
        self.totalClickCount = UserDefaults.standard.integer(forKey: Constants.userDefaultsClickCountKey)
        logger.info("MomentousSupplementService", "Initializing Momentous supplement partnership service")
    }

    // MARK: - Fetch Recommendations

    /// Fetches supplement recommendations from Supabase, falling back to demo data.
    func fetchRecommendations() async {
        logger.diagnostic("MomentousSupplementService: Fetching recommendations from server")
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await supabase.client
                .from(Constants.recommendationsTable)
                .select()
                .order("evidence_rating", ascending: false)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let fetched = try decoder.decode([MomentousRecommendation].self, from: response.data)
            recommendations = fetched
            logger.success("MomentousSupplementService", "Fetched \(fetched.count) Momentous recommendations")
        } catch {
            logger.warning("MomentousSupplementService", "Server fetch failed: \(error.localizedDescription). Using demo data.")
            recommendations = MomentousRecommendation.demoRecommendations
        }
    }

    // MARK: - Get Contextual Recommendations

    /// Returns supplement recommendations filtered by the user's current training goal.
    ///
    /// - Parameter goal: The training goal to filter by
    /// - Returns: Sorted array of relevant recommendations
    func getRecommendations(for goal: TrainingGoalContext) -> [MomentousRecommendation] {
        let contextMapping: [TrainingGoalContext: [String]] = [
            .performance: ["Performance"],
            .recovery: ["Recovery"],
            .sleep: ["Sleep"],
            .endurance: ["Performance", "Recovery"],
            .strength: ["Performance"],
            .generalWellness: ["Recovery", "Sleep", "Performance"]
        ]

        let relevantContexts = contextMapping[goal] ?? ["Performance"]
        let filtered = recommendations.filter { relevantContexts.contains($0.context) }

        logger.diagnostic("MomentousSupplementService: Found \(filtered.count) recommendations for goal: \(goal.displayName)")
        return filtered.sorted { $0.evidenceRating > $1.evidenceRating }
    }

    // MARK: - Affiliate URL Generation

    /// Generates an affiliate URL for a supplement, appending the user referral parameter.
    ///
    /// - Parameter supplement: The supplement to generate a link for
    /// - Returns: The affiliate URL with tracking parameters
    func affiliateURL(for supplement: MomentousRecommendation) -> URL? {
        guard var components = URLComponents(string: supplement.affiliateURL) else {
            logger.warning("MomentousSupplementService", "Invalid affiliate URL: \(supplement.affiliateURL)")
            return nil
        }

        // Append affiliate referral parameter
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: Constants.affiliateParam, value: Constants.affiliateCode))

        // Append user ID if authenticated for per-user attribution
        if let userId = supabase.userId {
            queryItems.append(URLQueryItem(name: "uid", value: String(userId.prefix(8))))
        }

        components.queryItems = queryItems

        logger.diagnostic("MomentousSupplementService: Generated affiliate URL for \(supplement.name)")
        return components.url
    }

    // MARK: - Click Tracking

    /// Records a supplement link click for affiliate revenue tracking.
    ///
    /// Persists the click event to both local storage (for offline) and
    /// Supabase (for analytics). Deduplication is handled server-side.
    ///
    /// - Parameter supplement: The supplement that was clicked
    func recordSupplementClick(_ supplement: MomentousRecommendation) {
        logger.info("MomentousSupplementService", "Recording click for: \(supplement.name) (id: \(supplement.id))")

        // Update local count
        totalClickCount += 1
        UserDefaults.standard.set(totalClickCount, forKey: Constants.userDefaultsClickCountKey)

        // Async sync to backend
        Task {
            await syncClickToBackend(supplement: supplement)
        }
    }

    // MARK: - Private Helpers

    /// Syncs a click event to Supabase for analytics and affiliate reconciliation.
    private func syncClickToBackend(supplement: MomentousRecommendation) async {
        guard let userId = supabase.userId else {
            logger.diagnostic("MomentousSupplementService: Skipping click sync - no authenticated user")
            return
        }

        do {
            try await supabase.client
                .from(Constants.clickTrackingTable)
                .insert([
                    "user_id": userId,
                    "supplement_id": supplement.id,
                    "supplement_name": supplement.name,
                    "affiliate_url": supplement.affiliateURL,
                    "context": supplement.context,
                    "clicked_at": ISO8601DateFormatter().string(from: Date())
                ])
                .execute()

            logger.success("MomentousSupplementService", "Synced click event for: \(supplement.name)")
        } catch {
            logger.warning("MomentousSupplementService", "Failed to sync click event: \(error.localizedDescription)")
        }
    }
}
