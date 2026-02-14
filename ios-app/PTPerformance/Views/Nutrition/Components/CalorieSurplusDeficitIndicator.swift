//
//  CalorieSurplusDeficitIndicator.swift
//  PTPerformance
//
//  ACP-1018: Calorie surplus/deficit indicator with color coding
//

import SwiftUI

// MARK: - Calorie Surplus/Deficit Indicator

/// Visual indicator showing whether user is in calorie surplus or deficit
struct CalorieSurplusDeficitIndicator: View {
    let currentCalories: Int
    let targetCalories: Int

    @State private var isVisible = false
    @Environment(\.colorScheme) private var colorScheme

    private var difference: Int {
        currentCalories - targetCalories
    }

    private var percentageDifference: Double {
        guard targetCalories > 0 else { return 0 }
        return Double(difference) / Double(targetCalories) * 100
    }

    private var status: Status {
        let absPercentage = abs(percentageDifference)

        if absPercentage < 5 {
            return .onTarget
        } else if difference > 0 {
            if absPercentage < 15 {
                return .mildSurplus
            } else {
                return .surplus
            }
        } else {
            if absPercentage < 15 {
                return .mildDeficit
            } else {
                return .deficit
            }
        }
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Text("Calorie Balance")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                statusBadge
            }

            // Visual bar indicator
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(Color(.tertiarySystemBackground))
                        .frame(height: 8)

                    // Target marker
                    Rectangle()
                        .fill(Color.green.opacity(0.8))
                        .frame(width: 3, height: 16)
                        .offset(x: geometry.size.width * 0.5 - 1.5)

                    // Progress bar
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(status.color)
                        .frame(
                            width: isVisible ? barWidth(totalWidth: geometry.size.width) : 0,
                            height: 8
                        )
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: isVisible)
                }
            }
            .frame(height: 16)

            // Details row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("\(currentCalories)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text("Goal")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("\(targetCalories)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(difference >= 0 ? "Surplus" : "Deficit")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("\(difference >= 0 ? "+" : "")\(difference)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(status.color)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
        .onAppear {
            withAnimation(.easeOut(duration: AnimationDuration.standard).delay(0.2)) {
                isVisible = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Calorie balance: \(currentCalories) of \(targetCalories) calories, \(abs(difference)) calorie \(difference >= 0 ? "surplus" : "deficit")")
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption2)

            Text(status.text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(status.color)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(
            Capsule()
                .fill(status.color.opacity(colorScheme == .dark ? 0.25 : 0.15))
        )
    }

    private func barWidth(totalWidth: CGFloat) -> CGFloat {
        let progress = Double(currentCalories) / Double(targetCalories)
        let clampedProgress = min(max(progress, 0), 2.0) // Cap at 200%
        return totalWidth * (clampedProgress / 2.0) // Map 0-200% to 0-100% of width
    }

    // MARK: - Status Enum

    enum Status {
        case deficit
        case mildDeficit
        case onTarget
        case mildSurplus
        case surplus

        var color: Color {
            switch self {
            case .deficit:
                return .red
            case .mildDeficit:
                return .orange
            case .onTarget:
                return .green
            case .mildSurplus:
                return .blue
            case .surplus:
                return .purple
            }
        }

        var icon: String {
            switch self {
            case .deficit:
                return "arrow.down.circle.fill"
            case .mildDeficit:
                return "arrow.down.circle"
            case .onTarget:
                return "checkmark.circle.fill"
            case .mildSurplus:
                return "arrow.up.circle"
            case .surplus:
                return "arrow.up.circle.fill"
            }
        }

        var text: String {
            switch self {
            case .deficit:
                return "High Deficit"
            case .mildDeficit:
                return "Mild Deficit"
            case .onTarget:
                return "On Target"
            case .mildSurplus:
                return "Mild Surplus"
            case .surplus:
                return "High Surplus"
            }
        }
    }
}

// MARK: - Compact Calorie Balance Badge

/// Compact version for use in cards
struct CompactCalorieBalanceBadge: View {
    let currentCalories: Int
    let targetCalories: Int

    @Environment(\.colorScheme) private var colorScheme

    private var difference: Int {
        currentCalories - targetCalories
    }

    private var percentageDifference: Double {
        guard targetCalories > 0 else { return 0 }
        return Double(difference) / Double(targetCalories) * 100
    }

    private var color: Color {
        let absPercentage = abs(percentageDifference)

        if absPercentage < 5 {
            return .green
        } else if absPercentage < 15 {
            return difference > 0 ? .modusCyan : .orange
        } else {
            return difference > 0 ? .purple : .red
        }
    }

    private var icon: String {
        if abs(percentageDifference) < 5 {
            return "checkmark.circle.fill"
        } else {
            return difference > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)

            Text("\(difference >= 0 ? "+" : "")\(difference)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(
            Capsule()
                .fill(color.opacity(colorScheme == .dark ? 0.25 : 0.15))
        )
    }
}

// MARK: - Preview

#if DEBUG
struct CalorieSurplusDeficitIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.lg) {
            // On target
            CalorieSurplusDeficitIndicator(
                currentCalories: 2150,
                targetCalories: 2200
            )

            // Mild deficit
            CalorieSurplusDeficitIndicator(
                currentCalories: 1950,
                targetCalories: 2200
            )

            // Deficit
            CalorieSurplusDeficitIndicator(
                currentCalories: 1600,
                targetCalories: 2200
            )

            // Mild surplus
            CalorieSurplusDeficitIndicator(
                currentCalories: 2450,
                targetCalories: 2200
            )

            // Surplus
            CalorieSurplusDeficitIndicator(
                currentCalories: 2800,
                targetCalories: 2200
            )

            // Compact badges
            HStack(spacing: Spacing.sm) {
                CompactCalorieBalanceBadge(currentCalories: 2150, targetCalories: 2200)
                CompactCalorieBalanceBadge(currentCalories: 1950, targetCalories: 2200)
                CompactCalorieBalanceBadge(currentCalories: 2450, targetCalories: 2200)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
