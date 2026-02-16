import Foundation
import Supabase

/// Supabase client singleton for Modus app.
///
/// Manages authentication and database access to Supabase backend.
/// Provides a centralized point of access for all Supabase operations.
///
/// ## Features
/// - Session management and persistence
/// - User authentication (email/password, Apple Sign In)
/// - Role-based access (patient vs therapist)
/// - Flexible date decoding for multiple PostgreSQL date formats
///
/// ## Usage
/// ```swift
/// let client = PTSupabaseClient.shared
/// try await client.signIn(email: "user@example.com", password: "password")
/// ```
///
/// ## Thread Safety
/// Published properties are updated on MainActor. Database operations are async.
class PTSupabaseClient: ObservableObject {
    static let shared = PTSupabaseClient()

    let client: Supabase.SupabaseClient

    @Published var currentSession: Supabase.Session?
    @Published var currentUser: Supabase.User?
    @Published var userRole: UserRole?
    @Published var userId: String?
    @Published var isOffline = false

    /// Indicates whether the client was initialized with a valid configuration
    /// When false, all operations will fail gracefully
    private(set) var isConfigurationValid = true

    // MARK: - Shared Flexible Date Decoder

    /// Shared decoder for all Supabase queries that handles multiple date formats.
    ///
    /// **Why flexible decoding is required:**
    /// Supabase/PostgreSQL uses different column types for temporal data, each returning different formats:
    /// - `TIMESTAMPTZ` columns return ISO8601 with fractional seconds: `2024-01-15T10:30:00.123456+00:00`
    /// - `TIMESTAMP` columns return ISO8601 without timezone: `2024-01-15T10:30:00`
    /// - `DATE` columns return simple date format: `2024-01-15`
    /// - `TIME` columns return time only: `10:30:00`
    ///
    /// The meal_plans table uses DATE columns for start_date/end_date (calendar dates without time),
    /// while created_at/updated_at use TIMESTAMPTZ (precise timestamps). This decoder handles both
    /// seamlessly so model code doesn't need to worry about the underlying column types.
    ///
    /// **Usage:**
    /// - This decoder is automatically configured in the SupabaseClient options for `.execute().value` calls
    /// - For manual decoding with `.execute()`, use `PTSupabaseClient.flexibleDecoder`
    ///
    /// Flexible decoder with comprehensive documentation
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
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
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
        // ACP-932/945: Cold Start & Main Thread Optimization
        // Minimize synchronous work during init - defer logging to background

        // Load from Config (with environment variable override support)
        let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? Config.supabaseURL
        let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? Config.supabaseAnonKey

        // Validate URL; use a placeholder if invalid to prevent crash (client will be non-functional)
        let url: URL
        if let validUrl = URL(string: supabaseURL) {
            url = validUrl
        } else {
            isConfigurationValid = false
            // Use a placeholder URL to allow initialization; all operations will fail gracefully
            // This URL is guaranteed to be valid (only contains ASCII alphanumeric and standard URL characters)
            var components = URLComponents()
            components.scheme = "https"
            components.host = "invalid.supabase.co"
            url = components.url ?? URL(fileURLWithPath: "/")
        }

        // CRASH FIX: Supabase SDK 2.41.1 has a force unwrap on `supabaseURL.host!` at
        // SupabaseClient.swift:168 when computing the default auth storage key.
        // By providing `storageKey` explicitly, we bypass the SDK's dangerous code path entirely.
        // This prevents EXC_BREAKPOINT/SIGTRAP crashes on iOS versions where URL.host may
        // return nil (observed on iOS 26.x with new URL parser behavior).
        let projectRef = url.host?.split(separator: ".").first.map(String.init) ?? "modus"
        let authStorageKey = "sb-\(projectRef)-auth-token"

