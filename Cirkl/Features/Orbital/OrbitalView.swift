import SwiftUI

// MARK: - OrbitalView (Design Fidèle - Glass Bubble Style)
struct OrbitalView: View {
    @StateObject private var viewModel = OrbitalViewModel()
    @StateObject private var neo4jService = Neo4jService.shared
    private let invitedContactsService = InvitedContactsService.shared

    // État partagé: offsets de drag pour chaque bulle (par index)
    // Les lignes de connexion suivent ces offsets en temps réel
    @State private var bubbleOffsets: [Int: CGSize] = [:]

    // État pour afficher la liste des connexions
    @State private var showConnectionsList = false

    // État pour afficher le profil d'un contact (tap sur bulle)
    @State private var selectedContact: OrbitalContact?

    // État pour afficher la vue de vérification de proximité
    @State private var showVerificationView = false

    // État pour afficher les options d'ajout (ActionSheet)
    @State private var showAddOptions = false

    // État pour afficher la vue d'import de contacts
    @State private var showContactsImport = false

    // Mode d'affichage: vérifiés ou en attente
    @State private var selectedViewMode: OrbitalViewMode = .verified

    // Utilisateur courant (Gil) pour la vérification
    private var currentUser: User {
        User(
            name: "Gil",
            email: "gil@cirkl.app",
            avatarURL: nil,
            bio: "Fondateur Cirkl",
            sphere: .professional
        )
    }

    // Contacts combinés: Neo4j (primaire) + fallback mocks avec positionnement circulaire équidistant
    private var allContacts: [OrbitalContact] {
        var baseContacts: [OrbitalContact] = []

        // 1. NEO4J comme source PRIMAIRE - inclut toutes les modifications
        let neo4jNames = Set(neo4jService.connections.map { $0.name.lowercased() })

        // Couleurs pour les contacts Neo4j (pour ceux qui n'ont pas d'avatarColor stocké)
        let defaultColors: [Color] = [
            Color(red: 0.85, green: 0.65, blue: 0.45),  // Denis
            Color(red: 0.55, green: 0.75, blue: 0.85),  // Shay
            Color(red: 0.75, green: 0.55, blue: 0.70),  // Salomé
            Color(red: 0.50, green: 0.70, blue: 0.60),  // Dan
            Color(red: 0.65, green: 0.60, blue: 0.75),  // Gilles
            Color(red: 0.80, green: 0.55, blue: 0.55),  // Judith
        ]

        // Mapping nom -> couleur pour les mocks connus
        let mockColorMap: [String: Color] = [
            "denis": Color(red: 0.85, green: 0.65, blue: 0.45),
            "shay": Color(red: 0.55, green: 0.75, blue: 0.85),
            "salomé": Color(red: 0.75, green: 0.55, blue: 0.70),
            "dan": Color(red: 0.50, green: 0.70, blue: 0.60),
            "gilles": Color(red: 0.65, green: 0.60, blue: 0.75),
            "judith": Color(red: 0.80, green: 0.55, blue: 0.55),
        ]

        // Mapping nom -> photoName pour les mocks connus
        let mockPhotoMap: [String: String] = [
            "denis": "photo_denis",
            "shay": "photo_shay",
            "salomé": "photo_salome",
            "dan": "photo_dan",
            "gilles": "photo_gilles",
            "judith": "photo_judith",
        ]

        // Ajouter TOUS les contacts Neo4j (sauf Gil)
        for (index, neo4jContact) in neo4jService.connections.enumerated() {
            let nameLower = neo4jContact.name.lowercased()
            guard nameLower != "gil" else { continue }

            // Utiliser la couleur du mock si connue, sinon couleur par défaut cyclique
            let avatarColor = mockColorMap[nameLower] ?? defaultColors[index % defaultColors.count]

            // Récupérer le photoName pour les contacts connus
            let photoName = mockPhotoMap[nameLower]

            baseContacts.append(OrbitalContact.from(
                neo4jContact,
                xPercent: 0.5,
                yPercent: 0.5,
                avatarColor: avatarColor,
                photoName: photoName,
                trustLevel: .verified  // Contacts Neo4j sont vérifiés par défaut
            ))
        }

        // 2. Fallback: ajouter les mocks qui ne sont PAS encore dans Neo4j
        for mockContact in OrbitalContact.all {
            if !neo4jNames.contains(mockContact.name.lowercased()) {
                baseContacts.append(mockContact)
            }
        }

        // 3. Ajouter les contacts INVITÉS (en attente de confirmation)
        let existingNames = Set(baseContacts.map { $0.name.lowercased() })
        for invitedContact in invitedContactsService.invitedContacts {
            // Éviter les doublons
            guard !existingNames.contains(invitedContact.name.lowercased()) else { continue }

            let orbitalContact = OrbitalContact(
                id: invitedContact.id,
                name: invitedContact.name,
                photoName: nil,
                xPercent: 0.5,
                yPercent: 0.5,
                avatarColor: invitedContact.color,
                trustLevel: .invited,  // 👻 En attente de confirmation
                role: invitedContact.jobTitle,
                company: invitedContact.organizationName,
                industry: nil,
                meetingPlace: nil,
                meetingDate: invitedContact.meetingDate,  // Date de rencontre (pas d'invitation)
                connectionType: .personnel,
                relationshipType: invitedContact.relationshipType,
                selfiePhotoData: nil,
                contactPhotoData: invitedContact.photoData,  // Photo du contact
                notes: invitedContact.note,
                tags: [],
                invitedAt: invitedContact.invitedAt  // Date d'invitation
            )
            baseContacts.append(orbitalContact)
        }

        // 4. Filtrer selon le mode sélectionné (une seule catégorie à la fois)
        let filteredContacts: [OrbitalContact]
        switch selectedViewMode {
        case .verified:
            filteredContacts = baseContacts.filter { $0.trustLevel.isConfirmed }
        case .pending:
            filteredContacts = baseContacts.filter { !$0.trustLevel.isConfirmed }
        }

        // Paramètres du cercle orbital unique
        let centerX: CGFloat = 0.5
        let centerY: CGFloat = 0.42
        let radiusX: CGFloat = 0.32  // Rayon horizontal
        let radiusY: CGFloat = 0.27  // Rayon vertical
        let startAngle: CGFloat = -.pi / 2

        var positionedContacts: [OrbitalContact] = []

        // Positionner tous les contacts filtrés sur une seule orbite
        for (index, contact) in filteredContacts.enumerated() {
            let count = filteredContacts.count
            guard count > 0 else { continue }
            let angle = startAngle + (2 * .pi * CGFloat(index) / CGFloat(count))
            let xPercent = centerX + radiusX * cos(angle)
            let yPercent = centerY + radiusY * sin(angle)

            var positioned = contact
            positioned.xPercent = xPercent
            positioned.yPercent = yPercent
            positionedContacts.append(positioned)
        }

        return positionedContacts
    }

