import SwiftUI

// MARK: - MAIN CONTENT VIEW POUR CIRKL
struct ContentView: View {
    @StateObject private var appState = AppStateManager()
    @StateObject private var connectionState = ConnectionStateManager()
    @StateObject private var performanceManager = PerformanceManager()
    @StateObject private var errorHandler = ErrorHandler()
    
    var body: some View {
        Group {
            if appState.showOnboarding {
                OnboardingView(appState: appState)
                    .withErrorHandling(errorHandler)
            } else if appState.isAuthenticated {
                // Interface principale avec nouveau design Living Glass
                OrbitalView()
                    .environmentObject(appState)
                    .environmentObject(connectionState)
                    .environmentObject(performanceManager)
                    .withErrorHandling(errorHandler)
            } else {
                AuthenticationView(appState: appState)
                    .withErrorHandling(errorHandler)
            }
        }
        .onAppear {
            // Pour le développement : skip onboarding et authenticate directement
            #if DEBUG
            appState.completeOnboarding()
            appState.authenticate()
            #endif
        }
        .task {
            // Initialiser les optimisations de performance
            await performanceManager.initializeOptimizations()
        }
    }
}

// MARK: - INTERFACE PRINCIPALE CIRKL AVEC LIQUID GLASS
struct CirklMainInterface: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var connectionState: ConnectionStateManager
    @EnvironmentObject var performanceManager: PerformanceManager
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            // Arrière-plan avec gradient subtil Liquid Glass
            LinearGradient(
                colors: [
                    Color(white: 0.98),
                    Color(white: 0.95),
                    Color(white: 0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Contenu principal
            VStack(spacing: 0) {
                // Zone principale centrée avec les bulles orbitales
                GeometryReader { geometry in
                    OrbitalBubbleSystem()
                        .environmentObject(connectionState)
                        .environmentObject(performanceManager)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                
                // Bouton AI en bas
                CirklAIButton()
                    .padding(.bottom, 30)
                    .frame(height: 100)
            }
        }
        .safeAreaInset(edge: .top) {
            // Header positionné en utilisant safeAreaInset
            CirklHeaderView(
                searchText: $connectionState.searchText,
                showSettings: $showSettings,
                connectionCount: connectionState.connections.count
            )
            .padding(.horizontal)
            .background(
                LinearGradient(
                    colors: [
                        Color(white: 0.98).opacity(0.95),
                        Color(white: 0.96).opacity(0.9)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .sheet(isPresented: $showSettings) {
            CirklSettingsView()
                .environmentObject(appState)
        }
    }
}

// MARK: - SYSTÈME ORBITAL DES BULLES
struct OrbitalBubbleSystem: View {
    @EnvironmentObject var connectionState: ConnectionStateManager
    @EnvironmentObject var performanceManager: PerformanceManager
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
            
            // Rayon optimal pour un cercle parfait (35% de la plus petite dimension)
            let orbitalRadius = min(geometry.size.width, geometry.size.height) * 0.32
            
            ZStack {
                // Guide visuel optionnel du cercle orbital (très subtil)
                if performanceManager.shouldShowLiquidEffects {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.gray.opacity(0.03),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                        .frame(width: orbitalRadius * 2, height: orbitalRadius * 2)
                        .position(center)
                }
                
                // Connexions lignes subtiles (optionnelles)
                if performanceManager.shouldShowLiquidEffects {
                    ForEach(Array(connectionState.filteredConnections.enumerated()), id: \.element.id) { index, connection in
                        let angle = calculateAngle(for: index, total: connectionState.filteredConnections.count)
                        let endPosition = calculatePosition(center: center, radius: orbitalRadius, angle: angle)
                        
                        Path { path in
                            path.move(to: center)
                            path.addLine(to: endPosition)
                        }
                        .stroke(
                            LinearGradient(
                                colors: [
                                    connection.color.opacity(0.1),
                                    connection.color.opacity(0.02)
                                ],
                                startPoint: .center,
                                endPoint: .trailing
                            ),
                            lineWidth: 0.5
                        )
                    }
                }
                
                // Bulles des connexions disposées en cercle parfait
                ForEach(Array(connectionState.filteredConnections.enumerated()), id: \.element.id) { index, connection in
                    let angle = calculateAngle(for: index, total: connectionState.filteredConnections.count)
                    let position = calculatePosition(
                        center: center,
                        radius: orbitalRadius,
                        angle: angle
                    )
                    
                    CirklProfileBubble(
                        connection: connection,
                        isSelected: connectionState.selectedConnection?.id == connection.id
                    )
                    .position(position)
                    .zIndex(connectionState.selectedConnection?.id == connection.id ? 10 : 1)
                    .onTapGesture {
                        handleBubbleTap(connection)
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: connectionState.selectedConnection?.id)
                }
                
                // Bulle centrale (Gil) avec Liquid Glass et effet arc-en-ciel
                CirklCentralBubble()
                    .position(center)
                    .zIndex(20)
                    .scaleEffect(1.0)
            }
        }
        .onAppear {
            startOrbitalAnimation()
        }
    }
    
    // Calcul de l'angle pour chaque bulle (répartition uniforme)
    private func calculateAngle(for index: Int, total: Int) -> Double {
        // Répartition uniforme sur 360°
        let baseAngle = (Double(index) * 360.0 / Double(total))
        // Commencer par le haut (12 heures)
        return baseAngle - 90 + rotationAngle
    }
    
    // Calcul de la position exacte de la bulle
    private func calculatePosition(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        let angleRad = angle * .pi / 180
        return CGPoint(
            x: center.x + Foundation.cos(angleRad) * radius,
            y: center.y + Foundation.sin(angleRad) * radius
        )
    }
    
    // Gestion du tap sur une bulle
    private func handleBubbleTap(_ connection: Connection) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if connectionState.selectedConnection?.id == connection.id {
                connectionState.deselectConnection()
            } else {
                connectionState.selectConnection(connection)
            }
        }
    }
    
    // Animation de rotation très lente et subtile
    private func startOrbitalAnimation() {
        withAnimation(.linear(duration: 90).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}

#Preview {
    ContentView()
}