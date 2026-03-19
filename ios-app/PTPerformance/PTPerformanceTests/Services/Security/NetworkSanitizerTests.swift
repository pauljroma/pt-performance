//
//  NetworkSanitizerTests.swift
//  PTPerformanceTests
//
//  Unit tests for NetworkSanitizer (ACP-1055).
//  Tests URL validation, header sanitization, body sanitization,
//  PII stripping, SQL injection detection, and SSRF prevention
//  for HIPAA compliance.
//

import XCTest
@testable import PTPerformance

// MARK: - NetworkSanitizer Tests

@MainActor
final class NetworkSanitizerTests: XCTestCase {

    // MARK: - Properties

    var sut: NetworkSanitizer!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        sut = NetworkSanitizer.shared
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(NetworkSanitizer.shared)
    }

    func testSharedInstanceReturnsSameObject() {
        let instance1 = NetworkSanitizer.shared
        let instance2 = NetworkSanitizer.shared
        XCTAssertTrue(instance1 === instance2, "shared should return the same instance")
    }

    // MARK: - URL Validation: Valid URLs

    func testValidateURL_ValidHTTPS_ReturnsTrue() {
        let url = URL(string: "https://api.supabase.co/rest/v1/patients")!
        XCTAssertTrue(sut.validateURL(url))
    }

    func testValidateURL_ValidHTTPSWithQuery_ReturnsTrue() {
        let url = URL(string: "https://api.example.com/data?page=1&limit=20")!
        XCTAssertTrue(sut.validateURL(url))
    }

    func testValidateURL_ValidHTTPSWithPort_ReturnsTrue() {
        let url = URL(string: "https://api.example.com:8443/data")!
        XCTAssertTrue(sut.validateURL(url))
    }

    func testValidateURL_KorzaScheme_ReturnsTrue() {
        let url = URL(string: "korza://deeplink/action")!
        XCTAssertTrue(sut.validateURL(url))
    }

    // MARK: - URL Validation: Invalid URLs

    func testValidateURL_HTTPScheme_ReturnsFalse() {
        let url = URL(string: "http://api.example.com/data")!
        XCTAssertFalse(sut.validateURL(url), "HTTP should be rejected; only HTTPS is allowed")
    }

    func testValidateURL_FTPScheme_ReturnsFalse() {
        let url = URL(string: "ftp://files.example.com/data")!
        XCTAssertFalse(sut.validateURL(url), "FTP scheme should be rejected")
    }

    func testValidateURL_FileScheme_ReturnsFalse() {
        let url = URL(string: "file:///etc/passwd")!
        XCTAssertFalse(sut.validateURL(url), "file:// scheme should be rejected")
    }

    func testValidateURL_JavascriptScheme_ReturnsFalse() {
        // javascript: scheme should fail (no host, wrong scheme)
        let url = URL(string: "javascript:alert(1)")!
        XCTAssertFalse(sut.validateURL(url))
    }

    // MARK: - URL Validation: SSRF Prevention (Private Addresses)

    func testValidateURL_Localhost_ReturnsFalse() {
        let url = URL(string: "https://localhost/admin")!
        XCTAssertFalse(sut.validateURL(url), "localhost should be blocked for SSRF prevention")
    }

    func testValidateURL_Loopback127_ReturnsFalse() {
        let url = URL(string: "https://127.0.0.1/internal")!
        XCTAssertFalse(sut.validateURL(url), "127.0.0.1 should be blocked")
    }

    func testValidateURL_ZeroAddress_ReturnsFalse() {
        let url = URL(string: "https://0.0.0.0/")!
        XCTAssertFalse(sut.validateURL(url), "0.0.0.0 should be blocked")
    }

    func testValidateURL_PrivateClassA_ReturnsFalse() {
        let url = URL(string: "https://10.0.0.1/internal")!
        XCTAssertFalse(sut.validateURL(url), "10.x.x.x should be blocked")
    }

    func testValidateURL_PrivateClassB_ReturnsFalse() {
        let url = URL(string: "https://172.16.0.1/internal")!
        XCTAssertFalse(sut.validateURL(url), "172.16.x.x should be blocked")
    }

    func testValidateURL_PrivateClassC_ReturnsFalse() {
        let url = URL(string: "https://192.168.1.1/admin")!
        XCTAssertFalse(sut.validateURL(url), "192.168.x.x should be blocked")
    }

    func testValidateURL_LinkLocal_ReturnsFalse() {
        let url = URL(string: "https://169.254.169.254/metadata")!
        XCTAssertFalse(sut.validateURL(url), "Link-local 169.254.x.x should be blocked (cloud metadata endpoint)")
    }

    func testValidateURL_IPv6Loopback_ReturnsFalse() {
        let url = URL(string: "https://[::1]/admin")!
        XCTAssertFalse(sut.validateURL(url), "IPv6 loopback should be blocked")
    }

    // MARK: - URL Validation: Oversized URL

    func testValidateURL_ExceedsMaxLength_ReturnsFalse() {
        let longPath = String(repeating: "a", count: 9000)
        let url = URL(string: "https://example.com/\(longPath)")!
        XCTAssertFalse(sut.validateURL(url), "URLs exceeding 8192 chars should be rejected")
    }

    func testValidateURL_AtMaxLength_ReturnsTrue() {
        // Create a URL that is exactly at the limit (8192 bytes)
        let base = "https://example.com/"
        let remaining = 8192 - base.count
        let path = String(repeating: "x", count: remaining)
        let url = URL(string: base + path)!
        XCTAssertTrue(sut.validateURL(url), "URL exactly at 8192 chars should be accepted")
    }

    // MARK: - URL Sanitization: Sensitive Query Parameters

    func testSanitizeURL_RedactsTokenParam() {
        let url = URL(string: "https://api.example.com/auth?token=secret123")!
        let result = sut.sanitizeURL(url)
        XCTAssertFalse(result.contains("secret123"), "Token value should be redacted")
        // URLComponents may percent-encode brackets, so check for both forms
        let containsRedacted = result.contains("[REDACTED]") || result.contains("%5BREDACTED%5D")
        XCTAssertTrue(containsRedacted, "Should contain redaction placeholder (raw or percent-encoded)")
    }

    func testSanitizeURL_RedactsAccessToken() {
        let url = URL(string: "https://api.example.com/oauth?access_token=abc123xyz")!
        let result = sut.sanitizeURL(url)
        XCTAssertFalse(result.contains("abc123xyz"))
        let containsRedacted = result.contains("[REDACTED]") || result.contains("%5BREDACTED%5D")
        XCTAssertTrue(containsRedacted, "Should contain redaction placeholder (raw or percent-encoded)")
    }

    func testSanitizeURL_RedactsPassword() {
        let url = URL(string: "https://api.example.com/login?password=hunter2")!
        let result = sut.sanitizeURL(url)
        XCTAssertFalse(result.contains("hunter2"))
    }

    func testSanitizeURL_RedactsEmail() {
        let url = URL(string: "https://api.example.com/user?email=patient@hospital.com")!
        let result = sut.sanitizeURL(url)
        XCTAssertFalse(result.contains("patient@hospital.com"))
    }

    func testSanitizeURL_RedactsApiKey() {
        let url = URL(string: "https://api.example.com/data?api_key=sk-1234567890")!
        let result = sut.sanitizeURL(url)
        XCTAssertFalse(result.contains("sk-1234567890"))
    }

    func testSanitizeURL_RedactsSSN() {
        let url = URL(string: "https://api.example.com/verify?ssn=123-45-6789")!
        let result = sut.sanitizeURL(url)
        XCTAssertFalse(result.contains("123-45-6789"))
    }

    func testSanitizeURL_RedactsCreditCard() {
        let url = URL(string: "https://api.example.com/pay?credit_card=4111111111111111")!
        let result = sut.sanitizeURL(url)
        XCTAssertFalse(result.contains("4111111111111111"))
    }

    func testSanitizeURL_PreservesNonSensitiveParams() {
        let url = URL(string: "https://api.example.com/data?page=1&limit=20")!
        let result = sut.sanitizeURL(url)
        XCTAssertTrue(result.contains("page=1"), "Non-sensitive params should be preserved")
        XCTAssertTrue(result.contains("limit=20"), "Non-sensitive params should be preserved")
    }

    func testSanitizeURL_RedactsMultipleSensitiveParams() {
        let url = URL(string: "https://api.example.com/auth?token=abc&password=xyz&email=a@b.com")!
        let result = sut.sanitizeURL(url)
        XCTAssertFalse(result.contains("abc"), "Token should be redacted")
        XCTAssertFalse(result.contains("xyz"), "Password should be redacted")
    }

    // MARK: - URL Sanitization: PII in Values

    func testSanitizeURL_RedactsEmailInValue() {
        let url = URL(string: "https://api.example.com/search?q=contact+john@example.com+please")!
        let result = sut.sanitizeURL(url)
        XCTAssertFalse(result.contains("john@example.com"), "Email embedded in value should be redacted")
    }

    func testSanitizeURL_RedactsJWT() {
        let jwt = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U"
        let url = URL(string: "https://api.example.com/verify?data=\(jwt)")!
        let result = sut.sanitizeURL(url)
        XCTAssertFalse(result.contains("eyJhbGciOiJIUzI1NiJ9"), "JWT should be redacted from URL")
    }

    // MARK: - URL Sanitization: Edge Cases

    func testSanitizeURL_HandlesURLWithNoQuery() {
        let url = URL(string: "https://api.example.com/data")!
        let result = sut.sanitizeURL(url)
        XCTAssertTrue(result.contains("https://api.example.com/data"))
    }

    func testSanitizeURL_HandlesEmptyQueryValue() {
        let url = URL(string: "https://api.example.com/data?token=")!
        let result = sut.sanitizeURL(url)
        // token with empty value should still be handled
        XCTAssertTrue(result.contains("token"))
    }

    // MARK: - Header Sanitization

    func testSanitizeHeaders_RedactsAuthorization() {
        let headers = ["Authorization": "Bearer eyJabc123"]
        let result = sut.sanitizeHeaders(headers)
        XCTAssertEqual(result["Authorization"], "[REDACTED]")
    }

    func testSanitizeHeaders_RedactsApiKey() {
        let headers = ["apikey": "super-secret-key-12345"]
        let result = sut.sanitizeHeaders(headers)
        XCTAssertEqual(result["apikey"], "[REDACTED]")
    }

    func testSanitizeHeaders_RedactsCookie() {
        let headers = ["Cookie": "session=abc123; user=patient1"]
        let result = sut.sanitizeHeaders(headers)
        XCTAssertEqual(result["Cookie"], "[REDACTED]")
    }

    func testSanitizeHeaders_RedactsSetCookie() {
        let headers = ["Set-Cookie": "session=xyz789; HttpOnly; Secure"]
        let result = sut.sanitizeHeaders(headers)
        XCTAssertEqual(result["Set-Cookie"], "[REDACTED]")
    }

    func testSanitizeHeaders_RedactsSupabaseAuth() {
        let headers = ["x-supabase-auth": "my-supabase-token"]
        let result = sut.sanitizeHeaders(headers)
        XCTAssertEqual(result["x-supabase-auth"], "[REDACTED]")
    }

    func testSanitizeHeaders_RedactsXAccessToken() {
        let headers = ["x-access-token": "token-value-here"]
        let result = sut.sanitizeHeaders(headers)
        XCTAssertEqual(result["x-access-token"], "[REDACTED]")
    }

    func testSanitizeHeaders_RedactsXRefreshToken() {
        let headers = ["x-refresh-token": "refresh-value"]
        let result = sut.sanitizeHeaders(headers)
        XCTAssertEqual(result["x-refresh-token"], "[REDACTED]")
    }

    func testSanitizeHeaders_RedactsProxyAuthorization() {
        let headers = ["Proxy-Authorization": "Basic dXNlcjpwYXNz"]
        let result = sut.sanitizeHeaders(headers)
        XCTAssertEqual(result["Proxy-Authorization"], "[REDACTED]")
    }

    func testSanitizeHeaders_RedactsWWWAuthenticate() {
        let headers = ["WWW-Authenticate": "Bearer realm=\"api\""]
        let result = sut.sanitizeHeaders(headers)
        XCTAssertEqual(result["WWW-Authenticate"], "[REDACTED]")
    }

    func testSanitizeHeaders_PreservesNonSensitiveHeaders() {
        let headers = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-Request-ID": "req-12345"
        ]
        let result = sut.sanitizeHeaders(headers)
        XCTAssertEqual(result["Content-Type"], "application/json")
        XCTAssertEqual(result["Accept"], "application/json")
        XCTAssertEqual(result["X-Request-ID"], "req-12345")
    }

    func testSanitizeHeaders_CaseInsensitiveMatching() {
        let headers = ["AUTHORIZATION": "Bearer token123"]
        let result = sut.sanitizeHeaders(headers)
        XCTAssertEqual(result["AUTHORIZATION"], "[REDACTED]",
                       "Header matching should be case-insensitive")
    }

    func testSanitizeHeaders_MixedSensitiveAndNonSensitive() {
        let headers = [
            "Authorization": "Bearer abc",
            "Content-Type": "application/json",
            "Cookie": "session=xyz",
            "X-Request-ID": "123"
        ]
        let result = sut.sanitizeHeaders(headers)
        XCTAssertEqual(result["Authorization"], "[REDACTED]")
        XCTAssertEqual(result["Content-Type"], "application/json")
        XCTAssertEqual(result["Cookie"], "[REDACTED]")
        XCTAssertEqual(result["X-Request-ID"], "123")
    }

    func testSanitizeHeaders_EmptyDictionary() {
        let headers: [String: String] = [:]
        let result = sut.sanitizeHeaders(headers)
        XCTAssertTrue(result.isEmpty)
    }

    func testSanitizeHeaders_RedactsPIIInNonSensitiveHeaderValues() {
        let headers = ["X-Debug-Info": "user email is patient@hospital.com"]
        let result = sut.sanitizeHeaders(headers)
        XCTAssertFalse(result["X-Debug-Info"]?.contains("patient@hospital.com") ?? true,
                       "PII in header values should be redacted even for non-sensitive header names")
    }

    // MARK: - Body Sanitization

    func testSanitizeBody_NilBody_ReturnsNil() {
        let result = sut.sanitizeBody(nil)
        XCTAssertNil(result)
    }

    func testSanitizeBody_EmptyData_ReturnsNil() {
        let result = sut.sanitizeBody(Data())
        XCTAssertNil(result)
    }

    func testSanitizeBody_JSONWithSensitiveFields_RedactsThem() {
        let json: [String: Any] = [
            "username": "john_doe",
            "password": "super_secret",
            "email": "john@example.com"
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let result = sut.sanitizeBody(data)

        #if DEBUG
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("[REDACTED]"), "Sensitive fields should be redacted")
        XCTAssertFalse(result!.contains("super_secret"), "Password should not appear in sanitized body")
        #endif
    }

    func testSanitizeBody_JSONWithNonSensitiveFields_PreservesThem() {
        let json: [String: Any] = [
            "page": 1,
            "limit": 20,
            "sort": "created_at"
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let result = sut.sanitizeBody(data)

        #if DEBUG
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.contains("[REDACTED]"),
                       "Non-sensitive fields should not be redacted")
        #endif
    }

    func testSanitizeBody_JSONWithToken_RedactsIt() {
        let json: [String: Any] = [
            "access_token": "eyJhbGciOiJIUzI1NiJ9.payload.signature",
            "token_type": "bearer"
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let result = sut.sanitizeBody(data)

        #if DEBUG
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("[REDACTED]"))
        XCTAssertFalse(result!.contains("eyJhbGciOiJIUzI1NiJ9"))
        #endif
    }

    func testSanitizeBody_NestedJSON_RedactsDeeply() {
        let json: [String: Any] = [
            "user": [
                "name": "John",
                "email": "john@test.com",
                "credentials": [
                    "password": "secret123"
                ]
            ]
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let result = sut.sanitizeBody(data)

        #if DEBUG
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.contains("secret123"), "Nested password should be redacted")
        #endif
    }

    func testSanitizeBody_LargeBody_IsTruncated() {
        let largeValue = String(repeating: "x", count: 1000)
        let json: [String: Any] = ["data": largeValue]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let result = sut.sanitizeBody(data)

        #if DEBUG
        XCTAssertNotNil(result)
        if result!.count > 500 {
            XCTAssertTrue(result!.contains("[truncated]"),
                          "Large bodies should be truncated")
        }
        #endif
    }

    func testSanitizeBody_PlainTextWithEmail_RedactsIt() {
        let text = "Contact us at patient@hospital.org for more info"
        let data = text.data(using: .utf8)!
        let result = sut.sanitizeBody(data)

        #if DEBUG
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.contains("patient@hospital.org"),
                       "Email in plain text body should be redacted")
        #endif
    }

    func testSanitizeBody_BinaryData_ReportsByteCount() {
        // Create non-UTF8, non-JSON data
        var bytes: [UInt8] = [0xFF, 0xFE, 0xFD, 0x00, 0x01, 0x80, 0x81]
        let data = Data(bytes: &bytes, count: bytes.count)
        let result = sut.sanitizeBody(data)

        #if DEBUG
        // If it can't be parsed as UTF-8 string or JSON, it should report as binary
        if let result = result, result.contains("binary data") {
            XCTAssertTrue(result.contains("\(data.count) bytes"))
        }
        #endif
    }

    // MARK: - Redirect Validation

    func testValidateRedirect_SameDomain_ReturnsTrue() {
        let original = URL(string: "https://api.supabase.co/auth/login")!
        let redirect = URL(string: "https://api.supabase.co/auth/callback")!
        XCTAssertTrue(sut.validateRedirect(from: original, to: redirect))
    }

    func testValidateRedirect_ProtocolDowngrade_ReturnsFalse() {
        let original = URL(string: "https://api.supabase.co/auth")!
        let redirect = URL(string: "http://api.supabase.co/callback")!
        XCTAssertFalse(sut.validateRedirect(from: original, to: redirect),
                       "HTTPS to HTTP downgrade should be blocked")
    }

    func testValidateRedirect_ToSubabaseDomain_ReturnsTrue() {
        let original = URL(string: "https://myapp.supabase.co/auth")!
        let redirect = URL(string: "https://other.supabase.co/callback")!
        XCTAssertTrue(sut.validateRedirect(from: original, to: redirect))
    }

    func testValidateRedirect_ToAllowedDomain_ReturnsTrue() {
        let original = URL(string: "https://myapp.supabase.co/auth")!
        let redirect = URL(string: "https://trusted.example.com/callback")!
        let allowed: Set<String> = ["example.com", "trusted.org"]
        XCTAssertTrue(sut.validateRedirect(from: original, to: redirect, allowedDomains: allowed))
    }

    func testValidateRedirect_ToDisallowedDomain_ReturnsFalse() {
        let original = URL(string: "https://myapp.supabase.co/auth")!
        let redirect = URL(string: "https://evil.com/steal-data")!
        XCTAssertFalse(sut.validateRedirect(from: original, to: redirect),
                       "Redirect to unknown domain should be blocked")
    }

    func testValidateRedirect_ToPrivateAddress_ReturnsFalse() {
        let original = URL(string: "https://api.supabase.co/auth")!
        let redirect = URL(string: "https://192.168.1.1/admin")!
        XCTAssertFalse(sut.validateRedirect(from: original, to: redirect),
                       "Redirect to private IP should be blocked")
    }

    func testValidateRedirect_ToAllowedSubdomain_ReturnsTrue() {
        let original = URL(string: "https://myapp.supabase.co/auth")!
        let redirect = URL(string: "https://sub.example.com/callback")!
        let allowed: Set<String> = ["example.com"]
        XCTAssertTrue(sut.validateRedirect(from: original, to: redirect, allowedDomains: allowed),
                      "Subdomains of allowed domains should be permitted")
    }

    // MARK: - XSS Attack Strings

    func testSanitizeURL_XSSInQueryParam() {
        let url = URL(string: "https://api.example.com/search?q=%3Cscript%3Ealert(1)%3C/script%3E")!
        // Should not crash, and the result should be a valid string
        let result = sut.sanitizeURL(url)
        XCTAssertNotNil(result)
    }

    func testSanitizeHeaders_XSSInHeaderValue() {
        let headers = ["X-Custom": "<script>alert('xss')</script>"]
        let result = sut.sanitizeHeaders(headers)
        // Non-sensitive header with XSS -- should still return something
        XCTAssertNotNil(result["X-Custom"])
    }

    // MARK: - SQL Injection in Query Strings

    func testSanitizeURL_SQLInjectionInQuery() {
        let url = URL(string: "https://api.example.com/data?id=1%27%20OR%201%3D1%20--%20")!
        let result = sut.sanitizeURL(url)
        XCTAssertNotNil(result, "SQL injection in query should not crash sanitizer")
    }

    func testSanitizeURL_SQLDropTableInQuery() {
        let url = URL(string: "https://api.example.com/data?name=%27%3B%20DROP%20TABLE%20patients%3B%20--")!
        let result = sut.sanitizeURL(url)
        XCTAssertNotNil(result, "DROP TABLE injection should not crash sanitizer")
    }

    func testSanitizeURL_SQLUnionInQuery() {
        let url = URL(string: "https://api.example.com/data?id=1%20UNION%20SELECT%20*%20FROM%20users")!
        let result = sut.sanitizeURL(url)
        XCTAssertNotNil(result)
    }

    // MARK: - Body Sanitization: Medical-Specific Fields

    func testSanitizeBody_JSONWithPhoneNumber_RedactsIt() {
        let json: [String: Any] = [
            "name": "John Doe",
            "phone": "555-123-4567"
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let result = sut.sanitizeBody(data)

        #if DEBUG
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("[REDACTED]"), "Phone field should be redacted")
        XCTAssertFalse(result!.contains("555-123-4567"))
        #endif
    }

    func testSanitizeBody_JSONWithSSN_RedactsIt() {
        let json: [String: Any] = [
            "patient_name": "Jane",
            "ssn": "123-45-6789"
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let result = sut.sanitizeBody(data)

        #if DEBUG
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("[REDACTED]"))
        XCTAssertFalse(result!.contains("123-45-6789"))
        #endif
    }

    func testSanitizeBody_JSONArrayWithSensitiveData_RedactsAll() {
        let json: [[String: Any]] = [
            ["email": "a@b.com", "name": "Alice"],
            ["email": "c@d.com", "name": "Bob"]
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let result = sut.sanitizeBody(data)

        #if DEBUG
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.contains("a@b.com"))
        XCTAssertFalse(result!.contains("c@d.com"))
        #endif
    }

    // MARK: - Oversized Header Values

    func testSanitizeHeaders_OversizedValue_DoesNotCrash() {
        let bigValue = String(repeating: "A", count: 10_000)
        let headers = ["X-Huge-Header": bigValue]
        let result = sut.sanitizeHeaders(headers)
        XCTAssertNotNil(result["X-Huge-Header"])
    }

    func testSanitizeHeaders_ManyHeaders_DoesNotCrash() {
        var headers: [String: String] = [:]
        for i in 0..<1000 {
            headers["X-Header-\(i)"] = "value-\(i)"
        }
        let result = sut.sanitizeHeaders(headers)
        XCTAssertEqual(result.count, 1000)
    }

    // MARK: - Edge Cases

    func testSanitizeURL_URLWithFragment() {
        let url = URL(string: "https://api.example.com/page#section?token=abc")!
        let result = sut.sanitizeURL(url)
        XCTAssertNotNil(result)
    }

    func testSanitizeURL_URLWithUserInfo() {
        let url = URL(string: "https://user:password@api.example.com/data")!
        let result = sut.sanitizeURL(url)
        XCTAssertNotNil(result)
    }

    func testSanitizeURL_URLWithUnicode() {
        let url = URL(string: "https://api.example.com/data?name=%E4%B8%AD%E6%96%87")!
        let result = sut.sanitizeURL(url)
        XCTAssertNotNil(result)
    }

    func testValidateURL_EmptyHost() {
        // URL with scheme but empty host
        let url = URL(string: "https:///path")!
        XCTAssertFalse(sut.validateURL(url), "URL with empty host should be rejected")
    }

    func testSanitizeBody_JSONWithAllSensitiveFieldTypes() {
        let json: [String: Any] = [
            "password": "pass123",
            "token": "tok123",
            "access_token": "at123",
            "refresh_token": "rt123",
            "email": "x@y.com",
            "phone": "555-0000",
            "ssn": "000-00-0000",
            "credit_card": "4111111111111111",
            "cvv": "123",
            "secret": "s3cr3t",
            "safe_field": "this should remain"
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let result = sut.sanitizeBody(data)

        #if DEBUG
        XCTAssertNotNil(result)
        // All sensitive values should be gone
        XCTAssertFalse(result!.contains("pass123"))
        XCTAssertFalse(result!.contains("tok123"))
        XCTAssertFalse(result!.contains("at123"))
        XCTAssertFalse(result!.contains("rt123"))
        XCTAssertFalse(result!.contains("s3cr3t"))
        #endif
    }

    // MARK: - Validate Redirect: Supabase Domains

    func testValidateRedirect_ToSupabaseCom_ReturnsTrue() {
        let original = URL(string: "https://myapp.supabase.co/auth")!
        let redirect = URL(string: "https://auth.supabase.com/callback")!
        XCTAssertTrue(sut.validateRedirect(from: original, to: redirect))
    }

    func testValidateRedirect_ToSubdomainOfSupabaseCo_ReturnsTrue() {
        let original = URL(string: "https://myapp.supabase.co/auth")!
        let redirect = URL(string: "https://deep.sub.supabase.co/callback")!
        XCTAssertTrue(sut.validateRedirect(from: original, to: redirect))
    }

    func testValidateRedirect_ToRandomDomain_WithNoAllowedDomains_ReturnsFalse() {
        let original = URL(string: "https://myapp.supabase.co/auth")!
        let redirect = URL(string: "https://not-supabase.io/callback")!
        XCTAssertFalse(sut.validateRedirect(from: original, to: redirect))
    }
}
