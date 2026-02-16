//
//  CellRecycler.swift
//  PTPerformance
//
//  ACP-942: 60fps Scroll Performance — View identity optimization for cell reuse.
//  Provides stable ID wrappers, reuse identifiers, and placeholder/shimmer cells
//  to maximize SwiftUI's cell recycling and reduce layout churn during scrolling.
//

import SwiftUI

// MARK: - StableIDWrapper

/// Wrapper that ensures stable identifiers for ForEach, maximizing cell reuse.
/// SwiftUI's diffing algorithm works best when IDs are stable across data refreshes.
/// Wrapping your data elements in StableIDWrapper prevents unnecessary cell
/// destruction and recreation when the underlying collection is replaced.
///
/// Usage:
/// ```swift
/// let stableWorkouts = workouts.map { StableIDWrapper(wrapped: $0) }
/// ForEach(stableWorkouts) { wrapper in
///     WorkoutRow(workout: wrapper.wrapped)
/// }
/// ```
struct StableIDWrapper<T: Identifiable>: Identifiable {
    let wrapped: T

    var id: T.ID {
        wrapped.id
    }

    init(wrapped: T) {
        self.wrapped = wrapped
    }
}

/// Convenience for mapping collections to StableIDWrapper
extension RandomAccessCollection where Element: Identifiable {
    /// Wrap each element in a StableIDWrapper for optimal ForEach reuse.
    func stableWrapped() -> [StableIDWrapper<Element>] {
        map { StableIDWrapper(wrapped: $0) }
    }
}

// MARK: - Reuse Identifier Modifier

/// View modifier that sets a stable `.id()` on a view to help SwiftUI's
/// diffing algorithm maximize cell reuse. When SwiftUI sees the same ID,
/// it updates the existing view in place rather than destroying and recreating it.
struct ReuseIdentifierModifier: ViewModifier {
    let identifier: String

    func body(content: Content) -> some View {
        content
            .id(identifier)
    }
}

extension View {
    /// Set a stable reuse identifier for SwiftUI's diffing algorithm.
    /// Use this on list cells to ensure SwiftUI reuses them efficiently
    /// rather than creating new view instances.
    ///
    /// - Parameter id: A stable, unique identifier string for this cell.
    /// - Returns: The view with a stable identity set.
    ///
    /// Usage:
    /// ```swift
    /// ExerciseRow(exercise: exercise)
    ///     .reuseIdentifier("exercise-\(exercise.id)")
    /// ```
    func reuseIdentifier(_ id: String) -> some View {
        modifier(ReuseIdentifierModifier(identifier: id))
    }
}

// MARK: - PlaceholderCell

/// A lightweight shimmer/skeleton placeholder cell displayed while real content loads.
/// Uses a simple gradient animation to indicate loading state. Designed to be as
/// cheap as possible to render so it never causes frame drops itself.
///
/// Usage:
/// ```swift
/// if isLoading {
///     PlaceholderCell(height: 80, cornerRadius: 12)
/// } else {
///     RealContent()
/// }
/// ```
struct PlaceholderCell: View {
    let height: CGFloat
    let cornerRadius: CGFloat
    let animated: Bool

    @State private var shimmerOffset: CGFloat = -1.0

    init(
        height: CGFloat = 60,
        cornerRadius: CGFloat = 8,
        animated: Bool = true
    ) {
        self.height = height
        self.cornerRadius = cornerRadius
        self.animated = animated
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(shimmerGradient)
            .frame(height: height)
            .onAppear {
                guard animated else { return }
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    shimmerOffset = 2.0
                }
            }
    }

    private var shimmerGradient: some ShapeStyle {
        if animated {
            return AnyShapeStyle(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.gray.opacity(0.15),
                        Color.gray.opacity(0.30),
                        Color.gray.opacity(0.15)
                    ]),
                    startPoint: UnitPoint(x: shimmerOffset - 1, y: 0.5),
                    endPoint: UnitPoint(x: shimmerOffset, y: 0.5)
                )
            )
        } else {
            return AnyShapeStyle(Color.gray.opacity(0.15))
        }
    }
}

// MARK: - PlaceholderRow

/// A multi-line shimmer placeholder that mimics a typical list row layout
/// (thumbnail + two text lines). Useful as a skeleton screen for list cells.
struct PlaceholderRow: View {
    let imageSize: CGFloat
    let animated: Bool

    init(imageSize: CGFloat = 44, animated: Bool = true) {
        self.imageSize = imageSize
        self.animated = animated
    }

    var body: some View {
        HStack(spacing: 12) {
            PlaceholderCell(
                height: imageSize,
                cornerRadius: imageSize / 4,
                animated: animated
            )
            .frame(width: imageSize)

            VStack(alignment: .leading, spacing: 8) {
                PlaceholderCell(
                    height: 14,
                    cornerRadius: 4,
                    animated: animated
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                PlaceholderCell(
                    height: 12,
                    cornerRadius: 4,
                    animated: animated
                )
                .frame(width: 120, alignment: .leading)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

// MARK: - Placeholder List

/// Generates a list of placeholder rows for skeleton loading screens.
/// Drop this into a loading state to give users immediate visual feedback.
///
/// Usage:
/// ```swift
/// if isLoading {
///     PlaceholderList(rowCount: 10, rowHeight: 72)
/// }
/// ```
struct PlaceholderList: View {
    let rowCount: Int
    let rowHeight: CGFloat
    let cornerRadius: CGFloat
    let animated: Bool

    init(
        rowCount: Int = 8,
        rowHeight: CGFloat = 60,
        cornerRadius: CGFloat = 8,
        animated: Bool = true
    ) {
        self.rowCount = rowCount
        self.rowHeight = rowHeight
        self.cornerRadius = cornerRadius
        self.animated = animated
    }

    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(0..<rowCount, id: \.self) { _ in
                PlaceholderCell(
                    height: rowHeight,
                    cornerRadius: cornerRadius,
                    animated: animated
                )
                .padding(.horizontal, 16)
            }
        }
    }
}
