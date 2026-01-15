// APPLE INTELLIGENCE BUBBLE ANIMATIONS - iOS 18

struct AppleIntelligenceBubble: View {
    @State private var gradientRotation = 0.0
    @State private var breathingScale = 1.0
    @State private var shimmerPhase = 0.0
    @State private var layer1Rotation = 0.0
    @State private var layer2Rotation = 0.0
    @State private var layer3Rotation = 0.0
    @State private var glowOpacity = 0.3
    
    var body: some View {
        ZStack {
            // LAYER 3 - Slowest (8s)
            Circle()
                .fill(angularGradient)
                .frame(width: 70, height: 70)
                .blur(radius: 3)
                .opacity(0.6)
                .rotationEffect(.degrees(layer3Rotation))
            
            // LAYER 2 - Medium (6s)
            Circle()
                .fill(angularGradient)
                .frame(width: 65, height: 65)
                .blur(radius: 2)
                .opacity(0.7)
                .rotationEffect(.degrees(layer2Rotation))
            
            // LAYER 1 - Fastest (4s)
            Circle()
                .fill(angularGradient)
                .frame(width: 60, height: 60)
                .blur(radius: 1)
                .opacity(0.8)
                .rotationEffect(.degrees(layer1Rotation))
            
            // CENTER - Adapts to theme
            Circle()
                .fill(Color.primary.opacity(0.9))
                .frame(width: 55, height: 55)
            
            // SHIMMER OVERLAY
            Circle()
                .trim(from: shimmerPhase, to: shimmerPhase + 0.1)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.8), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 58, height: 58)
                .rotationEffect(.degrees(shimmerPhase * 360))
            
            // GLOW EFFECT
            Circle()
                .stroke(Color.purple.opacity(glowOpacity), lineWidth: 3)
                .frame(width: 75, height: 75)
                .blur(radius: 5)
        }
        .scaleEffect(breathingScale)
        .onAppear {
            startAnimations()
        }
    }
    
    var angularGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(stops: [
                .init(color: Color(hex: "007AFF"), location: 0.0),  // Blue
                .init(color: Color(hex: "5AC8FA"), location: 0.2),  // Cyan
                .init(color: Color(hex: "FF9500"), location: 0.4),  // Orange
                .init(color: Color(hex: "FF2D55"), location: 0.6),  // Pink
                .init(color: Color(hex: "AF52DE"), location: 0.8),  // Purple
                .init(color: Color(hex: "007AFF"), location: 1.0)   // Blue
            ]),
            center: .center
        )
    }
    
    func startAnimations() {
        // BREATHING - 2.5s cycle
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            breathingScale = 1.08
        }
        
        // LAYER ROTATIONS - Different speeds
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            layer1Rotation = 360
        }
        withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
            layer2Rotation = 360
        }
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            layer3Rotation = 360
        }
        
        // SHIMMER - Every 3 seconds
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            shimmerPhase = 1.0
        }
        
        // GLOW PULSE - Subtle
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowOpacity = 0.6
        }
    }
}

// ANIMATION TIMINGS REFERENCE:
// - Gradient Rotation: 4s, 6s, 8s (3 layers)
// - Breathing: 2.5s in/out
// - Shimmer: 3s loop
// - Glow: 1.5s pulse
// - All animations: .repeatForever
// - Performance: 60fps target