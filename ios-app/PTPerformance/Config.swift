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
    static let buildNumber = "33"

    // MARK: - Demo Credentials

    enum Demo {
        static let patientEmail = "demo-athlete@ptperformance.app"
        static let patientPassword = "demo-patient-2025"

        static let therapistEmail = "demo-pt@ptperformance.app"
        static let therapistPassword = "demo-therapist-2025"
    }
}
