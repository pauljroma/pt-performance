//
//  ErrorAlertView.swift
//  PTPerformance
//
//  Build 95 - Agent 9: Reusable error alert component
//

import SwiftUI

/// Reusable error alert view with retry functionality
struct ErrorAlertView: ViewModifier {
    @Binding var error: AppError?
    var onRetry: (() async -> Void)?

    func body(content: Content) -> some View {
        content
            .alert(
                error?.errorDescription ?? "Error",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                )
            ) {
                // Retry button (if applicable)
                if let onRetry = onRetry, error?.shouldRetry == true {
                    Button("Retry") {
                        Task {
                            await onRetry()
                        }
                    }
                }

                // Dismiss button
                Button("OK", role: .cancel) {
                    error = nil
                }
            } message: {
                if let suggestion = error?.recoverySuggestion {
                    Text(suggestion)
                }
            }
    }
}

extension View {
    /// Display an error alert with optional retry functionality
    /// - Parameters:
    ///   - error: Binding to an optional AppError
    ///   - onRetry: Optional retry closure
    func errorAlert(error: Binding<AppError?>, onRetry: (() async -> Void)? = nil) -> some View {
        modifier(ErrorAlertView(error: error, onRetry: onRetry))
    }
}

/// Inline error message view
struct InlineErrorView: View {
    let error: AppError
    var onRetry: (() async -> Void)?
    @State private var isRetrying = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)

                Text(error.errorDescription ?? "Error")
                    .font(.headline)
            }

            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let onRetry = onRetry, error.shouldRetry {
                Button {
                    Task {
                        isRetrying = true
                        await onRetry()
                        isRetrying = false
                    }
                } label: {
                    if isRetrying {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Label("Retry", systemImage: "arrow.clockwise")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isRetrying)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

/// Empty state view with error
struct EmptyStateErrorView: View {
    let title: String
    let error: AppError?
    var onRetry: (() async -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: error != nil ? "exclamationmark.triangle" : "tray")
                .font(.system(size: 60))
                .foregroundColor(error != nil ? .orange : .gray)

            VStack(spacing: 8) {
                Text(error?.errorDescription ?? title)
                    .font(.headline)

                if let suggestion = error?.recoverySuggestion {
                    Text(suggestion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }

            if let error = error, let onRetry = onRetry, error.shouldRetry {
                Button {
                    Task {
                        await onRetry()
                    }
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

// MARK: - Preview

#Preview("Error Alert") {
    struct PreviewWrapper: View {
        @State private var error: AppError? = .noInternetConnection

        var body: some View {
            VStack {
                Button("Show Error") {
                    error = .noInternetConnection
                }
            }
            .errorAlert(error: $error) {
                print("Retrying...")
            }
        }
    }

    return PreviewWrapper()
}

#Preview("Inline Error") {
    InlineErrorView(
        error: .aiTimeout,
        onRetry: {
            print("Retrying AI request...")
        }
    )
}

#Preview("Empty State Error") {
    EmptyStateErrorView(
        title: "No Data",
        error: .noInternetConnection,
        onRetry: {
            print("Retrying...")
        }
    )
}
