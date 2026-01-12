import SwiftUI

// MARK: - VerificationSuccessView
/// Vue de confirmation affichée après une vérification réussie
struct VerificationSuccessView: View {

    // MARK: - Properties
    let distance: Float?
    let onComplete: () -> Void

    // MARK: - Accessibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var checkmarkScale: CGFloat = 0
    @State private var ringScale: CGFloat = 0
    @State private var contentOpacity: Double = 0
    @State private var confettiVisible = false

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
            // Confetti particles (disabled when Reduce Motion is enabled)
            if confettiVisible && !reduceMotion {
                ForEach(0..<20, id: \.self) { index in
                    VerificationConfettiParticle(
                        color: confettiColors[index % confettiColors.count],
                        delay: Double(index) * 0.05
                    )
                }
            }

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
    }

    // MARK: - Success Content
    private var successContent: some View {
        VStack(spacing: 16) {
            Text("Rencontre vérifiée !")
                .font(.title.bold())
                .foregroundStyle(.white)

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
            Text("Cette connexion est maintenant marquée comme vérifiée physiquement.")
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
        CirklHaptics.verificationSuccess()

        // 🎉 Toast confirmation
        ToastManager.shared.success("Connexion vérifiée !")

        // Use simpler animations when Reduce Motion is enabled
        if reduceMotion {
            // Instant appearance for Reduce Motion
            checkmarkScale = 1.0
            ringScale = 1.0
            contentOpacity = 1.0
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

            // Confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                confettiVisible = true
            }
        }
    }
}

// MARK: - Verification Confetti Particle
private struct VerificationConfettiParticle: View {
    let color: Color
    let delay: Double

    @State private var offsetY: CGFloat = 0
    @State private var offsetX: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 8, height: 8)
            .offset(x: offsetX, y: offsetY)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                let randomX = CGFloat.random(in: -150...150)
                let randomY = CGFloat.random(in: 100...300)

                withAnimation(.easeOut(duration: 2).delay(delay)) {
                    offsetX = randomX
                    offsetY = randomY
                    rotation = Double.random(in: 0...720)
                    opacity = 0
                }
            }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(red: 0.04, green: 0.05, blue: 0.15)
            .ignoresSafeArea()

        VerificationSuccessView(
            distance: 0.32,
            onComplete: {}
        )
    }
}