    // Base contacts non filtrés (pour comptage)
    private var baseContactsForCounting: [OrbitalContact] {
        var contacts: [OrbitalContact] = []

        // Neo4j contacts
        let defaultColors: [Color] = [
            Color(red: 0.85, green: 0.65, blue: 0.45),
            Color(red: 0.55, green: 0.75, blue: 0.85),
            Color(red: 0.75, green: 0.55, blue: 0.70),
            Color(red: 0.50, green: 0.70, blue: 0.60),
            Color(red: 0.65, green: 0.60, blue: 0.75),
            Color(red: 0.80, green: 0.55, blue: 0.55),
        ]

        let mockColorMap: [String: Color] = [
            "denis": Color(red: 0.85, green: 0.65, blue: 0.45),
            "shay": Color(red: 0.55, green: 0.75, blue: 0.85),
            "salomé": Color(red: 0.75, green: 0.55, blue: 0.70),
            "dan": Color(red: 0.50, green: 0.70, blue: 0.60),
            "gilles": Color(red: 0.65, green: 0.60, blue: 0.75),
            "judith": Color(red: 0.80, green: 0.55, blue: 0.55),
        ]

        let neo4jNames = Set(neo4jService.connections.map { $0.name.lowercased() })

        for (index, neo4jContact) in neo4jService.connections.enumerated() {
            let nameLower = neo4jContact.name.lowercased()
            guard nameLower != "gil" else { continue }
            let avatarColor = mockColorMap[nameLower] ?? defaultColors[index % defaultColors.count]

            contacts.append(OrbitalContact.from(
                neo4jContact,
                xPercent: 0.5,
                yPercent: 0.5,
                avatarColor: avatarColor,
                photoName: nil,
                trustLevel: .verified
            ))
        }

        // Mocks
        for mockContact in OrbitalContact.all {
            if !neo4jNames.contains(mockContact.name.lowercased()) {
                contacts.append(mockContact)
            }
        }

        // Invités
        let existingNames = Set(contacts.map { $0.name.lowercased() })
        for invitedContact in invitedContactsService.invitedContacts {
            guard !existingNames.contains(invitedContact.name.lowercased()) else { continue }
            contacts.append(OrbitalContact(
                id: invitedContact.id,
                name: invitedContact.name,
                photoName: nil,
                xPercent: 0.5,
                yPercent: 0.5,
                avatarColor: invitedContact.color,
                trustLevel: .invited,
                role: invitedContact.jobTitle,
                company: invitedContact.organizationName,
                industry: nil,
                meetingPlace: nil,
                meetingDate: invitedContact.meetingDate,  // Date de rencontre (pas d'invitation)
                connectionType: .personnel,
                relationshipType: invitedContact.relationshipType,
                selfiePhotoData: nil,
                contactPhotoData: invitedContact.photoData,  // Photo du contact
                notes: invitedContact.note,
                tags: [],
                invitedAt: invitedContact.invitedAt  // Date d'invitation
            ))
        }

        return contacts
    }

    // Compteurs pour le header (basés sur tous les contacts)
    private var verifiedCount: Int {
        baseContactsForCounting.filter { $0.trustLevel.isConfirmed }.count
    }

