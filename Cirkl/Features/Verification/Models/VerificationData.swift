import Foundation

// MARK: - Verification Data (Données de vérification échangées)
/// Données échangées entre deux appareils lors de la vérification de proximité
struct VerificationData: Codable, Identifiable, Equatable {
    /// Identifiant unique de cette vérification
    let id: UUID

    /// ID de l'utilisateur qui envoie la vérification
    let userId: String

    /// Nom de l'utilisateur
    let userName: String

    /// URL de l'avatar (optionnel)
    let avatarURL: URL?

    /// Timestamp de la vérification
    let timestamp: Date

    /// Méthode de vérification utilisée
    let method: VerificationMethod

    /// Lieu de la rencontre (optionnel, basé sur GPS)
    let location: String?

    /// Coordonnées GPS (optionnel)
    let latitude: Double?
    let longitude: Double?

    /// Distance mesurée par UWB en mètres (nil si non disponible)
    let distance: Float?

    /// Token de découverte NearbyInteraction (pour échange UWB)
    let discoveryTokenData: Data?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        userId: String,
        userName: String,
        avatarURL: URL? = nil,
        timestamp: Date = Date(),
        method: VerificationMethod = .proximity,
        location: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        distance: Float? = nil,
        discoveryTokenData: Data? = nil
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.avatarURL = avatarURL
        self.timestamp = timestamp
        self.method = method
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.distance = distance
        self.discoveryTokenData = discoveryTokenData
    }

    // MARK: - Computed Properties

    /// Date formatée pour l'affichage
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: timestamp)
    }

    /// Distance formatée pour l'affichage
    var formattedDistance: String? {
        guard let distance = distance else { return nil }
        if distance < 1.0 {
            return String(format: "%.0f cm", distance * 100)
        } else {
            return String(format: "%.1f m", distance)
        }
    }
}

// MARK: - Verification Result
/// Résultat d'une vérification de proximité
struct VerificationResult: Codable, Equatable {
    /// Données de notre utilisateur
    let localData: VerificationData

    /// Données reçues de l'autre utilisateur
    let remoteData: VerificationData

    /// Distance finale mesurée (moyenne si plusieurs mesures)
    let finalDistance: Float?

    /// La vérification est-elle valide?
    let isValid: Bool

    /// Raison si invalide
    let invalidReason: String?

    /// Timestamp de la validation
    let validatedAt: Date

    // MARK: - Computed Properties

    /// Niveau de confiance résultant
    var resultingTrustLevel: TrustLevel {
        guard isValid else { return .pending }

        // Si distance UWB mesurée < 50cm = verified
        if let distance = finalDistance, distance < 0.5 {
            return .verified
        }

        // Sinon attested (QR code ou distance > 50cm)
        return .attested
    }
}
