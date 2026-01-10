import Foundation
import SwiftUI
import Combine
import MultipeerConnectivity

// MARK: - VerificationViewModel
/// ViewModel orchestrant la vérification de proximité
/// Coordonne ProximityVerificationService et NearbyInteractionService
@MainActor
@Observable
final class VerificationViewModel {

    // MARK: - State
    enum ViewState: Equatable {
        case idle
        case scanning
        case found(peerName: String)
        case connecting
        case measuring
        case verified(distance: Float?)
        case error(String)

        var title: String {
            switch self {
            case .idle:
                return String(localized: "Vérifier une rencontre")
            case .scanning:
                return String(localized: "Recherche en cours")
            case .found(let name):
                return String(localized: "\(name) détecté")
            case .connecting:
                return String(localized: "Connexion...")
            case .measuring:
                return String(localized: "Mesure de distance")
            case .verified:
                return String(localized: "Rencontre vérifiée !")
            case .error:
                return String(localized: "Erreur")
            }
        }
    }

    // MARK: - Properties
    private(set) var state: ViewState = .idle
    private(set) var nearbyUsers: [MCPeerID] = []
    private(set) var currentDistance: Float?
    private(set) var isUWBAvailable: Bool = false
    private(set) var verificationResult: VerificationResult?

    // Services
    private let proximityService = ProximityVerificationService.shared
    private let nearbyService = NearbyInteractionService.shared

    // Current user info
    private var currentUserId: String = ""
    private var currentUserName: String = ""
    private var currentAvatarURL: URL?

    // Completion handler
    var onVerificationComplete: ((Connection) -> Void)?

    // MARK: - Initialization
    init() {
        setupServiceCallbacks()
        isUWBAvailable = nearbyService.isAvailable
    }

    // MARK: - Public Methods

    /// Configure le ViewModel avec les informations de l'utilisateur courant
    func configure(userId: String, userName: String, avatarURL: URL? = nil) {
        currentUserId = userId
        currentUserName = userName
        currentAvatarURL = avatarURL
    }

    /// Démarre la recherche d'utilisateurs Cirkl à proximité
    func startScanning() {
        guard !currentUserId.isEmpty else {
            state = .error(String(localized: "Utilisateur non configuré"))
            return
        }

        state = .scanning

        // Démarrer MultipeerConnectivity
        proximityService.startVerification(
            userId: currentUserId,
            userName: currentUserName,
            avatarURL: currentAvatarURL
        )

        // Démarrer NearbyInteraction si disponible
        if isUWBAvailable {
            nearbyService.startSession()
        }
    }

    /// Arrête la recherche
    func stopScanning() {
        proximityService.stopVerification()
        nearbyService.stopSession()
        state = .idle
        nearbyUsers = []
        currentDistance = nil
    }

    /// Se connecte à un utilisateur détecté
    func connectTo(_ peer: MCPeerID) {
        state = .connecting
        proximityService.connectTo(peer)
    }

    /// Réessaye après une erreur
    func retry() {
        state = .idle
        stopScanning()

        // Petit délai avant de redémarrer
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            startScanning()
        }
    }

    /// Finalise la vérification et crée la connexion
    func finalizeVerification() {
        guard let receivedData = proximityService.receivedData else {
            state = .error(String(localized: "Données de vérification manquantes"))
            return
        }

        // Créer la connexion vérifiée
        let connection = createVerifiedConnection(from: receivedData)

        // Notifier la completion
        onVerificationComplete?(connection)

        // Arrêter les services
        stopScanning()
    }

    // MARK: - QR Fallback

    /// Génère les données pour le QR code de vérification
    func generateQRData() -> Data? {
        let qrData = VerificationData(
            userId: currentUserId,
            userName: currentUserName,
            avatarURL: currentAvatarURL,
            method: .qrCode
        )

        let encoder = JSONEncoder()
        return try? encoder.encode(qrData)
    }

    /// Traite un QR code scanné
    func processScannedQR(_ data: Data) {
        do {
            let decoder = JSONDecoder()
            let verificationData = try decoder.decode(VerificationData.self, from: data)

            // Créer la connexion depuis le QR
            let connection = createVerifiedConnection(from: verificationData, method: .qrCode)

            state = .verified(distance: nil)
            onVerificationComplete?(connection)

        } catch {
            state = .error(String(localized: "QR code invalide"))
        }
    }

    // MARK: - Private Methods

    private func setupServiceCallbacks() {
        // Callback quand des données sont reçues
        proximityService.onDataReceived = { [weak self] data in
            Task { @MainActor in
                guard let self = self else { return }

                // Si on a reçu un token NearbyInteraction, configurer la session
                if let tokenData = data.discoveryTokenData, self.isUWBAvailable {
                    self.nearbyService.configureSession(withPeerTokenData: tokenData)

                    // Envoyer notre token en retour
                    if let ourTokenData = self.nearbyService.getDiscoveryTokenData() {
                        try? self.proximityService.sendVerificationData(withDiscoveryToken: ourTokenData)
                    }
                }
            }
        }

        // Callback quand la connexion est établie
        proximityService.onConnectionEstablished = { [weak self] peer in
            Task { @MainActor in
                guard let self = self else { return }
                self.state = .measuring

                // Si UWB disponible, attendre la mesure de distance
                if self.isUWBAvailable {
                    // Envoyer notre token NearbyInteraction
                    if let tokenData = self.nearbyService.getDiscoveryTokenData() {
                        try? self.proximityService.sendVerificationData(withDiscoveryToken: tokenData)
                    }
                } else {
                    // Pas d'UWB, valider directement
                    self.state = .verified(distance: nil)
                }
            }
        }

        // Callback sur erreur
        proximityService.onError = { [weak self] error in
            Task { @MainActor in
                self?.state = .error(error.localizedDescription ?? "Erreur inconnue")
            }
        }

        // Callback de mise à jour de distance UWB
        nearbyService.onDistanceUpdated = { [weak self] distance in
            Task { @MainActor in
                self?.currentDistance = distance
            }
        }

        // Callback quand la distance est valide
        nearbyService.onVerificationValid = { [weak self] in
            Task { @MainActor in
                guard let self = self else { return }
                self.state = .verified(distance: self.currentDistance)
            }
        }
    }

    private func createVerifiedConnection(
        from data: VerificationData,
        method: VerificationMethod = .proximity
    ) -> Connection {
        // Déterminer le niveau de confiance
        let trustLevel: TrustLevel
        if let distance = currentDistance, distance < 0.5 {
            trustLevel = .verified
        } else if method == .qrCode {
            trustLevel = .attested
        } else {
            trustLevel = .attested
        }

        return Connection(
            id: UUID(),
            name: data.userName,
            avatarURL: data.avatarURL,
            connectionDate: Date(),
            lastInteraction: Date(),
            meetingPlace: data.location,
            verificationMethod: method,
            verificationLocation: data.location,
            trustLevel: trustLevel
        )
    }
}

// MARK: - Observable Updates
extension VerificationViewModel {

    /// Met à jour l'état basé sur l'état du service de proximité
    func syncWithProximityService() {
        nearbyUsers = proximityService.nearbyPeers

        switch proximityService.state {
        case .idle:
            if state != .idle && state != .verified(distance: nil) {
                state = .idle
            }
        case .scanning:
            state = .scanning
        case .found(let peerName, _):
            state = .found(peerName: peerName)
        case .connecting:
            state = .connecting
        case .measuring:
            state = .measuring
        case .verified(let distance):
            state = .verified(distance: distance)
        case .error(let error):
            state = .error(error.localizedDescription ?? "Erreur")
        }
    }
}
