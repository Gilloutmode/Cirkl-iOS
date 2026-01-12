import SwiftUI

struct OrbitalConnectionsView: View {
    @State private var rotationAngle: Double = 0
    @State private var selectedConnection: String? = nil
    @State private var searchText = ""
    @State private var voiceActive = false
    @StateObject private var performanceManager = PerformanceManager()
    @Namespace private var connectionTransition
    
    // Connections with real names and colors
    let connections = [
        (name: "Gilles", angle: 0.0, color: DesignTokens.Colors.purple),
        (name: "Judith", angle: 60.0, color: DesignTokens.Colors.pink),
        (name: "Denis", angle: 120.0, color: DesignTokens.Colors.warning),
        (name: "Salomé", angle: 180.0, color: DesignTokens.Colors.success),
        (name: "Dan", angle: 240.0, color: DesignTokens.Colors.electricBlue),
        (name: "Shay", angle: 300.0, color: DesignTokens.Colors.electricBlue)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // LIGHT LIQUID GLASS BACKGROUND
                LightLiquidGlassBackground()
                
                VStack(spacing: 0) {
                    // HEADER FIXED AT ABSOLUTE TOP
                    VStack(spacing: 0) {
                        // Safe area spacer
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: geometry.safeAreaInsets.top)
                        
                        // Header content
                        HStack {
                            // Connection counter - BLACK text
                            HStack(spacing: 6) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                Text("1,247")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .glassEffect(.regular, in: .rect(cornerRadius: 20))
                            
                            Spacer()
                            
                            // Cirkl title - BLACK
                            Text("Cirkl")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            
                            Spacer()
                            
                            // Settings - BLACK icon
                            Button(action: {}) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                    .frame(width: 40, height: 40)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(Circle())
                                    .glassEffect(.regular.interactive(), in: .circle)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                    
                    // SEARCH BAR - Utilisera LiquidGlass quand iOS 26 sera disponible
                    AppleIntelligenceSearchBar(text: $searchText)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // CENTERED ORBITAL SYSTEM
                    GeometryReader { geo in
                        let centerX = geo.size.width / 2
                        let centerY = geo.size.height / 2
                        let center = CGPoint(x: centerX, y: centerY)
                        
                        ZStack {
                            // Connection Lines
                            ForEach(connections.indices, id: \.self) { index in
                                let connection = connections[index]
                                let angle = connection.angle + rotationAngle
                                let radians = angle * .pi / 180
                                let radius: CGFloat = 140
                                let endPoint = CGPoint(
                                    x: centerX + radius * CGFloat(cos(radians)),
                                    y: centerY + radius * CGFloat(sin(radians))
                                )
                                
                                PremiumGlassConnectionLine(
                                    from: center,
                                    to: endPoint,
                                    color: connection.color,
                                    isSelected: selectedConnection == connection.name
                                )
                            }
                            
                            // Gil at exact center
                            PremiumCentralSphere()
                                .position(x: centerX, y: centerY)
                            
                            // Connections in perfect orbit
                            ForEach(connections.indices, id: \.self) { index in
                                let connection = connections[index]
                                let angle = connection.angle + rotationAngle
                                let radians = angle * .pi / 180
                                let radius: CGFloat = 140
                                
                                // Utilise les sphères existantes - sera mis à jour pour iOS 26
                                PremiumGlassSphere(
                                    name: connection.name,
                                    color: connection.color,
                                    isSelected: selectedConnection == connection.name
                                )
                                .position(
                                    x: centerX + radius * CGFloat(cos(radians)),
                                    y: centerY + radius * CGFloat(sin(radians))
                                )
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        selectedConnection = connection.name
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // LIQUID BUBBLE VOICE BUTTON
                    LiquidBubbleVoiceButton(isActive: $voiceActive)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

// MARK: - Adaptive Liquid Glass Background
struct LightLiquidGlassBackground: View {
    @State private var animateGradient = false
    @Environment(\.colorScheme) private var colorScheme

    // Couleurs adaptatives selon le mode
    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.08, green: 0.06, blue: 0.15), // Dark purple
                Color(red: 0.06, green: 0.08, blue: 0.18), // Dark blue
                Color(red: 0.12, green: 0.06, blue: 0.12)  // Dark pink
            ]
        } else {
            return [
                Color(red: 0.95, green: 0.94, blue: 1.0), // Light purple
                Color(red: 0.94, green: 0.97, blue: 1.0), // Light blue
                Color(red: 1.0, green: 0.95, blue: 0.98)  // Light pink
            ]
        }
    }

    private var blobOpacity: Double {
        colorScheme == .dark ? 0.15 : 0.1
    }

    var body: some View {
        ZStack {
            // Adaptive base gradient
            LinearGradient(
                colors: gradientColors,
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )

            // Floating blobs - adaptatives
            ForEach(0..<5) { i in
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purple.opacity(blobOpacity),
                                Color.blue.opacity(blobOpacity * 0.5),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(
                        x: CGFloat.random(in: -150...150),
                        y: CGFloat.random(in: -200...200)
                    )
                    .blur(radius: 30)
                    .animation(
                        .easeInOut(duration: Double.random(in: 10...20))
                        .repeatForever(autoreverses: true),
                        value: animateGradient
                    )
            }
        }
        .ignoresSafeArea()
        .onAppear { animateGradient.toggle() }
    }
}

// MARK: - Apple Intelligence Search Bar
struct AppleIntelligenceSearchBar: View {
    @Binding var text: String
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 12) {
            // Animated bubble icon like Apple Intelligence
            ZStack {
                // Gradient ring
                SwiftUI.Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color.orange,
                                Color.pink,
                                Color.purple,
                                Color.blue,
                                Color.cyan,
                                Color.orange
                            ]),
                            center: .center,
                            startAngle: .degrees(rotationAngle),
                            endAngle: .degrees(rotationAngle + 360)
                        )
                    )
                    .frame(width: 28, height: 28)
                    .blur(radius: 8)
                