        // Use flexible decoder for all database queries
        // Handles ISO8601 (with/without fractional seconds), DATE (yyyy-MM-dd), and TIME (HH:mm:ss)
        // Auth configuration: PKCE flow (recommended for mobile) with URL scheme redirect
        client = Supabase.SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseAnonKey,
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(decoder: PTSupabaseClient.flexibleDecoder),
                auth: SupabaseClientOptions.AuthOptions(
                    redirectToURL: URL(string: "modus://auth"),
                    storageKey: authStorageKey,
                    flowType: .pkce,
                    autoRefreshToken: true
                )
            )
        )

        // ACP-932/945: Defer logging and session check to avoid blocking main thread
        let isValid = isConfigurationValid
        let urlString = supabaseURL
        let keyPrefix = String(supabaseAnonKey.prefix(20))

        Task(priority: .utility) {
            let logger = DebugLogger.shared
            #if DEBUG
            logger.log("Initializing PTSupabaseClient...")
            logger.log("Supabase URL: \(urlString)")
            logger.log("Anon Key: \(keyPrefix)...")
            #endif

            if !isValid {
                logger.log("Invalid Supabase URL: \(urlString). Client will be non-functional.", level: .error)
            }

            #if DEBUG
            logger.log("Supabase client initialized with flexible decoder", level: .success)
            #endif
        }

        // Note: Session restore is handled by RootView.restoreSession() which also
        // updates AppState. We intentionally do NOT call checkSession() here to avoid
        // a race condition where both paths concurrently read/write auth state.
    }

    /// Checks for an existing persisted authentication session
    ///
    /// Called automatically on initialization to restore any previously
    /// authenticated session. If a valid session exists, updates
    /// `currentSession`, `currentUser`, and fetches the user role.
    ///
    /// - Note: Fails silently if no session exists, logging in debug builds
    func checkSession() async {
        do {
            let session = try await client.auth.session
            await MainActor.run {
                self.currentSession = session
                self.currentUser = session.user
                // Set hasActiveSession flag for Siri intent compatibility
                // Note: App Intents cannot access SecureStore, so we use UserDefaults for this boolean flag only
                UserDefaults.standard.set(true, forKey: "hasActiveSession")
            }

            // Fetch user role from database
            await fetchUserRole(userId: session.user.id.uuidString)
        } catch {
            await MainActor.run {
                // Clear hasActiveSession flag when no session exists
                UserDefaults.standard.set(false, forKey: "hasActiveSession")
            }
            DebugLogger.shared.log("[SupabaseClient] No existing session: \(error.localizedDescription)", level: .diagnostic)
        }
    }

    /// Signs in a user with email and password credentials
    ///
    /// Authenticates against Supabase Auth and fetches the user's role from
    /// the database. If no role is found, automatically registers the user
    /// as a patient (handles edge cases from incomplete signups).
    ///
    /// - Parameters:
    ///   - email: The user's email address
    ///   - password: The user's password
    ///
    /// - Throws: Supabase authentication errors if credentials are invalid
    func signIn(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)

        await MainActor.run {
            self.currentSession = session
            self.currentUser = session.user
            // Set hasActiveSession flag for Siri intent compatibility
            UserDefaults.standard.set(true, forKey: "hasActiveSession")
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

    /// Fetches the user role from the database (patient or therapist)
    ///
    /// Determines whether the authenticated user is a patient or therapist by
    /// querying both tables. Prioritizes lookup by `user_id` (exact match to
    /// Supabase auth user), then falls back to email lookup for legacy records.
    ///
    /// - Parameter userId: The Supabase auth user ID (UUID string)
    ///
    /// - Note: Updates `userRole` and `userId` published properties on success.
    ///         Fails silently on error, logging in debug builds.
    func fetchUserRole(userId: String) async {
        // Get user email from auth session (may be nil for Apple Sign-In with hidden email)
        let userEmail = currentUser?.email

        do {
            // First: look up patient by user_id (exact match to Supabase auth user)
            let patientByAuthId: [AuthPatient] = try await client
                .from("patients")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            if let patient = patientByAuthId.first {
                await MainActor.run {
                    self.userRole = .patient
                    self.userId = patient.id.uuidString
                }
                DebugLogger.shared.log("[SupabaseClient] Found patient by user_id: \(patient.first_name) \(patient.last_name)", level: .success)
                return
            }

            // Second: look up therapist by user_id
            let therapistByAuthId: [AuthTherapist] = try await client
                .from("therapists")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            if let therapist = therapistByAuthId.first {
                await MainActor.run {
                    self.userRole = .therapist
                    self.userId = therapist.id.uuidString
                }
                DebugLogger.shared.log("[SupabaseClient] Found therapist by user_id: \(therapist.first_name) \(therapist.last_name)", level: .success)
                return
            }

            // Fallback: look up by email for legacy records without user_id
            // Skip email-based lookup if email is not available (e.g., Apple Sign-In with hidden email)
            guard let userEmail = userEmail else {
                DebugLogger.shared.log("[SupabaseClient] No user email available for fallback lookup, userId: \(userId)", level: .warning)
                return
            }

            let patientByEmail: [AuthPatient] = try await client
                .from("patients")
                .select()
                .eq("email", value: userEmail)
                .execute()
                .value

            if let patient = patientByEmail.first {
                await MainActor.run {
                    self.userRole = .patient
                    self.userId = patient.id.uuidString
                }
                DebugLogger.shared.log("[SupabaseClient] Found patient by email (legacy): \(patient.first_name) \(patient.last_name)", level: .success)
                return
            }

            let therapistByEmail: [AuthTherapist] = try await client
                .from("therapists")
                .select()
                .eq("email", value: userEmail)
                .execute()
                .value

            if let therapist = therapistByEmail.first {
                await MainActor.run {
                    self.userRole = .therapist
                    self.userId = therapist.id.uuidString
                }
                DebugLogger.shared.log("[SupabaseClient] Found therapist by email (legacy): \(therapist.first_name) \(therapist.last_name)", level: .success)
                return
            }

            DebugLogger.shared.log("[SupabaseClient] User not found in patients or therapists table for userId: \(userId), email: \(userEmail)", level: .warning)
        } catch {
            DebugLogger.shared.log("[SupabaseClient] Error fetching user role: \(error.localizedDescription)", level: .error)
        }
    }

    /// Creates a new user account with email and password
    ///
    /// Registers a new user with Supabase Auth and creates the corresponding
    /// patient record. Handles both immediate session flows (no email confirmation)
    /// and email confirmation flows.
    ///
    /// - Parameters:
    ///   - email: The user's email address
    ///   - password: The user's password (minimum 6 characters)
    ///   - fullName: The user's display name
    ///
    /// - Throws: Supabase authentication errors if registration fails
    ///
    /// - Note: New users are always registered as patients. Therapist accounts
    ///         must be created through a separate administrative process.
    func signUp(email: String, password: String, fullName: String) async throws {
        let response = try await client.auth.signUp(email: email, password: password)

        // If we got an immediate session (no email confirmation required)
        if let session = response.session {
            await MainActor.run {
                self.currentSession = session
                self.currentUser = session.user
                // Set hasActiveSession flag for Siri intent compatibility
                UserDefaults.standard.set(true, forKey: "hasActiveSession")
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
            DebugLogger.shared.log("[SupabaseClient] User registered, awaiting email confirmation", level: .success)
        }
    }

    /// Signs in a user using Apple Sign In credentials
    ///
    /// Authenticates with Supabase using the Apple ID token. Does NOT call
    /// `fetchUserRole()` — the caller must handle role detection after any
    /// registration step to avoid race conditions with new users.
    ///
    /// - Parameters:
    ///   - idToken: The identity token from Apple Sign In
    ///   - nonce: The cryptographic nonce used during the sign-in request
    ///
    /// - Throws: Supabase authentication errors if sign-in fails
    ///
    /// - Important: After calling this method, the caller should check if
    ///              the user needs to be registered as a patient before
    ///              calling `fetchUserRole()`.
    func signInWithApple(idToken: String, nonce: String) async throws {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        await MainActor.run {
            self.currentSession = session
            self.currentUser = session.user
            // Set hasActiveSession flag for Siri intent compatibility
            UserDefaults.standard.set(true, forKey: "hasActiveSession")
        }
    }

    /// Registers a new patient record via the edge function
    ///
    /// Creates a patient record in the database linked to the authenticated user.
    /// This is called automatically during sign-up or when a user signs in without
    /// an existing role.
    ///
    /// - Parameters:
    ///   - userId: The Supabase auth user ID
    ///   - email: The user's email address
    ///   - fullName: The user's display name
    ///   - authProvider: The authentication provider ("email" or "apple")
    ///
    /// - Throws: Edge function errors if registration fails
    func registerPatient(userId: String, email: String, fullName: String, authProvider: String) async throws {
        let body: [String: String] = [
            "userId": userId, "email": email, "fullName": fullName, "authProvider": authProvider
        ]
        _ = try await client.functions.invoke("register-patient", options: .init(body: body))
    }

    /// Sends a magic link email to log the user back in
    ///
    /// - Parameter email: The email address to send the magic link to
    ///
    /// - Throws: Supabase authentication errors if the request fails
    ///
    /// - Note: The magic link redirects to `modus://auth` and logs user in directly
    func sendMagicLink(email: String) async throws {
        do {
            try await client.auth.signInWithOTP(
                email: email,
                redirectTo: URL(string: "modus://auth")
            )
            DebugLogger.shared.success("SupabaseClient", "Magic link sent to \(email)")
        } catch {
            DebugLogger.shared.error("SupabaseClient", "Failed to send magic link: \(error)")
            DebugLogger.shared.error("SupabaseClient", "Error details: \(String(describing: error))")
            throw error
        }
    }

    /// Legacy password reset - sends a password reset email
    /// Use sendMagicLink() instead for simpler login flow
    func resetPassword(email: String) async throws {
        do {
            try await client.auth.resetPasswordForEmail(
                email,
                redirectTo: URL(string: "modus://reset-password")
            )
            DebugLogger.shared.success("SupabaseClient", "Password reset email sent to \(email)")
        } catch {
            DebugLogger.shared.error("SupabaseClient", "Failed to send password reset: \(error)")
            DebugLogger.shared.error("SupabaseClient", "Error details: \(String(describing: error))")
            throw error
        }
    }

    /// Updates the current user's password
    ///
    /// - Parameter newPassword: The new password to set
    ///
    /// - Throws: Supabase authentication errors if the update fails
    ///
    /// - Note: User must be authenticated (via password reset link session) before calling.
    ///         ACP-1040: After password change, SessionManager forces re-authentication
    ///         on all other sessions by invalidating the stored session fingerprint.
    func updatePassword(newPassword: String) async throws {
        try await client.auth.update(user: .init(password: newPassword))

        // ACP-1040: Notify SessionManager that password changed
        // This triggers force logout so user must re-authenticate with new password
        await MainActor.run {
            SessionManager.shared.handlePasswordChanged()
        }
    }

    /// Sign out
    /// Clears Supabase session and all securely stored credentials.
    /// Local state is always cleared even if the server-side sign-out fails,
    /// to prevent the app from being stuck in a "logged in" state with an
    /// invalid session.
    func signOut() async throws {
        // Attempt server-side sign out, but capture the error to clear local state regardless
        var signOutError: Error?
        do {
            try await client.auth.signOut()
        } catch {
            signOutError = error
            DebugLogger.shared.error("SupabaseClient", "Server-side sign out failed: \(error.localizedDescription)")
        }

        // Clear securely stored tokens and credentials
        await MainActor.run {
            AppleSignInService.shared.clearStoredCredentials()
        }

        // Clear WHOOP tokens if stored
        do {
            try SecureStore.shared.delete(forKey: SecureStore.Keys.whoopAccessToken)
            try SecureStore.shared.delete(forKey: SecureStore.Keys.whoopRefreshToken)
        } catch {
            // Silent fail - tokens may not exist
        }

        // Always clear local state to prevent inconsistent auth state
        await MainActor.run {
            self.currentSession = nil
            self.currentUser = nil
            self.userRole = nil
            self.userId = nil
            // Clear hasActiveSession flag for Siri intent compatibility
            UserDefaults.standard.set(false, forKey: "hasActiveSession")
        }

        // Re-throw the error after cleanup so callers know sign-out had issues
        if let signOutError {
            throw signOutError
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
