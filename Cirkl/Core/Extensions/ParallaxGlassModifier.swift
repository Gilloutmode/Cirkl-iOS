import SwiftUI

// MARK: - Parallax Glass Modifier
/// Modificateur qui ajoute un effet parallaxe aux vues, réagissant au mouvement du device
/// Crée une profondeur 3D subtile inspirée du home screen iOS
struct ParallaxGlassModifier: ViewModifier {
    let intensity: CGFloat
    let useSmoothing: Bool
    let enable3DRotation: Bool

    @State private var motion = MotionManager.shared

    // Facteurs de transformation
    private let rotationMultiplier: CGFloat = 8
    private let offsetMultiplier: CGFloat = 15

    func body(content: Content) -> some View {
        let pitch = useSmoothing ? motion.smoothPitch : motion.pitch
        let roll = useSmoothing ? motion.smoothRoll : motion.roll

        content
            .modifier(ConditionalRotation3D(
                enabled: enable3DRotation,
                pitchDegrees: pitch * intensity * rotationMultiplier,
                rollDegrees: roll * intensity * rotationMultiplier
            ))
            .offset(
                x: roll * intensity * offsetMultiplier,
                y: pitch * intensity * offsetMultiplier
            )
            .onAppear {
                motion.start()
            }
    }
}

// MARK: - Conditional 3D Rotation Helper
/// Helper pour appliquer rotation3DEffect conditionnellement
private struct ConditionalRotation3D: ViewModifier {
    let enabled: Bool
    let pitchDegrees: Double
    let rollDegrees: Double

    func body(content: Content) -> some View {
        if enabled {
            content
                .rotation3DEffect(
                    .degrees(pitchDegrees),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.5
                )
                .rotation3DEffect(
                    .degrees(rollDegrees),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
        } else {
            content
        }
    }
}

// MARK: - View Extension
extension View {
    /// Ajoute un effet parallaxe glass qui réagit au mouvement du device
    /// - Parameters:
    ///   - intensity: Force de l'effet (0.0 à 2.0, défaut 1.0)
    ///   - useSmoothing: Utilise des valeurs lissées pour plus de fluidité
    ///   - enable3DRotation: Active la rotation 3D en plus du déplacement
    /// - Returns: Vue avec effet parallaxe
    func parallaxGlass(
        intensity: CGFloat = 1.0,
        useSmoothing: Bool = true,
        enable3DRotation: Bool = true
    ) -> some View {
        modifier(ParallaxGlassModifier(
            intensity: intensity,
            useSmoothing: useSmoothing,
            enable3DRotation: enable3DRotation
        ))
    }

    /// Effet parallaxe léger (pour éléments d'arrière-plan)
    func parallaxGlassSubtle() -> some View {
        parallaxGlass(intensity: 0.3, enable3DRotation: false)
    }

    /// Effet parallaxe prononcé (pour éléments au premier plan)
    func parallaxGlassProminent() -> some View {
        parallaxGlass(intensity: 1.2, enable3DRotation: true)
    }
}

// MARK: - Parallax Layer Modifier
/// Modificateur pour créer des couches de parallaxe avec différentes profondeurs
struct ParallaxLayerModifier: ViewModifier {
    let depth: ParallaxDepth

    @State private var motion = MotionManager.shared

    func body(content: Content) -> some View {
        let pitch = motion.smoothPitch
        let roll = motion.smoothRoll

        content
            .offset(
                x: roll * depth.offsetFactor,
                y: pitch * depth.offsetFactor
            )
            .onAppear {
                motion.start()
            }
    }
}

// MARK: - Parallax Depth Levels
enum ParallaxDepth {
    case background   // Bouge peu (loin)
    case midground    // Mouvement moyen
    case foreground   // Bouge beaucoup (proche)
    case floating     // Effet flottant exagéré

    var offsetFactor: CGFloat {
        switch self {
        case .background: return 5
        case .midground: return 15
        case .foreground: return 30
        case .floating: return 50
        }
    }
}

extension View {
    /// Applique un effet parallaxe basé sur la profondeur
    func parallaxLayer(_ depth: ParallaxDepth) -> some View {
        modifier(ParallaxLayerModifier(depth: depth))
    }
}

// MARK: - Preview
#Preview("Parallax Glass Effect") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            // Carte avec effet parallaxe
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .frame(width: 200, height: 120)
                .overlay {
                    Text("Parallax Card")
                        .foregroundStyle(.white)
                }
                .parallaxGlass(intensity: 1.0)

            // Cercle avec effet subtil
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .parallaxGlassSubtle()

            Text("Incline ton device!")
                .foregroundStyle(.secondary)
        }
    }
}
