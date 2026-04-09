//
//  ShareCardView.swift
//  PTPerformance
//
//  ACP-995: Social Sharing Features
//  Branded share card generator for workouts, achievements, streaks, and progress
//

import SwiftUI

// MARK: - Share Card Variant

/// The type of share card to render
enum ShareCardVariant {
    case workout(
        exerciseName: String,
        sets: Int?,
        reps: Int?,
        weight: Double?,
        isPR: Bool,
        date: Date,
        duration: Int?,
        totalVolume: Double?,
        exerciseCount: Int
    )
    case achievement(
        iconName: String,
        title: String,
        description: String,
        tier: String,
        unlockedAt: Date
    )
    case streak(
        days: Int,
        motivationalText: String
    )
    case progress(
        before: ProgressSnapshot,
        after: ProgressSnapshot
    )
}

// MARK: - Share Card View

/// Modus-branded share card for social sharing
/// Rendered as UIImage by SocialSharingService for sharing via UIActivityViewController
struct ShareCardView: View {
    let variant: ShareCardVariant

    private let cardWidth: CGFloat = 390
    private let cardHeight: CGFloat = 520

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 13/255, green: 79/255, blue: 79/255),
                    Color(red: 8/255, green: 50/255, blue: 60/255),
                    Color(red: 5/255, green: 30/255, blue: 40/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                // Header with Modus branding
                headerSection
                    .padding(.top, Spacing.lg)

                Spacer()

                // Main content based on variant
                cardContent
                    .padding(.horizontal, Spacing.lg)

                Spacer()

                // Watermark footer
                watermarkFooter
                    .padding(.bottom, Spacing.md)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            // Modus logo area
            HStack(spacing: Spacing.xs) {
                Image(systemName: "bolt.circle.fill")
                    .font(.title2)
                    .foregroundColor(.modusCyanStatic)

                Text("MODUS")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .tracking(2)
            }

            Spacer()

            // Card type badge
            Text(cardTypeBadge)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.modusCyanStatic)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(
                    Capsule()
                        .fill(Color.modusCyanStatic.opacity(0.2))
                )
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var cardTypeBadge: String {
        switch variant {
        case .workout: return "WORKOUT"
        case .achievement: return "ACHIEVEMENT"
        case .streak: return "STREAK"
        case .progress: return "PROGRESS"
        }
    }

    // MARK: - Card Content Router

    @ViewBuilder
    private var cardContent: some View {
        switch variant {
        case let .workout(exerciseName, sets, reps, weight, isPR, date, duration, totalVolume, exerciseCount):
            workoutCard(
                exerciseName: exerciseName,
                sets: sets,
                reps: reps,
                weight: weight,
                isPR: isPR,
                date: date,
                duration: duration,
                totalVolume: totalVolume,
                exerciseCount: exerciseCount
            )
        case let .achievement(iconName, title, description, tier, unlockedAt):
            achievementCard(
                iconName: iconName,
                title: title,
                description: description,
                tier: tier,
                unlockedAt: unlockedAt
            )
        case let .streak(days, motivationalText):
            streakCard(days: days, motivationalText: motivationalText)
        case let .progress(before, after):
            progressCard(before: before, after: after)
        }
    }

    // MARK: - Workout Card

    private func workoutCard(
        exerciseName: String,
        sets: Int?,
        reps: Int?,
        weight: Double?,
        isPR: Bool,
        date: Date,
        duration: Int?,
        totalVolume: Double?,
        exerciseCount: Int
    ) -> some View {
        VStack(spacing: Spacing.lg) {
            // PR Badge (if applicable)
            if isPR {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("PERSONAL RECORD")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                        .tracking(1)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(
                    Capsule()
                        .fill(Color.yellow.opacity(0.15))
                )
            }

            // Exercise name
            Text(exerciseName)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Stats grid
            HStack(spacing: Spacing.lg) {
                if let sets = sets {
                    statBubble(value: "\(sets)", label: "Sets")
                }
                if let reps = reps {
                    statBubble(value: "\(reps)", label: "Reps")
                }
                if let weight = weight, weight > 0 {
                    statBubble(value: formatWeight(weight), label: "Weight")
                }
            }

            // Secondary stats
            HStack(spacing: Spacing.xl) {
                if let duration = duration {
                    secondaryStat(icon: "clock.fill", value: "\(duration) min")
                }
                secondaryStat(icon: "figure.strengthtraining.traditional", value: "\(exerciseCount) exercises")
                if let volume = totalVolume, volume > 0 {
                    secondaryStat(icon: "scalemass.fill", value: formatVolume(volume))
                }
            }

            // Date
            Text(formattedDate(date))
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
    }

    // MARK: - Achievement Card

    private func achievementCard(
        iconName: String,
        title: String,
        description: String,
        tier: String,
        unlockedAt: Date
    ) -> some View {
        VStack(spacing: Spacing.lg) {
            // Badge icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.modusCyanStatic.opacity(0.6), Color.modusCyanStatic.opacity(0.1)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: iconName)
                    .font(.system(size: 48))
                    .foregroundColor(.modusCyanStatic)
            }

            // Tier badge
            Text(tier.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(tierColor(tier))
                .tracking(2)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(
                    Capsule()
                        .fill(tierColor(tier).opacity(0.15))
                )

            // Title
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Description
            Text(description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(3)

            // Unlock date
            Text("Unlocked \(formattedDate(unlockedAt))")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
    }

    // MARK: - Streak Card

    private func streakCard(days: Int, motivationalText: String) -> some View {
        VStack(spacing: Spacing.lg) {
            // Flame icon
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.orange.opacity(0.5), Color.orange.opacity(0.0)],
                            center: .center,
                            startRadius: 15,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                Image(systemName: "flame.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange, .red],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            // Day count
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                Text("\(days)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("DAYS")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(2)
            }

            // Motivational text
            Text(motivationalText)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.md)
                .lineLimit(3)
        }
    }

    // MARK: - Progress Card

    private func progressCard(before: ProgressSnapshot, after: ProgressSnapshot) -> some View {
        VStack(spacing: Spacing.lg) {
            // Title
            Text("Progress")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            // Date range
            Text("\(formattedShortDate(before.date)) - \(formattedShortDate(after.date))")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))

            // Progress stats
            VStack(spacing: Spacing.sm) {
                if let beforeW = before.bodyWeight, let afterW = after.bodyWeight {
                    progressRow(label: "Body Weight", before: formatWeight(beforeW), after: formatWeight(afterW), diff: afterW - beforeW)
                }
                if let beforeB = before.benchPress, let afterB = after.benchPress {
                    progressRow(label: "Bench Press", before: formatWeight(beforeB), after: formatWeight(afterB), diff: afterB - beforeB)
                }
                if let beforeS = before.squat, let afterS = after.squat {
                    progressRow(label: "Squat", before: formatWeight(beforeS), after: formatWeight(afterS), diff: afterS - beforeS)
                }
                if let beforeD = before.deadlift, let afterD = after.deadlift {
                    progressRow(label: "Deadlift", before: formatWeight(beforeD), after: formatWeight(afterD), diff: afterD - beforeD)
                }
                if let beforeV = before.totalVolume, let afterV = after.totalVolume {
                    progressRow(label: "Weekly Volume", before: formatVolume(beforeV), after: formatVolume(afterV), diff: afterV - beforeV)
                }
                if let beforeS = before.longestStreak, let afterS = after.longestStreak {
                    progressRow(label: "Streak", before: "\(beforeS)d", after: "\(afterS)d", diff: Double(afterS - beforeS))
                }
            }
            .padding(Spacing.md)
            .background(Color.white.opacity(0.08))
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Watermark Footer

    private var watermarkFooter: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: "bolt.circle.fill")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.3))
            Text("Powered by Korza")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.3))
        }
    }

    // MARK: - Reusable Components

    private func statBubble(value: String, label: String) -> some View {
        VStack(spacing: Spacing.xxs) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
                .textCase(.uppercase)
        }
        .frame(minWidth: 70)
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.sm)
        .background(Color.white.opacity(0.08))
        .cornerRadius(CornerRadius.sm)
    }

    private func secondaryStat(icon: String, value: String) -> some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.modusCyanStatic)
            Text(value)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private func progressRow(label: String, before: String, after: String, diff: Double) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            Text(before)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))

            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundColor(.modusCyanStatic)

            Text(after)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            // Change indicator
            let sign = diff >= 0 ? "+" : ""
            Text("(\(sign)\(String(format: "%.0f", diff)))")
                .font(.caption2)
                .foregroundColor(diff >= 0 ? .green : .red)
        }
    }

    // MARK: - Helpers

    private func formatWeight(_ weight: Double) -> String {
        if weight == floor(weight) {
            return String(format: "%.0f", weight)
        }
        return String(format: "%.1f", weight)
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }

    private static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private func formattedDate(_ date: Date) -> String {
        Self.mediumDateFormatter.string(from: date)
    }

    private func formattedShortDate(_ date: Date) -> String {
        Self.shortDateFormatter.string(from: date)
    }

    private func tierColor(_ tier: String) -> Color {
        switch tier.lowercased() {
        case "bronze": return Color(red: 205/255, green: 127/255, blue: 50/255)
        case "silver": return Color.gray
        case "gold": return Color.yellow
        case "platinum": return Color.white
        case "diamond": return Color.modusCyanStatic
        default: return Color.modusCyanStatic
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ShareCardView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                ShareCardView(
                    variant: .workout(
                        exerciseName: "Bench Press",
                        sets: 4,
                        reps: 8,
                        weight: 225,
                        isPR: true,
                        date: Date(),
                        duration: 45,
                        totalVolume: 12500,
                        exerciseCount: 6
                    )
                )

                ShareCardView(
                    variant: .achievement(
                        iconName: "flame.fill",
                        title: "Week Warrior",
                        description: "Complete a 7-day workout streak",
                        tier: "Bronze",
                        unlockedAt: Date()
                    )
                )

                ShareCardView(
                    variant: .streak(
                        days: 30,
                        motivationalText: "A whole month of dedication. Unstoppable!"
                    )
                )

                ShareCardView(
                    variant: .progress(
                        before: ProgressSnapshot(
                            date: Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
                            bodyWeight: 185,
                            benchPress: 185,
                            squat: 225,
                            deadlift: 275,
                            totalVolume: 25000,
                            workoutsPerWeek: 3,
                            longestStreak: 7
                        ),
                        after: ProgressSnapshot(
                            date: Date(),
                            bodyWeight: 180,
                            benchPress: 225,
                            squat: 275,
                            deadlift: 315,
                            totalVolume: 35000,
                            workoutsPerWeek: 4.5,
                            longestStreak: 30
                        )
                    )
                )
            }
            .padding()
        }
        .background(Color.black)
    }
}
#endif
