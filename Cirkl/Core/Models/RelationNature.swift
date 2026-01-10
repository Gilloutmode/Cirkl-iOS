import SwiftUI

// MARK: - RelationNature
/// Nature spécifique de la relation
/// Une personne peut avoir PLUSIEURS natures de relation simultanément
/// Ex: Un mentor peut aussi être un ami proche
enum RelationNature: String, Codable, CaseIterable, Identifiable, Hashable {
    // Professional
    case colleague = "colleague"
    case client = "client"
    case partner = "partner"
    case mentor = "mentor"
    case mentee = "mentee"
    case investor = "investor"
    case supplier = "supplier"
    case manager = "manager"
    case cofounder = "cofounder"

    // Personal
    case friend = "friend"
    case closeFriend = "close_friend"
    case bestFriend = "best_friend"
    case acquaintance = "acquaintance"
    case neighbor = "neighbor"
    case childhoodFriend = "childhood_friend"

    // Family
    case spouse = "spouse"
    case parent = "parent"
    case sibling = "sibling"
    case child = "child"
    case extendedFamily = "extended_family"
    case inLaw = "in_law"

    // Community
    case clubMember = "club_member"
    case associationMember = "association_member"
    case sportTeammate = "sport_teammate"
    case volunteerPartner = "volunteer_partner"

    // Creative
    case collaborator = "collaborator"
    case artisticPartner = "artistic_partner"
    case bandmate = "bandmate"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        // Professional
        case .colleague: return "Collègue"
        case .client: return "Client"
        case .partner: return "Partenaire"
        case .mentor: return "Mentor"
        case .mentee: return "Mentoré"
        case .investor: return "Investisseur"
        case .supplier: return "Fournisseur"
        case .manager: return "Manager"
        case .cofounder: return "Co-fondateur"

        // Personal
        case .friend: return "Ami"
        case .closeFriend: return "Ami proche"
        case .bestFriend: return "Meilleur ami"
        case .acquaintance: return "Connaissance"
        case .neighbor: return "Voisin"
        case .childhoodFriend: return "Ami d'enfance"

        // Family
        case .spouse: return "Conjoint"
        case .parent: return "Parent"
        case .sibling: return "Frère/Sœur"
        case .child: return "Enfant"
        case .extendedFamily: return "Famille élargie"
        case .inLaw: return "Belle-famille"

        // Community
        case .clubMember: return "Membre de club"
        case .associationMember: return "Membre d'association"
        case .sportTeammate: return "Coéquipier sportif"
        case .volunteerPartner: return "Partenaire bénévole"

        // Creative
        case .collaborator: return "Collaborateur"
        case .artisticPartner: return "Partenaire artistique"
        case .bandmate: return "Membre du groupe"
        }
    }

    var icon: String {
        switch self {
        // Professional
        case .colleague: return "person.2"
        case .client: return "person.crop.circle.badge.checkmark"
        case .partner: return "handshake"
        case .mentor: return "graduationcap"
        case .mentee: return "person.crop.circle.badge.plus"
        case .investor: return "chart.line.uptrend.xyaxis"
        case .supplier: return "shippingbox"
        case .manager: return "person.badge.shield.checkmark"
        case .cofounder: return "person.3.sequence"

        // Personal
        case .friend: return "face.smiling"
        case .closeFriend: return "heart"
        case .bestFriend: return "heart.fill"
        case .acquaintance: return "person.wave.2"
        case .neighbor: return "house.and.flag"
        case .childhoodFriend: return "figure.2.and.child.holdinghands"

        // Family
        case .spouse: return "heart.circle"
        case .parent: return "figure.and.child.holdinghands"
        case .sibling: return "person.2.wave.2"
        case .child: return "figure.child"
        case .extendedFamily: return "person.3"
        case .inLaw: return "person.crop.rectangle.stack"

        // Community
        case .clubMember: return "person.3.fill"
        case .associationMember: return "building.2"
        case .sportTeammate: return "sportscourt"
        case .volunteerPartner: return "hands.sparkles"

        // Creative
        case .collaborator: return "lightbulb"
        case .artisticPartner: return "paintpalette"
        case .bandmate: return "music.mic"
        }
    }

    /// Sphères compatibles avec cette nature
    var compatibleSpheres: Set<Sphere> {
        switch self {
        case .colleague, .client, .partner, .mentor, .mentee, .investor, .supplier, .manager, .cofounder:
            return [.professional]
        case .friend, .closeFriend, .bestFriend, .acquaintance, .neighbor, .childhoodFriend:
            return [.personal]
        case .spouse, .parent, .sibling, .child, .extendedFamily, .inLaw:
            return [.family]
        case .clubMember, .associationMember, .sportTeammate, .volunteerPartner:
            return [.community]
        case .collaborator, .artisticPartner, .bandmate:
            return [.creative]
        }
    }

    /// Groupement pour l'affichage dans le picker
    var group: Sphere {
        compatibleSpheres.first ?? .personal
    }

    /// Natures groupées par sphère compatible
    static func natures(for sphere: Sphere) -> [RelationNature] {
        allCases.filter { $0.compatibleSpheres.contains(sphere) }
    }

    /// Natures groupées par plusieurs sphères (union)
    static func natures(for spheres: Set<Sphere>) -> [RelationNature] {
        guard !spheres.isEmpty else { return allCases }
        return allCases.filter { nature in
            !nature.compatibleSpheres.isDisjoint(with: spheres)
        }
    }
}

// MARK: - Preview Helpers
extension RelationNature {
    static let previewMultiple: Set<RelationNature> = [.mentor, .friend]
}
