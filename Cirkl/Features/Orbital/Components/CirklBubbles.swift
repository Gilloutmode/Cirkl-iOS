import SwiftUI

// MARK: - CIRKL BUBBLE COMPONENTS AVEC LIQUID GLASS 3D
// Système de bulles orbitales avec effet Liquid Glass 3D translucide

/// Bulle de profil dans la disposition orbitale avec Liquid Glass 3D
struct CirklProfileBubble: View {
    let connection: Connection
    let isSelected: Bool

    // Accessibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // PERFORMANCE FIX: Removed breathingPhase - animation was not visually used
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 8) {
            // Bulle principale
            ZStack {
                // Fond Liquid Glass natif iOS 26
                Circle()
                    .fill(connection.color.opacity(0.1))
                    .frame(width: 75, height: 75)
                    .glassEffect(.regular, in: .circle)
                    .shadow(color: connection.color.opacity(0.3), radius: isSelected ? 15 : 8, x: 0, y: 5)
                    .overlay(
                        Circle()
                            .stroke(
                                connection.color.opacity(isSelected ? 0.6 : 0.3),
                                lineWidth: isSelected ? 2.5 : 1.5
                            )
                    )

                // Icône de profil
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 35, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                connection.color,
                                connection.color.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(isSelected ? 1.15 : (isHovered ? 1.05 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.3), value: isSelected)
            .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.3), value: isHovered)

            // Nom sous la bulle - adaptatif light/dark
            Text(connection.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(DesignTokens.Colors.bubbleBackground)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
        }
        .onHover { hovering in
            isHovered = hovering
        }
        // PERFORMANCE FIX: Removed breathing animation - it wasn't visually affecting the view
    }
}

/// Bulle centrale utilisateur (Gil) avec Liquid Glass 3D et effet arc-en-ciel
/// PERFORMANCE FIX: Reduced from 2 animations to 1 (rainbow rotation only)
struct CirklCentralBubble: View {
    // Accessibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var rainbowRotation: Double = 0

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Effet de halo lumineux - PERFORMANCE FIX: Static (no pulse animation)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.pink.opacity(0.3),
                                Color.purple.opacity(0.2),
                                Color.blue.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)

                // Bulle principale avec Liquid Glass natif iOS 26
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .glassEffect(.regular, in: .circle)
                    .shadow(color: Color.purple.opacity(0.4), radius: 20, x: 0, y: 8)

                // Bordure arc-en-ciel animée
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                .red, .orange, .yellow, .green,
                                .blue, .purple, .pink, .red
                            ],
                            center: .center,
                            startAngle: .degrees(rainbowRotation),
                            endAngle: .degrees(rainbowRotation + 360)
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 100, height: 100)

                // Photo de profil centrale
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.pink,
                                Color.purple
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Nom avec effet spécial - adaptatif light/dark
            Text("Gil")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.pink, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(DesignTokens.Colors.bubbleBackground)
                        .shadow(color: Color.purple.opacity(0.3), radius: 4, x: 0, y: 2)
                )
        }
        .onAppear {
            // PERFORMANCE FIX: Only 1 animation (rainbow rotation) - removed pulse
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rainbowRotation = 360
            }
        }
    }
}

// MARK: - Composants de support

/// Contenu du profil pour les bulles de connexion
struct CirklProfileContent: View {
    let connection: Connection
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            connection.color.opacity(0.2),
                            connection.color.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 45))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            connection.color.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: connection.color.opacity(0.3), radius: 5)
        }
    }
}

/// Contenu central utilisateur
struct CirklCentralContent: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.red.opacity(0.15),
                            Color.pink.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 45
                    )
                )
            
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 55))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color.pink.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .red.opacity(0.4), radius: 8)
        }
    }
}

/// Étiquette de nom simplifiée
struct CirklNameLabel: View {
    enum Style {
        case normal, central
        
        var fontSize: CGFloat {
            switch self {
            case .normal: return 14
            case .central: return 16
            }
        }
        
        var fontWeight: Font.Weight {
            switch self {
            case .normal: return .medium
            case .central: return .bold
            }
        }
    }
    
    let text: String
    let style: Style
    
    var body: some View {
        Text(text)
            .font(.system(size: style.fontSize, weight: style.fontWeight))
            .foregroundStyle(DesignTokens.Colors.textPrimary)
            .padding(.horizontal, style == .central ? 16 : 12)
            .padding(.vertical, style == .central ? 8 : 6)
            .background(
                Capsule()
                    .fill(DesignTokens.Colors.bubbleBackground)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            )
    }
}