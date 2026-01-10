import SwiftUI

/// Onboarding view with glassmorphic design
struct OnboardingView: View {
    @ObservedObject var appState: AppStateManager
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            // Background
            CirklGlassBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Logo
                Text("Cirkl")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                // Page content
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        title: "Connexions Authentiques",
                        description: "Rencontrez de vraies personnes, vérifiées physiquement par QR, NFC ou Bluetooth.",
                        icon: "person.2.fill",
                        color: .cyan
                    )
                    .tag(0)
                    
                    OnboardingPage(
                        title: "Interface Orbitale",
                        description: "Vos connexions gravitent autour de vous dans une interface révolutionnaire.",
                        icon: "circle.hexagongrid.fill",
                        color: .purple
                    )
                    .tag(1)
                    
                    OnboardingPage(
                        title: "Assistant IA",
                        description: "Votre compagnon intelligent qui détecte les opportunités et enrichit vos relations.",
                        icon: "sparkles",
                        color: .orange
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 300)
                
                // Get Started button
                if currentPage == 2 {
                    Button {
                        appState.completeOnboarding()
                    } label: {
                        Text("Commencer")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.cyan, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                    }
                    .padding(.horizontal, 40)
                }
            }
        }
    }
}

struct OnboardingPage: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 40)
        }
    }
}