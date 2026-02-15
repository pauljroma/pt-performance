//
//  SocialSharingService.swift
//  PTPerformance
//
//  ACP-995: Social Sharing Features
//  Service for generating shareable content from workouts, achievements, streaks, and progress
//

import SwiftUI
import UIKit

// MARK: - Share Content

/// Container for shareable content including text, image, and deep link
struct ShareContent: Identifiable {
    let id = UUID()
    let title: String
    let text: String
    let image: UIImage?
    let url: URL?

    /// Items formatted for UIActivityViewController / ShareLink
    var activityItems: [Any] {
        var items: [Any] = [text]
        if let image = image {
            items.append(image)
        }
        if let url = url {
            items.append(url)
        }
        return items
    }
}

// MARK: - Workout Summary for Sharing

/// Lightweight workout summary used by the sharing service
struct ShareableWorkoutSummary {
    let workoutName: String
    let completedAt: Date
    let duration: Int? // minutes
    let totalVolume: Double?
    let exerciseCount: Int
    let personalRecords: [String] // exercise names with PRs
    let topExercise: String?
    let topWeight: Double?
    let topSets: Int?
    let topReps: Int?
}

// MARK: - Progress Snapshot

/// Before/after snapshot for progress sharing
struct ProgressSnapshot {
    let date: Date
    let bodyWeight: Double?
    let benchPress: Double?
    let squat: Double?
    let deadlift: Double?
    let totalVolume: Double?
    let workoutsPerWeek: Double?
    let longestStreak: Int?
}

// MARK: - Social Sharing Service

/// Service for generating branded share content from app data
@MainActor
class SocialSharingService: ObservableObject {

    // MARK: - Singleton

    static let shared = SocialSharingService()

    // MARK: - Private Properties

    private let logger = DebugLogger.shared

    // MARK: - Initialization

    nonisolated init() {}

    // MARK: - Share Workout Summary

    /// Generate shareable content from a workout summary
    func shareWorkoutSummary(_ workout: ShareableWorkoutSummary) -> ShareContent {
        logger.info("SocialSharing", "Generating share content for workout: \(workout.workoutName)")

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        var lines: [String] = []
        lines.append("Just crushed \(workout.workoutName)!")

        if let duration = workout.duration {
            lines.append("Duration: \(duration) min")
        }
        if let volume = workout.totalVolume, volume > 0 {
            lines.append("Total Volume: \(formatVolume(volume))")
        }
        lines.append("Exercises: \(workout.exerciseCount)")

        if !workout.personalRecords.isEmpty {
            let prNames = workout.personalRecords.prefix(3).joined(separator: ", ")
            lines.append("New PRs: \(prNames)")
        }

        lines.append("")
        lines.append("Powered by Modus PT")

        let text = lines.joined(separator: "\n")
        let url = URL(string: "https://app.moduspt.com")

        // Render the share card image
        let cardView = ShareCardView(
            variant: .workout(
                exerciseName: workout.topExercise ?? workout.workoutName,
                sets: workout.topSets,
                reps: workout.topReps,
                weight: workout.topWeight,
                isPR: !workout.personalRecords.isEmpty,
                date: workout.completedAt,
                duration: workout.duration,
                totalVolume: workout.totalVolume,
                exerciseCount: workout.exerciseCount
            )
        )
        let image = renderCardAsImage(cardView)

        logger.success("SocialSharing", "Workout share content generated successfully")
        return ShareContent(title: "Workout Complete", text: text, image: image, url: url)
    }

    // MARK: - Share Achievement

    /// Generate shareable content from an unlocked achievement
    func shareAchievement(_ achievement: AchievementDefinition, unlockedAt: Date = Date()) -> ShareContent {
        logger.info("SocialSharing", "Generating share content for achievement: \(achievement.title)")

        var lines: [String] = []
        lines.append("Achievement Unlocked!")
        lines.append(achievement.title)
        lines.append(achievement.description)
        lines.append("")
        lines.append("Tier: \(achievement.tier.displayName)")
        lines.append("")
        lines.append("Powered by Modus PT")

        let text = lines.joined(separator: "\n")
        let url = URL(string: "https://app.moduspt.com")

        let cardView = ShareCardView(
            variant: .achievement(
                iconName: achievement.iconName,
                title: achievement.title,
                description: achievement.description,
                tier: achievement.tier.displayName,
                unlockedAt: unlockedAt
            )
        )
        let image = renderCardAsImage(cardView)

        logger.success("SocialSharing", "Achievement share content generated successfully")
        return ShareContent(title: "Achievement Unlocked", text: text, image: image, url: url)
    }

    // MARK: - Share Streak

    /// Generate shareable content from a streak count
    func shareStreak(_ days: Int) -> ShareContent {
        logger.info("SocialSharing", "Generating share content for \(days)-day streak")

        let motivationalText = streakMotivationalText(for: days)

        var lines: [String] = []
        lines.append("\(days)-Day Streak!")
        lines.append(motivationalText)
        lines.append("")
        lines.append("Powered by Modus PT")

        let text = lines.joined(separator: "\n")
        let url = URL(string: "https://app.moduspt.com")

        let cardView = ShareCardView(
            variant: .streak(days: days, motivationalText: motivationalText)
        )
        let image = renderCardAsImage(cardView)

        logger.success("SocialSharing", "Streak share content generated successfully")
        return ShareContent(title: "Streak Milestone", text: text, image: image, url: url)
    }

