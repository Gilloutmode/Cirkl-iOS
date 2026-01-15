import SwiftUI

// MARK: - OrbitalView (Design Fidèle - Glass Bubble Style)
struct OrbitalView: View {
    @EnvironmentObject var appState: AppStateManager
    @StateObject private var viewModel = OrbitalViewModel()
    @StateObject private var neo4jService = Neo4jService.shared
    private let invitedContactsService = InvitedContactsService.shared

    // État partagé: offsets de drag pour chaque bulle (par index)
    // Les lignes de connexion suivent ces offsets en temps réel
    @State private var bubbleOffsets: [Int: CGSize] = [:]

    // État pour afficher la liste des connexions
    @State private var showConnectionsList = false

    // État pour afficher les réglages
    @State private var showSettings = false

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

    // PERFORMANCE FIX: Memoized contacts to avoid recalculating on every render
    // allContacts was a computed property with 3+ loops + trigonometry running 60x/sec
    @State private var cachedContacts: [OrbitalContact] = []
    @State private var cachedBaseContacts: [OrbitalContact] = []
    @State private var lastContactsHash: Int = 0

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

    // PERFORMANCE FIX: Use cached contacts instead of computing on every render
    private var allContacts: [OrbitalContact] { cachedContacts }

    // PERFORMANCE FIX: Function to update contacts only when dependencies change
    private func updateContactsIfNeeded() {
        // Use count-based hash since InvitedContact doesn't conform to Hashable
        let invitedHash = invitedContactsService.invitedContacts.count ^
                          invitedContactsService.invitedContacts.map { $0.id.hashValue }.reduce(0, ^)
        let newHash = neo4jService.connections.hashValue ^
                      invitedHash ^
                      selectedViewMode.hashValue ^
                      viewModel.searchQuery.hashValue

        guard newHash != lastContactsHash else { return }
        lastContactsHash = newHash
        cachedBaseContacts = computeBaseContacts()
        cachedContacts = computeAllContacts()
    }

    // PERFORMANCE FIX: Compute all contacts with filtering and positioning
    private func computeAllContacts() -> [OrbitalContact] {
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
        var filteredContacts: [OrbitalContact]
        switch selectedViewMode {
        case .verified:
            filteredContacts = baseContacts.filter { $0.trustLevel.isConfirmed }
        case .pending:
            filteredContacts = baseContacts.filter { !$0.trustLevel.isConfirmed }
        }

        // 5. CRITICAL FIX: Filtrer par searchQuery (était manquant - causait le bug de filtrage)
        // Le filtrage visuel dans OrbitalBubblesLayer n'était pas suffisant sur device réel
        let searchQuery = viewModel.searchQuery
        if !searchQuery.isEmpty {
            filteredContacts = filteredContacts.filter { $0.matches(query: searchQuery) }
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

    // PERFORMANCE FIX: Use cached base contacts for counting (avoids recomputing)
    private var baseContactsForCounting: [OrbitalContact] { cachedBaseContacts }

    // PERFORMANCE FIX: Compute base contacts without filtering/positioning
    private func computeBaseContacts() -> [OrbitalContact] {
        var contacts: [OrbitalContact] = []

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

        let mockPhotoMap: [String: String] = [
            "denis": "photo_denis",
            "shay": "photo_shay",
            "salomé": "photo_salome",
            "dan": "photo_dan",
            "gilles": "photo_gilles",
            "judith": "photo_judith",
        ]

        let neo4jNames = Set(neo4jService.connections.map { $0.name.lowercased() })

        for (index, neo4jContact) in neo4jService.connections.enumerated() {
            let nameLower = neo4jContact.name.lowercased()
            guard nameLower != "gil" else { continue }
            let avatarColor = mockColorMap[nameLower] ?? defaultColors[index % defaultColors.count]
            let photoName = mockPhotoMap[nameLower]

            contacts.append(OrbitalContact.from(
                neo4jContact,
                xPercent: 0.5,
                yPercent: 0.5,
                avatarColor: avatarColor,
                photoName: photoName,
                trustLevel: .verified
            ))
        }

        for mockContact in OrbitalContact.all {
            if !neo4jNames.contains(mockContact.name.lowercased()) {
                contacts.append(mockContact)
            }
        }

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
                meetingDate: invitedContact.meetingDate,
                connectionType: .personnel,
                relationshipType: invitedContact.relationshipType,
                selfiePhotoData: nil,
                contactPhotoData: invitedContact.photoData,
                notes: invitedContact.note,
                tags: [],
                invitedAt: invitedContact.invitedAt
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
                invitedCount: invitedContactsService.invitedContacts.count,
                onAddTap: { showAddOptions = true },
                onSettingsTap: { showSettings = true },
                onConnectionsTap: { showConnectionsList = true }
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
                    if neo4jService.isLoading {
                        // Skeleton Loading State
                        OrbitalSkeletonView(
                            centerX: centerX,
                            centerY: centerY,
                            width: width,
                            height: height
                        )
                        .transition(.opacity)
                    } else if allContacts.isEmpty {
                        // Empty State - aucune connexion dans ce mode
                        VStack {
                            Spacer()
                            CirklEmptyState.orbital(onImport: {
                                CirklHaptics.selection()
                                showContactsImport = true
                            })
                            Spacer()
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
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
                                CirklHaptics.bubbleTap()
                                selectedContact = contact
                            }
                        )
                    }

                    // Bulle centrale (Gil) - toujours visible
                    CenterUserBubble()
                        .position(x: centerX, y: centerY)
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedViewMode)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: allContacts.isEmpty)
            }
            .padding(.top, 16)

            // === AI BUTTON AVEC LIVING STATE ===
            CirklAIButton()
                .padding(.bottom, 30)
        }
        .background(
            // Animated Liquid Glass background with parallax orbs
            StandaloneAdaptiveBackground()
        )
        .sheet(isPresented: $showConnectionsList) {
            ConnectionsListView(contacts: baseContactsForCounting)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(appState)
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
            // PERFORMANCE FIX: Initial cache population
            updateContactsIfNeeded()
        }
        // PERFORMANCE FIX: Update cache when dependencies change (instead of recomputing on every render)
        .onChange(of: neo4jService.connections) { _, _ in
            updateContactsIfNeeded()
        }
        // Track invited contacts count since InvitedContact doesn't conform to Equatable
        .onChange(of: invitedContactsService.invitedContacts.count) { _, _ in
            updateContactsIfNeeded()
        }
        .onChange(of: selectedViewMode) { _, _ in
            updateContactsIfNeeded()
        }
        .onChange(of: viewModel.searchQuery) { _, _ in
            updateContactsIfNeeded()
        }
    }
}

// MARK: - OrbitalContact Model
// NOTE: OrbitalContact is now defined in Models/OrbitalContact.swift

// MARK: - Extracted Components
// The following components have been extracted to separate files for better maintainability:
// - OrbitalContact → Models/OrbitalContact.swift
// - OrbitalHeaderView, InvitationsSentBadge, OrbitalSearchBarView → Components/OrbitalHeaderComponents.swift
// - OrbitalLinesCanvas, OrbitalBubblesLayer, AnimatedBubbleWrapper → Components/OrbitalLayers.swift
// - GlassBubbleOverlay, GlassBubbleView, GhostBubbleView, CenterUserBubble, OrbitalMicButtonView → Components/OrbitalBubbleViews.swift

// MARK: - Preview
#Preview {
    OrbitalView()
        .environmentObject(AppStateManager())
}
