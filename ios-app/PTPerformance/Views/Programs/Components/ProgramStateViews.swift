// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  ProgramStateViews.swift
//  PTPerformance
//
//  Reusable loading, error, and empty state views for program-related screens.
//  Provides consistent UX patterns across all program views.
//

import SwiftUI

// MARK: - Program Loading View

/// A reusable loading view for program-related screens
struct ProgramLoadingView: View {
    let message: String
    var showSpinner: Bool = true

    init(_ message: String = "Loading...", showSpinner: Bool = true) {
        self.message = message
        self.showSpinner = showSpinner
    }

    var body: some View {
        VStack(spacing: 16) {
            if showSpinner {
                ProgressView()
                    .scaleEffect(1.2)
            }

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading. \(message)")
    }
}

/// Full-screen loading overlay for program operations
struct ProgramLoadingOverlay: View {
    let message: String

    init(_ message: String = "Processing...") {
        self.message = message
    }

    var body: some View {
        ZStack {
            Color(.label).opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)

                Text(message)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(Spacing.xl)
            .background(Color(.systemBackground).opacity(0.95))
            .cornerRadius(CornerRadius.lg)
            .shadow(radius: 10)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading. \(message)")
        .accessibilityAddTraits(.isModal)
    }
}

// MARK: - Program Error View

/// A reusable error view for program-related screens
struct ProgramErrorView: View {
    let title: String
    let message: String
    let icon: String
    let iconColor: Color
    var retryAction: (() -> Void)?
    var secondaryAction: ProgramErrorAction?

