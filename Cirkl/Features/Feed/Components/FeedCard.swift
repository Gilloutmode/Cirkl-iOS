import SwiftUI

// MARK: - Feed Card (Generic Fallback)
/// Card générique pour les items du feed
/// Utilisé comme fallback, préférer les cards spécialisées (UpdateCard, SynergyCard, NetworkPulseCard)

struct FeedCard: View {

    let item: FeedItem
    let onTap: () -> Void

    // MARK: - Computed Properties

    /// Titre dérivé selon le type
    private var title: String {
        switch item.type {
        case .update:
            return item.connectionName ?? "Mise à jour"
        case .synergy:
            return "Synergie détectée"
        case .networkPulse:
            return item.connectionName ?? "Rappel réseau"
        }
    }

    /// Message dérivé selon le type
    private var message: String {
        switch item.type {
        case .update:
            return item.updateContent ?? "Nouvelle mise à jour"
        case .synergy:
            if let p1 = item.synergyPerson1Name, let p2 = item.synergyPerson2Name {
                return "\(p1) et \(p2) pourraient collaborer"
            }
            return "Match détecté entre deux connexions"
        case .networkPulse:
            if let days = item.daysSinceContact {
                return "Aucun contact depuis \(days) jours"
            }
            return "Cette connexion s'éloigne"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                // Avatar / Icon
                avatarView

                // Content
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    // Title with type indicator
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Text(item.type.emoji)
                            .font(.system(size: 14))

                        Text(title)
                            .font(DesignTokens.Typography.headline)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                    }

                    // Message
                    Text(message)
                        .font(DesignTokens.Typography.body)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    // Connection context + timestamp
                    HStack {
                        if let context = item.contextWithUser {
                            Text(context)
                                .font(DesignTokens.Typography.caption1)
                                .foregroundStyle(item.accentColor)
                        } else if let connectionName = item.connectionName {
                            Text(connectionName)
                                .font(DesignTokens.Typography.caption1)
                                .foregroundStyle(item.accentColor)
                        }

                        Spacer()

                        Text(item.relativeTimestamp)
                            .font(DesignTokens.Typography.caption2)
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }
                }

                Spacer(minLength: 0)

                // Unread indicator
                if !item.isRead {
                    Circle()
                        .fill(DesignTokens.Colors.electricBlue)
                        .frame(width: 10, height: 10)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background {
                glassBackground
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Avatar View

    @ViewBuilder
    private var avatarView: some View {
        if let connectionName = item.connectionName {
            // Connection avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [item.accentColor.opacity(0.3), item.accentColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Text(connectionName.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(item.accentColor)
                )
        } else {
            // Type icon for non-connection items
            Circle()
                .fill(
                    LinearGradient(
                        colors: [item.accentColor.opacity(0.2), item.accentColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: item.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(item.accentColor)
                )
        }
    }

    // MARK: - Glass Background

    @ViewBuilder
    private var glassBackground: some View {
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.medium)
                .fill(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: DesignTokens.Radius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.medium)
                        .strokeBorder(
                            item.isRead
                                ? DesignTokens.Colors.glassBorder.opacity(0.3)
                                : item.accentColor.opacity(0.3),
                            lineWidth: 1
                        )
                )
        } else {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.medium)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.medium)
                        .strokeBorder(
                            item.isRead
                                ? DesignTokens.Colors.glassBorder.opacity(0.3)
                                : item.accentColor.opacity(0.3),
                            lineWidth: 1
                        )
                )
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 16) {
            FeedCard(item: FeedItem.mockItems[0]) { }
            FeedCard(item: FeedItem.mockItems[1]) { }
            FeedCard(item: FeedItem.mockItems[2]) { }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
