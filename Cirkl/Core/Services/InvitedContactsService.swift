import SwiftUI

// MARK: - InvitedContact Model
/// Represents an invited contact awaiting confirmation, with enriched data
struct InvitedContact: Codable, Identifiable {

    // MARK: - Core Properties
    let id: String
    var name: String
    var phoneNumber: String?
    var emails: [String]

    // MARK: - Dates
    let invitedAt: Date
    var meetingDate: Date?  // Date de la rencontre physique (optionnel)

    // MARK: - Appearance
    let avatarColor: CodableColor
    let photoData: Data?

    // MARK: - Relationship
    var relationshipType: RelationshipType?
    var relationshipProfile: RelationshipProfile?

    // MARK: - Imported iOS Relation (original label from iOS)
    var iOSRelationLabel: String?

    // MARK: - Professional Info
    var organizationName: String?
    var jobTitle: String?

    // MARK: - Personal Info
    var birthday: CodableDateComponents?
    var note: String?

    // MARK: - Social Profiles
    var socialProfiles: [CodableSocialProfile]

    // MARK: - Postal Addresses
    var postalAddresses: [CodablePostalAddress]

    // MARK: - Computed Properties

    /// Couleur du cercle avatar
    var color: Color {
        avatarColor.color
    }

    /// Image du contact si disponible
    var photo: UIImage? {
        guard let data = photoData else { return nil }
        return UIImage(data: data)
    }

    /// Initiales pour l'avatar
    var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map { String($0).uppercased() } ?? ""
        let last = parts.count > 1 ? (parts.last?.first.map { String($0).uppercased() } ?? "") : ""
        let result = "\(first)\(last)"
        return result.isEmpty ? "?" : result
    }

    /// Date d'anniversaire formatée
    var birthdayDate: Date? {
        guard let birthday = birthday else { return nil }
        return Calendar.current.date(from: birthday.dateComponents)
    }

    var birthdayDisplayString: String? {
        guard let date = birthdayDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }

    /// Info professionnelle formatée
    var professionalInfo: String? {
        var parts: [String] = []
        if let title = jobTitle, !title.isEmpty { parts.append(title) }
        if let org = organizationName, !org.isEmpty { parts.append(org) }
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }

    /// Indique si la date de rencontre est requise (non pour la famille)
    var needsMeetingDate: Bool {
        guard let relationship = relationshipType else { return true }
        return !relationship.impliesLifelongRelation
    }

    /// Date de rencontre à afficher (ou "Depuis toujours" pour la famille)
    var meetingDateDisplay: String {
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
        return "Non spécifiée"
    }

    // MARK: - Default Initializer
    init(
        id: String = UUID().uuidString,
        name: String,
        phoneNumber: String? = nil,
        emails: [String] = [],
        invitedAt: Date = Date(),
        meetingDate: Date? = nil,
        avatarColor: CodableColor,
        photoData: Data? = nil,
        relationshipType: RelationshipType? = nil,
        relationshipProfile: RelationshipProfile? = nil,
        iOSRelationLabel: String? = nil,
        organizationName: String? = nil,
        jobTitle: String? = nil,
        birthday: CodableDateComponents? = nil,
        note: String? = nil,
        socialProfiles: [CodableSocialProfile] = [],
        postalAddresses: [CodablePostalAddress] = []
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.emails = emails
        self.invitedAt = invitedAt
        self.meetingDate = meetingDate
        self.avatarColor = avatarColor
        self.photoData = photoData
        self.relationshipType = relationshipType
        self.relationshipProfile = relationshipProfile
        self.iOSRelationLabel = iOSRelationLabel
        self.organizationName = organizationName
        self.jobTitle = jobTitle
        self.birthday = birthday
        self.note = note
        self.socialProfiles = socialProfiles
        self.postalAddresses = postalAddresses
    }

    // MARK: - Effective Relationship Profile
    /// Retourne le profil relationnel, migré depuis le type legacy si nécessaire
    var effectiveRelationshipProfile: RelationshipProfile {
        if let profile = relationshipProfile {
            return profile
        }
        if let legacyType = relationshipType {
            return RelationshipProfile.from(legacy: legacyType)
        }
        return RelationshipProfile()
    }

    /// Indique si le contact a une relation définie (profile ou legacy)
    var hasRelationship: Bool {
        relationshipProfile != nil || relationshipType != nil
    }
}

