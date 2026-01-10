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
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
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
                    .foregroundStyle(isActive ? .white : Color(white: 0.35))
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
            // Background inactif: style différent selon le mode
            if mode == .pending {
                // Style pointillé pour pending
                ZStack {
                    Capsule()
                        .fill(Color.white.opacity(0.9))
                    Capsule()
                        .stroke(
                            mode.color.opacity(0.4),
                            style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                        )
                }
            } else {
                // Style solide pour verified
                Capsule()
                    .fill(Color(white: 0.95))
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
                    }
                )
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(white: 0.98).ignoresSafeArea()

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
