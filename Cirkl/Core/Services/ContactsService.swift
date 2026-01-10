import SwiftUI
import Contacts

// MARK: - ContactsService
/// Service pour accéder aux contacts du téléphone via CNContactStore
@Observable
@MainActor
final class ContactsService {

    // MARK: - Singleton
    static let shared = ContactsService()

    // MARK: - Authorization Status
    enum AuthorizationStatus {
        case notDetermined
        case authorized
        case denied
        case restricted

        var canRequestAccess: Bool {
            self == .notDetermined
        }

        var isAuthorized: Bool {
            self == .authorized
        }
    }

    // MARK: - Published Properties
    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
    private(set) var contacts: [PhoneContact] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    // MARK: - Private Properties
    private let store = CNContactStore()

    // MARK: - Init
    private init() {
        updateAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Met à jour le statut d'autorisation actuel
    func updateAuthorizationStatus() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        print("📇 ContactsService: CNContactStore status = \(status.rawValue)")
        switch status {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .authorized, .limited:
            authorizationStatus = .authorized
        case .denied:
            authorizationStatus = .denied
        case .restricted:
            authorizationStatus = .restricted
        @unknown default:
            authorizationStatus = .denied
        }
        print("📇 ContactsService: Updated authorizationStatus = \(authorizationStatus)")
    }

    /// Demande l'accès aux contacts
    @discardableResult
    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestAccess(for: .contacts)
            updateAuthorizationStatus()

            if granted {
                try await fetchContacts()
            }

            return granted
        } catch {
            self.error = error
            updateAuthorizationStatus()
            return false
        }
    }

    /// Ouvre les réglages de l'app pour modifier les permissions
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Fetch Contacts

    /// Récupère tous les contacts du téléphone
    func fetchContacts() async throws {
        print("📇 ContactsService: fetchContacts called, authorizationStatus = \(authorizationStatus)")

        guard authorizationStatus == .authorized else {
            print("📇 ContactsService: Not authorized, throwing error")
            throw ContactsError.notAuthorized
        }

        isLoading = true
        error = nil
        print("📇 ContactsService: Starting fetch...")

        do {
            // MARK: - Keys to Fetch (All available CNContact data)
            let keysToFetch: [CNKeyDescriptor] = [
                // Core identity
                CNContactIdentifierKey as CNKeyDescriptor,
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,

                // Contact methods
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,

                // Photos (thumbnail + full resolution fallback)
                CNContactThumbnailImageDataKey as CNKeyDescriptor,
                CNContactImageDataKey as CNKeyDescriptor,
                CNContactImageDataAvailableKey as CNKeyDescriptor,

                // Professional info
                CNContactOrganizationNameKey as CNKeyDescriptor,
                CNContactJobTitleKey as CNKeyDescriptor,
                CNContactDepartmentNameKey as CNKeyDescriptor,

                // Personal info
                CNContactBirthdayKey as CNKeyDescriptor,
                // Note: CNContactNoteKey requires special entitlement (com.apple.developer.contacts.notes)
                // which must be requested from Apple, so we skip it

                // Relationships (family, spouse, etc.)
                CNContactRelationsKey as CNKeyDescriptor,

                // Social profiles (LinkedIn, Twitter, etc.)
                CNContactSocialProfilesKey as CNKeyDescriptor,

                // Addresses
                CNContactPostalAddressesKey as CNKeyDescriptor
            ]

            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            request.sortOrder = .givenName

            var fetchedContacts: [PhoneContact] = []

            try store.enumerateContacts(with: request) { cnContact, _ in
                let phoneContact = PhoneContact(from: cnContact)
                // Filtrer les contacts sans nom et sans numéro
                if !phoneContact.fullName.isEmpty || !phoneContact.phoneNumbers.isEmpty {
                    fetchedContacts.append(phoneContact)
                }
            }

            // Trier par nom
            contacts = fetchedContacts.sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
            print("📇 ContactsService: Fetch completed, \(contacts.count) contacts loaded")
            isLoading = false

        } catch {
            print("📇 ContactsService: Fetch FAILED with error: \(error)")
            self.error = error
            isLoading = false
            throw error
        }
    }

    /// Recherche dans les contacts
    func searchContacts(query: String) -> [PhoneContact] {
        guard !query.isEmpty else { return contacts }
        return contacts.filter { $0.matches(query: query) }
    }

    /// Regroupe les contacts par première lettre
    func groupedContacts() -> [(String, [PhoneContact])] {
        let grouped = Dictionary(grouping: contacts) { $0.sortKey }
        return grouped.sorted { $0.key < $1.key }
    }
}

// MARK: - Contacts Error
enum ContactsError: LocalizedError {
    case notAuthorized
    case fetchFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "L'accès aux contacts n'est pas autorisé"
        case .fetchFailed(let error):
            return "Erreur lors de la récupération des contacts: \(error.localizedDescription)"
        }
    }
}