    private var pendingCount: Int {
        baseContactsForCounting.filter { !$0.trustLevel.isConfirmed }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // === HEADER ===
            OrbitalHeaderView(
                selectedMode: $selectedViewMode,
                verifiedCount: verifiedCount,
                pendingCount: pendingCount,
                onAddTap: { showAddOptions = true }
            )
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // === SEARCH BAR ===
            OrbitalSearchBarView(searchText: $viewModel.searchQuery)
                .padding(.horizontal, 20)
                .padding(.top, 14)

            // === ZONE ORBITALE ===
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let centerX = width / 2
                let centerY = height * 0.42

                ZStack {
                    // Lignes de connexion grises subtiles (suivent les bulles)
                    OrbitalLinesCanvas(
                        contacts: allContacts,
                        centerX: centerX,
                        centerY: centerY,
                        width: width,
                        height: height,
                        bubbleOffsets: bubbleOffsets,
                        searchQuery: viewModel.searchQuery
                    )

                    // Bulles des connexions (draggables + filtrables + tap pour profil)
                    OrbitalBubblesLayer(
                        contacts: allContacts,
                        centerX: centerX,
                        centerY: centerY,
                        width: width,
                        height: height,
                        bubbleOffsets: $bubbleOffsets,
                        searchQuery: viewModel.searchQuery,
                        onContactTap: { contact in
                            selectedContact = contact
                        }
                    )

                    // Bulle centrale (Gil)
                    CenterUserBubble()
                        .position(x: centerX, y: centerY)
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedViewMode)
            }
            .padding(.top, 16)

            // === AI BUTTON AVEC LIVING STATE ===
            CirklAIButton()
                .padding(.bottom, 30)
        }
        .background(Color.white)
        .sheet(isPresented: $showConnectionsList) {
            ConnectionsListView(contacts: baseContactsForCounting)
        }
        .sheet(item: $selectedContact) { contact in
            // Si c'est un contact invité, afficher InvitedContactDetailView
            if contact.trustLevel == .invited,
               let invitedContact = invitedContactsService.contact(withId: contact.id) {
                InvitedContactDetailView(
                    contact: invitedContact,
                    onUpdate: { _ in
                        // Les changements sont automatiquement reflétés via @State service
                    }
                )
            } else {
                // Contact vérifié: ProfileDetailView classique
                ProfileDetailView(
                    contact: contact,
                    onUpdate: { updatedContact in
                        // Rafraîchir les connexions depuis Neo4j après mise à jour
                        Task {
                            await neo4jService.fetchConnections()
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showVerificationView) {
            VerificationView(currentUser: currentUser) { newConnection in
                // Nouvelle connexion vérifiée - rafraîchir les données
                Task {
                    await neo4jService.fetchConnections()
                    await neo4jService.fetchConnectionCount()
                }
            }
        }
        .sheet(isPresented: $showContactsImport) {
            ContactsImportView(currentUser: currentUser)
        }
        .confirmationDialog(
            "Ajouter une connexion",
            isPresented: $showAddOptions,
            titleVisibility: .visible
        ) {
            Button {
                showVerificationView = true
            } label: {
                Label("Vérifier une rencontre", systemImage: "person.badge.shield.checkmark")
            }

            Button {
                showContactsImport = true
            } label: {
                Label("Inviter des contacts", systemImage: "person.crop.circle.badge.plus")
            }

            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Comment souhaitez-vous ajouter une connexion ?")
        }
        .task {
            // Charger les connexions depuis Neo4j (données déjà présentes)
            await neo4jService.fetchConnectionCount()
            await neo4jService.fetchConnections()
        }
    }
}

// MARK: - Modèle de Connexion
struct OrbitalContact: Identifiable, Hashable {
    let id: String
    var name: String
    var photoName: String?
    var xPercent: CGFloat
    var yPercent: CGFloat
    var avatarColor: Color  // Couleur du cercle avatar
    var trustLevel: TrustLevel  // Niveau de confiance (invited, verified, etc.)

    // Métadonnées pour recherche multi-critères
    var role: String?
    var company: String?
    var industry: String?
    var meetingPlace: String?
    var meetingDate: Date?
    var connectionType: ConnectionType
    var relationshipType: RelationshipType?  // Type de relation hiérarchique (legacy)
    var relationshipProfile: RelationshipProfile?  // Profil relationnel multi-dimensionnel
    var selfiePhotoData: Data?
    var contactPhotoData: Data?  // Photo du contact (pour les invités)
    var notes: String?
    var tags: [String] = []
    var invitedAt: Date?  // Date d'invitation (pour les invités)

    // MARK: - Computed Properties for Relationship

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

    // MARK: - Computed Properties for Dates

    /// Indique si la date de rencontre est requise (non pour la famille)
    var needsMeetingDate: Bool {
        // Si on a un profil multi-dimensionnel avec la sphère famille
        if let profile = relationshipProfile, profile.spheres.contains(.family) {
            return false
        }
        // Sinon, vérifier le type legacy
        guard let relationship = relationshipType else { return true }
        return !relationship.impliesLifelongRelation
    }

    /// Date de rencontre à afficher (ou "Depuis toujours" pour la famille)
    var meetingDateDisplay: String {
        // Vérifier d'abord le profil multi-dimensionnel
        if let profile = relationshipProfile, profile.spheres.contains(.family) {
            return "Depuis toujours"
        }
        // Sinon, vérifier le type legacy
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

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: OrbitalContact, rhs: OrbitalContact) -> Bool {
        lhs.id == rhs.id
    }

    /// Créer depuis un Neo4jConnection
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
            contactPhotoData: nil,  // Pas de photo de contact pour les Neo4j connections
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

    // Vérifie si le contact correspond à une requête de recherche
    func matches(query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let lowerQuery = query.lowercased()

        // Recherche dans tous les champs
        if name.lowercased().contains(lowerQuery) { return true }
        if let role = role, role.lowercased().contains(lowerQuery) { return true }
        if let company = company, company.lowercased().contains(lowerQuery) { return true }
        if let meetingPlace = meetingPlace, meetingPlace.lowercased().contains(lowerQuery) { return true }
        if tags.contains(where: { $0.lowercased().contains(lowerQuery) }) { return true }

        return false
    }

    // Disposition COMPACTE orbitale autour du centre (0.5, 0.42)
    // Design référence: bulles proches formant une constellation serrée
    static let all: [OrbitalContact] = [
        // Rangée haute - proche du centre (connexions vérifiées)
        OrbitalContact(id: "denis", name: "Denis", photoName: "photo_denis", xPercent: 0.28, yPercent: 0.18,
                      avatarColor: Color(red: 0.85, green: 0.65, blue: 0.45), trustLevel: .verified,
                      role: "Designer", company: "Studio Créatif", meetingPlace: "Meetup Design",
                      connectionType: .evenement, tags: ["design", "créatif"]),
        OrbitalContact(id: "shay", name: "Shay", photoName: "photo_shay", xPercent: 0.72, yPercent: 0.18,
                      avatarColor: Color(red: 0.55, green: 0.75, blue: 0.85), trustLevel: .verified,
                      role: "Developer", company: "Tech Corp", meetingPlace: "Conférence Swift",
                      connectionType: .professionnel, tags: ["tech", "iOS"]),
        // Rangée milieu - sur les côtés mais proche
        OrbitalContact(id: "salome", name: "Salomé", photoName: "photo_salome", xPercent: 0.18, yPercent: 0.42,
                      avatarColor: Color(red: 0.75, green: 0.55, blue: 0.70), trustLevel: .verified,
                      role: "Marketing", company: "Brand Agency", meetingPlace: "Networking Event",
                      connectionType: .networking, tags: ["marketing", "stratégie"]),
        OrbitalContact(id: "dan", name: "Dan", photoName: "photo_dan", xPercent: 0.82, yPercent: 0.42,
                      avatarColor: Color(red: 0.50, green: 0.70, blue: 0.60), trustLevel: .verified,
                      role: "Entrepreneur", company: "StartupX", meetingPlace: "Station F",
                      connectionType: .professionnel, tags: ["startup", "business"]),
        // Rangée basse - proche du centre
        OrbitalContact(id: "gilles", name: "Gilles", photoName: "photo_gilles", xPercent: 0.30, yPercent: 0.66,
                      avatarColor: Color(red: 0.65, green: 0.60, blue: 0.75), trustLevel: .verified,
                      role: "Consultant", company: "Advisory Co", meetingPlace: "Linkedin",
                      connectionType: .networking, tags: ["conseil", "stratégie"]),
        OrbitalContact(id: "judith", name: "Judith", photoName: "photo_judith", xPercent: 0.70, yPercent: 0.66,
                      avatarColor: Color(red: 0.80, green: 0.55, blue: 0.55), trustLevel: .verified,
                      role: "Product Manager", company: "BigTech", meetingPlace: "Product School",
                      connectionType: .evenement, tags: ["product", "management"])
    ]
}

// MARK: - Header
struct OrbitalHeaderView: View {
    @Binding var selectedMode: OrbitalViewMode
    let verifiedCount: Int
    let pendingCount: Int
    let onAddTap: () -> Void

    var body: some View {
        ZStack {
            // Logo "Cirkl" centré - typographie moderne
            Text("Cirkl")
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .tracking(1.5)
                .foregroundColor(Color(white: 0.35))

            HStack {
                // Toggle badges à gauche (interactifs)
                ModeToggleGroup(
                    selectedMode: $selectedMode,
                    verifiedCount: verifiedCount,
                    pendingCount: pendingCount
                )

                Spacer()

                // Bouton ajouter connexion
                Button(action: onAddTap) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.78, blue: 0.51),  // Mint
                                    Color(red: 0.0, green: 0.48, blue: 1.0)   // Blue
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: Color(red: 0.0, green: 0.78, blue: 0.51).opacity(0.3), radius: 8, y: 4)

                // Bouton settings à droite
                Button(action: {}) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(Color(white: 0.35))
                }
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color(white: 0.95))
                )
            }
        }
        .frame(height: 44)
    }
}

