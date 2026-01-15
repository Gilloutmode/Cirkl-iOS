import SwiftUI

// MARK: - Modele de Connexion Orbitale
/// Represente un contact dans l'interface orbitale avec positionnement et metadonnees
struct OrbitalContact: Identifiable, Hashable {
    let id: String
    var name: String
    var photoName: String?
    var xPercent: CGFloat
    var yPercent: CGFloat
    var avatarColor: Color  // Couleur du cercle avatar
    var trustLevel: TrustLevel  // Niveau de confiance (invited, verified, etc.)

    // Metadonnees pour recherche multi-criteres
    var role: String?
    var company: String?
    var industry: String?
    var meetingPlace: String?
    var meetingDate: Date?
    var connectionType: ConnectionType
    var relationshipType: RelationshipType?  // Type de relation hierarchique (legacy)
    var relationshipProfile: RelationshipProfile?  // Profil relationnel multi-dimensionnel
    var selfiePhotoData: Data?
    var contactPhotoData: Data?  // Photo du contact (pour les invites)
    var notes: String?
    var tags: [String] = []
    var invitedAt: Date?  // Date d'invitation (pour les invites)

    // MARK: - Computed Properties for Relationship

    /// Retourne le profil relationnel, migre depuis le type legacy si necessaire
    var effectiveRelationshipProfile: RelationshipProfile {
        if let profile = relationshipProfile {
            return profile
        }
        if let legacyType = relationshipType {
            return RelationshipProfile.from(legacy: legacyType)
        }
        return RelationshipProfile()
    }

    /// Indique si le contact a une relation definie (profile ou legacy)
    var hasRelationship: Bool {
        relationshipProfile != nil || relationshipType != nil
    }

    // MARK: - Computed Properties for Dates

    /// Indique si la date de rencontre est requise (non pour la famille)
    var needsMeetingDate: Bool {
        // Si on a un profil multi-dimensionnel avec la sphere famille
        if let profile = relationshipProfile, profile.spheres.contains(.family) {
            return false
        }
        // Sinon, verifier le type legacy
        guard let relationship = relationshipType else { return true }
        return !relationship.impliesLifelongRelation
    }

