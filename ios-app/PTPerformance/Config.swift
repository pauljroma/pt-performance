import Foundation

/// Configuration for PT Performance app
/// Contains Supabase credentials and other app settings
enum Config {
    // MARK: - Supabase Configuration

    static let supabaseURL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
    static let supabaseAnonKey = "sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr"

    // MARK: - Backend Configuration

    /// Backend API URL - uses Supabase Edge Functions for all builds
    static let backendURL: String = ProcessInfo.processInfo.environment["BACKEND_URL"] ?? "\(supabaseURL)/functions/v1"

    // MARK: - App Configuration

    static let appVersion = "1.0"
    static let buildNumber = "88"

    // MARK: - Subscription Products
    enum Subscription {
        static let monthlyProductID = "com.getmodus.app.monthly"
        static let annualProductID = "com.getmodus.app.annual"
        static let groupID = "PTPerformance Premium"
    }

    // MARK: - WHOOP Integration (Build 40)

    enum WHOOP {
        // WHOOP API credentials - registered app at https://developer.whoop.com
        static let clientId = ProcessInfo.processInfo.environment["WHOOP_CLIENT_ID"] ?? "1c0e3e35-1892-4efb-97f8-878be04c3095"
        static let clientSecret = ProcessInfo.processInfo.environment["WHOOP_CLIENT_SECRET"] ?? "deb077841909f55c5ccaf0be8625d2dc3497e16533909bf5f9030abe17f6c1d5"
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

        // Feature Flags
        static let aiChatEnabled = true
        static let aiSubstitutionEnabled = true
        static let aiSafetyEnabled = true

        // Safety Configuration
        static let blockDangerLevel = true
        static let safetyCacheDuration: TimeInterval = 24 * 60 * 60 // 24 hours
        static let safetyDebounceDuration: TimeInterval = 5 * 60 // 5 minutes

        // Cost Controls
        static let maxChatHistoryMessages = 10
        static let maxDailyAPICallsPerAthlete = 100
    }
}
