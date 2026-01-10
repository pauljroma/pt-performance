import SwiftUI

// MARK: - Design System
// BUILD 95 - Agent 14: UI/UX Final Polish
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
enum Shadow {
    static let subtle = ShadowStyle(
        color: Color.black.opacity(0.05),
        radius: 2,
        x: 0,
        y: 1
    )

    static let medium = ShadowStyle(
        color: Color.black.opacity(0.08),
        radius: 4,
        x: 0,
        y: 2
    )

    static let prominent = ShadowStyle(
        color: Color.black.opacity(0.12),
        radius: 8,
        x: 0,
        y: 4
    )

    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

// MARK: - Haptic Feedback

/// Centralized haptic feedback manager
/// Provides consistent haptic feedback across the app
enum HapticFeedback {
    /// Light tap feedback (button presses)
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium tap feedback (selections)
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy tap feedback (important actions)
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    /// Success feedback (completion, confirmation)
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Error feedback (validation errors, failures)
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    /// Warning feedback (alerts, cautions)
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Selection changed feedback (picker, toggle)
    static func selectionChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
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
                configuration.isPressed ? Color.blue.opacity(0.8) : Color.blue
            )
            .cornerRadius(CornerRadius.md)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.quick), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
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
                isDisabled ? Color(.systemGray5) :
                configuration.isPressed ? Color(.systemGray5) : Color(.systemGray6)
            )
            .cornerRadius(CornerRadius.md)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.quick), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
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
            .onChange(of: configuration.isPressed) { isPressed in
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
                color: shadow.color,
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
                    color: Color.black.opacity(0.08),
                    radius: 4,
                    x: 0,
                    y: 2
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
            .onChange(of: trigger) { _ in
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

    /// Apply standard card styling
    func cardStyle(
        padding: CGFloat = Spacing.md,
        cornerRadius: CGFloat = CornerRadius.md,
        shadow: Shadow.ShadowStyle = Shadow.subtle
    ) -> some View {
        self
            .padding(padding)
            .background(Color(.systemBackground))
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
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

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.title2)
                    .bold()

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
                        }
                        Text(action.title)
                    }
                    .font(.headline)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.md)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
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
