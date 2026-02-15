//
//  DeepLinkService.swift
//  PTPerformance
//
//  ACP-999: Deep Link Attribution — Universal links, campaign tracking, deferred deep links
//
//  Handles all deep link routing, UTM attribution extraction, and deferred deep link
//  resolution. Works with both the custom `modus://` scheme and universal links from
//  `https://app.moduspt.com`.
//

import Foundation
import SwiftUI

// MARK: - Deep Link Destination Extensions for ACP-999

/// Extended deep link destinations for marketing, referral, and attribution flows.
/// These extend the existing `DeepLinkDestination` enum in PTPerformanceApp.swift.
extension DeepLinkDestination {
    // Existing cases already cover: .workout, .today, .settings, etc.
    // ACP-999 adds support for universal link patterns via DeepLinkService routing.
}

// MARK: - Deep Link Service

/// Centralized deep link handling with attribution tracking and deferred deep link support.
///
/// Parses incoming URLs from both custom scheme (`modus://`) and universal links
/// (`https://app.moduspt.com/...`), extracts UTM parameters for attribution, and
/// routes users to the correct in-app destination.
///
/// ## Features
/// - Universal link and custom scheme parsing
/// - UTM parameter extraction (source, medium, campaign, content)
/// - First-install attribution persistence
/// - Deferred deep link resolution on first launch
/// - Queuing when user is not yet authenticated
///
/// ## Usage
/// ```swift
/// // In PTPerformanceApp.swift
/// .onOpenURL { url in
///     DeepLinkService.shared.handleURL(url)
/// }
/// ```
@MainActor
class DeepLinkService: ObservableObject {

    // MARK: - Singleton

    static let shared = DeepLinkService()

    // MARK: - Published Properties

    /// The pending destination to navigate to. Views observe this and route accordingly.
    @Published var pendingDestination: DeepLinkDestination?

    /// The most recent attribution data extracted from a deep link
    @Published var lastAttribution: AttributionData?

    // MARK: - Private Properties

    private let logger = DebugLogger.shared
    private let tag = "DeepLinkService"

    /// UserDefaults keys for attribution persistence
    private enum Keys {
        static let firstInstallAttribution = "com.getmodus.attribution.firstInstall"
        static let hasCheckedDeferredLink = "com.getmodus.attribution.hasCheckedDeferred"
        static let attributionHistory = "com.getmodus.attribution.history"
        static let isFirstLaunch = "com.getmodus.attribution.isFirstLaunch"
        static let queuedDeepLinkURL = "com.getmodus.attribution.queuedURL"
    }

    /// Universal link host
    private let universalLinkHost = "app.moduspt.com"

    /// Custom URL scheme
    private let customScheme = "modus"

    // MARK: - Initialization

    private init() {
        // Mark first launch if not already set
        if UserDefaults.standard.object(forKey: Keys.isFirstLaunch) == nil {
            UserDefaults.standard.set(true, forKey: Keys.isFirstLaunch)
            logger.info(tag, "First launch detected — attribution tracking enabled")
        }
    }

    // MARK: - URL Handling

    /// Main entry point for all incoming URLs (custom scheme and universal links).
    /// Returns true if the URL was recognized and handled.
    @discardableResult
    func handleURL(_ url: URL) -> Bool {
        logger.info(tag, "Handling URL: \(url.absoluteString)")

        // Extract attribution from any URL before routing
        handleDeepLinkAttribution(url)

        // Try universal link parsing first
        if let destination = parseUniversalLink(url) {
            logger.success(tag, "Resolved universal link to destination: \(String(describing: destination))")
            pendingDestination = destination
            logDeepLinkEvent(url: url, destination: destination)
            return true
        }

        // Try custom scheme parsing
        if let destination = parseCustomScheme(url) {
            logger.success(tag, "Resolved custom scheme to destination: \(String(describing: destination))")
            pendingDestination = destination
            logDeepLinkEvent(url: url, destination: destination)
            return true
        }

        // Fall back to existing DeepLinkDestination parser for backward compatibility
        if let destination = DeepLinkDestination.from(url: url) {
            logger.success(tag, "Resolved via legacy parser to: \(String(describing: destination))")
            pendingDestination = destination
            logDeepLinkEvent(url: url, destination: destination)
            return true
        }

        logger.warning(tag, "Unrecognized deep link URL: \(url.absoluteString)")
        return false
    }

    /// Handle an NSUserActivity for universal links (Scene Delegate / UIKit continuation).
    func handleUserActivity(_ userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }

