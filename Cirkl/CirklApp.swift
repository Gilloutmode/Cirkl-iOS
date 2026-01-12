import SwiftUI
import Supabase

@main
struct CirklApp: App {
    /// Theme manager for light/dark/auto mode switching
    @State private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .toastContainer()  // 🍞 Toast notifications support
                .environment(\.themeManager, themeManager)
                .preferredColorScheme(themeManager.colorScheme)
                .onOpenURL { url in
                    // Handle deep link from Magic Link email
                    Task {
                        do {
                            try await SupabaseService.shared.client.auth.session(from: url)
                            #if DEBUG
                            print("✅ Deep link handled successfully: \(url)")
                            #endif
                        } catch {
                            #if DEBUG
                            print("❌ Error handling deep link: \(error)")
                            #endif
                        }
                    }
                }
        }
    }
}
