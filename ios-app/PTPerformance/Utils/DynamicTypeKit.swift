//
//  DynamicTypeKit.swift
//  PTPerformance
//
//  ACP-926: Dynamic Type Support
//  Centralized type scale system, scaled metrics, and layout adaptation
//  utilities for comprehensive Dynamic Type support across the app.
//

import SwiftUI

// MARK: - DynamicTypeKit Namespace

/// Centralized Dynamic Type utilities namespace.
///
/// `DynamicTypeKit` provides a semantic type scale system mapped to
/// Apple's Dynamic Type categories, scaled spacing utilities, layout
/// adaptation helpers, and preview tooling for testing all text sizes.
enum DynamicTypeKit {}

// MARK: - Type Scale

extension DynamicTypeKit {

    /// Semantic text styles mapped to SwiftUI `Font.TextStyle` values.
    ///
    /// Each style has a defined role in the visual hierarchy. Using these
    /// styles ensures text scales correctly with the user's Dynamic Type
    /// preference and maintains consistent hierarchy across the app.
    ///
    /// Usage:
    /// ```swift
    /// Text("Workout Summary")
    ///     .font(DynamicTypeKit.TypeScale.screenTitle.font)
    /// ```
    enum TypeScale: CaseIterable {

        /// Screen-level titles (e.g., navigation bar large titles).
        /// Maps to `.largeTitle`.
        case screenTitle

        /// Section headings within a screen.
        /// Maps to `.title2`.
        case sectionHeader

        /// Sub-section or card headings.
        /// Maps to `.title3`.
        case cardTitle

        /// Primary body content. The most commonly used style.
        /// Maps to `.body`.
        case body

        /// Secondary supporting text (descriptions, metadata).
        /// Maps to `.subheadline`.
        case bodySecondary

        /// Labels for form fields, stat categories, small UI elements.
        /// Maps to `.callout`.
        case label

        /// Captions, timestamps, footnotes.
        /// Maps to `.caption`.
        case caption

        /// Small legal text, badge labels.
        /// Maps to `.caption2`.
        case micro

        /// The corresponding SwiftUI `Font.TextStyle` for this semantic style.
        var textStyle: Font.TextStyle {
            switch self {
            case .screenTitle: return .largeTitle
            case .sectionHeader: return .title2
            case .cardTitle: return .title3
            case .body: return .body
            case .bodySecondary: return .subheadline
            case .label: return .callout
            case .caption: return .caption
            case .micro: return .caption2
            }
        }

        /// A ready-to-use `Font` configured for this semantic style.
        var font: Font {
            .system(textStyle)
        }

        /// A bold variant of the font for emphasis.
        var fontBold: Font {
            .system(textStyle).bold()
        }

        /// A weighted variant of the font.
        func font(weight: Font.Weight) -> Font {
            .system(textStyle).weight(weight)
        }

        /// Human-readable name for preview/debug purposes.
        var displayName: String {
            switch self {
            case .screenTitle: return "Screen Title"
            case .sectionHeader: return "Section Header"
            case .cardTitle: return "Card Title"
            case .body: return "Body"
            case .bodySecondary: return "Body Secondary"
            case .label: return "Label"
            case .caption: return "Caption"
            case .micro: return "Micro"
            }
        }
    }
}

// MARK: - Accessibility Size Detection

extension DynamicTypeKit {

    /// Threshold categories for adapting layout based on Dynamic Type size.
    ///
    /// Apple's HIG recommends layout adaptations at accessibility sizes
    /// (AX1 and above). This enum provides a clean API for checking the
    /// current category and adapting layouts accordingly.
    enum SizeCategory {

        /// Standard sizes: xSmall through xLarge.
        case standard

        /// Larger standard sizes: xxLarge and xxxLarge.
        case large

        /// Accessibility sizes: accessibility1 through accessibility5.
        case accessibilitySize

        /// Determines the category for a given `DynamicTypeSize`.
        @available(iOS 15.0, *)
        static func category(for size: DynamicTypeSize) -> SizeCategory {
            if size.isAccessibilitySize {
                return .accessibilitySize
            }
            switch size {
            case .xxLarge, .xxxLarge:
                return .large
            default:
                return .standard
            }
        }
    }

