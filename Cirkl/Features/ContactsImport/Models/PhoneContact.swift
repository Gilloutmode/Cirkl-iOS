import SwiftUI
import Contacts

// MARK: - PhoneContact
/// Modèle représentant un contact du téléphone avec toutes ses données enrichies
struct PhoneContact: Identifiable, Hashable {

    // MARK: - Core Properties
    let id: String  // CNContact.identifier
    let givenName: String
    let familyName: String
    let phoneNumbers: [String]
    let emails: [String]

    // MARK: - Photo Data (avec fallback)
    /// Photo thumbnail (petite taille, optimisée)
    let thumbnailImageData: Data?
    /// Photo haute résolution (fallback si pas de thumbnail)
    let fullImageData: Data?

    // MARK: - Professional Info
    let organizationName: String?
    let jobTitle: String?
    let departmentName: String?

    // MARK: - Personal Info
    let birthday: DateComponents?
    let note: String?

    // MARK: - iOS Relationships (famille définie dans le carnet)
    /// Relations définies dans iOS (ex: "brother", "mother", "spouse")
    let iOSRelations: [ContactRelation]

    // MARK: - Social Profiles
    let socialProfiles: [SocialProfile]

    // MARK: - Postal Addresses
    let postalAddresses: [PostalAddress]

    // MARK: - Computed Properties

    var fullName: String {
        let name = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "Sans nom" : name
    }

    var initials: String {
        let first = givenName.first.map { String($0).uppercased() } ?? ""
        let last = familyName.first.map { String($0).uppercased() } ?? ""
        let result = "\(first)\(last)"
        return result.isEmpty ? "?" : result
    }

    var primaryPhone: String? {
        phoneNumbers.first
    }

    var primaryEmail: String? {
        emails.first
    }

    var displayPhone: String {
        primaryPhone ?? "Pas de numéro"
    }

    /// Photo disponible (thumbnail ou full)
    var hasPhoto: Bool {
        thumbnailImageData != nil || fullImageData != nil
    }

    /// Données de la photo (thumbnail prioritaire, sinon full)
    var bestPhotoData: Data? {
        thumbnailImageData ?? fullImageData
    }

    /// Image du contact (thumbnail prioritaire, sinon full redimensionnée)
    var contactImage: UIImage? {
        if let data = thumbnailImageData {
            return UIImage(data: data)
        }
        if let data = fullImageData {
            // Redimensionner l'image haute résolution pour optimiser la mémoire
            return UIImage(data: data)?.resizedForThumbnail()
        }
        return nil
    }

    /// Date d'anniversaire formatée
    var birthdayDate: Date? {
        guard let birthday = birthday else { return nil }
        return Calendar.current.date(from: birthday)
    }

    var birthdayDisplayString: String? {
        guard let date = birthdayDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }

    /// Prochaine date d'anniversaire
    var nextBirthday: Date? {
        guard var birthday = birthday else { return nil }
        let calendar = Calendar.current
        let today = Date()
        let currentYear = calendar.component(.year, from: today)

        birthday.year = currentYear
        guard let thisYearBirthday = calendar.date(from: birthday) else { return nil }

        if thisYearBirthday < today {
            birthday.year = currentYear + 1
        }

        return calendar.date(from: birthday)
    }

    /// Relation iOS principale (si définie)
    var primaryiOSRelation: ContactRelation? {
        iOSRelations.first
    }

    /// Info professionnelle formatée
    var professionalInfo: String? {
        var parts: [String] = []
        if let title = jobTitle, !title.isEmpty { parts.append(title) }
        if let org = organizationName, !org.isEmpty { parts.append(org) }
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }

    // MARK: - Initializers

    init(
        id: String,
        givenName: String,
        familyName: String,
        phoneNumbers: [String],
        emails: [String],
        thumbnailImageData: Data?,
        fullImageData: Data? = nil,
        organizationName: String? = nil,
        jobTitle: String? = nil,
        departmentName: String? = nil,
        birthday: DateComponents? = nil,
        note: String? = nil,
        iOSRelations: [ContactRelation] = [],
        socialProfiles: [SocialProfile] = [],
        postalAddresses: [PostalAddress] = []
    ) {
        self.id = id
        self.givenName = givenName
        self.familyName = familyName
        self.phoneNumbers = phoneNumbers
        self.emails = emails
        self.thumbnailImageData = thumbnailImageData
        self.fullImageData = fullImageData
        self.organizationName = organizationName
        self.jobTitle = jobTitle
        self.departmentName = departmentName
        self.birthday = birthday
        self.note = note
        self.iOSRelations = iOSRelations
        self.socialProfiles = socialProfiles
        self.postalAddresses = postalAddresses
    }

