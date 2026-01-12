import SwiftUI
import Foundation

// MARK: - Animated Connection Model
struct AnimatedConnection: Identifiable {
    let id: Int
    let name: String
    let targetAngle: Double // Final hexagon angle
    let color: Color
    let imageName: String
    
    // Animation states
    @State var position: CGPoint = .zero
    @State var scale: CGFloat = 0
    @State var opacity: Double = 0
    @State var distance: CGFloat = 0
}

// MARK: - Bubble to Hexagon Animation View
struct BubbleToHexagonAnimation: View {
    // Animation phase control
    @State private var animationPhase: Int = 0
    @State private var showConnectionLines: Bool = false
    @State private var connectionLineOpacity: Double = 0
    
    // Connections with their target positions
    @State private var connections: [AnimatedConnection] = [
        AnimatedConnection(id: 1, name: "Denis", targetAngle: 330, color: Color(red: 1.0, green: 0.85, blue: 0.24), imageName: "person.crop.circle.fill"),
        AnimatedConnection(id: 2, name: "Shay", targetAngle: 30, color: Color(red: 0.42, green: 0.8, blue: 0.47), imageName: "person.crop.circle.fill"),
        AnimatedConnection(id: 3, name: "Dan", targetAngle: 90, color: Color(red: 0.3, green: 0.59, blue: 1.0), imageName: "person.crop.circle.fill"),
        AnimatedConnection(id: 4, name: "Judith", targetAngle: 150, color: Color(red: 1.0, green: 0.42, blue: 0.42), imageName: "person.crop.circle.fill"),
        AnimatedConnection(id: 5, name: "Gilles", targetAngle: 210, color: Color(red: 0.66, green: 0.9, blue: 0.81), imageName: "person.crop.circle.fill"),
        AnimatedConnection(id: 6, name: "Salomé", targetAngle: 270, color: Color(red: 1.0, green: 0.71, blue: 0.76), imageName: "person.crop.circle.fill")
    ]
    
    // Animation states for each connection
    @State private var connectionStates: [Int: ConnectionAnimationState] = [:]
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ZStack {
                // Background
                Color(red: 0.95, green: 0.95, blue: 0.97)
                    .ignoresSafeArea()
                
                // Connection lines (Phase 5)
                if showConnectionLines {
                    ForEach(connections) { connection in
                        AnimatedConnectionLine(
                            from: center,
                            angle: connection.targetAngle,
                            distance: 140,
                            opacity: connectionLineOpacity,
                            delay: Double(connection.id - 1) * 0.05
                        )
                    }
                }
                
                // Center profile (Gil) - always visible
                CenterProfile()
                    .position(center)
                
                // Animated connection bubbles
                ForEach(connections) { connection in
                    AnimatedBubble(
                        connection: connection,
                        phase: animationPhase,
                        center: center,
                        state: connectionStates[connection.id] ?? ConnectionAnimationState()
                    )
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Initialize all connection states
        for connection in connections {
            connectionStates[connection.id] = ConnectionAnimationState()
        }
        
        // Phase 1: Initial state (0ms) - all invisible at center
        // Already set by default
        
        // Phase 2: Bubble appearance (0-500ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.5)) {
                animationPhase = 2
            }
        }
        
        // Phase 3: Expansion start (500-1500ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 1.0)) {
                animationPhase = 3
            }
        }
        
        // Phase 4: Final positioning (1500-2500ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeInOut(duration: 1.0)) {
                animationPhase = 4
            }
        }
        
        // Phase 5: Connection lines (2500-3000ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            showConnectionLines = true
            withAnimation(.easeIn(duration: 0.5)) {
                connectionLineOpacity = 0.6
            }
        }
    }
}

// MARK: - Connection Animation State
struct ConnectionAnimationState {
    var scale: CGFloat = 0
    var opacity: Double = 0
    var distance: CGFloat = 0
    var offsetX: CGFloat = 0
    var offsetY: CGFloat = 0
}

