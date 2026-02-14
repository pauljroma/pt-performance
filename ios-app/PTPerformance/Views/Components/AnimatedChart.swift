//
//  AnimatedChart.swift
//  PTPerformance
//
//  Chart line drawing animations with accessibility support
//  Provides animated drawing effects for charts and progress rings
//

import SwiftUI

// MARK: - Animated Line Modifier

/// A view modifier that progressively draws a line from start to end
/// Respects reduce motion accessibility settings
struct AnimatedLineModifier: ViewModifier {
    /// The duration of the drawing animation in seconds
    var duration: Double = 0.8

    /// Optional delay before starting the animation
    var delay: Double = 0

    @State private var progress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .mask(
                GeometryReader { geometry in
                    Rectangle()
                        .frame(width: geometry.size.width * progress, height: geometry.size.height)
                        .animation(nil, value: progress)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            )
            .onAppear {
                if reduceMotion {
                    // Skip animation for reduce motion preference
                    progress = 1.0
                } else {
                    // Animate the line drawing
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(.easeOut(duration: duration)) {
                            progress = 1.0
                        }
                    }
                }
            }
    }
}

// MARK: - Animated Chart Line Shape

/// A shape that draws a line progressively using trim
/// Used for animating line chart paths
struct AnimatedChartLine: Shape {
    var progress: CGFloat
    let points: [CGPoint]

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard points.count >= 2 else { return Path() }

        var path = Path()
        path.move(to: points[0])

        for i in 1..<points.count {
            path.addLine(to: points[i])
        }

        return path.trimmedPath(from: 0, to: progress)
    }
}

// MARK: - Animated Progress Ring

/// A circular progress ring with spring animation fill
/// Respects reduce motion accessibility settings
struct AnimatedProgressRing: View {
    /// The progress value from 0.0 to 1.0
    let progress: Double

    /// The ring color
    var color: Color = .blue

    /// The size of the ring
    var size: CGFloat = 100

    /// The line width of the ring stroke
    var lineWidth: CGFloat = 10

    /// Whether to show the percentage label in the center
    var showLabel: Bool = true

    /// The font size for the percentage label
    var labelFontSize: CGFloat? = nil

    /// Optional label to show below the percentage
    var subtitle: String? = nil

    @State private var animatedProgress: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    color.opacity(colorScheme == .dark ? 0.15 : 0.1),
                    lineWidth: lineWidth
                )
                .frame(width: size, height: size)

            // Animated progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // Center label
            if showLabel {
                VStack(spacing: Spacing.xxs - 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(
                            size: labelFontSize ?? (size * 0.22),
                            weight: .bold,
                            design: .rounded
                        ))
                        .foregroundColor(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: size * 0.1))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear {
            if reduceMotion {
                animatedProgress = min(progress, 1.0)
            } else {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animatedProgress = min(progress, 1.0)
                }
            }
        }
        .onChange(of: progress) { _, newValue in
            if reduceMotion {
                animatedProgress = min(newValue, 1.0)
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    animatedProgress = min(newValue, 1.0)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress ring")
        .accessibilityValue("\(Int(progress * 100)) percent complete")
    }

    private var progressGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                color.opacity(0.7),
                color,
                color.opacity(0.9)
            ]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360 * animatedProgress)
        )
    }
}

// MARK: - Animated Trim Modifier

/// A view modifier for animating trim on shapes
/// Perfect for line charts using Chart's LineMark
struct AnimatedTrimModifier: ViewModifier {
    /// Duration of the trim animation
    var duration: Double = 0.8

    /// Delay before starting the animation
    var delay: Double = 0

    @State private var trimEnd: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .mask(
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Rectangle()
                            .frame(width: geometry.size.width * trimEnd)
                        Spacer(minLength: 0)
                    }
                }
            )
            .onAppear {
                if reduceMotion {
                    trimEnd = 1.0
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(.easeOut(duration: duration)) {
                            trimEnd = 1.0
                        }
                    }
                }
            }
    }
}

// MARK: - Chart Appear Animation Modifier

/// A view modifier for staggered appearance animation of chart elements
struct ChartAppearAnimationModifier: ViewModifier {
    /// The index of this element (for staggered animations)
    var index: Int = 0

    /// Base delay before animations start
    var baseDelay: Double = 0

    /// Stagger delay between each element
    var staggerDelay: Double = 0.05

    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .onAppear {
                if reduceMotion {
                    isVisible = true
                } else {
                    let delay = baseDelay + (Double(index) * staggerDelay)
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isVisible = true
                        }
                    }
                }
            }
    }
}

// MARK: - Line Drawing Animation State

/// Observable object for managing line chart drawing animation state
@MainActor
class LineChartAnimationState: ObservableObject {
    @Published var progress: CGFloat = 0

