import SwiftUI

// MARK: - RelationshipCategory
/// Catégorie principale de relation
enum RelationshipCategory: String, CaseIterable, Codable, Identifiable {
    case family = "family"
    case innerCircle = "inner_circle"
    case professional = "professional"
    case network = "network"
    case education = "education"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .family: return "Famille"
        case .innerCircle: return "Cercle proche"
        case .professional: return "Professionnel"
        case .network: return "Réseau"
        case .education: return "Éducation"
        }
    }

    var icon: String {
        switch self {
        case .family: return "house.fill"
        case .innerCircle: return "heart.fill"
        case .professional: return "briefcase.fill"
        case .network: return "person.2.fill"
        case .education: return "graduationcap.fill"
        }
    }

    var color: Color {
        switch self {
        case .family: return .pink
        case .innerCircle: return .red
        case .professional: return .blue
        case .network: return .orange
        case .education: return .purple
        }
    }

    /// Les sous-types disponibles pour cette catégorie
    var subtypes: [RelationshipSubtype] {
        switch self {
        case .family:
            return [.brother, .sister, .father, .mother, .son, .daughter,
                    .grandfather, .grandmother, .uncle, .aunt, .cousin,
                    .nephew, .niece, .spouse, .partner, .inLaw, .otherFamily]
        case .innerCircle:
            return [.bestFriend, .closeFriend, .childhoodFriend, .confidant, .otherClose]
        case .professional:
            return [.colleague, .manager, .employee, .businessPartner, .client,
                    .supplier, .mentor, .mentee, .investor, .cofounder, .otherPro]
        case .network:
            return [.acquaintance, .networkingContact, .eventMet, .onlineMet,
                    .referral, .neighbor, .otherNetwork]
        case .education:
            return [.classmate, .schoolFriend, .professor, .student, .alumnus,
                    .studyGroup, .otherEducation]
        }
    }

    /// Indique si cette catégorie implique une relation "depuis toujours" (pas besoin de date de rencontre)
    var impliesLifelongRelation: Bool {
        self == .family
    }
}

// MARK: - RelationshipSubtype
/// Sous-type spécifique de relation
enum RelationshipSubtype: String, CaseIterable, Codable, Identifiable {
    // Family
    case brother = "brother"
    case sister = "sister"
    case father = "father"
    case mother = "mother"
    case son = "son"
    case daughter = "daughter"
    case grandfather = "grandfather"
    case grandmother = "grandmother"
    case uncle = "uncle"
    case aunt = "aunt"
    case cousin = "cousin"
    case nephew = "nephew"
    case niece = "niece"
    case spouse = "spouse"
    case partner = "partner"
    case inLaw = "in_law"
    case otherFamily = "other_family"

    // Inner Circle
    case bestFriend = "best_friend"
    case closeFriend = "close_friend"
    case childhoodFriend = "childhood_friend"
    case confidant = "confidant"
    case otherClose = "other_close"

    // Professional
    case colleague = "colleague"
    case manager = "manager"
    case employee = "employee"
    case businessPartner = "business_partner"
    case client = "client"
    case supplier = "supplier"
    case mentor = "mentor"
    case mentee = "mentee"
    case investor = "investor"
    case cofounder = "cofounder"
    case otherPro = "other_pro"

    // Network
    case acquaintance = "acquaintance"
    case networkingContact = "networking_contact"
    case eventMet = "event_met"
    case onlineMet = "online_met"
    case referral = "referral"
    case neighbor = "neighbor"
    case otherNetwork = "other_network"

    // Education
    case classmate = "classmate"
    case schoolFriend = "school_friend"
    case professor = "professor"
    case student = "student"
    case alumnus = "alumnus"
    case studyGroup = "study_group"
    case otherEducation = "other_education"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        // Family
        case .brother: return "Frère"
        case .sister: return "Sœur"
        case .father: return "Père"
        case .mother: return "Mère"
        case .son: return "Fils"
        case .daughter: return "Fille"
        case .grandfather: return "Grand-père"
        case .grandmother: return "Grand-mère"
        case .uncle: return "Oncle"
        case .aunt: return "Tante"
        case .cousin: return "Cousin(e)"
        case .nephew: return "Neveu"
        case .niece: return "Nièce"
        case .spouse: return "Conjoint(e)"
        case .partner: return "Partenaire"
        case .inLaw: return "Belle-famille"
        case .otherFamily: return "Autre famille"

        // Inner Circle
        case .bestFriend: return "Meilleur(e) ami(e)"
        case .closeFriend: return "Ami(e) proche"
        case .childhoodFriend: return "Ami(e) d'enfance"
        case .confidant: return "Confident(e)"
        case .otherClose: return "Autre proche"

        // Professional
        case .colleague: return "Collègue"
        case .manager: return "Manager"
        case .employee: return "Employé(e)"
        case .businessPartner: return "Partenaire business"
        case .client: return "Client(e)"
        case .supplier: return "Fournisseur"
        case .mentor: return "Mentor"
        case .mentee: return "Mentoré(e)"
        case .investor: return "Investisseur"
        case .cofounder: return "Co-fondateur"
        case .otherPro: return "Autre pro"

