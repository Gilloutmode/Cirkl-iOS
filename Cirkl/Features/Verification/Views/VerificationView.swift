import SwiftUI

// MARK: - VerificationView
/// Vue principale de vérification de rencontre physique
/// Point d'entrée du flow de vérification par proximité
struct VerificationView: View {

    // MARK: - Properties
    @State private var viewModel = VerificationViewModel()
    @State private var showQRFallback = false
    @Environment(\.dismiss) private var dismiss

    let currentUser: User
    let onVerificationComplete: (Connection) -> Void

    // MARK: - Body
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient

            VStack(spacing: 0) {
                // Header
                headerView

                Spacer()

                // Content based on state
                contentView

                Spacer()

                // Bottom actions
                bottomActionsView
            }
            .padding()
        }
        .onAppear {
            viewModel.configure(
                userId: currentUser.id.uuidString,
                userName: currentUser.name,
                avatarURL: currentUser.avatarURL
            )
            viewModel.onVerificationComplete = onVerificationComplete
        }
        .onDisappear {
            viewModel.stopScanning()
        }
        .sheet(isPresented: $showQRFallback) {
            QRFallbackView(viewModel: viewModel)
        }
    }

    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.05, blue: 0.15),
                Color(red: 0.02, green: 0.03, blue: 0.10)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Text(viewModel.state.title)
                .font(.headline)
                .foregroundStyle(.white)

            Spacer()

            // Placeholder for balance
            Color.clear
                .frame(width: 28, height: 28)
        }
        .padding(.vertical)
    }

    // MARK: - Content
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle:
            IdleStateView {
                viewModel.startScanning()
            }

        case .scanning:
            ProximityDetectionView(
                nearbyUsers: viewModel.nearbyUsers,
                onUserSelected: { peer in
                    viewModel.connectTo(peer)
                }
            )

        case .found(let peerName):
            UserFoundView(
                peerName: peerName,
                onConnect: {
                    if let peer = viewModel.nearbyUsers.first {
                        viewModel.connectTo(peer)
                    }
                }
            )

        case .connecting, .measuring:
            MeasuringView(
                distance: viewModel.currentDistance,
                isUWBAvailable: viewModel.isUWBAvailable
            )

        case .verified(let distance):
            VerificationSuccessView(
                distance: distance,
                onComplete: {
                    viewModel.finalizeVerification()
                    dismiss()
                }
            )

        case .error(let message):
            ErrorStateView(
                message: message,
                onRetry: { viewModel.retry() }
            )
        }
    }

    // MARK: - Bottom Actions
    @ViewBuilder
    private var bottomActionsView: some View {
        if case .scanning = viewModel.state {
            VStack(spacing: 16) {
                // QR Fallback button (fix: glassEffect blocks taps)
                Button {
                    showQRFallback = true
                } label: {
                    HStack {
                        Image(systemName: "qrcode")
                        Text("Utiliser un QR Code")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.15))
                    )
                }
                .contentShape(RoundedRectangle(cornerRadius: 20))

                // Cancel button
                Button {
                    viewModel.stopScanning()
                } label: {
                    Text("Annuler")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Idle State View
private struct IdleStateView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            // Icon with Liquid Glass
            Image(systemName: "person.2.wave.2")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.mint, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .background(Color.mint.opacity(0.1))
                .clipShape(Circle())
                .glassEffect(.regular, in: .circle)

            // Text
            VStack(spacing: 12) {
                Text("Vérifier une rencontre")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("Rapprochez-vous de la personne que vous venez de rencontrer pour vérifier votre connexion.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Start button
            Button(action: onStart) {
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Commencer")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0, green: 0.78, blue: 0.51), Color(red: 0, green: 0.48, blue: 1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Measuring View
private struct MeasuringView: View {
    let distance: Float?
    let isUWBAvailable: Bool

    var body: some View {
        VStack(spacing: 24) {
            // Animated measuring indicator
            ZStack {
                // Pulsing circles
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(.mint.opacity(0.3), lineWidth: 2)
                        .frame(width: CGFloat(80 + index * 40), height: CGFloat(80 + index * 40))
                        .scaleEffect(1.0)
                        .opacity(0.8 - Double(index) * 0.2)
                }

                // Center icon with Liquid Glass
                Image(systemName: "wave.3.right")
                    .font(.system(size: 32))
                    .foregroundStyle(.mint)
                    .frame(width: 80, height: 80)
                    .background(Color.mint.opacity(0.1))
                    .clipShape(Circle())
                    .glassEffect(.regular, in: .circle)
            }

            // Status text
            VStack(spacing: 8) {
                Text(isUWBAvailable ? "Mesure de distance..." : "Connexion en cours...")
                    .font(.headline)
                    .foregroundStyle(.white)

                if let distance = distance {
                    Text(formatDistance(distance))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(distanceColor(distance))
                }

                Text("Gardez vos téléphones proches")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private func formatDistance(_ distance: Float) -> String {
        if distance < 1.0 {
            return String(format: "%.0f cm", distance * 100)
        } else {
            return String(format: "%.1f m", distance)
        }
    }

    private func distanceColor(_ distance: Float) -> Color {
        if distance < 0.5 {
            return .green
        } else if distance < 1.0 {
            return .yellow
        } else {
            return .orange
        }
    }
}

// MARK: - Error State View
private struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text("Une erreur est survenue")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Réessayer")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.15))
                )
            }
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

// MARK: - Preview
#Preview {
    VerificationView(
        currentUser: User(
            id: UUID(),
            name: "Test User",
            email: "test@example.com"
        ),
        onVerificationComplete: { _ in }
    )
}
