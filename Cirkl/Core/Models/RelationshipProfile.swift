import Foundation

// MARK: - RelationshipProfile
/// Profil relationnel multi-dimensionnel
/// Permet de capturer la complexité des relations humaines:
/// - Une personne peut exister dans plusieurs sphères (pro + perso)
/// - Une personne peut avoir plusieurs natures de relation (mentor + ami)
/// - Tout en ayant un niveau de proximité global
struct RelationshipProfile: Codable, Equatable, Hashable {
    var spheres: Set<Sphere>
    var natures: Set<RelationNature>
    var closeness: ClosenessLevel
    var interactionFrequency: InteractionFrequency?
    var meetingContext: String?
    var sharedInterests: [String]
    var sharedCircles: [String]

    // MARK: - Computed Properties

    /// Indique si la relation est multi-dimensionnelle (plusieurs sphères)
    var isMultiDimensional: Bool {
        spheres.count > 1
    }

    /// Sphère principale (première dans l'ordre d'importance)
    var primarySphere: Sphere? {
        // Priorité: family > professional > personal > community > creative
        let priority: [Sphere] = [.family, .professional, .personal, .community, .creative]
        return priority.first { spheres.contains($0) }
    }

    /// Nature principale (première dans l'ordre d'importance)
    var primaryNature: RelationNature? {
        natures.first
    }

    /// Indique si le profil est vide (non configuré)
    var isEmpty: Bool {
        spheres.isEmpty && natures.isEmpty
    }

    /// Résumé textuel du profil
    var summary: String {
        guard !isEmpty else { return "Non défini" }

        var parts: [String] = []

        if !spheres.isEmpty {
            let sphereNames = spheres.map { $0.shortDescription }.joined(separator: " + ")
            parts.append(sphereNames)
        }

        if !natures.isEmpty {
            let natureNames = natures.prefix(2).map { $0.displayName }.joined(separator: ", ")
            parts.append(natureNames)
        }

        parts.append("\(closeness.emoji) \(closeness.displayName)")

        return parts.joined(separator: " • ")
    }

    // MARK: - Init

    init(
        spheres: Set<Sphere> = [],
        natures: Set<RelationNature> = [],
        closeness: ClosenessLevel = .moderate,
        interactionFrequency: InteractionFrequency? = nil,
        meetingContext: String? = nil,
        sharedInterests: [String] = [],
        sharedCircles: [String] = []
    ) {
        self.spheres = spheres
        self.natures = natures
        self.closeness = closeness
        self.interactionFrequency = interactionFrequency
        self.meetingContext = meetingContext
        self.sharedInterests = sharedInterests
        self.sharedCircles = sharedCircles
    }

    // MARK: - Migration from Legacy RelationshipType

    /// Convertit un RelationshipType legacy vers RelationshipProfile
    static func from(legacy: RelationshipType) -> RelationshipProfile {
        var profile = RelationshipProfile()

        // Mapping catégorie → sphère
        switch legacy.category {
        case .family:
            profile.spheres = [.family]
            profile.closeness = .close
        case .innerCircle:
            profile.spheres = [.personal]
            profile.closeness = .intimate
        case .professional:
            profile.spheres = [.professional]
            profile.closeness = .moderate
        case .network:
            profile.spheres = [.personal]
            profile.closeness = .casual
        case .education:
            profile.spheres = [.professional, .personal]
            profile.closeness = .moderate
        }

        // Mapping sous-type → nature
        if let subtype = legacy.subtype {
            profile.natures = mapSubtypeToNatures(subtype)
        }

        return profile
    }

    /// Mapping des sous-types legacy vers les nouvelles natures
    private static func mapSubtypeToNatures(_ subtype: RelationshipSubtype) -> Set<RelationNature> {
        switch subtype {
        // Family
        case .brother, .sister:
            return [.sibling]
        case .father, .mother:
            return [.parent]
        case .son, .daughter:
            return [.child]
        case .grandfather, .grandmother, .uncle, .aunt, .cousin, .nephew, .niece:
            return [.extendedFamily]
        case .spouse, .partner:
            return [.spouse]
        case .inLaw:
            return [.inLaw]
        case .otherFamily:
            return [.extendedFamily]

        // Inner Circle
        case .bestFriend:
            return [.bestFriend]
        case .closeFriend:
            return [.closeFriend]
        case .childhoodFriend:
            return [.childhoodFriend]
        case .confidant:
            return [.closeFriend]
        case .otherClose:
            return [.friend]

        // Professional
        case .colleague:
            return [.colleague]
        case .manager:
            return [.manager]
        case .employee:
            return [.colleague]
        case .businessPartner:
            return [.partner]
        case .client:
            return [.client]
        case .supplier:
            return [.supplier]
        case .mentor:
            return [.mentor]
        case .mentee:
            return [.mentee]
        case .investor:
            return [.investor]
        case .cofounder:
            return [.cofounder]
        case .otherPro:
            return [.colleague]

        // Network
        case .acquaintance, .networkingContact, .eventMet, .onlineMet, .referral:
            return [.acquaintance]
        case .neighbor:
            return [.neighbor]
        case .otherNetwork:
            return [.acquaintance]

        // Education
        case .classmate, .schoolFriend, .studyGroup, .alumnus:
            return [.friend]
        case .professor:
            return [.mentor]
        case .student:
            return [.mentee]
        case .otherEducation:
            return [.acquaintance]
        }
    }
}

// MARK: - InteractionFrequency
/// Fréquence d'interaction avec le contact
enum InteractionFrequency: String, Codable, CaseIterable, Identifiable, Hashable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    case rarely = "rarely"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Quotidien"
        case .weekly: return "Hebdomadaire"
        case .monthly: return "Mensuel"
        case .quarterly: return "Trimestriel"
        case .yearly: return "Annuel"
        case .rarely: return "Rarement"
        }
    }

    var icon: String {
        switch self {
        case .daily: return "sun.max"
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .quarterly: return "calendar.badge.minus"
        case .yearly: return "gift"
        case .rarely: return "moon.zzz"
        }
    }
}

// MARK: - Preview Helpers
extension RelationshipProfile {
    /// Profil de prévisualisation multi-dimensionnel
    static let previewMultiDimensional = RelationshipProfile(
        spheres: [.professional, .personal],
        natures: [.mentor, .friend],
        closeness: .close,
        interactionFrequency: .weekly,
        meetingContext: "Conférence tech 2023",
        sharedInterests: ["Swift", "Entrepreneuriat"],
        sharedCircles: ["Tech Leaders Paris"]
    )

    /// Profil de prévisualisation simple
    static let previewSimple = RelationshipProfile(
        spheres: [.personal],
        natures: [.friend],
        closeness: .moderate
    )

    /// Profil vide
    static let empty = RelationshipProfile()
}
