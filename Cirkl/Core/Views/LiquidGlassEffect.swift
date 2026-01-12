import SwiftUI

// MARK: - Helper Type for Shape Erasure
public struct AnyShape: Shape, @unchecked Sendable {
    private let _path: @Sendable (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = { rect in shape.path(in: rect) }
    }

    public func path(in rect: CGRect) -> Path {
        return _path(rect)
    }
}

// MARK: - LIQUID GLASS EFFECT POUR iOS 26
// Implémentation complète du système Liquid Glass 3D Translucide

/// Style de l'effet Liquid Glass
public struct GlassEffectStyle {
    let opacity: Double
    let blurRadius: CGFloat
    let tintColor: Color?
    let isInteractive: Bool
    let refractionIntensity: Double
    
    // Styles prédéfinis
    public static let regular = GlassEffectStyle(
        opacity: 0.15,
        blurRadius: 20,
        tintColor: nil,
        isInteractive: false,
        refractionIntensity: 0.8
    )
    
    public static let clear = GlassEffectStyle(
        opacity: 0.05,
        blurRadius: 10,
        tintColor: nil,
        isInteractive: false,
        refractionIntensity: 0.5
    )
    
    public static let thick = GlassEffectStyle(
        opacity: 0.25,
        blurRadius: 30,
        tintColor: nil,
        isInteractive: false,
        refractionIntensity: 1.0
    )
    
    // Modificateurs de style
    public func tint(_ color: Color) -> GlassEffectStyle {
        GlassEffectStyle(
            opacity: opacity,
            blurRadius: blurRadius,
            tintColor: color,
            isInteractive: isInteractive,
            refractionIntensity: refractionIntensity
        )
    }
    
    public func interactive() -> GlassEffectStyle {
        GlassEffectStyle(
            opacity: opacity,
            blurRadius: blurRadius,
            tintColor: tintColor,
            isInteractive: true,
            refractionIntensity: refractionIntensity
        )
    }
}

/// Formes pour l'effet Glass
public enum GlassShape {
    case circle
    case capsule
    case rect(cornerRadius: CGFloat)
    case ellipse
}

// MARK: - Liquid Glass Modifier

struct LiquidGlassModifier: ViewModifier {
    let style: GlassEffectStyle
    let shape: GlassShape
    @State private var isPressed = false
    @State private var shimmerPhase: Double = 0
    @State private var breathingPhase: Double = 0
    
    func body(content: Content) -> some View {
        content
            .background {
                glassBackground()
            }
            .overlay {
                glassHighlights()
            }
            .scaleEffect(isPressed && style.isInteractive ? 0.98 : 1.0)
            .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.6), value: isPressed)
            .onAppear {
                startAnimations()
            }
            .onTapGesture {
                if style.isInteractive {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isPressed = false
                        }
                    }
                }
            }
    }
    
    @ViewBuilder
    private func glassBackground() -> some View {
        ZStack {
            // Couche de base avec blur
            shapeView()
                .fill(.ultraThinMaterial.opacity(style.opacity))
                .background {
                    // Effet de réfraction
                    shapeView()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blur(radius: style.blurRadius * 0.5)
                }
            
            // Couche de teinte si spécifiée
            if let tintColor = style.tintColor {
                shapeView()
                    .fill(tintColor.opacity(0.15))
                    .blendMode(.overlay)
            }
            
            // Bordure translucide
            shapeView()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 10,
            x: 0,
            y: 5
        )
    }
    
    @ViewBuilder
    private func glassHighlights() -> some View {
        ZStack {
            // Reflet principal
            shapeView()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .mask {
                    shapeView()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            
            // Effet de shimmer animé
            if style.isInteractive {
                shapeView()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: UnitPoint(x: shimmerPhase - 0.3, y: 0),
                            endPoint: UnitPoint(x: shimmerPhase + 0.3, y: 1)
                        )
                    )
                    .opacity(0.5)
            }
        }
    }
    
    private func shapeView() -> AnyShape {
        switch shape {
        case .circle:
            return AnyShape(Circle())
        case .capsule:
            return AnyShape(Capsule())
        case .rect(let radius):
            return AnyShape(RoundedRectangle(cornerRadius: radius))
        case .ellipse:
            return AnyShape(Ellipse())
        }
    }
    
    private func startAnimations() {
        if style.isInteractive {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                shimmerPhase = 2
            }
        }
        
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            breathingPhase = 1
        }
    }
}

// MARK: - Glass Effect Container

public struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content
    
    public init(spacing: CGFloat = 20, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }
    
    public var body: some View {
        ZStack {
            // Fond subtil pour améliorer l'effet de verre
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial.opacity(0.01))
                .blur(radius: 100)
                .ignoresSafeArea()
            
            // Contenu avec espacement
            VStack(spacing: spacing) {
                content()
            }
        }
    }
}

// MARK: - Extensions View

extension View {
    /// Applique l'effet Liquid Glass à une vue
    public func glassEffect(_ style: GlassEffectStyle = .regular, in shape: GlassShape = .capsule) -> some View {
        self.modifier(LiquidGlassModifier(style: style, shape: shape))
    }
    
    /// Version simplifiée pour compatibilité avec le code existant
    public func glassEffect() -> some View {
        self.glassEffect(.regular, in: .capsule)
    }
}

// MARK: - 3D Bubble Effect Modifier

public struct Bubble3DModifier: ViewModifier {
    let depth: CGFloat
    let isInteractive: Bool
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0
    @State private var scale: CGFloat = 1.0
    
    public func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(rotationX),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.5
            )
            .rotation3DEffect(
                .degrees(rotationY),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
            .scaleEffect(scale)
            .onAppear {
                if isInteractive {
                    withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                        rotationX = 5
                        rotationY = 5
                        scale = 1.05
                    }
                }
            }
            .shadow(
                color: .black.opacity(0.2),
                radius: depth * 2,
                x: 0,
                y: depth
            )
    }
}

extension View {
    /// Ajoute un effet 3D de bulle
    public func bubble3DEffect(depth: CGFloat = 10, isInteractive: Bool = true) -> some View {
        self.modifier(Bubble3DModifier(depth: depth, isInteractive: isInteractive))
    }
}

// MARK: - Rainbow Border Modifier

/// Modifier pour ajouter une bordure arc-en-ciel animée
struct RainbowBorderModifier: ViewModifier {
    let lineWidth: CGFloat
    @State var animationPhase: Double

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        AngularGradient(
                            colors: [
                                .red, .orange, .yellow, .green,
                                .blue, .purple, .pink, .red
                            ],
                            center: .center,
                            startAngle: .degrees(animationPhase),
                            endAngle: .degrees(animationPhase + 360)
                        ),
                        lineWidth: lineWidth
                    )
            )
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    animationPhase = 360
                }
            }
    }
}

// MARK: - Rainbow Border Extension

public extension View {
    /// Ajoute une bordure arc-en-ciel animée
    func rainbowBorder(lineWidth: CGFloat = 2) -> some View {
        self.modifier(RainbowBorderModifier(lineWidth: lineWidth, animationPhase: 0))
    }
}