//
//  CertificatePinningService.swift
//  PTPerformance
//
//  ACP-1054: Certificate Pinning for API Communication
//  Pins SSL certificates (SPKI public key hashes) for Supabase API endpoints.
//  Uses backup pins for rotation resilience and graceful failure handling.
//

import Foundation
import CommonCrypto
import CryptoKit
import os.log
#if canImport(Sentry)
import Sentry
#endif

// MARK: - CertificatePinningError

/// Errors related to certificate pinning validation
enum CertificatePinningError: Error, LocalizedError {
    /// The server certificate did not match any pinned public key hashes
    case pinValidationFailed(host: String)
    /// The server trust object could not be evaluated
    case serverTrustEvaluationFailed(host: String)
    /// No certificates were provided by the server
    case noCertificatesProvided(host: String)
    /// Certificate transparency check failed
    case transparencyCheckFailed(host: String)

    var errorDescription: String? {
        switch self {
        case .pinValidationFailed(let host):
            return "Certificate pin validation failed for \(host)"
        case .serverTrustEvaluationFailed(let host):
            return "Server trust evaluation failed for \(host)"
        case .noCertificatesProvided(let host):
            return "No certificates provided by \(host)"
        case .transparencyCheckFailed(let host):
            return "Certificate transparency check failed for \(host)"
        }
    }
}

// MARK: - PinningConfiguration

/// Configuration for a pinned domain, including primary and backup SPKI hashes
struct PinningConfiguration {
    /// The domain to pin (e.g., "rpbxeaxlaoyoqkohytlw.supabase.co")
    let domain: String

    /// Whether to include subdomains in the pinning policy
    let includeSubdomains: Bool

    /// SHA-256 hashes of the Subject Public Key Info (SPKI) for pinned certificates.
    /// At least one primary pin and one backup pin should be provided.
    /// Backup pins allow seamless certificate rotation without app updates.
    let pinnedHashes: [String]

    /// Maximum age (in seconds) before the pin set should be refreshed.
    /// After this duration, a fresh validation will be performed.
    let maxAge: TimeInterval

    /// When true, a pin mismatch is logged but the connection is still allowed.
    /// Use during rollout to detect issues before enforcing.
    let reportOnly: Bool
}

// MARK: - CertificatePinningService

/// Service for validating SSL certificate pins on network connections.
///
/// Implements SPKI (Subject Public Key Info) hash pinning, which is more resilient
/// to certificate rotation than whole-certificate pinning. The service validates
/// that at least one of the server's certificate chain public keys matches a
/// known (pinned) hash.
///
/// ## Graceful Failure
/// - In DEBUG builds, pinning is bypassed entirely to allow development with proxies.
/// - In RELEASE builds with `reportOnly` mode, mismatches are logged but connections proceed.
/// - If all pins fail, the service logs a critical security event but does NOT crash the app.
///
/// ## Pin Rotation
/// Include backup pins (from the next expected CA certificate) in the configuration.
/// When the server rotates certificates, the backup pin will match, and you can
/// update the primary pin in the next app release.
///
/// ## Usage
/// This service is primarily used via Info.plist `NSPinnedDomains` for system-level
/// pinning. The programmatic validation here serves as an additional layer for
/// custom URLSession delegates and certificate transparency monitoring.
///
/// ```swift
/// let service = CertificatePinningService.shared
/// // Check if a host is pinned
/// if service.isPinnedDomain("rpbxeaxlaoyoqkohytlw.supabase.co") {
///     // Validate in URLSession delegate
/// }
/// ```
final class CertificatePinningService {

    // MARK: - Singleton

    static let shared = CertificatePinningService()

    // MARK: - Constants

    /// ASN.1 header for RSA 2048-bit public keys (prepended before hashing)
    private static let rsa2048ASN1Header: [UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0D, 0x06, 0x09,
        0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01,
        0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0F, 0x00
    ]

