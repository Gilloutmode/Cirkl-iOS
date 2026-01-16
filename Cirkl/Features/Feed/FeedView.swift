import SwiftUI

// MARK: - Feed View
/// Onglet actualités réseau avec filtres et liste scrollable
/// Style Instagram notifications avec 3 types de cards spécialisées

struct FeedView: View {

    @StateObject private var viewModel = FeedViewModel()
    @State private var selectedFeedItem: FeedItem?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                DesignTokens.Colors.background
                    .ignoresSafeArea()

                // Content
                content
            }
            .navigationTitle("Actualités")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.hasUnread {
                        Button {
                            withAnimation(DesignTokens.Animations.fast) {
                                viewModel.markAllAsRead()
                            }
                        } label: {
                            Text("Tout lire")
                                .font(DesignTokens.Typography.buttonSmall)
                                .foregroundStyle(DesignTokens.Colors.electricBlue)
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .preferredColorScheme(.dark)
        // Animation globale pour les changements de filtre et items
        .animation(DesignTokens.Animations.fast, value: viewModel.selectedFilter)
        .animation(DesignTokens.Animations.normal, value: viewModel.items.count)
        .animation(DesignTokens.Animations.fast, value: viewModel.unreadCount)
        // Sheet pour le détail connexion
        .sheet(item: $selectedFeedItem) { item in
            FeedItemDetailSheet(item: item) { updatedContact in
                viewModel.updateConnectionInFeed(updatedContact)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            loadingView
        } else if viewModel.items.isEmpty {
            emptyView
        } else {
            feedList
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)

            Text("Chargement des actualités...")
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "newspaper")
                .font(.system(size: 48))
                .foregroundStyle(DesignTokens.Colors.textTertiary)

            Text("Aucune actualité")
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text("Les actualités de ton réseau apparaîtront ici")
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignTokens.Spacing.xl)
    }

    // MARK: - Feed List

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.md) {
                // Filter pills
                filterHeader
                    .padding(.horizontal, DesignTokens.Spacing.md)

                // Feed items - dispatched by type
                ForEach(viewModel.filteredItems) { item in
                    feedCard(for: item)
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .scale(scale: 0.9))
                        ))
                        // Animate isRead changes (unread indicator visibility)
                        .animation(DesignTokens.Animations.fast, value: item.isRead)
                        .id(item.id) // Important pour les animations
                }

                // Bottom spacer
                Spacer()
                    .frame(height: DesignTokens.Spacing.xxl)
            }
            .padding(.top, DesignTokens.Spacing.md)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Card Dispatcher

    @ViewBuilder
    private func feedCard(for item: FeedItem) -> some View {
        switch item.type {
        case .update:
            UpdateCard(item: item) {
                handleItemTap(item)
            }

        case .synergy:
            SynergyCard(
                item: item,
                isLoading: viewModel.isItemLoading(item.id),
                onCreateConnection: {
                    // Sauvegarder les noms AVANT suppression pour le toast
                    let person1 = item.synergyPerson1Name ?? "Contact 1"
                    let person2 = item.synergyPerson2Name ?? "Contact 2"
                    CirklHaptics.medium()

                    Task {
                        await viewModel.createSynergyConnection(item.id)

                        await MainActor.run {
                            withAnimation(DesignTokens.Animations.normal) {
                                // L'item est déjà supprimé dans le ViewModel si succès
                            }

                            // Toast feedback based on result
                            if let error = viewModel.error {
                                // Erreur réseau ou backend
                                ToastManager.shared.error("Échec : \(error)")
                                CirklHaptics.error()
                            } else {
                                // Succès
                                ToastManager.shared.success("Connexion \(person1) ↔ \(person2) créée !")
                                CirklHaptics.success()
                            }
                        }
                    }
                },
                onDismiss: {
                    withAnimation(DesignTokens.Animations.normal) {
                        viewModel.dismissSynergy(item.id)
                    }
                    ToastManager.shared.info("Synergie ignorée")
                }
            )

        case .networkPulse:
            NetworkPulseCard(item: item) {
                handleItemTap(item)
            }
        }
    }

    // MARK: - Filter Header

    private var filterHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(FeedFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        title: filter.rawValue,
                        count: countForFilter(filter),
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        withAnimation(DesignTokens.Animations.fast) {
                            viewModel.selectFilter(filter)
                        }
                        CirklHaptics.light()
                    }
                }
            }
            .padding(.vertical, DesignTokens.Spacing.xs)
        }
    }

    // MARK: - Helpers

    private func countForFilter(_ filter: FeedFilter) -> Int? {
        switch filter {
        case .all: return nil
        case .updates: return viewModel.updateCount
        case .synergies: return viewModel.synergyCount
        case .reminders: return viewModel.reminderCount
        }
    }

    private func handleItemTap(_ item: FeedItem) {
        // Mark as read with animation
        withAnimation(DesignTokens.Animations.fast) {
            viewModel.markAsRead(item.id)
        }

        // Haptic feedback
        CirklHaptics.light()

        #if DEBUG
        print("📰 Tapped: \(item.connectionName ?? item.type.displayName)")
        #endif

        // Open detail sheet for this item
        selectedFeedItem = item
    }
}

