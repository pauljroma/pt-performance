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
    @Published var isOffline = false

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
        // BUILD 366: Added auth configuration to ensure JWT is included in all requests
        logger.log("Creating Supabase client with flexible decoder and auth config...")
        client = Supabase.SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseAnonKey,
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(decoder: PTSupabaseClient.flexibleDecoder),
                auth: SupabaseClientOptions.AuthOptions(
                    flowType: .implicit,
                    autoRefreshToken: true
                )
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
            #if DEBUG
            print("No existing session: \(error.localizedDescription)")
            #endif
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

        // If no role found, auto-register as patient (handles edge case where
        // registration failed during signup or user was created via Apple Sign-in)
        if userRole == nil {
            let userId = session.user.id.uuidString
            let userEmail = session.user.email ?? email
            try? await registerPatient(
                userId: userId,
                email: userEmail,
                fullName: userEmail.components(separatedBy: "@").first ?? "Patient",
                authProvider: "email"
            )
            await fetchUserRole(userId: userId)
        }
    }

    /// Fetch user role from database (patient or therapist)
    /// Looks up by user_id first (exact match), then falls back to email for legacy records
    func fetchUserRole(userId: String) async {
        // Get user email from auth session
        guard let userEmail = currentUser?.email else {
            #if DEBUG
            print("❌ No user email available")
            #endif
            return
        }

        do {
            // First: look up patient by user_id (exact match to Supabase auth user)
            let patientByAuthId: [AuthPatient] = try await client
                .from("patients")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            if !patientByAuthId.isEmpty {
                await MainActor.run {
                    self.userRole = .patient
                    self.userId = patientByAuthId[0].id.uuidString
                }
                #if DEBUG
                print("✅ Found patient by user_id: \(patientByAuthId[0].first_name) \(patientByAuthId[0].last_name)")
                #endif
                return
            }

            // Second: look up therapist by user_id
            let therapistByAuthId: [AuthTherapist] = try await client
                .from("therapists")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            if !therapistByAuthId.isEmpty {
                await MainActor.run {
                    self.userRole = .therapist
                    self.userId = therapistByAuthId[0].id.uuidString
                }
                #if DEBUG
                print("✅ Found therapist by user_id: \(therapistByAuthId[0].first_name) \(therapistByAuthId[0].last_name)")
                #endif
                return
            }

            // Fallback: look up by email for legacy records without user_id
            let patientByEmail: [AuthPatient] = try await client
                .from("patients")
                .select()
                .eq("email", value: userEmail)
                .execute()
                .value

            if !patientByEmail.isEmpty {
                await MainActor.run {
                    self.userRole = .patient
                    self.userId = patientByEmail[0].id.uuidString
                }
                #if DEBUG
                print("✅ Found patient by email (legacy): \(patientByEmail[0].first_name) \(patientByEmail[0].last_name)")
                #endif
                return
            }

            let therapistByEmail: [AuthTherapist] = try await client
                .from("therapists")
                .select()
                .eq("email", value: userEmail)
                .execute()
                .value

            if !therapistByEmail.isEmpty {
                await MainActor.run {
                    self.userRole = .therapist
                    self.userId = therapistByEmail[0].id.uuidString
                }
                #if DEBUG
                print("✅ Found therapist by email (legacy): \(therapistByEmail[0].first_name) \(therapistByEmail[0].last_name)")
                #endif
                return
            }

            #if DEBUG
            print("⚠️ User not found in patients or therapists table for userId: \(userId), email: \(userEmail)")
            #endif
        } catch {
            #if DEBUG
            print("❌ Error fetching user role: \(error.localizedDescription)")
            #endif
        }
    }

    /// Sign up with email and password
    /// BUILD 317: Fixed to handle both immediate session and email confirmation flows
    func signUp(email: String, password: String, fullName: String) async throws {
        let response = try await client.auth.signUp(email: email, password: password)

        // If we got an immediate session (no email confirmation required)
        if let session = response.session {
            await MainActor.run {
                self.currentSession = session
                self.currentUser = session.user
            }
            let userId = session.user.id.uuidString
            let userEmail = session.user.email ?? email
            try await registerPatient(userId: userId, email: userEmail, fullName: fullName, authProvider: "email")
            await fetchUserRole(userId: userId)
        } else {
            // Email confirmation required - session is nil but user was created
            // Still register the patient so they exist when they confirm email
            let user = response.user
            let userId = user.id.uuidString
            let userEmail = user.email ?? email
            try await registerPatient(userId: userId, email: userEmail, fullName: fullName, authProvider: "email")
            await MainActor.run {
                self.userRole = .patient
                self.userId = userId
            }
            #if DEBUG
            print("[Auth] User registered, awaiting email confirmation")
            #endif
        }
    }

    /// Sign in with Apple via Supabase
    /// Note: Does NOT call fetchUserRole() — caller must handle role detection
    /// after any registration step to avoid race conditions with new users.
    func signInWithApple(idToken: String, nonce: String) async throws {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        await MainActor.run {
            self.currentSession = session
            self.currentUser = session.user
        }
    }

    /// Register patient via edge function
    func registerPatient(userId: String, email: String, fullName: String, authProvider: String) async throws {
        let body: [String: String] = [
            "userId": userId, "email": email, "fullName": fullName, "authProvider": authProvider
        ]
        _ = try await client.functions.invoke("register-patient", options: .init(body: body))
    }

    /// Reset password
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(
            email,
            redirectTo: URL(string: "ptperformance://reset-password")
        )
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
        let user_id: UUID?
        let therapist_id: UUID?
        let first_name: String
        let last_name: String
        let email: String?
        let sport: String?
        let position: String?
    }

    /// Simplified therapist model for authentication lookup
    private struct AuthTherapist: Codable {
        let id: UUID
        let user_id: UUID?
        let first_name: String
        let last_name: String
        let email: String
    }
}

enum UserRole: String {
    case patient
    case therapist
}