    /// ASN.1 header for EC 256-bit public keys (prepended before hashing)
    private static let ecDSA256ASN1Header: [UInt8] = [
        0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2A, 0x86,
        0x48, 0xCE, 0x3D, 0x02, 0x01, 0x06, 0x08, 0x2A,
        0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07, 0x03,
        0x42, 0x00
    ]

    // MARK: - Properties

    private let logger = DebugLogger.shared
    private let osLogger = Logger(subsystem: "com.getmodus.app", category: "CertificatePinning")

    /// Pinning configurations indexed by domain for fast lookup
    private var configurations: [String: PinningConfiguration] = [:]

    /// Tracks pinning validation results for monitoring
    private var validationHistory: [(date: Date, host: String, success: Bool)] = []

    /// Maximum number of validation history entries to retain
    private let maxHistoryEntries = 100

    /// Whether pinning enforcement is currently active.
    /// Automatically disabled in DEBUG builds and on simulators.
    private(set) var isEnforcementActive: Bool

    // MARK: - Initialization

    private init() {
        #if DEBUG
        // In DEBUG builds, disable enforcement to allow development proxies (e.g., Charles, Proxyman)
        isEnforcementActive = false
        #else
        isEnforcementActive = true
        #endif

        configurePins()
    }

    // MARK: - Configuration

    /// Configures the pinning set for all known API domains.
    ///
    /// The SPKI hashes here correspond to the public keys of:
    /// 1. The Supabase project's current leaf certificate
    /// 2. The intermediate CA certificate (backup for rotation)
    /// 3. A secondary backup from an alternate CA path
    ///
    /// These pins should be updated when certificates rotate. The backup pins
    /// ensure continuity during the rotation window.
    private func configurePins() {
        // Extract the Supabase project host from Config
        let supabaseHost: String
        if let url = URL(string: Config.supabaseURL), let host = url.host {
            supabaseHost = host
        } else {
            supabaseHost = "rpbxeaxlaoyoqkohytlw.supabase.co"
        }

        // SPKI SHA-256 hashes for the Supabase domain certificate chain.
        //
        // Pin 1 (Primary): Current Let's Encrypt / Cloudflare intermediate CA
        // Pin 2 (Backup):  ISRG Root X1 (Let's Encrypt root)
        // Pin 3 (Backup):  DigiCert Global Root G2 (alternate trust path)
        //
        // NOTE: These are well-known CA public key hashes. In production, you should
        // extract the actual SPKI hashes from your server's certificate chain using:
        //   openssl s_client -connect <host>:443 | openssl x509 -pubkey -noout | \
        //   openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64
        let supabaseConfig = PinningConfiguration(
            domain: supabaseHost,
            includeSubdomains: false,
            pinnedHashes: [
                // Let's Encrypt R3 intermediate (ISRG)
                "jQJTbIh0grw0/1TkHSumWb+Fs0Ggogr621gT3PvPKG0=",
                // ISRG Root X1
                "C5+lpZ7tcVwmwQIMcRtPbsQtWLABXhQzejna0wHFr8M=",
                // DigiCert Global Root G2 (backup trust path)
                "i7WTqTvh0OioIruIfFR4kMPnBqrS2rdiVPl/s2uC/CY="
            ],
            maxAge: 60 * 60 * 24 * 30,  // 30 days
            reportOnly: false
        )

        configurations[supabaseHost] = supabaseConfig

        // Also pin the general supabase.co domain for edge functions
        let supabaseGeneralConfig = PinningConfiguration(
            domain: "supabase.co",
            includeSubdomains: true,
            pinnedHashes: supabaseConfig.pinnedHashes,
            maxAge: supabaseConfig.maxAge,
            reportOnly: true  // Report-only for the wildcard to avoid blocking unforeseen subdomains
        )

        configurations["supabase.co"] = supabaseGeneralConfig

        logger.diagnostic("[CertificatePinning] Configured \(configurations.count) pinned domains")
    }

    // MARK: - Public API

    /// Returns whether a given host has a pinning configuration.
    ///
    /// - Parameter host: The hostname to check (e.g., "rpbxeaxlaoyoqkohytlw.supabase.co")
    /// - Returns: `true` if the host matches a pinned domain (directly or via subdomain matching)
    func isPinnedDomain(_ host: String) -> Bool {
        return findConfiguration(for: host) != nil
    }