// MARK: - Filter Pill

private struct FilterPill: View {
    let title: String
    let count: Int?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(DesignTokens.Typography.buttonSmall)

                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(DesignTokens.Typography.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.2) : DesignTokens.Colors.textTertiary.opacity(0.2))
                        )
                }
            }
            .foregroundStyle(
                isSelected ? Color.white : DesignTokens.Colors.textSecondary
            )
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background { pillBackground }
            .contentShape(Capsule()) // FIX: Zone de tap explicite
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var pillBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(isSelected ? DesignTokens.Colors.electricBlue : .clear)
                .glassEffect(.regular, in: .capsule)
        } else {
            if isSelected {
                Capsule()
                    .fill(DesignTokens.Colors.electricBlue)
            } else {
                Capsule()
                    .fill(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - Feed Item Detail Sheet

private struct FeedItemDetailSheet: View {
    let item: FeedItem
    let onConnectionUpdated: (OrbitalContact) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showProfileDetail = false
    @State private var showShareSheet = false
    @State private var suggestedMessage: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Header avec avatar
                    headerSection

                    // Contenu principal selon le type
                    contentSection

                    // Actions contextuelles
                    actionsSection
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignTokens.Colors.background)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showProfileDetail) {
            if let contact = createOrbitalContact() {
                ProfileDetailView(contact: contact) { updatedContact in
                    // Sync modifications back to the feed
                    onConnectionUpdated(updatedContact)

                    #if DEBUG
                    print("[Feed] ProfileDetailView callback: Connection updated - \(updatedContact.name)")
                    #endif
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [suggestedMessage])
        }
    }

    // MARK: - Navigation Title

    private var navigationTitle: String {
        switch item.type {
        case .update: return "Mise à jour"
        case .synergy: return "Synergie"
        case .networkPulse: return "Network Pulse"
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [item.accentColor.opacity(0.3), item.accentColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Group {
                        if let name = item.connectionName {
                            Text(name.prefix(1).uppercased())
                                .font(.system(size: 32, weight: .semibold, design: .rounded))
                                .foregroundStyle(item.accentColor)
                        } else {
                            Image(systemName: item.icon)
                                .font(.system(size: 32, weight: .medium))
                                .foregroundStyle(item.accentColor)
                        }
                    }
                )

            // Nom ou type
            Text(item.connectionName ?? item.type.displayName)
                .font(DesignTokens.Typography.title2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            // Contexte relationnel
            if let context = item.contextWithUser {
                Text(context)
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(item.accentColor)
            }

            // Timestamp
            Text(item.relativeTimestamp)
                .font(DesignTokens.Typography.caption1)
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
    }

    // MARK: - Content Section

    @ViewBuilder
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            switch item.type {
            case .update:
                updateContent

            case .synergy:
                synergyContent

            case .networkPulse:
                pulseContent
            }
        }
        .padding(DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(glassBackground)
    }

    @ViewBuilder
    private var updateContent: some View {
        if let content = item.updateContent {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Label("Mise à jour", systemImage: "newspaper.fill")
                    .font(DesignTokens.Typography.caption1)
                    .foregroundStyle(DesignTokens.Colors.electricBlue)

                Text(content)
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            }
        }
    }

    @ViewBuilder
    private var synergyContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Label("Synergie détectée", systemImage: "sparkles")
                .font(DesignTokens.Typography.caption1)
                .foregroundStyle(DesignTokens.Colors.purple)

            if let p1 = item.synergyPerson1Name, let p1Action = item.synergyPerson1 {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    personBadge(name: p1, color: DesignTokens.Colors.electricBlue)
                    Text(p1Action)
                        .font(DesignTokens.Typography.body)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }

            if let match = item.synergyMatch {
                Text("↔ \(match)")
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.purple)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            if let p2 = item.synergyPerson2Name, let p2Action = item.synergyPerson2 {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    personBadge(name: p2, color: DesignTokens.Colors.success)
                    Text(p2Action)
                        .font(DesignTokens.Typography.body)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private var pulseContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            if let status = item.pulseStatus {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Text(status.emoji)
                    Text(status == .dormant ? "Connexion dormante" : "Connexion à risque")
                        .font(DesignTokens.Typography.subheadline)
                        .foregroundStyle(status.color)
                }
            }

            if let days = item.daysSinceContact {
                Label("Dernier contact il y a \(days) jours", systemImage: "clock.arrow.circlepath")
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            if let lastInteraction = item.lastInteractionContext {
                Text("Contexte : \(lastInteraction)")
                    .font(DesignTokens.Typography.caption1)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
        }
    }

    private func personBadge(name: String, color: Color) -> some View {
        Circle()
            .fill(color.opacity(0.2))
            .frame(width: 32, height: 32)
            .overlay(
                Text(name.prefix(1).uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            )
    }

    // MARK: - Actions Section

    @ViewBuilder
    private var actionsSection: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // Actions selon le type d'item
            switch item.type {
            case .update, .networkPulse:
                // Ces types ont un connectionId unique → bouton profil
                if item.connectionId != nil {
                    Button {
                        CirklHaptics.medium()
                        showProfileDetail = true
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle")
                            Text("Voir le profil complet")
                        }
                        .font(DesignTokens.Typography.buttonSmall)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.md)
                        .background(
                            Capsule().fill(DesignTokens.Colors.electricBlue)
                        )
                    }
                    .buttonStyle(.plain)
                }

            case .synergy:
                // Les synergies impliquent 2 personnes, pas de profil unique
                // Message explicatif
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                    Text("Cette synergie implique 2 connexions distinctes")
                        .font(DesignTokens.Typography.caption1)
                }
                .foregroundStyle(DesignTokens.Colors.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.sm)
            }

            // Action contextuelle supplémentaire
            contextualActionButton
        }
        .padding(.top, DesignTokens.Spacing.md)
    }

    @ViewBuilder
    private var contextualActionButton: some View {
        switch item.type {
        case .update:
            // Pas d'action supplémentaire pour les updates
            EmptyView()

        case .synergy:
            // Note: Les boutons d'action (Créer connexion / Pas maintenant)
            // sont dans SynergyCard directement, pas dans le detail sheet
            EmptyView()

        case .networkPulse:
            Button {
                CirklHaptics.light()
                // Générer le message suggéré et ouvrir le share sheet
                suggestedMessage = generateResumeContactMessage()
                showShareSheet = true

                // Toast feedback for action
                let contactName = item.connectionName ?? "cette personne"
                ToastManager.shared.info("Message préparé pour \(contactName)")

                #if DEBUG
                print("[Feed] Reprendre contact tapped for: \(item.connectionName ?? "unknown")")
                #endif
            } label: {
                HStack {
                    Image(systemName: "message.fill")
                    Text("Reprendre contact")
                }
                .font(DesignTokens.Typography.buttonSmall)
                .foregroundStyle(item.accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.md)
                .background(
                    Capsule()
                        .strokeBorder(item.accentColor.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helper Methods

    /// Génère un message suggéré pour reprendre contact
    private func generateResumeContactMessage() -> String {
        let name = item.connectionName ?? "toi"
        let context = item.lastInteractionContext ?? "notre dernière rencontre"

        if let days = item.daysSinceContact {
            if days > 30 {
                return "Hey \(name) ! Ça fait un moment depuis \(context). Je pensais à toi, comment vas-tu ?"
            } else {
                return "Salut \(name) ! Je repensais à \(context). On se fait un café bientôt ?"
            }
        }

        return "Hey \(name) ! Je pensais à toi. On se fait un café bientôt ?"
    }

    // MARK: - Glass Background

    @ViewBuilder
    private var glassBackground: some View {
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.medium)
                .fill(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: DesignTokens.Radius.medium))
        } else {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.medium)
                .fill(.ultraThinMaterial)
        }
    }

    // MARK: - Create OrbitalContact

    /// Crée un OrbitalContact minimal depuis les données du FeedItem
    private func createOrbitalContact() -> OrbitalContact? {
        guard let connectionId = item.connectionId,
              let connectionName = item.connectionName else {
            return nil
        }

        return OrbitalContact(
            id: connectionId,
            name: connectionName,
            photoName: nil,
            xPercent: 0.5,
            yPercent: 0.5,
            avatarColor: item.accentColor,
            trustLevel: .verified,
            role: nil,
            company: nil,
            industry: nil,
            meetingPlace: nil,
            meetingDate: nil,
            connectionType: .networking,
            relationshipType: nil,
            relationshipProfile: nil,
            selfiePhotoData: nil,
            contactPhotoData: nil,
            notes: nil,
            tags: []
        )
    }
}

// MARK: - Preview

#Preview {
    FeedView()
}
