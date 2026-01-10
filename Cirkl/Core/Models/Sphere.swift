import SwiftUI

// MARK: - Sphere
/// Sphère de vie où existe la relation
/// Une personne peut appartenir à PLUSIEURS sphères simultanément
enum Sphere: String, Codable, CaseIterable, Identifiable, Hashable {
    case professional = "professional"
    case personal = "personal"
    case community = "community"      // Associations, clubs
    case family = "family"
    case creative = "creative"        // Projets artistiques, hobbies

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .professional: return "Professionnel"
        case .personal: return "Personnel"
        case .community: return "Communautaire"
        case .family: return "Famille"
        case .creative: return "Créatif"
        }
    }

    var icon: String {
        switch self {
        case .professional: return "briefcase.fill"
        case .personal: return "heart.fill"
        case .community: return "person.3.fill"
        case .family: return "house.fill"
        case .creative: return "paintbrush.fill"
        }
    }

    var color: Color {
        switch self {
        case .professional: return .blue
        case .personal: return .pink
        case .community: return .orange
        case .family: return .purple
        case .creative: return .mint
        }
    }

    /// Description courte pour affichage compact
    var shortDescription: String {
        switch self {
        case .professional: return "Pro"
        case .personal: return "Perso"
        case .community: return "Commu"
        case .family: return "Famille"
        case .creative: return "Créa"
        }
    }
}

// MARK: - Preview Helpers
extension Sphere {
    static let previewMultiple: Set<Sphere> = [.professional, .personal]
}
