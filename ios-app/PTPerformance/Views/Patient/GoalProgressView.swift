//
//  GoalProgressView.swift
//  PTPerformance
//
//  Goal Progress Visualization with Charts, Progress Rings, and Celebrations
//  Agent 4 Implementation - Goal Progress Visualization
//

import SwiftUI
import Charts

// MARK: - Goal Progress Data Point

/// Data point for tracking goal progress over time
struct GoalProgressDataPoint: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let value: Double
    let milestone: GoalMilestone?

    init(date: Date, value: Double, milestone: GoalMilestone? = nil) {
        self.date = date
        self.value = value
        self.milestone = milestone
    }

    private static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    var formattedDate: String {
        Self.monthDayFormatter.string(from: date)
    }
}

// MARK: - Goal Milestone

/// Milestone markers for goal progress
enum GoalMilestone: Int, CaseIterable, Identifiable {
    case quarterway = 25
    case halfway = 50
    case threeQuarters = 75
    case complete = 100

    var id: Int { rawValue }

    var fraction: Double {
        Double(rawValue) / 100.0
    }

    var displayText: String {
        "\(rawValue)%"
    }

    var icon: String {
        switch self {
        case .quarterway: return "flag.fill"
        case .halfway: return "star.fill"
        case .threeQuarters: return "flame.fill"
        case .complete: return "trophy.fill"
        }
    }

    var color: Color {
        switch self {
        case .quarterway: return .orange
        case .halfway: return .blue
        case .threeQuarters: return .purple
        case .complete: return .green
        }
    }

    /// Get the highest achieved milestone for a progress value
    static func highestAchieved(for progress: Double) -> GoalMilestone? {
        let percentage = progress * 100
        return allCases.reversed().first { percentage >= Double($0.rawValue) }
    }

    /// Get all achieved milestones for a progress value
    static func allAchieved(for progress: Double) -> [GoalMilestone] {
        let percentage = progress * 100
        return allCases.filter { percentage >= Double($0.rawValue) }
    }
}

// MARK: - Goal Progress Ring (Reusable Component)

/// A reusable circular progress ring component for goal visualization
struct GoalProgressRing: View {
    let progress: Double
    let category: GoalCategory
    let size: CGFloat
    let lineWidth: CGFloat
    let showMilestones: Bool
    let showPercentage: Bool
    let animated: Bool

    @State private var animatedProgress: Double = 0
    @State private var showCelebration: Bool = false

    init(
        progress: Double,
        category: GoalCategory,
        size: CGFloat = 120,
        lineWidth: CGFloat = 12,
        showMilestones: Bool = true,
        showPercentage: Bool = true,
        animated: Bool = true
    ) {
        self.progress = progress
        self.category = category
        self.size = size
        self.lineWidth = lineWidth
        self.showMilestones = showMilestones
        self.showPercentage = showPercentage
        self.animated = animated
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Milestone markers (if enabled)
            if showMilestones {
                ForEach(GoalMilestone.allCases) { milestone in
                    MilestoneMarker(
                        milestone: milestone,
                        size: size,
                        lineWidth: lineWidth,
                        isAchieved: animatedProgress >= milestone.fraction
                    )
                }
            }

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
            VStack(spacing: 2) {
                if showPercentage {
                    Text("\(Int(animatedProgress * 100))%")
                        .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }

                Image(systemName: category.icon)
                    .font(.system(size: size * 0.12))
                    .foregroundColor(category.color)
            }

            // Celebration overlay
            if showCelebration && progress >= 1.0 {
                CelebrationOverlay(size: size)
            }
        }
        .onAppear {
            if animated {
                withAnimation(.easeOut(duration: 1.0)) {
                    animatedProgress = min(progress, 1.0)
                }
                // Trigger celebration if goal is complete
                if progress >= 1.0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        showCelebration = true
                        HapticFeedback.success()
                    }
                }
            } else {
                animatedProgress = min(progress, 1.0)
            }
        }
        .onChange(of: progress) { _, newValue in
            let oldProgress = animatedProgress
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = min(newValue, 1.0)
            }
            // Trigger celebration when reaching 100%
            if newValue >= 1.0 && oldProgress < 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showCelebration = true
                    HapticFeedback.success()
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(category.displayName) goal: \(Int(progress * 100)) percent complete")
    }

    private var progressGradient: AngularGradient {
        let baseColor = progressColor(for: animatedProgress)
        return AngularGradient(
            gradient: Gradient(colors: [
                baseColor.opacity(0.6),
                baseColor,
                baseColor.opacity(0.9)
            ]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360 * animatedProgress)
        )
    }

    private func progressColor(for value: Double) -> Color {
        if value >= 1.0 { return .green }
        if value >= 0.75 { return category.color }
        if value >= 0.5 { return .blue }
        return .orange
    }
}