// MARK: - Search Bar
struct OrbitalSearchBarView: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(Color(white: 0.55))

            TextField("Ask anything you want to find...", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(Color(white: 0.30))

            Image(systemName: "mic")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(Color(white: 0.55))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(white: 0.96))
        )
    }
}

// MARK: - Connection Lines (Grises subtiles - suivent les bulles en temps réel)
struct OrbitalLinesCanvas: View {
    let contacts: [OrbitalContact]
    let centerX: CGFloat
    let centerY: CGFloat
    let width: CGFloat
    let height: CGFloat
    let bubbleOffsets: [Int: CGSize]  // Offsets de drag des bulles
    let searchQuery: String  // Pour filtrer les lignes aussi

    // Rayons des bulles (lignes touchent exactement le bord VISUEL)
    // Gil: size 90, contenu 90-6=84 → rayon 42
    // Contacts: size 70, contenu 70-6=64 → rayon 32
    private let centerBubbleRadius: CGFloat = 42
    private let contactBubbleRadius: CGFloat = 32

    // ID unique basé sur les offsets ET la recherche pour forcer le redraw du Canvas
    private var canvasId: String {
        let offsetsStr = bubbleOffsets.map { "\($0.key):\($0.value.width),\($0.value.height)" }.joined(separator: "|")
        return "\(offsetsStr)|\(searchQuery)|\(contacts.count)"
    }

