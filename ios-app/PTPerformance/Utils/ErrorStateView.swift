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
        title: String = LocalizedStrings.ErrorStates.somethingWentWrong,
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
                        .background(Color.modusCyan)
                        .foregroundColor(.white)
                        .cornerRadius(CornerRadius.md)
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
                        .background(Color(.secondarySystemGroupedBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(CornerRadius.md)
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
            primaryAction: ErrorAction(title: LocalizedStrings.ErrorStates.retry, icon: "arrow.clockwise", action: retry),
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
            primaryAction: ErrorAction(title: LocalizedStrings.ErrorStates.retry, icon: "arrow.clockwise", action: retry),
            secondaryAction: ErrorAction(title: "Contact Support", icon: "envelope.fill", action: contactSupport)
        )
    }

    /// Authentication error
    static func authenticationError(signIn: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            title: "Authentication Required",
            message: "Please sign in to access this content.",
            icon: "person.crop.circle.badge.exclamationmark",
            iconColor: .modusCyan,
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
            primaryAction: ErrorAction(title: LocalizedStrings.ErrorStates.retry, icon: "arrow.clockwise", action: retry),
            secondaryAction: nil
        )
    }

    /// Create an error view from any Error type with automatic user-friendly message conversion
    /// - Parameters:
    ///   - error: The error to display
    ///   - retry: Optional retry action
    ///   - contactSupport: Optional contact support action
    static func from(
        error: Error,
        retry: (() -> Void)? = nil,
        contactSupport: (() -> Void)? = nil
    ) -> ErrorStateView {
        let title = UserFriendlyError.title(for: error)
        let message = UserFriendlyError.message(for: error)
        let shouldRetry = UserFriendlyError.shouldShowRetry(for: error)

        // Determine icon based on error type
        let (icon, iconColor) = iconFor(error: error)

        var primaryAction: ErrorAction?
        var secondaryAction: ErrorAction?

        if let retry = retry, shouldRetry {
            primaryAction = ErrorAction(title: LocalizedStrings.ErrorStates.tryAgain, icon: "arrow.clockwise", action: retry)
        }

        if let contactSupport = contactSupport {
            secondaryAction = ErrorAction(title: "Contact Support", icon: "envelope.fill", action: contactSupport)
        }

        return ErrorStateView(
            title: title,
            message: message,
            icon: icon,
            iconColor: iconColor,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction
        )
    }

    /// Create an error view from an AppError
    /// - Parameters:
    ///   - appError: The AppError to display
    ///   - retry: Optional retry action
    static func from(
        appError: AppError,
        retry: (() -> Void)? = nil
    ) -> ErrorStateView {
        let title = appError.errorDescription ?? "Error"
        let message = appError.recoverySuggestion ?? "Please try again."

        // Determine icon based on error type
        let (icon, iconColor) = iconFor(appError: appError)

        var primaryAction: ErrorAction?
        if let retry = retry, appError.shouldRetry {
            primaryAction = ErrorAction(title: LocalizedStrings.ErrorStates.tryAgain, icon: "arrow.clockwise", action: retry)
        }

        return ErrorStateView(
            title: title,
            message: message,
            icon: icon,
            iconColor: iconColor,
            primaryAction: primaryAction,
            secondaryAction: nil
        )
    }

    // MARK: - Icon Helpers

    private static func iconFor(error: Error) -> (String, Color) {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return ("wifi.exclamationmark", .orange)
            case .timedOut:
                return ("clock.badge.exclamationmark", .orange)
            default:
                return ("exclamationmark.triangle.fill", .orange)
            }
        }

        if let appError = error as? AppError {
            return iconFor(appError: appError)
        }

        return ("exclamationmark.circle.fill", .orange)
    }

    private static func iconFor(appError: AppError) -> (String, Color) {
        switch appError {
        case .noInternetConnection:
            return ("wifi.exclamationmark", .orange)
        case .serverUnreachable:
            return ("server.rack", .red)
        case .requestTimeout:
            return ("clock.badge.exclamationmark", .orange)
        case .networkError:
            return ("network.slash", .orange)
        case .notAuthenticated, .sessionExpired, .invalidCredentials, .authenticationFailed:
            return ("person.crop.circle.badge.exclamationmark", .modusCyan)
        case .dataNotFound, .sessionNotFound:
            return ("doc.questionmark", .gray)
        case .saveFailed, .deleteFailed, .databaseError:
            return ("externaldrive.badge.exclamationmark", .red)
        case .aiServiceUnavailable, .aiTimeout, .aiQuotaExceeded, .aiError:
            return ("brain", .purple)
        case .duplicateSchedule, .scheduleConflict, .schedulingFailed:
            return ("calendar.badge.exclamationmark", .orange)
        case .invalidInput, .missingRequiredData, .invalidDateRange:
            return ("exclamationmark.bubble", .yellow)
        case .unknown, .custom:
            return ("exclamationmark.triangle.fill", .orange)
        }
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
                        .foregroundColor(.modusCyan)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
    }

    /// Create a compact error view from any Error
    static func from(error: Error, retry: (() -> Void)? = nil) -> CompactErrorView {
        CompactErrorView(
            message: UserFriendlyError.message(for: error),
            retry: UserFriendlyError.shouldShowRetry(for: error) ? retry : nil
        )
    }
}

// MARK: - Toast Error View

/// Toast-style error view for brief notifications
struct ErrorToastView: View {
    let message: String
    var icon: String = "exclamationmark.triangle.fill"
    var iconColor: Color = .orange

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.body)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
.adaptiveShadow(Shadow.prominent)
        )
        .padding(.horizontal)
    }

    /// Create a toast from any Error
    static func from(error: Error) -> ErrorToastView {
        ErrorToastView(message: UserFriendlyError.message(for: error))
    }
}

// MARK: - Error Banner View

/// Banner-style error view for persistent errors at top of screen
struct ErrorBannerView: View {
    let title: String
    let message: String
    var onRetry: (() -> Void)?
    var onDismiss: (() -> Void)?

    @State private var isRetrying = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)

                    Text(message)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }

                Spacer()

                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }

            if let onRetry = onRetry {
                Button(action: {
                    isRetrying = true
                    onRetry()
                    // Reset after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isRetrying = false
                    }
                }) {
                    HStack(spacing: 6) {
                        if isRetrying {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(LocalizedStrings.ErrorStates.tryAgain)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(CornerRadius.xs)
                }
                .disabled(isRetrying)
            }
        }
        .padding()
        .background(Color.orange)
    }

    /// Create a banner from any Error
    static func from(
        error: Error,
        onRetry: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> ErrorBannerView {
        ErrorBannerView(
            title: UserFriendlyError.title(for: error),
            message: UserFriendlyError.message(for: error),
            onRetry: UserFriendlyError.shouldShowRetry(for: error) ? onRetry : nil,
            onDismiss: onDismiss
        )
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

            ErrorStateView.from(
                appError: .noInternetConnection,
                retry: {}
            )
            .previewDisplayName("From AppError")

            CompactErrorView(
                message: "We couldn't load your data. Please try again.",
                retry: {}
            )
            .padding()
            .previewDisplayName("Compact Error")

            ErrorToastView(message: "Something went wrong. Please try again.")
                .padding(.vertical, 50)
                .previewDisplayName("Error Toast")

            VStack(spacing: 0) {
                ErrorBannerView(
                    title: "Connection Issue",
                    message: "We couldn't reach our servers. Please check your connection.",
                    onRetry: {},
                    onDismiss: {}
                )
                Spacer()
            }
            .previewDisplayName("Error Banner")
        }
    }
}
#endif
