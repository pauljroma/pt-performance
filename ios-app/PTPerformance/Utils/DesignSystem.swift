import SwiftUI
import UIKit

// MARK: - Design System
// Centralized design system with spacing, colors, animations, and haptic feedback

/// Consistent spacing system throughout the app
enum Spacing {
    /// 4pt - Minimal spacing for tight layouts
    static let xxs: CGFloat = 4

    /// 8pt - Small spacing within components
    static let xs: CGFloat = 8

    /// 12pt - Default spacing for related elements
    static let sm: CGFloat = 12

    /// 16pt - Standard spacing between elements (most common)
    static let md: CGFloat = 16

    /// 24pt - Spacing between sections
    static let lg: CGFloat = 24

    /// 32pt - Large spacing for major sections
    static let xl: CGFloat = 32

    /// 48pt - Extra large spacing for page-level separation
    static let xxl: CGFloat = 48
}

/// Corner radius constants
enum CornerRadius {
    /// 4pt - Minimal rounding for badges and small elements
    static let xs: CGFloat = 4

    /// 8pt - Standard rounding for cards and buttons
    static let sm: CGFloat = 8

    /// 12pt - Default rounding (most common)
    static let md: CGFloat = 12

    /// 16pt - Prominent rounding for major cards
    static let lg: CGFloat = 16

    /// 24pt - Extra large rounding for hero elements
    static let xl: CGFloat = 24
}

/// Animation duration constants
enum AnimationDuration {
    /// 0.2s - Quick animations (button taps, highlights)
    static let quick: Double = 0.2

    /// 0.3s - Standard animations (most common)
    static let standard: Double = 0.3

    /// 0.5s - Slow animations (page transitions)
    static let slow: Double = 0.5
}

/// Shadow constants for elevation
/// Note: Uses Color(.sRGBLinear, white: 0, opacity:) for adaptive dark mode shadows
enum Shadow {
    /// Returns adaptive shadow color based on color scheme
    /// In dark mode, shadows are more subtle as cards have less visual lift
    static func adaptiveColor(opacity: Double, colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(.sRGBLinear, white: 0, opacity: opacity * 1.5)
            : Color(.sRGBLinear, white: 0, opacity: opacity)
    }

    static let subtle = ShadowStyle(
        lightOpacity: 0.05,
        darkOpacity: 0.25,
        radius: 2,
        x: 0,
        y: 1
    )

    static let medium = ShadowStyle(
        lightOpacity: 0.08,
        darkOpacity: 0.30,
        radius: 4,
        x: 0,
        y: 2
    )

    static let prominent = ShadowStyle(
        lightOpacity: 0.12,
        darkOpacity: 0.40,
        radius: 8,
        x: 0,
        y: 4
    )

    struct ShadowStyle {
        let lightOpacity: Double
        let darkOpacity: Double
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat

        /// Legacy color property for backward compatibility (uses light mode opacity)
        var color: Color {
            Color.black.opacity(lightOpacity)
        }

        /// Returns adaptive shadow color for the given color scheme
        func color(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.black.opacity(darkOpacity)
                : Color.black.opacity(lightOpacity)
        }
    }
}

// MARK: - Haptic Feedback

/// Centralized haptic feedback manager
/// Provides consistent haptic feedback across the app
/// Delegates to HapticService.shared for pre-warmed generator performance
enum HapticFeedback {
    /// Light tap feedback (button presses)
    static func light() {
        HapticService.shared.trigger(.light)
    }

    /// Medium tap feedback (selections)
    static func medium() {
        HapticService.shared.trigger(.medium)
    }

    /// Heavy tap feedback (important actions)
    static func heavy() {
        HapticService.shared.trigger(.heavy)
    }

    /// Success feedback (completion, confirmation)
    static func success() {
        HapticService.shared.trigger(.success)
    }

    /// Error feedback (validation errors, failures)
    static func error() {
        HapticService.shared.trigger(.error)
    }

    /// Warning feedback (alerts, cautions)
    static func warning() {
        HapticService.shared.trigger(.warning)
    }

    /// Selection changed feedback (picker, toggle)
    static func selectionChanged() {
        HapticService.shared.trigger(.selection)
    }

    /// Tab switch feedback - soft impact with prepared generator for responsiveness
    /// Uses a rigid style with low intensity for subtle but responsive feedback
    static func tabSwitch() {
        HapticService.shared.triggerImpact(style: .rigid, intensity: 0.5)
    }

    /// Pull-to-refresh trigger feedback - light haptic to confirm refresh started
    static func pullToRefresh() {
        HapticService.shared.triggerImpact(style: .light, intensity: 0.6)
    }

