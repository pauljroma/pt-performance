import SwiftUI

/// Large circular fasting timer with progress indicator and benefits timeline (ACP-1002)
struct FastingTimerView: View {
    let isActive: Bool
    let elapsedSeconds: TimeInterval
    let targetSeconds: TimeInterval
    let currentPhase: FastingPhase

    @State private var animateProgress = false

    private var progress: Double {
        guard targetSeconds > 0 else { return 0 }
        return min(elapsedSeconds / targetSeconds, 1.0)
    }

    private var elapsedHours: Double {
        elapsedSeconds / 3600
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Main Timer Circle
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 16)
                    .frame(width: 220, height: 220)

                // Progress circle
                Circle()
                    .trim(from: 0, to: animateProgress ? progress : 0)
                    .stroke(
                        progressGradient,
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: animateProgress)

                // Glow effect when active
                if isActive {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            progressGradient,
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                        .blur(radius: 8)
                        .opacity(0.5)
                }

                // Inner content
                VStack(spacing: Spacing.xs) {
                    // Phase Icon
                    Image(systemName: currentPhase.icon)
                        .font(.system(size: 28))
                        .foregroundColor(currentPhase.timerColor)

                    // Time Display
                    Text(formatTime(elapsedSeconds))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .monospacedDigit()

                    // Phase Label
                    Text(currentPhase.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(currentPhase.timerColor)

                    // Progress Percentage
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Fasting timer: \(formatTime(elapsedSeconds)) elapsed, \(currentPhase.displayName) phase, \(Int(progress * 100)) percent complete")

            // Benefits Timeline
            if isActive {
                benefitsTimeline
            }
        }
        .onAppear {
            animateProgress = true
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                animateProgress = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animateProgress = true
                }
            }
        }
    }

    // MARK: - Progress Gradient

    private var progressGradient: LinearGradient {
        currentPhase.timerGradient
    }

    // MARK: - Benefits Timeline

    private var benefitsTimeline: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Fasting Benefits Timeline")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            VStack(spacing: 0) {
                ForEach(FastingBenefit.allBenefits, id: \.hours) { benefit in
                    BenefitRow(
                        benefit: benefit,
                        isReached: elapsedHours >= Double(benefit.hours),
                        isCurrent: isCurrentBenefit(benefit)
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private func isCurrentBenefit(_ benefit: FastingBenefit) -> Bool {
        let allBenefits = FastingBenefit.allBenefits
        guard let index = allBenefits.firstIndex(where: { $0.hours == benefit.hours }) else {
            return false
        }

        let nextIndex = index + 1
        if nextIndex < allBenefits.count {
            return elapsedHours >= Double(benefit.hours) && elapsedHours < Double(allBenefits[nextIndex].hours)
        } else {
            return elapsedHours >= Double(benefit.hours)
        }
    }

    // MARK: - Time Formatting

    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

// MARK: - Fasting Phase Extension for Timer View

/// Extension to provide timer-specific display properties for FastingPhase
/// Uses the canonical FastingPhase from FastingModels.swift
extension FastingPhase {
    /// Color for the timer progress gradient
    var timerColor: Color {
        switch self {
        case .fed: return .orange
        case .earlyFast: return .modusCyan
        case .fatBurning: return .orange
        case .ketosis: return .purple
        case .deepKetosis: return .blue
        case .autophagy: return .purple
        }
    }

    /// Gradient for the circular timer progress
    var timerGradient: LinearGradient {
        switch self {
        case .fed:
            return LinearGradient(
                colors: [.modusCyan, .modusTealAccent],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .earlyFast:
            return LinearGradient(
                colors: [.modusTealAccent, .green],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .fatBurning:
            return LinearGradient(
                colors: [.orange, .yellow],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .ketosis:
            return LinearGradient(
                colors: [.purple, .pink],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .deepKetosis:
            return LinearGradient(
                colors: [.modusCyan, .purple],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .autophagy:
            return LinearGradient(
                colors: [.purple, .modusCyan],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

// MARK: - Fasting Benefit

struct FastingBenefit {
    let hours: Int
    let title: String
    let description: String
    let icon: String
    let color: Color

    static let allBenefits: [FastingBenefit] = [
        FastingBenefit(
            hours: 12,
            title: "Fat Burning Begins",
            description: "Glycogen depleted, body switches to fat for fuel",
            icon: "flame.fill",
            color: .orange
        ),
        FastingBenefit(
            hours: 16,
            title: "Autophagy Begins",
            description: "Cellular cleanup and recycling processes activate",
            icon: "arrow.triangle.2.circlepath",
            color: .purple
        ),
        FastingBenefit(
            hours: 18,
            title: "Growth Hormone Increase",
            description: "HGH levels rise, supporting muscle preservation",
            icon: "arrow.up.circle.fill",
            color: .blue
        ),
        FastingBenefit(
            hours: 24,
            title: "Deep Autophagy",
            description: "Enhanced cellular repair and regeneration",
            icon: "sparkles",
            color: .purple
        )
    ]
}

// MARK: - Benefit Row

private struct BenefitRow: View {
    let benefit: FastingBenefit
    let isReached: Bool
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Timeline indicator
            VStack(spacing: 0) {
                Circle()
                    .fill(isReached ? benefit.color : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(isCurrent ? benefit.color : Color.clear, lineWidth: 2)
                            .scaleEffect(1.5)
                    )

                Rectangle()
                    .fill(isReached ? benefit.color.opacity(0.3) : Color.gray.opacity(0.2))
                    .frame(width: 2, height: 40)
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: benefit.icon)
                        .foregroundColor(isReached ? benefit.color : .gray)
                        .font(.caption)

                    Text("\(benefit.hours)h")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(isReached ? benefit.color : .gray)

                    Text(benefit.title)
                        .font(.subheadline)
                        .fontWeight(isCurrent ? .semibold : .regular)
                        .foregroundColor(isReached ? .primary : .secondary)
                }

                Text(benefit.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Checkmark for reached benefits
            if isReached {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(benefit.color)
            }
        }
        .padding(.vertical, Spacing.xs)
        .opacity(isReached ? 1.0 : 0.6)
    }
}

// MARK: - Standalone Timer View (for widget or compact display)

struct CompactFastingTimerView: View {
    let elapsedSeconds: TimeInterval
    let targetSeconds: TimeInterval
    let isActive: Bool

    private var progress: Double {
        guard targetSeconds > 0 else { return 0 }
        return min(elapsedSeconds / targetSeconds, 1.0)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.modusCyan, .modusTealAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text(formatCompactTime(elapsedSeconds))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text("of \(Int(targetSeconds / 3600))h")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 80, height: 80)
    }

    private func formatCompactTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return String(format: "%d:%02d", hours, minutes)
    }
}

// MARK: - Preview

#if DEBUG
struct FastingTimerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            FastingTimerView(
                isActive: true,
                elapsedSeconds: 14 * 3600 + 30 * 60,
                targetSeconds: 16 * 3600,
                currentPhase: FastingPhase.fatBurning
            )

            CompactFastingTimerView(
                elapsedSeconds: 14 * 3600,
                targetSeconds: 16 * 3600,
                isActive: true
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
