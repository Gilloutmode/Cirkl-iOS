import SwiftUI

// MARK: - 3D LIQUID GLASS BUBBLE COMPONENTS
// Advanced 3D translucent bubbles with realistic glass effects

/// Advanced 3D Glass Bubble with realistic translucent effects
struct Advanced3DGlassBubble<Content: View>: View {
    let content: Content
    let size: CGFloat
    let tintColor: Color?
    let isSelected: Bool
    let hasRainbowBorder: Bool
    
    @State private var shimmerPhase: Double = 0
    @State private var breathingPhase: Double = 0
    
    init(
        size: CGFloat = 90,
        tintColor: Color? = nil,
        isSelected: Bool = false,
        hasRainbowBorder: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.size = size
        self.tintColor = tintColor
        self.isSelected = isSelected
        self.hasRainbowBorder = hasRainbowBorder
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Outer glow effect for selection
            if isSelected {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (tintColor ?? .blue).opacity(0.3),
                                (tintColor ?? .blue).opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: size * 0.3,
                            endRadius: size * 0.8
                        )
                    )
                    .frame(width: size * 1.4, height: size * 1.4)
                    .blur(radius: 15)
                    .scaleEffect(1.0 + breathingPhase * 0.1)
            }
            
            // Main 3D glass bubble
            ZStack {
                // Base glass layer with depth
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05)
                            ],
                            center: UnitPoint(x: 0.3, y: 0.3),
                            startRadius: size * 0.1,
                            endRadius: size * 0.5
                        )
                    )
                    .overlay(
                        // Tint overlay
                        Circle()
                            .fill((tintColor ?? Color.clear).opacity(0.1))
                    )
                    .overlay(
                        // Glass surface with multiple material layers
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .opacity(0.7)
                            
                            Circle()
                                .fill(.thinMaterial)
                                .opacity(0.3)
                        }
                    )
                    .frame(width: size, height: size)
                
                // Rainbow border for special bubbles
                if hasRainbowBorder {
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    .cyan, .blue, .purple, .pink, 
                                    .orange, .yellow, .cyan
                                ],
                                center: .center,
                                startAngle: .degrees(shimmerPhase),
                                endAngle: .degrees(shimmerPhase + 360)
                            ),
                            lineWidth: 3
                        )
                        .frame(width: size + 2, height: size + 2)
                        .opacity(0.8)
                }
                
                // Glass edge highlights for 3D effect
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.3),
                                Color.clear,
                                Color.black.opacity(0.1),
                                Color.black.opacity(0.2)
                            ],
                            startPoint: UnitPoint(x: 0.2, y: 0.2),
                            endPoint: UnitPoint(x: 0.8, y: 0.8)
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: size, height: size)
                
                // Inner glass highlights
                ZStack {
                    // Top-left highlight
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 20
                            )
                        )
                        .frame(width: size * 0.25, height: size * 0.4)
                        .offset(x: -size * 0.2, y: -size * 0.2)
                    
                    // Small sparkle highlight
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: size * 0.08, height: size * 0.08)
                        .offset(x: size * 0.25, y: -size * 0.25)
                        .blur(radius: 0.5)
                    
                    // Bottom reflection
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.6, height: size * 0.15)
                        .offset(y: size * 0.3)
                }
                
                // Content
                content
                    .frame(width: size * 0.85, height: size * 0.85)
                    .clipShape(Circle())
            }
            .scaleEffect(isSelected ? 1.1 : (1.0 + breathingPhase * 0.02))
            .rotation3DEffect(
                .degrees(breathingPhase * 2),
                axis: (x: 0.3, y: 1, z: 0.2)
            )
            .shadow(
                color: .black.opacity(0.15),
                radius: isSelected ? 20 : 12,
                x: 0,
                y: isSelected ? 8 : 6
            )
            .shadow(
                color: .white.opacity(0.5),
                radius: 2,
                x: -1,
                y: -1
            )
        }
        .onAppear {
            // Subtle breathing animation
            withAnimation(.easeInOut(duration: Double.random(in: 3...5)).repeatForever(autoreverses: true)) {
                breathingPhase = 1.0
            }
            
            // Rainbow border animation
            if hasRainbowBorder {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    shimmerPhase = 360
                }
            }
        }
    }
}

/// 3D Glass Button with advanced effects
struct Advanced3DGlassButton<Content: View>: View {
    let content: Content
    let size: CGFloat
    let hasRainbowBorder: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var shimmerPhase: Double = 0
    @State private var pulsePhase: Double = 0
    