    /// Sheet/modal presentation feedback - subtle feedback for context switch
    static func sheetPresented() {
        HapticService.shared.triggerImpact(style: .light, intensity: 0.4)
    }

    /// Toggle switch feedback - selection feedback for toggle state changes
    static func toggle() {
        HapticService.shared.trigger(.selection)
    }

    /// Form submission feedback with success/error indication
    static func formSubmission(success: Bool) {
        HapticService.shared.trigger(success ? .success : .error)
    }

    /// Scroll threshold feedback - subtle feedback when crossing scroll thresholds
    static func scrollThreshold() {
        HapticService.shared.triggerImpact(style: .soft, intensity: 0.3)
    }
}

// MARK: - Button Styles

/// Primary button style (main CTAs)
struct PrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                isDisabled ? Color.gray :
                configuration.isPressed ? Color.modusCyan.opacity(0.8) : Color.modusCyan
            )
            .cornerRadius(CornerRadius.md)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.quick), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticFeedback.light()
                }
            }
    }
}

/// Secondary button style (alternative actions)
struct SecondaryButtonStyle: ButtonStyle {
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                isDisabled ? Color(.tertiarySystemGroupedBackground) :
                configuration.isPressed ? Color(.tertiarySystemGroupedBackground) : Color(.secondarySystemGroupedBackground)
            )
            .cornerRadius(CornerRadius.md)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.quick), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticFeedback.light()
                }
            }
    }
}

/// Destructive button style (delete, remove actions)
struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                configuration.isPressed ? Color.red.opacity(0.8) : Color.red
            )
            .cornerRadius(CornerRadius.md)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.quick), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticFeedback.medium()
                }
            }
    }
}

// MARK: - Card Styles

/// Standard card container with consistent styling
struct Card<Content: View>: View {
    let content: Content
    var padding: CGFloat = Spacing.md
    var cornerRadius: CGFloat = CornerRadius.md
    var shadow: Shadow.ShadowStyle = Shadow.subtle

    @Environment(\.colorScheme) private var colorScheme

    init(
        padding: CGFloat = Spacing.md,
        cornerRadius: CGFloat = CornerRadius.md,
        shadow: Shadow.ShadowStyle = Shadow.subtle,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(Color(.systemBackground))
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadow.color(for: colorScheme),
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

/// Tappable card with press animation
struct TappableCard<Content: View>: View {
    let action: () -> Void
    let content: Content
    var padding: CGFloat = Spacing.md
    var cornerRadius: CGFloat = CornerRadius.md

    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme

    init(
        padding: CGFloat = Spacing.md,
        cornerRadius: CGFloat = CornerRadius.md,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            content
                .padding(padding)
                .background(Color(.systemBackground))
                .cornerRadius(cornerRadius)
                .shadow(
                    color: Shadow.medium.color(for: colorScheme),
                    radius: Shadow.medium.radius,
                    x: Shadow.medium.x,
                    y: Shadow.medium.y
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - View Modifiers

/// Smooth appearance animation
struct AppearanceAnimation: ViewModifier {
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(.easeOut(duration: AnimationDuration.standard)) {
                    isVisible = true
                }
            }
    }
}

/// Shake animation for validation errors
struct ShakeAnimation: ViewModifier {
    let trigger: Bool
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: trigger) { _, _ in
                withAnimation(.default) {
                    offset = 10
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.default) {
                        offset = -10
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.default) {
                        offset = 5
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.default) {
                        offset = 0
                    }
                }
                HapticFeedback.error()
            }
    }
}

/// Pulse animation for loading states
struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.5 : 1.0)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
    }
}

/// Card style modifier with adaptive shadows for dark mode
struct CardStyleModifier: ViewModifier {
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadow: Shadow.ShadowStyle
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color(.systemBackground))
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadow.color(for: colorScheme),
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

/// Adaptive shadow modifier that adjusts opacity for dark mode
struct AdaptiveShadowModifier: ViewModifier {
    let style: Shadow.ShadowStyle
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .shadow(
                color: style.color(for: colorScheme),
                radius: style.radius,
                x: style.x,
                y: style.y
            )
    }
}

// MARK: - Haptic Feedback Modifiers

/// Modifier that adds haptic feedback when a sheet is presented
struct SheetHapticModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let sheetContent: () -> SheetContent

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                sheetContent()
            }
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    HapticFeedback.sheetPresented()
                }
            }
    }
}

/// Modifier that adds haptic feedback when a full screen cover is presented
struct FullScreenCoverHapticModifier<CoverContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let coverContent: () -> CoverContent

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                coverContent()
            }
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    HapticFeedback.sheetPresented()
                }
            }
    }
}

