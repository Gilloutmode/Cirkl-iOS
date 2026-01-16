import SwiftUI

// MARK: - Update Card (📢)
/// Card pour les changements de fiche publique
/// Affiche: Avatar + Nom + Update + Contexte relationnel

struct UpdateCard: View {

    let item: FeedItem
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            #if DEBUG
            print("[Feed] UpdateCard: tapped for \(item.connectionName ?? "unknown") (id: \(item.id))")
            #endif
            onTap()
        }) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                // Avatar
                avatarView

                // Content
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    // Header: Name + Timestamp
                    HStack {
                        Text(item.connectionName ?? "Connexion")
                            .font(DesignTokens.Typography.headline)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        Spacer()

                        Text(item.relativeTimestamp)
                            .font(DesignTokens.Typography.caption2)
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }

                    // Update content
                    if let updateContent = item.updateContent {
                        Text(updateContent)
                            .font(DesignTokens.Typography.body)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .lineLimit(2)
                    }

                    // Contexte relationnel (la valeur ajoutée CirKL)
                    if let context = item.contextWithUser {
                        HStack(spacing: 4) {
                            Text("💡")
                                .font(.system(size: 12))

                            Text(context)
                                .font(DesignTokens.Typography.caption1)
                                .foregroundStyle(DesignTokens.Colors.electricBlue)
                        }
                        .padding(.top, 2)
                    }
                }

                // Unread indicator
                if !item.isRead {
                    Circle()
                        .fill(DesignTokens.Colors.electricBlue)
                        .frame(width: 10, height: 10)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                    .fill(DesignTokens.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                    .strokeBorder(
                        item.isRead
                            ? DesignTokens.Colors.cardBorder
                            : DesignTokens.Colors.electricBlue.opacity(0.5),
                        lineWidth: item.isRead ? 1 : 1.5
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.large))
    }

    // MARK: - Avatar View

    private var avatarView: some View {
        Circle()
            .fill(DesignTokens.Colors.electricBlue.opacity(0.15))
            .frame(width: 48, height: 48)
            .overlay(
                Group {
                    if let name = item.connectionName {
                        Text(name.prefix(1).uppercased())
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(DesignTokens.Colors.electricBlue)
                    } else {
                        Image(systemName: "megaphone.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(DesignTokens.Colors.electricBlue)
                    }
                }
            )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 16) {
            UpdateCard(item: FeedItem.mockItems[0]) { }
            UpdateCard(item: FeedItem.mockItems[1]) { }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
