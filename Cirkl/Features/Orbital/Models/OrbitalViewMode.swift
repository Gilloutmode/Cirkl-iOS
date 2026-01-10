import SwiftUI

// MARK: - OrbitalViewMode
/// Mode d'affichage de l'orbital: connexions vérifiées ou invitations en attente
enum OrbitalViewMode: String, CaseIterable {
    case verified = "verified"
    case pending = "pending"

    /// Icône SF Symbol
    var icon: String {
        switch self {
        case .verified: return "checkmark.seal.fill"
        case .pending: return "paperplane.fill"
        }
    }

    /// Couleur du mode
    var color: Color {
        switch self {
        case .verified: return Color(red: 0.0, green: 0.78, blue: 0.51)  // Mint/Vert
        case .pending: return Color(red: 0.6, green: 0.6, blue: 0.65)     // Gris élégant
        }
    }

    /// Gradient pour l'état actif
    var activeGradient: LinearGradient {
        switch self {
        case .verified:
            return LinearGradient(
                colors: [
                    Color(red: 0.0, green: 0.78, blue: 0.51),  // Mint
                    Color(red: 0.0, green: 0.55, blue: 0.85)   // Bleu
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .pending:
            return LinearGradient(
                colors: [
                    Color(red: 0.5, green: 0.5, blue: 0.55),
                    Color(red: 0.65, green: 0.65, blue: 0.7)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    /// Label court
    var shortLabel: String {
        switch self {
        case .verified: return "Vérifiés"
        case .pending: return "Invités"
        }
    }
}
