import SwiftUI

@main
struct CirklApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark) // Force dark mode for glassmorphic design
        }
    }
}