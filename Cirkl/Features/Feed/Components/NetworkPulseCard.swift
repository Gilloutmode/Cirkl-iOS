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
        Button(action: onTap) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                // Status indicator + Avatar
                ZStack(alignment: .bottomTrailing) {
                    // Avatar
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [statusColor.opacity(0.3), statusColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
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
            .background { glassBackground }
        }
        .buttonStyle(.plain)
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
                                : statusColor.opacity(0.4),
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
                                : statusColor.opacity(0.4),
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
            NetworkPulseCard(item: FeedItem.mockItems[5]) { }
            NetworkPulseCard(item: FeedItem.mockItems[6]) { }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
