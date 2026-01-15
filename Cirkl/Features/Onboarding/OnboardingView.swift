import SwiftUI
import ConcentricOnboarding
import AnimateText
import ConfettiSwiftUI

// MARK: - OnboardingView
/// Onboarding 6 pages avec ConcentricOnboarding et AnimateText
struct OnboardingView: View {
    @ObservedObject var appState: AppStateManager
    @State private var confettiCounter = 0

    // Couleurs de fond pour chaque page
    private let pageColors: [Color] = [
        Color(red: 0.04, green: 0.05, blue: 0.15),   // Welcome - Deep Blue
        Color(red: 0.2, green: 0.1, blue: 0.3),      // Value Prop - Purple
        Color(red: 0.0, green: 0.3, blue: 0.25),     // Permissions - Mint
        Color(red: 0.1, green: 0.1, blue: 0.25),     // Orbital Tutorial - Indigo
        Color(red: 0.0, green: 0.25, blue: 0.35),    // AI Companion - Cyan
        Color(red: 0.05, green: 0.08, blue: 0.2)     // Ready - Dark Blue
    ]

    var body: some View {
        ConcentricOnboardingView(
            pageContents: [
                (AnyView(WelcomePage()), pageColors[0]),
                (AnyView(ValuePropPage()), pageColors[1]),
                (AnyView(PermissionsPage()), pageColors[2]),
                (AnyView(OrbitalTutorialPage()), pageColors[3]),
                (AnyView(AICompanionPage()), pageColors[4]),
                (AnyView(ReadyPage(confettiCounter: $confettiCounter, onComplete: appState.completeOnboarding)), pageColors[5])
            ]
        )
        .duration(0.8)
        .nextIcon("chevron.forward")
        .insteadOfCyclingToFirstPage {
            // Quand on atteint la fin et qu'on clique, terminer l'onboarding
            confettiCounter += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                appState.completeOnboarding()
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Page 1: Welcome
struct WelcomePage: View {
    @State private var titleText = ""
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo animé
            ZStack {
                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [DesignTokens.Colors.electricBlue.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: 120
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)

                // Logo text
                Text("Cirkl")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignTokens.Colors.electricBlue, DesignTokens.Colors.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            // Titre animé
            AnimateText<ATSpringEffect>($titleText, type: .letters)
                .font(.title.bold())
                .foregroundColor(.white)

            // Sous-titre
            Text("Ton réseau, amplifié")
                .font(.title3)
                .foregroundColor(.white.opacity(0.7))
                .opacity(showContent ? 1 : 0)

            Spacer()
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                titleText = "Bienvenue"
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
                showContent = true
            }
        }
    }
}

// MARK: - Page 2: Value Proposition
struct ValuePropPage: View {
    @State private var titleText = ""
    @State private var showBullets = [false, false, false]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icône
            Image(systemName: "person.2.badge.shield.checkmark.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [DesignTokens.Colors.mint, DesignTokens.Colors.electricBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolRenderingMode(.hierarchical)

            // Titre animé
            AnimateText<ATScaleEffect>($titleText, type: .words)
                .font(.title.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Bullets
            VStack(alignment: .leading, spacing: 16) {
                BulletPoint(icon: "shield.checkmark.fill", text: "Zéro faux profils", color: DesignTokens.Colors.mint)
                    .opacity(showBullets[0] ? 1 : 0)
                    .offset(x: showBullets[0] ? 0 : -20)

                BulletPoint(icon: "person.fill.checkmark", text: "100% humain", color: DesignTokens.Colors.electricBlue)
                    .opacity(showBullets[1] ? 1 : 0)
                    .offset(x: showBullets[1] ? 0 : -20)

                BulletPoint(icon: "qrcode.viewfinder", text: "Vérifié physiquement", color: DesignTokens.Colors.purple)
                    .opacity(showBullets[2] ? 1 : 0)
                    .offset(x: showBullets[2] ? 0 : -20)
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                titleText = "Connexions Authentiques"
            }
            for i in 0..<3 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6 + Double(i) * 0.2)) {
                    showBullets[i] = true
                }
            }
        }
    }
}

// MARK: - Page 3: Permissions
struct PermissionsPage: View {
    @State private var titleText = ""
    @State private var showButtons = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icône
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 80))
                .foregroundStyle(DesignTokens.Colors.mint)
                .symbolRenderingMode(.hierarchical)

            // Titre animé
            AnimateText<ATOpacityEffect>($titleText, type: .words)
                .font(.title.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Description
            Text("Importe tes contacts existants pour retrouver les personnes que tu connais déjà.")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(showButtons ? 1 : 0)

            // Boutons de permissions (visuels uniquement dans l'onboarding)
            VStack(spacing: 12) {
                PermissionButton(
                    icon: "person.crop.circle.fill",
                    title: "Contacts iPhone",
                    subtitle: "Retrouve tes amis",
                    color: DesignTokens.Colors.electricBlue
                )

                PermissionButton(
                    icon: "briefcase.fill",
                    title: "LinkedIn",
                    subtitle: "Réseau professionnel",
                    color: Color(red: 0.0, green: 0.46, blue: 0.78)
                )
            }
            .padding(.horizontal, 32)
            .opacity(showButtons ? 1 : 0)
            .offset(y: showButtons ? 0 : 20)

            Text("Tu pourras configurer ça plus tard")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .opacity(showButtons ? 1 : 0)

            Spacer()
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                titleText = "Importe ton réseau"
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7)) {
                showButtons = true
            }
        }
    }
}

