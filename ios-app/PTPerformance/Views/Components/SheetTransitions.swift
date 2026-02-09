//
//  SheetTransitions.swift
//  PTPerformance
//
//  Modal/Sheet Spring Physics Implementation
//  Provides polished spring-based sheet transitions with interactive dismiss support
//

import SwiftUI

// MARK: - Spring Animation Configuration

/// Configuration constants for sheet spring animations
enum SheetSpringConfig {
    /// Presentation spring animation: response 0.35s, dampingFraction 0.85
    static let presentation = Animation.spring(response: 0.35, dampingFraction: 0.85)

    /// Dismiss spring animation: slightly faster for snappy feel
    static let dismiss = Animation.spring(response: 0.30, dampingFraction: 0.85)

    /// Interactive drag spring: more responsive during gesture
    static let interactive = Animation.spring(response: 0.25, dampingFraction: 0.80)

    /// Drag threshold in points to trigger dismiss
    static let dismissThreshold: CGFloat = 100

    /// Velocity threshold to trigger dismiss (points per second)
    static let velocityThreshold: CGFloat = 500
}

// MARK: - Interactive Dismiss State

/// Observable state for interactive sheet dismiss gestures
class InteractiveDismissState: ObservableObject {
    @Published var dragOffset: CGFloat = 0
    @Published var isDragging: Bool = false

    /// Progress toward dismiss threshold (0.0 to 1.0)
    var dismissProgress: CGFloat {
        min(1.0, max(0, dragOffset / SheetSpringConfig.dismissThreshold))
    }

    /// Whether drag has passed the dismiss threshold
    var isPastThreshold: Bool {
        dismissProgress >= 1.0
    }

    /// Reset state to initial values
    func reset() {
        dragOffset = 0
        isDragging = false
    }
}

// MARK: - Interactive Dismiss Modifier

/// A view modifier that adds interactive drag-to-dismiss behavior with spring physics
struct InteractiveDismissModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?

    @StateObject private var state = InteractiveDismissState()
    @State private var hasTriggeredHaptic = false

    func body(content: Content) -> some View {
        content
            .offset(y: state.dragOffset)
            .opacity(Double(1.0 - (state.dismissProgress * 0.3))) // Fade slightly as dragging down
            .scaleEffect(CGFloat(1.0 - (state.dismissProgress * 0.05)), anchor: .top) // Subtle scale effect
            .gesture(createDragGesture())
            .animation(state.isDragging ? nil : SheetSpringConfig.interactive, value: state.dragOffset)
    }

    private func createDragGesture() -> some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { value in
                handleDragChanged(value)
            }
            .onEnded { value in
                handleDragEnded(value)
            }
    }

    private func handleDragChanged(_ value: DragGesture.Value) {
        // Only allow downward drag (positive Y translation)
        let translation = value.translation.height

        // Ignore upward drags or horizontal-dominant drags
        guard translation > 0,
              abs(value.translation.height) > abs(value.translation.width) else {
            return
        }

        state.isDragging = true

        // Apply rubber-band resistance when past threshold
        if translation > SheetSpringConfig.dismissThreshold {
            let overshoot = translation - SheetSpringConfig.dismissThreshold
            state.dragOffset = SheetSpringConfig.dismissThreshold + (overshoot * 0.3)
        } else {
            state.dragOffset = translation
        }

        // Haptic feedback at threshold crossing
        if state.isPastThreshold && !hasTriggeredHaptic {
            HapticFeedback.medium()
            hasTriggeredHaptic = true
        } else if !state.isPastThreshold {
            hasTriggeredHaptic = false
        }
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        state.isDragging = false

        let velocity = value.predictedEndTranslation.height - value.translation.height
        let shouldDismiss = state.isPastThreshold || velocity > SheetSpringConfig.velocityThreshold

        if shouldDismiss {
            // Dismiss with spring animation
            HapticFeedback.light()

            withAnimation(SheetSpringConfig.dismiss) {
                state.dragOffset = UIScreen.main.bounds.height
            }

            // Trigger dismiss after animation starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPresented = false
                onDismiss?()
                state.reset()
            }
        } else {
            // Snap back with spring animation
            withAnimation(SheetSpringConfig.interactive) {
                state.reset()
            }
        }

        hasTriggeredHaptic = false
    }
}

// MARK: - Spring Sheet Modifier

/// A view modifier that wraps sheet content with spring presentation animations
struct SpringSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    let content: () -> SheetContent

    @State private var sheetOpacity: Double = 0
    @State private var sheetScale: CGFloat = 0.9
    @State private var sheetOffset: CGFloat = 50

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented, onDismiss: {
                onDismiss?()
            }) {
                self.content()
                    .modifier(InteractiveDismissModifier(isPresented: $isPresented, onDismiss: onDismiss))
            }
    }
}

// MARK: - Spring Sheet Item Modifier

/// A view modifier for item-based sheet presentation with spring physics
struct SpringSheetItemModifier<Item: Identifiable, SheetContent: View>: ViewModifier {
    @Binding var item: Item?
    let onDismiss: (() -> Void)?
    let content: (Item) -> SheetContent

