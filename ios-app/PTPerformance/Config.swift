import Foundation

/// Configuration for Modus app
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
    static let buildNumber = "482"

    // MARK: - Subscription Products
    /// Centralized product IDs for security - prevents hardcoding throughout the app
    /// These must match the product IDs configured in App Store Connect
    enum Subscription {
        /// Monthly subscription product ID
        static let monthlyProductID = "com.getmodus.app.monthly"
        /// Annual subscription product ID
        static let annualProductID = "com.getmodus.app.annual"
        /// Baseball Pack one-time purchase product ID
        static let baseballPackProductID = "com.getmodus.app.baseballpack"
        /// Subscription group identifier
        static let groupID = "Modus Premium"

        /// All valid subscription/purchase product IDs
        static var allProductIDs: Set<String> {
            [monthlyProductID, annualProductID, baseballPackProductID]
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
