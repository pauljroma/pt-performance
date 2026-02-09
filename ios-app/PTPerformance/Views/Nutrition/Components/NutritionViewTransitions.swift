//
//  NutritionViewTransitions.swift
//  PTPerformance
//
//  ACP-1018: Visual upgrade - Animated transitions between daily/weekly views
//

import SwiftUI

// MARK: - View Period Toggle

/// Animated toggle for switching between daily and weekly nutrition views
struct NutritionViewPeriodToggle: View {
    @Binding var selectedPeriod: NutritionViewPeriod

    @Namespace private var animation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(NutritionViewPeriod.allCases, id: \.self) { period in
                periodButton(period)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
    }

    private func periodButton(_ period: NutritionViewPeriod) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedPeriod = period
            }
            HapticFeedback.selectionChanged()
        } label: {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: period.icon)
                    .font(.caption)

                Text(period.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(
                ZStack {
                    if selectedPeriod == period {
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color(.systemBackground))
                            .adaptiveShadow(Shadow.subtle)
                            .matchedGeometryEffect(id: "periodBackground", in: animation)
                    }
                }
            )
            .foregroundColor(selectedPeriod == period ? .primary : .secondary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Nutrition View Period

enum NutritionViewPeriod: String, CaseIterable, Hashable {
    case daily
    case weekly

    var displayName: String {
        switch self {
        case .daily: return "Today"
        case .weekly: return "Week"
        }
    }

    var icon: String {
        switch self {
        case .daily: return "sun.max.fill"
        case .weekly: return "calendar"
        }
    }
}

// MARK: - Animated View Container

/// Container that animates content transitions between views
struct NutritionAnimatedContainer<Content: View>: View {
    let period: NutritionViewPeriod
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .transition(.asymmetric(
                insertion: .move(edge: period == .daily ? .leading : .trailing)
                    .combined(with: .opacity),
                removal: .move(edge: period == .daily ? .trailing : .leading)
                    .combined(with: .opacity)
            ))
            .id(period)
    }
}

// MARK: - Staggered Appearance Animation

/// Modifier for staggered card appearance animation
struct StaggeredAppearanceModifier: ViewModifier {
    let index: Int
    let isVisible: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.7)
                    .delay(Double(index) * 0.08),
                value: isVisible
            )
    }
}

extension View {
    func staggeredAppearance(index: Int, isVisible: Bool) -> some View {
        modifier(StaggeredAppearanceModifier(index: index, isVisible: isVisible))
    }
}

// MARK: - Progress Update Animation

/// Modifier for smooth progress bar updates
struct ProgressUpdateAnimationModifier: ViewModifier {
    let progress: Double
    @State private var animatedProgress: Double = 0

    func body(content: Content) -> some View {
        content
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    animatedProgress = progress
                }
            }
            .onChange(of: progress) { _, newValue in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    animatedProgress = newValue
                }
            }
    }
}

// MARK: - Card Scale Animation

/// Reusable card scale animation modifier
struct CardScaleModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    func cardScaleEffect() -> some View {
        modifier(CardScaleModifier())
    }
}

// MARK: - Slide In Animation

/// Modifier for slide-in animation from a specified edge
struct SlideInModifier: ViewModifier {
    let edge: Edge
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .offset(x: horizontalOffset, y: verticalOffset)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                    isVisible = true
                }
            }
    }

    private var horizontalOffset: CGFloat {
        guard !isVisible else { return 0 }
        switch edge {
        case .leading: return -30
        case .trailing: return 30
        default: return 0
        }
    }

    private var verticalOffset: CGFloat {
        guard !isVisible else { return 0 }
        switch edge {
        case .top: return -30
        case .bottom: return 30
        default: return 0
        }
    }
}

extension View {
    func slideIn(from edge: Edge, delay: Double = 0) -> some View {
        modifier(SlideInModifier(edge: edge, delay: delay))
    }
}

// MARK: - Bounce Animation

/// Modifier for bounce animation on value change
struct BounceModifier: ViewModifier {
    let trigger: Bool
    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: trigger) { _, _ in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                    scale = 1.15
                }
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6).delay(0.15)) {
                    scale = 1.0
                }
            }
    }
}

extension View {
    func bounce(on trigger: Bool) -> some View {
        modifier(BounceModifier(trigger: trigger))
    }
}

// MARK: - Preview

#if DEBUG
struct NutritionViewTransitions_Previews: PreviewProvider {
    struct PreviewContainer: View {
        @State private var selectedPeriod: NutritionViewPeriod = .daily
        @State private var isVisible = false

        var body: some View {
            VStack(spacing: Spacing.lg) {
                NutritionViewPeriodToggle(selectedPeriod: $selectedPeriod)

                NutritionAnimatedContainer(period: selectedPeriod) {
                    switch selectedPeriod {
                    case .daily:
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(Color.blue.opacity(0.2))
                            .frame(height: 200)
                            .overlay(Text("Daily View"))
                    case .weekly:
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(Color.green.opacity(0.2))
                            .frame(height: 200)
                            .overlay(Text("Weekly View"))
                    }
                }

                VStack(spacing: Spacing.sm) {
                    ForEach(0..<3) { index in
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 60)
                            .staggeredAppearance(index: index, isVisible: isVisible)
                    }
                }
            }
            .padding()
            .onAppear {
                isVisible = true
            }
        }
    }

    static var previews: some View {
        PreviewContainer()
    }
}
#endif