/// Modifier that provides haptic feedback at scroll thresholds
/// Useful for indicating when user has scrolled past important points
struct ScrollHapticModifier: ViewModifier {
    let threshold: CGFloat
    let onThresholdCrossed: (() -> Void)?

    @State private var hasTriggered = false
    @State private var scrollOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                }
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                let previousOffset = scrollOffset
                scrollOffset = offset

                // Trigger haptic when crossing threshold (pull down past threshold)
                if !hasTriggered && offset < -threshold && previousOffset >= -threshold {
                    HapticFeedback.scrollThreshold()
                    hasTriggered = true
                    onThresholdCrossed?()
                }

                // Reset trigger when scrolling back up
                if hasTriggered && offset > -threshold + 20 {
                    hasTriggered = false
                }
            }
    }
}

// Note: ScrollOffsetPreferenceKey is defined in ScrollAnimations.swift

/// Modifier that wraps refreshable with haptic feedback
struct RefreshableHapticModifier: ViewModifier {
    let action: @Sendable () async -> Void

    func body(content: Content) -> some View {
        content
            .refreshable {
                HapticFeedback.pullToRefresh()
                await action()
            }
    }
}

/// Toggle style that provides haptic feedback on toggle
struct HapticToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Toggle(configuration)
            .onChange(of: configuration.isOn) { _, _ in
                HapticFeedback.toggle()
            }
    }
}

/// Button style that provides haptic feedback on tap
struct HapticButtonStyle: ButtonStyle {
    let hapticType: HapticButtonType

    enum HapticButtonType {
        case light
        case medium
        case selection
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.quick), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    switch hapticType {
                    case .light:
                        HapticFeedback.light()
                    case .medium:
                        HapticFeedback.medium()
                    case .selection:
                        HapticFeedback.selectionChanged()
                    }
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply smooth appearance animation
    func appearAnimation() -> some View {
        modifier(AppearanceAnimation())
    }

    /// Apply shake animation for errors
    func shake(trigger: Bool) -> some View {
        modifier(ShakeAnimation(trigger: trigger))
    }

    /// Apply pulse animation for loading
    func pulse() -> some View {
        modifier(PulseAnimation())
    }

    /// Apply standard card styling with adaptive shadows
    func cardStyle(
        padding: CGFloat = Spacing.md,
        cornerRadius: CGFloat = CornerRadius.md,
        shadow: Shadow.ShadowStyle = Shadow.subtle
    ) -> some View {
        modifier(CardStyleModifier(padding: padding, cornerRadius: cornerRadius, shadow: shadow))
    }

    /// Apply adaptive shadow that adjusts for dark mode
    func adaptiveShadow(_ style: Shadow.ShadowStyle = Shadow.subtle) -> some View {
        modifier(AdaptiveShadowModifier(style: style))
    }

    // MARK: - Accessibility Extensions

    /// Combines accessibility label and hint for icon buttons
    func accessibleIconButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }

    /// Makes a section header accessible
    func accessibleHeader() -> some View {
        self.accessibilityAddTraits(.isHeader)
    }

    /// Ensures text scales with Dynamic Type up to a maximum size
    /// Useful for timer displays and other large fixed-size text that shouldn't grow too large
    func dynamicTypeSize(maximum: DynamicTypeSize) -> some View {
        self.dynamicTypeSize(...maximum)
    }

    // MARK: - Haptic Feedback Extensions

    /// Presents a sheet with haptic feedback on presentation
    func sheetWithHaptic<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(SheetHapticModifier(isPresented: isPresented, sheetContent: content))
    }

    /// Presents a full screen cover with haptic feedback on presentation
    func fullScreenCoverWithHaptic<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(FullScreenCoverHapticModifier(isPresented: isPresented, coverContent: content))
    }

    /// Adds scroll threshold haptic feedback
    /// - Parameters:
    ///   - threshold: The scroll distance (in points) to trigger haptic
    ///   - onThresholdCrossed: Optional callback when threshold is crossed
    func scrollHaptic(
        threshold: CGFloat = 60,
        onThresholdCrossed: (() -> Void)? = nil
    ) -> some View {
        modifier(ScrollHapticModifier(threshold: threshold, onThresholdCrossed: onThresholdCrossed))
    }

    /// Adds refreshable with haptic feedback on trigger
    func refreshableWithHaptic(action: @Sendable @escaping () async -> Void) -> some View {
        modifier(RefreshableHapticModifier(action: action))
    }

    /// Applies haptic button style with the specified haptic type
    func hapticButtonStyle(_ type: HapticButtonStyle.HapticButtonType = .light) -> some View {
        self.buttonStyle(HapticButtonStyle(hapticType: type))
    }
}

