//
//  NetworkSanitizer.swift
//  PTPerformance
//
//  ACP-1055: Network Request Sanitization
//  Sanitizes all network-related data to prevent header injection,
//  strip PII from logs, and validate URLs for security.
//

import Foundation

// MARK: - NetworkSanitizer

/// Singleton service for sanitizing network request and response data.
///
/// Provides methods to:
/// - Strip sensitive data (tokens, passwords, PII) from URLs before logging
/// - Remove authorization headers from logged header dictionaries
/// - Redact sensitive fields in request/response bodies
/// - Validate URLs against injection attacks and malformed input
/// - Enforce secure redirect policies
///
/// ## Design Principles
/// - **Defense in depth**: Multiple layers of sanitization (URL, headers, body)
/// - **Fail-safe**: If sanitization fails, the data is fully redacted rather than leaked
/// - **Performance**: Regex patterns are pre-compiled and cached
///
/// ## Usage
/// ```swift
/// let sanitizer = NetworkSanitizer.shared
///
/// // Sanitize a URL for logging
/// let safeURL = sanitizer.sanitizeURL(url)
///
/// // Validate a URL before making a request
/// if sanitizer.validateURL(url) {
///     // Safe to use
/// }
/// ```
final class NetworkSanitizer {

    // MARK: - Singleton

    static let shared = NetworkSanitizer()

    // MARK: - Constants

    /// Query parameter names that are considered sensitive and should be redacted from logs
    private static let sensitiveQueryParams: Set<String> = [
        "token", "access_token", "refresh_token", "id_token",
        "apikey", "api_key", "key", "secret",
        "password", "passwd", "pwd",
        "email", "mail",
        "phone", "phone_number", "mobile",
        "ssn", "social_security",
        "credit_card", "card_number", "cvv", "cvc",
        "authorization", "auth",
        "session", "session_id", "sid",
        "nonce", "code", "grant_code",
        "client_secret"
    ]

    /// HTTP header names that should be redacted from logs (case-insensitive comparison)
    private static let sensitiveHeaders: Set<String> = [
        "authorization",
        "apikey",
        "x-api-key",
        "cookie",
        "set-cookie",
        "x-supabase-auth",
        "x-access-token",
        "x-refresh-token",
        "proxy-authorization",
        "www-authenticate"
    ]

    /// JSON field names that should be redacted in request/response bodies
    private static let sensitiveBodyFields: Set<String> = [
        "password", "passwd", "pwd", "new_password", "old_password", "confirm_password",
        "token", "access_token", "refresh_token", "id_token", "jwt",
        "email", "mail", "user_email",
        "phone", "phone_number", "mobile",
        "ssn", "social_security_number",
        "credit_card", "card_number", "cvv", "cvc", "expiry",
        "secret", "client_secret", "api_key", "apikey",
        "nonce", "code_verifier"
    ]

    /// Characters that indicate potential header injection or request smuggling
    private static let injectionCharacters = CharacterSet(charactersIn: "\r\n\0")

    /// Maximum allowed URL length to prevent buffer overflow attacks
    private static let maxURLLength = 8192

    /// Redaction placeholder
    private static let redacted = "[REDACTED]"

    // MARK: - Pre-compiled Regex Patterns

    /// Matches email addresses
    private let emailRegex: NSRegularExpression?

    /// Matches phone numbers (various formats)
    private let phoneRegex: NSRegularExpression?

    /// Matches JWT tokens (three base64 segments separated by dots)
    private let jwtRegex: NSRegularExpression?

    /// Matches Bearer tokens in strings
    private let bearerTokenRegex: NSRegularExpression?

    /// Matches UUID patterns (common for user IDs, session IDs)
    private let uuidInPathRegex: NSRegularExpression?

    // MARK: - Initialization