    /// Returns `true` when the given Dynamic Type size is at or above
    /// the accessibility range (AX1+).
    ///
    /// Use this to decide when to switch from horizontal to vertical
    /// layouts, increase tap targets, or simplify dense UI.
    @available(iOS 15.0, *)
    static func isAccessibilitySize(_ size: DynamicTypeSize) -> Bool {
        size.isAccessibilitySize
    }

    /// Returns `true` when the given Dynamic Type size is considered
    /// "large" (xxLarge or above, including accessibility sizes).
    ///
    /// Useful for intermediate layout adaptations that should kick in
    /// before the full accessibility threshold.
    @available(iOS 15.0, *)
    static func isLargeSize(_ size: DynamicTypeSize) -> Bool {
        switch size {
        case .xxLarge, .xxxLarge:
            return true
        default:
            return size.isAccessibilitySize
        }
    }
}

// MARK: - Scaled Metrics

extension DynamicTypeKit {

    /// Pre-defined base values for common scaled metrics.
    ///
    /// Use these with `@ScaledMetric` to get values that scale proportionally
    /// with the user's Dynamic Type preference.
    ///
    /// Usage:
    /// ```swift
    /// struct MyView: View {
    ///     @ScaledMetric(relativeTo: .body) private var iconSize = DynamicTypeKit.ScaledDefaults.iconMedium
    ///     @ScaledMetric(relativeTo: .body) private var cardPadding = DynamicTypeKit.ScaledDefaults.cardPadding
    /// }
    /// ```
    enum ScaledDefaults {

        // MARK: Icon Sizes

        /// Small icons (inline badges, status indicators): 16pt base.
        static let iconSmall: CGFloat = 16

        /// Medium icons (list row accessories, toolbar items): 24pt base.
        static let iconMedium: CGFloat = 24

        /// Large icons (empty state illustrations, feature icons): 32pt base.
        static let iconLarge: CGFloat = 32

        /// Extra-large icons (hero illustrations): 48pt base.
        static let iconXLarge: CGFloat = 48

        // MARK: Spacing

        /// Tight spacing within components: 4pt base.
        static let spacingTight: CGFloat = 4

        /// Small spacing between related elements: 8pt base.
        static let spacingSmall: CGFloat = 8

        /// Standard spacing between elements: 12pt base.
        static let spacingMedium: CGFloat = 12

        /// Generous spacing between sections: 16pt base.
        static let spacingLarge: CGFloat = 16

        /// Extra spacing for major sections: 24pt base.
        static let spacingXLarge: CGFloat = 24

        // MARK: Padding

        /// Card internal padding: 16pt base.
        static let cardPadding: CGFloat = 16

        /// Screen edge padding: 16pt base.
        static let screenPadding: CGFloat = 16

        /// Compact cell padding: 12pt base.
        static let cellPadding: CGFloat = 12

        // MARK: Tap Targets

        /// Minimum tap target size per Apple HIG: 44pt base.
        /// Scales up at larger Dynamic Type sizes for easier targeting.
        static let minimumTapTarget: CGFloat = 44

        /// Comfortable tap target for primary actions: 48pt base.
        static let comfortableTapTarget: CGFloat = 48
    }
}

// MARK: - Minimum Tap Target Utilities

extension DynamicTypeKit {

    /// Returns the minimum tap target size for the given Dynamic Type size.
    ///
    /// At standard sizes the minimum is 44pt (Apple HIG). At accessibility
    /// sizes the minimum increases to 60pt for easier targeting by users
    /// who typically have motor accessibility needs alongside vision needs.
    @available(iOS 15.0, *)
    static func minimumTapTarget(for size: DynamicTypeSize) -> CGFloat {
        if size.isAccessibilitySize {
            return 60
        }
        return 44
    }
}

// MARK: - Layout Adaptation Helpers

extension DynamicTypeKit {

    /// Determines whether a horizontal layout should switch to vertical
    /// for the given Dynamic Type size.
    ///
    /// At accessibility sizes, horizontal layouts (HStack) often overflow.
    /// This helper returns the preferred `Axis` so views can adapt.
    ///
    /// Usage:
    /// ```swift
    /// let axis = DynamicTypeKit.preferredAxis(for: dynamicTypeSize)
    /// // Use with AdaptiveStack or conditional layout
    /// ```
    @available(iOS 15.0, *)
    static func preferredAxis(for size: DynamicTypeSize) -> Axis {
        size.isAccessibilitySize ? .vertical : .horizontal
    }

