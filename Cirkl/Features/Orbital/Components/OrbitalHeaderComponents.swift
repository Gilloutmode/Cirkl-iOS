import SwiftUI

// MARK: - Header
struct OrbitalHeaderView: View {
    @Binding var selectedMode: OrbitalViewMode
    let verifiedCount: Int
    let pendingCount: Int
    let invitedCount: Int  // Nombre d'invitations envoyees (en attente)
    let onAddTap: () -> Void
    let onSettingsTap: () -> Void  // Callback pour ouvrir les reglages
    let onConnectionsTap: () -> Void  // Callback pour ouvrir la liste des connexions

    var body: some View {
        ZStack {
            // === LOGO CIRKL CENTRE - ADAPTIVE (light/dark mode) ===
            Text("Cirkl")
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary.opacity(0.9), .primary.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            HStack {
                // Toggle badges a gauche (interactifs) - tap pour toggle ET ouvrir la liste
                HStack(spacing: 8) {
                    // Toggle des modes avec callback pour ouvrir la liste
                    ModeToggleGroup(
                        selectedMode: $selectedMode,
                        verifiedCount: verifiedCount,
                        pendingCount: pendingCount,
                        onBadgeTap: onConnectionsTap
                    )

                    // Badge invitations envoyees (si > 0)
                    if invitedCount > 0 {
                        InvitationsSentBadge(count: invitedCount)
                            .onTapGesture {
                                // Basculer vers le mode pending et ouvrir la liste
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    selectedMode = .pending
                                }
                                onConnectionsTap()
                            }
                    }
                }

                Spacer()

                // Bouton ajouter connexion
                Button(action: onAddTap) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.78, blue: 0.51),  // Mint
                                    Color(red: 0.0, green: 0.48, blue: 1.0)   // Blue
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: Color(red: 0.0, green: 0.78, blue: 0.51).opacity(0.3), radius: 8, y: 4)

                // === BOUTON SETTINGS - ADAPTIVE (light/dark mode) ===
                Button(action: {
                    CirklHaptics.selection()
                    onSettingsTap()
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.primary.opacity(0.08)))
                .contentShape(Circle())
            }
        }
        .frame(height: 44)
    }
}

// MARK: - Invitations Sent Badge
/// Petit badge affichant le nombre d'invitations envoyees (en attente de confirmation)
struct InvitationsSentBadge: View {
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "paperplane.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            Text("\(count)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassEffect(.regular, in: .capsule)
        .overlay(
            Capsule()
                .stroke(
                    Color.white.opacity(0.2),
                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                )
        )
    }
}

// MARK: - Search Bar
struct OrbitalSearchBarView: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.secondary)

            TextField("Rechercher une connexion...", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(.primary)

            // Clear button when text is present
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            // CRITICAL FIX: Use ultraThinMaterial instead of glassEffect
            // glassEffect blocks touch events on iOS 26 real devices
            Capsule()
                .fill(Color.primary.opacity(0.04))
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
    }
}
