import SwiftUI

// MARK: - ClosenessLevel
/// Niveau de proximité relationnelle (1-5)
enum ClosenessLevel: Int, Codable, CaseIterable, Identifiable, Hashable {
    case distant = 1      // Connaissance lointaine
    case casual = 2       // Contact occasionnel
    case moderate = 3     // Relation régulière
    case close = 4        // Relation proche
    case intimate = 5     // Relation très proche

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .distant: return "Distant"
        case .casual: return "Occasionnel"
        case .moderate: return "Régulier"
        case .close: return "Proche"
        case .intimate: return "Très proche"
        }
    }

    var emoji: String {
        switch self {
        case .distant: return "👋"
        case .casual: return "🤝"
        case .moderate: return "😊"
        case .close: return "🤗"
        case .intimate: return "💜"
        }
    }

    var color: Color {
        switch self {
        case .distant: return .gray
        case .casual: return .blue.opacity(0.6)
        case .moderate: return .blue
        case .close: return .purple
        case .intimate: return .pink
        }
    }

    /// Description détaillée pour l'aide utilisateur
    var description: String {
        switch self {
        case .distant: return "Vous vous connaissez de loin, peu d'échanges"
        case .casual: return "Contacts occasionnels, échanges polis"
        case .moderate: return "Relation régulière, échanges fréquents"
        case .close: return "Relation proche, confiance mutuelle"
        case .intimate: return "Relation très proche, confidence et soutien"
        }
    }
}

// MARK: - Preview Helpers
extension ClosenessLevel {
    static let preview: ClosenessLevel = .moderate
}
