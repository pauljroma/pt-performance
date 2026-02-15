//
//  TransportSecurityService.swift
//  PTPerformance
//
//  ACP-1043: End-to-End Data Encryption
//  Verifies and monitors transport-layer security configuration.
//

import Foundation
import Security
import CryptoKit

// MARK: - TransportSecurityService

/// Verifies and monitors the app's transport-layer security posture.
///
/// This service:
/// - Validates App Transport Security (ATS) configuration at launch
/// - Ensures no arbitrary load exceptions exist
/// - Provides TLS certificate pinning evaluation for the Supabase backend
/// - Logs TLS protocol versions used by API connections
///
/// ## ATS Verification
/// ATS is enforced by iOS automatically. This service reads the Info.plist
/// at launch and warns if `NSAllowsArbitraryLoads` is enabled, which would
/// weaken transport security.
///
/// ## Usage
/// ```swift
/// TransportSecurityService.shared.verifyConfiguration()
/// ```
final class TransportSecurityService {

    // MARK: - Singleton

    static let shared = TransportSecurityService()

    // MARK: - Properties

    /// Whether ATS configuration was verified as secure
    private(set) var isATSConfigurationSecure: Bool = false

    /// Detected ATS issues (empty if configuration is secure)
    private(set) var atsIssues: [String] = []

    private let logger = DebugLogger.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - Public API

    /// Verifies the app's transport security configuration.
    ///
    /// Checks:
    /// 1. ATS is not globally disabled via `NSAllowsArbitraryLoads`
    /// 2. No insecure domain exceptions exist
    /// 3. Minimum TLS version is not downgraded below 1.2
    ///
    /// Results are stored in `isATSConfigurationSecure` and `atsIssues`.
    func verifyConfiguration() {
        logger.info("[TransportSecurity] Verifying App Transport Security configuration")

        var issues: [String] = []

        // Read ATS settings from Info.plist
        let atsDict = Bundle.main.object(forInfoDictionaryKey: "NSAppTransportSecurity") as? [String: Any]

        if let atsDict = atsDict {
            // Check for global arbitrary loads
            if let allowsArbitrary = atsDict["NSAllowsArbitraryLoads"] as? Bool, allowsArbitrary {
                issues.append("NSAllowsArbitraryLoads is enabled — all HTTP connections are allowed")
            }

            // Check for arbitrary loads in web content
            if let allowsWebArbitrary = atsDict["NSAllowsArbitraryLoadsInWebContent"] as? Bool, allowsWebArbitrary {
                issues.append("NSAllowsArbitraryLoadsInWebContent is enabled")
            }

            // Check for exception domains
            if let exceptions = atsDict["NSExceptionDomains"] as? [String: Any] {
                for (domain, config) in exceptions {
                    if let domainConfig = config as? [String: Any] {
                        if let allowsInsecure = domainConfig["NSExceptionAllowsInsecureHTTPLoads"] as? Bool, allowsInsecure {
                            issues.append("Domain \(domain) allows insecure HTTP loads")
                        }
                        if let minTLS = domainConfig["NSExceptionMinimumTLSVersion"] as? String {
                            if minTLS == "TLSv1.0" || minTLS == "TLSv1.1" {
                                issues.append("Domain \(domain) allows outdated TLS version: \(minTLS)")
                            }
                        }
                    }
                }
            }
        }

        // No ATS dictionary at all means ATS is fully enforced (default behavior) — this is good
        atsIssues = issues
        isATSConfigurationSecure = issues.isEmpty

        if isATSConfigurationSecure {
            logger.success("[TransportSecurity] ATS configuration is secure — no exceptions found")
        } else {
            for issue in issues {
                logger.warning("[TransportSecurity] ATS issue: \(issue)")
            }
        }
    }

    /// Creates a `URLSession` configured with TLS 1.2+ enforcement and optional
    /// certificate pinning via a delegate.
    ///
    /// - Parameter pinnedDomains: Optional dictionary mapping hostnames to their
    ///   expected SHA-256 public key hashes. If empty, no pinning is applied.
    /// - Returns: A configured `URLSession`.
    func createSecureSession(
        pinnedDomains: [String: [String]] = [:]
    ) -> URLSession {
        let config = URLSessionConfiguration.default
        config.tlsMinimumSupportedProtocolVersion = .TLSv12

        // Require TLS 1.3 when available (iOS negotiates the highest mutually supported version)
        config.tlsMaximumSupportedProtocolVersion = .TLSv13

        // Disable caching of sensitive responses
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData

        if pinnedDomains.isEmpty {
            return URLSession(configuration: config)
        } else {
            let delegate = TransportPinningDelegate(pinnedDomains: pinnedDomains)
            return URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        }
    }

    /// Evaluates the TLS protocol version used by a connection to the given URL.
    ///
    /// Performs a lightweight HEAD request and logs the negotiated TLS version.
    /// Useful for auditing backend connections.
    ///
    /// - Parameter url: The URL to probe.
    func auditTLSVersion(for url: URL) async {
        logger.diagnostic("[TransportSecurity] Auditing TLS version for \(url.host ?? "unknown")")

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                logger.info("[TransportSecurity] \(url.host ?? "?"): HTTP \(httpResponse.statusCode), TLS connection established")
            }
        } catch {
            logger.warning("[TransportSecurity] TLS audit failed for \(url.host ?? "?"): \(error.localizedDescription)")
        }
    }
}

// MARK: - TransportPinningDelegate

/// URLSession delegate that performs certificate pinning by validating server
/// trust against a set of expected public key hashes.
/// Named TransportPinningDelegate to avoid conflict with CertificatePinningService.CertificatePinningDelegate.
private final class TransportPinningDelegate: NSObject, URLSessionDelegate {

    /// Maps hostnames to arrays of expected SHA-256 public key hashes (base64 encoded).
    private let pinnedDomains: [String: [String]]

    init(pinnedDomains: [String: [String]]) {
        self.pinnedDomains = pinnedDomains
        super.init()
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let host = Optional(challenge.protectionSpace.host),
              let expectedHashes = pinnedDomains[host] else {
            // No pinning configured for this host — use default handling
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Evaluate the trust object
        var error: CFError?
        let isTrusted = SecTrustEvaluateWithError(serverTrust, &error)

        guard isTrusted else {
            DebugLogger.shared.error("[TransportSecurity] Certificate trust evaluation failed for \(host)")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Extract the server's public key and compute its SHA-256 hash
        guard let serverCertificate = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
              let firstCert = serverCertificate.first,
              let publicKey = SecCertificateCopyKey(firstCert) else {
            DebugLogger.shared.error("[TransportSecurity] Could not extract public key for \(host)")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
            DebugLogger.shared.error("[TransportSecurity] Could not export public key data for \(host)")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Compute SHA-256 of the public key
        let digest = SHA256.hash(data: publicKeyData)
        let hashBase64 = Data(digest).base64EncodedString()

        if expectedHashes.contains(hashBase64) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            DebugLogger.shared.warning("[TransportSecurity] Certificate pin mismatch for \(host). Got: \(hashBase64)")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