    /// Returns the number of columns appropriate for the given Dynamic Type
    /// size in a grid layout.
    ///
    /// At standard sizes, uses the preferred count. At larger sizes, reduces
    /// column count to give text room to breathe. At accessibility sizes,
    /// falls back to a single column.
    @available(iOS 15.0, *)
    static func adaptiveColumns(
        preferred: Int,
        for size: DynamicTypeSize
    ) -> Int {
        if size.isAccessibilitySize {
            return 1
        }
        if isLargeSize(size) {
            return max(1, preferred - 1)
        }
        return preferred
    }
}

// MARK: - AdaptiveStack

extension DynamicTypeKit {

    /// A stack that switches between `HStack` and `VStack` based on
    /// Dynamic Type size.
    ///
    /// At standard and large sizes, children are laid out horizontally.
    /// At accessibility sizes, the layout switches to vertical so text
    /// has room to display at the user's preferred size.
    ///
    /// Usage:
    /// ```swift
    /// DynamicTypeKit.AdaptiveStack(spacing: 12) {
    ///     Text("Reps")
    ///     Text("Weight")
    ///     Text("RPE")
    /// }
    /// ```
    struct AdaptiveStack<Content: View>: View {

        @Environment(\.dynamicTypeSize) private var dynamicTypeSize

        let horizontalAlignment: HorizontalAlignment
        let verticalAlignment: VerticalAlignment
        let spacing: CGFloat?
        let content: () -> Content

        /// Creates an adaptive stack.
        ///
        /// - Parameters:
        ///   - horizontalAlignment: Alignment when in VStack mode. Default `.leading`.
        ///   - verticalAlignment: Alignment when in HStack mode. Default `.center`.
        ///   - spacing: Spacing between children. Default `nil` (system default).
        ///   - content: The child views.
        init(
            horizontalAlignment: HorizontalAlignment = .leading,
            verticalAlignment: VerticalAlignment = .center,
            spacing: CGFloat? = nil,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.horizontalAlignment = horizontalAlignment
            self.verticalAlignment = verticalAlignment
            self.spacing = spacing
            self.content = content
        }

        var body: some View {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: horizontalAlignment, spacing: spacing) {
                    content()
                }
            } else {
                HStack(alignment: verticalAlignment, spacing: spacing) {
                    content()
                }
            }
        }
    }
}

// MARK: - AdaptiveGrid

extension DynamicTypeKit {

    /// A grid that reduces its column count at larger Dynamic Type sizes.
    ///
    /// At standard sizes, uses the specified column count. At accessibility
    /// sizes, automatically falls back to a single-column layout.
    ///
    /// Usage:
    /// ```swift
    /// DynamicTypeKit.AdaptiveGrid(columns: 2, spacing: 12) {
    ///     ForEach(stats) { stat in
    ///         StatCard(stat: stat)
    ///     }
    /// }
    /// ```
    struct AdaptiveGrid<Content: View>: View {

        @Environment(\.dynamicTypeSize) private var dynamicTypeSize

        let preferredColumns: Int
        let spacing: CGFloat
        let content: () -> Content

        /// Creates an adaptive grid.
        ///
        /// - Parameters:
        ///   - columns: Preferred number of columns at standard sizes.
        ///   - spacing: Spacing between grid items. Default `12`.
        ///   - content: The grid content.
        init(
            columns: Int,
            spacing: CGFloat = 12,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.preferredColumns = columns
            self.spacing = spacing
            self.content = content
        }

        var body: some View {
            let columnCount = DynamicTypeKit.adaptiveColumns(
                preferred: preferredColumns,
                for: dynamicTypeSize
            )
            let gridColumns = Array(
                repeating: GridItem(.flexible(), spacing: spacing),
                count: columnCount
            )

            LazyVGrid(columns: gridColumns, spacing: spacing) {
                content()
            }
        }
    }
}

// MARK: - Dynamic Type Preview Helper

