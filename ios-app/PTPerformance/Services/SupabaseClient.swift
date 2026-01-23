import Foundation
import Supabase

/// Supabase client singleton for PT Performance app
/// Manages authentication and database access to Supabase backend
class PTSupabaseClient: ObservableObject {
    static let shared = PTSupabaseClient()

    let client: Supabase.SupabaseClient

    @Published var currentSession: Supabase.Session?
    @Published var currentUser: Supabase.User?
    @Published var userRole: UserRole?
    @Published var userId: String?

    // BUILD 251: Shared flexible decoder for all Supabase queries
    static let flexibleDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with fractional seconds (Supabase TIMESTAMPTZ)
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }

            // Try ISO8601 without fractional seconds
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }

            // Try simple date format (yyyy-MM-dd for DATE columns)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            // Try time format (HH:mm:ss for TIME columns)
            dateFormatter.dateFormat = "HH:mm:ss"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
        return decoder
    }()

    private init() {
        let logger = DebugLogger.shared

        logger.log("Initializing PTSupabaseClient...")

        // Load from Config (with environment variable override support)
        let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? Config.supabaseURL
        let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? Config.supabaseAnonKey

        logger.log("Supabase URL: \(supabaseURL)")
        logger.log("Anon Key: \(supabaseAnonKey.prefix(20))...")

        guard let url = URL(string: supabaseURL) else {
            logger.log("Invalid Supabase URL: \(supabaseURL)", level: .error)
            fatalError("Invalid Supabase URL: \(supabaseURL)")
        }

        // BUILD 251: Use flexible decoder for all database queries
        // Handles ISO8601 (with/without fractional seconds), DATE (yyyy-MM-dd), and TIME (HH:mm:ss)
        logger.log("Creating Supabase client with flexible decoder...")
        client = Supabase.SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseAnonKey,
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(decoder: PTSupabaseClient.flexibleDecoder)
            )
        )

        logger.log("Supabase client initialized with flexible decoder", level: .success)

        // Check for existing session on init
        Task {
            await checkSession()
        }
    }

    /// Check for existing session (persisted auth)
    func checkSession() async {
        do {
            let session = try await client.auth.session
            await MainActor.run {
                self.currentSession = session
                self.currentUser = session.user
            }

            // Fetch user role from database
            await fetchUserRole(userId: session.user.id.uuidString)
        } catch {
            print("No existing session: \(error.localizedDescription)")
        }
    }

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)

        await MainActor.run {
            self.currentSession = session
            self.currentUser = session.user
        }

        // Fetch user role from database
        await fetchUserRole(userId: session.user.id.uuidString)
    }

    /// Sign in as demo patient (John Brebbia)
    func signInAsDemoPatient() async throws {
        // Demo patient credentials
        let email = "demo-athlete@ptperformance.app"
        let password = "demo-patient-2025"

        try await signIn(email: email, password: password)
    }

    /// Sign in as demo therapist (Sarah Thompson)
    func signInAsDemoTherapist() async throws {
        // Demo therapist credentials
        let email = "demo-pt@ptperformance.app"
        let password = "demo-therapist-2025"

        try await signIn(email: email, password: password)
    }

    /// Sign in as Nic Roma (demo patient with Winter Lift program)
    func signInAsNicRoma() async throws {
        // Nic Roma credentials
        let email = "nic-demo@ptperformance.app"
        let password = "demo-patient-2025"

        try await signIn(email: email, password: password)
    }

    /// Fetch user role from database (patient or therapist)
    private func fetchUserRole(userId: String) async {
        // Get user email from auth session
        guard let userEmail = currentUser?.email else {
            print("❌ No user email available")
            return
        }

        do {
            // Check if user is a patient (lookup by email)
            let patientResponse: [AuthPatient] = try await client
                .from("patients")
                .select()
                .eq("email", value: userEmail)
                .execute()
                .value

            if !patientResponse.isEmpty {
                await MainActor.run {
                    self.userRole = .patient
                    self.userId = patientResponse[0].id.uuidString
                }
                print("✅ Found patient: \(patientResponse[0].first_name) \(patientResponse[0].last_name)")
                return
            }

            // Check if user is a therapist (lookup by email)
            let therapistResponse: [AuthTherapist] = try await client
                .from("therapists")
                .select()
                .eq("email", value: userEmail)
                .execute()
                .value

            if !therapistResponse.isEmpty {
                await MainActor.run {
                    self.userRole = .therapist
                    self.userId = therapistResponse[0].id.uuidString
                }
                print("✅ Found therapist: \(therapistResponse[0].first_name) \(therapistResponse[0].last_name)")
                return
            }

            print("⚠️ User not found in patients or therapists table for email: \(userEmail)")
        } catch {
            print("❌ Error fetching user role: \(error.localizedDescription)")
        }
    }

    /// Sign out
    func signOut() async throws {
        try await client.auth.signOut()

        await MainActor.run {
            self.currentSession = nil
            self.currentUser = nil
            self.userRole = nil
            self.userId = nil
        }
    }

    // MARK: - Data Models (Auth Lookup)

    /// Simplified patient model for authentication lookup
    private struct AuthPatient: Codable {
        let id: UUID
        let auth_user_id: UUID?
        let therapist_id: UUID
        let first_name: String
        let last_name: String
        let email: String
        let sport: String
        let position: String?
    }

    /// Simplified therapist model for authentication lookup
    private struct AuthTherapist: Codable {
        let id: UUID
        let auth_user_id: UUID?
        let first_name: String
        let last_name: String
        let email: String
    }
}

enum UserRole: String {
    case patient
    case therapist
}
