//
//  ConnectionRevealView.swift
//  Cirkl
//
//  Created by Claude on 15/01/2026.
//

import SwiftUI
import ConfettiSwiftUI

// MARK: - ConnectionRevealView

/// Vue "wow" affichée après une vérification réussie
/// Révèle le profil public de la nouvelle connexion avec effet surprise
struct ConnectionRevealView: View {

    // MARK: - Properties

    let connectionId: String
    let publicProfile: ConnectionPublicProfile
    let onComplete: () -> Void

    // MARK: - State

    @State private var phase: RevealPhase = .initial
    @State private var confettiCounter = 0
    @State private var messageOpacity: Double = 0
    @State private var cardScale: CGFloat = 0.8
    @State private var cardOpacity: Double = 0
    @State private var sparkleRotation: Double = 0
    @State private var generatedMessage: String?
    @State private var isLoadingMessage = false

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed

    private var commonPointsCount: Int {
        publicProfile.commonPointsCount
    }

    private var shouldUseAI: Bool {
        commonPointsCount >= 5
    }

    private var displayMessage: String {
        if let generated = generatedMessage {
            return generated
        }
        return buildTemplateMessage()
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            // Content
            VStack(spacing: 32) {
                Spacer()

                // Sparkle animation
                sparkleHeader

                // Profile card
                profileCard

                // Message
                messageSection

                Spacer()

                // Continue button
                continueButton
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
        }
        .confettiCannon(
            trigger: $confettiCounter,
            num: 80,
            confettis: [.shape(.circle), .shape(.square), .text("🎉"), .text("✨")],
            colors: [.mint, .blue, .purple, .pink, .yellow],
            confettiSize: 12,
            rainHeight: 800,
            fadesOut: true,
            openingAngle: Angle(degrees: 40),
            closingAngle: Angle(degrees: 140),
            radius: 400
        )
        .onAppear {
            startRevealSequence()
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.05, blue: 0.15),
                Color(red: 0.08, green: 0.10, blue: 0.25),
                Color(red: 0.04, green: 0.05, blue: 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Sparkle Header

    private var sparkleHeader: some View {
        ZStack {
            // Rotating sparkles
            ForEach(0..<6) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(x: 60 * cos(Double(i) * .pi / 3 + sparkleRotation),
                            y: 60 * sin(Double(i) * .pi / 3 + sparkleRotation))
                    .opacity(phase == .initial ? 0 : 0.8)
            }

            // Center icon
            Image(systemName: "person.2.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.mint, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .mint.opacity(0.5), radius: 20)
        }
        .opacity(phase == .initial ? 0 : 1)
        .scaleEffect(phase == .initial ? 0.5 : 1.0)
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(spacing: 16) {
            // Name
            Text(publicProfile.name)
                .font(.title.bold())
                .foregroundStyle(.white)

            // Role + Company
            if let role = publicProfile.role, let company = publicProfile.company {
                HStack(spacing: 8) {
                    Image(systemName: "briefcase.fill")
                        .foregroundStyle(.mint)
                    Text("\(role) @ \(company)")
                        .foregroundStyle(.white.opacity(0.9))
                }
                .font(.subheadline)
            }

            // Industry
            if let industry = publicProfile.industry {
                HStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(.blue)
                    Text(industry)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .font(.caption)
            }

            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.vertical, 8)

            // Common points
            commonPointsSection
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.08))
        )
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .mint.opacity(0.2), radius: 30, x: 0, y: 10)
        .scaleEffect(cardScale)
        .opacity(cardOpacity)
    }

    // MARK: - Common Points Section

    @ViewBuilder
    private var commonPointsSection: some View {
        VStack(spacing: 12) {
            // Mutual connections
            if publicProfile.mutualConnectionsCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .foregroundStyle(.purple)

                    if publicProfile.mutualConnectionNames.isEmpty {
                        Text("\(publicProfile.mutualConnectionsCount) connexion(s) en commun")
                    } else {
                        Text("\(publicProfile.mutualConnectionsCount) en commun: \(publicProfile.mutualConnectionNames.prefix(2).joined(separator: ", "))")
                    }
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
            }

            // Shared interests
            if !publicProfile.sharedInterests.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                    Text("Intérêts: \(publicProfile.sharedInterests.prefix(3).joined(separator: ", "))")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
            }

            // Tags
            if !publicProfile.tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(publicProfile.tags.prefix(4), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.mint.opacity(0.2)))
                            .foregroundStyle(.mint)
                    }
                }
            }

            // Meeting place
            if let place = publicProfile.meetingPlace {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.orange)
                    Text("Rencontre: \(place)")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Message Section

    private var messageSection: some View {
        VStack(spacing: 12) {
            if isLoadingMessage {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.mint)
                    Text("L'IA analyse votre connexion...")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            } else {
                Text(displayMessage)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .opacity(messageOpacity)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: completeReveal) {
            HStack(spacing: 12) {
                Text("Continuer")
                    .font(.headline)
                Image(systemName: "arrow.right")
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.mint, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .mint.opacity(0.4), radius: 15, y: 5)
        }
        .opacity(messageOpacity)
        .disabled(isLoadingMessage)
    }

    // MARK: - Animation Sequence

    private func startRevealSequence() {
        // Haptic
        CirklHaptics.celebration()

        // Phase 1: Sparkles appear
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            phase = .sparkles
        }

        // Rotate sparkles continuously
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            sparkleRotation = .pi * 2
        }

        // Phase 2: Card appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                cardScale = 1.0
                cardOpacity = 1.0
            }
        }

        // Phase 3: Confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            confettiCounter += 1
        }

        // Phase 4: Message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if shouldUseAI {
                generateAIMessage()
            }

            withAnimation(.easeOut(duration: 0.4)) {
                messageOpacity = 1.0
                phase = .complete
            }
        }

        // Create pending debriefing
        createPendingDebriefing()
    }

    // MARK: - Message Generation

    private func buildTemplateMessage() -> String {
        var parts: [String] = []

        // Base message
        parts.append("🎉 Nouvelle connexion avec \(publicProfile.name) !")

        // Mutual connections
        if publicProfile.mutualConnectionsCount > 0 {
            if publicProfile.mutualConnectionsCount == 1 {
                parts.append("Vous avez 1 connexion en commun.")
            } else {
                parts.append("Vous avez \(publicProfile.mutualConnectionsCount) connexions en commun !")
            }
        }

        // Shared interests
        if !publicProfile.sharedInterests.isEmpty {
            let interests = publicProfile.sharedInterests.prefix(2).joined(separator: " et ")
            parts.append("Vous partagez un intérêt pour \(interests).")
        }

        // Meeting context
        if let place = publicProfile.meetingPlace {
            parts.append("Rencontre à \(place).")
        }

        return parts.joined(separator: "\n\n")
    }

    private func generateAIMessage() {
        isLoadingMessage = true

        Task {
            do {
                // Call N8N for AI-generated message
                let response = try await N8NService.shared.sendMessage(
                    "[SYSTEM: Generate a surprising connection reveal message] Profile: \(publicProfile.summary)",
                    userId: "gil", // TODO: Get from auth
                    sessionId: UUID().uuidString
                )

                await MainActor.run {
                    generatedMessage = response.response
                    isLoadingMessage = false
                }
            } catch {
                await MainActor.run {
                    // Fallback to template
                    isLoadingMessage = false
                    #if DEBUG
                    print("❌ AI message generation failed: \(error)")
                    #endif
                }
            }
        }
    }

    // MARK: - Debriefing Creation

    private func createPendingDebriefing() {
        DebriefingManager.shared.addDebriefing(
            connectionId: connectionId,
            connectionName: publicProfile.name,
            connectionAvatarURL: nil,
            publicProfile: publicProfile
        )

        #if DEBUG
        print("📝 Created pending debriefing for \(publicProfile.name)")
        #endif
    }

    // MARK: - Completion

    private func completeReveal() {
        CirklHaptics.selection()
        onComplete()
    }
}

// MARK: - Reveal Phase

private enum RevealPhase {
    case initial
    case sparkles
    case complete
}

// Note: FlowLayout is defined in Components/FlowLayout.swift

// MARK: - Preview

#Preview("Connection Reveal") {
    ConnectionRevealView(
        connectionId: "test-123",
        publicProfile: ConnectionPublicProfile(
            name: "Sarah Martin",
            role: "CEO",
            company: "TechStart",
            industry: "Tech / AI",
            tags: ["AI", "Startup", "Innovation", "Paris"],
            sharedInterests: ["Intelligence Artificielle", "Entrepreneuriat"],
            mutualConnectionsCount: 3,
            mutualConnectionNames: ["Marc", "Julie", "Denis"],
            meetingPlace: "Station F"
        ),
        onComplete: {}
    )
}
