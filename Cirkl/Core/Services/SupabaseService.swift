import Foundation
import Supabase

// MARK: - SupabaseService
/// Service for authentication and user data management via Supabase
/// Handles: Auth (Apple Sign-In, Magic Link), User profiles, Preferences
@MainActor
final class SupabaseService: ObservableObject {

    // MARK: - Singleton
    static let shared = SupabaseService()

    // MARK: - Configuration
    /// Supabase credentials for CirKL iOS
    /// Note: anon key is safe to include - RLS protects data access
    private static let supabaseURL = URL(string: "https://konenzwguhnmnsqgcpnm.supabase.co")!
    private static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtvbmVuendndWhubW5zcWdjcG5tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgxMjkzMTEsImV4cCI6MjA4MzcwNTMxMX0.beyh6YD2eIZ4G6UZ32NWEJtlnx3wAFHuBsaoNONyL04"

    // MARK: - Client
    let client: SupabaseClient

    // MARK: - Published State
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var userPreferences: UserPreferences?

    // MARK: - Init
    private init() {
        // Configure client with PKCE flow for Magic Link
        // emitLocalSessionAsInitialSession: true ensures locally stored session is always emitted
        // See: https://github.com/supabase/supabase-swift/pull/822
        client = SupabaseClient(
            supabaseURL: Self.supabaseURL,
            supabaseKey: Self.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    redirectToURL: URL(string: "cirkl://auth/callback"),
                    flowType: .pkce,
                    emitLocalSessionAsInitialSession: true
                )
            )
        )

        // Listen for auth state changes
        Task {
            await setupAuthListener()
        }
    }

    // MARK: - Auth State Listener
    private func setupAuthListener() async {
        for await state in client.auth.authStateChanges {
            switch state.event {
            case .initialSession, .signedIn:
                if let session = state.session {
                    await handleSignIn(session: session)
                }
            case .signedOut:
                handleSignOut()
            default:
                break
            }
        }
    }

    private func handleSignIn(session: Session) async {
        isAuthenticated = true
        await fetchOrCreateUser(authId: session.user.id.uuidString, email: session.user.email)
        await fetchUserPreferences()

        #if DEBUG
        print("✅ Supabase: User signed in - \(session.user.email ?? "no email")")
        #endif
    }

    private func handleSignOut() {
        isAuthenticated = false
        currentUser = nil
        userPreferences = nil

        #if DEBUG
        print("🚪 Supabase: User signed out")
        #endif
    }
}

// MARK: - Authentication Methods
extension SupabaseService {

    /// Sign in with Apple
    /// Requires Apple Sign-In capability in Xcode + Supabase Apple provider config
    func signInWithApple(idToken: String, nonce: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
    }

    /// Sign in with Magic Link (email)
    func signInWithMagicLink(email: String) async throws {
        try await client.auth.signInWithOTP(
            email: email,
            redirectTo: URL(string: "cirkl://auth/callback")
        )

        #if DEBUG
        print("📧 Supabase: Magic link sent to \(email)")
        #endif
    }

    /// Sign out
    func signOut() async throws {
        try await client.auth.signOut()
    }

    /// Get current session
    var session: Session? {
        get async {
            try? await client.auth.session
        }
    }

    /// Check if user is logged in
    func checkSession() async -> Bool {
        let session = await session
        return session != nil
    }
}

// MARK: - User Management
extension SupabaseService {

    /// Fetch or create user profile in database
    private func fetchOrCreateUser(authId: String, email: String?) async {
        do {
            // Try to fetch existing user
            let existingUser: User? = try await client
                .from("users")
                .select()
                .eq("auth_id", value: authId)
                .single()
                .execute()
                .value

            if let user = existingUser {
                currentUser = user
            } else {
                // Create new user
                let newUser = User(
                    id: UUID().uuidString,
                    authId: authId,
                    email: email ?? "",
                    name: email?.components(separatedBy: "@").first ?? "User",
                    avatarURL: nil,
                    createdAt: Date()
                )

                try await client
                    .from("users")
                    .insert(newUser)
                    .execute()

                currentUser = newUser

                // Create default preferences
                await createDefaultPreferences(userId: newUser.id)
            }
        } catch {
            #if DEBUG
            print("❌ Supabase: Error fetching/creating user - \(error)")
            #endif
        }
    }