    var body: some View {
        Canvas { context, _ in
            for (index, contact) in contacts.enumerated() {
                // Ne pas dessiner les lignes pour les contacts filtrés
                guard contact.matches(query: searchQuery) else { continue }
                // Position de base de la bulle
                let baseX = width * contact.xPercent
                let baseY = height * contact.yPercent

                // Ajouter l'offset de drag si présent
                let offset = bubbleOffsets[index] ?? .zero
                let bubbleX = baseX + offset.width
                let bubbleY = baseY + offset.height

                // Calculer la direction et distance vers le centre (Gil)
                let dx = bubbleX - centerX
                let dy = bubbleY - centerY
                let distance = sqrt(dx * dx + dy * dy)

                // Éviter division par zéro
                guard distance > 0 else { continue }

                // Normaliser la direction
                let dirX = dx / distance
                let dirY = dy / distance

                // Point de départ: exactement au bord de la bulle centrale (Gil)
                let startX = centerX + dirX * centerBubbleRadius
                let startY = centerY + dirY * centerBubbleRadius

                // Point d'arrivée: exactement au bord de la bulle contact
                let endX = bubbleX - dirX * contactBubbleRadius
                let endY = bubbleY - dirY * contactBubbleRadius

                var path = Path()
                path.move(to: CGPoint(x: startX, y: startY))
                path.addLine(to: CGPoint(x: endX, y: endY))

                context.stroke(
                    path,
                    with: .color(Color(white: 0.75).opacity(0.7)),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                )
            }
        }
        .id(canvasId)  // Force le redraw quand les offsets changent
    }
}

// MARK: - Connection Bubbles Layer
struct OrbitalBubblesLayer: View {
    let contacts: [OrbitalContact]
    let centerX: CGFloat
    let centerY: CGFloat
    let width: CGFloat
    let height: CGFloat
    @Binding var bubbleOffsets: [Int: CGSize]
    let searchQuery: String
    var onContactTap: ((OrbitalContact) -> Void)?  // Callback pour ouvrir le profil

    private let verifiedBubbleSize: CGFloat = 70   // Taille pour connexions vérifiées
    private let pendingBubbleSize: CGFloat = 60    // Taille réduite pour connexions en attente

    var body: some View {
        ForEach(Array(contacts.enumerated()), id: \.element.id) { index, contact in
            let posX = width * contact.xPercent
            let posY = height * contact.yPercent
            let isVisible = contact.matches(query: searchQuery)
            let bubbleSize = contact.trustLevel.isConfirmed ? verifiedBubbleSize : pendingBubbleSize

            AnimatedBubbleWrapper(
                contact: contact,
                index: index,
                posX: posX,
                posY: posY,
                centerX: centerX,
                centerY: centerY,
                bubbleSize: bubbleSize,
                isVisible: isVisible,
                isPending: !contact.trustLevel.isConfirmed,
                dragOffset: Binding(
                    get: { bubbleOffsets[index] ?? .zero },
                    set: { bubbleOffsets[index] = $0 }
                ),
                onTap: { onContactTap?(contact) }
            )
        }
    }
}

// MARK: - Animated Bubble Wrapper (Explosion Effect)
struct AnimatedBubbleWrapper: View {
    let contact: OrbitalContact
    let index: Int
    let posX: CGFloat
    let posY: CGFloat
    let centerX: CGFloat
    let centerY: CGFloat
    let bubbleSize: CGFloat
    let isVisible: Bool
    let isPending: Bool  // Détermine le style de bulle (ghost ou normal)
    @Binding var dragOffset: CGSize
    var onTap: (() -> Void)?  // Callback pour ouvrir le profil

    // Animation states
    @State private var explosionOffset: CGSize = .zero
    @State private var explosionScale: CGFloat = 1.0
    @State private var explosionOpacity: Double = 1.0
    @State private var explosionRotation: Double = 0

    var body: some View {
        Group {
            if isPending {
                // Bulle fantôme pour connexions en attente
                GhostBubbleView(
                    name: contact.name,
                    photoName: contact.photoName,
                    contactPhotoData: contact.contactPhotoData,
                    avatarColor: contact.avatarColor,
                    size: bubbleSize,
                    index: index,
                    dragOffset: $dragOffset,
                    onTap: onTap
                )
            } else {
                // Bulle normale pour connexions vérifiées
                GlassBubbleView(
                    name: contact.name,
                    photoName: contact.photoName,
                    avatarColor: contact.avatarColor,
                    size: bubbleSize,
                    index: index,
                    dragOffset: $dragOffset,
                    onTap: onTap
                )
            }
        }
        .scaleEffect(explosionScale)
        .opacity(explosionOpacity)
        .rotationEffect(.degrees(explosionRotation))
        .offset(x: explosionOffset.width, y: explosionOffset.height)
        .position(x: posX, y: posY)
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                // Retour avec animation "pop-in"
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    explosionOffset = .zero
                    explosionScale = 1.0
                    explosionOpacity = 1.0
                    explosionRotation = 0
                }
            } else {
                // Explosion vers l'extérieur
                let dx = posX - centerX
                let dy = posY - centerY
                let angle = atan2(dy, dx)

                // Distance d'explosion basée sur la position
                let distance: CGFloat = 300
                let targetX = cos(angle) * distance
                let targetY = sin(angle) * distance

                // Rotation aléatoire pour effet naturel
                let randomRotation = Double.random(in: -45...45)

                withAnimation(.easeOut(duration: 0.4)) {
                    explosionOffset = CGSize(width: targetX, height: targetY)
                    explosionScale = 0.3
                    explosionOpacity = 0.0
                    explosionRotation = randomRotation
                }
            }
        }
    }
}

