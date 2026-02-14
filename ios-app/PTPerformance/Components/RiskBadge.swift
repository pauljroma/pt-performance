//
//  RiskBadge.swift
//  PTPerformance
//
//  Badge component showing escalation count on therapist navigation
//  Part of Risk Escalation System (M4) - X2Index Command Center
//

import SwiftUI

// MARK: - Risk Badge

/// Small badge showing unacknowledged escalation count
/// Used on tab bar items and navigation elements
struct RiskBadge: View {
    let count: Int
    var severity: EscalationSeverity?
    var size: BadgeSize = .medium

    var body: some View {
        if count > 0 {
            ZStack {
                badgeBackground

                Text(displayCount)
                    .font(badgeFont)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: badgeDimension, height: badgeDimension)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: count)
        }
    }

    // MARK: - Computed Properties

    private var displayCount: String {
        count > 99 ? "99+" : "\(count)"
    }

    private var badgeBackground: some View {
        Circle()
            .fill(badgeColor)
            .shadow(color: badgeColor.opacity(0.5), radius: 2, x: 0, y: 1)
    }

    private var badgeColor: Color {
        if let severity = severity {
            return severity.color
        }
        return .red
    }

    /// Use the canonical top-level BadgeSize enum
    typealias BadgeSize = PTPerformance.BadgeSize

    /// Circular badge dimension based on size
    private var badgeDimension: CGFloat {
        switch size {
        case .small: return 16
        case .medium: return 20
        case .large: return 24
        }
    }

    /// Fixed-size font for circular risk badge text
    private var badgeFont: Font {
        switch size {
        case .small: return .system(size: 9)
        case .medium: return .system(size: 11)
        case .large: return .system(size: 13)
        }
    }
}

// MARK: - Risk Badge Overlay Modifier

/// View modifier to add a risk badge to any view
struct RiskBadgeModifier: ViewModifier {
    let count: Int
    var severity: EscalationSeverity?
    var alignment: Alignment = .topTrailing
    var offset: CGPoint = CGPoint(x: 8, y: -8)

    func body(content: Content) -> some View {
        content
            .overlay(alignment: alignment) {
                RiskBadge(count: count, severity: severity)
                    .offset(x: offset.x, y: offset.y)
            }
    }
}

extension View {
    /// Add a risk badge overlay to this view
    /// - Parameters:
    ///   - count: Number to display in the badge
    ///   - severity: Optional severity level for coloring
    ///   - alignment: Badge alignment (default: topTrailing)
    ///   - offset: Badge offset from alignment position
    func riskBadge(
        count: Int,
        severity: EscalationSeverity? = nil,
        alignment: Alignment = .topTrailing,
        offset: CGPoint = CGPoint(x: 8, y: -8)
    ) -> some View {
        modifier(RiskBadgeModifier(
            count: count,
            severity: severity,
            alignment: alignment,
            offset: offset
        ))
    }
}

// MARK: - Animated Risk Badge

/// Risk badge with pulse animation for urgent alerts
struct AnimatedRiskBadge: View {
    let count: Int
    var severity: EscalationSeverity?
    @State private var isPulsing = false

    var body: some View {
        if count > 0 {
            ZStack {
                // Pulse effect for critical/high
                if shouldPulse {
                    Circle()
                        .fill(badgeColor.opacity(0.3))
                        .frame(width: 28, height: 28)
                        .scaleEffect(isPulsing ? 1.3 : 1.0)
                        .opacity(isPulsing ? 0 : 0.5)
                }

                RiskBadge(count: count, severity: severity)
            }
            .onAppear {
                if shouldPulse {
                    startPulsing()
                }
            }
        }
    }

    private var shouldPulse: Bool {
        guard let severity = severity else { return count > 0 }
        return severity == .critical || severity == .high
    }

    private var badgeColor: Color {
        severity?.color ?? .red
    }

    private func startPulsing() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
            isPulsing = true
        }
    }
}

// MARK: - Multi-Severity Badge

/// Badge showing breakdown by severity level
struct MultiSeverityBadge: View {
    let criticalCount: Int
    let highCount: Int
    let mediumCount: Int

    var body: some View {
        HStack(spacing: 4) {
            if criticalCount > 0 {
                severityPill(count: criticalCount, color: .red)
            }
            if highCount > 0 {
                severityPill(count: highCount, color: .orange)
            }
            if mediumCount > 0 {
                severityPill(count: mediumCount, color: .yellow)
            }
        }
    }

    private func severityPill(count: Int, color: Color) -> some View {
        HStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text("\(count)")
                .font(.caption2.weight(.bold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.15))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Risk Indicator Dot

/// Simple dot indicator for risk presence
struct RiskIndicatorDot: View {
    let severity: EscalationSeverity
    var isAnimated: Bool = false
    @State private var isVisible = true

    var body: some View {
        Circle()
            .fill(severity.color)
            .frame(width: 8, height: 8)
            .opacity(isVisible ? 1 : 0.3)
            .onAppear {
                if isAnimated && (severity == .critical || severity == .high) {
                    startBlinking()
                }
            }
    }

    private func startBlinking() {
        withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
            isVisible.toggle()
        }
    }
}

// MARK: - Tab Badge View

/// Badge specifically designed for tab bar items
struct TabRiskBadge: View {
    @StateObject var badgeManager = TabBarBadgeManager.shared

    var body: some View {
        Group {
            if badgeManager.intelligenceBadge > 0 {
                RiskBadge(count: badgeManager.intelligenceBadge, size: .small)
                    .offset(x: 12, y: -8)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct RiskBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 32) {
            // Standard badges
            HStack(spacing: 24) {
                RiskBadge(count: 3)
                RiskBadge(count: 12, severity: .critical)
                RiskBadge(count: 99, severity: .high)
                RiskBadge(count: 150, severity: .medium)
            }

            // Different sizes
            HStack(spacing: 24) {
                RiskBadge(count: 5, size: .small)
                RiskBadge(count: 5, size: .medium)
                RiskBadge(count: 5, size: .large)
            }

            // Badge overlay
            Image(systemName: "bell.fill")
                .font(.title)
                .riskBadge(count: 3, severity: .critical)

            // Animated badge
            AnimatedRiskBadge(count: 2, severity: .critical)

            // Multi-severity badge
            MultiSeverityBadge(criticalCount: 1, highCount: 3, mediumCount: 5)

            // Risk indicators
            HStack(spacing: 16) {
                ForEach(EscalationSeverity.allCases, id: \.self) { severity in
                    RiskIndicatorDot(severity: severity, isAnimated: true)
                }
            }
        }
        .padding()
    }
}
#endif
