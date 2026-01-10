import Foundation
import SwiftUI

// MARK: - Trust Level (Niveau de confiance de la connexion)
/// Représente le niveau de confiance d'une connexion basé sur la méthode de vérification
enum TrustLevel: String, Codable, CaseIterable, Identifiable {
    case invited = "invited"           // 👻 Invitation envoyée, en attente de confirmation
    case pending = "pending"           // ⚪ En attente de vérification
    case attested = "attested"         // 🟡 Attestation mutuelle (SMS/invitation)
    case verified = "verified"         // 🟢 Vérification physique (proximity)
    case superVerified = "superVerified" // 🔵 Multi-vérifications confirmées

    var id: String { rawValue }

    // MARK: - Display Properties

    /// Nom affiché pour ce niveau de confiance
    var displayName: String {
        switch self {
        case .invited:
            return String(localized: "Invité")
        case .pending:
            return String(localized: "En attente")
        case .attested:
            return String(localized: "Attestée")
        case .verified:
            return String(localized: "Vérifiée")
        case .superVerified:
            return String(localized: "Super vérifiée")
        }
    }

    /// Description détaillée du niveau
    var description: String {
        switch self {
        case .invited:
            return String(localized: "Invitation envoyée, en attente de confirmation")
        case .pending:
            return String(localized: "Cette connexion n'a pas encore été vérifiée")
        case .attested:
            return String(localized: "Les deux personnes attestent s'être rencontrées")
        case .verified:
            return String(localized: "Rencontre physique vérifiée par proximité")
        case .superVerified:
            return String(localized: "Vérification confirmée plusieurs fois")
        }
    }

    /// Couleur associée à ce niveau de confiance
    var color: Color {
        switch self {
        case .invited:
            return .gray.opacity(0.4) // Gris très léger pour ghost
        case .pending:
            return .gray.opacity(0.6)
        case .attested:
            return Color(red: 1.0, green: 0.8, blue: 0.0) // Jaune/Or
        case .verified:
            return Color(red: 0.0, green: 0.78, blue: 0.51) // Mint CirKL
        case .superVerified:
            return Color(red: 0.0, green: 0.48, blue: 1.0) // Electric Blue CirKL
        }
    }

    /// Icône SF Symbol pour ce niveau
    var icon: String {
        switch self {
        case .invited:
            return "paperplane.circle"
        case .pending:
            return "questionmark.circle"
        case .attested:
            return "person.2.circle"
        case .verified:
            return "checkmark.seal.fill"
        case .superVerified:
            return "checkmark.shield.fill"
        }
    }

    /// Valeur numérique pour le tri (plus élevé = plus de confiance)
    var sortValue: Int {
        switch self {
        case .invited: return -1  // Invité mais pas encore confirmé
        case .pending: return 0
        case .attested: return 1
        case .verified: return 2
        case .superVerified: return 3
        }
    }

    /// Indique si ce niveau représente une connexion confirmée (pas en attente)
    var isConfirmed: Bool {
        switch self {
        case .invited, .pending:
            return false
        case .attested, .verified, .superVerified:
            return true
        }
    }
}

// MARK: - Comparable
extension TrustLevel: Comparable {
    static func < (lhs: TrustLevel, rhs: TrustLevel) -> Bool {
        lhs.sortValue < rhs.sortValue
    }
}
