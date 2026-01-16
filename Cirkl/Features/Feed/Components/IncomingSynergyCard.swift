import SwiftUI

// MARK: - Incoming Synergy Card (🤝)
/// Card pour recevoir une mise en relation d'un autre utilisateur
/// Affiche: Introducteur + Personne présentée + Message + Actions Accept/Decline

struct IncomingSynergyCard: View {

    let item: FeedItem
    let isLoading: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void

    private let themeColor = DesignTokens.Colors.success

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Header
            headerSection

            // Introducer info
            Text("\(item.introducerName ?? "Quelqu'un") veut te présenter :")
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            // Introduced person card
            introducedPersonSection

            // Introduction message
            if let message = item.introductionMessage {
                messageSection(message)
            }

            // Action buttons
            actionsSection
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                .fill(DesignTokens.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                .strokeBorder(
                    item.isRead ? DesignTokens.Colors.cardBorder : themeColor.opacity(0.5),
                    lineWidth: item.isRead ? 1 : 1.5
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Text("🤝")
                    .font(.system(size: 16))
                Text("MISE EN RELATION")
                    .font(DesignTokens.Typography.caption1)
                    .fontWeight(.semibold)
                    .foregroundStyle(themeColor)
            }

            Spacer()

            Text(item.relativeTimestamp)
                .font(DesignTokens.Typography.caption2)
                .foregroundStyle(DesignTokens.Colors.textTertiary)

            if !item.isRead {
                Circle()
                    .fill(themeColor)
                    .frame(width: 10, height: 10)
            }
        }
    }

    // MARK: - Introduced Person Section

    private var introducedPersonSection: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Avatar
            Circle()
                .fill(themeColor.opacity(0.15))
                .frame(width: 56, height: 56)
                .overlay(
                    Text((item.introducedPersonName ?? "?").prefix(1).uppercased())
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.introducedPersonName ?? "Connexion")
                    .font(DesignTokens.Typography.headline)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                if let role = item.introducedPersonRole {
                    Text(role)
                        .font(DesignTokens.Typography.caption1)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }

                if let location = item.introducedPersonLocation {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 10))
                        Text(location)
                            .font(DesignTokens.Typography.caption2)
                    }
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
            }

            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small)
                .fill(DesignTokens.Colors.cardBackgroundElevated)
        )
    }

    // MARK: - Message Section

    private func messageSection(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("💬")
                .font(.system(size: 14))
            Text("\"\(message)\"")
                .font(DesignTokens.Typography.body)
                .italic()
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Accept button
            Button {
                CirklHaptics.medium()
                onAccept()
            } label: {
                HStack(spacing: 6) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .medium))
                    }
                    Text(isLoading ? "..." : "Accepter")
                        .font(DesignTokens.Typography.buttonSmall)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(
                    Capsule().fill(themeColor)
                )
            }
            .buttonStyle(.plain)
            .disabled(isLoading)

            // Decline button
            Button {
                CirklHaptics.light()
                onDecline()
            } label: {
                Text("Plus tard")
                    .font(DesignTokens.Typography.buttonSmall)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(
                        Capsule()
                            .strokeBorder(DesignTokens.Colors.textTertiary.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 16) {
            IncomingSynergyCard(
                item: FeedItem.mockItems[0],
                isLoading: false,
                onAccept: { },
                onDecline: { }
            )

            IncomingSynergyCard(
                item: FeedItem.mockItems[0],
                isLoading: true,
                onAccept: { },
                onDecline: { }
            )
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
