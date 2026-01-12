import Foundation
import NearbyInteraction
import Combine

// MARK: - NearbyInteractionService
/// Service de mesure de distance UWB utilisant NearbyInteraction
/// Utilise la puce U1 pour une mesure précise de la distance (<10cm de précision)
@MainActor
final class NearbyInteractionService: NSObject, ObservableObject {

    // MARK: - Singleton
    static let shared = NearbyInteractionService()

    // MARK: - Published Properties
    @Published private(set) var distance: Float?
    @Published private(set) var direction: simd_float3?
    @Published private(set) var isWithinRange: Bool = false
    @Published private(set) var isAvailable: Bool = false
    @Published private(set) var isSessionActive: Bool = false

    // MARK: - Configuration
    /// Distance maximale pour considérer la vérification valide (en mètres)
    let verificationDistanceThreshold: Float = 0.5 // 50cm

    // MARK: - NearbyInteraction Properties
    private var session: NISession?
    private var peerDiscoveryToken: NIDiscoveryToken?

    // MARK: - Callbacks
    var onDistanceUpdated: ((Float) -> Void)?
    var onVerificationValid: (() -> Void)?
    var onSessionInvalidated: ((Error?) -> Void)?

    // MARK: - Initialization
    private override init() {
        super.init()
        checkAvailability()
    }

    // MARK: - Public Methods

    /// Vérifie si NearbyInteraction est disponible sur cet appareil
    func checkAvailability() {
        // Utiliser deviceCapabilities (iOS 16+) au lieu de isSupported (deprecated)
        let capabilities = NISession.deviceCapabilities
        isAvailable = capabilities.supportsPreciseDistanceMeasurement
    }

    /// Retourne le discovery token de la session courante
    /// - Returns: Les données du discovery token ou nil si non disponible
    func getDiscoveryTokenData() -> Data? {
        guard let session = session,
              let token = session.discoveryToken else {
            return nil
        }

        do {
            return try NSKeyedArchiver.archivedData(
                withRootObject: token,
                requiringSecureCoding: true
            )
        } catch {
            print("NearbyInteractionService: Erreur d'archivage du token: \(error)")
            return nil
        }
    }

    /// Démarre une session NearbyInteraction
    func startSession() {
        guard isAvailable else {
            print("NearbyInteractionService: Non disponible sur cet appareil")
            return
        }

        // Créer une nouvelle session
        session = NISession()
        session?.delegate = self
        isSessionActive = true

        print("NearbyInteractionService: Session démarrée")
    }

    /// Configure la session avec le token du peer distant
    /// - Parameter tokenData: Les données du discovery token reçues du peer
    func configureSession(withPeerTokenData tokenData: Data) {
        guard let session = session else {
            print("NearbyInteractionService: Session non initialisée")
            return
        }

        do {
            guard let token = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: NIDiscoveryToken.self,
                from: tokenData
            ) else {
                print("NearbyInteractionService: Token invalide")
                return
            }

            peerDiscoveryToken = token

            let configuration = NINearbyPeerConfiguration(peerToken: token)
            session.run(configuration)

            print("NearbyInteractionService: Session configurée avec le token peer")
        } catch {
            print("NearbyInteractionService: Erreur de désarchivage du token: \(error)")
        }
    }

    /// Arrête la session NearbyInteraction
    func stopSession() {
        session?.invalidate()
        session = nil
        peerDiscoveryToken = nil
        distance = nil
        direction = nil
        isWithinRange = false
        isSessionActive = false

        print("NearbyInteractionService: Session arrêtée")
    }

    /// Vérifie si la distance actuelle est dans le seuil de vérification
    /// - Returns: true si la distance est < 50cm
    func isDistanceValid() -> Bool {
        guard let distance = distance else { return false }
        return distance < verificationDistanceThreshold
    }

    // MARK: - Private Methods

    private func handleDistanceUpdate(_ distance: Float) {
        self.distance = distance
        let wasWithinRange = isWithinRange
        isWithinRange = distance < verificationDistanceThreshold

        onDistanceUpdated?(distance)

        // Notifier si on vient d'entrer dans la zone de vérification
        if isWithinRange && !wasWithinRange {
            onVerificationValid?()
        }
    }
}

// MARK: - NISessionDelegate
extension NearbyInteractionService: NISessionDelegate {

    nonisolated func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        Task { @MainActor in
            guard let nearbyObject = nearbyObjects.first else { return }

            // Mettre à jour la distance
            if let distance = nearbyObject.distance {
                self.handleDistanceUpdate(distance)
            }

            // Mettre à jour la direction (si disponible)
            if let direction = nearbyObject.direction {
                self.direction = direction
            }
        }
    }

    nonisolated func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        Task { @MainActor in
            switch reason {
            case .peerEnded:
                print("NearbyInteractionService: Le peer a terminé la session")
            case .timeout:
                print("NearbyInteractionService: Timeout de la session")
            @unknown default:
                print("NearbyInteractionService: Peer supprimé pour raison inconnue")
            }

            self.distance = nil
            self.direction = nil
            self.isWithinRange = false
        }
    }

    nonisolated func sessionWasSuspended(_ session: NISession) {
        Task { @MainActor in
            print("NearbyInteractionService: Session suspendue")
        }
    }

    nonisolated func sessionSuspensionEnded(_ session: NISession) {
        Task { @MainActor in
            print("NearbyInteractionService: Suspension terminée")

            // Reconfigurer la session si on a le token du peer
            if let tokenData = self.peerDiscoveryToken {
                let configuration = NINearbyPeerConfiguration(peerToken: tokenData)
                session.run(configuration)
            }
        }
    }

    nonisolated func session(_ session: NISession, didInvalidateWith error: Error) {
        Task { @MainActor in
            print("NearbyInteractionService: Session invalidée: \(error.localizedDescription)")

            self.isSessionActive = false
            self.distance = nil
            self.direction = nil
            self.isWithinRange = false

            self.onSessionInvalidated?(error)
        }
    }
}

// MARK: - Distance Formatting Extension
extension NearbyInteractionService {

    /// Formate la distance pour l'affichage
    var formattedDistance: String {
        guard let distance = distance else {
            return String(localized: "Distance inconnue")
        }

        if distance < 1.0 {
            return String(format: "%.0f cm", distance * 100)
        } else {
            return String(format: "%.1f m", distance)
        }
    }

    /// Retourne une couleur basée sur la distance
    var distanceColor: String {
        guard let distance = distance else { return "gray" }

        if distance < verificationDistanceThreshold {
            return "green" // Dans la zone de vérification
        } else if distance < 1.0 {
            return "yellow" // Proche mais pas assez
        } else {
            return "red" // Trop loin
        }
    }

    /// Message d'instruction basé sur la distance
    var distanceInstruction: String {
        guard let distance = distance else {
            return String(localized: "Rapprochez vos téléphones")
        }

        if distance < verificationDistanceThreshold {
            return String(localized: "Parfait ! Vérification en cours...")
        } else if distance < 1.0 {
            return String(localized: "Encore un peu plus près...")
        } else {
            return String(localized: "Rapprochez-vous davantage")
        }
    }
}