    private var reduceMotion: Bool = false

    func configure(reduceMotion: Bool) {
        self.reduceMotion = reduceMotion
    }

    func startAnimation(duration: Double = 0.8, delay: Double = 0) {
        if reduceMotion {
            progress = 1.0
            return
        }

        progress = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            withAnimation(.easeOut(duration: duration)) {
                self?.progress = 1.0
            }
        }
    }

    func reset() {
        progress = 0
    }
}

// MARK: - View Extensions

extension View {
    /// Apply animated line drawing effect to the view
    /// - Parameters:
    ///   - duration: Animation duration in seconds (default: 0.8)
    ///   - delay: Delay before animation starts (default: 0)
    func animatedLineDrawing(duration: Double = 0.8, delay: Double = 0) -> some View {
        modifier(AnimatedLineModifier(duration: duration, delay: delay))
    }

    /// Apply animated trim effect to chart views
    /// - Parameters:
    ///   - duration: Animation duration in seconds (default: 0.8)
    ///   - delay: Delay before animation starts (default: 0)
    func animatedTrim(duration: Double = 0.8, delay: Double = 0) -> some View {
        modifier(AnimatedTrimModifier(duration: duration, delay: delay))
    }

    /// Apply staggered appearance animation for chart elements
    /// - Parameters:
    ///   - index: The index of this element for stagger calculation
    ///   - baseDelay: Base delay before animations start
    ///   - staggerDelay: Delay between each element
    func chartAppearAnimation(
        index: Int = 0,
        baseDelay: Double = 0,
        staggerDelay: Double = 0.05
    ) -> some View {
        modifier(ChartAppearAnimationModifier(
            index: index,
            baseDelay: baseDelay,
            staggerDelay: staggerDelay
        ))
    }
}

// MARK: - Animated Bar Chart Bar

/// An animated bar for bar charts with grow-up animation
struct AnimatedChartBar: View {
    let value: CGFloat
    let maxValue: CGFloat
    let color: Color
    var width: CGFloat = 30
    var maxHeight: CGFloat = 150
    var cornerRadius: CGFloat = 4
    var delay: Double = 0

    @State private var animatedHeight: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var targetHeight: CGFloat {
        guard maxValue > 0 else { return 0 }
        return (value / maxValue) * maxHeight
    }

    var body: some View {
        VStack {
            Spacer(minLength: 0)

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(color)
                .frame(width: width, height: animatedHeight)
        }
        .frame(height: maxHeight)
        .onAppear {
            if reduceMotion {
                animatedHeight = targetHeight
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        animatedHeight = targetHeight
                    }
                }
            }
        }
        .onChange(of: value) { _, _ in
            if reduceMotion {
                animatedHeight = targetHeight
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    animatedHeight = targetHeight
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct AnimatedChart_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.xl + Spacing.xs) {
                // Progress Ring Examples
                Text("Animated Progress Rings")
                    .font(.headline)

                HStack(spacing: Spacing.lg - Spacing.xxs) {
                    AnimatedProgressRing(
                        progress: 0.75,
                        color: .modusCyan,
                        size: 80,
                        lineWidth: 8
                    )

                    AnimatedProgressRing(
                        progress: 0.5,
                        color: .green,
                        size: 80,
                        lineWidth: 8,
                        subtitle: "Goal"
                    )

                    AnimatedProgressRing(
                        progress: 1.0,
                        color: .orange,
                        size: 80,
                        lineWidth: 8
                    )
                }

                Divider()

                // Bar Chart Example
                Text("Animated Bar Chart")
                    .font(.headline)

                HStack(alignment: .bottom, spacing: Spacing.xs) {
                    ForEach(0..<7, id: \.self) { index in
                        AnimatedChartBar(
                            value: CGFloat.random(in: 30...100),
                            maxValue: 100,
                            color: .modusCyan,
                            delay: Double(index) * 0.1
                        )
                    }
                }
                .frame(height: 160)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(CornerRadius.md)

                Divider()

                // Line Animation Example
                Text("Animated Line Drawing")
                    .font(.headline)

                Path { path in
                    path.move(to: CGPoint(x: 0, y: 100))
                    path.addLine(to: CGPoint(x: 50, y: 60))
                    path.addLine(to: CGPoint(x: 100, y: 80))
                    path.addLine(to: CGPoint(x: 150, y: 40))
                    path.addLine(to: CGPoint(x: 200, y: 70))
                    path.addLine(to: CGPoint(x: 250, y: 30))
                    path.addLine(to: CGPoint(x: 300, y: 50))
                }
                .stroke(Color.green, lineWidth: 3)
                .frame(width: 300, height: 120)
                .animatedLineDrawing(duration: 1.0)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(CornerRadius.md)

                Spacer()
            }
            .padding()
        }
    }
}
#endif
