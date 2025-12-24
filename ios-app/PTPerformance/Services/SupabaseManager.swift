//
//  SupabaseManager.swift
//  PTPerformance
//
//  Centralized Supabase client management
//  Created: 2025-12-20
//

import Foundation
import Supabase

/// Shared Supabase client instance
class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey
        )
    }
}