// MARK: - Milestone Marker

/// Individual milestone marker on the progress ring
struct MilestoneMarker: View {
    let milestone: GoalMilestone
    let size: CGFloat
    let lineWidth: CGFloat
    let isAchieved: Bool

    var body: some View {
        let angle = Angle.degrees(360 * milestone.fraction - 90)
        let radius = (size / 2) + (lineWidth / 2) + 4
        let x = cos(angle.radians) * radius
        let y = sin(angle.radians) * radius

        Circle()
            .fill(isAchieved ? milestone.color : Color.gray.opacity(0.3))
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(Color(.systemBackground), lineWidth: 1)
            )
            .offset(x: x, y: y)
            .scaleEffect(isAchieved ? 1.0 : 0.8)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAchieved)
    }
}

// MARK: - Celebration Overlay

/// Confetti/celebration animation when goal is achieved
struct CelebrationOverlay: View {
    let size: CGFloat

    @State private var particles: [ConfettiParticle] = []
    @State private var showCheckmark = false

    var body: some View {
        ZStack {
            // Confetti particles
            ForEach(particles) { particle in
                ConfettiParticleView(particle: particle)
            }

            // Success checkmark
            if showCheckmark {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.green)
                    .scaleEffect(showCheckmark ? 1.0 : 0.1)
                    .opacity(showCheckmark ? 1.0 : 0.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.5), value: showCheckmark)
            }
        }
        .drawingGroup()
        .onAppear {
            generateParticles()
            withAnimation {
                showCheckmark = true
            }
            // Hide checkmark after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    showCheckmark = false
                }
            }
        }
    }

    private func generateParticles() {
        particles = (0..<20).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: -size/2...size/2),
                y: CGFloat.random(in: -size/2...size/2),
                color: [Color.green, Color.yellow, Color.modusCyan, Color.orange, Color.purple].randomElement() ?? .modusCyan,
                size: CGFloat.random(in: 4...8),
                delay: Double.random(in: 0...0.5)
            )
        }
    }
}

// MARK: - Confetti Particle

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let color: Color
    let size: CGFloat
    let delay: Double
}

struct ConfettiParticleView: View {
    let particle: ConfettiParticle

    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.1
    @State private var yOffset: CGFloat = 0

    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .offset(x: particle.x, y: particle.y + yOffset)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3).delay(particle.delay)) {
                    scale = 1.0
                }
                withAnimation(.easeIn(duration: 1.5).delay(particle.delay + 0.5)) {
                    yOffset = 100
                    opacity = 0
                }
            }
    }
}

// MARK: - Goal Progress Mini Chart

/// Mini chart showing progress toward goal over time using Swift Charts
struct GoalProgressMiniChart: View {
    let goal: PatientGoal
    let dataPoints: [GoalProgressDataPoint]
    let height: CGFloat

