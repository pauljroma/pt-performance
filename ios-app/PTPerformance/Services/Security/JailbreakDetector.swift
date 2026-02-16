//
//  JailbreakDetector.swift
//  PTPerformance
//
//  ACP-1045: Secure Local Storage
//  Detects jailbroken devices using multiple heuristics.
//

import Foundation
import UIKit
import MachO
import Darwin

// MARK: - JailbreakDetector

/// Detects whether the device is jailbroken by performing several heuristic checks.
///
/// Checks performed:
/// 1. **Known jailbreak file paths** — looks for Cydia, Sileo, and other artifacts
/// 2. **URL scheme checks** — attempts to open `cydia://` and `sileo://`
/// 3. **Writable system paths** — tries writing to restricted directories
/// 4. **Dylib injection** — inspects the loaded dynamic libraries
/// 5. **Sandbox integrity** — checks for environment variables and accessible paths that indicate a compromised sandbox
///
/// The detector does **not** block the app on jailbroken devices. It logs a warning
/// and makes the result available so other services can make informed decisions
/// (e.g., increasing logging, disabling local caching of sensitive data).
///
/// ## Usage
/// ```swift
/// JailbreakDetector.shared.check()
/// if JailbreakDetector.shared.isJailbroken {
///     // Take appropriate action
/// }
/// ```
final class JailbreakDetector {

    // MARK: - Singleton

    static let shared = JailbreakDetector()

    // MARK: - Properties

    /// Whether the device has been identified as jailbroken.
    /// Only valid after `check()` has been called at least once.
    private(set) var isJailbroken: Bool = false

    /// The specific checks that triggered a positive detection.
    private(set) var detectedIndicators: [String] = []

    private let logger = DebugLogger.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - Known Jailbreak Paths

    /// File paths commonly created by jailbreak tools and package managers
    private static let jailbreakPaths: [String] = [
        "/Applications/Cydia.app",
        "/Applications/Sileo.app",
        "/Applications/Zebra.app",
        "/Applications/Installer.app",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/usr/sbin/sshd",
        "/usr/bin/sshd",
        "/usr/libexec/sftp-server",
        "/etc/apt",
        "/private/var/lib/apt/",
        "/private/var/lib/cydia",
        "/private/var/mobile/Library/SBSettings/Themes",
        "/private/var/stash",
        "/private/var/tmp/cydia.log",
        "/var/cache/apt",
        "/var/lib/cydia",
        "/usr/bin/cycript",
        "/usr/local/bin/cycript",
        "/usr/lib/libcycript.dylib",
        "/bin/bash",
        "/bin/sh",
        "/usr/sbin/frida-server",
        "/usr/bin/ssh"
    ]

    // MARK: - Public API

    /// Performs all jailbreak detection checks.
    ///
    /// Call this on app launch. Results are stored in `isJailbroken` and
    /// `detectedIndicators` for later inspection.
    func check() {
        #if targetEnvironment(simulator)
        // Never flag simulator as jailbroken
        logger.diagnostic("[JailbreakDetector] Running in Simulator — skipping jailbreak checks")
        isJailbroken = false
        detectedIndicators = []
        return
        #else
        var indicators: [String] = []

        if checkJailbreakPaths() {
            indicators.append("jailbreak_files_found")
        }

        if checkURLSchemes() {
            indicators.append("jailbreak_url_schemes")
        }

        if checkWritableSystemPaths() {
            indicators.append("writable_system_paths")
        }

        if checkDylibInjection() {
            indicators.append("dylib_injection_detected")
        }

        if checkSandboxIntegrity() {
            indicators.append("sandbox_compromised")
        }

        detectedIndicators = indicators
        isJailbroken = !indicators.isEmpty

        if isJailbroken {
            logger.warning("[JailbreakDetector] Device appears to be jailbroken. Indicators: \(indicators.joined(separator: ", "))")
        } else {
            logger.success("[JailbreakDetector] No jailbreak indicators detected")
        }
        #endif
    }

    // MARK: - Individual Checks

