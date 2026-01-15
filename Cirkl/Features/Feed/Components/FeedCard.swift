import SwiftUI

// MARK: - Feed Card
/// Card d'actualité avec avatar, titre, message et timestamp
/// Style Instagram notifications avec Liquid Glass

struct FeedCard: View {

    let item: FeedItem
    let onTap: () -> Void

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

                        Text(item.title)
                            .font(DesignTokens.Typography.headline)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                    }

                    // Message
                    Text(item.message)
                        .font(DesignTokens.Typography.body)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    // Connection context + timestamp
                    HStack {
                        if let connectionName = item.connectionName {
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