// MARK: - Glass Bubble Overlay (Effet bulle transparent réutilisable)
struct GlassBubbleOverlay: View {
    let size: CGFloat
    let tintColor: Color

    var body: some View {
        ZStack {
            // === BORDURE ÉPAISSE IRIDESCENTE (style référence) ===
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(red: 0.7, green: 0.85, blue: 1.0).opacity(0.8),  // Bleu clair haut
                            tintColor.opacity(0.4),
                            Color(red: 0.85, green: 0.7, blue: 0.95).opacity(0.7), // Violet
                            Color(red: 1.0, green: 0.75, blue: 0.85).opacity(0.6), // Rose
                            Color(red: 0.7, green: 0.85, blue: 1.0).opacity(0.8)   // Retour bleu
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    lineWidth: 3.5
                )
                .frame(width: size, height: size)

            // === HIGHLIGHT PRINCIPAL HAUT-GAUCHE (grand arc) ===
            Circle()
                .trim(from: 0.6, to: 0.9)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.95),
                            Color.white.opacity(1.0),
                            Color.white.opacity(0.95),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: size * 0.92, height: size * 0.92)
                .rotationEffect(.degrees(-20))

            // === REFLET COURBE HAUT-GAUCHE ===
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.85),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.4, height: size * 0.15)
                .rotationEffect(.degrees(-40))
                .offset(x: -size * 0.12, y: -size * 0.32)

            // === REFLET BAS SUBTIL ===
            Circle()
                .trim(from: 0.05, to: 0.20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .frame(width: size * 0.85, height: size * 0.85)

            // === POINT SPARKLE ===
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.06, height: size * 0.06)
                .offset(x: -size * 0.25, y: -size * 0.28)
                .blur(radius: 0.3)
        }
    }
}

// MARK: - Glass Bubble View (VRAIE BULLE TRANSPARENTE style soap/glass)
struct GlassBubbleView: View {
    let name: String
    let photoName: String?
    let avatarColor: Color
    let size: CGFloat
    let index: Int
    @Binding var dragOffset: CGSize  // Binding partagé pour que les lignes suivent
    var onTap: (() -> Void)?  // Callback pour ouvrir le profil

    @State private var breathingPhase: Double = 0
    @State private var isDragging: Bool = false
    @State private var isBouncing: Bool = false  // Effet rebond au toucher
    @State private var dragStartLocation: CGPoint = .zero  // Pour détecter le tap vs drag

    var body: some View {
        VStack(spacing: 8) {
            // === BULLE PRINCIPALE ===
            ZStack {
                // === FOND TRANSPARENT TEINTÉ (visible derrière la personne détourée) ===
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                avatarColor.opacity(0.08),
                                avatarColor.opacity(0.15),
                                avatarColor.opacity(0.05)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.5
                        )
                    )
                    .frame(width: size - 6, height: size - 6)

                // === CONTENU: PHOTO DÉTOURÉE (fond transparent) OU PLACEHOLDER ===
                if let photoName = photoName, UIImage(named: photoName) != nil {
                    // Photo détourée avec fond transparent via Vision
                    SegmentedAsyncImage(
                        imageName: photoName,
                        size: CGSize(width: size - 6, height: size - 6),
                        placeholderColor: avatarColor
                    )
                } else {
                    // Placeholder: icône personne
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.35, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    avatarColor.opacity(0.8),
                                    avatarColor.opacity(0.6)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                // === OVERLAY GLASS BUBBLE (transparent avec effets) ===
                GlassBubbleOverlay(size: size, tintColor: avatarColor)
            }
            .scaleEffect(1.0 + breathingPhase * 0.012)
            // Effet rebond au premier toucher (bounce)
            .scaleEffect(isBouncing ? 1.15 : 1.0)
            // Légère augmentation de taille quand on drag
            .scaleEffect(isDragging ? 1.08 : 1.0)
            .shadow(color: avatarColor.opacity(isDragging ? 0.5 : 0.3), radius: isDragging ? 15 : 10, x: 0, y: isDragging ? 8 : 5)

            // === BADGE NOM ===
            Text(name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Color(white: 0.3))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
                )
        }
        .offset(x: dragOffset.width, y: dragOffset.height)
        .gesture(
            DragGesture(minimumDistance: 0)  // minimumDistance 0 pour détecter le toucher immédiat
                .onChanged { value in
                    // Stocker la position de départ au premier toucher
                    if !isDragging && !isBouncing {
                        dragStartLocation = value.startLocation

                        // Feedback haptique au toucher
                        let impact = UIImpactFeedbackGenerator(style: .soft)
                        impact.impactOccurred()

                        // Déclencher l'animation de rebond
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.5, blendDuration: 0)) {
                            isBouncing = true
                        }
                        // Revenir à la taille normale après le bounce
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
                                isBouncing = false
                            }
                        }
                    }

                    // Mise à jour immédiate (sans animation) pour que les lignes suivent en temps réel
                    isDragging = true
                    dragOffset = value.translation
                }
                .onEnded { value in
                    // Calculer la distance parcourue
                    let dragDistance = sqrt(
                        pow(value.translation.width, 2) +
                        pow(value.translation.height, 2)
                    )

                    // Si distance < 10pt, c'est un TAP → ouvrir le profil
                    if dragDistance < 10 {
                        onTap?()
                    }

                    // Retour élastique à la position initiale
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                        isDragging = false
                        dragOffset = .zero
                    }
                    // Feedback haptique au relâchement
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
        )
        .onAppear {
            // Animation breathing (scale) subtile
            withAnimation(.easeInOut(duration: Double.random(in: 3...5)).repeatForever(autoreverses: true)) {
                breathingPhase = 1.0
            }
        }
    }
}

