//
//  HelpContentLoader.swift
//  PTPerformance
//
//  Service to load help articles from Supabase
//

import Foundation
import Supabase

/// Loads and caches help articles from Supabase help_articles table
class HelpContentLoader: ObservableObject {
    static let shared = HelpContentLoader()

    @Published var articles: [HelpArticle] = []
    @Published var isLoading = false
    @Published var error: String?

    private let supabase = PTSupabaseClient.shared.client

    private init() {
        // Load articles on initialization
        Task {
            await loadArticles()
        }
    }

    /// Load help articles from Supabase
    @MainActor
    func loadArticles() async {
        isLoading = true
        error = nil

        do {
            // Fetch published articles from content_items table (194 baseball articles)
            let response: [SupabaseContentItem] = try await supabase
                .from("content_items")
                .select("""
                    id,
                    slug,
                    title,
                    category,
                    subcategory,
                    content,
                    tags,
                    excerpt,
                    is_published
                """)
                .eq("is_published", value: true)
                .order("category", ascending: true)
                .order("title", ascending: true)
                .execute()
                .value

            // Map to app models
            articles = response.compactMap { mapContentItemFromDB($0) }

            #if DEBUG
            print("✅ Loaded \(articles.count) help articles from Supabase content_items table")
            #endif

        } catch {
            self.error = "Failed to load help articles: \(error.localizedDescription)"
            #if DEBUG
            print("❌ Error loading help articles: \(error.localizedDescription)")
            print("❌ Full error: \(error)")
            #endif

            // Load sample articles as fallback
            loadSampleArticles()
        }

        isLoading = false
    }

    /// Reload articles (pull-to-refresh)
    func reload() {
        Task {
            await loadArticles()
        }
    }

    /// Map Supabase content_items to app model with category mapping
    private func mapContentItemFromDB(_ item: SupabaseContentItem) -> HelpArticle? {
        // Convert string ID to UUID
        guard let articleId = UUID(uuidString: item.id) else {
            #if DEBUG
            print("⚠️ Skipping article with invalid UUID: \(item.id)")
            #endif
            return nil
        }

        // Map database categories to app categories
        let category: HelpCategory
        switch item.category.lowercased() {
        case "nutrition", "recovery", "warmup", "preparation":
            category = .gettingStarted
        case "training", "arm-care", "injury-prevention":
            category = .programs
        case "hitting", "speed", "mobility":
            category = .workouts
        case "mental":
            category = .analytics
        default:
            category = .gettingStarted
        }

        // Extract markdown content from nested structure (handle optional)
        let markdownContent = item.content.markdown ?? ""

        return HelpArticle(
            id: articleId,
            title: item.title,
            content: markdownContent,
            category: category,
            keywords: item.tags ?? []
        )
    }

    /// Load articles from local JSON file as fallback
    private func loadSampleArticles() {
        // Try to load from bundled JSON file first
        if let url = Bundle.main.url(forResource: "HelpContent", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let jsonArticles = try? JSONDecoder().decode([JSONHelpArticle].self, from: data) {

            articles = jsonArticles.compactMap { jsonArticle in
                // Convert string ID to UUID
                guard let articleId = UUID(uuidString: jsonArticle.id) else {
                    #if DEBUG
                    print("⚠️ Skipping article with invalid UUID: \(jsonArticle.id)")
                    #endif
                    return nil
                }

                let category: HelpCategory
                switch jsonArticle.category.lowercased() {
                case "gettingstarted":
                    category = .gettingStarted
                case "programs":
                    category = .programs
                case "workouts":
                    category = .workouts
                case "analytics":
                    category = .analytics
                default:
                    category = .gettingStarted
                }

                return HelpArticle(
                    id: articleId,
                    title: jsonArticle.title,
                    content: jsonArticle.content,
                    category: category,
                    keywords: jsonArticle.keywords
                )
            }

            #if DEBUG
            print("✅ Loaded \(articles.count) help articles from local JSON file")
            #endif
            return
        }

        // Fallback to hardcoded sample articles if JSON file not found
        articles = [
            HelpArticle(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                title: "Getting Started with Modus",
                content: """
                # Welcome to Modus

                Modus helps you track your training, monitor progress, and work with your therapist to achieve your athletic goals.

                ## Key Features

                - **Programs**: Follow structured training programs designed by your therapist
                - **Workouts**: Complete daily sessions with exercise tracking
                - **Analytics**: View your progress over time
                - **Communication**: Stay connected with your therapist

                ## Getting Started

                1. Complete your profile setup
                2. Review your assigned program
                3. Start your first workout
                4. Track your progress

                Need help? Tap the help icon anytime.
                """,
                category: .gettingStarted,
                keywords: ["welcome", "introduction", "setup", "basics"]
            ),
            HelpArticle(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                title: "Creating Your First Program",
                content: """
                # Creating a Training Program

                Programs are structured training plans that guide your athletic development.

                ## Program Structure

                - **Phases**: Programs are divided into training phases (e.g., Off-Season, Pre-Season)
                - **Weeks**: Each phase contains weekly training schedules
                - **Sessions**: Individual workouts scheduled throughout the week

                ## Creating a Program

                1. Go to Programs tab
                2. Tap "New Program"
                3. Choose your sport and focus area
                4. Select duration and frequency
                5. Review and save

                Your therapist can also create programs for you.
                """,
                category: .programs,
                keywords: ["program", "create", "training plan", "structure"]
            ),
            HelpArticle(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                title: "Completing Your Workouts",
                content: """
                # How to Complete Workouts

                Follow these steps to log your training sessions effectively.

                ## During Your Workout

                1. **Start Session**: Tap on today's scheduled workout
                2. **Follow Exercises**: Complete each exercise in order
                3. **Log Performance**: Enter sets, reps, and weights
                4. **Add Notes**: Record how you felt or any issues

                ## Exercise Tracking

                - Tap checkmark after completing each set
                - Use video demonstrations for proper form
                - Adjust weights based on your readiness

                ## After Completion

                - Rate your session difficulty
                - Share notes with your therapist
                - Review your progress
                """,
                category: .workouts,
                keywords: ["workout", "exercise", "log", "complete", "tracking"]
            ),
            HelpArticle(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
                title: "Understanding Your Analytics",
                content: """
                # Analytics & Progress Tracking

                PT Performance tracks your progress automatically.

                ## Key Metrics

                - **Volume**: Total training load over time
                - **Readiness**: Daily readiness scores
                - **Compliance**: Workout completion rate
                - **Performance**: Strength and skill improvements

                ## Charts & Trends

                - View weekly and monthly trends
                - Compare phases of training
                - Identify patterns

                ## Sharing with Your Therapist

                Your therapist can see all your data to:
                - Adjust your program
                - Monitor recovery
                - Prevent overtraining
                """,
                category: .analytics,
                keywords: ["analytics", "progress", "metrics", "charts", "tracking"]
            )
        ]

        #if DEBUG
        print("⚠️ Using hardcoded sample articles (JSON file and database unavailable)")
        #endif
    }
}

/// Helper struct for decoding JSON articles
private struct JSONHelpArticle: Codable {
    let id: String
    let title: String
    let category: String
    let keywords: [String]
    let content: String
}

// Note: SupabaseContentItem is defined in Models/SupabaseContentModels.swift
