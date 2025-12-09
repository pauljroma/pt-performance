import Foundation

/// Configuration for PT Performance app
/// Contains Supabase credentials and other app settings
enum Config {
    // MARK: - Supabase Configuration

    static let supabaseURL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
    static let supabaseAnonKey = "sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3"

    // MARK: - Backend Configuration

    /// Backend API URL - defaults to Supabase functions in production, localhost in DEBUG
    static let backendURL: String = {
        #if DEBUG
        // Development: Use local backend if running
        return ProcessInfo.processInfo.environment["BACKEND_URL"] ?? "http://localhost:4000"
        #else
        // Production: Use Supabase Edge Functions or deployed backend
        return ProcessInfo.processInfo.environment["BACKEND_URL"] ?? "\(supabaseURL)/functions/v1"
        #endif
    }()

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
