//
//  ErrorStateViewTests.swift
//  PTPerformanceTests
//
//  Tests for ErrorStateView and related error presentation components
//

import XCTest
@testable import PTPerformance

final class ErrorActionTests: XCTestCase {

    // MARK: - Initialization Tests

    func testErrorAction_InitWithTitleOnly() {
        var called = false
        let action = ErrorAction(title: "Retry") {
            called = true
        }

        XCTAssertEqual(action.title, "Retry")
        XCTAssertNil(action.icon)

        action.action()
        XCTAssertTrue(called)
    }

    func testErrorAction_InitWithTitleAndIcon() {
        let action = ErrorAction(title: "Try Again", icon: "arrow.clockwise") {}

        XCTAssertEqual(action.title, "Try Again")
        XCTAssertEqual(action.icon, "arrow.clockwise")
    }
}

final class ErrorStateViewFactoryTests: XCTestCase {

    // MARK: - Network Error Tests

    func testNetworkError_HasRetryAction() {
        var retried = false
        let view = ErrorStateView.networkError {
            retried = true
        }

        XCTAssertEqual(view.title, "Connection Error")
        XCTAssertEqual(view.icon, "wifi.exclamationmark")
        XCTAssertNotNil(view.primaryAction)
        XCTAssertNil(view.secondaryAction)

        view.primaryAction?.action()
        XCTAssertTrue(retried)
    }

    // MARK: - No Data Tests

    func testNoData_DefaultValues() {
        let view = ErrorStateView.noData()

        XCTAssertEqual(view.title, "No Data Available")
        XCTAssertEqual(view.message, "There's no data to display at this time.")
        XCTAssertEqual(view.icon, "tray.fill")
        XCTAssertNil(view.primaryAction)
    }

    func testNoData_CustomValues() {
        let view = ErrorStateView.noData(
            title: "No Sessions",
            message: "You haven't completed any sessions yet.",
            action: ErrorAction(title: "Create One", icon: "plus") {}
        )

        XCTAssertEqual(view.title, "No Sessions")
        XCTAssertEqual(view.message, "You haven't completed any sessions yet.")
        XCTAssertNotNil(view.primaryAction)
        XCTAssertEqual(view.primaryAction?.title, "Create One")
    }

    // MARK: - Permission Denied Tests

    func testPermissionDenied_HasDefaultMessage() {
        let view = ErrorStateView.permissionDenied()

        XCTAssertEqual(view.title, "Permission Denied")
        XCTAssertEqual(view.icon, "lock.fill")
        XCTAssertNil(view.primaryAction)
    }

    func testPermissionDenied_CustomMessage() {
        let view = ErrorStateView.permissionDenied(message: "Contact your therapist for access.")

        XCTAssertEqual(view.message, "Contact your therapist for access.")
    }

    // MARK: - Server Error Tests

    func testServerError_HasBothActions() {
        var retried = false
        var contactedSupport = false

        let view = ErrorStateView.serverError(
            retry: { retried = true },
            contactSupport: { contactedSupport = true }
        )

        XCTAssertEqual(view.title, "Server Error")
        XCTAssertNotNil(view.primaryAction)
        XCTAssertNotNil(view.secondaryAction)

        view.primaryAction?.action()
        XCTAssertTrue(retried)

        view.secondaryAction?.action()
        XCTAssertTrue(contactedSupport)
    }

    // MARK: - Authentication Error Tests

    func testAuthenticationError_HasSignInAction() {
        var signedIn = false
        let view = ErrorStateView.authenticationError {
            signedIn = true
        }

        XCTAssertEqual(view.title, "Authentication Required")
        XCTAssertEqual(view.icon, "person.crop.circle.badge.exclamationmark")
        XCTAssertEqual(view.primaryAction?.title, "Sign In")

        view.primaryAction?.action()
        XCTAssertTrue(signedIn)
    }

    // MARK: - Generic Error Tests

    func testGenericError_DefaultMessage() {
        let view = ErrorStateView.genericError { }

        XCTAssertEqual(view.title, "Error")
        XCTAssertEqual(view.message, "Something unexpected happened. Please try again.")
    }

    func testGenericError_CustomMessage() {
        let view = ErrorStateView.genericError(message: "Custom error message") { }

        XCTAssertEqual(view.message, "Custom error message")
    }

    // MARK: - From AppError Tests

    func testFromAppError_NetworkError() {
        let view = ErrorStateView.from(appError: .noInternetConnection)

        XCTAssertEqual(view.icon, "wifi.exclamationmark")
    }

    func testFromAppError_AuthError() {
        let view = ErrorStateView.from(appError: .notAuthenticated)

        XCTAssertEqual(view.icon, "person.crop.circle.badge.exclamationmark")
    }

    func testFromAppError_DataNotFound() {
        let view = ErrorStateView.from(appError: .dataNotFound)

        XCTAssertEqual(view.icon, "doc.questionmark")
    }

    func testFromAppError_AIError() {
        let view = ErrorStateView.from(appError: .aiServiceUnavailable)

        XCTAssertEqual(view.icon, "brain")
    }

    func testFromAppError_WithRetry() {
        var retried = false
        let view = ErrorStateView.from(appError: .noInternetConnection) {
            retried = true
        }

        XCTAssertNotNil(view.primaryAction)
        view.primaryAction?.action()
        XCTAssertTrue(retried)
    }
}

final class CompactErrorViewTests: XCTestCase {

    func testCompactErrorView_HasMessage() {
        let view = CompactErrorView(message: "Test error", retry: nil)

        XCTAssertEqual(view.message, "Test error")
        XCTAssertNil(view.retry)
    }

    func testCompactErrorView_HasRetry() {
        var called = false
        let view = CompactErrorView(message: "Test", retry: { called = true })

        XCTAssertNotNil(view.retry)
        view.retry?()
        XCTAssertTrue(called)
    }
}

final class ErrorToastViewTests: XCTestCase {

    func testErrorToastView_DefaultValues() {
        let toast = ErrorToastView(message: "Something went wrong")

        XCTAssertEqual(toast.message, "Something went wrong")
        XCTAssertEqual(toast.icon, "exclamationmark.triangle.fill")
    }

    func testErrorToastView_CustomIcon() {
        let toast = ErrorToastView(
            message: "Network error",
            icon: "wifi.exclamationmark",
            iconColor: .red
        )

        XCTAssertEqual(toast.icon, "wifi.exclamationmark")
    }
}

final class ErrorBannerViewTests: XCTestCase {

    func testErrorBannerView_RequiredProperties() {
        let banner = ErrorBannerView(title: "Error", message: "Details")

        XCTAssertEqual(banner.title, "Error")
        XCTAssertEqual(banner.message, "Details")
        XCTAssertNil(banner.onRetry)
        XCTAssertNil(banner.onDismiss)
    }

    func testErrorBannerView_WithActions() {
        var retried = false
        var dismissed = false

        let banner = ErrorBannerView(
            title: "Error",
            message: "Details",
            onRetry: { retried = true },
            onDismiss: { dismissed = true }
        )

        XCTAssertNotNil(banner.onRetry)
        XCTAssertNotNil(banner.onDismiss)

        banner.onRetry?()
        XCTAssertTrue(retried)

        banner.onDismiss?()
        XCTAssertTrue(dismissed)
    }
}
