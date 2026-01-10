import SwiftUI

// MARK: - UserFoundView
/// Vue affichée quand un utilisateur CirKL est détecté à proximité
struct UserFoundView: View {

    // MARK: - Properties
    let peerName: String
    let onConnect: () -> Void

    @State private var appearAnimation = false

    // MARK: - Body
    var body: some View {
        VStack(spacing: 32) {
            // User card
            userCard

            // Instructions
            instructionsView

            // Connect button
            connectButton
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appearAnimation = true
            }
        }
    }

    // MARK: - User Card
    private var userCard: some View {
        VStack(spacing: 20) {
            // Avatar with glow
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.mint.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)

                // Avatar circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.mint, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                    .overlay(
                        Text(peerName.prefix(1).uppercased())
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.white)
                    )
            }
            .scaleEffect(appearAnimation ? 1.0 : 0.5)
            .opacity(appearAnimation ? 1 : 0)

            // Name
            VStack(spacing: 8) {
                Text(peerName)
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                // Status badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)

                    Text("À proximité")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.green.opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .offset(y: appearAnimation ? 0 : 30)
    }

    // MARK: - Instructions
    private var instructionsView: some View {
        VStack(spacing: 12) {
            // Arrow animation
            Image(systemName: "arrow.down.circle.fill")
                .font(.title)
                .foregroundStyle(.mint.opacity(0.6))
                .offset(y: appearAnimation ? 5 : 0)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: appearAnimation
                )

            Text("Rapprochez vos téléphones")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Placez vos téléphones côte à côte pour vérifier la rencontre")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .opacity(appearAnimation ? 1 : 0)
    }

    // MARK: - Connect Button
    private var connectButton: some View {
        Button(action: onConnect) {
            HStack(spacing: 12) {
                Image(systemName: "link")
                    .font(.headline)

                Text("Connecter")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 48)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0, green: 0.78, blue: 0.51),
                        Color(red: 0, green: 0.48, blue: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .mint.opacity(0.4), radius: 15, y: 5)
        }
        .scaleEffect(appearAnimation ? 1.0 : 0.8)
        .opacity(appearAnimation ? 1 : 0)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(red: 0.04, green: 0.05, blue: 0.15)
            .ignoresSafeArea()

        UserFoundView(
            peerName: "Marie Dupont",
            onConnect: {}
        )
    }
}