    func body(content: Content) -> some View {
        content
            .sheet(item: $item, onDismiss: {
                onDismiss?()
            }) { item in
                self.content(item)
                    .modifier(InteractiveDismissModifier(
                        isPresented: Binding(
                            get: { self.item != nil },
                            set: { if !$0 { self.item = nil } }
                        ),
                        onDismiss: onDismiss
                    ))
            }
    }
}

// MARK: - Spring Presentation Container

/// A container view that provides spring animation for sheet content appearance
struct SpringPresentationContainer<Content: View>: View {
    let content: Content

    @State private var isAppeared = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .opacity(isAppeared ? 1 : 0)
            .scaleEffect(isAppeared ? 1 : 0.9)
            .offset(y: isAppeared ? 0 : 30)
            .onAppear {
                withAnimation(SheetSpringConfig.presentation) {
                    isAppeared = true
                }
            }
    }
}

// MARK: - Drag Indicator View

/// A standardized drag indicator for sheet headers
struct SheetDragIndicator: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Color(.systemGray3))
            .frame(width: 36, height: 5)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xs)
    }
}

// MARK: - Sheet Header

/// A standardized sheet header with drag indicator and optional title
struct SpringSheetHeader: View {
    let title: String?
    let showDragIndicator: Bool
    let onClose: (() -> Void)?

    init(
        title: String? = nil,
        showDragIndicator: Bool = true,
        onClose: (() -> Void)? = nil
    ) {
        self.title = title
        self.showDragIndicator = showDragIndicator
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            if showDragIndicator {
                SheetDragIndicator()
            }

            if let title = title {
                HStack {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Spacer()

                    if let onClose = onClose {
                        Button(action: {
                            HapticFeedback.light()
                            onClose()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        .accessibleIconButton(label: "Close", hint: "Dismiss this sheet")
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Presents a sheet with spring animation physics
    /// - Parameters:
    ///   - isPresented: Binding to control sheet presentation
    ///   - onDismiss: Optional callback when sheet is dismissed
    ///   - content: The content to display in the sheet
    func springSheet<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.modifier(SpringSheetModifier(
            isPresented: isPresented,
            onDismiss: onDismiss,
            content: content
        ))
    }

    /// Presents an item-based sheet with spring animation physics
    /// - Parameters:
    ///   - item: Binding to the optional item that triggers presentation
    ///   - onDismiss: Optional callback when sheet is dismissed
    ///   - content: The content to display in the sheet, receiving the item
    func springSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        self.modifier(SpringSheetItemModifier(
            item: item,
            onDismiss: onDismiss,
            content: content
        ))
    }

    /// Adds interactive dismiss behavior to a view (typically sheet content)
    /// - Parameters:
    ///   - isPresented: Binding to control dismissal
    ///   - onDismiss: Optional callback when dismissed via gesture
    func interactiveDismiss(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        self.modifier(InteractiveDismissModifier(
            isPresented: isPresented,
            onDismiss: onDismiss
        ))
    }

    /// Wraps content in a spring presentation container for smooth appearance
    func springPresentation() -> some View {
        SpringPresentationContainer { self }
    }
}

// MARK: - Preview

#if DEBUG
struct SheetTransitions_Previews: PreviewProvider {
    static var previews: some View {
        SheetTransitionsPreviewContainer()
    }
}

private struct SheetTransitionsPreviewContainer: View {
    @State private var showSheet = false
    @State private var selectedItem: PreviewItem?

    struct PreviewItem: Identifiable {
        let id = UUID()
        let title: String
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text("Spring Sheet Transitions")
                .font(.title)
                .fontWeight(.bold)

            Text("Drag threshold: \(Int(SheetSpringConfig.dismissThreshold))pt")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Velocity threshold: \(Int(SheetSpringConfig.velocityThreshold)) pts/sec")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button("Show Spring Sheet") {
                HapticFeedback.medium()
                showSheet = true
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Spacing.lg)

            Button("Show Item Sheet") {
                HapticFeedback.medium()
                selectedItem = PreviewItem(title: "Sample Item")
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding(.horizontal, Spacing.lg)

            Spacer()
        }
        .padding()
        .springSheet(isPresented: $showSheet) {
            VStack {
                SpringSheetHeader(
                    title: "Spring Sheet Demo",
                    onClose: { showSheet = false }
                )

                ScrollView {
                    VStack(spacing: Spacing.md) {
                        ForEach(0..<10, id: \.self) { index in
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(Color.blue.opacity(0.1))
                                .frame(height: 60)
                                .overlay(
                                    Text("Item \(index + 1)")
                                        .font(.headline)
                                )
                        }
                    }
                    .padding()
                }
                .springPresentation()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
        .springSheet(item: $selectedItem) { item in
            VStack {
                SpringSheetHeader(
                    title: item.title,
                    onClose: { selectedItem = nil }
                )

                Text("This sheet was triggered by an item binding")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .springPresentation()

                Spacer()
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
        }
    }
}
#endif
