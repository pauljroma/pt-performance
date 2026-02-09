//
//  NutritionProgressRing.swift
//  PTPerformance
//
//  ACP-1018: Visual upgrade - Circular progress rings for macro nutrients
//

import SwiftUI

// MARK: - Macro Progress Ring

/// A circular progress ring component for displaying macro nutrient progress
/// with animated fill and goal completion feedback
/// Respects @Environment(\.accessibilityReduceMotion) for accessibility
struct NutritionMacroRing: View {
    let progress: Double
    let macroName: String
    let color: Color
    let currentGrams: Double
    let targetGrams: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let animated: Bool

    @State private var animatedProgress: Double = 0
    @State private var showGoalAchieved: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        progress: Double,
        macroName: String,
        color: Color,
        currentGrams: Double,
        targetGrams: Double,
        size: CGFloat = 80,
        lineWidth: CGFloat = 8,
        animated: Bool = true
    ) {
        self.progress = progress
        self.macroName = macroName
        self.color = color
        self.currentGrams = currentGrams
        self.targetGrams = targetGrams
        self.size = size
        self.lineWidth = lineWidth
        self.animated = animated
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    color.opacity(colorScheme == .dark ? 0.15 : 0.1),
                    lineWidth: lineWidth
                )
                .frame(width: size, height: size)

            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: 0) {
                Text("\(Int(currentGrams))")
                    .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("g")
                    .font(.system(size: size * 0.12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            // Goal achieved glow effect (skip if reduce motion is enabled)
            if showGoalAchieved && !reduceMotion {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: lineWidth + 4)
                    .frame(width: size, height: size)
                    .blur(radius: 4)
                    .scaleEffect(1.1)
            }
        }
        .onAppear {
            if animated && !reduceMotion {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animatedProgress = min(progress, 1.0)
                }
                // Trigger goal achieved effect
                if progress >= 1.0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showGoalAchieved = true
                        }
                        HapticFeedback.success()
                    }
                }
            } else {
                // Instant update for reduce motion or non-animated
                animatedProgress = min(progress, 1.0)
                if progress >= 1.0 {
                    showGoalAchieved = true
                }
            }
        }
        .onChange(of: progress) { _, newValue in
            let oldProgress = animatedProgress

            if reduceMotion {
                // Instant update for reduce motion
                animatedProgress = min(newValue, 1.0)
                if newValue >= 1.0 && oldProgress < 1.0 {
                    showGoalAchieved = true
                    HapticFeedback.success()
                } else if newValue < 1.0 {
                    showGoalAchieved = false
                }
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    animatedProgress = min(newValue, 1.0)
                }
                // Trigger goal achieved when crossing 100%
                if newValue >= 1.0 && oldProgress < 1.0 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showGoalAchieved = true
                    }
                    HapticFeedback.success()
                } else if newValue < 1.0 {
                    showGoalAchieved = false
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(macroName): \(Int(currentGrams)) of \(Int(targetGrams)) grams, \(Int(progress * 100)) percent complete")
    }

    private var progressGradient: AngularGradient {
        let baseColor = progress >= 1.0 ? Color.green : color
        return AngularGradient(
            gradient: Gradient(colors: [
                baseColor.opacity(0.7),
                baseColor,
                baseColor.opacity(0.9)
            ]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360 * animatedProgress)
        )
    }
}

// MARK: - Triple Macro Rings View

