//
//  SuccessConfetti.swift
//  Cirkl
//
//  Created by Claude on 12/01/2026.
//

import SwiftUI

// MARK: - Success Confetti View

/// A celebratory confetti animation for success moments
/// Automatically respects Reduce Motion accessibility setting
struct SuccessConfetti: View {

    // MARK: - Properties

    /// Whether the confetti is currently animating
    @Binding var isActive: Bool

    /// Duration of the confetti animation
    var duration: Double = 3.0

    /// Number of confetti particles
    var particleCount: Int = 50

    /// Colors for the confetti particles
    var colors: [Color] = [
        DesignTokens.Colors.mint,
        DesignTokens.Colors.electricBlue,
        DesignTokens.Colors.purple,
        DesignTokens.Colors.pink,
        .yellow,
        .orange
    ]

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - State

    @State private var particles: [ConfettiParticle] = []
    @State private var animationPhase: Double = 0

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if reduceMotion {
                    // Simple success indicator for Reduce Motion
                    successBadge
                        .opacity(isActive ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3), value: isActive)
                } else {
                    // Full confetti animation
                    ForEach(particles) { particle in
                        ConfettiParticleView(particle: particle, phase: animationPhase)
                    }
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    startAnimation(in: geometry.size)
                }
            }
        }
    }

    // MARK: - Success Badge (Reduce Motion Alternative)

    private var successBadge: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [DesignTokens.Colors.mint, DesignTokens.Colors.electricBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: DesignTokens.Colors.mint.opacity(0.5), radius: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Animation Logic

    private func startAnimation(in size: CGSize) {
        guard !reduceMotion else {
            // For Reduce Motion, just show and hide
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                isActive = false
            }
            return
        }

        // Generate confetti particles
        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                startPosition: CGPoint(x: size.width / 2, y: size.height * 0.3),
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 8...16),
                rotation: Double.random(in: 0...360),
                velocity: CGPoint(
                    x: CGFloat.random(in: -200...200),
                    y: CGFloat.random(in: -400 ... -200)
                )
            )
        }

        // Animate particles
        withAnimation(.easeOut(duration: duration)) {
            animationPhase = 1
        }

        // Clean up after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            isActive = false
            particles = []
            animationPhase = 0
        }
    }
}

// MARK: - Confetti Particle Model

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let startPosition: CGPoint
    let color: Color
    let size: CGFloat
    let rotation: Double
    let velocity: CGPoint
    let shape: ConfettiShape = ConfettiShape.allCases.randomElement() ?? .circle

    /// Calculate final position based on physics
    func endPosition(in bounds: CGSize) -> CGPoint {
        CGPoint(
            x: startPosition.x + velocity.x,
            y: bounds.height + 50 // Fall below screen
        )
    }
}

// MARK: - Confetti Shape

enum ConfettiShape: CaseIterable {
    case circle
    case rectangle
    case star
}

// MARK: - Confetti Particle View

struct ConfettiParticleView: View {

    let particle: ConfettiParticle
    let phase: Double

    var body: some View {
        GeometryReader { geometry in
            particleShape
                .fill(particle.color)
                .frame(width: particle.size, height: particle.size * aspectRatio)
                .rotationEffect(.degrees(particle.rotation + phase * 720))
                .position(interpolatedPosition(in: geometry.size))
                .opacity(1 - phase * 0.5)
        }
    }

    private var aspectRatio: CGFloat {
        switch particle.shape {
        case .circle: return 1.0
        case .rectangle: return 0.4
        case .star: return 1.0
        }
    }

    private var particleShape: AnyShape {
        switch particle.shape {
        case .circle:
            AnyShape(Circle())
        case .rectangle:
            AnyShape(RoundedRectangle(cornerRadius: 2))
        case .star:
            AnyShape(StarShape())
        }
    }

    private func interpolatedPosition(in size: CGSize) -> CGPoint {
        let endPos = particle.endPosition(in: size)
        return CGPoint(
            x: particle.startPosition.x + (endPos.x - particle.startPosition.x) * phase,
            y: particle.startPosition.y + (endPos.y - particle.startPosition.y) * phase + (phase * phase * 500) // Gravity effect
        )
    }
}

// MARK: - Star Shape

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4
        let points = 5

        var path = Path()

        for i in 0..<(points * 2) {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = Double(i) * .pi / Double(points) - .pi / 2

            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - View Modifier

extension View {
    /// Adds a success confetti overlay to the view
    func successConfetti(isActive: Binding<Bool>, duration: Double = 3.0) -> some View {
        self.overlay {
            SuccessConfetti(isActive: isActive, duration: duration)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Preview

#Preview("Success Confetti") {
    struct PreviewWrapper: View {
        @State private var showConfetti = false

        var body: some View {
            ZStack {
                DesignTokens.Colors.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Success Confetti Demo")
                        .font(DesignTokens.Typography.title2)
                        .foregroundColor(DesignTokens.Colors.textPrimary)

                    Button("Celebrate!") {
                        showConfetti = true
                    }
                    .font(DesignTokens.Typography.button)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(DesignTokens.Colors.mint)
                    .clipShape(Capsule())
                }
            }
            .successConfetti(isActive: $showConfetti)
        }
    }

    return PreviewWrapper()
        .preferredColorScheme(.dark)
}
