//
//  Config.swift
//  PTPerformance
//
//  Configuration constants for the app
//

import Foundation

struct Config {
    // MARK: - Supabase
    static let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
    static let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""

    // MARK: - WHOOP Integration (Build 76)
    static let whoopClientId = ProcessInfo.processInfo.environment["WHOOP_CLIENT_ID"] ?? ""
    static let whoopClientSecret = ProcessInfo.processInfo.environment["WHOOP_CLIENT_SECRET"] ?? ""
    static let whoopRedirectUri = "ptperformance://whoop/callback"

    // MARK: - AI Integration (Build 77)
    static let openaiAPIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    static let anthropicAPIKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""

    // MARK: - Feature Flags
    static let isWHOOPEnabled = true
    static let isAIHelperEnabled = true

    // MARK: - API Endpoints
    static var whoopOAuthCallbackURL: String {
        return "\(supabaseURL)/functions/v1/whoop-oauth-callback"
    }

    static var whoopSyncRecoveryURL: String {
        return "\(supabaseURL)/functions/v1/whoop-sync-recovery"
    }

    static var aiChatCompletionURL: String {
        return "\(supabaseURL)/functions/v1/ai-chat-completion"
    }

    static var aiExerciseSubstitutionURL: String {
        return "\(supabaseURL)/functions/v1/ai-exercise-substitution"
    }

    static var aiSafetyCheckURL: String {
        return "\(supabaseURL)/functions/v1/ai-safety-check"
    }
}
