import Foundation

/// Configuration for Modus app
/// Contains Supabase credentials and other app settings
enum Config {
    // MARK: - Supabase Configuration

    static let supabaseURL: String = {
        #if DEBUG
        return ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "https://rpbxeaxlaoyoqkohytlw.supabase.co"
        #else
        guard let url = ProcessInfo.processInfo.environment["SUPABASE_URL"], !url.isEmpty else {
            fatalError("SUPABASE_URL not configured for production build")
        }
        return url
        #endif
    }()

    static let supabaseAnonKey: String = {
        #if DEBUG
        return ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJwYnhlYXhsYW95b3Frb2h5dGx3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ5OTkwMTgsImV4cCI6MjA4MDU3NTAxOH0.7RHRs-pdfbqQf9SYvg5C0e5OGktuXHVrJtsm7-fXxLo"
        #else
        guard let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !key.isEmpty else {
            fatalError("SUPABASE_ANON_KEY not configured for production build")
        }
        return key
        #endif
    }()

    // MARK: - Backend Configuration

    /// Backend API URL - uses Supabase Edge Functions for all builds
    static let backendURL: String = ProcessInfo.processInfo.environment["BACKEND_URL"] ?? "\(supabaseURL)/functions/v1"

    // MARK: - App Configuration

    static let appVersion = "1.0.0"
    static let buildNumber: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"

    // MARK: - Subscription Products
    /// Centralized product IDs for security - prevents hardcoding throughout the app
    /// These must match the product IDs configured in App Store Connect
    enum Subscription {
        /// Monthly subscription product ID (Pro tier)
        static let monthlyProductID = "com.getmodus.app.monthly"
        /// Annual subscription product ID (Pro tier)
        static let annualProductID = "com.getmodus.app.annual"
        /// Baseball Pack one-time purchase product ID
        static let baseballPackProductID = "com.getmodus.app.baseballpack"
        /// Subscription group identifier
        static let groupID = "Modus Premium"

        // ACP-986: Elite tier product IDs
        /// Monthly subscription product ID (Elite tier)
        static let eliteMonthlyProductID = "com.getmodus.app.elite.monthly"
        /// Annual subscription product ID (Elite tier)
        static let eliteAnnualProductID = "com.getmodus.app.elite.annual"

        /// All valid subscription/purchase product IDs
        static var allProductIDs: Set<String> {
            [monthlyProductID, annualProductID, baseballPackProductID,
             eliteMonthlyProductID, eliteAnnualProductID]
        }

        /// Validates if a product ID is known and valid
        static func isValidProductID(_ productID: String) -> Bool {
            allProductIDs.contains(productID)
        }
    }

    // MARK: - WHOOP Integration (Build 40)

    enum WHOOP {
        /// Error thrown when required WHOOP credentials are not configured
        enum ConfigurationError: Error, LocalizedError {
            case missingClientId
            case missingClientSecret

            var errorDescription: String? {
                switch self {
                case .missingClientId:
                    return "WHOOP_CLIENT_ID environment variable is not set"
                case .missingClientSecret:
                    return "WHOOP_CLIENT_SECRET environment variable is not set"
                }
            }
        }

        /// WHOOP client ID - must be set via WHOOP_CLIENT_ID environment variable
        /// Throws ConfigurationError.missingClientId if not set
        static func getClientId() throws -> String {
            guard let clientId = ProcessInfo.processInfo.environment["WHOOP_CLIENT_ID"], !clientId.isEmpty else {
                throw ConfigurationError.missingClientId
            }
            return clientId
        }

        /// WHOOP client secret - must be set via WHOOP_CLIENT_SECRET environment variable
        /// Throws ConfigurationError.missingClientSecret if not set
        static func getClientSecret() throws -> String {
            guard let clientSecret = ProcessInfo.processInfo.environment["WHOOP_CLIENT_SECRET"], !clientSecret.isEmpty else {
                throw ConfigurationError.missingClientSecret
            }
            return clientSecret
        }
    }

    // MARK: - AI Services Configuration (Build 79)

    struct AIConfig {
        // OpenAI Configuration
        static let openAIEnabled = true
        static let openAIModel = "gpt-4-turbo-preview"
        static let openAIMaxTokens = 500
        static let openAITemperature = 0.7