                // Black center
                SwiftUI.Circle()
                    .fill(Color.black)
                    .frame(width: 24, height: 24)
                
                // Glossy overlay
                SwiftUI.Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.8), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 26, height: 26)
            }
            .scaleEffect(pulseScale)
            
            TextField("Ask anything you want to find...", text: $text)
                .font(.system(size: 15))
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Button(action: {}) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 16))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

// MARK: - Premium Glass Sphere
struct PremiumGlassSphere: View {
    let name: String
    let color: Color
    let isSelected: Bool
    @State private var animateLiquid = false
    @State private var rotateY: Double = 0
    @State private var breathe: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Animated flowing background gradient
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: color.opacity(0.4), location: 0.0),
                                .init(color: color.opacity(0.2), location: 0.6),
                                .init(color: Color.white.opacity(0.8), location: 1.0)
                            ]),
                            center: animateLiquid ? .topLeading : .bottomTrailing,
                            startRadius: 10,
                            endRadius: 45
                        )
                    )
                    .frame(width: 70, height: 70)
                
                // Glass material layer - iOS 26 Liquid Glass
                SwiftUI.Circle()
                    .frame(width: 70, height: 70)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
                    .glassEffect(.regular, in: .circle)
                
                // Perfect glass reflection highlight
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: .white.opacity(0.75), location: 0.0),
                                .init(color: .white.opacity(0.10), location: 0.15),
                                .init(color: .clear, location: 0.35),
                            ]),
                            center: .init(x: 0.35, y: 0.30),
                            startRadius: 2,
                            endRadius: 25
                        )
                    )
                    .frame(width: 70, height: 70)
                    .blendMode(.screen)
                
                // User icon
                Image(systemName: "person.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(color)
                
                // Rim highlight
                SwiftUI.Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), color.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 70, height: 70)
            }
            .shadow(color: color.opacity(0.3), radius: 15, x: 0, y: 8)
            .scaleEffect(isSelected ? 1.2 : breathe)
            .rotation3DEffect(
                .degrees(rotateY),
                axis: (x: 0, y: 1, z: 0),
                anchor: .center,
                anchorZ: 0,
                perspective: 0.6
            )
            
            // Name label
            Text(name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .glassEffect(.regular, in: .rect(cornerRadius: 12))
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateLiquid = true
                breathe = 1.02
            }
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                rotateY = 15
            }
        }
    }
}

// MARK: - Premium Central Sphere (Gil)
struct PremiumCentralSphere: View {
    @State private var animateLiquid = false
    @State private var rotateY: Double = 0
    @State private var pulse: CGFloat = 1.0
    @State private var orbitalRings: Double = 0
    
    var body: some View {
        ZStack {
            // Orbital decoration rings
            ForEach(0..<3) { i in
                SwiftUI.Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3 - Double(i) * 0.1),
                                Color.purple.opacity(0.1 - Double(i) * 0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.8
                    )
                    .frame(width: 140 + CGFloat(i * 25), height: 140 + CGFloat(i * 25))
                    .rotationEffect(.degrees(orbitalRings + Double(i * 60)))
                    .opacity(0.6 - Double(i) * 0.15)
            }
            
            // Main premium glass sphere
            ZStack {
                // Liquid glass base
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.white.opacity(0.9), location: 0.0),
                                .init(color: Color.purple.opacity(0.3), location: 0.4),
                                .init(color: Color.cyan.opacity(0.2), location: 0.7),
                                .init(color: Color.white.opacity(0.95), location: 1.0)
                            ]),
                            center: animateLiquid ? .init(x: 0.3, y: 0.2) : .init(x: 0.7, y: 0.8),
                            startRadius: 15,
                            endRadius: 65
                        )
                    )
                    .frame(width: 110, height: 110)
                
                // Glass material layer - iOS 26 Liquid Glass
                SwiftUI.Circle()
                    .frame(width: 110, height: 110)
                    .background(Color.purple.opacity(0.1))
                    .clipShape(Circle())
                    .glassEffect(.regular, in: .circle)
                
                // Perfect spherical highlight
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: .white.opacity(0.85), location: 0.0),
                                .init(color: .white.opacity(0.3), location: 0.2),
                                .init(color: .clear, location: 0.45),
                            ]),
                            center: .init(x: 0.35, y: 0.25),
                            startRadius: 3,
                            endRadius: 40
                        )
                    )
                    .frame(width: 110, height: 110)
                    .blendMode(.screen)
                
                // Gil text
                Text("Gil")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Animated border
                SwiftUI.Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                .purple, .cyan, .pink, .purple
                            ]),
                            center: .center,
                            startAngle: .degrees(orbitalRings),
                            endAngle: .degrees(orbitalRings + 360)
                        ),
                        lineWidth: 2.5
                    )
                    .frame(width: 110, height: 110)
            }
            .shadow(color: .purple.opacity(0.4), radius: 25, x: 0, y: 12)
            .scaleEffect(pulse)
            .rotation3DEffect(
                .degrees(rotateY),
                axis: (x: 0, y: 1, z: 0),
                anchor: .center,
                anchorZ: 0,
                perspective: 0.5
            )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                pulse = 1.08
                animateLiquid = true
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                orbitalRings = 360
            }
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                rotateY = 25
            }
        }
    }
}