// MARK: - Empty State View

/// Standardized empty state view
struct EmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    var iconColor: Color = .secondary
    var action: EmptyStateAction?

    struct EmptyStateAction {
        let title: String
        let icon: String?
        let action: () -> Void
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(iconColor)
                .accessibilityHidden(true)

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.title2)
                    .bold()
                    .accessibilityAddTraits(.isHeader)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            if let action = action {
                Button(action: {
                    HapticFeedback.medium()
                    action.action()
                }) {
                    HStack {
                        if let icon = action.icon {
                            Image(systemName: icon)
                                .accessibilityHidden(true)
                        }
                        Text(action.title)
                    }
                    .font(.headline)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .background(Color.modusCyan)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.md)
                }
                .accessibilityLabel(action.title)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Loading Button

/// Button with built-in loading state
struct LoadingButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void
    var style: ButtonStyleType = .primary
    var isDisabled: Bool = false

    enum ButtonStyleType {
        case primary, secondary, destructive
    }

    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                HapticFeedback.medium()
                action()
            }
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style == .primary || style == .destructive ? .white : .primary))
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
        }
        .disabled(isLoading || isDisabled)
        .buttonStyle(buttonStyle)
    }

    private var buttonStyle: some ButtonStyle {
        switch style {
        case .primary:
            return AnyButtonStyle(PrimaryButtonStyle(isLoading: isLoading, isDisabled: isDisabled))
        case .secondary:
            return AnyButtonStyle(SecondaryButtonStyle(isDisabled: isDisabled))
        case .destructive:
            return AnyButtonStyle(DestructiveButtonStyle())
        }
    }
}

/// Type-erased button style wrapper
struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}

// MARK: - Preview

#if DEBUG
struct DesignSystem_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Spacing examples
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Spacing System")
                        .font(.headline)

                    HStack(spacing: Spacing.xs) {
                        Rectangle().fill(Color.blue).frame(width: 50, height: 50)
                        Rectangle().fill(Color.blue).frame(width: 50, height: 50)
                    }

                    Text("xs (8pt), sm (12pt), md (16pt), lg (24pt), xl (32pt)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Button styles
                VStack(spacing: Spacing.sm) {
                    Text("Button Styles")
                        .font(.headline)

                    Button("Primary Button") {}
                        .buttonStyle(PrimaryButtonStyle())

                    Button("Secondary Button") {}
                        .buttonStyle(SecondaryButtonStyle())

                    Button("Destructive Button") {}
                        .buttonStyle(DestructiveButtonStyle())

                    LoadingButton(
                        title: "Loading Button",
                        icon: "checkmark",
                        isLoading: true,
                        action: {}
                    )
                }

                // Card styles
                VStack(spacing: Spacing.sm) {
                    Text("Card Styles")
                        .font(.headline)

                    Card {
                        Text("Standard Card")
                            .font(.subheadline)
                    }

                    TappableCard(action: {}) {
                        HStack {
                            Text("Tappable Card")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }
                }

                // Empty state
                EmptyStateView(
                    title: "No Data Yet",
                    message: "Get started by creating your first item",
                    icon: "tray.fill",
                    action: EmptyStateView.EmptyStateAction(
                        title: "Create Item",
                        icon: "plus.circle",
                        action: {}
                    )
                )
                .frame(height: 300)
            }
            .padding()
        }
    }
}
#endif

// MARK: - Pain Score Color

/// Shared pain score color mapping used across Rehab views
/// Maps a 0-10 pain score to a semantic color
func painScoreColor(_ score: Int) -> Color {
    switch score {
    case 0...3: return .green
    case 4...6: return .yellow
    case 7...10: return .red
    default: return .secondary
    }
}

// MARK: - Readiness Color

/// Shared readiness-score-to-color mapping used across Performance Mode views.
/// Eliminates duplicated switch logic in PerformanceModeDashboardView and PerformanceModeStatusCard.
enum ReadinessColor {
    static func color(for score: Double) -> Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}

// MARK: - Weight Unit Default

/// Default weight unit used when no unit is provided by the data model.
/// Centralised here so the fallback can be changed in one place if the app
/// adds a user-preference for metric/imperial units later.
enum WeightUnit {
    static let defaultUnit = "lbs"
}

// MARK: - Volume Trend Constants

/// Shared thresholds for volume trend calculations.
/// Used by ModeStatusCardViewModel.deriveVolumeTrend and
/// StrengthModeContentModifier.loadVolumeData to ensure consistency.
enum VolumeTrendThreshold {
    /// Percentage change (absolute) below which volume is considered "stable".
    static let stablePercent: Double = 5.0
}