    /// Update user profile
    func updateUser(name: String? = nil, avatarURL: String? = nil) async throws {
        guard let userId = currentUser?.id else { return }

        var updates: [String: AnyJSON] = [:]
        if let name = name { updates["name"] = .string(name) }
        if let avatarURL = avatarURL { updates["avatar_url"] = .string(avatarURL) }
        updates["updated_at"] = .string(ISO8601DateFormatter().string(from: Date()))

        try await client
            .from("users")
            .update(updates)
            .eq("id", value: userId)
            .execute()

        // Refresh local state
        if let name = name { currentUser?.name = name }
        if let avatarURL = avatarURL { currentUser?.avatarURL = avatarURL }
    }
}

// MARK: - User Preferences
extension SupabaseService {

    /// Fetch user preferences
    func fetchUserPreferences() async {
        guard let userId = currentUser?.id else { return }

        do {
            let prefs: UserPreferences? = try await client
                .from("user_preferences")
                .select()
                .eq("user_id", value: userId)
                .single()
                .execute()
                .value

            userPreferences = prefs
        } catch {
            #if DEBUG
            print("⚠️ Supabase: No preferences found, using defaults")
            #endif
        }
    }

    /// Create default preferences for new user
    private func createDefaultPreferences(userId: String) async {
        let defaultPrefs = UserPreferences(
            userId: userId,
            morningBriefTime: "07:30",
            morningBriefEnabled: true,
            language: Locale.current.language.languageCode?.identifier ?? "en",
            notificationsEnabled: true
        )

        do {
            try await client
                .from("user_preferences")
                .insert(defaultPrefs)
                .execute()

            userPreferences = defaultPrefs
        } catch {
            #if DEBUG
            print("❌ Supabase: Error creating default preferences - \(error)")
            #endif
        }
    }

    /// Update user preferences
    func updatePreferences(
        morningBriefTime: String? = nil,
        morningBriefEnabled: Bool? = nil,
        language: String? = nil,
        notificationsEnabled: Bool? = nil
    ) async throws {
        guard let userId = currentUser?.id else { return }

        var updates: [String: AnyJSON] = [:]
        if let time = morningBriefTime { updates["morning_brief_time"] = .string(time) }
        if let enabled = morningBriefEnabled { updates["morning_brief_enabled"] = .bool(enabled) }
        if let lang = language { updates["language"] = .string(lang) }
        if let notifs = notificationsEnabled { updates["notifications_enabled"] = .bool(notifs) }

        try await client
            .from("user_preferences")
            .update(updates)
            .eq("user_id", value: userId)
            .execute()

        // Refresh local state
        await fetchUserPreferences()
    }
}

// MARK: - Models
extension SupabaseService {

    /// User model matching Supabase table
    struct User: Codable, Identifiable {
        let id: String
        let authId: String
        var email: String
        var name: String
        var avatarURL: String?
        let createdAt: Date
        var updatedAt: Date?

        enum CodingKeys: String, CodingKey {
            case id
            case authId = "auth_id"
            case email
            case name
            case avatarURL = "avatar_url"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }

    /// User preferences model matching Supabase table
    struct UserPreferences: Codable {
        let userId: String
        var morningBriefTime: String
        var morningBriefEnabled: Bool
        var language: String
        var notificationsEnabled: Bool

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case morningBriefTime = "morning_brief_time"
            case morningBriefEnabled = "morning_brief_enabled"
            case language
            case notificationsEnabled = "notifications_enabled"
        }
    }
}

// MARK: - Helper to get current userId for other services
extension SupabaseService {

    /// Returns the current user's ID for use in Neo4j/N8N calls
    /// Falls back to "Gil" for backward compatibility during migration
    var currentUserId: String {
        currentUser?.id ?? "Gil"  // TODO: Remove fallback after migration
    }

    /// Returns the current user's name
    var currentUserName: String {
        currentUser?.name ?? "User"
    }
}