// MARK: - Premium Glass Connection Line
struct PremiumGlassConnectionLine: View {
    let from: CGPoint
    let to: CGPoint
    let color: Color
    let isSelected: Bool
    @State private var phase: CGFloat = 0
    @State private var glowIntensity: Double = 0.3
    
    var body: some View {
        ZStack {
            // Outer glow layer
            Path { path in
                path.move(to: from)
                path.addQuadCurve(
                    to: to,
                    control: CGPoint(
                        x: (from.x + to.x) / 2,
                        y: (from.y + to.y) / 2 - 30
                    )
                )
            }
            .stroke(
                color.opacity(glowIntensity),
                style: StrokeStyle(lineWidth: 6, lineCap: .round)
            )
            .blur(radius: 8)
            
            // Main glass line
            Path { path in
                path.move(to: from)
                path.addQuadCurve(
                    to: to,
                    control: CGPoint(
                        x: (from.x + to.x) / 2,
                        y: (from.y + to.y) / 2 - 30
                    )
                )
            }
            .stroke(
                LinearGradient(
                    colors: [
                        color.opacity(0.8),
                        Color.white.opacity(0.6),
                        color.opacity(0.8)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(
                    lineWidth: isSelected ? 3.0 : 2.0,
                    lineCap: .round,
                    dash: [12, 6],
                    dashPhase: phase
                )
            )
        }
        .opacity(isSelected ? 1.0 : 0.7)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                phase = 18
            }
        }
    }
}

// MARK: - Liquid Bubble Voice Button
struct LiquidBubbleVoiceButton: View {
    @Binding var isActive: Bool
    @State private var animationPhase: CGFloat = 0
    @State private var breathingScale: CGFloat = 1.0
    @State private var shimmerRotation: Double = 0
    
    var body: some View {
        Button(action: { 
            withAnimation(.spring()) {
                isActive.toggle()
            }
        }) {
            ZStack {
                // Multiple gradient layers
                ForEach(0..<3) { index in
                    SwiftUI.Circle()
                        .fill(
                            AngularGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.blue, location: 0.0),
                                    .init(color: Color.cyan, location: 0.2),
                                    .init(color: Color.orange, location: 0.4),
                                    .init(color: Color.pink, location: 0.6),
                                    .init(color: Color.purple, location: 0.8),
                                    .init(color: Color.blue, location: 1.0)
                                ]),
                                center: .center,
                                startAngle: .degrees(animationPhase + Double(index * 120)),
                                endAngle: .degrees(animationPhase + 360 + Double(index * 120))
                            )
                        )
                        .frame(width: 70 - CGFloat(index * 5), height: 70 - CGFloat(index * 5))
                        .blur(radius: CGFloat(index))
                        .opacity(0.8 - Double(index) * 0.2)
                        .scaleEffect(breathingScale + CGFloat(index) * 0.02)
                }
                
                // Black center
                SwiftUI.Circle()
                    .fill(Color.black)
                    .frame(width: 60, height: 60)
                
                // Glossy highlights
                SwiftUI.Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.7), Color.cyan.opacity(0.5), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 58, height: 58)
                    .rotationEffect(.degrees(shimmerRotation))
                    .blur(radius: 1)
                
                // Top reflection
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), Color.cyan.opacity(0.3), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 25, height: 15)
                    .offset(y: -18)
                    .blur(radius: 1)
                
                // Microphone icon
                Image(systemName: isActive ? "waveform" : "mic.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .symbolEffect(.bounce, value: isActive)
            }
            .frame(width: 80, height: 80)
            .shadow(color: .purple.opacity(0.4), radius: 20, x: 0, y: 10)
        }
        .scaleEffect(isActive ? 1.15 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                animationPhase = 360
            }
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                shimmerRotation = 360
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                breathingScale = 1.08
            }
        }
    }
}

#Preview {
    OrbitalConnectionsView()
}
