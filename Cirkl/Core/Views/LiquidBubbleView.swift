import SwiftUI

// MARK: - Color Extension for Components

extension Color {
    var components: (red: Double, green: Double, blue: Double, alpha: Double) {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (Double(red), Double(green), Double(blue), Double(alpha))
    }
}

/// Apple Intelligence-inspired liquid motion bubble with organic, breathing animations
struct LiquidBubbleView: View {
    @State private var rotationAngle: Double = 0
    @State private var breathingScale: Double = 1.0
    @State private var shimmerOffset: Double = 0
    @State private var glowIntensity: Double = 0.8
    @Environment(\.colorScheme) private var colorScheme
    
    // Animation timers
    @State private var mainRotationTimer: Timer?
    @State private var breathingTimer: Timer?
    @State private var shimmerTimer: Timer?
    @State private var glowTimer: Timer?
    
    // Configuration
    let size: CGFloat
    let colors: [Color]
    let isActive: Bool
    
    init(size: CGFloat = 60, colors: [Color] = LiquidBubbleView.defaultColors, isActive: Bool = true) {
        self.size = size
        self.colors = colors
        self.isActive = isActive
    }
    
    static let defaultColors: [Color] = [
        .purple, .pink, .cyan, .blue, .orange, .yellow
    ]
    
    // Theme-adapted colors
    private var themeAdaptedColors: [Color] {
        if colorScheme == .dark {
            return colors
        } else {
            // Light mode: slightly more muted colors
            return colors.map { color in
                let components = color.components
                return Color(
                    red: components.red * 0.8,
                    green: components.green * 0.8,
                    blue: components.blue * 0.8,
                    opacity: components.alpha
                )
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Main bubble with multiple rotation layers
            ForEach(0..<3, id: \.self) { layer in
                bubbleLayer(layer: layer)
            }
            
            // Shimmer effect overlay
            shimmerOverlay
        }
        .frame(width: size, height: size)
        .scaleEffect(breathingScale)
        .onAppear {
            if isActive {
                startAnimations()
            }
        }
        .onDisappear {
            stopAnimations()
        }
    }
    
    // MARK: - Bubble Layers
    
    @ViewBuilder
    private func bubbleLayer(layer: Int) -> some View {
        let layerRotation = rotationAngle + Double(layer * 120) // Offset each layer
        let layerSpeed = layer == 0 ? 1.0 : layer == 1 ? 0.75 : 0.5 // Different speeds
        let layerSize = size * (1.0 - CGFloat(layer) * 0.15) // Slightly smaller each layer
        
        ZStack {
            // Main gradient with bleeding colors
            Circle()
                .fill(
                    RadialGradient(
                        colors: createBleedingGradient(for: layer),
                        center: .center,
                        startRadius: 0,
                        endRadius: layerSize / 2
                    )
                )
                .frame(width: layerSize, height: layerSize)
                .rotationEffect(.degrees(layerRotation * layerSpeed))
            
            // Glass reflection overlay
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .clear,
                            .white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: layerSize, height: layerSize)
                .rotationEffect(.degrees(layerRotation * layerSpeed + 45))
                .blendMode(.overlay)
            
            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.2),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: layerSize / 4
                    )
                )
                .frame(width: layerSize, height: layerSize)
                .rotationEffect(.degrees(layerRotation * layerSpeed))
        }
        .blur(radius: layer == 2 ? 2 : 0) // Outer layer has soft blur
        .opacity(layer == 2 ? 0.6 : 1.0) // Outer layer is more transparent
        .shadow(
            color: themeAdaptedColors.first?.opacity(0.3 * glowIntensity) ?? .clear,
            radius: layer == 0 ? 8 * glowIntensity : 4 * glowIntensity,
            x: 0,
            y: 0
        )
    }
    
    // MARK: - Gradient Creation
    
    private func createBleedingGradient(for layer: Int) -> [Color] {
        let baseColors = themeAdaptedColors
        
        // Create bleeding effect by mixing adjacent colors
        var bleedingColors: [Color] = []
        
        for i in 0..<baseColors.count {
            let currentColor = baseColors[i]
            let nextColor = baseColors[(i + 1) % baseColors.count]
            
            // Add the current color
            bleedingColors.append(currentColor)
            
            // Add a blended color between current and next
            let blendedColor = Color(
                red: (currentColor.components.red + nextColor.components.red) / 2,
                green: (currentColor.components.green + nextColor.components.green) / 2,
                blue: (currentColor.components.blue + nextColor.components.blue) / 2
            )
            bleedingColors.append(blendedColor.opacity(0.7))
        }
        
        return bleedingColors
    }
    
    // MARK: - Shimmer Overlay
    
    private var shimmerOverlay: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.9),
                        .white.opacity(0.6),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(shimmerOffset))
            .opacity(0.7)
            .blendMode(.overlay)
            .mask(
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.clear, .black, .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size / 2
                        )
                    )
            )
    }
    
    // MARK: - Animation Control
    
    private func startAnimations() {
        // Main rotation: 3-4 seconds per revolution
        mainRotationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            withAnimation(.linear(duration: 0.016)) {
                rotationAngle += 1.0 // 1 degree per frame at 60fps = 6 degrees per 0.1s
            }
        }
        
        // Breathing: 2-3 second cycle
        breathingTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.016)) {
                breathingScale = 1.0 + 0.1 * sin(Date().timeIntervalSince1970 * 2.0)
            }
        }
        
        // Shimmer: Passes every 2 seconds
        shimmerTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.016)) {
                shimmerOffset = (Date().timeIntervalSince1970 * 180).truncatingRemainder(dividingBy: 360)
            }
        }
        
        // Glow pulse: Subtle intensity variation
        glowTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.016)) {
                glowIntensity = 0.8 + 0.2 * sin(Date().timeIntervalSince1970 * 1.5)
            }
        }
    }
    
    private func stopAnimations() {
        mainRotationTimer?.invalidate()
        breathingTimer?.invalidate()
        shimmerTimer?.invalidate()
        glowTimer?.invalidate()
    }
}

// MARK: - Liquid Bubble Button

struct LiquidBubbleButton: View {
    let action: () -> Void
    let size: CGFloat
    let isActive: Bool
    
    init(action: @escaping () -> Void, size: CGFloat = 60, isActive: Bool = true) {
        self.action = action
        self.size = size
        self.isActive = isActive
    }
    
    var body: some View {
        Button(action: action) {
            LiquidBubbleView(size: size, isActive: isActive)
        }
        .buttonStyle(LiquidBubbleButtonStyle())
    }
}

// MARK: - Button Style

struct LiquidBubbleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Search Bar with Liquid Bubble

struct LiquidSearchBar: View {
    @Binding var text: String
    @State private var isFocused: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Liquid bubble icon with center adaptation
            ZStack {
                // Center adaptation to iOS theme
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                colorScheme == .dark ? .black : .white,
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 12
                        )
                    )
                    .frame(width: 24, height: 24)
                    .blendMode(.overlay)
                
                // Liquid bubble
                LiquidBubbleView(size: 24, isActive: isFocused || !text.isEmpty)
            }
            
            // Search text field
            TextField("Ask anything...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isFocused = true
                    }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 25))
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                isFocused = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // Standalone bubble
        LiquidBubbleView(size: 80)
        
        // Interactive button
        LiquidBubbleButton(action: {
            print("Button tapped!")
        }, size: 60, isActive: true)
        
        // Search bar
        LiquidSearchBar(text: .constant(""))
            .padding()
        
        Spacer()
    }
    .padding()
    .background(.black)
    .preferredColorScheme(.dark)
}