    init(
        size: CGFloat = 85,
        hasRainbowBorder: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.size = size
        self.hasRainbowBorder = hasRainbowBorder
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            action()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.2)) {
                    isPressed = false
                }
            }
        }) {
            ZStack {
                // Subtle pulse glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.cyan.opacity(0.1),
                                Color.blue.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: size * 0.3,
                            endRadius: size * 0.8
                        )
                    )
                    .frame(width: size * 1.3, height: size * 1.3)
                    .blur(radius: 10)
                    .scaleEffect(1.0 + pulsePhase * 0.2)
                    .opacity(0.7)
                
                // Main glass button
                ZStack {
                    // Base glass surface
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05)
                                ],
                                center: UnitPoint(x: 0.3, y: 0.3),
                                startRadius: size * 0.1,
                                endRadius: size * 0.5
                            )
                        )
                        .overlay(
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.8)
                                
                                Circle()
                                    .fill(.thinMaterial)
                                    .opacity(0.4)
                            }
                        )
                        .frame(width: size, height: size)
                    
                    // Rainbow border
                    if hasRainbowBorder {
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        .cyan, .blue, .purple, .pink,
                                        .orange, .yellow, .cyan
                                    ],
                                    center: .center,
                                    startAngle: .degrees(shimmerPhase),
                                    endAngle: .degrees(shimmerPhase + 360)
                                ),
                                lineWidth: 2.5
                            )
                            .frame(width: size + 1, height: size + 1)
                            .opacity(0.9)
                    }
                    
                    // Glass highlights
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.2),
                                    Color.clear,
                                    Color.black.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: size, height: size)
                    
                    // Content with proper scaling
                    content
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                }
                .scaleEffect(isPressed ? 0.95 : (1.0 + pulsePhase * 0.03))
                .rotation3DEffect(
                    .degrees(isPressed ? 3 : pulsePhase * 1),
                    axis: (x: 0.2, y: 1, z: 0.1)
                )
                .shadow(
                    color: .black.opacity(0.2),
                    radius: isPressed ? 8 : 15,
                    x: 0,
                    y: isPressed ? 3 : 6
                )
                .shadow(
                    color: .white.opacity(0.4),
                    radius: 1,
                    x: -1,
                    y: -1
                )
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                pulsePhase = 1.0
            }
            
            if hasRainbowBorder {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    shimmerPhase = 360
                }
            }
        }
    }
}

/// Advanced 3D Glass Search Bar
struct Advanced3DGlassSearchBar: View {
    @Binding var searchText: String
    @State private var rainbowPhase: Double = 0
    
    var body: some View {
        HStack(spacing: 16) {
            // AI Sparkles icon with rainbow animation
            ZStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        AngularGradient(
                            colors: [
                                .cyan, .blue, .purple, .pink,
                                .orange, .yellow, .cyan
                            ],
                            center: .center,
                            startAngle: .degrees(rainbowPhase),
                            endAngle: .degrees(rainbowPhase + 360)
                        )
                    )
            }
            .frame(width: 44, height: 44)
            .background(
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear,
                                            Color.black.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .shadow(color: .white.opacity(0.3), radius: 1, x: -1, y: -1)
                }
            )
            
            TextField("Ask anything you want to find...", text: $searchText)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
                .textFieldStyle(.plain)
            
            // Mic button
            Button(action: {}) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                            )
                            .shadow(color: .black.opacity(0.05), radius: 2)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.1),
                                        Color.clear,
                                        Color.black.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .shadow(color: .white.opacity(0.3), radius: 2, x: -1, y: -1)
            }
        )
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rainbowPhase = 360
            }
        }
    }
}

/// Name label with 3D glass effect
struct Advanced3DGlassLabel: View {
    let text: String
    let isProminent: Bool
    
    init(_ text: String, prominent: Bool = false) {
        self.text = text
        self.isProminent = prominent
    }
    
    var body: some View {
        Text(text)
            .font(.system(
                size: isProminent ? 16 : 14, 
                weight: isProminent ? .bold : .medium
            ))
            .foregroundStyle(.primary.opacity(0.9))
            .padding(.horizontal, isProminent ? 16 : 12)
            .padding(.vertical, isProminent ? 8 : 6)
            .background(
                ZStack {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .fill(isProminent ? Color.blue.opacity(0.1) : Color.clear)
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear,
                                            Color.black.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        )
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                        .shadow(color: .white.opacity(0.2), radius: 1, x: -1, y: -1)
                }
            )
    }
}