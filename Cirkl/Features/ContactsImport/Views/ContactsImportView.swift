import SwiftUI

// MARK: - ContactsImportView
/// Vue principale pour importer des contacts et les inviter sur CirKL
struct ContactsImportView: View {

    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery = ""
    @State private var selectedContacts: Set<String> = []
    @State private var contactToInvite: PhoneContact?

    // Observable properties mirrored to State for proper SwiftUI updates
    @State private var contacts: [PhoneContact] = []
    @State private var authorizationStatus: ContactsService.AuthorizationStatus = .notDetermined
    @State private var isLoading = false

    let currentUser: User
    private let contactsService = ContactsService.shared

    // MARK: - Computed
    private var filteredContacts: [PhoneContact] {
        guard !searchQuery.isEmpty else { return contacts }
        return contacts.filter { $0.matches(query: searchQuery) }
    }

    private var selectedCount: Int {
        selectedContacts.count
    }

    private var hasSelection: Bool {
        !selectedContacts.isEmpty
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                // Content based on authorization status
                switch authorizationStatus {
                case .notDetermined:
                    permissionRequestView
                case .authorized:
                    contactsListView
                case .denied, .restricted:
                    permissionDeniedView
                }

                // Floating invite button
                if hasSelection && authorizationStatus == .authorized {
                    floatingInviteButton
                }
            }
            .navigationTitle("Inviter des contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }

                if authorizationStatus == .authorized {
                    ToolbarItem(placement: .topBarTrailing) {
                        selectionButton
                    }
                }
            }
            .sheet(item: $contactToInvite) { contact in
                InvitationOptionsSheet(
                    contact: contact,
                    currentUser: currentUser,
                    onComplete: { result in
                        handleInvitationResult(result, for: contact)
                    }
                )
                .presentationDetents([.medium])
            }
            .task {
                print("📱 ContactsImportView: .task started")
                await loadContacts()
                print("📱 ContactsImportView: .task completed, contacts count = \(contacts.count)")
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Refresh when returning from Settings
                Task {
                    await loadContacts()
                }
            }
        }
    }

    // MARK: - Load Contacts
    private func loadContacts() async {
        // Sync authorization status from CNContactStore directly
        contactsService.updateAuthorizationStatus()
        let currentStatus = contactsService.authorizationStatus
        authorizationStatus = currentStatus

        print("📱 ContactsImportView: Authorization status = \(currentStatus)")

        // If authorized, load contacts
        guard currentStatus == .authorized else {
            print("📱 ContactsImportView: Not authorized, skipping fetch")
            return
        }

        isLoading = true

        do {
            try await contactsService.fetchContacts()
            // Important: copier les contacts APRÈS le fetch
            let fetchedContacts = contactsService.contacts
            print("📱 ContactsImportView: Fetched \(fetchedContacts.count) contacts")
            contacts = fetchedContacts
        } catch {
            print("❌ ContactsImportView: Error loading contacts: \(error)")
        }

        isLoading = false
    }

    // MARK: - Permission Request View
    private var permissionRequestView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.mint.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 44))
                    .foregroundStyle(.mint)
            }

            // Title
            Text("Accéder à vos contacts")
                .font(.title2.weight(.bold))

            // Description
            Text("CirKL a besoin d'accéder à vos contacts pour vous permettre d'inviter les personnes que vous avez déjà rencontrées.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Button
            Button {
                Task {
                    print("📱 ContactsImportView: Requesting access...")
                    let granted = await contactsService.requestAccess()
                    print("📱 ContactsImportView: Access granted = \(granted)")
                    if granted {
                        await loadContacts()
                    } else {
                        authorizationStatus = contactsService.authorizationStatus
                        print("📱 ContactsImportView: Access denied, status = \(authorizationStatus)")
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "lock.open.fill")
                    Text("Autoriser l'accès")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.mint, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Permission Denied View
    private var permissionDeniedView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.lock.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.orange)
            }

            // Title
            Text("Accès refusé")
                .font(.title2.weight(.bold))

            // Description
            Text("Pour inviter vos contacts, vous devez autoriser l'accès dans les réglages de votre iPhone.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Button
            Button {
                contactsService.openSettings()
            } label: {
                HStack {
                    Image(systemName: "gear")
                    Text("Ouvrir les réglages")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.orange)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Contacts List View
    private var contactsListView: some View {
        VStack(spacing: 0) {
            // Header question
            questionHeader

            // Search bar
            searchBar

            // Contacts list
            if isLoading {
                ProgressView("Chargement des contacts...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredContacts.isEmpty {
                EmptyContactsView(searchQuery: searchQuery)
            } else {
                contactsList
            }
        }
    }

    // MARK: - Question Header
    private var questionHeader: some View {
        VStack(spacing: 8) {
            Text("Sélectionnez les contacts que vous avez déjà rencontrés physiquement")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            Text("Ces personnes recevront une invitation à confirmer votre rencontre")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.mint.opacity(0.08))
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Rechercher un contact...", text: $searchQuery)
                .textFieldStyle(.plain)

            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Contacts List
    private var contactsList: some View {
        ScrollView {
            LazyVStack(spacing: 4, pinnedViews: [.sectionHeaders]) {
                ForEach(filteredContacts) { contact in
                    ContactRow(
                        contact: contact,
                        isSelected: selectedContacts.contains(contact.id),
                        onTap: {
                            toggleSelection(for: contact)
                        }
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, hasSelection ? 100 : 20)
        }
    }

    // MARK: - Selection Button
    private var selectionButton: some View {
        Menu {
            Button {
                selectAll()
            } label: {
                Label("Tout sélectionner", systemImage: "checkmark.circle.fill")
            }

            Button {
                deselectAll()
            } label: {
                Label("Tout désélectionner", systemImage: "circle")
            }
        } label: {
            Image(systemName: "checklist")
                .font(.system(size: 17))
        }
    }

    // MARK: - Floating Invite Button
    private var floatingInviteButton: some View {
        VStack {
            Spacer()

            Button {
                // Show invitation options for all selected contacts
                if let firstSelected = selectedContacts.first,
                   let contact = filteredContacts.first(where: { $0.id == firstSelected }) {
                    contactToInvite = contact
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "paperplane.fill")
                    Text("Inviter (\(selectedCount))")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.mint, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .mint.opacity(0.4), radius: 12, y: 6)
                )
            }
            .padding(.bottom, 30)
        }
    }

    // MARK: - Actions

    private func toggleSelection(for contact: PhoneContact) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        if selectedContacts.contains(contact.id) {
            selectedContacts.remove(contact.id)
        } else {
            selectedContacts.insert(contact.id)
        }
    }

    private func selectAll() {
        selectedContacts = Set(filteredContacts.map { $0.id })
    }

    private func deselectAll() {
        selectedContacts.removeAll()
    }

    private func handleInvitationResult(_ result: InvitationResult, for contact: PhoneContact) {
        switch result {
        case .sent:
            // Ajouter aux contacts invités pour affichage dans l'orbital
            addToInvitedContacts(contact)

            // Retirer de la sélection
            selectedContacts.remove(contact.id)

            // Passer au prochain contact sélectionné après un court délai
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let nextId = selectedContacts.first,
                   let nextContact = filteredContacts.first(where: { $0.id == nextId }) {
                    contactToInvite = nextContact
                } else {
                    // Tous les contacts invités
                    contactToInvite = nil
                }
            }

        case .cancelled, .failed:
            contactToInvite = nil
        }
    }

    /// Ajoute le contact aux invitations en attente avec toutes les données enrichies
    private func addToInvitedContacts(_ contact: PhoneContact) {
        // Générer une couleur pastel aléatoire pour l'avatar
        let colors: [Color] = [
            Color(red: 0.6, green: 0.75, blue: 0.9),
            Color(red: 0.9, green: 0.7, blue: 0.8),
            Color(red: 0.7, green: 0.85, blue: 0.7),
            Color(red: 0.95, green: 0.8, blue: 0.6),
            Color(red: 0.8, green: 0.7, blue: 0.85),
        ]
        let randomColor = colors.randomElement() ?? .gray

        // Convertir les relations iOS en RelationshipType si possible
        var relationshipType: RelationshipType?
        var iOSRelationLabel: String?

        if let firstRelation = contact.iOSRelations.first {
            iOSRelationLabel = firstRelation.label
            relationshipType = RelationshipType.fromIOSRelation(label: firstRelation.label)
        }

        // Convertir les profils sociaux
        let socialProfiles = contact.socialProfiles.map { profile in
            CodableSocialProfile(
                service: profile.service,
                username: profile.username,
                urlString: profile.urlString
            )
        }

        // Convertir les adresses postales
        let postalAddresses = contact.postalAddresses.map { address in
            CodablePostalAddress(
                label: address.label,
                street: address.street,
                city: address.city,
                state: address.state,
                postalCode: address.postalCode,
                country: address.country
            )
        }

        InvitedContactsService.shared.addInvitedContact(
            name: contact.fullName,
            phoneNumber: contact.primaryPhone,
            emails: contact.emails,
            avatarColor: randomColor,
            photoData: contact.bestPhotoData,  // Use bestPhotoData for fallback
            relationshipType: relationshipType,
            iOSRelationLabel: iOSRelationLabel,
            organizationName: contact.organizationName,
            jobTitle: contact.jobTitle,
            birthday: contact.birthday,
            note: contact.note,
            socialProfiles: socialProfiles,
            postalAddresses: postalAddresses
        )
    }
}

// MARK: - Preview
#Preview {
    ContactsImportView(
        currentUser: User(
            name: "Gil",
            email: "gil@cirkl.app",
            sphere: .professional
        )
    )
}
