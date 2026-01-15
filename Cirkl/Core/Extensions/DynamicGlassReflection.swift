import SwiftUI

// MARK: - Dynamic Glass Reflection Modifier
/// Ajoute un reflet dynamique qui TOURNE autour de la bulle en fonction de l'orientation du device
/// Simule une source lumineuse fixe dans l'espace - quand tu tournes le téléphone, le reflet tourne
struct DynamicGlassReflectionModifier: ViewModifier {
    @State private var motion = MotionManager.shared

    let intensity: CGFloat
    let highlightColor: Color

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    let size = min(geometry.size.width, geometry.size.height)

                    // === CALCUL DE L'ANGLE DE ROTATION ===
                    // La lumière est "fixe dans l'espace" - quand le téléphone tourne, le reflet tourne
                    // Roll = rotation gauche/droite, Pitch = inclinaison avant/arrière
                    let lightAngle = atan2(
                        Double(motion.smoothRoll),
                        Double(-motion.smoothPitch)
                    )
                    let rotationDegrees = lightAngle * 180 / .pi

                    // Intensité basée sur l'inclinaison totale (plus incliné = reflet plus visible)
                    let tiltMagnitude = sqrt(
                        pow(Double(motion.smoothRoll), 2) +
                        pow(Double(motion.smoothPitch), 2)
                    )
                    let dynamicIntensity = min(1.0, 0.5 + tiltMagnitude * 2) * Double(intensity)

                    ZStack {
                        // === ARC PRINCIPAL DE REFLET ===
                        // Arc lumineux positionné en haut, tourne avec le device
                        Circle()
                            .trim(from: 0.60, to: 0.90)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        highlightColor.opacity(0.0),
                                        highlightColor.opacity(0.5 * dynamicIntensity),
                                        highlightColor.opacity(0.8 * dynamicIntensity),
                                        highlightColor.opacity(0.5 * dynamicIntensity),
                                        highlightColor.opacity(0.0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: size * 0.06, lineCap: .round)
                            )
                            .frame(width: size * 0.88, height: size * 0.88)

                        // === SPOT LUMINEUX ELLIPTIQUE ===
                        // Éclat principal au sommet du reflet
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        highlightColor.opacity(0.9 * dynamicIntensity),
                                        highlightColor.opacity(0.4 * dynamicIntensity),
                                        highlightColor.opacity(0.0)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: size * 0.15
                                )
                            )
                            .frame(width: size * 0.3, height: size * 0.08)
                            .offset(y: -size * 0.38)

                        // === POINT SPARKLE ===
                        // Petit éclat brillant
                        Circle()
                            .fill(highlightColor.opacity(0.95 * dynamicIntensity))
                            .frame(width: size * 0.04, height: size * 0.04)
                            .blur(radius: 0.5)
                            .offset(x: -size * 0.08, y: -size * 0.36)

                        // === REFLET SECONDAIRE (opposé) ===
                        // Léger reflet de l'autre côté pour plus de réalisme
                        Circle()
                            .trim(from: 0.10, to: 0.20)
                            .stroke(
                                highlightColor.opacity(0.15 * dynamicIntensity),
                                style: StrokeStyle(lineWidth: size * 0.03, lineCap: .round)
                            )
                            .frame(width: size * 0.85, height: size * 0.85)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    // === ROTATION GLOBALE ===
                    // Tout le système de reflet tourne autour du centre
                    .rotationEffect(.degrees(rotationDegrees))
                }
                .allowsHitTesting(false)
            }
            .onAppear {
                motion.start()
            }
    }
}

// MARK: - Rectangle Glass Reflection (pour les cartes)
/// Reflet dynamique adapté aux formes rectangulaires - le reflet glisse le long du bord supérieur
struct DynamicCardReflectionModifier: ViewModifier {
    @State private var motion = MotionManager.shared

    let intensity: CGFloat
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = geometry.size.height

                    // Position horizontale du reflet basée sur le roll
                    // Quand tu inclines à droite, le reflet va à gauche (comme une vraie lumière)
                    let reflectionX = -motion.smoothRoll * width * 0.4

                    // Intensité basée sur le pitch (plus incliné vers toi = plus visible)
                    let pitchIntensity = max(0.3, 1.0 - Double(motion.smoothPitch) * 2)

                    ZStack {
                        // === REFLET LINÉAIRE QUI GLISSE ===
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.0),
                                        Color.white.opacity(0.3 * intensity * pitchIntensity),
                                        Color.white.opacity(0.5 * intensity * pitchIntensity),
                                        Color.white.opacity(0.3 * intensity * pitchIntensity),
                                        Color.white.opacity(0.0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: width * 0.5, height: 2.5)
                            .offset(
                                x: reflectionX,
                                y: -height * 0.45
                            )

                        // === GLOW SUBTIL DANS LE COIN ===
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.15 * intensity * pitchIntensity),
                                        Color.white.opacity(0.0)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: width * 0.2
                                )
                            )
                            .frame(width: width * 0.35, height: height * 0.2)
                            .offset(
                                x: -width * 0.3 + reflectionX * 0.3,
                                y: -height * 0.35
                            )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                }
                .allowsHitTesting(false)
            }
            .onAppear {
                motion.start()
            }
    }
}

// MARK: - View Extensions
extension View {
    /// Ajoute un reflet dynamique circulaire qui TOURNE avec l'orientation du device
    /// - Parameters:
    ///   - intensity: Force du reflet (0.0 à 1.0, défaut 0.8)
    ///   - highlightColor: Couleur du reflet (défaut blanc)
    func dynamicGlassReflection(
        intensity: CGFloat = 0.8,
        highlightColor: Color = .white
    ) -> some View {
        modifier(DynamicGlassReflectionModifier(
            intensity: intensity,
            highlightColor: highlightColor
        ))
    }

    /// Reflet subtil pour les bulles secondaires
    func dynamicGlassReflectionSubtle() -> some View {
        dynamicGlassReflection(intensity: 0.4)
    }

    /// Reflet prononcé pour les éléments au premier plan
    func dynamicGlassReflectionProminent() -> some View {
        dynamicGlassReflection(intensity: 1.0)
    }

    /// Reflet dynamique pour les cartes/sections rectangulaires
    func dynamicCardReflection(
        intensity: CGFloat = 0.6,
        cornerRadius: CGFloat = 20
    ) -> some View {
        modifier(DynamicCardReflectionModifier(
            intensity: intensity,
            cornerRadius: cornerRadius
        ))
    }
}

// MARK: - Preview
#Preview("Dynamic Glass Reflection") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            // Bulle avec reflet dynamique
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.blue.opacity(0.2),
                            Color.blue.opacity(0.1)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .glassEffect(.regular, in: .circle)
                .dynamicGlassReflection(intensity: 0.9)

            // Carte avec reflet dynamique
            VStack {
                Text("Glass Card")
                    .foregroundColor(.white)
            }
            .frame(width: 200, height: 100)
            .background(Color.white.opacity(0.1))
            .glassEffect(.regular, in: .rect(cornerRadius: 20))
            .dynamicCardReflection(cornerRadius: 20)

            Text("Incline le device!")
                .foregroundColor(.secondary)
        }
    }
    .preferredColorScheme(.dark)
}
