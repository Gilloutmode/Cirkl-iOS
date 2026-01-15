import SwiftUI

// MARK: - Animated Glass Background
/// Fond animé avec orbes lumineuses qui réagissent au mouvement du device
/// Crée une ambiance immersive de type "univers vivant" pour l'interface orbitale
struct AnimatedGlassBackground: View {
    @State private var motion = MotionManager.shared

    // Configuration des orbes
    let primaryOrbColor: Color
    let secondaryOrbColor: Color
    let showTertiaryOrb: Bool

    // PERFORMANCE FIX: Disabled tertiary orb by default to reduce GPU load
    init(
        primaryOrbColor: Color = DesignTokens.Colors.electricBlue,
        secondaryOrbColor: Color = DesignTokens.Colors.success,
        showTertiaryOrb: Bool = false
    ) {
        self.primaryOrbColor = primaryOrbColor
        self.secondaryOrbColor = secondaryOrbColor
        self.showTertiaryOrb = showTertiaryOrb
    }

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                // Fond gradient de base
                LinearGradient(
                    colors: [
                        DesignTokens.Colors.background,
                        DesignTokens.Colors.surface
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Orbe primaire (Electric Blue) - Centre haut
                // PERFORMANCE FIX: Reduced motion multipliers from 60 to 20 for less frequent redraws
                GlowingOrb(
                    color: primaryOrbColor,
                    size: 400,
                    blur: 80,
                    opacity: 0.25
                )
                .position(
                    x: center.x + motion.smoothRoll * 20,
                    y: center.y - 150 + motion.smoothPitch * 20
                )

                // Orbe secondaire (Mint/Success) - Bas gauche
                GlowingOrb(
                    color: secondaryOrbColor,
                    size: 300,
                    blur: 60,
                    opacity: 0.18
                )
                .position(
                    x: center.x - 120 + motion.smoothRoll * 15,
                    y: center.y + 200 + motion.smoothPitch * 15
                )

                // Orbe tertiaire (Purple) - Droite (disabled by default)
                if showTertiaryOrb {
                    GlowingOrb(
                        color: .purple,
                        size: 250,
                        blur: 50,
                        opacity: 0.12
                    )
                    .position(
                        x: center.x + 150 + motion.smoothRoll * 10,
                        y: center.y + 50 + motion.smoothPitch * 10
                    )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            motion.start()
        }
        // PERFORMANCE FIX: Stop motion updates when view disappears (e.g., when sheet is presented)
        // This prevents unnecessary CPU usage and view updates in background
        .onDisappear {
            motion.stop()
        }
    }
}

// MARK: - Glowing Orb Component
/// Orbe lumineuse avec gradient radial et effet de glow
struct GlowingOrb: View {
    let color: Color
    let size: CGFloat
    let blur: CGFloat
    let opacity: Double

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        color.opacity(opacity),
                        color.opacity(opacity * 0.5),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: blur)
    }
}

// MARK: - Simplified Background (Performance Mode)
/// Version simplifiée du fond pour les devices moins performants
struct SimpleGlassBackground: View {
    var body: some View {
        ZStack {
            DesignTokens.Colors.background

            // Un seul gradient subtil
            RadialGradient(
                colors: [
                    DesignTokens.Colors.electricBlue.opacity(0.15),
                    Color.clear
                ],
                center: .top,
                startRadius: 100,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Adaptive Glass Background
/// Choisit automatiquement le fond en fonction des performances
struct AdaptiveGlassBackground: View {
    @EnvironmentObject private var performanceManager: PerformanceManager

    var body: some View {
        Group {
            if performanceManager.shouldShowLiquidEffects {
                AnimatedGlassBackground()
            } else {
                SimpleGlassBackground()
            }
        }
    }
}

// MARK: - Standalone Adaptive Background (sans EnvironmentObject)
/// Version qui fonctionne sans EnvironmentObject - utilise toujours le fond animé
struct StandaloneAdaptiveBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                SimpleGlassBackground()
            } else {
                AnimatedGlassBackground()
            }
        }
    }
}

// MARK: - Preview
#Preview("Animated Glass Background") {
    ZStack {
        AnimatedGlassBackground()

        VStack {
            Text("Animated Background")
                .font(.title)
                .foregroundStyle(.white)

            Text("Incline le device pour voir l'effet")
                .foregroundStyle(.secondary)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Simple Background") {
    SimpleGlassBackground()
        .preferredColorScheme(.dark)
}