    // MARK: - Share Progress

    /// Generate shareable content from before/after progress snapshots
    func shareProgress(before: ProgressSnapshot, after: ProgressSnapshot) -> ShareContent {
        logger.info("SocialSharing", "Generating share content for progress comparison")

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        var lines: [String] = []
        lines.append("Progress Update")
        lines.append("\(dateFormatter.string(from: before.date)) -> \(dateFormatter.string(from: after.date))")
        lines.append("")

        if let beforeWeight = before.bodyWeight, let afterWeight = after.bodyWeight {
            let diff = afterWeight - beforeWeight
            let sign = diff >= 0 ? "+" : ""
            lines.append("Body Weight: \(formatWeight(beforeWeight)) -> \(formatWeight(afterWeight)) (\(sign)\(formatWeight(diff)))")
        }

        if let beforeBench = before.benchPress, let afterBench = after.benchPress {
            let diff = afterBench - beforeBench
            let sign = diff >= 0 ? "+" : ""
            lines.append("Bench Press: \(formatWeight(beforeBench)) -> \(formatWeight(afterBench)) (\(sign)\(formatWeight(diff)))")
        }

        if let beforeSquat = before.squat, let afterSquat = after.squat {
            let diff = afterSquat - beforeSquat
            let sign = diff >= 0 ? "+" : ""
            lines.append("Squat: \(formatWeight(beforeSquat)) -> \(formatWeight(afterSquat)) (\(sign)\(formatWeight(diff)))")
        }

        if let beforeDL = before.deadlift, let afterDL = after.deadlift {
            let diff = afterDL - beforeDL
            let sign = diff >= 0 ? "+" : ""
            lines.append("Deadlift: \(formatWeight(beforeDL)) -> \(formatWeight(afterDL)) (\(sign)\(formatWeight(diff)))")
        }

        lines.append("")
        lines.append("Powered by Modus PT")

        let text = lines.joined(separator: "\n")
        let url = URL(string: "https://app.moduspt.com")

        let cardView = ShareCardView(
            variant: .progress(before: before, after: after)
        )
        let image = renderCardAsImage(cardView)

        logger.success("SocialSharing", "Progress share content generated successfully")
        return ShareContent(title: "Progress Update", text: text, image: image, url: url)
    }

    // MARK: - Present Share Sheet

    /// Present the system share sheet with the given content
    func presentShareSheet(content: ShareContent) {
        logger.info("SocialSharing", "Presenting share sheet for: \(content.title)")
        HapticFeedback.medium()

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            logger.error("SocialSharing", "Failed to find root view controller for share sheet")
            return
        }

        let activityVC = UIActivityViewController(
            activityItems: content.activityItems,
            applicationActivities: nil
        )

        // Exclude irrelevant activities
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks,
            .saveToCameraRoll
        ]

        // iPad popover support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootViewController.view
            popover.sourceRect = CGRect(
                x: rootViewController.view.bounds.midX,
                y: rootViewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        // Find the topmost presented view controller
        var topVC = rootViewController
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        topVC.present(activityVC, animated: true) { [weak self] in
            self?.logger.diagnostic("[SocialSharing]Share sheet presented")
        }
    }

    // MARK: - Private Helpers

    /// Render a SwiftUI view as a UIImage for sharing
    private func renderCardAsImage<V: View>(_ view: V) -> UIImage? {
        let hostingController = UIHostingController(rootView: view)
        let targetSize = CGSize(width: 390, height: 520)

        hostingController.view.bounds = CGRect(origin: .zero, size: targetSize)
        hostingController.view.backgroundColor = .clear

        // Force layout pass
        hostingController.view.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let image = renderer.image { _ in
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }

        logger.diagnostic("[SocialSharing]Rendered share card image: \(targetSize)")
        return image
    }

    /// Format volume for display
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk lbs", volume / 1000)
        }
        return String(format: "%.0f lbs", volume)
    }

    /// Format weight for display
    private func formatWeight(_ weight: Double) -> String {
        if weight == floor(weight) {
            return String(format: "%.0f lbs", weight)
        }
        return String(format: "%.1f lbs", weight)
    }

    /// Get motivational text for a streak count
    private func streakMotivationalText(for days: Int) -> String {
        switch days {
        case 1...6:
            return "Building momentum, one day at a time."
        case 7...13:
            return "A full week of consistency. Keep it going!"
        case 14...29:
            return "Two weeks strong. Discipline is becoming habit."
        case 30...59:
            return "A whole month of dedication. Unstoppable!"
        case 60...89:
            return "60+ days in. This is who you are now."
        case 90...179:
            return "90-day warrior. True commitment on display."
        case 180...364:
            return "Half a year of relentless work. Legendary."
        case 365...:
            return "365+ days. You are a force of nature."
        default:
            return "Every day counts. Keep showing up."
        }
    }
}

// MARK: - Share Sheet View Representable

/// UIViewControllerRepresentable wrapper for UIActivityViewController
struct ShareSheetView: UIViewControllerRepresentable {
    let content: ShareContent

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityVC = UIActivityViewController(
            activityItems: content.activityItems,
            applicationActivities: nil
        )
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks
        ]
        return activityVC
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
