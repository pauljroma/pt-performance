//
//  DynamicTypeModifiers.swift
//  PTPerformance
//
//  ACP-926: Dynamic Type Support
//  Reusable SwiftUI view modifiers for adaptive layouts, scaled spacing,
//  scaled icons, truncation-safe text, and minimum tap target enforcement.
//
//  Usage:
//  ```swift
//  HStack { ... }
//      .adaptiveStack()   // Switches to VStack at accessibility sizes
//
//  Image(systemName: "heart.fill")
//      .scaledIcon(.medium)
//
//  Text("Long exercise name that might truncate")
//      .truncationSafe()
//
//  Button("Start") { ... }
//      .scaledTapTarget()
//  ```
//

import SwiftUI

// MARK: - Adaptive Stack Modifier

/// Replaces the content with an `HStack` at standard sizes or a `VStack`
/// at accessibility Dynamic Type sizes.
///
/// This modifier wraps existing content; for building adaptive stacks from
/// scratch, use `DynamicTypeKit.AdaptiveStack` directly.
private struct AdaptiveStackModifier: ViewModifier {

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let spacing: CGFloat?

    func body(content: Content) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: horizontalAlignment, spacing: spacing) {
                content
            }
        } else {
            HStack(alignment: verticalAlignment, spacing: spacing) {
                content
            }
        }
    }
}

// MARK: - Scaled Icon Modifier

/// Scales a system image (SF Symbol) proportionally with Dynamic Type.
///
/// Uses `@ScaledMetric` to ensure icons grow alongside text, maintaining
/// visual balance at all Dynamic Type sizes.
private struct ScaledIconModifier: ViewModifier {

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let baseSize: CGFloat
    let color: Color?

    @ScaledMetric(wrappedValue: 20, relativeTo: .body) private var scaledSize: CGFloat

    init(baseSize: CGFloat, color: Color?) {
        self.baseSize = baseSize
        self.color = color
        self._scaledSize = ScaledMetric(wrappedValue: baseSize, relativeTo: .body)
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: scaledSize))
            .foregroundStyle(color ?? .primary)
            .frame(minWidth: scaledSize, minHeight: scaledSize)
    }
}

// MARK: - Scaled Spacing Modifier

/// Applies scaled padding that grows proportionally with Dynamic Type.
///
/// Unlike fixed padding, this ensures spacing relationships remain
/// visually consistent as text size changes.
private struct ScaledPaddingModifier: ViewModifier {

    let edges: Edge.Set
    let baseAmount: CGFloat

    @ScaledMetric(wrappedValue: 8, relativeTo: .body) private var scaledAmount: CGFloat

    init(edges: Edge.Set, baseAmount: CGFloat) {
        self.edges = edges
        self.baseAmount = baseAmount
        self._scaledAmount = ScaledMetric(wrappedValue: baseAmount, relativeTo: .body)
    }

    func body(content: Content) -> some View {
        content
            .padding(edges, scaledAmount)
    }
}

// MARK: - Truncation-Safe Text Modifier

/// Ensures text remains readable at all Dynamic Type sizes by allowing
/// multi-line wrapping and setting a minimum scale factor.
///
/// At accessibility sizes, text that would normally truncate is allowed
/// to wrap to additional lines. The `minimumScaleFactor` provides a
/// final fallback before truncation occurs.
private struct TruncationSafeModifier: ViewModifier {

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let lineLimit: Int?
    let minimumScaleFactor: CGFloat

    func body(content: Content) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            // At accessibility sizes, allow unlimited wrapping by default
            content
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            content
                .lineLimit(lineLimit)
                .minimumScaleFactor(minimumScaleFactor)
        }
    }
}

// MARK: - Scaled Tap Target Modifier

/// Ensures a view meets minimum tap target size requirements that
/// scale with Dynamic Type.
///
/// Apple HIG requires 44pt minimum at standard sizes. At accessibility
/// sizes, this modifier increases the minimum to 60pt for users who
/// may also have motor accessibility needs.
private struct ScaledTapTargetModifier: ViewModifier {

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ScaledMetric(relativeTo: .body) private var baseTarget: CGFloat = 44

