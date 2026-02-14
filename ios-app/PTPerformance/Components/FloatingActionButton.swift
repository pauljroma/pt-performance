//
//  FloatingActionButton.swift
//  PTPerformance
//
//  Floating action button with expandable menu for quick workout actions
//

import SwiftUI
import UIKit

/// Floating action button that expands to show workout creation options
struct FloatingActionButton: View {
    @Environment(\.colorScheme) private var colorScheme
    // MARK: - Callbacks

    let onAddToToday: (() -> Void)?
    let onNewWorkout: () -> Void
    let onFromLibrary: () -> Void

    // MARK: - State

    @State private var isExpanded = false

    // MARK: - Constants

    private let buttonSize: CGFloat = 56
    private let menuItemSpacing: CGFloat = 12
    private let animationDuration: Double = 0.3

    // MARK: - Body

    var body: some View {
        ZStack {
            // Semi-transparent backdrop when expanded
            if isExpanded {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        collapse()
                    }
                    .transition(.opacity)
            }

            // Menu and FAB container
            VStack(alignment: .trailing, spacing: menuItemSpacing) {
                // Expanded menu items
                if isExpanded {
                    // Menu items appear from bottom to top
                    menuItem(
                        title: "From Library",
                        icon: "books.vertical",
                        action: {
                            collapse()
                            onFromLibrary()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))

                    menuItem(
                        title: "New Workout",
                        icon: "figure.walk",
                        action: {
                            collapse()
                            onNewWorkout()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))

                    // Only show "Add to Today" if callback is provided
                    if let addToToday = onAddToToday {
                        menuItem(
                            title: "Add to Today",
                            icon: "plus.circle",
                            action: {
                                collapse()
                                addToToday()
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }

                // Main FAB button
                Button {
                    toggleExpanded()
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.modusCyan, .modusCyan.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: buttonSize, height: buttonSize)
                            .shadow(color: .modusCyan.opacity(0.3), radius: 8, x: 0, y: 4)

                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(isExpanded ? 45 : 0))
                    }
                }
                .accessibilityLabel(isExpanded ? "Close menu" : "Open workout menu")
                .accessibilityHint(isExpanded ? "Tap to close the menu" : "Tap to see workout options")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .animation(.spring(response: animationDuration, dampingFraction: 0.7), value: isExpanded)
    }

    // MARK: - Menu Item View

    @ViewBuilder
    private func menuItem(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.modusCyan)
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Capsule()
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: colorScheme == .dark ? .black.opacity(0.4) : .black.opacity(0.15), radius: 6, x: 0, y: 2)
            )
        }
        .accessibilityLabel(title)
        .accessibilityHint(menuItemHint(for: title))
    }

    private func menuItemHint(for title: String) -> String {
        switch title {
        case "Add to Today":
            return "Adds an exercise to today's workout"
        case "New Workout":
            return "Creates a new custom workout"
        case "From Library":
            return "Selects a workout from your saved templates"
        default:
            return ""
        }
    }

    // MARK: - Actions

    private func toggleExpanded() {
        withAnimation(.spring(response: animationDuration, dampingFraction: 0.7)) {
            isExpanded.toggle()
        }
    }

    private func collapse() {
        withAnimation(.spring(response: animationDuration, dampingFraction: 0.7)) {
            isExpanded = false
        }
    }
}

// MARK: - Preview

#Preview("Floating Action Button") {
    ZStack {
        // Sample background content
        Color(UIColor.systemGroupedBackground)
            .ignoresSafeArea()

        VStack {
            Text("Sample Content")
                .font(.title)
            Text("Tap the FAB in the bottom-right corner")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }

        FloatingActionButton(
            onAddToToday: {
                print("Add to Today tapped")
            },
            onNewWorkout: {
                print("New Workout tapped")
            },
            onFromLibrary: {
                print("From Library tapped")
            }
        )
    }
}

#Preview("Floating Action Button - Dark Mode") {
    ZStack {
        Color(UIColor.systemGroupedBackground)
            .ignoresSafeArea()

        VStack {
            Text("Dark Mode Preview")
                .font(.title)
            Text("Tap the FAB in the bottom-right corner")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }

        FloatingActionButton(
            onAddToToday: {},
            onNewWorkout: {},
            onFromLibrary: {}
        )
    }
    .preferredColorScheme(.dark)
}