// MARK: - Ghost Bubble View (Pour connexions invitées/en attente)
/// Bulle avec effet "fantôme" pour les connexions non confirmées
struct GhostBubbleView: View {
    let name: String
    let photoName: String?
    let contactPhotoData: Data?  // Photo réelle du contact
    let avatarColor: Color
    let size: CGFloat
    let index: Int
    @Binding var dragOffset: CGSize
    var onTap: (() -> Void)?

    @State private var pulsePhase: Double = 0
    @State private var isDragging: Bool = false
    @State private var isBouncing: Bool = false
    @State private var dragStartLocation: CGPoint = .zero

    // Opacité réduite pour effet fantôme
    private let ghostOpacity: Double = 0.65  // Légèrement plus visible avec photo

    /// Récupère l'UIImage depuis les données du contact
    private var contactImage: UIImage? {
        guard let data = contactPhotoData else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        VStack(spacing: 8) {
            // === BULLE FANTÔME ===
            ZStack {
                // === FOND GLASS EFFET ===
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                avatarColor.opacity(0.08 * ghostOpacity),
                                avatarColor.opacity(0.12 * ghostOpacity),
                                avatarColor.opacity(0.05 * ghostOpacity)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.5
                        )
                    )
                    .frame(width: size - 6, height: size - 6)

                // === CONTENU FANTÔME ===
                if let uiImage = contactImage {
                    // Photo réelle du contact avec effet glass
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size - 8, height: size - 8)
                        .clipShape(Circle())
                        .overlay(
                            // Overlay glass pour effet fantôme
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.15),
                                            Color.clear,
                                            Color.black.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .saturation(0.7)  // Légère désaturation pour effet fantôme
                        .opacity(ghostOpacity)
                } else if let photoName = photoName, UIImage(named: photoName) != nil {
                    SegmentedAsyncImage(
                        imageName: photoName,
                        size: CGSize(width: size - 6, height: size - 6),
                        placeholderColor: avatarColor
                    )
                    .opacity(ghostOpacity)
                } else {
                    // Fallback: icône person
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.35, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    avatarColor.opacity(0.6 * ghostOpacity),
                                    avatarColor.opacity(0.4 * ghostOpacity)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                // === BORDURE EN POINTILLÉS (style en attente) ===
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.gray.opacity(0.4),
                                avatarColor.opacity(0.3),
                                Color.gray.opacity(0.4)
                            ],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                    )
                    .frame(width: size, height: size)

                // === ICÔNE D'INVITATION (petit badge) ===
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(5)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.7))
                            )
                            .offset(x: 5, y: -5)
                    }
                    Spacer()
                }
                .frame(width: size, height: size)
            }
            .scaleEffect(1.0 + pulsePhase * 0.03) // Pulsation plus visible
            .scaleEffect(isBouncing ? 1.12 : 1.0)
            .scaleEffect(isDragging ? 1.05 : 1.0)
            .shadow(color: Color.gray.opacity(isDragging ? 0.3 : 0.15), radius: isDragging ? 10 : 6, x: 0, y: isDragging ? 6 : 3)

            // === BADGE NOM (semi-transparent) ===
            Text(name)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Color(white: 0.45))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.75))
                        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                )
        }
        .offset(x: dragOffset.width, y: dragOffset.height)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isDragging && !isBouncing {
                        dragStartLocation = value.startLocation

                        let impact = UIImpactFeedbackGenerator(style: .soft)
                        impact.impactOccurred()

                        withAnimation(.spring(response: 0.25, dampingFraction: 0.5, blendDuration: 0)) {
                            isBouncing = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
                                isBouncing = false
                            }
                        }
                    }

                    isDragging = true
                    dragOffset = value.translation
                }
                .onEnded { value in
                    let dragDistance = sqrt(
                        pow(value.translation.width, 2) +
                        pow(value.translation.height, 2)
                    )

                    if dragDistance < 10 {
                        onTap?()
                    }

                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                        isDragging = false
                        dragOffset = .zero
                    }
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
        )
        .onAppear {
            // Animation pulsation pour indiquer l'état "en attente"
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulsePhase = 1.0
            }
        }
    }
}

// MARK: - Center User Bubble (Gil - Style Glass Transparent comme les autres bulles)
struct CenterUserBubble: View {
    private let size: CGFloat = 90  // Plus grande que les contacts (70pt)

    @State private var breathingPhase: Double = 0

    // Couleur orange/coral distinctive pour Gil
    private let gilColor = Color(red: 0.95, green: 0.55, blue: 0.40)

