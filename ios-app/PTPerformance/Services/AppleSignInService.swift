//
//  AppleSignInService.swift
//  PTPerformance
//
//  Auth redesign: Sign in with Apple coordinator using ASAuthorizationController
//

import Foundation
import AuthenticationServices
import CryptoKit

@MainActor
final class AppleSignInService: NSObject, ObservableObject {
    static let shared = AppleSignInService()

    /// The current cryptographic nonce used for the active sign-in request
    private var currentNonce: String?

    /// Continuation for bridging delegate callbacks to async/await
    /// Using MainActor-isolated storage ensures thread-safe access from nonisolated delegate methods
    private var continuation: CheckedContinuation<Void, Error>?

    override private init() {
        super.init()
    }

    // MARK: - Public API

    /// Initiates Sign in with Apple flow
    /// - Throws: Error if sign-in fails or is cancelled
    func signIn() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            self.continuation = cont

            let nonce = randomNonceString()
            self.currentNonce = nonce
            let hashedNonce = sha256(nonce)

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
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            self.continuation?.resume(throwing: AppleSignInError.invalidCredential)
            self.continuation = nil
            return
        }

        guard let idTokenData = appleIDCredential.identityToken,
              let idTokenString = String(data: idTokenData, encoding: .utf8) else {
            self.continuation?.resume(throwing: AppleSignInError.missingIdentityToken)
            self.continuation = nil
            return
        }

        guard let nonce = self.currentNonce else {
            self.continuation?.resume(throwing: AppleSignInError.missingNonce)
            self.continuation = nil
            return
        }

        // Capture continuation before starting async work
        let capturedContinuation = self.continuation
        self.continuation = nil

        Task { @MainActor [weak self] in
            do {
                // Sign in with Supabase using the Apple ID token
                try await PTSupabaseClient.shared.signInWithApple(idToken: idTokenString, nonce: nonce)

                let supabase = PTSupabaseClient.shared
                guard let userId = supabase.currentUser?.id.uuidString,
                      let userEmail = supabase.currentUser?.email else {
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

                capturedContinuation?.resume()
            } catch {
                capturedContinuation?.resume(throwing: error)
            }
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
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
}