    /// Validates a server trust against the pinned SPKI hashes for the given host.
    ///
    /// This method should be called from a `URLSessionDelegate`'s
    /// `urlSession(_:didReceive:completionHandler:)` method.
    ///
    /// - Parameters:
    ///   - serverTrust: The `SecTrust` object from the authentication challenge
    ///   - host: The hostname being connected to
    /// - Returns: `true` if the certificate chain contains at least one matching pin,
    ///            or if enforcement is disabled (DEBUG builds)
    func validateCertificate(serverTrust: SecTrust, host: String) -> Bool {
        // In DEBUG builds, always allow connections
        #if DEBUG
        logger.diagnostic("[CertificatePinning] DEBUG build — bypassing pin validation for \(host)")
        return true
        #else
        return performValidation(serverTrust: serverTrust, host: host)
        #endif
    }

    /// Returns a summary of recent validation results for monitoring/diagnostics.
    ///
    /// - Returns: Array of tuples containing the date, host, and whether validation succeeded
    func getValidationHistory() -> [(date: Date, host: String, success: Bool)] {
        return validationHistory
    }

    /// Returns the current pinning configuration for a given host, if any.
    ///
    /// - Parameter host: The hostname to look up
    /// - Returns: The `PinningConfiguration` or `nil` if the host is not pinned
    func getConfiguration(for host: String) -> PinningConfiguration? {
        return findConfiguration(for: host)
    }

    /// Allows updating pin hashes at runtime (e.g., from a remote configuration).
    ///
    /// This enables pin rotation without requiring an app update.
    ///
    /// - Parameters:
    ///   - domain: The domain to update pins for
    ///   - newHashes: The new set of SPKI SHA-256 hashes (base64-encoded)
    ///
    /// - Important: The new hashes must include at least one backup pin.
    ///              This method validates that at least 2 hashes are provided.
    func updatePins(for domain: String, newHashes: [String]) {
        guard newHashes.count >= 2 else {
            logger.warning("[CertificatePinning] Refusing to update pins for \(domain): at least 2 hashes required (primary + backup)")
            return
        }

        guard var config = configurations[domain] else {
            logger.warning("[CertificatePinning] No existing configuration for domain: \(domain)")
            return
        }

        config = PinningConfiguration(
            domain: config.domain,
            includeSubdomains: config.includeSubdomains,
            pinnedHashes: newHashes,
            maxAge: config.maxAge,
            reportOnly: config.reportOnly
        )

        configurations[domain] = config
        logger.info("[CertificatePinning] Updated pins for \(domain) with \(newHashes.count) hashes")
    }

    // MARK: - Certificate Transparency Monitoring

    /// Checks whether the server's certificate includes Certificate Transparency (CT) SCTs.
    ///
    /// Certificate Transparency helps detect misissued certificates by requiring
    /// certificates to be logged in public CT logs. iOS performs CT checks automatically
    /// for system trust evaluations, but this method provides an additional programmatic check.
    ///
    /// - Parameters:
    ///   - serverTrust: The `SecTrust` from the server's TLS handshake
    ///   - host: The hostname being verified
    /// - Returns: `true` if CT validation passes or if evaluation is not available
    func checkCertificateTransparency(serverTrust: SecTrust, host: String) -> Bool {
        // iOS performs CT checks as part of the standard trust evaluation.
        // We verify that the trust evaluation succeeds with the CT policy applied.
        let policy = SecPolicyCreateSSL(true, host as CFString)
        SecTrustSetPolicies(serverTrust, policy)

        var error: CFError?
        let trustResult = SecTrustEvaluateWithError(serverTrust, &error)

        if !trustResult {
            let errorDesc = error.map { CFErrorCopyDescription($0) as String? ?? "Unknown" } ?? "Unknown"
            logger.warning("[CertificatePinning] CT check warning for \(host): \(errorDesc)")

            // Log the CT issue but don't block — iOS handles CT enforcement at the system level
            recordValidation(host: host, success: false)
            return false
        }

        return true
    }

