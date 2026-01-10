import Foundation

// MARK: - Proximity State (État de la vérification de proximité)
/// Machine d'états pour le processus de vérification physique
enum ProximityState: Equatable {
    /// État initial - pas de scan en cours
    case idle

    /// Recherche d'utilisateurs Cirkl à proximité
    case scanning

    /// Un utilisateur a été détecté
    case found(peerName: String, peerId: String)

    /// Connexion en cours avec l'utilisateur détecté
    case connecting

    /// NearbyInteraction mesure la distance UWB
    case measuring

    /// Vérification réussie avec distance mesurée
    case verified(distance: Float)

    /// Erreur durant le processus
    case error(ProximityError)

    // MARK: - Computed Properties

    /// Indique si le processus est actif
    var isActive: Bool {
        switch self {
        case .idle, .error:
            return false
        default:
            return true
        }
    }

    /// Message de statut pour l'UI
    var statusMessage: String {
        switch self {
        case .idle:
            return String(localized: "Prêt à vérifier")
        case .scanning:
            return String(localized: "Recherche en cours...")
        case .found(let peerName, _):
            return String(localized: "\(peerName) détecté")
        case .connecting:
            return String(localized: "Connexion en cours...")
        case .measuring:
            return String(localized: "Mesure de distance...")
        case .verified(let distance):
            let distanceCm = Int(distance * 100)
            return String(localized: "Vérifié à \(distanceCm)cm")
        case .error(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Proximity Error
/// Erreurs possibles durant la vérification de proximité
enum ProximityError: Error, Equatable, LocalizedError {
    /// Permission réseau local refusée
    case localNetworkPermissionDenied

    /// Bluetooth désactivé
    case bluetoothDisabled

    /// NearbyInteraction non disponible (pas de puce U1)
    case nearbyInteractionUnavailable

    /// Timeout durant la recherche
    case searchTimeout

    /// Connexion perdue avec le peer
    case connectionLost

    /// Distance trop grande pour vérification
    case distanceTooFar(Float)

    /// Erreur inconnue
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .localNetworkPermissionDenied:
            return String(localized: "Permission réseau local requise. Activez-la dans les Réglages.")
        case .bluetoothDisabled:
            return String(localized: "Activez le Bluetooth pour détecter les utilisateurs proches.")
        case .nearbyInteractionUnavailable:
            return String(localized: "La mesure de distance n'est pas disponible sur cet appareil.")
        case .searchTimeout:
            return String(localized: "Aucun utilisateur Cirkl trouvé à proximité.")
        case .connectionLost:
            return String(localized: "La connexion a été perdue. Réessayez.")
        case .distanceTooFar(let distance):
            let distanceCm = Int(distance * 100)
            return String(localized: "Distance trop grande (\(distanceCm)cm). Rapprochez-vous.")
        case .unknown(let message):
            return message
        }
    }
}
