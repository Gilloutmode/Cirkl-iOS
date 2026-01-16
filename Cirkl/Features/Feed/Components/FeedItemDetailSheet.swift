import SwiftUI

// MARK: - Feed Item Detail Sheet
/// Sheet de détail pour les items du feed
/// Affiche le contenu complet et les actions contextuelles

struct FeedItemDetailSheet: View {
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
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                .fill(DesignTokens.Colors.cardBackgroundElevated)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
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
    FeedItemDetailSheet(
        item: FeedItem.mockItems.first!,
        onConnectionUpdated: { _ in }
    )
}
