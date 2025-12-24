import Foundation

/// Summary metrics for a training session
struct QuickMetrics: Codable, Hashable {
    let totalSets: Int
    let completedSets: Int
    let totalVolume: Double? // Total load × reps
    let averageRPE: Double?
    let duration: TimeInterval? // In seconds
    let painFlags: Int
    let caloriesBurned: Int?

    init(totalSets: Int = 0, completedSets: Int = 0, totalVolume: Double? = nil, averageRPE: Double? = nil, duration: TimeInterval? = nil, painFlags: Int = 0, caloriesBurned: Int? = nil) {
        self.totalSets = totalSets
        self.completedSets = completedSets
        self.totalVolume = totalVolume
        self.averageRPE = averageRPE
        self.duration = duration
        self.painFlags = painFlags
        self.caloriesBurned = caloriesBurned
    }

    /// Calculate metrics from blocks
    static func from(blocks: [Block]) -> QuickMetrics {
        var totalSets = 0
        var completedSets = 0
        var totalVolume: Double = 0
        var rpeValues: [Int] = []
        var painFlags = 0

        for block in blocks {
            totalSets += block.totalSets
            completedSets += block.completedSets

            for item in block.items {
                // Calculate volume
                if let volume = item.totalVolume {
                    totalVolume += volume
                }

                // Collect RPE values
                for set in item.completedSets {
                    if let rpe = set.actualRPE {
                        rpeValues.append(rpe)
                    }
                    if set.hasPainFlag {
                        painFlags += 1
                    }
                }
            }
        }

        let averageRPE: Double? = rpeValues.isEmpty ? nil : Double(rpeValues.reduce(0, +)) / Double(rpeValues.count)
        let volumeValue: Double? = totalVolume > 0 ? totalVolume : nil

        return QuickMetrics(
            totalSets: totalSets,
            completedSets: completedSets,
            totalVolume: volumeValue,
            averageRPE: averageRPE,
            duration: nil, // Calculated separately
            painFlags: painFlags,
            caloriesBurned: nil // Calculated separately
        )
    }

    /// Progress percentage (0.0 to 1.0)
    var progress: Double {
        guard totalSets > 0 else { return 0.0 }
        return Double(completedSets) / Double(totalSets)
    }

    /// Format duration for display
    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Format volume for display
    var formattedVolume: String? {
        guard let volume = totalVolume else { return nil }
        if volume >= 1000 {
            return String(format: "%.1fk lbs", volume / 1000)
        }
        return String(format: "%.0f lbs", volume)
    }

    /// Format average RPE for display
    var formattedAverageRPE: String? {
        guard let rpe = averageRPE else { return nil }
        return String(format: "%.1f", rpe)
    }

    /// Check if session is complete
    var isComplete: Bool {
        return totalSets > 0 && completedSets == totalSets
    }

    /// Check if there are any pain flags
    var hasPainFlags: Bool {
        return painFlags > 0
    }
}

// MARK: - Metric Display Item

/// Individual metric for display in UI
struct MetricDisplayItem: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let icon: String
    let color: String
    let isWarning: Bool

    static func from(metrics: QuickMetrics) -> [MetricDisplayItem] {
        var items: [MetricDisplayItem] = []

        // Sets progress
        items.append(MetricDisplayItem(
            label: "Sets",
            value: "\(metrics.completedSets)/\(metrics.totalSets)",
            icon: "checkmark.circle.fill",
            color: metrics.isComplete ? "green" : "blue",
            isWarning: false
        ))

        // Volume
        if let formattedVolume = metrics.formattedVolume {
            items.append(MetricDisplayItem(
                label: "Volume",
                value: formattedVolume,
                icon: "scalemass.fill",
                color: "purple",
                isWarning: false
            ))
        }

        // Average RPE
        if let formattedRPE = metrics.formattedAverageRPE {
            let rpeColor = (metrics.averageRPE ?? 0) > 8 ? "red" : "orange"
            items.append(MetricDisplayItem(
                label: "Avg RPE",
                value: formattedRPE,
                icon: "bolt.fill",
                color: rpeColor,
                isWarning: (metrics.averageRPE ?? 0) > 8
            ))
        }

        // Duration
        if let formattedDuration = metrics.formattedDuration {
            items.append(MetricDisplayItem(
                label: "Time",
                value: formattedDuration,
                icon: "clock.fill",
                color: "gray",
                isWarning: false
            ))
        }

        // Pain flags
        if metrics.hasPainFlags {
            items.append(MetricDisplayItem(
                label: "Pain Flags",
                value: "\(metrics.painFlags)",
                icon: "exclamationmark.triangle.fill",
                color: "red",
                isWarning: true
            ))
        }

        return items
    }
}
