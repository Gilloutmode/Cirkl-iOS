//
//  CirklEmptyState.swift
//  Cirkl
//
//  Created by Claude on 12/01/2026.
//

import SwiftUI

// MARK: - Empty State Component

/// A reusable empty state component following Cirkl design system
/// Used when content is unavailable or a list is empty
struct CirklEmptyState: View {

    // MARK: - Properties

    /// SF Symbol name for the icon
    let icon: String

    /// Main title text
    let title: String

    /// Descriptive message text
    let message: String

    /// Call-to-action button title (optional)
    let ctaTitle: String?

    /// Call-to-action button action (optional)
    let ctaAction: (() -> Void)?

    /// Style variant
    var style: EmptyStateStyle = .standard

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - State

    @State private var isAnimating = false

    // MARK: - Initialization

    init(
        icon: String,
        title: String,
        message: String,
        ctaTitle: String? = nil,
        ctaAction: (() -> Void)? = nil,
        style: EmptyStateStyle = .standard
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.ctaTitle = ctaTitle
        self.ctaAction = ctaAction
        self.style = style
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Icon
            iconView

            // Text Content
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(title)
                    .font(DesignTokens.Typography.title2)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)

            // CTA Button (if provided)
            if let ctaTitle = ctaTitle, let ctaAction = ctaAction {
                Button(action: {
                    CirklHaptics.medium()
                    ctaAction()
                }) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Text(ctaTitle)
                            .font(DesignTokens.Typography.button)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.vertical, DesignTokens.Spacing.md)
                    .background(
                        LinearGradient(
                            colors: [DesignTokens.Colors.electricBlue, DesignTokens.Colors.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(ctaTitle)
                .accessibilityHint("Double-tap pour effectuer cette action")
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity)
        .onAppear {
            if !reduceMotion {
                withAnimation(
                    .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }

    // MARK: - Icon View

    @ViewBuilder
    private var iconView: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            style.accentColor.opacity(0.3),
                            style.accentColor.opacity(0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .scaleEffect(isAnimating ? 1.1 : 1.0)

            // Icon container
            Circle()
                .fill(style.accentColor.opacity(0.15))
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(style.accentColor)
                        .symbolEffect(.pulse, options: .repeating, isActive: !reduceMotion)
                }
        }
        .accessibilityHidden(true)
    }

}

// MARK: - Empty State Style

enum EmptyStateStyle {
    case standard
    case orbital
    case chat
    case connections
    case search

    var accentColor: Color {
        switch self {
        case .standard:
            return DesignTokens.Colors.electricBlue
        case .orbital:
            return DesignTokens.Colors.purple
        case .chat:
            return DesignTokens.Colors.mint
        case .connections:
            return DesignTokens.Colors.pink
        case .search:
            return DesignTokens.Colors.electricBlue
        }
    }
}

// MARK: - Convenience Initializers

extension CirklEmptyState {

    /// Empty state for orbital view (no connections)
    static func orbital(onImport: @escaping () -> Void) -> CirklEmptyState {
        CirklEmptyState(
            icon: "globe.europe.africa",
            title: "Votre orbite est vide",
            message: "Importez vos contacts ou scannez un QR pour créer votre première connexion authentique.",
            ctaTitle: "Importer mes contacts",
            ctaAction: onImport,
            style: .orbital
        )
    }

    /// Empty state for chat view (no messages)
    static func chat(onStart: @escaping () -> Void) -> CirklEmptyState {
        CirklEmptyState(
            icon: "bubble.left.and.bubble.right",
            title: "Aucune conversation",
            message: "Posez votre première question à votre compagnon relationnel.",
            ctaTitle: "Commencer",
            ctaAction: onStart,
            style: .chat
        )
    }

    /// Empty state for search results
    static var noSearchResults: CirklEmptyState {
        CirklEmptyState(
            icon: "magnifyingglass",
            title: "Aucun résultat",
            message: "Essayez avec d'autres termes de recherche.",
            style: .search
        )
    }

    /// Empty state for connections list
    static func connections(onAdd: @escaping () -> Void) -> CirklEmptyState {
        CirklEmptyState(
            icon: "person.2",
            title: "Aucune connexion",
            message: "Ajoutez votre premier contact pour commencer à construire votre réseau.",
            ctaTitle: "Ajouter un contact",
            ctaAction: onAdd,
            style: .connections
        )
    }

    /// Empty state for pending invitations
    static var noPendingInvitations: CirklEmptyState {
        CirklEmptyState(
            icon: "envelope.open",
            title: "Aucune invitation",
            message: "Vous n'avez pas d'invitations en attente pour le moment.",
            style: .standard
        )
    }
}

// MARK: - Preview

#Preview("Standard Empty State") {
    ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()

        CirklEmptyState(
            icon: "tray",
            title: "Rien ici",
            message: "Cet espace est vide pour le moment.",
            ctaTitle: "Ajouter quelque chose",
            ctaAction: { print("CTA tapped") }
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Orbital Empty State") {
    ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()

        CirklEmptyState.orbital(onImport: { print("Import tapped") })
    }
    .preferredColorScheme(.dark)
}

#Preview("Chat Empty State") {
    ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()

        CirklEmptyState.chat(onStart: { print("Start tapped") })
    }
    .preferredColorScheme(.dark)
}
