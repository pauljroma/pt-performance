//
//  GoalProgressCard.swift
//  PTPerformance
//
//  Reusable card component showing progress toward a body composition goal
//

import SwiftUI

/// A card that displays progress toward a specific body composition goal
struct BodyCompGoalProgressCard: View {
    let title: String
    let current: Double?
    let target: Double?
    let starting: Double?
    let unit: String
    let color: Color
    var icon: String = "target"

    // Convenience init with 'start' parameter for backwards compatibility
    init(title: String, current: Double?, target: Double?, start: Double? = nil, starting: Double? = nil, unit: String, color: Color, icon: String = "target") {
        self.title = title
        self.current = current
        self.target = target
        self.starting = starting ?? start
        self.unit = unit
        self.color = color
        self.icon = icon
    }

    // MARK: - Computed Properties

    /// Calculate progress from start to target (0.0 to 1.0+)
    private var progress: Double {
        guard let current = current,
              let target = target else { return 0 }

        let startValue = starting ?? current

        // Avoid division by zero
        guard target != startValue else { return current == target ? 1.0 : 0.0 }

        let totalChange = target - startValue
        let currentChange = current - startValue

        return currentChange / totalChange
    }

    /// Clamped progress for display (0.0 to 1.0)
    private var displayProgress: Double {
        min(1.0, max(0, progress))
    }

    /// Progress percentage as an integer
    private var progressPercent: Int {
        Int(displayProgress * 100)
    }

    /// Whether the goal has been achieved
    private var isAchieved: Bool {
        progress >= 1.0
    }

    /// The change needed to reach the goal
    private var remainingChange: Double? {
        guard let current = current, let target = target else { return nil }
        return target - current
    }

    /// Direction indicator (loss vs gain)
    private var isGainGoal: Bool {
        guard let target = target else { return true }
        let startValue = starting ?? (current ?? target)
        return target > startValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and icon
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if isAchieved {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }

            HStack(spacing: 16) {
                // Current value
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let current = current {
                        Text("\(current, specifier: "%.1f")")
                            .font(.title2)
                            .fontWeight(.bold)
                        + Text(" \(unit)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("--")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Progress ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(color.opacity(0.2), lineWidth: 8)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: displayProgress)
                        .stroke(
                            isAchieved ? Color.green : color,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: displayProgress)

                    // Percentage text
                    VStack(spacing: 0) {
                        Text("\(progressPercent)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 64, height: 64)

                Spacer()

                // Target value
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Target")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let target = target {
                        Text("\(target, specifier: "%.1f")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(color)
                        + Text(" \(unit)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("--")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(color.opacity(0.2))
                        .frame(height: 6)

                    // Progress fill
                    Capsule()
                        .fill(isAchieved ? Color.green : color)
                        .frame(width: geometry.size.width * displayProgress, height: 6)
                        .animation(.easeInOut(duration: 0.5), value: displayProgress)
                }
            }
            .frame(height: 6)

            // Remaining change indicator
            if let remaining = remainingChange, !isAchieved {
                HStack {
                    Image(systemName: isGainGoal ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                        .foregroundColor(color)

                    Text("\(abs(remaining), specifier: "%.1f") \(unit) to go")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if let startVal = starting {
                        let totalChange = abs((target ?? startVal) - startVal)
                        let changeText = isGainGoal ? "gain" : "loss"
                        Text("\(totalChange, specifier: "%.1f") \(unit) \(changeText) goal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else if isAchieved {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)

                    Text("Goal achieved!")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Compact Version

/// A more compact version of the goal progress card for smaller spaces
struct CompactGoalProgressCard: View {
    let title: String
    let current: Double?
    let target: Double?
    let unit: String
    let color: Color

    private var progress: Double {
        guard let current = current, let target = target, target != 0 else { return 0 }
        return min(1.0, max(0, current / target))
    }

    var body: some View {
        HStack(spacing: 12) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    if let current = current {
                        Text("\(current, specifier: "%.1f")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    } else {
                        Text("--")
                            .font(.subheadline)
                    }

                    Text("/")
                        .foregroundColor(.secondary)

                    if let target = target {
                        Text("\(target, specifier: "%.1f") \(unit)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Text("\(Int(progress * 100))%")
                .font(.headline)
                .foregroundColor(color)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Preview

#if DEBUG
struct BodyCompGoalProgressCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Weight loss goal - in progress
                BodyCompGoalProgressCard(
                    title: "Weight Goal",
                    current: 185.0,
                    target: 175.0,
                    start: 195.0,
                    unit: "lbs",
                    color: .modusCyan,
                    icon: "scalemass"
                )

                // Body fat goal - achieved
                BodyCompGoalProgressCard(
                    title: "Body Fat Goal",
                    current: 15.0,
                    target: 15.0,
                    start: 20.0,
                    unit: "%",
                    color: .orange,
                    icon: "percent"
                )

                // Muscle mass gain goal
                BodyCompGoalProgressCard(
                    title: "Muscle Mass Goal",
                    current: 155.0,
                    target: 165.0,
                    start: 150.0,
                    unit: "lbs",
                    color: .green,
                    icon: "figure.strengthtraining.traditional"
                )

                // No current data
                BodyCompGoalProgressCard(
                    title: "Weight Goal",
                    current: nil,
                    target: 175.0,
                    start: nil,
                    unit: "lbs",
                    color: .blue
                )

                Divider()

                Text("Compact Cards")
                    .font(.headline)

                CompactGoalProgressCard(
                    title: "Weight",
                    current: 185.0,
                    target: 175.0,
                    unit: "lbs",
                    color: .blue
                )

                CompactGoalProgressCard(
                    title: "Body Fat",
                    current: 18.0,
                    target: 15.0,
                    unit: "%",
                    color: .orange
                )
            }
            .padding()
        }
    }
}
#endif
