//
//  PRCelebrationView.swift
//  PTPerformance
//
//  Gamification Polish - Milestone Celebrations & Achievements
//  Personal record celebration animation
//

import SwiftUI

// MARK: - PR Celebration View

/// Full-screen celebration for setting a personal record
struct PRCelebrationView: View {
    let data: PRCelebrationData
    let onDismiss: () -> Void
    var onShare: (() -> Void)?

    @State private var showContent = false
    @State private var trophyScale: CGFloat = 0.1
    @State private var trophyRotation: Double = -20
    @State private var weightScale: CGFloat = 0.5
    @State private var weightOffset: CGFloat = 30
    @State private var textOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0
    @State private var showBurst = false
    @State private var burstScale: CGFloat = 0.5

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            // Star burst effect
            if showBurst {
                StarBurstView()
                    .scaleEffect(burstScale)
                    .opacity(showContent ? 0.6 : 0)
            }

            // Content
            VStack(spacing: Spacing.xl) {
                Spacer()

                // Header
                Text(data.type.title)
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [data.type.color, data.type.color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(textOpacity)

                // Trophy/Icon with glow
                ZStack {
                    // Glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [data.type.color.opacity(0.5), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .opacity(showContent ? 1 : 0)

                    // Icon
                    Image(systemName: data.type.iconName)
                        .font(.system(size: 100))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .yellow.opacity(0.5), radius: 20)
                        .scaleEffect(trophyScale)
                        .rotationEffect(.degrees(trophyRotation))
                }

                // Exercise name
                Text(data.exerciseName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(textOpacity)

                // Weight display
                VStack(spacing: Spacing.xs) {
                    Text(data.formattedWeight)
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, data.type.color],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: data.type.color.opacity(0.5), radius: 10)
                        .scaleEffect(weightScale)
                        .offset(y: weightOffset)

                    // Improvement indicator
                    if let improvement = data.formattedImprovement {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.green)
                            Text(improvement)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        .font(.title3)
                        .opacity(textOpacity)
                    }

                    // Previous weight
                    if let previous = data.previousWeight {
                        Text("Previous: \(String(format: "%.0f", previous)) \(data.unit)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                            .opacity(textOpacity)
                    }
                }

                // Subtitle
                Text(data.type.subtitle)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
                    .opacity(textOpacity)

                Spacer()

                // Buttons
                VStack(spacing: Spacing.md) {
                    if onShare != nil {
                        Button(action: {
                            HapticFeedback.light()
                            onShare?()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share PR")
                            }
                            .font(.headline)
                            .foregroundColor(data.type.color)
                            .padding(.horizontal, Spacing.xl)
                            .padding(.vertical, Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .stroke(data.type.color, lineWidth: 2)
                            )
                        }
                    }

                    Button(action: {
                        HapticFeedback.light()
                        onDismiss()
                    }) {
                        Text("Keep Lifting!")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal, Spacing.xxl)
                            .padding(.vertical, Spacing.md)
                            .background(
                                LinearGradient(
                                    colors: [data.type.color, data.type.color.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(CornerRadius.lg)
                            .shadow(color: data.type.color.opacity(0.5), radius: 10)
                    }
                }
                .opacity(buttonsOpacity)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .onAppear {
            animateIn()
            HapticFeedback.success()
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            Color.black

            LinearGradient(
                colors: [
                    data.type.color.opacity(0.4),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Animation

    private func animateIn() {
        // Star burst
        withAnimation(.easeOut(duration: 0.3)) {
            showBurst = true
            showContent = true
        }

        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
            burstScale = 1.0
        }

        // Trophy animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.15)) {
            trophyScale = 1.0
            trophyRotation = 0
        }

        // Weight animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3)) {
            weightScale = 1.0
            weightOffset = 0
        }

        // Text fade in
        withAnimation(.easeIn(duration: 0.4).delay(0.4)) {
            textOpacity = 1.0
        }

        // Buttons
        withAnimation(.easeIn(duration: 0.3).delay(0.6)) {
            buttonsOpacity = 1.0
        }

        // Haptic sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            HapticFeedback.heavy()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            HapticFeedback.heavy()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            HapticFeedback.medium()
        }
    }
}

// MARK: - Star Burst View

/// Animated star burst effect
struct StarBurstView: View {
    let rayCount: Int = 12
    @State private var rotation: Double = 0

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                ForEach(0..<rayCount, id: \.self) { index in
                    RayView(angle: Double(index) * (360.0 / Double(rayCount)))
                        .position(center)
                }
            }
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(
                    .linear(duration: 20)
                    .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
        }
    }
}