// MARK: - Page 4: Orbital Tutorial
struct OrbitalTutorialPage: View {
    @State private var titleText = ""
    @State private var showDemo = false
    @State private var bubbleScale: CGFloat = 0.5
    @State private var bubbleRotation: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Mini démo orbitale
            ZStack {
                // Orbites
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .frame(width: CGFloat(80 + i * 50), height: CGFloat(80 + i * 50))
                }

                // Toi au centre
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DesignTokens.Colors.electricBlue, DesignTokens.Colors.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text("Toi")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    )
                    .scaleEffect(showDemo ? 1 : 0.5)

                // Connexions en orbite
                ForEach(0..<4) { i in
                    let angle = Double(i) * 90 + bubbleRotation
                    let radius: CGFloat = 80
                    Circle()
                        .fill(DesignTokens.Colors.mint.opacity(0.8))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                        )
                        .offset(
                            x: cos(angle * .pi / 180) * radius,
                            y: sin(angle * .pi / 180) * radius
                        )
                        .scaleEffect(bubbleScale)
                }
            }
            .frame(height: 220)

            // Titre animé
            AnimateText<ATBottomTopEffect>($titleText, type: .words)
                .font(.title.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Instructions
            VStack(spacing: 12) {
                InstructionRow(icon: "hand.tap.fill", text: "Tape sur une bulle pour voir le profil")
                InstructionRow(icon: "hand.draw.fill", text: "Glisse pour explorer ton réseau")
                InstructionRow(icon: "sparkles", text: "L'IA détecte les opportunités")
            }
            .padding(.horizontal, 32)
            .opacity(showDemo ? 1 : 0)

            Spacer()
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                titleText = "Toi au centre"
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) {
                showDemo = true
                bubbleScale = 1.0
            }
            // Animation de rotation continue
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                bubbleRotation = 360
            }
        }
    }
}

// MARK: - Page 5: AI Companion
struct AICompanionPage: View {
    @State private var titleText = ""
    @State private var showContent = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Bouton AI animé
            ZStack {
                // Pulse rings
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(DesignTokens.Colors.purple.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                        .frame(width: 100 + CGFloat(i * 30), height: 100 + CGFloat(i * 30))
                        .scaleEffect(pulseScale)
                }

                // Core button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DesignTokens.Colors.purple, DesignTokens.Colors.electricBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .shadow(color: DesignTokens.Colors.purple.opacity(0.5), radius: 20)
            }

            // Titre animé
            AnimateText<ATSpringEffect>($titleText, type: .words)
                .font(.title.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Features de l'IA
            VStack(spacing: 16) {
                AIFeatureRow(icon: "sun.max.fill", title: "Morning Brief", description: "Brief vocal quotidien personnalisé")
                AIFeatureRow(icon: "bell.badge.fill", title: "Opportunités", description: "Détecte les synergies dans ton réseau")
                AIFeatureRow(icon: "heart.fill", title: "Compagnon", description: "Pas un outil, un ami relationnel")
            }
            .padding(.horizontal, 24)
            .opacity(showContent ? 1 : 0)

            Spacer()
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                titleText = "Ton assistant IA"
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
                showContent = true
            }
            // Pulse animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
}

// MARK: - Page 6: Ready
struct ReadyPage: View {
    @Binding var confettiCounter: Int
    let onComplete: () -> Void

    @State private var titleText = ""
    @State private var showContent = false
    @State private var buttonScale: CGFloat = 0.8

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Checkmark animé
            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.mint.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignTokens.Colors.mint, DesignTokens.Colors.electricBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(showContent ? 1 : 0.5)
            }
            .confettiCannon(
                trigger: $confettiCounter,
                num: 80,
                confettis: [.shape(.circle), .shape(.square), .shape(.triangle)],
                colors: [DesignTokens.Colors.mint, DesignTokens.Colors.electricBlue, DesignTokens.Colors.purple, .white],
                confettiSize: 12,
                rainHeight: 800,
                radius: 400
            )

            // Titre animé
            AnimateText<ATScaleEffect>($titleText, type: .letters)
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            // Magic numbers
            VStack(spacing: 8) {
                Text("25 connexions + 3 CirKLs")
                    .font(.headline)
                    .foregroundColor(DesignTokens.Colors.mint)

                Text("= Seuil d'indispensabilité")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
            )
            .opacity(showContent ? 1 : 0)

            Spacer()

            // CTA Button
            Button(action: {
                CirklHaptics.success()
                confettiCounter += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onComplete()
                }
            }) {
                HStack(spacing: 12) {
                    Text("Commencer")
                        .font(.headline.bold())
                    Image(systemName: "arrow.right")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [DesignTokens.Colors.electricBlue, DesignTokens.Colors.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: DesignTokens.Colors.electricBlue.opacity(0.4), radius: 15, y: 5)
            }
            .padding(.horizontal, 40)
            .scaleEffect(buttonScale)
            .opacity(showContent ? 1 : 0)

            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                titleText = "Tu es prêt !"
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) {
                showContent = true
                buttonScale = 1.0
            }
        }
    }
}

// MARK: - Helper Components

struct BulletPoint: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32)

            Text(text)
                .font(.body)
                .foregroundColor(.white)

            Spacer()
        }
    }
}

struct PermissionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct InstructionRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(DesignTokens.Colors.mint)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            Spacer()
        }
    }
}

struct AIFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(DesignTokens.Colors.purple)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(appState: AppStateManager())
        .preferredColorScheme(.dark)
}
