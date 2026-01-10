import SwiftUI
import MultipeerConnectivity

// MARK: - ProximityDetectionView
/// Vue d'animation radar pour la recherche d'utilisateurs CirKL à proximité
struct ProximityDetectionView: View {

    // MARK: - Properties
    let nearbyUsers: [MCPeerID]
    let onUserSelected: (MCPeerID) -> Void

    @State private var radarPulse = false
    @State private var rotation: Double = 0

    // MARK: - Body
    var body: some View {
        VStack(spacing: 32) {
            // Radar animation
            ZStack {
                // Background circles
                radarBackground

                // Scanning line
                radarScanLine

                // Center user avatar
                centerAvatar

                // Detected users dots
                detectedUsersDots
            }
            .frame(width: 280, height: 280)

            // Status text
            VStack(spacing: 8) {
                Text("Recherche en cours...")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(nearbyUsers.isEmpty
                    ? "Rapprochez-vous d'un utilisateur CirKL"
                    : "\(nearbyUsers.count) utilisateur(s) détecté(s)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }

            // Detected users list
            if !nearbyUsers.isEmpty {
                detectedUsersList
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Radar Background
    private var radarBackground: some View {
        ZStack {
            // Concentric circles
            ForEach(1..<5, id: \.self) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .mint.opacity(0.3 - Double(index) * 0.05),
                                .blue.opacity(0.2 - Double(index) * 0.03)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .frame(
                        width: CGFloat(60 + index * 55),
                        height: CGFloat(60 + index * 55)
                    )
            }

            // Pulsing outer ring
            Circle()
                .stroke(.mint.opacity(0.4), lineWidth: 2)
                .frame(width: 280, height: 280)
                .scaleEffect(radarPulse ? 1.1 : 1.0)
                .opacity(radarPulse ? 0 : 1)
                .animation(
                    .easeOut(duration: 1.5)
                    .repeatForever(autoreverses: false),
                    value: radarPulse
                )
        }
    }

    // MARK: - Radar Scan Line
    private var radarScanLine: some View {
        ZStack {
            // Gradient sweep
            AngularGradient(
                gradient: Gradient(colors: [
                    .clear,
                    .mint.opacity(0.1),
                    .mint.opacity(0.3),
                    .mint.opacity(0.5),
                    .clear
                ]),
                center: .center,
                startAngle: .degrees(rotation - 45),
                endAngle: .degrees(rotation)
            )
            .frame(width: 260, height: 260)
            .mask(Circle())
            .rotationEffect(.degrees(rotation))

            // Scan line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.mint, .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: 2, height: 130)
                .offset(y: -65)
                .rotationEffect(.degrees(rotation))
        }
        .animation(
            .linear(duration: 3)
            .repeatForever(autoreverses: false),
            value: rotation
        )
    }

    // MARK: - Center Avatar
    private var centerAvatar: some View {
        ZStack {
            // Glow
            Circle()
                .fill(.mint.opacity(0.2))
                .frame(width: 70, height: 70)
                .blur(radius: 10)

            // Glass circle
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 60, height: 60)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 0.5)
                )

            // Icon
            Image(systemName: "person.fill")
                .font(.system(size: 24))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Detected Users Dots
    private var detectedUsersDots: some View {
        ForEach(Array(nearbyUsers.enumerated()), id: \.element.displayName) { index, peer in
            let angle = Double(index) * (360.0 / max(Double(nearbyUsers.count), 1))
            let radius: CGFloat = 100

            UserDot(name: peer.displayName)
                .offset(
                    x: cos(angle * .pi / 180) * radius,
                    y: sin(angle * .pi / 180) * radius
                )
                .onTapGesture {
                    onUserSelected(peer)
                }
        }
    }

    // MARK: - Detected Users List
    private var detectedUsersList: some View {
        VStack(spacing: 12) {
            ForEach(nearbyUsers, id: \.displayName) { peer in
                Button {
                    onUserSelected(peer)
                } label: {
                    HStack {
                        // Avatar
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundStyle(.white.opacity(0.8))
                            )

                        // Name
                        Text(peer.displayName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)

                        Spacer()

                        // Connect button
                        Text("Connecter")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.mint)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.mint.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    )
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Animations
    private func startAnimations() {
        radarPulse = true

        // Continuous rotation
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }
}

// MARK: - User Dot
private struct UserDot: View {
    let name: String
    @State private var pulse = false

    var body: some View {
        ZStack {
            // Pulse effect
            Circle()
                .fill(.mint.opacity(0.3))
                .frame(width: 24, height: 24)
                .scaleEffect(pulse ? 1.5 : 1.0)
                .opacity(pulse ? 0 : 1)

            // Dot
            Circle()
                .fill(.mint)
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.5), lineWidth: 1)
                )

            // Name label
            Text(name.prefix(2).uppercased())
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(red: 0.04, green: 0.05, blue: 0.15)
            .ignoresSafeArea()

        ProximityDetectionView(
            nearbyUsers: [],
            onUserSelected: { _ in }
        )
    }
}
