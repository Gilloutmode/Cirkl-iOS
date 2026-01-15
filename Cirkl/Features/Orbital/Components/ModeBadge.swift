import SwiftUI

// MARK: - ModeBadge
/// Badge toggle interactif pour switcher entre les modes d'affichage orbital
struct ModeBadge: View {
    let mode: OrbitalViewMode
    let count: Int
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            CirklHaptics.modeToggle()
            action()
        }) {
            HStack(spacing: 6) {
                // Icône avec animation
                Image(systemName: mode.icon)
                    .font(.system(size: isActive ? 12 : 11, weight: .semibold))
                    .foregroundStyle(isActive ? .white : mode.color)

                // Compteur
                Text("\(count)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(isActive ? .white : .white.opacity(0.7))
            }
            .padding(.horizontal, isActive ? 14 : 12)
            .padding(.vertical, isActive ? 10 : 8)
            .background(badgeBackground)
            .clipShape(Capsule())
            .shadow(
                color: isActive ? mode.color.opacity(0.35) : .clear,
                radius: isActive ? 8 : 0,
                y: isActive ? 3 : 0
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isActive)
    }

    @ViewBuilder
    private var badgeBackground: some View {
        if isActive {
            // Background actif: gradient avec glow
            mode.activeGradient
        } else {
            // === LIQUID GLASS: Native glassEffect pour badges inactifs ===
            if mode == .pending {
                // Style pointillé glass pour pending
                Capsule()
                    .fill(Color.primary.opacity(0.04))
                    .glassEffect(.regular, in: .capsule)
                    .overlay(
                        Capsule()
                            .stroke(
                                mode.color.opacity(0.4),
                                style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                            )
                    )
            } else {
                // Style glass pour verified
                Capsule()
                    .fill(Color.primary.opacity(0.04))
                    .glassEffect(.regular, in: .capsule)
                    .overlay(
                        Capsule()
                            .stroke(DesignTokens.Colors.textPrimary.opacity(0.15), lineWidth: 0.5)
                    )
            }
        }
    }
}

// MARK: - ModeToggleGroup
/// Groupe de toggles pour basculer entre les modes
struct ModeToggleGroup: View {
    @Binding var selectedMode: OrbitalViewMode
    let verifiedCount: Int
    let pendingCount: Int
    var onBadgeTap: (() -> Void)? = nil  // Callback optionnel appelé quand un badge est tappé

    var body: some View {
        HStack(spacing: 10) {
            // Badge vérifiés
            ModeBadge(
                mode: .verified,
                count: verifiedCount,
                isActive: selectedMode == .verified,
                action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        selectedMode = .verified
                    }
                    onBadgeTap?()
                }
            )

            // Badge en attente (seulement si > 0)
            if pendingCount > 0 {
                ModeBadge(
                    mode: .pending,
                    count: pendingCount,
                    isActive: selectedMode == .pending,
                    action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            selectedMode = .pending
                        }
                        onBadgeTap?()
                    }
                )
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        // === DARK MODE PREVIEW BACKGROUND ===
        DesignTokens.Colors.background.ignoresSafeArea()

        VStack(spacing: 40) {
            // États individuels
            Text("États individuels").font(.headline)

            HStack(spacing: 20) {
                ModeBadge(mode: .verified, count: 8, isActive: true, action: {})
                ModeBadge(mode: .verified, count: 8, isActive: false, action: {})
            }

            HStack(spacing: 20) {
                ModeBadge(mode: .pending, count: 2, isActive: true, action: {})
                ModeBadge(mode: .pending, count: 2, isActive: false, action: {})
            }

            // Toggle group
            Text("Toggle Group").font(.headline)

            PreviewModeToggle()
        }
    }
}

private struct PreviewModeToggle: View {
    @State private var mode: OrbitalViewMode = .verified

    var body: some View {
        VStack(spacing: 20) {
            ModeToggleGroup(
                selectedMode: $mode,
                verifiedCount: 8,
                pendingCount: 2
            )

            Text("Mode sélectionné: \(mode.shortLabel)")
                .foregroundStyle(.secondary)
        }
    }
}
