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

    // MARK: - Feature Flags
    static let isWHOOPEnabled = true

    // MARK: - API Endpoints
    static var whoopOAuthCallbackURL: String {
        return "\(supabaseURL)/functions/v1/whoop-oauth-callback"
    }

    static var whoopSyncRecoveryURL: String {
        return "\(supabaseURL)/functions/v1/whoop-sync-recovery"
    }
}