        // Network
        case .acquaintance: return "Connaissance"
        case .networkingContact: return "Contact networking"
        case .eventMet: return "Rencontré en événement"
        case .onlineMet: return "Rencontré en ligne"
        case .referral: return "Recommandation"
        case .neighbor: return "Voisin(e)"
        case .otherNetwork: return "Autre réseau"

        // Education
        case .classmate: return "Camarade de classe"
        case .schoolFriend: return "Ami(e) d'école"
        case .professor: return "Professeur"
        case .student: return "Étudiant(e)"
        case .alumnus: return "Alumni"
        case .studyGroup: return "Groupe d'études"
        case .otherEducation: return "Autre éducation"
        }
    }

    /// Retourne la catégorie parente
    var category: RelationshipCategory {
        switch self {
        case .brother, .sister, .father, .mother, .son, .daughter,
             .grandfather, .grandmother, .uncle, .aunt, .cousin,
             .nephew, .niece, .spouse, .partner, .inLaw, .otherFamily:
            return .family
        case .bestFriend, .closeFriend, .childhoodFriend, .confidant, .otherClose:
            return .innerCircle
        case .colleague, .manager, .employee, .businessPartner, .client,
             .supplier, .mentor, .mentee, .investor, .cofounder, .otherPro:
            return .professional
        case .acquaintance, .networkingContact, .eventMet, .onlineMet,
             .referral, .neighbor, .otherNetwork:
            return .network
        case .classmate, .schoolFriend, .professor, .student,
             .alumnus, .studyGroup, .otherEducation:
            return .education
        }
    }
}

// MARK: - RelationshipType (Combined)
/// Type de relation complet (catégorie + sous-type optionnel)
struct RelationshipType: Codable, Hashable, Identifiable {
    let category: RelationshipCategory
    let subtype: RelationshipSubtype?

    var id: String {
        if let subtype = subtype {
            return "\(category.rawValue)_\(subtype.rawValue)"
        }
        return category.rawValue
    }

    var displayName: String {
        if let subtype = subtype {
            return subtype.displayName
        }
        return category.displayName
    }

    var fullDisplayName: String {
        if let subtype = subtype {
            return "\(category.displayName) • \(subtype.displayName)"
        }
        return category.displayName
    }

    var icon: String {
        category.icon
    }

    var color: Color {
        category.color
    }

    /// Indique si cette relation n'a pas besoin de date de rencontre
    var impliesLifelongRelation: Bool {
        category.impliesLifelongRelation
    }

    // MARK: - Convenience Initializers

    init(category: RelationshipCategory, subtype: RelationshipSubtype? = nil) {
        self.category = category
        self.subtype = subtype
    }

    init(subtype: RelationshipSubtype) {
        self.category = subtype.category
        self.subtype = subtype
    }

    // MARK: - iOS Contact Mapping

    /// Tente de mapper un label de relation iOS vers un RelationshipType
    static func fromIOSRelation(label: String) -> RelationshipType? {
        let normalizedLabel = label.lowercased()

        // Mappings directs des labels iOS
        let mappings: [String: RelationshipSubtype] = [
            "brother": .brother,
            "frère": .brother,
            "sister": .sister,
            "sœur": .sister,
            "soeur": .sister,
            "father": .father,
            "père": .father,
            "pere": .father,
            "mother": .mother,
            "mère": .mother,
            "mere": .mother,
            "son": .son,
            "fils": .son,
            "daughter": .daughter,
            "fille": .daughter,
            "spouse": .spouse,
            "conjoint": .spouse,
            "époux": .spouse,
            "épouse": .spouse,
            "partner": .partner,
            "partenaire": .partner,
            "friend": .closeFriend,
            "ami": .closeFriend,
            "amie": .closeFriend,
            "manager": .manager,
            "assistant": .colleague,
            "parent": .otherFamily,
            "child": .otherFamily,
            "enfant": .otherFamily
        ]

        if let subtype = mappings[normalizedLabel] {
            return RelationshipType(subtype: subtype)
        }

        // Détection par mots-clés
        if normalizedLabel.contains("grand") {
            if normalizedLabel.contains("père") || normalizedLabel.contains("father") {
                return RelationshipType(subtype: .grandfather)
            }
            if normalizedLabel.contains("mère") || normalizedLabel.contains("mother") {
                return RelationshipType(subtype: .grandmother)
            }
        }

        if normalizedLabel.contains("oncle") || normalizedLabel.contains("uncle") {
            return RelationshipType(subtype: .uncle)
        }

        if normalizedLabel.contains("tante") || normalizedLabel.contains("aunt") {
            return RelationshipType(subtype: .aunt)
        }

        if normalizedLabel.contains("cousin") {
            return RelationshipType(subtype: .cousin)
        }

        return nil
    }
}

// MARK: - Preview Helpers
extension RelationshipType {
    static let preview = RelationshipType(subtype: .brother)
    static let previewPro = RelationshipType(subtype: .colleague)
    static let previewFriend = RelationshipType(subtype: .closeFriend)
}