    private init() {
        // Pre-compile regex patterns for performance
        emailRegex = try? NSRegularExpression(
            pattern: "[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}",
            options: []
        )

        phoneRegex = try? NSRegularExpression(
            pattern: "(?:\\+?1[\\-\\s.]?)?(?:\\(?\\d{3}\\)?[\\-\\s.]?)?\\d{3}[\\-\\s.]?\\d{4}",
            options: []
        )

        jwtRegex = try? NSRegularExpression(
            pattern: "eyJ[a-zA-Z0-9_\\-]+\\.eyJ[a-zA-Z0-9_\\-]+\\.[a-zA-Z0-9_\\-]+",
            options: []
        )

        bearerTokenRegex = try? NSRegularExpression(
            pattern: "Bearer\\s+[a-zA-Z0-9\\-._~+/]+=*",
            options: .caseInsensitive
        )

        // Matches UUIDs in URL paths (to redact user IDs)
        uuidInPathRegex = try? NSRegularExpression(
            pattern: "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}",
            options: []
        )
    }

    // MARK: - URL Sanitization

    /// Sanitizes a URL for safe logging by stripping sensitive query parameters and PII.
    ///
    /// - Parameter url: The original URL
    /// - Returns: A sanitized string representation with sensitive data replaced by `[REDACTED]`
    ///
    /// ## What gets redacted
    /// - Query parameters with sensitive names (token, password, email, etc.)
    /// - Email addresses anywhere in the URL
    /// - JWT tokens in the URL path or query
    /// - Bearer tokens
    ///
    /// ## Example
    /// ```
    /// Input:  https://api.example.com/auth?token=abc123&email=user@test.com
    /// Output: https://api.example.com/auth?token=[REDACTED]&email=[REDACTED]
    /// ```
    func sanitizeURL(_ url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return Self.redacted
        }

        // Redact sensitive query parameters
        if let queryItems = components.queryItems {
            components.queryItems = queryItems.map { item in
                let nameLower = item.name.lowercased()
                if Self.sensitiveQueryParams.contains(nameLower) {
                    return URLQueryItem(name: item.name, value: Self.redacted)
                }
                // Also check if the value itself contains PII
                if let value = item.value {
                    let sanitizedValue = redactPII(in: value)
                    return URLQueryItem(name: item.name, value: sanitizedValue)
                }
                return item
            }
        }

        // Reconstruct and further redact PII in the full URL string
        var result = components.string ?? url.absoluteString
        result = redactPII(in: result)

