import SwiftUI

// MARK: - LIQUID GLASS EXTENSIONS
// Extensions pour implémenter le design Liquid Glass dans SwiftUI

// GlassEffectStyle et GlassMaterial sont définis dans LiquidGlassEffect.swift

// L'extension glassEffect est définie dans LiquidGlassEffect.swift

/// Conteneur avec effet Liquid Glass
// GlassEffectContainer est défini dans LiquidGlassEffect.swift

/// Modificateur pour effet de survol interactif
struct InteractiveGlassEffect: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .brightness(isPressed ? -0.05 : 0)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }, perform: {})
    }
}

extension View {
    func interactiveGlass() -> some View {
        self.modifier(InteractiveGlassEffect())
    }
}

// MARK: - Formes personnalisées pour Liquid Glass
struct LiquidGlassShape: Shape {
    var animatableData: CGFloat = 0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.size.width
        let height = rect.size.height
        
        path.move(to: CGPoint(x: 0.08 * width, y: 0.2 * height))
        path.addCurve(
            to: CGPoint(x: 0.92 * width, y: 0.2 * height),
            control1: CGPoint(x: 0.3 * width, y: 0.1 * height),
            control2: CGPoint(x: 0.7 * width, y: 0.1 * height)
        )
        path.addLine(to: CGPoint(x: 0.92 * width, y: 0.8 * height))
        path.addCurve(
            to: CGPoint(x: 0.08 * width, y: 0.8 * height),
            control1: CGPoint(x: 0.7 * width, y: 0.9 * height),
            control2: CGPoint(x: 0.3 * width, y: 0.9 * height)
        )
        path.closeSubpath()
        
        return path
    }
}