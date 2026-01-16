import SwiftUI

// MARK: - Network Pulse Card (🟡🔴)
/// Card pour les rappels de connexions dormantes/à risque
/// Affiche: Indicateur couleur + Nom + Contexte dernière interaction

struct NetworkPulseCard: View {

    let item: FeedItem
    let onTap: () -> Void

    private var statusColor: Color {
        item.pulseStatus?.color ?? DesignTokens.Colors.warning
    }

    private var statusEmoji: String {
        item.pulseStatus?.emoji ?? "🟡"
    }

    var body: some View {
        Button(action: {
            #if DEBUG
            print("[Feed] NetworkPulseCard: tapped for \(item.connectionName ?? "unknown") - status: \(item.pulseStatus?.rawValue ?? "unknown") (id: \(item.id))")
            #endif
            onTap()
        }) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                // Status indicator + Avatar
                ZStack(alignment: .bottomTrailing) {
                    // Avatar
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Group {
                                if let name = item.connectionName {
                                    Text(name.prefix(1).uppercased())
                                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                                        .foregroundStyle(statusColor)
                                }
                            }
                        )

                    // Status badge
                    Text(statusEmoji)
                        .font(.system(size: 14))
                        .background(
                            Circle()
                                .fill(DesignTokens.Colors.background)
                                .frame(width: 22, height: 22)
                        )
                        .offset(x: 4, y: 4)
                }

                // Content
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    // Header: Name + Days count
                    HStack {
                        Text(item.connectionName ?? "Connexion")
                            .font(DesignTokens.Typography.headline)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        Spacer()

                        if let days = item.daysSinceContact {
                            Text("Il y a \(days)j")
                                .font(DesignTokens.Typography.caption2)
                                .foregroundStyle(statusColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(statusColor.opacity(0.15))
                                )
                        }

                        // Unread indicator
                        if !item.isRead {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 10, height: 10)
                        }
                    }

                    // Contexte relationnel
                    if let context = item.contextWithUser {
                        Text(context)
                            .font(DesignTokens.Typography.caption1)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }

                    // Dernière interaction
                    if let lastInteraction = item.lastInteractionContext {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 11))

                            Text("Dernier contact : \(lastInteraction)")
                                .font(DesignTokens.Typography.caption2)
                        }
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                        .padding(.top, 2)
                    }

                    // Status message
                    statusMessage
                        .padding(.top, 4)
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
                            : statusColor.opacity(0.5),
                        lineWidth: item.isRead ? 1 : 1.5
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.large))
    }

    // MARK: - Status Message

    @ViewBuilder
    private var statusMessage: some View {
        switch item.pulseStatus {
        case .dormant:
            HStack(spacing: 6) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 12))

                Text("Cette connexion s'éloigne de ton réseau")
                    .font(DesignTokens.Typography.caption1)
            }
            .foregroundStyle(DesignTokens.Colors.warning)

        case .atRisk:
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))

                Text("Connexion à risque - reprends contact !")
                    .font(DesignTokens.Typography.caption1)
            }
            .foregroundStyle(DesignTokens.Colors.error)

        default:
            EmptyView()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 16) {
            NetworkPulseCard(item: FeedItem.mockItems[5]) { }
            NetworkPulseCard(item: FeedItem.mockItems[6]) { }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
