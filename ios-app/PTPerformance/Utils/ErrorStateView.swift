import SwiftUI

/// Reusable error state view with actionable buttons
/// Build 60: UX Polish - Error states
struct ErrorStateView: View {
    let title: String
    let message: String
    let icon: String
    let iconColor: Color
    var primaryAction: ErrorAction?
    var secondaryAction: ErrorAction?

    init(
        title: String = "Something Went Wrong",
        message: String,
        icon: String = "exclamationmark.triangle.fill",
        iconColor: Color = .orange,
        primaryAction: ErrorAction? = nil,
        secondaryAction: ErrorAction? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.iconColor = iconColor
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }

    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(iconColor)
                .padding(.bottom, 8)

            // Title
            Text(title)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)

            // Message
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Actions
            VStack(spacing: 12) {
                if let primary = primaryAction {
                    Button(action: primary.action) {
                        HStack {
                            if let icon = primary.icon {
                                Image(systemName: icon)
                            }
                            Text(primary.title)
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }

                if let secondary = secondaryAction {
                    Button(action: secondary.action) {
                        HStack {
                            if let icon = secondary.icon {
                                Image(systemName: icon)
                            }
                            Text(secondary.title)
                        }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

/// Error action definition
struct ErrorAction {
    let title: String
    let icon: String?
    let action: () -> Void

    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
}

// MARK: - Convenience Initializers

extension ErrorStateView {
    /// Network error state
    static func networkError(retry: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            title: "Connection Error",
            message: "Unable to connect to the server. Please check your internet connection and try again.",
            icon: "wifi.exclamationmark",
            iconColor: .orange,
            primaryAction: ErrorAction(title: "Retry", icon: "arrow.clockwise", action: retry),
            secondaryAction: nil
        )
    }

    /// No data error state
    static func noData(
        title: String = "No Data Available",
        message: String = "There's no data to display at this time.",
        action: ErrorAction? = nil
    ) -> ErrorStateView {
        ErrorStateView(
            title: title,
            message: message,
            icon: "tray.fill",
            iconColor: .gray,
            primaryAction: action,
            secondaryAction: nil
        )
    }

    /// Permission denied error
    static func permissionDenied(message: String = "You don't have permission to access this content.") -> ErrorStateView {
        ErrorStateView(
            title: "Permission Denied",
            message: message,
            icon: "lock.fill",
            iconColor: .red,
            primaryAction: nil,
            secondaryAction: nil
        )
    }

    /// Server error state
    static func serverError(retry: @escaping () -> Void, contactSupport: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            title: "Server Error",
            message: "We're experiencing technical difficulties. Our team has been notified and is working to fix the issue.",
            icon: "exclamationmark.triangle.fill",
            iconColor: .red,
            primaryAction: ErrorAction(title: "Retry", icon: "arrow.clockwise", action: retry),
            secondaryAction: ErrorAction(title: "Contact Support", icon: "envelope.fill", action: contactSupport)
        )
    }

    /// Authentication error
    static func authenticationError(signIn: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            title: "Authentication Required",
            message: "Please sign in to access this content.",
            icon: "person.crop.circle.badge.exclamationmark",
            iconColor: .blue,
            primaryAction: ErrorAction(title: "Sign In", icon: "arrow.right.circle.fill", action: signIn),
            secondaryAction: nil
        )
    }

    /// Generic error with retry
    static func genericError(
        message: String = "Something unexpected happened. Please try again.",
        retry: @escaping () -> Void
    ) -> ErrorStateView {
        ErrorStateView(
            title: "Error",
            message: message,
            icon: "exclamationmark.circle.fill",
            iconColor: .orange,
            primaryAction: ErrorAction(title: "Retry", icon: "arrow.clockwise", action: retry),
            secondaryAction: nil
        )
    }
}

// MARK: - Compact Error View

/// Compact error view for inline display (e.g., within a list or card)
struct CompactErrorView: View {
    let message: String
    let retry: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            Spacer()

            if let retry = retry {
                Button(action: retry) {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#if DEBUG
struct ErrorStateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ErrorStateView.networkError(retry: {})
                .previewDisplayName("Network Error")

            ErrorStateView.serverError(
                retry: {},
                contactSupport: {}
            )
            .previewDisplayName("Server Error")

            ErrorStateView.noData(
                title: "No Sessions Yet",
                message: "You don't have any scheduled sessions at this time.",
                action: ErrorAction(title: "Create Program", icon: "plus.circle", action: {})
            )
            .previewDisplayName("No Data")

            ErrorStateView.permissionDenied()
                .previewDisplayName("Permission Denied")

            ErrorStateView.authenticationError(signIn: {})
                .previewDisplayName("Authentication Required")

            CompactErrorView(
                message: "Failed to load data",
                retry: {}
            )
            .padding()
            .previewDisplayName("Compact Error")
        }
    }
}
#endif