    func body(content: Content) -> some View {
        let minimum = DynamicTypeKit.minimumTapTarget(for: dynamicTypeSize)
        let target = max(baseTarget, minimum)

        content
            .frame(minWidth: target, minHeight: target)
            .contentShape(Rectangle())
    }
}

// MARK: - Adaptive Visibility Modifier

/// Conditionally hides content at accessibility Dynamic Type sizes.
///
/// Use for secondary decorative elements (e.g., inline icons, badges)
/// that add visual noise at large text sizes and can be safely hidden
/// to give primary content more room.
private struct HideAtAccessibilitySizesModifier: ViewModifier {

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            EmptyView()
        } else {
            content
        }
    }
}

// MARK: - Show Only At Accessibility Sizes Modifier

/// Conditionally shows content only at accessibility Dynamic Type sizes.
///
/// Use for additional context that is helpful at large sizes (e.g.,
/// expanded labels that replace icons at accessibility sizes).
private struct ShowAtAccessibilitySizesModifier: ViewModifier {

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            content
        } else {
            EmptyView()
        }
    }
}

// MARK: - Scaled Card Modifier

/// Applies scaled padding, corner radius, and minimum height to a
/// card-style container that adapts to Dynamic Type.
///
/// Ensures cards remain comfortably tappable and readable at all sizes.
private struct ScaledCardModifier: ViewModifier {

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ScaledMetric(relativeTo: .body) private var padding: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var cornerRadius: CGFloat = 12
    @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = 44

