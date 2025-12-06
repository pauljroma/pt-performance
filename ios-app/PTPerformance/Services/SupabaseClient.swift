import Foundation
import Supabase

/// Supabase client singleton for PT Performance app
/// Manages authentication and database access to Supabase backend
class PTSupabaseClient: ObservableObject {
    static let shared = PTSupabaseClient()

    let client: Supabase.SupabaseClient

    @Published var currentSession: Session?
    @Published var currentUser: User?
    @Published var userRole: UserRole?
    @Published var userId: String?

    private init() {
        // Load from environment or configuration
        let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "https://your-project.supabase.co"
        let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? "your-anon-key"

        guard let url = URL(string: supabaseURL) else {
            fatalError("Invalid Supabase URL")
        }

        client = Supabase.SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseAnonKey
        )

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
        let email = "demo-patient@ptperformance.app"
        let password = "demo-patient-password"

        try await signIn(email: email, password: password)
    }

    /// Sign in as demo therapist (Sarah Thompson)
    func signInAsDemoTherapist() async throws {
        // Demo therapist credentials
        let email = "demo-pt@ptperformance.app"
        let password = "demo-therapist-password"

        try await signIn(email: email, password: password)
    }

    /// Fetch user role from database (patient or therapist)
    private func fetchUserRole(userId: String) async {
        do {
            // Check if user is a patient
            let patientResponse: [Patient] = try await client
                .from("patients")
                .select()
                .eq("auth_user_id", value: userId)
                .execute()
                .value

            if !patientResponse.isEmpty {
                await MainActor.run {
                    self.userRole = .patient
                    self.userId = patientResponse[0].id
                }
                return
            }

            // Check if user is a therapist
            let therapistResponse: [Therapist] = try await client
                .from("therapists")
                .select()
                .eq("auth_user_id", value: userId)
                .execute()
                .value

            if !therapistResponse.isEmpty {
                await MainActor.run {
                    self.userRole = .therapist
                    self.userId = therapistResponse[0].id
                }
                return
            }

            print("⚠️ User not found in patients or therapists table")
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

    // MARK: - Data Models

    struct Patient: Codable {
        let id: String
        let auth_user_id: String?
        let therapist_id: String
        let first_name: String
        let last_name: String
        let email: String
        let sport: String
        let position: String?
    }

    struct Therapist: Codable {
        let id: String
        let auth_user_id: String?
        let first_name: String
        let last_name: String
        let email: String
    }
}

enum UserRole: String {
    case patient
    case therapist
}
