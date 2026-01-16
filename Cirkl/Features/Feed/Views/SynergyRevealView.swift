import SwiftUI

// MARK: - Synergy Reveal View
/// Full-screen animated reveal for synergy detection
/// Duolingo-like "WOW" experience with orchestrated animations

struct SynergyRevealView: View {

    let item: FeedItem
    let onCreateConnection: () -> Void
    let onDismiss: () -> Void
    let onSkip: () -> Void

    // MARK: - Animation States

    @State private var showBackground = false
    @State private var avatar1Offset: CGFloat = -200
    @State private var avatar2Offset: CGFloat = 200
    @State private var scoreProgress: CGFloat = 0
    @State private var showTitle = false
    @State private var showReason = false
    @State private var showButtons = false

    // MARK: - Computed Properties

    private var person1Name: String {
        item.synergyPerson1Name ?? "Contact 1"
    }

    private var person2Name: String {
        item.synergyPerson2Name ?? "Contact 2"
    }

    private var person1Action: String {
        item.synergyPerson1 ?? ""
    }

    private var person2Action: String {
        item.synergyPerson2 ?? ""
    }

    private var synergyScore: Int {
        // Mock score between 75-95 based on item id hash
        let hash = abs(item.id.hashValue)
        return 75 + (hash % 21)
    }

    private var matchContext: String? {
        item.synergyMatch
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 1. Animated gradient background
            AnimatedGradientBackground()
                .opacity(showBackground ? 1 : 0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                skipButton
                    .padding(.top, 16)
                    .padding(.trailing, 20)

                Spacer()

                // Main content
                VStack(spacing: 32) {
                    // Avatars approaching
                    avatarsSection

                    // Title
                    if showTitle {
                        titleSection
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Score bar
                    scoreSection

                    // Reason text
                    if showReason {
                        reasonSection
                            .transition(.opacity)
                    }
                }

                Spacer()

                // Action buttons
                if showButtons {
                    buttonsSection
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            startAnimationSequence()
        }
    }

    // MARK: - Skip Button

    private var skipButton: some View {
        HStack {
            Spacer()
            Button {
                CirklHaptics.light()
                onSkip()
            } label: {
                HStack(spacing: 4) {
                    Text("Skip")
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.15))
                )
            }
        }
    }

    // MARK: - Avatars Section

    private var avatarsSection: some View {
        HStack(spacing: 40) {
            // Person 1 (from left)
            VStack(spacing: 8) {
                SynergyAvatar(name: person1Name, color: DesignTokens.Colors.electricBlue)
                Text(person1Name)
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(.white)
            }
            .offset(x: avatar1Offset)

            // Connection indicator
            if avatar1Offset == 0 && avatar2Offset == 0 {
                Image(systemName: "link")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .transition(.scale)
            }

            // Person 2 (from right)
            VStack(spacing: 8) {
                SynergyAvatar(name: person2Name, color: DesignTokens.Colors.success)
                Text(person2Name)
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(.white)
            }
            .offset(x: avatar2Offset)
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        HStack(spacing: 8) {
            Text("🔮")
                .font(.system(size: 32))
            Text("SYNERGIE")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Score Section

    private var scoreSection: some View {
        VStack(spacing: 12) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.2))

                    // Progress
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [DesignTokens.Colors.purple, DesignTokens.Colors.electricBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * scoreProgress * CGFloat(synergyScore) / 100)
                }
            }
            .frame(height: 16)
            .padding(.horizontal, 40)

            // Score text
            Text("\(Int(scoreProgress * CGFloat(synergyScore)))%")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
    }

    // MARK: - Reason Section

    private var reasonSection: some View {
        VStack(spacing: 12) {
            // Person 1 reason
            HStack(spacing: 8) {
                Text(person1Name)
                    .fontWeight(.semibold)
                Text(person1Action)
            }
            .font(DesignTokens.Typography.body)
            .foregroundStyle(.white.opacity(0.9))

            // Match context
            if let context = matchContext {
                Text("↔ \(context)")
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.purple)
                    .padding(.vertical, 4)
            }

            // Person 2 reason
            HStack(spacing: 8) {
                Text(person2Name)
                    .fontWeight(.semibold)
                Text(person2Action)
            }
            .font(DesignTokens.Typography.body)
            .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 32)
        .multilineTextAlignment(.center)
    }

    // MARK: - Buttons Section

    private var buttonsSection: some View {
        VStack(spacing: 16) {
            // Primary CTA
            Button {
                CirklHaptics.heavy()
                onCreateConnection()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                    Text("Créer la connexion")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [DesignTokens.Colors.purple, DesignTokens.Colors.purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: DesignTokens.Colors.purple.opacity(0.4), radius: 12, y: 6)
            }
            .padding(.horizontal, 32)

            // Secondary action
            Button {
                CirklHaptics.light()
                onDismiss()
            } label: {
                Text("Pas maintenant")
                    .font(DesignTokens.Typography.buttonSmall)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Animation Sequence

    private func startAnimationSequence() {
        // Initial haptic
        CirklHaptics.medium()

        // Phase 1: Background fade in (0-0.5s)
        withAnimation(.easeIn(duration: 0.5)) {
            showBackground = true
        }

        // Phase 2: Avatars approach (0.3-1.5s)
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
            avatar1Offset = 0
            avatar2Offset = 0
        }

        // Phase 2.5: Title appears (1.2s)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(1.2)) {
            showTitle = true
        }

        // Phase 3: Score animation (1.5-3s)
        withAnimation(.easeOut(duration: 1.5).delay(1.5)) {
            scoreProgress = 1.0
        }

        // Score complete haptic
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            CirklHaptics.success()
        }

        // Phase 4: Reason text (2.5-3s)
        withAnimation(.easeIn(duration: 0.5).delay(2.5)) {
            showReason = true
        }

        // Phase 5: Buttons slide up (3.5-4s)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(3.5)) {
            showButtons = true
        }
    }
}

// MARK: - Synergy Avatar

private struct SynergyAvatar: View {
    let name: String
    let color: Color

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.8), color.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 80, height: 80)
            .overlay(
                Text(name.prefix(1).uppercased())
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            )
            .overlay(
                Circle()
                    .strokeBorder(.white.opacity(0.3), lineWidth: 2)
            )
            .shadow(color: color.opacity(0.5), radius: 12, y: 4)
    }
}

// MARK: - Animated Gradient Background

private struct AnimatedGradientBackground: View {
    @State private var animateGradient = false

    var body: some View {
        LinearGradient(
            colors: [
                Color.purple.opacity(0.9),
                Color.blue.opacity(0.7),
                Color.indigo.opacity(0.8)
            ],
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SynergyRevealView(
        item: FeedItem.mockItems[3],
        onCreateConnection: { },
        onDismiss: { },
        onSkip: { }
    )
}