// MARK: - CodableColor
/// Wrapper pour stocker Color dans UserDefaults
struct CodableColor: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double

    init(color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.opacity = Double(a)
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

// MARK: - CodableDateComponents
/// Wrapper pour stocker DateComponents dans UserDefaults
struct CodableDateComponents: Codable {
    let year: Int?
    let month: Int?
    let day: Int?

    init(from dateComponents: DateComponents) {
        self.year = dateComponents.year
        self.month = dateComponents.month
        self.day = dateComponents.day
    }

    var dateComponents: DateComponents {
        DateComponents(year: year, month: month, day: day)
    }
}

// MARK: - CodableSocialProfile
/// Profil social codable pour stockage
struct CodableSocialProfile: Codable, Hashable {
    let service: String
    let username: String
    let urlString: String
}

// MARK: - CodablePostalAddress
/// Adresse postale codable pour stockage
struct CodablePostalAddress: Codable, Hashable {
    let label: String
    let street: String
    let city: String
    let state: String
    let postalCode: String
    let country: String

    var formattedAddress: String {
        var parts: [String] = []
        if !street.isEmpty { parts.append(street) }
        if !postalCode.isEmpty || !city.isEmpty {
            parts.append("\(postalCode) \(city)".trimmingCharacters(in: .whitespaces))
        }
        if !country.isEmpty { parts.append(country) }
        return parts.joined(separator: "\n")
    }
}

// MARK: - InvitedContactsService
/// Service pour gérer les contacts invités en attente de confirmation
@Observable
@MainActor
final class InvitedContactsService {

    // MARK: - Singleton
    static let shared = InvitedContactsService()

    // MARK: - Properties
    private(set) var invitedContacts: [InvitedContact] = []

    private let userDefaultsKey = "cirkl.invited.contacts.v2"  // New key for enriched model

    // MARK: - Init
    private init() {
        loadFromStorage()
    }

    // MARK: - Public Methods

    /// Ajoute un contact invité avec toutes les données enrichies
    func addInvitedContact(
        id: String = UUID().uuidString,
        name: String,
        phoneNumber: String?,
        emails: [String] = [],
        avatarColor: Color = .gray,
        photoData: Data? = nil,
        relationshipType: RelationshipType? = nil,
        relationshipProfile: RelationshipProfile? = nil,
        iOSRelationLabel: String? = nil,
        organizationName: String? = nil,
        jobTitle: String? = nil,
        birthday: DateComponents? = nil,
        note: String? = nil,
        socialProfiles: [CodableSocialProfile] = [],
        postalAddresses: [CodablePostalAddress] = []
    ) {
        let contact = InvitedContact(
            id: id,
            name: name,
            phoneNumber: phoneNumber,
            emails: emails,
            invitedAt: Date(),
            meetingDate: nil,
            avatarColor: CodableColor(color: avatarColor),
            photoData: photoData,
            relationshipType: relationshipType,
            relationshipProfile: relationshipProfile,
            iOSRelationLabel: iOSRelationLabel,
            organizationName: organizationName,
            jobTitle: jobTitle,
            birthday: birthday.map { CodableDateComponents(from: $0) },
            note: note,
            socialProfiles: socialProfiles,
            postalAddresses: postalAddresses
        )

        // Éviter les doublons (par nom ou numéro)
        guard !invitedContacts.contains(where: {
            $0.name.lowercased() == name.lowercased() ||
            ($0.phoneNumber != nil && $0.phoneNumber == phoneNumber)
        }) else {
            print("⚠️ Contact déjà invité: \(name)")
            return
        }

        invitedContacts.append(contact)
        saveToStorage()

        print("✅ Contact invité ajouté: \(name)")
    }

    /// Met à jour un contact invité existant
    func updateContact(_ updatedContact: InvitedContact) {
        guard let index = invitedContacts.firstIndex(where: { $0.id == updatedContact.id }) else {
            print("⚠️ Contact non trouvé pour mise à jour: \(updatedContact.id)")
            return
        }

        invitedContacts[index] = updatedContact
        saveToStorage()
        print("✅ Contact mis à jour: \(updatedContact.name)")
    }

    /// Met à jour le type de relation d'un contact (legacy)
    func updateRelationship(for contactId: String, relationship: RelationshipType?) {
        guard let index = invitedContacts.firstIndex(where: { $0.id == contactId }) else { return }
        invitedContacts[index].relationshipType = relationship
        saveToStorage()
    }

    /// Met à jour le profil relationnel multi-dimensionnel d'un contact
    func updateRelationshipProfile(for contactId: String, profile: RelationshipProfile?) {
        guard let index = invitedContacts.firstIndex(where: { $0.id == contactId }) else { return }
        invitedContacts[index].relationshipProfile = profile
        saveToStorage()
        print("✅ Profil relationnel mis à jour pour: \(invitedContacts[index].name)")
    }

    /// Met à jour la date de rencontre d'un contact
    func updateMeetingDate(for contactId: String, date: Date?) {
        guard let index = invitedContacts.firstIndex(where: { $0.id == contactId }) else { return }
        invitedContacts[index].meetingDate = date
        saveToStorage()
    }

    /// Retire un contact invité (quand il confirme ou annule)
    func removeInvitedContact(id: String) {
        invitedContacts.removeAll { $0.id == id }
        saveToStorage()
    }

    /// Retire un contact invité par nom
    func removeInvitedContact(name: String) {
        invitedContacts.removeAll { $0.name.lowercased() == name.lowercased() }
        saveToStorage()
    }

    /// Récupère un contact par ID
    func contact(withId id: String) -> InvitedContact? {
        invitedContacts.first { $0.id == id }
    }

    /// Vérifie si un contact est déjà invité
    func isInvited(name: String) -> Bool {
        invitedContacts.contains { $0.name.lowercased() == name.lowercased() }
    }

    /// Nombre de contacts invités
    var count: Int {
        invitedContacts.count
    }

    // MARK: - Persistence

    private func loadFromStorage() {
        // Try new key first
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            do {
                invitedContacts = try JSONDecoder().decode([InvitedContact].self, from: data)
                print("📂 Chargé \(invitedContacts.count) contacts invités (v2)")
                return
            } catch {
                print("❌ Erreur chargement contacts invités v2: \(error)")
            }
        }

        // Migration from old key
        if let oldData = UserDefaults.standard.data(forKey: "cirkl.invited.contacts") {
            migrateFromOldFormat(oldData)
        }
    }

    private func migrateFromOldFormat(_ data: Data) {
        // Try to decode old format and migrate
        struct OldInvitedContact: Codable {
            let id: String
            let name: String
            let phoneNumber: String?
            let invitedAt: Date
            let avatarColor: CodableColor
            let photoData: Data?
        }

        do {
            let oldContacts = try JSONDecoder().decode([OldInvitedContact].self, from: data)
            invitedContacts = oldContacts.map { old in
                InvitedContact(
                    id: old.id,
                    name: old.name,
                    phoneNumber: old.phoneNumber,
                    emails: [],
                    invitedAt: old.invitedAt,
                    meetingDate: nil,
                    avatarColor: old.avatarColor,
                    photoData: old.photoData,
                    relationshipType: nil,
                    iOSRelationLabel: nil,
                    organizationName: nil,
                    jobTitle: nil,
                    birthday: nil,
                    note: nil,
                    socialProfiles: [],
                    postalAddresses: []
                )
            }
            saveToStorage()
            // Remove old key after migration
            UserDefaults.standard.removeObject(forKey: "cirkl.invited.contacts")
            print("✅ Migration de \(invitedContacts.count) contacts vers v2")
        } catch {
            print("❌ Erreur migration anciens contacts: \(error)")
        }
    }

    private func saveToStorage() {
        do {
            let data = try JSONEncoder().encode(invitedContacts)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            print("💾 Sauvegardé \(invitedContacts.count) contacts invités")
        } catch {
            print("❌ Erreur sauvegarde contacts invités: \(error)")
        }
    }

    /// Efface tous les contacts invités (pour debug/reset)
    func clearAll() {
        invitedContacts.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: "cirkl.invited.contacts")
    }
}
