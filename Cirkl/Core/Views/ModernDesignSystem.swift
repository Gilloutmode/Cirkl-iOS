import SwiftUI

// MARK: - Modern Design System for iOS 18
struct ModernDesignSystem {
    
    // MARK: - Colors
    struct Colors {
        // Primary Brand Colors
        static let primaryViolet = Color(red: 108/255, green: 99/255, blue: 255/255)
        static let primaryCoral = Color(red: 255/255, green: 107/255, blue: 107/255)
        static let primaryTurquoise = Color(red: 78/255, green: 205/255, blue: 196/255)
        static let darkBackground = Color(red: 10/255, green: 14/255, blue: 39/255)
        
        // User-specific colors
        static let gilSignature = Color(red: 220/255, green: 38/255, blue: 127/255)
        static let denisSignature = Color(red: 0/255, green: 122/255, blue: 255/255)
        static let gillesSignature = Color(red: 52/255, green: 199/255, blue: 89/255)
        
        // Glassmorphism
        static let glassLight = Color.white.opacity(0.1)
        static let glassDark = Color.black.opacity(0.3)
        static let glassUltraLight = Color.white.opacity(0.05)
        
        // Semantic Colors
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary = Color.white.opacity(0.5)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 12
        static let medium: CGFloat = 20
        static let large: CGFloat = 28
        static let xlarge: CGFloat = 36
        static let full: CGFloat = 9999
    }
    
    // MARK: - Typography
    struct Typography {
        static func largeTitle() -> Font {
            .system(size: 34, weight: .bold, design: .rounded)
        }
        
        static func title() -> Font {
            .system(size: 28, weight: .semibold, design: .rounded)
        }
        
        static func headline() -> Font {
            .system(size: 20, weight: .semibold, design: .rounded)
        }
        
        static func body() -> Font {
            .system(size: 17, weight: .regular, design: .rounded)
        }
        
        static func callout() -> Font {
            .system(size: 16, weight: .regular, design: .rounded)
        }
        
        static func caption() -> Font {
            .system(size: 14, weight: .regular, design: .rounded)
        }
    }
    
    // MARK: - Animations
    struct Animation {
        static let springSmooth = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
        static let springQuick = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let easeInOutSmooth = SwiftUI.Animation.easeInOut(duration: 0.3)
    }
    
    // MARK: - Shadow
    struct Shadows {
        static func soft() -> (Color, CGFloat, CGFloat, CGFloat) {
            (Color.black.opacity(0.15), 10, 0, 5)
        }
        
        static func medium() -> (Color, CGFloat, CGFloat, CGFloat) {
            (Color.black.opacity(0.2), 20, 0, 10)
        }
        
        static func strong() -> (Color, CGFloat, CGFloat, CGFloat) {
            (Color.black.opacity(0.3), 30, 0, 15)
        }
        
        static func glow(color: Color) -> (Color, CGFloat, CGFloat, CGFloat) {
            (color.opacity(0.6), 20, 0, 0)
        }
    }
}

// MARK: - Glass Material View Modifier
struct GlassMaterial: ViewModifier {
    var cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.large
    var borderOpacity: Double = 0.2
    var blurRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Blur effect
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    
                    // Gradient overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    ModernDesignSystem.Colors.glassLight,
                                    ModernDesignSystem.Colors.glassUltraLight
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(borderOpacity),
                                    Color.white.opacity(borderOpacity * 0.5)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
    }
}

// MARK: - Convenience Extensions
extension View {
    func glassMaterial(
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.large,
        borderOpacity: Double = 0.2
    ) -> some View {
        modifier(GlassMaterial(cornerRadius: cornerRadius, borderOpacity: borderOpacity))
    }
    
    func softShadow() -> some View {
        shadow(
            color: .black.opacity(0.15),
            radius: 10,
            x: 0,
            y: 5
        )
    }
    
    func glowEffect(color: Color = ModernDesignSystem.Colors.primaryViolet) -> some View {
        shadow(color: color.opacity(0.6), radius: 20)
    }
}

// MARK: - Haptic Feedback Manager
struct HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}