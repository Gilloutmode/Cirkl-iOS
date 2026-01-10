import SwiftUI

// MARK: - CIRKL DESIGN SYSTEM
// Centralized design tokens and theme system

/// Cirkl color palette
struct CirklColors {
    static let primary = Color(.systemBlue)
    static let secondary = Color(.systemGray)
    static let accent = Color(.systemPink)
    
    // Glass morphism colors
    static let glassBase = Color.white.opacity(0.1)
    static let glassBorder = Color.white.opacity(0.2)
    static let glassShadow = Color.black.opacity(0.03)
    
    // Rainbow gradient colors
    static let rainbowGradient = [
        Color.cyan, Color.blue, Color.purple,
        Color.pink, Color.orange, Color.yellow, Color.cyan
    ]
    
    // Connection colors based on relationship strength
    static func connectionColor(for strength: CGFloat) -> Color {
        let hue = Double.random(in: 0...1)
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }
}

/// Typography system
struct CirklTypography {
    static let titleLarge = Font.system(size: 28, weight: .bold)
    static let titleMedium = Font.system(size: 18, weight: .semibold)
    static let bodyRegular = Font.system(size: 16, weight: .regular)
    static let bodyMedium = Font.system(size: 16, weight: .medium)
    static let captionRegular = Font.system(size: 14, weight: .regular)
    static let captionMedium = Font.system(size: 14, weight: .medium)
}

/// Spacing system
struct CirklSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}

/// Corner radius system
struct CirklRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let full: CGFloat = .infinity
}

/// Glass morphism style modifiers
struct GlassMorphismModifier: ViewModifier {
    let cornerRadius: CGFloat
    let opacity: Double
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial.opacity(opacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(CirklColors.glassBorder, lineWidth: 0.5)
                    )
                    .shadow(color: CirklColors.glassShadow, radius: 8, x: 0, y: 2)
            }
    }
}

extension View {
    func glassMorphism(
        cornerRadius: CGFloat = CirklRadius.lg,
        opacity: Double = 0.5
    ) -> some View {
        modifier(GlassMorphismModifier(cornerRadius: cornerRadius, opacity: opacity))
    }
}

/// Rainbow gradient modifier
struct RainbowBorderModifier: ViewModifier {
    let lineWidth: CGFloat
    let animationPhase: Double
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: CirklRadius.xl)
                    .stroke(
                        AngularGradient(
                            colors: CirklColors.rainbowGradient,
                            center: .center,
                            startAngle: .degrees(animationPhase),
                            endAngle: .degrees(animationPhase + 360)
                        ),
                        lineWidth: lineWidth
                    )
            )
    }
}

extension View {
    func rainbowBorder(
        lineWidth: CGFloat = 2,
        animationPhase: Double = 0
    ) -> some View {
        modifier(RainbowBorderModifier(lineWidth: lineWidth, animationPhase: animationPhase))
    }
}

/// Breathing animation modifier
struct BreathingAnimationModifier: ViewModifier {
    let intensity: Double
    let duration: Double
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(1.0 + (isAnimating ? intensity : 0))
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    func breathingAnimation(
        intensity: Double = 0.03,
        duration: Double = 4.0
    ) -> some View {
        modifier(BreathingAnimationModifier(intensity: intensity, duration: duration))
    }
}

/// 3D rotation animation modifier
struct FloatingAnimationModifier: ViewModifier {
    let intensity: Double
    let duration: Double
    @State private var rotationPhase: Double = 0
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(rotationPhase * intensity),
                axis: (x: 0.5, y: 1, z: 0.3)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: false)
                ) {
                    rotationPhase = 360
                }
            }
    }
}

extension View {
    func floatingAnimation(
        intensity: Double = 1.0,
        duration: Double = 8.0
    ) -> some View {
        modifier(FloatingAnimationModifier(intensity: intensity, duration: duration))
    }
}

/// Orbital position calculator
struct OrbitalPositionCalculator {
    static func position(
        for index: Int,
        totalCount: Int,
        center: CGPoint,
        radius: CGFloat,
        startAngle: Double = 0
    ) -> CGPoint {
        let angleStep = 360.0 / Double(totalCount)
        let angle = startAngle + Double(index) * angleStep
        let angleRad = angle * .pi / 180
        
        return CGPoint(
            x: center.x + CGFloat(cos(angleRad)) * radius,
            y: center.y + CGFloat(sin(angleRad)) * radius
        )
    }
}

/// Performance-aware animation quality
extension AnimationQuality {
    var glassOpacity: Double {
        switch self {
        case .reduced: return 0.2
        case .medium: return 0.3
        case .high: return 0.5
        }
    }
    
    var shadowRadius: CGFloat {
        switch self {
        case .reduced: return 4
        case .medium: return 8
        case .high: return 12
        }
    }
    
    var blurRadius: CGFloat {
        switch self {
        case .reduced: return 5
        case .medium: return 10
        case .high: return 20
        }
    }
}