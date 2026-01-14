import SwiftUI
import CoreMotion

// MARK: - Motion Manager for Parallax Effects
/// Gère les données de l'accéléromètre/gyroscope pour les effets parallaxe Liquid Glass
/// Inspiré du home screen iOS qui réagit au mouvement du device
@MainActor
@Observable
final class MotionManager {
    static let shared = MotionManager()

    // Valeurs normalisées pour l'effet parallaxe (-1 à 1)
    var pitch: Double = 0  // Inclinaison avant/arrière
    var roll: Double = 0   // Inclinaison gauche/droite

    // Valeurs lissées pour animations fluides
    var smoothPitch: Double = 0
    var smoothRoll: Double = 0

    private let motionManager = CMMotionManager()
    private var isRunning = false
    private let smoothingFactor: Double = 0.15 // Plus bas = plus fluide

    private init() {}

    // MARK: - Public API

    /// Démarre la capture des données de mouvement
    func start() {
        guard motionManager.isDeviceMotionAvailable, !isRunning else { return }

        // PERFORMANCE FIX: Reduced from 60fps to 30fps - still smooth but much less CPU load
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }

            // CONCURRENCY FIX: Use MainActor.assumeIsolated since we're already on main queue
            // This avoids "unsafeForcedSync called from Swift Concurrent context" warning
            MainActor.assumeIsolated {
                // Valeurs brutes de l'attitude (pitch et roll)
                let rawPitch = motion.attitude.pitch
                let rawRoll = motion.attitude.roll

                // Limiter les valeurs pour éviter les mouvements extrêmes
                let clampedPitch = max(-0.5, min(0.5, rawPitch))
                let clampedRoll = max(-0.5, min(0.5, rawRoll))

                // Mise à jour des valeurs brutes
                self.pitch = clampedPitch
                self.roll = clampedRoll

                // Lissage exponentiel pour des animations fluides
                self.smoothPitch += (clampedPitch - self.smoothPitch) * self.smoothingFactor
                self.smoothRoll += (clampedRoll - self.smoothRoll) * self.smoothingFactor
            }
        }
        isRunning = true

        #if DEBUG
        print("🎯 MotionManager: Started motion updates")
        #endif
    }

    /// Arrête la capture des données de mouvement
    func stop() {
        guard isRunning else { return }
        motionManager.stopDeviceMotionUpdates()
        isRunning = false

        #if DEBUG
        print("🎯 MotionManager: Stopped motion updates")
        #endif
    }

    /// Vérifie si le device supporte les capteurs de mouvement
    var isAvailable: Bool {
        motionManager.isDeviceMotionAvailable
    }

    /// Réinitialise les valeurs à zéro (utile pour calibration)
    func reset() {
        pitch = 0
        roll = 0
        smoothPitch = 0
        smoothRoll = 0
    }
}

// MARK: - Preview Helper
#if DEBUG
extension MotionManager {
    /// Simule des valeurs de mouvement pour les previews
    func simulateMotion(pitch: Double, roll: Double) {
        self.pitch = pitch
        self.roll = roll
        self.smoothPitch = pitch
        self.smoothRoll = roll
    }
}
#endif