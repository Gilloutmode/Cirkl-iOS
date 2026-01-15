import SwiftUI

// MARK: - Pulse Connection Row
/// Affiche une connexion avec son statut et suggestion IA
/// Actions: Copier suggestion, Ouvrir Messages, Ignorer

struct PulseConnectionRow: View {

    let connection: NetworkPulseViewModel.PulseConnection
    let onRequestSuggestion: () -> Void
    let onCopySuggestion: (String) -> Void
    let onOpenMessages: (String) -> Void
    let onDismiss: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            Button {
                withAnimation(DesignTokens.Animations.spring) {
                    isExpanded.toggle()
                    if isExpanded && connection.suggestion == nil && !connection.isLoadingSuggestion {
                        onRequestSuggestion()
                    }
                }
            } label: {
                mainRowContent
            }
            .buttonStyle(.plain)

            // Expanded suggestion section
            if isExpanded {
                suggestionSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.medium)
                .fill(connection.status.color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.medium)
                        .strokeBorder(connection.status.color.opacity(0.2), lineWidth: 1)
                )
        }
    }

    // MARK: - Main Row Content

    private var mainRowContent: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Avatar placeholder
            Circle()
                .fill(
                    LinearGradient(
                        colors: [connection.status.color.opacity(0.3), connection.status.color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
                .overlay(
                    Text(connection.name.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(connection.status.color)
                )

            // Name and info
            VStack(alignment: .leading, spacing: 4) {
                Text(connection.name)
                    .font(DesignTokens.Typography.headline)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                if !connection.displayRole.isEmpty {
                    Text(connection.displayRole)
                        .font(DesignTokens.Typography.caption1)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Status badge
            VStack(alignment: .trailing, spacing: 4) {
                Text(connection.status.emoji)
                    .font(.system(size: 16))

                Text(connection.lastInteractionText)
                    .font(DesignTokens.Typography.caption2)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            // Chevron
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
    }

    // MARK: - Suggestion Section

    @ViewBuilder
    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Divider()
                .background(connection.status.color.opacity(0.2))
                .padding(.vertical, DesignTokens.Spacing.sm)

            if connection.isLoadingSuggestion {
                // Loading state
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)

                    Text("L'IA prépare une suggestion...")
                        .font(DesignTokens.Typography.footnote)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                .padding(.vertical, DesignTokens.Spacing.sm)
            } else if let suggestion = connection.suggestion {
                // Suggestion content
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    // Suggestion text
                    Text(suggestion)
                        .font(DesignTokens.Typography.body)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .padding(DesignTokens.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.small)
                                .fill(DesignTokens.Colors.surface)
                        )

                    // Action buttons
                    HStack(spacing: DesignTokens.Spacing.md) {
                        // Copy button
                        Button {
                            onCopySuggestion(suggestion)
                        } label: {
                            Label("Copier", systemImage: "doc.on.doc")
                                .font(DesignTokens.Typography.buttonSmall)
                        }
                        .buttonStyle(PulseActionButtonStyle(color: DesignTokens.Colors.electricBlue))

                        // Open Messages button
                        Button {
                            onOpenMessages(connection.name)
                        } label: {
                            Label("Messages", systemImage: "message.fill")
                                .font(DesignTokens.Typography.buttonSmall)
                        }
                        .buttonStyle(PulseActionButtonStyle(color: DesignTokens.Colors.mint))

                        Spacer()

                        // Dismiss button
                        Button {
                            onDismiss()
                            withAnimation {
                                isExpanded = false
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(DesignTokens.Colors.textTertiary)
                        }
                    }
                }
            } else {
                // No suggestion yet - tap to request
                Button {
                    onRequestSuggestion()
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Demander une suggestion IA")
                    }
                    .font(DesignTokens.Typography.buttonSmall)
                    .foregroundStyle(DesignTokens.Colors.electricBlue)
                }
                .padding(.vertical, DesignTokens.Spacing.sm)
            }
        }
    }
}

// MARK: - Action Button Style

private struct PulseActionButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(color)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                Capsule()
                    .fill(color.opacity(0.1))
                    .overlay(
                        Capsule()
                            .strokeBorder(color.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 16) {
            PulseConnectionRow(
                connection: .init(
                    id: "1",
                    name: "Denis Martin",
                    role: "Designer",
                    company: "Studio Créatif",
                    lastInteraction: Calendar.current.date(byAdding: .day, value: -15, to: Date()),
                    status: .dormant,
                    suggestion: "Hey Denis ! Ça fait un moment qu'on ne s'est pas parlé. J'ai vu que ton projet avance bien, on pourrait se faire un café pour en discuter ?"
                ),
                onRequestSuggestion: {},
                onCopySuggestion: { _ in },
                onOpenMessages: { _ in },
                onDismiss: {}
            )

            PulseConnectionRow(
                connection: .init(
                    id: "2",
                    name: "Sarah Chen",
                    role: "CEO",
                    company: "TechStart",
                    lastInteraction: Calendar.current.date(byAdding: .day, value: -45, to: Date()),
                    status: .atRisk
                ),
                onRequestSuggestion: {},
                onCopySuggestion: { _ in },
                onOpenMessages: { _ in },
                onDismiss: {}
            )
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
