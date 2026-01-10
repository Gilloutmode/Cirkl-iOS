import SwiftUI
import Foundation

// MARK: - App State Manager
@MainActor
class AppStateManager: ObservableObject {
    @Published var showOnboarding: Bool = true
    @Published var isAuthenticated: Bool = false
    
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { 
            UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding")
            // Manually trigger objectWillChange when the computed property changes
            objectWillChange.send()
        }
    }
    
    init() {
        showOnboarding = !hasCompletedOnboarding
        
        #if DEBUG
        // Pour le développement, skip l'onboarding
        if CommandLine.arguments.contains("--skip-onboarding") {
            hasCompletedOnboarding = true
            showOnboarding = false
            isAuthenticated = true
        }
        #endif
    }
    
    func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.5)) {
            hasCompletedOnboarding = true
            showOnboarding = false
        }
    }
    
    func authenticate() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isAuthenticated = true
        }
    }
    
    func logout() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isAuthenticated = false
        }
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        showOnboarding = true
        isAuthenticated = false
    }
}

// MARK: - Animation Quality
enum AnimationQuality {
    case reduced, medium, high
    
    var animationDuration: Double {
        switch self {
        case .reduced: return 0.1
        case .medium: return 0.3
        case .high: return 0.5
        }
    }
    
    var shouldShowParticles: Bool {
        self == .high
    }
    
    var shouldShowLiquidEffects: Bool {
        self != .reduced
    }
}