        logger.info(tag, "Handling NSUserActivity universal link: \(url.absoluteString)")
        return handleURL(url)
    }

    // MARK: - Universal Link Parsing

    /// Parse universal links from https://app.moduspt.com/...
    ///
    /// Supported patterns:
    /// - /workout/{id} — Open specific workout
    /// - /invite/{code} — Referral invitation
    /// - /subscribe — Subscription paywall
    /// - /profile — User profile
    /// - /settings — App settings
    /// - /exercise/{id} — Specific exercise detail
    /// - /achievement/{id} — Achievement detail
    /// - /today — Today's session
    /// - /readiness — Readiness score
    /// - /recovery — Recovery view
    /// - /progress — Progress dashboard
    private func parseUniversalLink(_ url: URL) -> DeepLinkDestination? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host,
              host == universalLinkHost || host == "www.\(universalLinkHost)" else {
            return nil
        }

        let pathComponents = components.path
            .split(separator: "/")
            .map(String.init)

        guard let firstComponent = pathComponents.first else {
            // Root URL — default to today view
            return .today
        }

        switch firstComponent {
        case "workout":
            if let id = pathComponents.dropFirst().first {
                return .workout(sessionId: id)
            }
            return .today

        case "invite":
            if let code = pathComponents.dropFirst().first {
                // Store referral code for post-auth processing
                storeReferralCode(code)
                logger.info(tag, "Referral code captured: \(code)")
                // Navigate to today — referral is processed in background
                return .today
            }
            return .today

        case "subscribe":
            // Navigate to today — the paywall trigger is handled separately
            // by StoreKitService based on the attribution data
            logger.info(tag, "Subscribe deep link — will show paywall")
            return .today

        case "profile":
            return .settings

        case "settings":
            return .settings

        case "exercise":
            if let id = pathComponents.dropFirst().first {
                // Map to workout context — exercises are viewed within workouts
                return .workout(sessionId: id)
            }
            return .today

        case "achievement":
            // Achievement deep links route to progress view
            return .progress

        case "today":
            return .today

        case "readiness":
            return .readiness

        case "recovery":
            return .recovery

        case "progress":
            return .progress

        case "streak":
            return .streak

        case "schedule":
            return .schedule

        default:
            logger.warning(tag, "Unknown universal link path: /\(firstComponent)")
            return nil
        }
    }

    // MARK: - Custom Scheme Parsing

    /// Parse custom scheme URLs: modus://...
    /// Extends existing DeepLinkDestination.from(url:) with attribution-aware patterns.
    private func parseCustomScheme(_ url: URL) -> DeepLinkDestination? {
        guard url.scheme == customScheme else { return nil }

        let host = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "invite":
            if let code = pathComponents.first {
                storeReferralCode(code)
                return .today
            }
            return nil

        case "subscribe":
            // Route to today — paywall shown via attribution trigger
            return .today

        case "profile":
            return .settings

        default:
            // Delegate to existing DeepLinkDestination parser
            return nil
        }
    }

    // MARK: - Attribution Extraction

    /// Extract UTM parameters and referral codes from any deep link URL.
    /// Stores attribution data in UserDefaults and syncs to Supabase.
    func handleDeepLinkAttribution(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            logger.warning(tag, "Could not parse URL components for attribution: \(url.absoluteString)")
            return
        }

        let queryItems = components.queryItems ?? []

        let source = queryItems.first(where: { $0.name == "utm_source" })?.value
        let medium = queryItems.first(where: { $0.name == "utm_medium" })?.value
        let campaign = queryItems.first(where: { $0.name == "utm_campaign" })?.value
        let content = queryItems.first(where: { $0.name == "utm_content" })?.value

        // Extract referral code from path or query
        var referralCode: String?
        if let pathComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)?.path
            .split(separator: "/")
            .map(String.init),
           pathComponents.first == "invite",
           let code = pathComponents.dropFirst().first {
            referralCode = code
        }
        // Also check query param for referral
        if referralCode == nil {
            referralCode = queryItems.first(where: { $0.name == "ref" })?.value
        }

        // Only store attribution if there's meaningful data
        guard source != nil || medium != nil || campaign != nil || content != nil || referralCode != nil else {
            logger.diagnostic("[\(tag)] No attribution parameters found in URL")
            return
        }

        let isFirstInstall = UserDefaults.standard.bool(forKey: Keys.isFirstLaunch)

        let attribution = AttributionData(
            source: source,
            medium: medium,
            campaign: campaign,
            content: content,
            referralCode: referralCode,
            timestamp: Date(),
            isFirstInstall: isFirstInstall
        )

        lastAttribution = attribution

        // Persist first install attribution (never overwritten)
        if isFirstInstall {
            storeFirstInstallAttribution(attribution)
            // Clear first launch flag after storing
            UserDefaults.standard.set(false, forKey: Keys.isFirstLaunch)
        }

        // Append to attribution history
        appendAttributionHistory(attribution)

        // Sync to Supabase
        Task {
            await syncAttributionToSupabase(attribution)
        }

        logger.info(tag, "Attribution captured — source: \(source ?? "nil"), medium: \(medium ?? "nil"), campaign: \(campaign ?? "nil")")
    }

    // MARK: - Deferred Deep Links

    /// Check for pending deferred deep links on first launch after install.
    /// Called once during app startup when the user has not previously opened the app.
    func checkDeferredDeepLink() async {
        guard !UserDefaults.standard.bool(forKey: Keys.hasCheckedDeferredLink) else {
            logger.diagnostic("[\(tag)] Deferred deep link already checked — skipping")
            return
        }

        // Mark as checked immediately to prevent duplicate calls
        UserDefaults.standard.set(true, forKey: Keys.hasCheckedDeferredLink)

        logger.info(tag, "Checking for deferred deep link...")

        do {
            // Build a device fingerprint for matching
            let fingerprint = buildDeviceFingerprint()

            // Query Supabase for unclaimed deferred deep links matching this fingerprint
            let response: [DeferredDeepLink] = try await PTSupabaseClient.shared.client
                .from("deferred_deep_links")
                .select()
                .eq("fingerprint", value: fingerprint)
                .eq("is_claimed", value: false)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value

            guard let deferredLink = response.first else {
                logger.info(tag, "No deferred deep link found for this device")
                return
            }

            logger.success(tag, "Found deferred deep link: \(deferredLink.url)")

            // Claim the deferred deep link
            try await PTSupabaseClient.shared.client
                .from("deferred_deep_links")
                .update(["is_claimed": "true", "claimed_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: deferredLink.id)
                .execute()

            // Process the deferred URL
            if let url = URL(string: deferredLink.url) {
                _ = handleURL(url)
            }

        } catch {
            // Deferred deep links are best-effort — don't block app startup on failure
            logger.warning(tag, "Failed to check deferred deep link: \(error.localizedDescription)")
        }
    }

    // MARK: - Queued Deep Links (Pre-Auth)

    /// Queue a deep link URL for processing after authentication completes.
    /// Used when a deep link arrives but the user is not yet logged in.
    func queueDeepLinkForPostAuth(_ url: URL) {
        UserDefaults.standard.set(url.absoluteString, forKey: Keys.queuedDeepLinkURL)
        logger.info(tag, "Queued deep link for post-auth: \(url.absoluteString)")
    }

    /// Process any queued deep link after the user has authenticated.
    /// Should be called from the auth completion flow.
    func processQueuedDeepLink() {
        guard let urlString = UserDefaults.standard.string(forKey: Keys.queuedDeepLinkURL),
              let url = URL(string: urlString) else {
            return
        }

        // Clear the queued URL
        UserDefaults.standard.removeObject(forKey: Keys.queuedDeepLinkURL)

        logger.info(tag, "Processing queued post-auth deep link: \(urlString)")
        _ = handleURL(url)
    }

    /// Clear the pending destination after navigation has been performed.
    func clearPendingDestination() {
        pendingDestination = nil
    }

    // MARK: - Referral Code Management

    /// Store a referral code for processing after authentication.
    private func storeReferralCode(_ code: String) {
        UserDefaults.standard.set(code, forKey: "com.getmodus.referral.pendingCode")
        logger.info(tag, "Stored pending referral code: \(code)")
    }

    /// Retrieve and consume the pending referral code.
    /// Returns nil if no code is pending.
    func consumePendingReferralCode() -> String? {
        guard let code = UserDefaults.standard.string(forKey: "com.getmodus.referral.pendingCode") else {
            return nil
        }
        UserDefaults.standard.removeObject(forKey: "com.getmodus.referral.pendingCode")
        logger.info(tag, "Consumed pending referral code: \(code)")
        return code
    }

    // MARK: - Private Helpers

    /// Persist first-install attribution to UserDefaults (write-once).
    private func storeFirstInstallAttribution(_ attribution: AttributionData) {
        guard UserDefaults.standard.data(forKey: Keys.firstInstallAttribution) == nil else {
            logger.diagnostic("[\(tag)] First install attribution already stored — skipping")
            return
        }

        do {
            let data = try JSONEncoder().encode(attribution)
            UserDefaults.standard.set(data, forKey: Keys.firstInstallAttribution)
            logger.success(tag, "Stored first install attribution")
        } catch {
            logger.error(tag, "Failed to encode first install attribution: \(error.localizedDescription)")
        }
    }

    /// Retrieve the stored first-install attribution data.
    func getFirstInstallAttribution() -> AttributionData? {
        guard let data = UserDefaults.standard.data(forKey: Keys.firstInstallAttribution) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(AttributionData.self, from: data)
        } catch {
            logger.error(tag, "Failed to decode first install attribution: \(error.localizedDescription)")
            return nil
        }
    }

    /// Append attribution to the rolling history in UserDefaults.
    private func appendAttributionHistory(_ attribution: AttributionData) {
        var history = getAttributionHistory()
        history.append(attribution)

        // Keep last 50 attribution events
        if history.count > 50 {
            history = Array(history.suffix(50))
        }

        do {
            let data = try JSONEncoder().encode(history)
            UserDefaults.standard.set(data, forKey: Keys.attributionHistory)
        } catch {
            logger.error(tag, "Failed to encode attribution history: \(error.localizedDescription)")
        }
    }

    /// Retrieve the attribution history.
    func getAttributionHistory() -> [AttributionData] {
        guard let data = UserDefaults.standard.data(forKey: Keys.attributionHistory) else {
            return []
        }

        do {
            return try JSONDecoder().decode([AttributionData].self, from: data)
        } catch {
            logger.error(tag, "Failed to decode attribution history: \(error.localizedDescription)")
            return []
        }
    }

    /// Sync attribution data to Supabase analytics table.
    private func syncAttributionToSupabase(_ attribution: AttributionData) async {
        let supabase = PTSupabaseClient.shared

        // Only sync if we have a valid client configuration
        guard supabase.isConfigurationValid else {
            logger.warning(tag, "Supabase not configured — skipping attribution sync")
            return
        }

        do {
            let payload: [String: String] = attribution.asDictionary.merging([
                "user_id": supabase.userId ?? "anonymous",
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                "build_number": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
            ]) { _, new in new }

            try await supabase.client
                .from("deep_link_attributions")
                .insert(payload)
                .execute()

            logger.success(tag, "Attribution synced to Supabase")
        } catch {
            // Attribution sync is best-effort — failures should not block UX
            logger.warning(tag, "Failed to sync attribution to Supabase: \(error.localizedDescription)")
        }
    }

    /// Log a deep link event for analytics.
    private func logDeepLinkEvent(url: URL, destination: DeepLinkDestination) {
        let event = DeepLinkEvent(
            url: url.absoluteString,
            destination: String(describing: destination),
            attribution: lastAttribution,
            timestamp: Date(),
            userId: PTSupabaseClient.shared.userId
        )

        // Log to ErrorLogger for analytics
        ErrorLogger.shared.logUserAction(
            action: "deep_link_opened",
            properties: [
                "url": event.url,
                "destination": event.destination,
                "has_attribution": event.attribution != nil ? "true" : "false",
                "source": event.attribution?.source ?? "none"
            ]
        )

        // Sync event to Supabase asynchronously
        Task {
            await syncDeepLinkEventToSupabase(event)
        }
    }

    /// Sync a deep link event to Supabase.
    private func syncDeepLinkEventToSupabase(_ event: DeepLinkEvent) async {
        do {
            let payload: [String: String] = [
                "url": event.url,
                "destination": event.destination,
                "timestamp": ISO8601DateFormatter().string(from: event.timestamp),
                "user_id": event.userId ?? "anonymous",
                "source": event.attribution?.source ?? "",
                "medium": event.attribution?.medium ?? "",
                "campaign": event.attribution?.campaign ?? ""
            ]

            try await PTSupabaseClient.shared.client
                .from("deep_link_events")
                .insert(payload)
                .execute()

            logger.diagnostic("[\(tag)] Deep link event synced to Supabase")
        } catch {
            logger.warning(tag, "Failed to sync deep link event: \(error.localizedDescription)")
        }
    }

    /// Build a simple device fingerprint for deferred deep link matching.
    /// Uses device model + locale + timezone as a best-effort identifier.
    private func buildDeviceFingerprint() -> String {
        let model = UIDevice.current.model
        let locale = Locale.current.identifier
        let timezone = TimeZone.current.identifier
        let raw = "\(model)-\(locale)-\(timezone)"
        // Simple hash — server side should use a more robust fingerprint
        return raw.data(using: .utf8)?.base64EncodedString() ?? raw
    }
}