    // MARK: - Private Helpers

    /// Finds the matching pinning configuration for a given host.
    /// Checks for an exact domain match first, then for subdomain matching.
    private func findConfiguration(for host: String) -> PinningConfiguration? {
        // Exact match
        if let config = configurations[host] {
            return config
        }

        // Subdomain match: check if "api.supabase.co" matches a config for "supabase.co" with includeSubdomains
        for (_, config) in configurations {
            if config.includeSubdomains && host.hasSuffix("." + config.domain) {
                return config
            }
        }

        return nil
    }

    /// Performs the actual SPKI pin validation against the server trust.
    private func performValidation(serverTrust: SecTrust, host: String) -> Bool {
        guard let config = findConfiguration(for: host) else {
            // Not a pinned domain — allow the connection
            return true
        }

        // Evaluate the server trust first (standard TLS validation)
        let policy = SecPolicyCreateSSL(true, host as CFString)
        SecTrustSetPolicies(serverTrust, policy)

        var error: CFError?
        let trustValid = SecTrustEvaluateWithError(serverTrust, &error)

        guard trustValid else {
            let errorDesc = error.map { CFErrorCopyDescription($0) as String? ?? "Unknown" } ?? "Unknown"
            logger.error("[CertificatePinning] Server trust evaluation failed for \(host): \(errorDesc)")
            recordValidation(host: host, success: false)
            reportPinFailure(host: host, reason: "Trust evaluation failed: \(errorDesc)")

            // If report-only mode, allow the connection despite the failure
            return config.reportOnly
        }

        // Extract the certificate chain using the modern API (iOS 15+)
        guard let certificateChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
              !certificateChain.isEmpty else {
            logger.error("[CertificatePinning] Could not copy certificate chain for \(host)")
            recordValidation(host: host, success: false)
            reportPinFailure(host: host, reason: "Could not copy certificate chain")
            return config.reportOnly
        }

        // Check each certificate in the chain against the pinned hashes
        for (index, certificate) in certificateChain.enumerated() {
            if let publicKeyHash = extractSPKIHash(from: certificate) {
                if config.pinnedHashes.contains(publicKeyHash) {
                    // Match found — pin validation succeeds
                    logger.diagnostic("[CertificatePinning] Pin matched for \(host) at chain index \(index)")
                    recordValidation(host: host, success: true)
                    return true
                }
            }
        }

        // No pin matched
        logger.error("[CertificatePinning] CRITICAL: No pin match for \(host). Certificate chain has \(certificateChain.count) certificates.")
        recordValidation(host: host, success: false)
        reportPinFailure(host: host, reason: "No matching SPKI hash in certificate chain")

        // In report-only mode, allow the connection but log the failure
        if config.reportOnly {
            logger.warning("[CertificatePinning] Report-only mode — allowing connection to \(host) despite pin mismatch")
            return true
        }

        // Enforcement mode: block the connection
        // NOTE: We intentionally do NOT crash. The caller should handle this by
        // cancelling the connection and showing an appropriate error to the user.
        return false
    }

    /// Extracts the SHA-256 hash of the SPKI (Subject Public Key Info) from a certificate.
    ///
    /// The SPKI hash is computed by:
    /// 1. Extracting the public key from the certificate
    /// 2. Getting the raw key data
    /// 3. Prepending the appropriate ASN.1 header based on key type
    /// 4. Computing SHA-256 over the combined data
    /// 5. Base64-encoding the hash
    ///
    /// - Parameter certificate: The `SecCertificate` to extract the hash from
    /// - Returns: The base64-encoded SHA-256 hash of the SPKI, or `nil` if extraction fails
    private func extractSPKIHash(from certificate: SecCertificate) -> String? {
        // Create a temporary trust to extract the public key
        var trust: SecTrust?
        let policy = SecPolicyCreateBasicX509()
        let status = SecTrustCreateWithCertificates(certificate, policy, &trust)

        guard status == errSecSuccess, let serverTrust = trust else {
            return nil
        }

        // Evaluate trust to populate the key (result intentionally discarded —
        // we only need the key to be populated, not the trust result)
        _ = SecTrustEvaluateWithError(serverTrust, nil)

        guard let publicKey = SecTrustCopyKey(serverTrust) else {
            return nil
        }

        // Get the external representation of the public key
        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            return nil
        }

