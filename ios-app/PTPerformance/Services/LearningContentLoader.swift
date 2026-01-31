//
//  LearningContentLoader.swift
//  PTPerformance
//
//  Service to load learning articles from Supabase content_library table
//

import Foundation
import Supabase

/// Loads and caches learning articles from Supabase content_library table
class LearningContentLoader: ObservableObject {
    static let shared = LearningContentLoader()

    @Published var articles: [LearningArticle] = []
    @Published var isLoading = false
    @Published var error: String?

    private let supabase = PTSupabaseClient.shared.client

    private init() {
        // Load articles on initialization
        Task {
            await loadArticles()
        }
    }

    /// Load learning articles from Supabase content_items table
    @MainActor
    func loadArticles() async {
        isLoading = true
        error = nil

        do {
            // Fetch published articles from content_items table (new flexible content system)
            // Filter for baseball/learning categories (exclude help articles)
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
                    difficulty,
                    estimated_duration_minutes,
                    excerpt,
                    is_published
                """)
                .eq("is_published", value: true)
                .in("category", values: [
                    "arm-care", "hitting", "injury-prevention", "mental",
                    "mobility", "nutrition", "preparation", "recovery",
                    "speed", "training", "warmup"
                ])
                .order("category", ascending: true)
                .order("title", ascending: true)
                .execute()
                .value

            // Map to app models
            articles = response.compactMap { mapToLearningArticle($0) }

            #if DEBUG
            print("✅ Loaded \(articles.count) learning articles from Supabase")
            #endif

        } catch {
            self.error = "Failed to load learning articles: \(error.localizedDescription)"
            #if DEBUG
            print("❌ Error loading learning articles: \(error.localizedDescription)")
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

    /// Map Supabase content_item to app model
    private func mapToLearningArticle(_ item: SupabaseContentItem) -> LearningArticle? {
        // Extract markdown content from JSONB content field
        guard let content = item.content.markdown else {
            #if DEBUG
            print("⚠️ Could not extract markdown content for article '\(item.title)'")
            #endif
            return nil
        }

        // Map database category to enum
        guard let category = LearningCategory.fromDatabaseString(item.category) else {
            #if DEBUG
            print("⚠️ Unknown category '\(item.category)' for article '\(item.title)'")
            #endif
            return nil
        }

        return LearningArticle(
            id: item.slug,
            title: item.title,
            content: content,
            category: category,
            subcategory: item.subcategory,
            keywords: item.tags ?? [],
            readingTimeMinutes: item.estimated_duration_minutes,
            difficulty: item.difficulty,
            excerpt: item.excerpt
        )
    }

    /// Load sample articles as fallback when database is unavailable
    private func loadSampleArticles() {
        articles = [
            LearningArticle(
                id: "sample-recovery",
                title: "Sleep for Pitchers: Why Arm Recovery Happens at Night",
                content: """
                # Sleep for Pitchers: Why Arm Recovery Happens at Night

                **Category:** Recovery & Sleep
                **Reading Time:** 6 minutes

                ## The Science Behind Overnight Arm Recovery

                When you finish a start and head to the clubhouse, your recovery work has just begun. While ice, stretching, and nutrition play important roles, the most critical recovery phase happens while you sleep.

                ## Why Your Arm Recovers During Sleep

                During deep sleep (NREM stages 3 and 4), your body releases human growth hormone (HGH), which drives tissue repair and muscle recovery. For pitchers, this means rebuilding the microtraumas in your rotator cuff, labrum, and ulnar collateral ligament that occur with every pitch.

                ## The 8-10 Hour Requirement

                Elite athletes need 8-10 hours of sleep per night—significantly more than the general population's 7-hour recommendation.

                ## Practical Sleep Strategies for Pitchers

                **Post-Game Routine:** After night games, create a wind-down protocol. Avoid screens for 60 minutes before bed, use blackout curtains, and keep your room at 65-68°F.

                **Nutrition Timing:** Avoid heavy meals within 3 hours of bedtime. A small protein snack (Greek yogurt, cottage cheese) 90 minutes before sleep can support overnight muscle protein synthesis.

                **Track Your Recovery:** Use a wearable device to monitor heart rate variability (HRV) and resting heart rate.
                """,
                category: .recovery,
                subcategory: "Sleep",
                keywords: ["sleep", "recovery", "pitching", "arm care"],
                readingTimeMinutes: 6,
                difficulty: "Intermediate",
                excerpt: "The most critical recovery phase for pitchers happens during sleep. Learn why 8-10 hours is essential for arm health."
            ),
            LearningArticle(
                id: "sample-warmup",
                title: "Dynamic Warmup for Baseball Players",
                content: """
                # Dynamic Warmup for Baseball Players

                **Category:** Warmup & Preparation
                **Reading Time:** 5 minutes

                ## Why Dynamic Warmups Matter

                A proper dynamic warmup prepares your body for explosive movements, reduces injury risk, and improves performance.

                ## The Essential Components

                1. **General Movement** (5 minutes)
                   - Light jogging
                   - High knees
                   - Butt kicks
                   - Lateral shuffles

                2. **Dynamic Stretching** (5 minutes)
                   - Leg swings
                   - Arm circles
                   - Walking lunges
                   - Torso rotations

                3. **Sport-Specific Movements** (5 minutes)
                   - Throwing progressions
                   - Batting practice swings
                   - Fielding movements

                ## Key Principles

                - Never static stretch cold muscles
                - Gradually increase intensity
                - Focus on full range of motion
                - Make it sport-specific
                """,
                category: .warmup,
                subcategory: "Pre-Game",
                keywords: ["warmup", "dynamic stretching", "preparation"],
                readingTimeMinutes: 5,
                difficulty: "Beginner",
                excerpt: "Learn the essential components of an effective dynamic warmup routine for baseball players."
            ),
            LearningArticle(
                id: "sample-nutrition",
                title: "Nutrition for Baseball Performance",
                content: """
                # Nutrition for Baseball Performance

                **Category:** Nutrition
                **Reading Time:** 8 minutes

                ## Fueling for Success

                Proper nutrition is essential for optimal baseball performance, recovery, and long-term health.

                ## The Baseball Nutrition Pyramid

                **Foundation: Hydration**
                - Drink 16-20 oz water 2 hours before games
                - Consume 8-10 oz every 15-20 minutes during play
                - Rehydrate with 24 oz per pound lost after games

                **Level 2: Macronutrients**
                - **Carbohydrates:** 45-65% of total calories
                - **Protein:** 1.2-1.7g per kg body weight
                - **Fats:** 20-35% of total calories

                **Level 3: Timing**
                - Pre-game: 2-3 hours before, high carb, moderate protein
                - During: Quick carbs for energy
                - Post-game: Protein + carbs within 30-60 minutes

                ## Sample Meal Plan

                **Breakfast:**
                - Oatmeal with berries and nuts
                - 2 eggs
                - Whole grain toast

                **Pre-Game:**
                - Chicken breast
                - Brown rice
                - Steamed vegetables

                **Post-Game:**
                - Protein shake
                - Banana
                - Handful of almonds
                """,
                category: .nutrition,
                subcategory: "Meal Planning",
                keywords: ["nutrition", "diet", "meal plan", "hydration"],
                readingTimeMinutes: 8,
                difficulty: "Intermediate",
                excerpt: "Master the fundamentals of baseball nutrition to fuel performance and accelerate recovery."
            )
        ]

        #if DEBUG
        print("⚠️ Using sample learning articles (database unavailable)")
        #endif
    }
}
