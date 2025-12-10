import Foundation

/// Configuration for PT Performance app
/// Contains Supabase credentials and other app settings
enum Config {
    // MARK: - Supabase Configuration

    static let supabaseURL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJwYnhlYXhsYW95b3Frb2h5dGx3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzMyNDc3MDMsImV4cCI6MjA0ODgyMzcwM30.ecg4DRB_cgq@azx4vcr"

    // MARK: - Backend Configuration

    /// Backend API URL - uses Supabase Edge Functions for all builds
    static let backendURL: String = ProcessInfo.processInfo.environment["BACKEND_URL"] ?? "\(supabaseURL)/functions/v1"

    // MARK: - App Configuration

    static let appVersion = "1.0"
    static let buildNumber = "1"

    // MARK: - Demo Credentials

    enum Demo {
        static let patientEmail = "demo-athlete@ptperformance.app"
        static let patientPassword = "demo-patient-2025"

        static let therapistEmail = "demo-pt@ptperformance.app"
        static let therapistPassword = "demo-therapist-2025"
    }
}