    /// Créer depuis un CNContact
    init(from cnContact: CNContact) {
        self.id = cnContact.identifier
        self.givenName = cnContact.givenName
        self.familyName = cnContact.familyName

        // Extraire les numéros de téléphone
        self.phoneNumbers = cnContact.phoneNumbers.compactMap { labeledValue in
            let phoneNumber = labeledValue.value
            return phoneNumber.stringValue
        }

        // Extraire les emails
        self.emails = cnContact.emailAddresses.compactMap { labeledValue in
            return labeledValue.value as String
        }

        // Photo: thumbnail prioritaire, sinon imageData en fallback
        self.thumbnailImageData = cnContact.thumbnailImageData
        self.fullImageData = cnContact.imageDataAvailable ? cnContact.imageData : nil

        // Infos professionnelles
        self.organizationName = cnContact.organizationName.isEmpty ? nil : cnContact.organizationName
        self.jobTitle = cnContact.jobTitle.isEmpty ? nil : cnContact.jobTitle
        self.departmentName = cnContact.departmentName.isEmpty ? nil : cnContact.departmentName

        // Anniversaire
        self.birthday = cnContact.birthday

        // Note - requires special entitlement (com.apple.developer.contacts.notes)
        // so we can't access it without Apple approval
        self.note = nil

        // Relations iOS (famille, conjoint, etc.)
        self.iOSRelations = cnContact.contactRelations.compactMap { labeledValue in
            let relation = labeledValue.value
            let label = labeledValue.label ?? ""
            return ContactRelation(
                name: relation.name,
                label: CNLabeledValue<CNContactRelation>.localizedString(forLabel: label)
            )
        }

        // Profils sociaux
        self.socialProfiles = cnContact.socialProfiles.compactMap { labeledValue in
            let profile = labeledValue.value
            return SocialProfile(
                service: profile.service,
                username: profile.username,
                urlString: profile.urlString
            )
        }

        // Adresses postales
        self.postalAddresses = cnContact.postalAddresses.compactMap { labeledValue in
            let address = labeledValue.value
            let label = labeledValue.label ?? ""
            return PostalAddress(
                label: CNLabeledValue<CNPostalAddress>.localizedString(forLabel: label),
                street: address.street,
                city: address.city,
                state: address.state,
                postalCode: address.postalCode,
                country: address.country
            )
        }
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PhoneContact, rhs: PhoneContact) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - ContactRelation
/// Relation définie dans le carnet de contacts iOS
struct ContactRelation: Hashable, Codable {
    let name: String
    let label: String  // "brother", "mother", "spouse", etc.

    /// Label traduit en français
    var localizedLabel: String {
        // iOS fournit déjà la traduction via CNLabeledValue.localizedString
        label
    }
}

// MARK: - SocialProfile
/// Profil social du contact
struct SocialProfile: Hashable, Codable {
    let service: String  // "Twitter", "LinkedIn", "Facebook", etc.
    let username: String
    let urlString: String
}

// MARK: - PostalAddress
/// Adresse postale du contact
struct PostalAddress: Hashable, Codable {
    let label: String  // "home", "work", etc.
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

// MARK: - UIImage Extension
extension UIImage {
    /// Redimensionne l'image pour une utilisation thumbnail
    func resizedForThumbnail(maxSize: CGFloat = 200) -> UIImage {
        let ratio = min(maxSize / size.width, maxSize / size.height)
        guard ratio < 1 else { return self }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - PhoneContact + Sorting
extension PhoneContact {

    /// Clé de tri pour le regroupement alphabétique
    var sortKey: String {
        let firstLetter = fullName.first.map { String($0).uppercased() } ?? "#"
        return firstLetter.rangeOfCharacter(from: .letters) != nil ? firstLetter : "#"
    }
}

// MARK: - PhoneContact + Search
extension PhoneContact {

    /// Vérifie si le contact correspond à une recherche
    func matches(query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let lowerQuery = query.lowercased()

        if fullName.lowercased().contains(lowerQuery) { return true }
        if phoneNumbers.contains(where: { $0.contains(lowerQuery) }) { return true }
        if emails.contains(where: { $0.lowercased().contains(lowerQuery) }) { return true }
        if let org = organizationName, org.lowercased().contains(lowerQuery) { return true }
        if let title = jobTitle, title.lowercased().contains(lowerQuery) { return true }

        return false
    }
}

// MARK: - Mock Data
extension PhoneContact {

    static let mockContacts: [PhoneContact] = [
        PhoneContact(
            id: "mock-1",
            givenName: "Marie",
            familyName: "Dupont",
            phoneNumbers: ["+33 6 12 34 56 78"],
            emails: ["marie.dupont@email.com"],
            thumbnailImageData: nil,
            organizationName: "Tech Corp",
            jobTitle: "Designer"
        ),
        PhoneContact(
            id: "mock-2",
            givenName: "Jean",
            familyName: "Martin",
            phoneNumbers: ["+33 6 98 76 54 32"],
            emails: ["jean.martin@email.com"],
            thumbnailImageData: nil,
            organizationName: "Startup XYZ",
            jobTitle: "CTO"
        ),
        PhoneContact(
            id: "mock-3",
            givenName: "Sophie",
            familyName: "Bernard",
            phoneNumbers: ["+33 7 11 22 33 44"],
            emails: [],
            thumbnailImageData: nil
        ),
        PhoneContact(
            id: "mock-4",
            givenName: "Pierre",
            familyName: "Lefebvre",
            phoneNumbers: ["+33 6 55 44 33 22"],
            emails: ["pierre@startup.io"],
            thumbnailImageData: nil,
            organizationName: "Startup.io",
            jobTitle: "Founder"
        ),
        PhoneContact(
            id: "mock-5",
            givenName: "Emma",
            familyName: "Moreau",
            phoneNumbers: ["+33 6 00 11 22 33"],
            emails: ["emma.moreau@company.fr"],
            thumbnailImageData: nil,
            birthday: DateComponents(month: 5, day: 15),
            iOSRelations: [ContactRelation(name: "Emma", label: "Sœur")]
        )
    ]
}