    init(goal: PatientGoal, dataPoints: [GoalProgressDataPoint] = [], height: CGFloat = 120) {
        self.goal = goal
        self.dataPoints = dataPoints
        self.height = height
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Chart header
            HStack {
                Text("Progress Over Time")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Spacer()

                if let latestPoint = dataPoints.last {
                    Text(latestPoint.formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if dataPoints.isEmpty {
                // Empty state when no data points are available
                VStack(spacing: Spacing.xs) {
                    Image(systemName: "chart.line.flattrend.xyaxis")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("No progress data yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: height)
                .frame(maxWidth: .infinity)
            } else {
                // Swift Charts visualization
                Chart {
                    // Target line
                    if let target = goal.targetValue {
                        RuleMark(y: .value("Target", target))
                            .foregroundStyle(Color.green.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                            .annotation(position: .trailing, alignment: .leading) {
                                Text("Goal")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                    }

                    // Progress line
                    ForEach(dataPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(goal.category.color.gradient)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        // Area fill
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [goal.category.color.opacity(0.3), goal.category.color.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        // Milestone points
                        if let milestone = point.milestone {
                            PointMark(
                                x: .value("Date", point.date),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle(milestone.color)
                            .symbolSize(40)
                        }
                    }
                }
                .frame(height: height)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(Int(doubleValue))")
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemBackground))
        )
    }

}

// MARK: - Milestone Progress View

/// Horizontal milestone progress indicator
struct MilestoneProgressView: View {
    let progress: Double
    let category: GoalCategory

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Milestones")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            HStack(spacing: 0) {
                ForEach(GoalMilestone.allCases) { milestone in
                    MilestoneSegment(
                        milestone: milestone,
                        isAchieved: progress >= milestone.fraction,
                        isLast: milestone == .complete
                    )
                }
            }

            // Labels
            HStack {
                ForEach(GoalMilestone.allCases) { milestone in
                    Text(milestone.displayText)
                        .font(.caption2)
                        .foregroundColor(progress >= milestone.fraction ? milestone.color : .secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

/// Individual milestone segment in the horizontal progress
struct MilestoneSegment: View {
    let milestone: GoalMilestone
    let isAchieved: Bool
    let isLast: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Segment line
            Rectangle()
                .fill(isAchieved ? milestone.color : Color.gray.opacity(0.3))
                .frame(height: 4)

            // Milestone marker
            ZStack {
                Circle()
                    .fill(isAchieved ? milestone.color : Color.gray.opacity(0.3))
                    .frame(width: 24, height: 24)

                Image(systemName: milestone.icon)
                    .font(.system(size: 10))
                    .foregroundColor(.white)
            }
            .scaleEffect(isAchieved ? 1.0 : 0.9)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAchieved)

            // Trailing line (except for last)
            if !isLast {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
    }
}

// MARK: - Deadline Countdown View

/// Countdown display for goal deadline
struct DeadlineCountdownView: View {
    let targetDate: Date?
    let isCompleted: Bool

    @State private var timeRemaining: TimeInterval = 0

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if isCompleted {
                completedView
            } else if let target = targetDate {
                countdownView(for: target)
            } else {
                noDeadlineView
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var completedView: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text("Goal Achieved!")
                    .font(.headline)
                    .foregroundColor(.green)

                Text("Congratulations on reaching your target")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    private func countdownView(for target: Date) -> some View {
        let components = calculateComponents(from: target)
        let isOverdue = components.isOverdue

        return HStack(spacing: Spacing.sm) {
            Image(systemName: isOverdue ? "exclamationmark.triangle.fill" : "calendar.badge.clock")
                .font(.title2)
                .foregroundColor(isOverdue ? .red : .modusCyan)

            VStack(alignment: .leading, spacing: 2) {
                Text(isOverdue ? "Overdue" : "Time Remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: Spacing.xs) {
                    if components.days > 0 {
                        CountdownUnit(value: components.days, unit: "d")
                    }
                    CountdownUnit(value: components.hours, unit: "h")
                    CountdownUnit(value: components.minutes, unit: "m")
                }
            }

            Spacer()

            // Target date badge
            VStack(alignment: .trailing, spacing: 2) {
                Text("Target")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(formattedDate(target))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isOverdue ? .red : .primary)
            }
        }
        .onReceive(timer) { _ in
            timeRemaining = target.timeIntervalSinceNow
        }
        .onAppear {
            timeRemaining = target.timeIntervalSinceNow
        }
    }

    private var noDeadlineView: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "infinity")
                .font(.title2)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("No Deadline")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("Work at your own pace")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    private func calculateComponents(from target: Date) -> (days: Int, hours: Int, minutes: Int, isOverdue: Bool) {
        let interval = target.timeIntervalSinceNow
        let isOverdue = interval < 0
        let absoluteInterval = abs(interval)

        let days = Int(absoluteInterval / 86400)
        let hours = Int((absoluteInterval.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((absoluteInterval.truncatingRemainder(dividingBy: 3600)) / 60)

        return (days, hours, minutes, isOverdue)
    }

    private static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private func formattedDate(_ date: Date) -> String {
        Self.mediumDateFormatter.string(from: date)
    }
}

/// Individual countdown unit display
struct CountdownUnit: View {
    let value: Int
    let unit: String

    var body: some View {
        HStack(spacing: 1) {
            Text("\(value)")
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)

            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Goal Progress Card (Enhanced Row)

/// Enhanced goal row with visual progress indicators
struct GoalProgressCard: View {
    let goal: PatientGoal
    let showChart: Bool

    @State private var isExpanded: Bool = false

    init(goal: PatientGoal, showChart: Bool = false) {
        self.goal = goal
        self.showChart = showChart
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Main content row
            HStack(spacing: Spacing.md) {
                // Progress ring
                GoalProgressRing(
                    progress: goal.progress,
                    category: goal.category,
                    size: 60,
                    lineWidth: 6,
                    showMilestones: false,
                    showPercentage: true,
                    animated: true
                )

                // Goal info
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(goal.title)
                        .font(.headline)
                        .lineLimit(1)

                    if let description = goal.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    // Category and deadline badges
                    HStack(spacing: Spacing.xs) {
                        GoalCategoryBadge(category: goal.category)

                        if let days = goal.daysRemaining {
                            DeadlineBadge(days: days)
                        }
                    }
                }

                Spacer()

                // Expand/collapse button
                if showChart {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded.toggle()
                        }
                        HapticFeedback.light()
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Expanded content
            if isExpanded && showChart {
                VStack(spacing: Spacing.sm) {
                    MilestoneProgressView(progress: goal.progress, category: goal.category)
                    GoalProgressMiniChart(goal: goal)
                    DeadlineCountdownView(targetDate: goal.targetDate, isCompleted: goal.isCompleted)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.systemBackground))
                .adaptiveShadow(Shadow.subtle)
        )
    }
}

/// Small category badge for goals
struct GoalCategoryBadge: View {
    let category: GoalCategory

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.system(size: 8))
            Text(category.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(category.color.opacity(0.15))
        .foregroundColor(category.color)
        .clipShape(Capsule())
    }
}

/// Small deadline badge
struct DeadlineBadge: View {
    let days: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "calendar")
                .font(.system(size: 8))
            Text(days >= 0 ? "\(days)d left" : "\(abs(days))d overdue")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(days >= 0 ? Color.modusCyan.opacity(0.15) : Color.red.opacity(0.15))
        .foregroundColor(days >= 0 ? .modusCyan : .red)
        .clipShape(Capsule())
    }
}

// MARK: - Full Goal Progress View

/// Full-screen goal progress view with all visualizations
struct GoalProgressView: View {
    let goal: PatientGoal
    @ObservedObject var viewModel: PatientGoalsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingCelebration: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Hero progress ring
                GoalProgressRing(
                    progress: goal.progress,
                    category: goal.category,
                    size: 180,
                    lineWidth: 16,
                    showMilestones: true,
                    showPercentage: true,
                    animated: true
                )
                .padding(.top, Spacing.md)

                // Goal title and description
                VStack(spacing: Spacing.xs) {
                    Text(goal.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    if let description = goal.description, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    GoalCategoryBadge(category: goal.category)
                        .padding(.top, Spacing.xxs)
                }
                .padding(.horizontal, Spacing.md)

                // Progress stats
                progressStatsSection

                // Milestones
                MilestoneProgressView(progress: goal.progress, category: goal.category)
                    .padding(.horizontal, Spacing.md)

                // Progress chart
                GoalProgressMiniChart(goal: goal, height: 150)
                    .padding(.horizontal, Spacing.md)

                // Deadline countdown
                DeadlineCountdownView(targetDate: goal.targetDate, isCompleted: goal.isCompleted)
                    .padding(.horizontal, Spacing.md)

                Spacer(minLength: Spacing.xl)
            }
        }
        .navigationTitle("Goal Progress")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if goal.progress >= 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showingCelebration = true
                }
            }
        }
    }

    private var progressStatsSection: some View {
        HStack(spacing: 0) {
            StatBox(
                title: "Current",
                value: formatValue(goal.currentValue, unit: goal.unit),
                icon: "chart.line.uptrend.xyaxis",
                color: .blue
            )

            Divider()
                .frame(height: 50)

            StatBox(
                title: "Target",
                value: formatValue(goal.targetValue, unit: goal.unit),
                icon: "target",
                color: .green
            )

            Divider()
                .frame(height: 50)

            StatBox(
                title: "Remaining",
                value: formatRemaining(),
                icon: "arrow.up.right",
                color: .orange
            )
        }
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal, Spacing.md)
    }

    private func formatValue(_ value: Double?, unit: String?) -> String {
        guard let value = value else { return "--" }
        let formatted = value == value.rounded() ? String(format: "%.0f", value) : String(format: "%.1f", value)
        if let unit = unit, !unit.isEmpty {
            return "\(formatted) \(unit)"
        }
        return formatted
    }

    private func formatRemaining() -> String {
        guard let target = goal.targetValue else { return "--" }
        let current = goal.currentValue ?? 0
        let remaining = max(0, target - current)
        let formatted = remaining == remaining.rounded() ? String(format: "%.0f", remaining) : String(format: "%.1f", remaining)
        if let unit = goal.unit, !unit.isEmpty {
            return "\(formatted) \(unit)"
        }
        return formatted
    }
}

/// Stat box component
struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            Text(value)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.semibold)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Previews

#if DEBUG
struct GoalProgressView_Previews: PreviewProvider {
    static let sampleGoal = PatientGoal(
        id: UUID(),
        patientId: UUID(),
        title: "Bench Press 225 lbs",
        description: "Build strength to bench press 225 lbs for a clean single rep.",
        category: .strength,
        targetValue: 225,
        currentValue: 185,
        unit: "lbs",
        targetDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
        status: .active,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let completedGoal = PatientGoal(
        id: UUID(),
        patientId: UUID(),
        title: "Run 5K in Under 25 Minutes",
        description: "Improve cardiovascular endurance",
        category: .endurance,
        targetValue: 25,
        currentValue: 25,
        unit: "min",
        targetDate: Date(),
        status: .completed,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let painReductionGoal = PatientGoal(
        id: UUID(),
        patientId: UUID(),
        title: "Reduce Lower Back Pain",
        description: "Decrease pain level from 7 to 2",
        category: .painReduction,
        targetValue: 2,
        currentValue: 4,
        unit: "pain scale",
        targetDate: Calendar.current.date(byAdding: .weekOfYear, value: 6, to: Date()),
        status: .active,
        createdAt: Date(),
        updatedAt: Date()
    )

    static var previews: some View {
        Group {
            // Progress Ring Preview
            VStack(spacing: 40) {
                GoalProgressRing(
                    progress: 0.82,
                    category: .strength,
                    size: 150,
                    lineWidth: 14
                )

                GoalProgressRing(
                    progress: 1.0,
                    category: .endurance,
                    size: 120,
                    lineWidth: 10
                )

                GoalProgressRing(
                    progress: 0.45,
                    category: .painReduction,
                    size: 100,
                    lineWidth: 8
                )
            }
            .padding()
            .previewDisplayName("Progress Rings")

            // Mini Chart Preview
            GoalProgressMiniChart(goal: sampleGoal)
                .padding()
                .previewDisplayName("Mini Chart")

            // Milestone Progress Preview
            MilestoneProgressView(progress: 0.65, category: .strength)
                .padding()
                .previewDisplayName("Milestones")

            // Deadline Countdown Preview
            VStack(spacing: 16) {
                DeadlineCountdownView(
                    targetDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
                    isCompleted: false
                )

                DeadlineCountdownView(
                    targetDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
                    isCompleted: false
                )

                DeadlineCountdownView(targetDate: nil, isCompleted: true)
            }
            .padding()
            .previewDisplayName("Deadline Countdown")

            // Goal Progress Card Preview
            VStack(spacing: 16) {
                GoalProgressCard(goal: sampleGoal, showChart: true)
                GoalProgressCard(goal: completedGoal, showChart: false)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .previewDisplayName("Goal Cards")

            // Full Progress View
            NavigationStack {
                GoalProgressView(goal: sampleGoal, viewModel: PatientGoalsViewModel())
            }
            .previewDisplayName("Full Progress View")
        }
    }
}
#endif
