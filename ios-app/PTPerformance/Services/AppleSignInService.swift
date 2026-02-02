//
//  AppleSignInService.swift
//  PTPerformance
//
//  Auth redesign: Sign in with Apple coordinator using ASAuthorizationController
//

import Foundation
import AuthenticationServices
import CryptoKit
import UIKit

@MainActor
final class AppleSignInService: NSObject, ObservableObject {
    static let shared = AppleSignInService()

    /// The current cryptographic nonce used for the active sign-in request
    private var currentNonce: String?

    /// Continuation for bridging delegate callbacks to async/await
    /// Using MainActor-isolated storage ensures thread-safe access from nonisolated delegate methods
    private var continuation: CheckedContinuation<Void, Error>?

    private let logger = DebugLogger.shared

    override private init() {
        super.init()
        logger.info("AppleSignIn", "AppleSignInService initialized")
    }

    // MARK: - Public API

    /// Initiates Sign in with Apple flow
    /// - Throws: Error if sign-in fails or is cancelled
    func signIn() async throws {
        logger.info("AppleSignIn", "Starting Sign in with Apple flow")

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            self.continuation = cont

            let nonce = randomNonceString()
            self.currentNonce = nonce
            let hashedNonce = sha256(nonce)

            self.logger.diagnostic("AppleSignIn: Generated nonce, presenting authorization sheet")

            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = hashedNonce

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }

    // MARK: - Cryptographic Helpers

    /// Generates a cryptographically secure random nonce string
    /// - Parameter length: The length of the nonce (default 32)
    /// - Returns: A random string suitable for use as a nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    /// Hashes the input string using SHA256
    /// - Parameter input: The string to hash
    /// - Returns: The hex-encoded SHA256 hash
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInService: ASAuthorizationControllerDelegate {

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        let logger = DebugLogger.shared
        logger.info("AppleSignIn", "Authorization completed, processing credential")

        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            logger.error("AppleSignIn", "Invalid credential type received")
            self.continuation?.resume(throwing: AppleSignInError.invalidCredential)
            self.continuation = nil
            return
        }

        guard let idTokenData = appleIDCredential.identityToken,
              let idTokenString = String(data: idTokenData, encoding: .utf8) else {
            logger.error("AppleSignIn", "Missing identity token in credential")
            self.continuation?.resume(throwing: AppleSignInError.missingIdentityToken)
            self.continuation = nil
            return
        }

        guard let nonce = self.currentNonce else {
            logger.error("AppleSignIn", "Nonce was not set for this request")
            self.continuation?.resume(throwing: AppleSignInError.missingNonce)
            self.continuation = nil
            return
        }

        logger.diagnostic("AppleSignIn: Received valid ID token, authenticating with Supabase")

        // Capture continuation before starting async work
        let capturedContinuation = self.continuation
        self.continuation = nil

        Task { @MainActor in
            do {
                // Sign in with Supabase using the Apple ID token
                try await PTSupabaseClient.shared.signInWithApple(idToken: idTokenString, nonce: nonce)
                logger.success("AppleSignIn", "Supabase authentication successful")

                let supabase = PTSupabaseClient.shared
                guard let userId = supabase.currentUser?.id.uuidString,
                      let userEmail = supabase.currentUser?.email else {
                    logger.error("AppleSignIn", "User ID or email missing after Supabase auth")
                    capturedContinuation?.resume(throwing: AppleSignInError.invalidCredential)
                    return
                }

                // Build display name from Apple credential (only available on first sign-in)
                var displayName = ""
                if let fullName = appleIDCredential.fullName {
                    let givenName = fullName.givenName ?? ""
                    let familyName = fullName.familyName ?? ""
                    displayName = [givenName, familyName]
                        .filter { !$0.isEmpty }
                        .joined(separator: " ")
                }

                // Fetch user role first to check if patient record exists
                await supabase.fetchUserRole(userId: userId)

                // If no role found, register as patient (handles first sign-in AND
                // cases where prior registration failed)
                if supabase.userRole == nil {
                    logger.info("AppleSignIn", "No existing role found, registering as patient")
                    let name = displayName.isEmpty
                        ? (userEmail.components(separatedBy: "@").first ?? "Patient")
                        : displayName
                    try? await supabase.registerPatient(
                        userId: userId,
                        email: userEmail,
                        fullName: name,
                        authProvider: "apple"
                    )
                    await supabase.fetchUserRole(userId: userId)
                }

                logger.success("AppleSignIn", "Sign in complete for user: \(userId)")
                capturedContinuation?.resume()
            } catch {
                logger.error("AppleSignIn", "Authentication failed: \(error.localizedDescription)")
                capturedContinuation?.resume(throwing: error)
            }
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let logger = DebugLogger.shared
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                logger.info("AppleSignIn", "User cancelled sign in")
            case .failed:
                logger.error("AppleSignIn", "Authorization failed: \(error.localizedDescription)")
            case .invalidResponse:
                logger.error("AppleSignIn", "Invalid response from Apple")
            case .notHandled:
                logger.error("AppleSignIn", "Authorization not handled")
            case .notInteractive:
                logger.error("AppleSignIn", "Non-interactive authorization failed")
            case .unknown:
                logger.error("AppleSignIn", "Unknown authorization error")
            case .matchedExcludedCredential:
                logger.error("AppleSignIn", "Matched excluded credential")
            case .credentialImport:
                logger.error("AppleSignIn", "Credential import error")
            case .credentialExport:
                logger.error("AppleSignIn", "Credential export error")
            case .preferSignInWithApple:
                logger.info("AppleSignIn", "Prefer Sign in with Apple")
            case .deviceNotConfiguredForPasskeyCreation:
                logger.error("AppleSignIn", "Device not configured for passkey creation")
            @unknown default:
                logger.error("AppleSignIn", "Unrecognized error code: \(authError.code)")
            }
        } else {
            logger.error("AppleSignIn", "Authorization error: \(error.localizedDescription)")
        }
        self.continuation?.resume(throwing: error)
        self.continuation = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the key window for presenting the Apple Sign-in sheet
        // This method is called on main thread by the framework, safe to access UIApplication here
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }) else {
            return UIWindow()
        }
        return window
    }
}

// MARK: - Error Types

enum AppleSignInError: LocalizedError {
    case invalidCredential
    case missingIdentityToken
    case missingNonce

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid Apple ID credential received."
        case .missingIdentityToken:
            return "Unable to retrieve identity token from Apple."
        case .missingNonce:
            return "Authentication nonce was not set. Please try again."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidCredential:
            return "Please try signing in with Apple again. If the problem persists, check your Apple ID settings."
        case .missingIdentityToken:
            return "There was a problem communicating with Apple. Please try again."
        case .missingNonce:
            return "Please close and reopen the app, then try signing in again."
        }
    }
}