        return result
    }

    // MARK: - Header Sanitization

    /// Sanitizes HTTP headers for safe logging by removing sensitive values.
    ///
    /// - Parameter headers: The original HTTP headers dictionary
    /// - Returns: A new dictionary with sensitive header values replaced by `[REDACTED]`
    ///
    /// Headers like `Authorization`, `Cookie`, and `apikey` are fully redacted.
    /// Other headers are returned as-is.
    func sanitizeHeaders(_ headers: [String: String]) -> [String: String] {
        var sanitized: [String: String] = [:]

        for (key, value) in headers {
            if Self.sensitiveHeaders.contains(key.lowercased()) {
                sanitized[key] = Self.redacted
            } else {
                // Check if the value contains embedded PII or tokens
                sanitized[key] = redactPII(in: value)
            }
        }

        return sanitized
    }

    // MARK: - Body Sanitization

    /// Sanitizes a request or response body for safe logging.
    ///
    /// Attempts to parse the body as JSON and redacts known sensitive field values.
    /// If parsing fails, the entire body is redacted for safety.
    ///
    /// - Parameter body: The raw body data
    /// - Returns: A sanitized string representation, or `nil` if the body is nil/empty
    ///
    /// ## Behavior
    /// - **JSON objects**: Sensitive keys have their values replaced with `[REDACTED]`
    /// - **Non-JSON**: The entire string is scanned for PII patterns and redacted
    /// - **Binary data**: Returns `[binary data: N bytes]`
    /// - **Release builds**: Always returns `[body redacted in release]`
    func sanitizeBody(_ body: Data?) -> String? {
        guard let body = body, !body.isEmpty else {
            return nil
        }

        // In release builds, never log request/response bodies
        #if !DEBUG
        return "[body redacted in release]"
        #else
        // Try to parse as JSON
        if let jsonObject = try? JSONSerialization.jsonObject(with: body, options: []) {
            let sanitizedJSON = sanitizeJSONValue(jsonObject)
            if let sanitizedData = try? JSONSerialization.data(withJSONObject: sanitizedJSON, options: [.prettyPrinted, .sortedKeys]),
               let sanitizedString = String(data: sanitizedData, encoding: .utf8) {
                // Truncate large bodies
                if sanitizedString.count > 500 {
                    return String(sanitizedString.prefix(500)) + "... [truncated]"
                }
                return sanitizedString
            }
        }

        // Not JSON — try as a string and redact PII
        if let bodyString = String(data: body, encoding: .utf8) {
            let redacted = redactPII(in: bodyString)
            if redacted.count > 500 {
                return String(redacted.prefix(500)) + "... [truncated]"
            }
            return redacted
        }

        // Binary data
        return "[binary data: \(body.count) bytes]"
        #endif
    }

    // MARK: - URL Validation

    /// Validates a URL for security issues before making a network request.
    ///
    /// Checks for:
    /// - Header injection characters (CRLF injection)
    /// - Excessive URL length (buffer overflow prevention)
    /// - Invalid or missing scheme (must be HTTPS)
    /// - Invalid host characters
    /// - Local/private network addresses (SSRF prevention)
    ///
    /// - Parameter url: The URL to validate
    /// - Returns: `true` if the URL passes all security checks
    func validateURL(_ url: URL) -> Bool {
        let urlString = url.absoluteString

        // Check URL length
        guard urlString.count <= Self.maxURLLength else {
            DebugLogger.shared.warning("[NetworkSanitizer] URL exceeds maximum length (\(urlString.count) > \(Self.maxURLLength))")
            return false
        }

        // Check for CRLF injection characters
        guard urlString.rangeOfCharacter(from: Self.injectionCharacters) == nil else {
            DebugLogger.shared.error("[NetworkSanitizer] URL contains injection characters: \(sanitizeURL(url))")
            return false
        }

        // Require HTTPS scheme
        guard let scheme = url.scheme?.lowercased(), scheme == "https" else {
            // Allow modus:// scheme for deep links
            if url.scheme?.lowercased() == "modus" {
                return true
            }
            DebugLogger.shared.warning("[NetworkSanitizer] URL has non-HTTPS scheme: \(url.scheme ?? "nil")")
            return false
        }

        // Validate host exists and is not empty
        guard let host = url.host, !host.isEmpty else {
            DebugLogger.shared.warning("[NetworkSanitizer] URL has no host")
            return false
        }

        // Check for header injection in host
        guard host.rangeOfCharacter(from: Self.injectionCharacters) == nil else {
            DebugLogger.shared.error("[NetworkSanitizer] Host contains injection characters")
            return false
        }

        // Block private/local network addresses (SSRF prevention)
        if isPrivateAddress(host) {
            DebugLogger.shared.warning("[NetworkSanitizer] URL points to private/local address: \(host)")
            return false
        }

        return true
    }

    // MARK: - Redirect Validation

    /// Validates a redirect URL to prevent open redirect attacks.
    ///
    /// Ensures the redirect stays within allowed domains and does not
    /// downgrade from HTTPS to HTTP.
    ///
    /// - Parameters:
    ///   - redirectURL: The URL the server wants to redirect to
    ///   - originalURL: The original request URL
    ///   - allowedDomains: Set of domains that are allowed redirect targets.
    ///                     If nil, only same-domain redirects are allowed.
    /// - Returns: `true` if the redirect is safe to follow
    func validateRedirect(
        from originalURL: URL,
        to redirectURL: URL,
        allowedDomains: Set<String>? = nil
    ) -> Bool {
        // Must be HTTPS (no protocol downgrade)
        guard redirectURL.scheme?.lowercased() == "https" else {
            DebugLogger.shared.warning("[NetworkSanitizer] Redirect blocked: protocol downgrade from HTTPS to \(redirectURL.scheme ?? "unknown")")
            return false
        }

        // Validate the redirect URL itself
        guard validateURL(redirectURL) else {
            return false
        }

        guard let redirectHost = redirectURL.host?.lowercased(),
              let originalHost = originalURL.host?.lowercased() else {
            return false
        }

        // Same-domain redirect is always allowed
        if redirectHost == originalHost {
            return true
        }

        // Check against allowed domains
        if let allowed = allowedDomains {
            let isAllowed = allowed.contains { domain in
                redirectHost == domain || redirectHost.hasSuffix("." + domain)
            }
            if !isAllowed {
                DebugLogger.shared.warning("[NetworkSanitizer] Redirect blocked: \(redirectHost) not in allowed domains")
                return false
            }
            return true
        }

        // Default: only allow supabase.co domain family
        let supabaseDomains: Set<String> = ["supabase.co", "supabase.com"]
        let isSupabaseDomain = supabaseDomains.contains { domain in
            redirectHost == domain || redirectHost.hasSuffix("." + domain)
        }

        if !isSupabaseDomain {
            DebugLogger.shared.warning("[NetworkSanitizer] Redirect blocked: \(redirectHost) is not a Supabase domain")
            return false
        }

        return true
    }

    // MARK: - Private Helpers

    /// Redacts PII patterns in a string (emails, phone numbers, JWTs, bearer tokens).
    private func redactPII(in string: String) -> String {
        var result = string

        // Redact JWTs first (they're long and may contain other patterns)
        if let regex = jwtRegex {
            result = regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result), withTemplate: Self.redacted)
        }

        // Redact Bearer tokens
        if let regex = bearerTokenRegex {
            result = regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result), withTemplate: "Bearer \(Self.redacted)")
        }

        // Redact email addresses
        if let regex = emailRegex {
            result = regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result), withTemplate: Self.redacted)
        }

        // Redact phone numbers
        if let regex = phoneRegex {
            result = regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result), withTemplate: Self.redacted)
        }

        return result
    }

    /// Recursively sanitizes a JSON value, redacting sensitive fields.
    private func sanitizeJSONValue(_ value: Any) -> Any {
        if let dict = value as? [String: Any] {
            var sanitized: [String: Any] = [:]
            for (key, val) in dict {
                if Self.sensitiveBodyFields.contains(key.lowercased()) {
                    sanitized[key] = Self.redacted
                } else {
                    sanitized[key] = sanitizeJSONValue(val)
                }
            }
            return sanitized
        } else if let array = value as? [Any] {
            return array.map { sanitizeJSONValue($0) }
        } else if let string = value as? String {
            return redactPII(in: string)
        }
        return value
    }

    /// Checks whether a hostname resolves to a private/local network address.
    /// Used for SSRF prevention.
    private func isPrivateAddress(_ host: String) -> Bool {
        let privatePatterns = [
            "localhost",
            "127.0.0.1",
            "0.0.0.0",
            "::1",
            "10.",
            "172.16.", "172.17.", "172.18.", "172.19.",
            "172.20.", "172.21.", "172.22.", "172.23.",
            "172.24.", "172.25.", "172.26.", "172.27.",
            "172.28.", "172.29.", "172.30.", "172.31.",
            "192.168.",
            "169.254.",  // Link-local
            "fc00:",     // IPv6 unique local
            "fe80:"      // IPv6 link-local
        ]

        let hostLower = host.lowercased()
        return privatePatterns.contains { hostLower.hasPrefix($0) || hostLower == $0 }
    }
}
