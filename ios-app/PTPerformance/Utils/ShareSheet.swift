//
//  ShareSheet.swift
//  PTPerformance
//
//  Utility for sharing content via UIActivityViewController
//

import SwiftUI
import UIKit

/// SwiftUI wrapper for UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: applicationActivities
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

/// Helper for creating shareable achievement images
enum AchievementShareHelper {

    /// Generate a shareable text for an achievement
    static func shareText(for achievement: AchievementDefinition, earnedDate: Date?) -> String {
        let dateString: String
        if let date = earnedDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            dateString = formatter.string(from: date)
        } else {
            dateString = "recently"
        }

        return """
        I just unlocked the "\(achievement.title)" achievement in Korza Training! 🏆

        \(achievement.description)

        Earned: \(dateString)
        Tier: \(achievement.tier.displayName)
        Rarity: \(achievement.rarity.displayName)

        #KorzaTraining #FitnessGoals #Achievement
        """
    }
}
