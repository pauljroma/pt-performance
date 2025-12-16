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
    static let buildNumber = "60"

    // MARK: - Demo Credentials

    enum Demo {
        static let patientEmail = "demo-athlete@ptperformance.app"
        static let patientPassword = "demo-patient-2025"

        static let therapistEmail = "demo-pt@ptperformance.app"
        static let therapistPassword = "demo-therapist-2025"
    }

    // MARK: - WHOOP Integration (Build 40)

    enum WHOOP {
        // WHOOP API credentials - registered app at https://developer.whoop.com
        static let clientId = ProcessInfo.processInfo.environment["WHOOP_CLIENT_ID"] ?? "1c0e3e35-1892-4efb-97f8-878be04c3095"
        static let clientSecret = ProcessInfo.processInfo.environment["WHOOP_CLIENT_SECRET"] ?? "deb077841909f55c5ccaf0be8625d2dc3497e16533909bf5f9030abe17f6c1d5"
    }
}