/// Displays three macro progress rings (protein, carbs, fat) in a horizontal layout
/// Respects @Environment(\.accessibilityReduceMotion) for accessibility
struct TripleMacroRingsView: View {
    let proteinCurrent: Double
    let proteinTarget: Double
    let carbsCurrent: Double
    let carbsTarget: Double
    let fatCurrent: Double
    let fatTarget: Double

    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Spacing.lg) {
            macroRingColumn(
                name: "Protein",
                current: proteinCurrent,
                target: proteinTarget,
                color: .red,
                delay: 0
            )

            macroRingColumn(
                name: "Carbs",
                current: carbsCurrent,
                target: carbsTarget,
                color: .blue,
                delay: 0.1
            )

            macroRingColumn(
                name: "Fat",
                current: fatCurrent,
                target: fatTarget,
                color: .yellow,
                delay: 0.2
            )
        }
        .onAppear {
            if reduceMotion {
                isVisible = true
            } else {
                withAnimation(.easeOut(duration: AnimationDuration.standard)) {
                    isVisible = true
                }
            }
        }
    }

    private func macroRingColumn(name: String, current: Double, target: Double, color: Color, delay: Double) -> some View {
        let progress = target > 0 ? current / target : 0

        return VStack(spacing: Spacing.xs) {
            NutritionMacroRing(
                progress: progress,
                macroName: name,
                color: color,
                currentGrams: current,
                targetGrams: target,
                size: 70,
                lineWidth: 7
            )
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: isVisible)

            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text("\(Int(target))g goal")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Calorie Progress Ring

/// Large calorie progress ring with remaining calories display
/// Respects @Environment(\.accessibilityReduceMotion) for accessibility
struct CalorieProgressRing: View {
    let currentCalories: Int
    let targetCalories: Int
    let size: CGFloat

    @State private var animatedProgress: Double = 0
    @State private var showGoalAchieved: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: Double {
        guard targetCalories > 0 else { return 0 }
        return Double(currentCalories) / Double(targetCalories)
    }

    private var remainingCalories: Int {
        max(0, targetCalories - currentCalories)
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Color.blue.opacity(colorScheme == .dark ? 0.15 : 0.1),
                    lineWidth: 12
                )
                .frame(width: size, height: size)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: Spacing.xxs) {
                Text("\(currentCalories)")
                    .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("of \(targetCalories)")
                    .font(.system(size: size * 0.08))
                    .foregroundColor(.secondary)

                Text("\(remainingCalories) left")
                    .font(.system(size: size * 0.07, weight: .medium))
                    .foregroundColor(progress >= 1.0 ? .green : .blue)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill((progress >= 1.0 ? Color.green : Color.blue).opacity(0.15))
                    )
            }

            // Goal achieved pulse effect (skip if reduce motion is enabled)
            if showGoalAchieved && !reduceMotion {
                Circle()
                    .stroke(Color.green.opacity(0.4), lineWidth: 16)
                    .frame(width: size, height: size)
                    .blur(radius: 6)
                    .scaleEffect(1.15)
            }
        }
        .onAppear {
            if reduceMotion {
                animatedProgress = min(progress, 1.0)
                if progress >= 1.0 {
                    showGoalAchieved = true
                }
            } else {
                withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                    animatedProgress = min(progress, 1.0)
                }
                if progress >= 1.0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showGoalAchieved = true
                        }
                        HapticFeedback.success()
                    }
                }
            }
        }
        .onChange(of: progress) { _, newValue in
            if reduceMotion {
                animatedProgress = min(newValue, 1.0)
                if newValue >= 1.0 && !showGoalAchieved {
                    showGoalAchieved = true
                    HapticFeedback.success()
                }
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    animatedProgress = min(newValue, 1.0)
                }
                if newValue >= 1.0 && !showGoalAchieved {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showGoalAchieved = true
                    }
                    HapticFeedback.success()
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Calories: \(currentCalories) of \(targetCalories), \(remainingCalories) remaining")
    }

    private var progressGradient: AngularGradient {
        let baseColor = progress >= 1.0 ? Color.green : Color.blue
        return AngularGradient(
            gradient: Gradient(colors: [
                baseColor.opacity(0.6),
                baseColor,
                baseColor.opacity(0.85)
            ]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360 * animatedProgress)
        )
    }
}

// MARK: - Goal Achievement Celebration

/// Visual celebration overlay when nutrition goals are met
struct NutritionGoalCelebration: View {
    let goalType: String
    @Binding var isShowing: Bool

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var confettiOpacity: Double = 1

    var body: some View {
        ZStack {
            // Confetti particles
            ForEach(0..<12, id: \.self) { index in
                NutritionConfettiPiece(
                    index: index,
                    opacity: confettiOpacity
                )
            }

            // Success badge
            VStack(spacing: Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)

                Text("\(goalType) Goal Met!")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color(.systemBackground))
                    .adaptiveShadow(Shadow.prominent)
            )
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }

            // Auto dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                    confettiOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isShowing = false
                }
            }
        }
    }
}

/// Individual confetti piece for celebration animation
private struct NutritionConfettiPiece: View {
    let index: Int
    let opacity: Double

    @State private var yOffset: CGFloat = 0
    @State private var rotation: Double = 0

    private let colors: [Color] = [.green, .blue, .orange, .purple, .yellow]

    var body: some View {
        let angle = Double(index) * (360.0 / 12.0)
        let radius: CGFloat = 80
        let xPos = cos(angle * .pi / 180) * radius
        let yPos = sin(angle * .pi / 180) * radius

        Circle()
            .fill(colors[index % colors.count])
            .frame(width: 8, height: 8)
            .offset(x: xPos, y: yPos + yOffset)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    yOffset = 60
                    rotation = Double.random(in: 180...360)
                }
            }
    }
}

// MARK: - Preview

#if DEBUG
struct NutritionProgressRing_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Single macro ring
            NutritionMacroRing(
                progress: 0.75,
                macroName: "Protein",
                color: .red,
                currentGrams: 120,
                targetGrams: 160,
                size: 100,
                lineWidth: 10
            )

            // Triple macro rings
            TripleMacroRingsView(
                proteinCurrent: 120,
                proteinTarget: 160,
                carbsCurrent: 180,
                carbsTarget: 250,
                fatCurrent: 50,
                fatTarget: 70
            )
            .padding()

            // Calorie ring
            CalorieProgressRing(
                currentCalories: 1650,
                targetCalories: 2200,
                size: 150
            )
        }
        .padding()
    }
}
#endif
