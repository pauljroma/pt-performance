//
//  WHOOPService.swift
//  PTPerformance
//
//  Build 76 - WHOOP Integration
//

import Foundation
import SwiftUI

/// Service for WHOOP API integration via Supabase Edge Functions
class WHOOPService: ObservableObject {
    static let shared = WHOOPService()

    @Published var isConnected: Bool = false
    @Published var currentRecovery: WHOOPRecovery?
    @Published var isLoading: Bool = false

    private let supabase = SupabaseManager.shared

    // MARK: - OAuth Flow

    func startOAuthFlow() {
        // Open WHOOP OAuth URL
        let clientId = Config.whoopClientId
        let redirectUri = Config.whoopRedirectUri
        let authURL = "https://api.whoop.com/oauth/authorize?client_id=\(clientId)&redirect_uri=\(redirectUri)&response_type=code&scope=read:recovery read:sleep read:workout"

        if let url = URL(string: authURL) {
            UIApplication.shared.open(url)
        }
    }

    func handleOAuthCallback(code: String) async throws {
        // Exchange code for access token via Supabase Edge Function
        isLoading = true
        defer { isLoading = false }

        let athleteId = await SupabaseManager.shared.currentAthlete?.id.uuidString ?? ""

        let response = try await supabase.functions.invoke(
            "whoop-oauth-callback",
            body: ["code": code, "athlete_id": athleteId]
        )

        await MainActor.run {
            self.isConnected = true
        }

        // Trigger initial sync
        await syncRecovery()
    }

    // MARK: - Data Sync

    func syncRecovery() async {
        guard isConnected else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let athleteId = await SupabaseManager.shared.currentAthlete?.id.uuidString ?? ""

            // Call Supabase Edge Function to sync WHOOP data
            _ = try await supabase.functions.invoke(
                "whoop-sync-recovery",
                body: ["athlete_id": athleteId]
            )

            // Fetch latest recovery from database
            await fetchCurrentRecovery()
        } catch {
            print("❌ WHOOP sync failed: \(error)")
        }
    }

    func fetchCurrentRecovery() async {
        do {
            let athleteId = await SupabaseManager.shared.currentAthlete?.id ?? UUID()

            let query = supabase.database
                .from("whoop_recovery")
                .select()
                .eq("athlete_id", value: athleteId.uuidString)
                .order("date", ascending: false)
                .limit(1)

            let response: [WHOOPRecovery] = try await query.execute().value

            await MainActor.run {
                self.currentRecovery = response.first
            }
        } catch {
            print("❌ Failed to fetch WHOOP recovery: \(error)")
        }
    }

    func checkConnectionStatus() async {
        do {
            let athleteId = await SupabaseManager.shared.currentAthlete?.id ?? UUID()

            let query = supabase.database
                .from("whoop_credentials")
                .select("id")
                .eq("athlete_id", value: athleteId.uuidString)
                .limit(1)

            let response: [WHOOPCredentials] = try await query.execute().value

            await MainActor.run {
                self.isConnected = !response.isEmpty
            }

            if isConnected {
                await fetchCurrentRecovery()
            }
        } catch {
            print("❌ Failed to check WHOOP connection: \(error)")
        }
    }

    // MARK: - Readiness Band Calculation

    func getReadinessBand(from recoveryScore: Double) -> ReadinessBand {
        switch recoveryScore {
        case 67...100:
            return .green
        case 34..<67:
            return .yellow
        default:
            return .red
        }
    }

    func calculateSessionAdjustment(from recoveryScore: Double) -> SessionAdjustment {
        switch recoveryScore {
        case 67...100:
            return SessionAdjustment(
                volumeMultiplier: 1.0,
                intensity: .high,
                notes: "High recovery - ready for demanding sessions"
            )
        case 34..<67:
            return SessionAdjustment(
                volumeMultiplier: 0.85,
                intensity: .moderate,
                notes: "Moderate recovery - reduce volume to 85%"
            )
        default:
            return SessionAdjustment(
                volumeMultiplier: 0.65,
                intensity: .low,
                notes: "Low recovery - focus on technique, reduce to 65% volume"
            )
        }
    }

    // MARK: - Disconnect

    func disconnect() async {
        do {
            let athleteId = await SupabaseManager.shared.currentAthlete?.id ?? UUID()

            // Remove WHOOP credentials from database
            _ = try await supabase.database
                .from("whoop_credentials")
                .delete()
                .eq("athlete_id", value: athleteId.uuidString)
                .execute()

            await MainActor.run {
                self.isConnected = false
                self.currentRecovery = nil
            }
        } catch {
            print("❌ Failed to disconnect WHOOP: \(error)")
        }
    }
}

// Minimal WHOOPCredentials struct for connection check
private struct WHOOPCredentials: Codable {
    let id: UUID
}
