// LIQUID GLASS EFFECT EXAMPLE for Cursor
// Copy this as reference for the premium effects

import SwiftUI

// 1. LIQUID GLASS BACKGROUND
struct LiquidGlassBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Base gradient
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.3),
                    Color(red: 0.3, green: 0.1, blue: 0.5),
                    Color(red: 0.5, green: 0.2, blue: 0.6),
                    Color(red: 0.2, green: 0.3, blue: 0.7),
                    Color(red: 0.6, green: 0.3, blue: 0.8),
                    Color(red: 0.4, green: 0.2, blue: 0.6),
                    Color(red: 0.3, green: 0.4, blue: 0.8),
                    Color(red: 0.5, green: 0.3, blue: 0.7),
                    Color(red: 0.4, green: 0.5, blue: 0.9)
                ]
            )
            .ignoresSafeArea()
            
            // Animated blobs
            ForEach(0..<3) { i in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purple.opacity(0.3),
                                Color.blue.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(
                        x: animate ? CGFloat.random(in: -100...100) : 0,
                        y: animate ? CGFloat.random(in: -100...100) : 0
                    )
                    .blur(radius: 30)
                    .animation(
                        .easeInOut(duration: Double.random(in: 8...12))
                        .repeatForever(autoreverses: true),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

// 2. PREMIUM GLASS CARD
struct LiquidGlassCard: View {
    var body: some View {
        ZStack {
            // Multiple glass layers for depth
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1),
                                    Color.purple.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    // Inner glow
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.purple.opacity(0.2)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                        .blur(radius: 1)
                )
                .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10)
                .shadow(color: .blue.opacity(0.2), radius: 40, x: 0, y: 20)
        }
    }
}

// 3. ANIMATED CONNECTION LINE
struct ExampleAnimatedConnectionLine: View {
    let from: CGPoint
    let to: CGPoint
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Glow layer
            Path { path in
                path.move(to: from)
                path.addCurve(
                    to: to,
                    control1: CGPoint(x: from.x, y: to.y),
                    control2: CGPoint(x: to.x, y: from.y)
                )
            }
            .stroke(
                LinearGradient(
                    colors: [Color.purple, Color.cyan],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(
                    lineWidth: 4,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .blur(radius: 10)
            .opacity(0.6)
            
            // Main line with animation
            Path { path in
                path.move(to: from)
                path.addCurve(
                    to: to,
                    control1: CGPoint(x: from.x, y: to.y),
                    control2: CGPoint(x: to.x, y: from.y)
                )
            }
            .stroke(
                LinearGradient(
                    colors: [Color.purple, Color.cyan],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(
                    lineWidth: 2,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: [10, 5],
                    dashPhase: phase
                )
            )
            .animation(
                .linear(duration: 2).repeatForever(autoreverses: false),
                value: phase
            )
            .onAppear {
                phase = 20
            }
        }
    }
}

// 4. CENTRAL USER HERO
struct CentralUserHero: View {
    @State private var scale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // Outer glow rings
            ForEach(0..<3) { i in
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.purple, .blue, .cyan, .purple],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 140 + CGFloat(i * 20), height: 140 + CGFloat(i * 20))
                    .opacity(0.3 - Double(i) * 0.1)
                    .rotationEffect(.degrees(rotationAngle + Double(i * 30)))
                    .animation(
                        .linear(duration: 10 + Double(i * 2))
                        .repeatForever(autoreverses: false),
                        value: rotationAngle
                    )
            }
            
            // Profile container
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 120, height: 120)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.purple, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )
                .shadow(color: .purple.opacity(0.5), radius: 20)
                .scaleEffect(scale)
                .animation(
                    .easeInOut(duration: 2).repeatForever(autoreverses: true),
                    value: scale
                )
            
            // User image placeholder
            Image(systemName: "person.fill")
                .font(.system(size: 50))
                .foregroundColor(.white)
            
            // Status indicator
            Circle()
                .fill(Color.green)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )
                .offset(x: 40, y: 40)
        }
        .onAppear {
            scale = 1.05
            rotationAngle = 360
        }
    }
}
