import SwiftUI

// MARK: - Synergy Card (🔮)
/// Card pour les synergies détectées par l'IA
/// Affiche: 2 personnes + match + BOUTONS D'ACTION

struct SynergyCard: View {

    let item: FeedItem
    let isLoading: Bool
    let onCreateConnection: () -> Void
    let onDismiss: () -> Void

    init(item: FeedItem, isLoading: Bool = false, onCreateConnection: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.item = item
        self.isLoading = isLoading
        self.onCreateConnection = onCreateConnection
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Header
            HStack {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Text("🔮")
                        .font(.system(size: 16))

                    Text("SYNERGIE DÉTECTÉE")
                        .font(DesignTokens.Typography.caption1)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignTokens.Colors.purple)
                }

                Spacer()

                Text(item.relativeTimestamp)
                    .font(DesignTokens.Typography.caption2)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)

                // Unread indicator
                if !item.isRead {
                    Circle()
                        .fill(DesignTokens.Colors.purple)
                        .frame(width: 10, height: 10)
                }
            }

            // Synergy content box
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                // Person 1
                if let person1Name = item.synergyPerson1Name,
                   let person1Action = item.synergyPerson1 {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        personAvatar(name: person1Name, color: DesignTokens.Colors.electricBlue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(person1Name)
                                .font(DesignTokens.Typography.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(DesignTokens.Colors.textPrimary)

                            Text(person1Action)
                                .font(DesignTokens.Typography.caption1)
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                        }
                    }
                }

                // Match indicator
                if let match = item.synergyMatch {
                    HStack {
                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 10))

                            Text(match)
                                .font(DesignTokens.Typography.caption2)
                        }
                        .foregroundStyle(DesignTokens.Colors.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(DesignTokens.Colors.purple.opacity(0.15))
                        )

                        Spacer()
                    }
                }

                // Person 2
                if let person2Name = item.synergyPerson2Name,
                   let person2Action = item.synergyPerson2 {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        personAvatar(name: person2Name, color: DesignTokens.Colors.success)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(person2Name)
                                .font(DesignTokens.Typography.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(DesignTokens.Colors.textPrimary)

                            Text(person2Action)
                                .font(DesignTokens.Typography.caption1)
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                        }
                    }
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(synergyBoxBackground)

            // Action buttons
            HStack(spacing: DesignTokens.Spacing.md) {
                // Primary action: Create connection
                Button(action: {
                    onCreateConnection()
                }) {
                    HStack(spacing: 6) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "link")
                                .font(.system(size: 14, weight: .medium))
                        }

                        Text(isLoading ? "Création..." : "Créer la connexion")
                            .font(DesignTokens.Typography.buttonSmall)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(
                        Capsule()
                            .fill(isLoading ? DesignTokens.Colors.purple.opacity(0.6) : DesignTokens.Colors.purple)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isLoading)

                // Secondary action: Dismiss
                Button(action: {
                    CirklHaptics.light()
                    onDismiss()
                }) {
                    Text("Pas maintenant")
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
                .opacity(isLoading ? 0.5 : 1.0)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background { glassBackground }
    }

    // MARK: - Person Avatar

    private func personAvatar(name: String, color: Color) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.3), color.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 36, height: 36)
            .overlay(
                Text(name.prefix(1).uppercased())
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
            )
    }

    // MARK: - Synergy Box Background

    @ViewBuilder
    private var synergyBoxBackground: some View {
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small)
                .fill(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: DesignTokens.Radius.small))
        } else {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small)
                .fill(DesignTokens.Colors.surface.opacity(0.5))
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
                                : DesignTokens.Colors.purple.opacity(0.4),
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
                                : DesignTokens.Colors.purple.opacity(0.4),
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
            SynergyCard(
                item: FeedItem.mockItems[3],
                onCreateConnection: { print("Create!") },
                onDismiss: { print("Dismiss") }
            )
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