    /// Checks for the existence of known jailbreak-related files and directories.
    private func checkJailbreakPaths() -> Bool {
        for path in Self.jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                logger.diagnostic("[JailbreakDetector] Found jailbreak artifact: \(path)")
                return true
            }
        }
        return false
    }

    /// Checks whether jailbreak-specific URL schemes can be opened.
    ///
    /// Uses `DispatchQueue.main.async` with a continuation to avoid the
    /// deadlock risk that `DispatchQueue.main.sync` introduces when the
    /// caller is already on (or blocked by) the main thread.
    private func checkURLSchemes() -> Bool {
        let schemes = ["cydia://package/com.example.package", "sileo://package/com.example.package"]

        // UIApplication.shared.canOpenURL must be called from the main thread.
        // We bridge to the main queue safely via a semaphore-free async path
        // using withCheckedContinuation.
        let detected: Bool
        if Thread.isMainThread {
            detected = schemes.contains { scheme in
                guard let url = URL(string: scheme) else { return false }
                return UIApplication.shared.canOpenURL(url)
            }
        } else {
            // Use a RunLoop-based spin instead of DispatchQueue.main.sync to
            // avoid a potential deadlock when another queue holds the main
            // thread. This is safe because the work is non-blocking and fast.
            var result = false
            var finished = false
            DispatchQueue.main.async {
                result = schemes.contains { scheme in
                    guard let url = URL(string: scheme) else { return false }
                    return UIApplication.shared.canOpenURL(url)
                }
                finished = true
            }
            // Spin briefly — canOpenURL returns in microseconds
            while !finished {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.005))
            }
            detected = result
        }

        if detected {
            logger.diagnostic("[JailbreakDetector] Jailbreak URL scheme detected")
        }
        return detected
    }

    /// Attempts to write to a directory that should be read-only on non-jailbroken devices.
    private func checkWritableSystemPaths() -> Bool {
        let testPath = "/private/jailbreak_test_\(UUID().uuidString)"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            // If we get here, the write succeeded — the device is jailbroken
            try? FileManager.default.removeItem(atPath: testPath)
            logger.diagnostic("[JailbreakDetector] Successfully wrote to restricted path")
            return true
        } catch {
            // Expected on non-jailbroken devices
            return false
        }
    }

    /// Inspects the loaded dynamic libraries for known injection frameworks.
    private func checkDylibInjection() -> Bool {
        let suspiciousLibs = [
            "FridaGadget",
            "frida",
            "cynject",
            "libcycript",
            "MobileSubstrate",
            "SubstrateLoader",
            "SSLKillSwitch",
            "0xced",
            "libReveal"
        ]

        let count = _dyld_image_count()
        for i in 0..<count {
            guard let name = _dyld_get_image_name(i) else { continue }
            let imageName = String(cString: name)
            for lib in suspiciousLibs {
                if imageName.lowercased().contains(lib.lowercased()) {
                    logger.diagnostic("[JailbreakDetector] Suspicious dylib loaded: \(imageName)")
                    return true
                }
            }
        }
        return false
    }

    /// Checks for sandbox integrity by attempting operations that should be
    /// blocked in a normal iOS sandbox.
    ///
    /// On non-jailbroken devices, the sandbox prevents opening system
    /// pseudo-terminals and accessing certain restricted paths.
    private func checkSandboxIntegrity() -> Bool {
        // Attempt to open /dev/urandom for writing — should fail in sandbox
        // (read is allowed, write is not)
        let fd = open("/bin/sh", O_RDONLY)
        if fd >= 0 {
            close(fd)
            // Being able to open /bin/sh is an indicator of a compromised sandbox
            // on devices where this path should not exist
            if FileManager.default.fileExists(atPath: "/bin/sh") {
                logger.diagnostic("[JailbreakDetector] Sandbox integrity check: /bin/sh is accessible")
                return true
            }
        }

        // Check for suspicious environment variables set by jailbreak tools
        if let _ = getenv("DYLD_INSERT_LIBRARIES") {
            logger.diagnostic("[JailbreakDetector] DYLD_INSERT_LIBRARIES is set")
            return true
        }

        if let _ = getenv("_MSSafeMode") {
            logger.diagnostic("[JailbreakDetector] MobileSubstrate safe mode variable detected")
            return true
        }

        return false
    }
}
