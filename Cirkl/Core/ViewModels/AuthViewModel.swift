import SwiftUI
import Observation

@Observable
@MainActor
class AuthViewModel {
    var currentUser: User?
    var isAuthenticated: Bool { currentUser != nil }
    var isLoading = false
    var errorMessage: String?

    /// Authenticate user (MVP: simplified local auth)
    func authenticate(userId: String, name: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // MVP: Create local user without backend validation
        // TODO: Implement proper auth with N8N backend
        try? await Task.sleep(for: .milliseconds(500)) // Simulate network delay

        currentUser = User(
            name: name,
            email: "\(userId)@cirkl.app",
            sphere: .professional
        )
    }

    /// Quick dev login for testing
    func devLogin() async {
        await authenticate(userId: "gil", name: "Gil")
    }

    func signOut() {
        currentUser = nil
        errorMessage = nil
    }
}
