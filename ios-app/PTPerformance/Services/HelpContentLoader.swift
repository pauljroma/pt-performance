//
//  HelpContentLoader.swift
//  PTPerformance
//
//  Service to load help articles from Supabase
//

import Foundation
import Supabase

/// Loads and caches help articles from Supabase help_articles table
@MainActor
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

    /// Load help articles — general fitness content for 1.0 launch
    /// Note: Database content_items table contains sport-specific articles (archived for post-launch).
    /// For MVP, we serve curated general fitness articles directly.
    @MainActor
    func loadArticles() async {
        isLoading = true
        error = nil

        loadSampleArticles()

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
            DebugLogger.shared.log("[HelpContentLoader] Skipping article with invalid UUID: \(item.id)", level: .warning)
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
                    DebugLogger.shared.log("[HelpContentLoader] Skipping article with invalid UUID: \(jsonArticle.id)", level: .warning)
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

            DebugLogger.shared.log("[HelpContentLoader] Loaded \(articles.count) help articles from local JSON file", level: .success)
            return
        }

        // General fitness help articles for 1.0 launch
        articles = [
            // MARK: Getting Started
            HelpArticle(
                id: UUID(uuidString: "a0000000-0000-0000-0000-000000000001") ?? UUID(),
                title: "Welcome to Korza Training",
                content: """
                # Welcome to Korza Training

                Korza Training helps you train smarter and recover faster. Whether you're rehabbing an injury, building strength, or chasing performance goals, the app keeps you on track.

                ## What You Can Do

                - **Follow Programs**: Work through structured training plans with phases, weeks, and daily sessions
                - **Track Workouts**: Log sets, reps, and weights for every exercise
                - **Monitor Progress**: See your streaks, volume trends, and weekly summaries
                - **Check In Daily**: Rate your readiness so the app can guide your intensity

                ## Quick Start

                1. Open the **Today** tab to see your scheduled workout
                2. Tap **Start Workout** to begin logging
                3. Complete each exercise and mark sets as done
                4. Check your streak on the Today tab — consistency is key
                """,
                category: .gettingStarted,
                keywords: ["welcome", "introduction", "setup", "basics", "getting started"]
            ),
            HelpArticle(
                id: UUID(uuidString: "a0000000-0000-0000-0000-000000000002") ?? UUID(),
                title: "Setting Up Your Profile",
                content: """
                # Setting Up Your Profile

                Your profile personalizes the app to match your training goals.

                ## Quick Setup

                When you first open Korza, you'll go through a short setup:

                1. **Choose Your Mode** — Rehab, Strength, or Performance. This customizes your dashboard
                2. **Pick Your Goals** — Select up to 3 focus areas to track

                You can change these anytime in **Settings**.

                ## Your Dashboard

                After setup, your Today tab shows:
                - Today's scheduled workout
                - Your current streak
                - Quick access to timers and check-ins

                ## Settings

                Visit Settings to update your profile, manage notifications, and adjust preferences.
                """,
                category: .gettingStarted,
                keywords: ["profile", "setup", "mode", "goals", "preferences"]
            ),

            // MARK: Programs
            HelpArticle(
                id: UUID(uuidString: "a0000000-0000-0000-0000-000000000003") ?? UUID(),
                title: "Understanding Your Program",
                content: """
                # Understanding Your Program

                Programs are structured training plans organized into phases, weeks, and sessions.

                ## Program Structure

                - **Program**: Your overall training plan (e.g., "12-Week Strength Builder")
                - **Phases**: Blocks within the program (e.g., "Foundation", "Build", "Peak")
                - **Sessions**: Individual workouts scheduled on specific days

                ## Following Your Program

                1. Go to the **Today** tab to see today's session
                2. Each session lists exercises with target sets, reps, and weights
                3. Complete the exercises and log your actual performance
                4. The app tracks your progress across the full program

                ## Program Progression

                As you complete sessions, the app tracks your volume and consistency. Your therapist or coach can adjust the program based on your progress.
                """,
                category: .programs,
                keywords: ["program", "phase", "training plan", "structure", "schedule"]
            ),
            HelpArticle(
                id: UUID(uuidString: "a0000000-0000-0000-0000-000000000004") ?? UUID(),
                title: "Streaks and Consistency",
                content: """
                # Streaks and Consistency

                Your streak tracks consecutive days of completing workouts. Consistency is the single biggest predictor of results.

                ## How Streaks Work

                - Complete at least one workout to keep your streak alive
                - Your streak counter appears on the Today tab
                - Miss a day and your streak resets

                ## Streak Dashboard

                Tap the flame icon to see:
                - Your current streak length
                - Your longest streak ever
                - Weekly workout history

                ## Tips for Building Consistency

                - Start with shorter, manageable workouts
                - Schedule workouts at the same time each day
                - Use the daily check-in to stay accountable
                """,
                category: .programs,
                keywords: ["streak", "consistency", "habit", "motivation", "daily"]
            ),

            // MARK: Workouts
            HelpArticle(
                id: UUID(uuidString: "a0000000-0000-0000-0000-000000000005") ?? UUID(),
                title: "Completing a Workout",
                content: """
                # Completing a Workout

                Follow these steps to get the most out of each training session.

                ## Starting Your Workout

                1. Open the **Today** tab
                2. Tap **Start Workout** on your scheduled session
                3. The exercise list appears with target sets, reps, and weights

                ## Logging Sets

                For each exercise:
                - Enter your actual weight and reps
                - Tap the checkmark to complete the set
                - Add notes if needed (e.g., "felt easy", "form breakdown")

                ## Finishing Up

                When all exercises are complete:
                - Review your session summary
                - Your streak updates automatically
                - Volume data feeds into your weekly summary
                """,
                category: .workouts,
                keywords: ["workout", "exercise", "log", "sets", "reps", "complete"]
            ),
            HelpArticle(
                id: UUID(uuidString: "a0000000-0000-0000-0000-000000000006") ?? UUID(),
                title: "Exercise Substitutions",
                content: """
                # Exercise Substitutions

                Can't do a prescribed exercise? Korza can suggest alternatives.

                ## When to Substitute

                - Equipment isn't available
                - An exercise causes discomfort
                - You need a regression or progression

                ## How It Works

                1. During a workout, tap the exercise name
                2. Select **Substitute Exercise**
                3. The app suggests alternatives that target the same muscle groups
                4. Pick a substitute and continue your workout

                ## Important Notes

                - Substitutions are logged so your therapist can review them
                - If an exercise causes pain, stop and note it — don't just substitute
                - Your program's overall volume is maintained with smart substitutions
                """,
                category: .workouts,
                keywords: ["substitute", "alternative", "exercise", "swap", "equipment"]
            ),
            HelpArticle(
                id: UUID(uuidString: "a0000000-0000-0000-0000-000000000007") ?? UUID(),
                title: "Using Timers",
                content: """
                # Using Timers

                Rest timers help you maintain proper recovery between sets.

                ## Rest Timer

                - Set a rest period (30s, 60s, 90s, or custom)
                - The timer starts automatically after completing a set
                - You'll get a notification when rest is over

                ## Workout Timer

                - Tracks total workout duration
                - Runs in the background while you exercise
                - Shows elapsed time on the Today tab

                ## Tips

                - Stick to prescribed rest periods for best results
                - Shorter rest (30-60s) for endurance and muscle building
                - Longer rest (2-3 min) for heavy strength work
                """,
                category: .workouts,
                keywords: ["timer", "rest", "interval", "countdown", "recovery"]
            ),

            // MARK: Analytics
            HelpArticle(
                id: UUID(uuidString: "a0000000-0000-0000-0000-000000000008") ?? UUID(),
                title: "Weekly Summaries",
                content: """
                # Weekly Summaries

                Every week, Korza generates a summary of your training.

                ## What's Included

                - **Workouts Completed**: How many sessions you finished
                - **Total Volume**: Combined weight moved across all exercises
                - **Streak Status**: Your current and longest streaks
                - **Trends**: Whether your volume is increasing, stable, or decreasing

                ## Viewing Your Summary

                - Summaries appear automatically at the end of each week
                - Access past summaries from the Today tab menu
                - Share summaries with your therapist or coach

                ## Using Summaries to Improve

                - Look for consistent upward trends in volume
                - If volume drops, check if you're recovering enough
                - Aim for at least 80% workout completion each week
                """,
                category: .analytics,
                keywords: ["weekly", "summary", "volume", "trends", "progress"]
            ),
            HelpArticle(
                id: UUID(uuidString: "a0000000-0000-0000-0000-000000000009") ?? UUID(),
                title: "Daily Readiness Check-In",
                content: """
                # Daily Readiness Check-In

                The daily check-in helps you train at the right intensity.

                ## How It Works

                1. Open the check-in from the Today tab
                2. Rate how you feel across key areas (sleep, energy, soreness)
                3. Get a readiness score that guides your training intensity

                ## Readiness Scores

                - **High (80+)**: You're fresh — push hard today
                - **Moderate (60-79)**: Normal training, stay on program
                - **Low (40-59)**: Consider reducing intensity or volume
                - **Very Low (<40)**: Focus on recovery — light movement only

                ## Why It Matters

                Training hard when you're not recovered leads to overtraining and injury. The readiness check-in helps you make smart decisions about intensity every day.
                """,
                category: .analytics,
                keywords: ["readiness", "check-in", "recovery", "sleep", "energy", "soreness"]
            )
        ]

        DebugLogger.shared.log("[HelpContentLoader] Loaded \(articles.count) general fitness help articles", level: .success)
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
