import SwiftUI
import ConfettiSwiftUI

// MARK: - VerificationSuccessView
/// Vue de confirmation affichée après une vérification réussie
struct VerificationSuccessView: View {

    // MARK: - Properties
    let distance: Float?
    let onComplete: () -> Void
    var isFirstConnection: Bool = false

    // MARK: - Accessibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var checkmarkScale: CGFloat = 0
    @State private var ringScale: CGFloat = 0
    @State private var contentOpacity: Double = 0
    @State private var confettiCounter = 0
    @State private var showFirstConnectionBadge = false

    // MARK: - Body
    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Success animation
            successAnimation

            // Content
            successContent

            Spacer()

            // Complete button
            completeButton
        }
        .padding()
        .onAppear {
            runAnimations()
        }
    }

    // MARK: - Success Animation
    private var successAnimation: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.mint, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: 140, height: 140)
                .scaleEffect(ringScale)
                .opacity(ringScale > 0 ? 1 : 0)

            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.mint.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 70
                    )
                )
                .frame(width: 140, height: 140)

            // Checkmark with Liquid Glass background
            Image(systemName: "checkmark")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.mint, .green],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .background(Color.mint.opacity(0.1))
                .clipShape(Circle())
                .glassEffect(.regular, in: .circle)
                .scaleEffect(checkmarkScale)
        }
        // ConfettiSwiftUI cannon - triggers when confettiCounter changes
        .confettiCannon(
            trigger: $confettiCounter,
            num: 50,
            confettis: [.shape(.circle), .shape(.square), .shape(.triangle)],
            colors: confettiColors,
            confettiSize: 10,
            rainHeight: 600,
            fadesOut: true,
            opacity: 1.0,
            openingAngle: Angle(degrees: 60),
            closingAngle: Angle(degrees: 120),
            radius: 300
        )
    }

    // MARK: - Success Content
    private var successContent: some View {
        VStack(spacing: 16) {
            // Title - special for first connection
            if isFirstConnection {
                VStack(spacing: 8) {
                    Text("🎉")
                        .font(.system(size: 40))

                    Text("Première connexion !")
                        .font(.largeTitle.bold())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.mint, .blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            } else {
                Text("Rencontre vérifiée !")
                    .font(.title.bold())
                    .foregroundStyle(.white)
            }

            // First connection milestone badge
            if isFirstConnection && showFirstConnectionBadge {
                HStack(spacing: 10) {
                    Image(systemName: "star.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.yellow)

                    Text("Tu viens de débloquer ton réseau Cirkl !")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                        )
                )
                .transition(.scale.combined(with: .opacity))
            }

            // Trust level badge
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.mint)

                Text(trustLevelText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.mint.opacity(0.15))
            .clipShape(Capsule())

            // Distance info (if UWB)
            if let distance = distance {
                HStack(spacing: 6) {
                    Image(systemName: "ruler")
                        .foregroundStyle(.white.opacity(0.6))

                    Text("Distance: \(formatDistance(distance))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            // Description
            Text(isFirstConnection
                 ? "C'est le début de ton aventure. 24 connexions de plus et tu atteins le seuil d'indispensabilité !"
                 : "Cette connexion est maintenant marquée comme vérifiée physiquement.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .opacity(contentOpacity)
    }

    // MARK: - Complete Button
    private var completeButton: some View {
        Button(action: onComplete) {
            HStack(spacing: 10) {
                Text("Voir la connexion")
                    .font(.headline)

                Image(systemName: "arrow.right")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 40)
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
        .opacity(contentOpacity)
        .padding(.bottom, 32)
    }

    // MARK: - Helpers
    private var trustLevelText: String {
        if distance != nil && distance! < 0.5 {
            return "Niveau: Vérifié"
        }
        return "Niveau: Attesté"
    }

    private func formatDistance(_ distance: Float) -> String {
        if distance < 1.0 {
            return String(format: "%.0f cm", distance * 100)
        } else {
            return String(format: "%.1f m", distance)
        }
    }

    private let confettiColors: [Color] = [
        .mint, .blue, .green, .cyan, .teal
    ]

    // MARK: - Animations
    private func runAnimations() {
        // 🎉 Haptic feedback for success celebration
        if isFirstConnection {
            // Extra celebration for first connection
            CirklHaptics.celebration()
        } else {
            CirklHaptics.verificationSuccess()
        }

        // 🎉 Toast confirmation
        ToastManager.shared.success(isFirstConnection
            ? "🎉 Première connexion Cirkl !"
            : "Connexion vérifiée !")

        // Use simpler animations when Reduce Motion is enabled
        if reduceMotion {
            // Instant appearance for Reduce Motion
            checkmarkScale = 1.0
            ringScale = 1.0
            contentOpacity = 1.0
            showFirstConnectionBadge = isFirstConnection
        } else {
            // Checkmark pop
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.1)) {
                checkmarkScale = 1.0
            }

            // Ring expand
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                ringScale = 1.0
            }

            // Content fade in
            withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
                contentOpacity = 1.0
            }

            // Confetti - trigger ConfettiSwiftUI cannon
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                confettiCounter += 1

                // Extra confetti bursts for first connection
                if isFirstConnection {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        confettiCounter += 1
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        confettiCounter += 1
                    }
                }
            }

            // Show first connection badge with delay
            if isFirstConnection {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.8)) {
                    showFirstConnectionBadge = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Regular Verification") {
    ZStack {
        Color(red: 0.04, green: 0.05, blue: 0.15)
            .ignoresSafeArea()

        VerificationSuccessView(
            distance: 0.32,
            onComplete: {}
        )
    }
}

#Preview("First Connection 🎉") {
    ZStack {
        Color(red: 0.04, green: 0.05, blue: 0.15)
            .ignoresSafeArea()

        VerificationSuccessView(
            distance: 0.32,
            onComplete: {},
            isFirstConnection: true
        )
    }
}