    var body: some View {
        ZStack {
            // === BULLE PRINCIPALE ===
            VStack(spacing: 0) {
                ZStack {
                    // === FOND TRANSPARENT TEINTÉ (visible derrière la personne détourée) ===
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    gilColor.opacity(0.08),
                                    gilColor.opacity(0.15),
                                    gilColor.opacity(0.05)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: size * 0.5
                            )
                        )
                        .frame(width: size - 6, height: size - 6)

                    // === CONTENU: PHOTO DÉTOURÉE (fond transparent) OU PLACEHOLDER ===
                    if UIImage(named: "photo_gil") != nil {
                        // Photo détourée avec fond transparent via Vision
                        SegmentedAsyncImage(
                            imageName: "photo_gil",
                            size: CGSize(width: size - 6, height: size - 6),
                            placeholderColor: gilColor
                        )
                    } else {
                        // Placeholder: icône personne
                        Image(systemName: "person.fill")
                            .font(.system(size: size * 0.40, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        gilColor.opacity(0.85),
                                        gilColor.opacity(0.65)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    // === OVERLAY GLASS BUBBLE (transparent avec effets) ===
                    GlassBubbleOverlay(size: size, tintColor: gilColor)
                }
                .scaleEffect(1.0 + breathingPhase * 0.015)
                .shadow(color: gilColor.opacity(0.35), radius: 12, x: 0, y: 6)
            }

            // === BADGE NOM "Gil" (positionné en bas de la bulle) ===
            VStack {
                Spacer()
                    .frame(height: size * 0.95)

                Text("Gil")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color(white: 0.2))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.95))
                            .shadow(color: gilColor.opacity(0.2), radius: 4, y: 2)
                            .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                    )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                breathingPhase = 1.0
            }
        }
    }
}

// MARK: - Mic Button (Style Liquid Glass transparent - avec Long Press pour Audio)
struct OrbitalMicButtonView: View {
    let onTap: () -> Void
    let onAudioRecorded: (Data) -> Void

    @StateObject private var audioService = AudioRecorderService.shared

    @State private var isPressed = false
    @State private var pulsePhase: Double = 0
    @State private var isLongPressing = false
    @State private var longPressStartTime: Date?

    private let buttonSize: CGFloat = 70
    private let micColor = Color(red: 0.5, green: 0.3, blue: 0.8)
    private let recordingColor = Color.red

    // Délai pour distinguer tap de long press
    private let longPressThreshold: TimeInterval = 0.3

    var body: some View {
        ZStack {
            // === FOND INTÉRIEUR TRANSPARENT TEINTÉ ===
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            currentColor.opacity(0.15),
                            currentColor.opacity(0.25),
                            currentColor.opacity(0.10)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: buttonSize * 0.5
                    )
                )
                .frame(width: buttonSize - 4, height: buttonSize - 4)

            // === ICÔNE MIC ===
            Image(systemName: audioService.state.isRecording ? "waveform.circle.fill" : "mic.fill")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            currentColor.opacity(0.9),
                            currentColor.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .symbolEffect(.pulse, isActive: audioService.state.isRecording)

            // === OVERLAY GLASS BUBBLE ===
            GlassBubbleOverlay(size: buttonSize, tintColor: currentColor)

            // === RING D'ENREGISTREMENT (rouge pulsant) ===
            if audioService.state.isRecording {
                Circle()
                    .stroke(recordingColor.opacity(0.8), lineWidth: 3)
                    .frame(width: buttonSize + 8, height: buttonSize + 8)
                    .scaleEffect(1.0 + CGFloat(audioService.audioLevel) * 0.15)
                    .animation(.easeOut(duration: 0.1), value: audioService.audioLevel)
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .scaleEffect(1.0 + pulsePhase * 0.02)
        .shadow(color: currentColor.opacity(0.3), radius: 12, x: 0, y: 6)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isLongPressing {
                        isLongPressing = true
                        longPressStartTime = Date()

                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()

                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            isPressed = true
                        }

                        // Démarrer l'enregistrement après le seuil de long press
                        Task {
                            try? await Task.sleep(for: .milliseconds(Int(longPressThreshold * 1000)))

                            // Vérifier qu'on est toujours en train d'appuyer
                            if isLongPressing {
                                let impact = UIImpactFeedbackGenerator(style: .heavy)
                                impact.impactOccurred()

                                do {
                                    try await audioService.startRecording()
                                    print("🎤 Recording started via long press")
                                } catch {
                                    print("❌ Failed to start recording: \(error)")
                                }
                            }
                        }
                    }
                }
                .onEnded { _ in
                    let pressDuration = Date().timeIntervalSince(longPressStartTime ?? Date())

                    withAnimation(.easeOut(duration: 0.2)) {
                        isPressed = false
                    }

                    if audioService.state.isRecording {
                        // Long press terminé → arrêter l'enregistrement et envoyer
                        Task {
                            do {
                                let audioData = try await audioService.stopRecording()
                                print("🎤 Recording stopped: \(audioData.count) bytes")
                                onAudioRecorded(audioData)
                            } catch {
                                print("❌ Failed to stop recording: \(error)")
                            }
                        }
                    } else if pressDuration < longPressThreshold {
                        // Tap court → ouvrir le chat texte
                        onTap()
                    }

                    isLongPressing = false
                    longPressStartTime = nil
                }
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                pulsePhase = 1.0
            }
        }
    }

    private var currentColor: Color {
        audioService.state.isRecording ? recordingColor : micColor
    }
}

// MARK: - Preview
#Preview {
    OrbitalView()
}
