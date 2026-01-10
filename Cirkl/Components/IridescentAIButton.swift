import SwiftUI
import Foundation

// MARK: - Iridescent AI Button with Fluid Animation
struct IridescentAIButton: View {
    @State private var gradientRotation: Double = 0
    @State private var breathingScale: CGFloat = 1.0
    @State private var morphPhase: Double = 0
    @State private var isPressed: Bool = false
    @State private var shimmerPhase: Double = 0
    @State private var liquidDistortion: CGFloat = 0
    
    // Dynamic gradient colors for iridescent effect
    private var iridescentColors: [Color] {
        [
            Color(red: 1.0, green: 0.3, blue: 0.5),  // Hot pink
            Color(red: 1.0, green: 0.5, blue: 0.2),  // Orange
            Color(red: 1.0, green: 0.9, blue: 0.3),  // Yellow
            Color(red: 0.3, green: 1.0, blue: 0.7),  // Cyan
            Color(red: 0.3, green: 0.5, blue: 1.0),  // Blue
            Color(red: 0.7, green: 0.3, blue: 1.0),  // Purple
            Color(red: 1.0, green: 0.3, blue: 0.5),  // Back to pink
        ]
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed.toggle()
            }
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }) {
            ZStack {
                // Outer glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                iridescentColors[Int(morphPhase) % iridescentColors.count].opacity(0.6),
                                iridescentColors[(Int(morphPhase) + 3) % iridescentColors.count].opacity(0.3),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                    .scaleEffect(breathingScale * 1.1)
                
                // Main button with liquid glass effect
                ZStack {
                    // Dark center (like the reference)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.black,
                                    Color.black.opacity(0.8),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 35
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    // Iridescent ring with animation
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: iridescentColors),
                                center: .center,
                                angle: .degrees(gradientRotation)
                            ),
                            lineWidth: 8 + CGFloat(sin(morphPhase * .pi / 180) * 3)
                        )
                        .frame(width: 64, height: 64)
                        .blur(radius: 0.5)
                    
                    // Liquid glass distortion overlay
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        iridescentColors[index].opacity(0.3),
                                        iridescentColors[(index + 2) % iridescentColors.count].opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(
                                width: 56 + CGFloat(index) * 4,
                                height: 56 + CGFloat(index) * 4
                            )
                            .offset(
                                x: CGFloat(sin(morphPhase * .pi / 180 + Double(index) * 120)) * liquidDistortion,
                                y: CGFloat(cos(morphPhase * .pi / 180 + Double(index) * 120)) * liquidDistortion
                            )
                            .blendMode(.screen)
                    }
                    
                    // Shimmer effect
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.white.opacity(0), location: 0),
                                    .init(color: Color.white.opacity(0.4), location: shimmerPhase),
                                    .init(color: Color.white.opacity(0), location: min(1, shimmerPhase + 0.1))
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .mask(
                            Circle()
                                .stroke(lineWidth: 3)
                                .frame(width: 64, height: 64)
                        )
                    
                    // Microphone icon in center
                    Image(systemName: "mic.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(isPressed ? 1.1 : 1.0)
                }
                .scaleEffect(breathingScale)
                .rotation3DEffect(
                    .degrees(isPressed ? 10 : 0),
                    axis: (x: 1, y: 0, z: 0)
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Gradient rotation animation
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            gradientRotation = 360
        }
        
        // Breathing animation
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            breathingScale = 1.08
        }
        
        // Morphing phase animation
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            morphPhase = 360
        }
        
        // Shimmer animation
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            shimmerPhase = 1
        }
        
        // Liquid distortion animation
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            liquidDistortion = 3
        }
    }
}

// MARK: - Morphing Shape for Organic Feel
struct LiquidMorphShape: Shape {
    var morphPhase: Double
    
    var animatableData: Double {
        get { morphPhase }
        set { morphPhase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        // Create organic shape with varying radius
        for angle in stride(from: 0, to: 360, by: 10) {
            let radians = Double(angle) * .pi / 180
            let variation = CGFloat(sin(radians * 3 + morphPhase * .pi / 180) * 5)
            let currentRadius = radius + variation
            
            let x = center.x + CGFloat(cos(radians)) * currentRadius
            let y = center.y + CGFloat(sin(radians)) * currentRadius
            
            if angle == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Preview
struct IridescentAIButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            IridescentAIButton()
        }
    }
}