    /// Date de rencontre a afficher (ou "Depuis toujours" pour la famille)
    var meetingDateDisplay: String {
        // Verifier d'abord le profil multi-dimensionnel
        if let profile = relationshipProfile, profile.spheres.contains(.family) {
            return "Depuis toujours"
        }
        // Sinon, verifier le type legacy
        if let relationship = relationshipType, relationship.impliesLifelongRelation {
            return "Depuis toujours"
        }
        if let date = meetingDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            formatter.locale = Locale(identifier: "fr_FR")
            return formatter.string(from: date)
        }
        return "Non specifiee"
    }

    // MARK: - Hashable Conformance

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: OrbitalContact, rhs: OrbitalContact) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Neo4j Conversion

    /// Creer depuis un Neo4jConnection
    static func from(_ neo4j: Neo4jConnection, xPercent: CGFloat = 0.5, yPercent: CGFloat = 0.5, avatarColor: Color = .blue, photoName: String? = nil, trustLevel: TrustLevel = .verified) -> OrbitalContact {
        var selfieData: Data?
        if let base64 = neo4j.selfiePhotoBase64 {
            selfieData = Data(base64Encoded: base64)
        }

        return OrbitalContact(
            id: neo4j.id,
            name: neo4j.name,
            photoName: photoName,
            xPercent: xPercent,
            yPercent: yPercent,
            avatarColor: avatarColor,
            trustLevel: trustLevel,
            role: neo4j.role,
            company: neo4j.company,
            industry: neo4j.industry,
            meetingPlace: neo4j.meetingPlace,
            meetingDate: neo4j.meetingDate,
            connectionType: neo4j.connectionType,
            relationshipType: neo4j.relationshipType,
            relationshipProfile: neo4j.relationshipProfile,
            selfiePhotoData: selfieData,
            contactPhotoData: nil,
            notes: neo4j.notes,
            tags: neo4j.tags
        )
    }

    /// Convertir en Neo4jConnection
    func toNeo4jConnection() -> Neo4jConnection {
        var base64Photo: String?
        if let data = selfiePhotoData {
            base64Photo = data.base64EncodedString()
        }

        return Neo4jConnection(
            id: id,
            name: name,
            role: role,
            company: company,
            industry: industry,
            meetingPlace: meetingPlace,
            meetingDate: meetingDate,
            connectionType: connectionType,
            selfiePhotoBase64: base64Photo,
            relationshipType: relationshipType,
            relationshipProfile: relationshipProfile,
            notes: notes,
            tags: tags
        )
    }

    // MARK: - Search

    /// Verifie si le contact correspond a une requete de recherche
    func matches(query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let lowerQuery = query.lowercased()

        if name.lowercased().contains(lowerQuery) { return true }
        if let role = role, role.lowercased().contains(lowerQuery) { return true }
        if let company = company, company.lowercased().contains(lowerQuery) { return true }
        if let meetingPlace = meetingPlace, meetingPlace.lowercased().contains(lowerQuery) { return true }
        if tags.contains(where: { $0.lowercased().contains(lowerQuery) }) { return true }

        return false
    }

    // MARK: - Mock Data

    /// Disposition COMPACTE orbitale autour du centre (0.5, 0.42)
    static let all: [OrbitalContact] = [
        OrbitalContact(id: "denis", name: "Denis", photoName: "photo_denis", xPercent: 0.28, yPercent: 0.18,
                      avatarColor: Color(red: 0.85, green: 0.65, blue: 0.45), trustLevel: .verified,
                      role: "Designer", company: "Studio Creatif", meetingPlace: "Meetup Design",
                      connectionType: .evenement, tags: ["design", "creatif"]),
        OrbitalContact(id: "shay", name: "Shay", photoName: "photo_shay", xPercent: 0.72, yPercent: 0.18,
                      avatarColor: Color(red: 0.55, green: 0.75, blue: 0.85), trustLevel: .verified,
                      role: "Developer", company: "Tech Corp", meetingPlace: "Conference Swift",
                      connectionType: .professionnel, tags: ["tech", "iOS"]),
        OrbitalContact(id: "salome", name: "Salome", photoName: "photo_salome", xPercent: 0.18, yPercent: 0.42,
                      avatarColor: Color(red: 0.75, green: 0.55, blue: 0.70), trustLevel: .verified,
                      role: "Marketing", company: "Brand Agency", meetingPlace: "Networking Event",
                      connectionType: .networking, tags: ["marketing", "strategie"]),
        OrbitalContact(id: "dan", name: "Dan", photoName: "photo_dan", xPercent: 0.82, yPercent: 0.42,
                      avatarColor: Color(red: 0.50, green: 0.70, blue: 0.60), trustLevel: .verified,
                      role: "Entrepreneur", company: "StartupX", meetingPlace: "Station F",
                      connectionType: .professionnel, tags: ["startup", "business"]),
        OrbitalContact(id: "gilles", name: "Gilles", photoName: "photo_gilles", xPercent: 0.30, yPercent: 0.66,
                      avatarColor: Color(red: 0.65, green: 0.60, blue: 0.75), trustLevel: .verified,
                      role: "Consultant", company: "Advisory Co", meetingPlace: "Linkedin",
                      connectionType: .networking, tags: ["conseil", "strategie"]),
        OrbitalContact(id: "judith", name: "Judith", photoName: "photo_judith", xPercent: 0.70, yPercent: 0.66,
                      avatarColor: Color(red: 0.80, green: 0.55, blue: 0.55), trustLevel: .verified,
                      role: "Product Manager", company: "BigTech", meetingPlace: "Product School",
                      connectionType: .evenement, tags: ["product", "management"])
    ]
}