extension DynamicTypeKit {

    /// All Dynamic Type sizes available for preview testing.
    ///
    /// Use with SwiftUI previews to render a view at every Dynamic Type
    /// size in a single preview, ensuring the layout adapts correctly.
    ///
    /// Usage:
    /// ```swift
    /// #Preview("Dynamic Type Sizes") {
    ///     ScrollView {
    ///         VStack(spacing: 24) {
    ///             ForEach(DynamicTypeKit.PreviewHelper.allSizes, id: \.self) { size in
    ///                 MyView()
    ///                     .environment(\.dynamicTypeSize, size)
    ///             }
    ///         }
    ///     }
    /// }
    /// ```
    enum PreviewHelper {

        /// All available Dynamic Type sizes in order from smallest to largest.
        static let allSizes: [DynamicTypeSize] = [
            .xSmall,
            .small,
            .medium,
            .large,        // System default
            .xLarge,
            .xxLarge,
            .xxxLarge,
            .accessibility1,
            .accessibility2,
            .accessibility3,
            .accessibility4,
            .accessibility5
        ]

        /// A representative subset of sizes for quick preview testing.
        ///
        /// Includes the smallest standard size, the system default, the
        /// largest standard size, and two accessibility sizes.
        static let representativeSizes: [DynamicTypeSize] = [
            .xSmall,
            .large,         // System default
            .xxxLarge,
            .accessibility1,
            .accessibility3
        ]

        /// Human-readable name for a Dynamic Type size.
        static func displayName(for size: DynamicTypeSize) -> String {
            switch size {
            case .xSmall: return "XS"
            case .small: return "S"
            case .medium: return "M"
            case .large: return "L (Default)"
            case .xLarge: return "XL"
            case .xxLarge: return "XXL"
            case .xxxLarge: return "XXXL"
            case .accessibility1: return "AX1"
            case .accessibility2: return "AX2"
            case .accessibility3: return "AX3"
            case .accessibility4: return "AX4"
            case .accessibility5: return "AX5"
            @unknown default: return "Unknown"
            }
        }
    }
}

// MARK: - DynamicTypePreview View

extension DynamicTypeKit {

    /// A preview wrapper that renders a view at multiple Dynamic Type sizes.
    ///
    /// Displays each size in a labeled section so you can visually verify
    /// that your view adapts correctly across the full range.
    ///
    /// Usage:
    /// ```swift
    /// #Preview("All Sizes") {
    ///     DynamicTypeKit.DynamicTypePreview {
    ///         WorkoutCard(workout: .preview)
    ///     }
    /// }
    /// ```
    struct DynamicTypePreview<Content: View>: View {

        let useRepresentativeSizes: Bool
        let content: () -> Content

        /// Creates a Dynamic Type preview wrapper.
        ///
        /// - Parameters:
        ///   - representativeOnly: If `true`, shows only a representative
        ///     subset of sizes. Default `false` shows all sizes.
        ///   - content: The view to preview at each size.
        init(
            representativeOnly: Bool = false,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.useRepresentativeSizes = representativeOnly
            self.content = content
        }

        private var sizes: [DynamicTypeSize] {
            useRepresentativeSizes
                ? PreviewHelper.representativeSizes
                : PreviewHelper.allSizes
        }

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(sizes, id: \.self) { size in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(PreviewHelper.displayName(for: size))
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 16)

                            content()
                                .environment(\.dynamicTypeSize, size)
                                .padding(.horizontal, 16)

                            Divider()
                        }
                    }
                }
                .padding(.vertical, 16)
            }
        }
    }
}

// MARK: - Type Scale Preview View

extension DynamicTypeKit {

    /// A preview view that displays all semantic type scale styles.
    ///
    /// Useful for design review and verifying that the type hierarchy
    /// looks correct at the current Dynamic Type size.
    struct TypeScalePreview: View {

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(TypeScale.allCases, id: \.displayName) { style in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(style.displayName)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)

                            Text("The quick brown fox jumps over the lazy dog")
                                .font(style.font)

                            Text("Bold variant")
                                .font(style.fontBold)
                        }
                        .padding(.horizontal, 16)

                        Divider()
                    }
                }
                .padding(.vertical, 16)
            }
        }
    }
}