        // Anthropic Configuration
        static let anthropicEnabled = true
        static let anthropicModel = "claude-3-5-sonnet-20241022"
        static let anthropicMaxTokens = 1000
        static let anthropicTemperature = 0.3

        // Feature Flags (remote via FeatureFlagService, with local defaults)
        static var aiChatEnabled: Bool { FeatureFlagService.shared.isEnabled("ai_chat_enabled") }
        static var aiSubstitutionEnabled: Bool { FeatureFlagService.shared.isEnabled("ai_substitution_enabled") }
        static var aiSafetyEnabled: Bool { FeatureFlagService.shared.isEnabled("ai_safety_enabled") }
        static var aiProgressiveOverloadEnabled: Bool { FeatureFlagService.shared.isEnabled("ai_progressive_overload_enabled") }
        static var aiSoapSuggestionsEnabled: Bool { FeatureFlagService.shared.isEnabled("ai_soap_suggestions_enabled") }
        static var aiNutritionEnabled: Bool { FeatureFlagService.shared.isEnabled("ai_nutrition_enabled") }
        static var whoopIntegrationEnabled: Bool { FeatureFlagService.shared.isEnabled("whoop_integration_enabled") }
        static var baseballPackEnabled: Bool { FeatureFlagService.shared.isEnabled("baseball_pack_enabled") }
        static var eliteTierEnabled: Bool { FeatureFlagService.shared.isEnabled("elite_tier_enabled") }

        // Safety Configuration
        static let blockDangerLevel = true
        static let safetyCacheDuration: TimeInterval = 24 * 60 * 60 // 24 hours
        static let safetyDebounceDuration: TimeInterval = 5 * 60 // 5 minutes

        // Cost Controls
        static let maxChatHistoryMessages = 10
        static let maxDailyAPICallsPerAthlete = 100
    }

    // MARK: - MVP Feature Flags

    struct MVPConfig {
        static var isMVPMode: Bool { FeatureFlagService.shared.isEnabled("mvp_mode") }
        static var therapistModeEnabled: Bool { FeatureFlagService.shared.isEnabled("therapist_mode_enabled") }
        static var modeSelectionEnabled: Bool { FeatureFlagService.shared.isEnabled("mode_selection_enabled") }
        static var painTrackingEnabled: Bool { FeatureFlagService.shared.isEnabled("pain_tracking_enabled") }
        static var romExercisesEnabled: Bool { FeatureFlagService.shared.isEnabled("rom_exercises_enabled") }
        static var prTrackingEnabled: Bool { FeatureFlagService.shared.isEnabled("pr_tracking_enabled") }
        static var performanceAnalyticsEnabled: Bool { FeatureFlagService.shared.isEnabled("performance_analytics_enabled") }
        static var fastingTrackerEnabled: Bool { FeatureFlagService.shared.isEnabled("fasting_tracker_enabled") }
        static var biomarkerDashboardEnabled: Bool { FeatureFlagService.shared.isEnabled("biomarker_dashboard_enabled") }
        static var aiHealthCoachEnabled: Bool { FeatureFlagService.shared.isEnabled("ai_health_coach_enabled") }
        static var labUploadEnabled: Bool { FeatureFlagService.shared.isEnabled("lab_upload_enabled") }
        static var programsPacksEnabled: Bool { FeatureFlagService.shared.isEnabled("programs_packs_enabled") }
        static var programsTrendsEnabled: Bool { FeatureFlagService.shared.isEnabled("programs_trends_enabled") }
        static var programsHistoryEnabled: Bool { FeatureFlagService.shared.isEnabled("programs_history_enabled") }
        static var armCareEnabled: Bool { FeatureFlagService.shared.isEnabled("arm_care_enabled") }
        static var paywallEnabled: Bool { FeatureFlagService.shared.isEnabled("paywall_enabled") }
        static var modeDashboardsEnabled: Bool { FeatureFlagService.shared.isEnabled("mode_dashboards_enabled") }
        static var bodyCompToolsEnabled: Bool { FeatureFlagService.shared.isEnabled("body_comp_tools_enabled") }
        static var therapistLinkingEnabled: Bool { FeatureFlagService.shared.isEnabled("therapist_linking_enabled") }
    }
}