    func body(content: Content) -> some View {
        let adjustedMinHeight = dynamicTypeSize.isAccessibilitySize
            ? max(minHeight, 60)
            : minHeight

        content
            .padding(padding)
            .frame(minHeight: adjustedMinHeight)
            .background(DesignTokens.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Dynamic Type Aware Font Modifier

/// Applies a semantic type scale font from `DynamicTypeKit.TypeScale`.
///
/// Convenience modifier that avoids referencing `DynamicTypeKit.TypeScale`
/// directly in view code.
private struct TypeScaleFontModifier: ViewModifier {

    let style: DynamicTypeKit.TypeScale
    let weight: Font.Weight?

    func body(content: Content) -> some View {
        if let weight {
            content.font(style.font(weight: weight))
        } else {
            content.font(style.font)
        }
    }
}

// MARK: - View Extensions

extension View {

    /// Wraps this view's content in an adaptive stack that switches from
    /// horizontal to vertical layout at accessibility Dynamic Type sizes.
    ///
    /// - Parameters:
    ///   - horizontalAlignment: Alignment when vertical. Default `.leading`.
    ///   - verticalAlignment: Alignment when horizontal. Default `.center`.
    ///   - spacing: Spacing between children. Default `nil`.
    /// - Returns: The modified view.
    func adaptiveStack(
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil
    ) -> some View {
        modifier(AdaptiveStackModifier(
            horizontalAlignment: horizontalAlignment,
            verticalAlignment: verticalAlignment,
            spacing: spacing
        ))
    }

    /// Scales an icon (SF Symbol) proportionally with Dynamic Type.
    ///
    /// Predefined sizes match `DesignTokens` icon size tokens:
    /// - `.small` = 16pt base
    /// - `.medium` = 24pt base
    /// - `.large` = 32pt base
    /// - `.xLarge` = 48pt base
    ///
    /// - Parameters:
    ///   - size: The icon size category.
    ///   - color: Optional color override. Default `nil` uses `.primary`.
    /// - Returns: The modified view.
    func scaledIcon(
        _ size: ScaledIconSize = .medium,
        color: Color? = nil
    ) -> some View {
        modifier(ScaledIconModifier(baseSize: size.basePoints, color: color))
    }

    /// Applies padding that scales proportionally with Dynamic Type.
    ///
    /// Unlike `.padding(_:_:)`, the spacing grows with the user's text
    /// size preference, maintaining visual proportions.
    ///
    /// - Parameters:
    ///   - edges: The edges to pad. Default `.all`.
    ///   - baseAmount: The base padding in points at standard size.
    /// - Returns: The modified view.
    func scaledPadding(_ edges: Edge.Set = .all, _ baseAmount: CGFloat = 16) -> some View {
        modifier(ScaledPaddingModifier(edges: edges, baseAmount: baseAmount))
    }

    /// Makes text truncation-safe by allowing wrapping at accessibility
    /// sizes and applying a minimum scale factor at standard sizes.
    ///
    /// - Parameters:
    ///   - lineLimit: Maximum lines at standard sizes. Default `nil` (unlimited).
    ///   - minimumScaleFactor: Minimum scale before truncation. Default `0.8`.
    /// - Returns: The modified view.
    func truncationSafe(lineLimit: Int? = nil, minimumScaleFactor: CGFloat = 0.8) -> some View {
        modifier(TruncationSafeModifier(lineLimit: lineLimit, minimumScaleFactor: minimumScaleFactor))
    }

    /// Ensures this view meets minimum tap target size requirements
    /// that scale with Dynamic Type.
    ///
    /// At standard sizes: minimum 44pt (Apple HIG).
    /// At accessibility sizes: minimum 60pt.
    ///
    /// - Returns: The modified view.
    func scaledTapTarget() -> some View {
        modifier(ScaledTapTargetModifier())
    }

    /// Hides this view at accessibility Dynamic Type sizes.
    ///
    /// Use for secondary decorative elements that add visual noise at
    /// large text sizes and can be safely removed.
    ///
    /// - Returns: The modified view (or `EmptyView` at accessibility sizes).
    func hideAtAccessibilitySizes() -> some View {
        modifier(HideAtAccessibilitySizesModifier())
    }

    /// Shows this view only at accessibility Dynamic Type sizes.
    ///
    /// Use for additional context or expanded labels that replace
    /// compact representations at large text sizes.
    ///
    /// - Returns: The modified view (or `EmptyView` at standard sizes).
    func showAtAccessibilitySizes() -> some View {
        modifier(ShowAtAccessibilitySizesModifier())
    }

    /// Applies scaled padding, corner radius, and minimum height to
    /// create an adaptive card container.
    ///
    /// - Returns: The modified view styled as a scaled card.
    func scaledCard() -> some View {
        modifier(ScaledCardModifier())
    }

    /// Applies a semantic type scale font from `DynamicTypeKit.TypeScale`.
    ///
    /// - Parameters:
    ///   - style: The semantic type scale style.
    ///   - weight: Optional font weight override.
    /// - Returns: The modified view.
    func typeScale(_ style: DynamicTypeKit.TypeScale, weight: Font.Weight? = nil) -> some View {
        modifier(TypeScaleFontModifier(style: style, weight: weight))
    }
}

// MARK: - ScaledIconSize

/// Predefined icon size categories that map to `DesignTokens` icon sizes.
///
/// Used with the `.scaledIcon()` modifier for consistent, scaled icon sizing.
enum ScaledIconSize {

    /// 16pt base — inline badges, status indicators.
    case small

    /// 24pt base — list row accessories, toolbar items.
    case medium

    /// 32pt base — feature icons, empty state.
    case large

    /// 48pt base — hero illustrations.
    case xLarge

    /// Custom base size in points.
    case custom(CGFloat)

    /// The base size in points before scaling.
    var basePoints: CGFloat {
        switch self {
        case .small: return DesignTokens.iconSizeSmall
        case .medium: return DesignTokens.iconSizeMedium
        case .large: return DesignTokens.iconSizeLarge
        case .xLarge: return DesignTokens.iconSizeXLarge
        case .custom(let size): return size
        }
    }
}