    init(
        title: String = "Something Went Wrong",
        message: String,
        icon: String = "exclamationmark.triangle",
        iconColor: Color = .orange,
        retryAction: (() -> Void)? = nil,
        secondaryAction: ProgramErrorAction? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.iconColor = iconColor
        self.retryAction = retryAction
        self.secondaryAction = secondaryAction
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(iconColor)

            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                if let retryAction = retryAction {
                    Button(action: retryAction) {
                        Label("Try Again", systemImage: "arrow.clockwise")
                            .font(.subheadline.weight(.medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Try again")
                    .accessibilityHint("Attempts to reload the content")
                }

                if let secondary = secondaryAction {
                    Button(action: secondary.action) {
                        if let icon = secondary.icon {
                            Label(secondary.title, systemImage: icon)
                        } else {
                            Text(secondary.title)
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error. \(title). \(message)")
    }
}

/// Action for secondary button in error view
struct ProgramErrorAction {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
}

// MARK: - Program Error View Convenience Initializers

extension ProgramErrorView {
    /// Creates an error view for loading failures
    static func loadingFailed(
        _ message: String = "We couldn't load the program data.",
        retryAction: @escaping () -> Void
    ) -> ProgramErrorView {
        ProgramErrorView(
            title: "Couldn't Load Program",
            message: message,
            icon: "exclamationmark.triangle",
            iconColor: .orange,
            retryAction: retryAction
        )
    }

    /// Creates an error view for network errors
    static func networkError(retryAction: @escaping () -> Void) -> ProgramErrorView {
        ProgramErrorView(
            title: "Connection Error",
            message: "Please check your internet connection and try again.",
            icon: "wifi.exclamationmark",
            iconColor: .orange,
            retryAction: retryAction
        )
    }

    /// Creates an error view for save failures
    static func saveFailed(
        _ message: String = "We couldn't save your changes.",
        retryAction: @escaping () -> Void
    ) -> ProgramErrorView {
        ProgramErrorView(
            title: "Save Failed",
            message: message,
            icon: "exclamationmark.circle",
            iconColor: .red,
            retryAction: retryAction
        )
    }
}

// MARK: - Program Empty State View

/// A reusable empty state view for program-related screens
struct ProgramEmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    let iconColor: Color
    var action: ProgramEmptyStateAction?

    init(
        title: String,
        message: String,
        icon: String = "doc.text.magnifyingglass",
        iconColor: Color = .blue.opacity(0.7),
        action: ProgramEmptyStateAction? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.iconColor = iconColor
        self.action = action
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(iconColor)

            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let action = action {
                Button(action: action.action) {
                    if let icon = action.icon {
                        Label(action.title, systemImage: icon)
                    } else {
                        Text(action.title)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, Spacing.xs)
                .accessibilityLabel(action.title)
                .accessibilityHint(action.hint ?? "")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

/// Action for empty state view
struct ProgramEmptyStateAction {
    let title: String
    let icon: String?
    let hint: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, hint: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.hint = hint
        self.action = action
    }
}

// MARK: - Program Empty State View Convenience Initializers

extension ProgramEmptyStateView {
    /// Empty state for no exercises in a workout
    static func noExercises(addAction: (() -> Void)? = nil) -> ProgramEmptyStateView {
        ProgramEmptyStateView(
            title: "No Exercises",
            message: "This workout doesn't have any exercises yet.",
            icon: "dumbbell",
            iconColor: .secondary,
            action: addAction.map { ProgramEmptyStateAction("Add Exercise", icon: "plus.circle.fill", action: $0) }
        )
    }

    /// Empty state for no workouts in a phase
    static func noWorkouts(addAction: (() -> Void)? = nil) -> ProgramEmptyStateView {
        ProgramEmptyStateView(
            title: "No Workouts",
            message: "Add workouts to this phase to get started.",
            icon: "figure.run",
            iconColor: .secondary,
            action: addAction.map { ProgramEmptyStateAction("Add Workout", icon: "plus.circle.fill", action: $0) }
        )
    }

    /// Empty state for no phases in a program
    static func noPhases(addAction: (() -> Void)? = nil) -> ProgramEmptyStateView {
        ProgramEmptyStateView(
            title: "No Phases Yet",
            message: "Add phases to structure your program's progression.",
            icon: "calendar.badge.plus",
            iconColor: .secondary,
            action: addAction.map { ProgramEmptyStateAction("Add Phase", icon: "plus.circle.fill", action: $0) }
        )
    }

    /// Empty state for program template (no customized workouts)
    static func programTemplate() -> ProgramEmptyStateView {
        ProgramEmptyStateView(
            title: "Program Template",
            message: "This is a program template. Workouts will appear once your therapist customizes it for you.",
            icon: "doc.text.magnifyingglass",
            iconColor: .blue.opacity(0.7)
        )
    }

    /// Empty state for no enrolled programs
    static func noEnrolledPrograms(browseAction: @escaping () -> Void) -> ProgramEmptyStateView {
        ProgramEmptyStateView(
            title: "No Active Programs",
            message: "You haven't enrolled in any programs yet. Browse our library to find one that fits your goals.",
            icon: "rectangle.stack.badge.plus",
            iconColor: .modusCyan,
            action: ProgramEmptyStateAction("Browse Programs", icon: "magnifyingglass", hint: "Opens the program library", action: browseAction)
        )
    }

    /// Empty state for no templates found
    static func noTemplates(searchText: String = "") -> ProgramEmptyStateView {
        ProgramEmptyStateView(
            title: searchText.isEmpty ? "No Templates Available" : "No Matching Templates",
            message: searchText.isEmpty ? "There are no program templates available." : "Try a different search term.",
            icon: "doc.text.magnifyingglass",
            iconColor: .secondary
        )
    }
}

// MARK: - Inline Error Banner

/// A compact inline error banner for showing errors within content
struct ProgramInlineError: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(2)

            Spacer()

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundColor(.modusCyan)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error. \(message)")
    }
}

// MARK: - Preview

#if DEBUG
struct ProgramStateViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Loading Views
            ScrollView {
                VStack(spacing: 24) {
                    ProgramLoadingView("Loading program structure...")
                }
            }
            .previewDisplayName("Loading States")

            // Error Views
            ScrollView {
                VStack(spacing: 24) {
                    ProgramErrorView.loadingFailed { }

                    Divider()

                    ProgramErrorView.networkError { }

                    Divider()

                    ProgramInlineError(message: "Failed to save your progress") { }
                }
            }
            .previewDisplayName("Error States")

            // Empty States
            ScrollView {
                VStack(spacing: 24) {
                    ProgramEmptyStateView.noExercises { }

                    Divider()

                    ProgramEmptyStateView.noPhases { }

                    Divider()

                    ProgramEmptyStateView.programTemplate()
                }
            }
            .previewDisplayName("Empty States")

            // Loading Overlay
            ZStack {
                Color.gray.opacity(0.2)
                ProgramLoadingOverlay("Saving Template...")
            }
            .previewDisplayName("Loading Overlay")
        }
    }
}
#endif
