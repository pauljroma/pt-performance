//
//  UndoToast.swift
//  PTPerformance
//
//  ACP-515: Eliminate Confirmation Dialogs
//  SwiftUI component that shows action confirmation with undo option.
//  Shows action confirmation (e.g., "Set deleted")
//  "Undo" button that reverses the action
//  Auto-dismisses after timeout (5 seconds)
//  Stacks multiple toasts if needed
//

import SwiftUI

// MARK: - Single Undo Toast

/// Individual toast view for a single undoable action
struct UndoToastView: View {
    let action: any UndoableAction
    let onUndo: () -> Void
    let onDismiss: () -> Void

    @State private var progress: CGFloat = 1.0
    @State private var isUndoing = false

    /// Toast expiration time in seconds
    private let expirationSeconds: TimeInterval = 5.0

    var body: some View {
        HStack(spacing: 12) {
            // Action description
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white.opacity(0.9))
                    .font(.system(size: 16, weight: .medium))

                Text(action.actionDescription)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            Spacer()

            // Undo button
            Button(action: {
                isUndoing = true
                onUndo()
            }) {
                HStack(spacing: 4) {
                    if isUndoing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    Text("Undo")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .cornerRadius(CornerRadius.lg)
            }
            .disabled(isUndoing)

            // Dismiss button
            Button(action: {
                HapticFeedback.light()
                onDismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.leading, Spacing.xxs)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray).opacity(0.95))

                // Progress indicator at bottom
                GeometryReader { geometry in
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: geometry.size.width * progress, height: 2)
                            .animation(.linear(duration: expirationSeconds), value: progress)
                    }
                }
                .cornerRadius(CornerRadius.md)
            }
        )
        .shadow(color: Color(.systemGray4).opacity(0.2), radius: 8, x: 0, y: 4)
        .onAppear {
            // Start progress animation
            withAnimation(.linear(duration: expirationSeconds)) {
                progress = 0
            }
        }
    }
}

// MARK: - Undo Toast Container

/// Container that displays and manages multiple undo toasts
struct UndoToastContainer: View {
    @ObservedObject var undoManager: PTUndoManager

    var body: some View {
        VStack(spacing: 8) {
            ForEach(undoManager.undoStack.prefix(3), id: \.id) { action in
                UndoToastView(
                    action: action,
                    onUndo: {
                        Task {
                            await undoManager.undo(action)
                        }
                    },
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            undoManager.dismiss(action)
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.xs)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: undoManager.undoStack.count)
    }
}

// MARK: - View Modifier

/// Modifier to add undo toast overlay to any view
struct UndoToastModifier: ViewModifier {
    @ObservedObject var undoManager: PTUndoManager

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content

            if !undoManager.undoStack.isEmpty {
                UndoToastContainer(undoManager: undoManager)
                    .padding(.bottom, Spacing.md)
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Add undo toast overlay to the view
    /// - Parameter undoManager: The undo manager to observe (defaults to shared instance)
    @MainActor
    func withUndoToasts(undoManager: PTUndoManager? = nil) -> some View {
        modifier(UndoToastModifier(undoManager: undoManager ?? PTUndoManager.shared))
    }
}

// MARK: - Preview

#if DEBUG
struct UndoToastPreview: View {
    @StateObject private var undoManager = PTUndoManager.shared

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                Button("Delete Exercise") {
                    undoManager.registerDeleteExercise(
                        exerciseId: UUID(),
                        exerciseName: "Bench Press"
                    ) {
                        print("Restored exercise")
                    }
                }

                Button("Skip Set") {
                    undoManager.registerSkipSet(
                        exerciseId: UUID(),
                        setNumber: 2,
                        exerciseName: "Squats"
                    ) {
                        print("Restored set")
                    }
                }

                Button("End Workout") {
                    undoManager.registerEndWorkout(
                        workoutName: "Morning Workout",
                        completedExercises: 3,
                        totalExercises: 5
                    ) {
                        print("Restored workout")
                    }
                }

                Button("Clear All") {
                    undoManager.dismissAll()
                }
                .foregroundColor(.red)
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .withUndoToasts(undoManager: undoManager)
    }
}

#Preview {
    UndoToastPreview()
}
#endif