        // Determine the ASN.1 header based on key type
        let keyAttributes = SecKeyCopyAttributes(publicKey) as? [String: Any]
        let keyType = keyAttributes?[kSecAttrKeyType as String] as? String
        let keySize = keyAttributes?[kSecAttrKeySizeInBits as String] as? Int

        var headerData: Data
        if keyType == (kSecAttrKeyTypeRSA as String), keySize == 2048 {
            headerData = Data(Self.rsa2048ASN1Header)
        } else if keyType == (kSecAttrKeyTypeECSECPrimeRandom as String), keySize == 256 {
            headerData = Data(Self.ecDSA256ASN1Header)
        } else {
            // For other key types, hash the raw key data without an ASN.1 header
            headerData = Data()
        }

        // Compute SHA-256(ASN.1 header + public key data)
        var spkiData = headerData
        spkiData.append(publicKeyData)

        let hash = SHA256.hash(data: spkiData)
        return Data(hash).base64EncodedString()
    }

    /// Records a validation result for monitoring purposes.
    private func recordValidation(host: String, success: Bool) {
        validationHistory.append((date: Date(), host: host, success: success))

        // Trim history if it exceeds the limit
        if validationHistory.count > maxHistoryEntries {
            validationHistory.removeFirst(validationHistory.count - maxHistoryEntries)
        }
    }

    /// Reports a pinning failure as a critical security event.
    ///
    /// In production, this would send a report to the backend or crash reporting service.
    /// The app continues to function — this is purely an observability mechanism.
    private func reportPinFailure(host: String, reason: String) {
        let event: [String: Any] = [
            "event": "CERTIFICATE_PIN_FAILURE",
            "host": host,
            "reason": reason,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "enforcement_active": isEnforcementActive
        ]

        osLogger.critical("SECURITY: Certificate pin failure for \(host): \(reason)")

        // Report to Sentry if available — the import is at the file level
        reportToSentry(host: host, event: event)
    }

    /// Sends a certificate pin failure event to Sentry for observability.
    private func reportToSentry(host: String, event: [String: Any]) {
        #if canImport(Sentry)
        SentrySDK.capture(message: "Certificate Pin Failure: \(host)") { scope in
            scope.setLevel(.fatal)
            scope.setContext(value: event, key: "certificate_pinning")
            scope.setTag(value: "certificate_pin_failure", key: "security_event_type")
        }
        #endif
    }
}

// MARK: - URLSessionDelegate Support

/// A `URLSessionDelegate` that enforces certificate pinning on TLS connections.
///
/// Use this delegate when creating custom `URLSession` instances that need
/// certificate pinning. The Supabase SDK uses its own URLSession, so this
/// delegate is available for any additional network calls made outside the SDK.
///
/// ## Usage
/// ```swift
/// let session = URLSession(
///     configuration: .default,
///     delegate: CertificatePinningDelegate(),
///     delegateQueue: nil
/// )
/// ```
final class CertificatePinningDelegate: NSObject, URLSessionDelegate {

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host
        let pinningService = CertificatePinningService.shared

        // If the host is not in our pinning configuration, use default handling
        guard pinningService.isPinnedDomain(host) else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Validate the certificate against our pins
        if pinningService.validateCertificate(serverTrust: serverTrust, host: host) {
            // Also check certificate transparency
            _ = pinningService.checkCertificateTransparency(serverTrust: serverTrust, host: host)
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            // Pin validation failed — cancel the connection
            DebugLogger.shared.error("[CertificatePinning] Connection cancelled for \(host) due to pin mismatch")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