struct RayView: View {
    let angle: Double

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.yellow.opacity(0.4), Color.clear],
                    startPoint: .center,
                    endPoint: .bottom
                )
            )
            .frame(width: 3, height: 300)
            .offset(y: -150)
            .rotationEffect(.degrees(angle))
    }
}

// MARK: - Compact PR Badge

/// Compact PR indicator for inline display
struct PRBadgeView: View {
    let exerciseName: String
    let weight: Double
    let unit: String
    var isNew: Bool = true

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Trophy icon
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: "trophy.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xxs) {
                    Text(exerciseName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if isNew {
                        Text("NEW")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.xxs)
                            .padding(.vertical, 1)
                            .background(Color.green)
                            .cornerRadius(CornerRadius.xs)
                    }
                }

                Text("\(String(format: "%.0f", weight)) \(unit)")
                    .font(.headline)
                    .foregroundColor(.yellow)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - PR History Row

/// Row for PR history display
struct PRHistoryRow: View {
    let exerciseName: String
    let currentPR: Double
    let previousPR: Double?
    let date: Date
    let unit: String

    var improvement: Double? {
        guard let prev = previousPR else { return nil }
        return currentPR - prev
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Exercise info
            VStack(alignment: .leading, spacing: 4) {
                Text(exerciseName)
                    .font(.headline)

                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // PR value with improvement
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(String(format: "%.0f", currentPR)) \(unit)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)

                if let improvement = improvement {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up")
                            .font(.caption2)
                        Text("+\(String(format: "%.0f", improvement))")
                            .font(.caption)
                    }
                    .foregroundColor(.green)
                }
            }

            Image(systemName: "trophy.fill")
                .foregroundColor(.yellow)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Preview

#if DEBUG
struct PRCelebrationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PRCelebrationView(
                data: PRCelebrationData(
                    exerciseName: "Bench Press",
                    newWeight: 225,
                    previousWeight: 215,
                    improvement: 10,
                    unit: "lbs",
                    type: .newPR
                ),
                onDismiss: {},
                onShare: {}
            )
            .previewDisplayName("New PR")

            PRCelebrationView(
                data: PRCelebrationData(
                    exerciseName: "Squat",
                    newWeight: 315,
                    previousWeight: nil,
                    improvement: nil,
                    unit: "lbs",
                    type: .firstPR
                ),
                onDismiss: {}
            )
            .previewDisplayName("First PR")

            PRCelebrationView(
                data: PRCelebrationData(
                    exerciseName: "Deadlift",
                    newWeight: 405,
                    previousWeight: 365,
                    improvement: 40,
                    unit: "lbs",
                    type: .milestonePR
                ),
                onDismiss: {}
            )
            .previewDisplayName("Milestone PR")

            PRBadgeView(
                exerciseName: "Bench Press",
                weight: 225,
                unit: "lbs"
            )
            .padding()
            .previewDisplayName("PR Badge")

            PRHistoryRow(
                exerciseName: "Squat",
                currentPR: 315,
                previousPR: 295,
                date: Date(),
                unit: "lbs"
            )
            .padding()
            .previewDisplayName("PR History Row")
        }
    }
}
#endif