// MARK: - Animated Bubble Component
struct AnimatedBubble: View {
    let connection: AnimatedConnection
    let phase: Int
    let center: CGPoint
    @State var state: ConnectionAnimationState
    
    private var position: CGPoint {
        let angle = CGFloat(connection.targetAngle * .pi / 180)
        
        switch phase {
        case 2: // Bubble appearance with slight offset
            let randomOffsetX = CGFloat.random(in: -10...10)
            let randomOffsetY = CGFloat.random(in: -10...10)
            return CGPoint(
                x: center.x + randomOffsetX,
                y: center.y + randomOffsetY
            )
        case 3: // Arc movement to 100px
            let distance: CGFloat = 100
            return CGPoint(
                x: center.x + cos(angle) * distance,
                y: center.y + sin(angle) * distance
            )
        case 4: // Final hexagon position at 140px
            let distance: CGFloat = 140
            return CGPoint(
                x: center.x + cos(angle) * distance,
                y: center.y + sin(angle) * distance
            )
        default: // Phase 1: Center
            return center
        }
    }
    
    private var scale: CGFloat {
        switch phase {
        case 2: return 0.3
        case 3: return 0.7
        case 4: return 1.0
        default: return 0
        }
    }
    
    private var opacity: Double {
        switch phase {
        case 2: return 0.6
        case 3: return 0.8
        case 4: return 1.0
        default: return 0
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Glassmorphic background (Phase 4+)
                if phase >= 4 {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.5),
                                            Color.white.opacity(0.2)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .frame(width: 65, height: 65)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                } else {
                    // Simple white bubble for phases 2-3
                    Circle()
                        .fill(Color.white)
                        .frame(width: 65, height: 65)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
                }
                
                // Profile image placeholder with color transition
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                phase >= 3 ? connection.color : Color.white,
                                phase >= 3 ? connection.color.opacity(0.7) : Color.white.opacity(0.9)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 55, height: 55)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 28))
                    .foregroundColor(phase >= 3 ? Color.white : Color(red: 0.7, green: 0.65, blue: 0.6))
            }
            
            Text(connection.name)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .opacity(phase >= 2 ? 1 : 0)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .position(position)
        .animation(
            Animation.easeInOut(duration: phase == 2 ? 0.5 : 1.0)
                .delay(phase == 2 ? Double(connection.id - 1) * 0.05 : 0),
            value: phase
        )
    }
}

// MARK: - Center Profile (Gil)
struct CenterProfile: View {
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                
                Circle()
                    .stroke(Color(red: 0.0, green: 0.48, blue: 1.0), lineWidth: 3)
                    .frame(width: 80, height: 80)
                
                // Glow effect
                Circle()
                    .stroke(Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.3), lineWidth: 20)
                    .blur(radius: 10)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 70, height: 70)
                    .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8))
            }
            
            Text("Gil")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DesignTokens.Colors.textPrimary)
        }
    }
}

// MARK: - Connection Line
struct AnimatedConnectionLine: View {
    let from: CGPoint
    let angle: Double
    let distance: CGFloat
    let opacity: Double
    let delay: Double
    
    @State private var animatedOpacity: Double = 0
    
    var body: some View {
        Path { path in
            let radians = CGFloat(angle * .pi / 180)
            let to = CGPoint(
                x: from.x + cos(radians) * distance,
                y: from.y + sin(radians) * distance
            )
            
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(
            Color(red: 0.9, green: 0.9, blue: 0.9),
            lineWidth: 2
        )
        .opacity(animatedOpacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3).delay(delay)) {
                animatedOpacity = opacity
            }
        }
    }
}

// MARK: - Preview
struct BubbleToHexagonAnimation_Previews: PreviewProvider {
    static var previews: some View {
        BubbleToHexagonAnimation()
            .previewDevice("iPhone 15 Pro")
    }
}