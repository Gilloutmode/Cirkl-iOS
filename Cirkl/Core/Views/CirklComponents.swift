import SwiftUI

// MARK: - COMPOSANTS DU SYSTÈME DE DESIGN CIRKL
// Extraits de ContentView.swift pour une meilleure modularité

/// Composant d'arrière-plan Liquid Glass moderne
struct CirklGlassBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .glassEffect(GlassEffectStyle.regular.interactive(), in: .rect(cornerRadius: 20))
    }
}

/// Ligne de connexion entre le centre et les bulles orbitales
struct CirklConnectionLine: View {
    let center: CGPoint
    let angle: Double
    let radius: CGFloat
    let color: Color
    
    var body: some View {
        let angleRad = angle * .pi / 180
        let endPoint = CGPoint(
            x: center.x + cos(angleRad) * radius,
            y: center.y + sin(angleRad) * radius
        )
        
        Path { path in
            path.move(to: center)
            path.addLine(to: endPoint)
        }
        .stroke(
            LinearGradient(
                colors: [
                    color.opacity(0.1),
                    color.opacity(0.05),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 1, lineCap: .round)
        )
    }
}

/// Vue d'en-tête avec compteur de connexions et réglages
struct CirklHeaderView: View {
    @Binding var searchText: String
    @Binding var showSettings: Bool
    let connectionCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Compteur de connexions avec effet Liquid Glass
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Text("\(connectionCount)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .glassEffect(GlassEffectStyle.regular.interactive(), in: .capsule)
                
                Spacer()
                
                Text("Cirkl")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary.opacity(0.9), .primary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Spacer()
                
                Button(action: { showSettings.toggle() }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .glassEffect(GlassEffectStyle.regular.interactive(), in: .circle)
                }
            }
            .padding(.horizontal, 20)
            
            // Barre de recherche alimentée par l'IA
            CirklSearchBar(searchText: $searchText)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 8) // Padding vertical minimal
    }
}

/// AI-powered search bar with voice input
struct CirklSearchBar: View {
    @Binding var searchText: String
    @State private var rainbowPhase: Double = 0
    
    var body: some View {
        HStack(spacing: 16) {
            // AI Assistant indicator with animated rainbow edge like in your images
            ZStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        AngularGradient(
                            colors: [
                                .cyan, .blue, .purple, .pink, .orange, .yellow, .cyan
                            ],
                            center: .center,
                            startAngle: .degrees(rainbowPhase),
                            endAngle: .degrees(rainbowPhase + 360)
                        )
                    )
            }
            .frame(width: 44, height: 44)
            .glassEffect(GlassEffectStyle.regular.interactive(), in: .circle)
            .onAppear {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    rainbowPhase = 360
                }
            }
            
            TextField("Ask anything you want to find...", text: $searchText)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
                .textFieldStyle(.plain)
            
            Button(action: {}) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .glassEffect(GlassEffectStyle.regular.interactive(), in: .circle)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .glassEffect(GlassEffectStyle.regular.interactive(), in: .rect(cornerRadius: 24))
    }
}

/// Settings view with logout and reset options
struct CirklSettingsView: View {
    @EnvironmentObject var appState: AppStateManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            GlassEffectContainer(spacing: 20.0) {
                VStack(spacing: 24) {
                    Text("Réglages")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                    
                    VStack(spacing: 16) {
                        Button("Déconnexion") {
                            appState.logout()
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.red)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .glassEffect(GlassEffectStyle.regular.tint(Color.red).interactive(), in: .rect(cornerRadius: 12))
                        
                        Button("Réinitialiser l'onboarding") {
                            appState.resetOnboarding()
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.orange)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .glassEffect(GlassEffectStyle.regular.tint(Color.orange).interactive(), in: .rect(cornerRadius: 12))
                    }
                    
                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Fermer") {
                            dismiss()
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}