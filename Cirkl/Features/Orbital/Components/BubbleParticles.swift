//
//  BubbleParticles.swift
//  Cirkl
//
//  Created by Claude on 15/01/2026.
//

import SwiftUI

// MARK: - Bubble Particles

/// Effet de particules lumineuses autour des bulles actives (synergies/opportunités)
struct BubbleParticles: View {

    // MARK: - Properties

    /// Taille de la bulle parente
    let bubbleSize: CGFloat

    /// Niveau d'intensité (0-1, basé sur le score de synergie)
    let intensity: Double

    /// Couleur des particules
    let color: Color

    /// Nombre de particules
    var particleCount: Int = 8

    // MARK: - State

    @State private var particles: [SynergyParticle] = []
    @State private var animationTimer: Timer?

    // MARK: - Body

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            for particle in particles {
                // Calculate particle position
                let angle = particle.angle
                let distance = particle.distance
                let x = center.x + cos(angle) * distance
                let y = center.y + sin(angle) * distance

                // Draw particle
                let particleSize = particle.size * CGFloat(intensity)
                let rect = CGRect(
                    x: x - particleSize / 2,
                    y: y - particleSize / 2,
                    width: particleSize,
                    height: particleSize
                )

                // Glow
                let glowRect = rect.insetBy(dx: -4, dy: -4)
                context.fill(
                    Path(ellipseIn: glowRect),
                    with: .radialGradient(
                        Gradient(colors: [color.opacity(particle.opacity * 0.5), .clear]),
                        center: CGPoint(x: x, y: y),
                        startRadius: 0,
                        endRadius: particleSize + 4
                    )
                )

                // Core
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(color.opacity(particle.opacity))
                )
            }
        }
        .frame(width: bubbleSize + 40, height: bubbleSize + 40)
        .onAppear {
            initializeParticles()
            startAnimation()
        }
        .onDisappear {
            animationTimer?.invalidate()
        }
    }

    // MARK: - Particle Management

    private func initializeParticles() {
        particles = (0..<particleCount).map { i in
            SynergyParticle(
                angle: Double(i) * (2 * .pi / Double(particleCount)) + Double.random(in: -0.3...0.3),
                distance: bubbleSize / 2 + 8 + CGFloat.random(in: 0...15),
                size: CGFloat.random(in: 3...6),
                opacity: Double.random(in: 0.4...0.9),
                speed: Double.random(in: 0.5...1.5)
            )
        }
    }

    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            updateParticles()
        }
    }

    private func updateParticles() {
        for i in particles.indices {
            // Rotate around the bubble
            particles[i].angle += 0.02 * particles[i].speed

            // Subtle distance oscillation
            let baseDistance = bubbleSize / 2 + 8
            particles[i].distance = baseDistance + 10 * sin(particles[i].angle * 2)

            // Opacity pulsing
            particles[i].opacity = 0.4 + 0.5 * abs(sin(particles[i].angle * 1.5))
        }
    }
}

// MARK: - Particle Model

private struct SynergyParticle {
    var angle: Double
    var distance: CGFloat
    var size: CGFloat
    var opacity: Double
    var speed: Double
}

// MARK: - Synergy Particles Effect

/// Effet de particules pour connexion en synergie
struct SynergyBubbleEffect: View {

    let bubbleSize: CGFloat
    let synergyType: SynergyType
    let score: Double

    var body: some View {
        BubbleParticles(
            bubbleSize: bubbleSize,
            intensity: score,
            color: synergyType.category.color,
            particleCount: particleCountForScore
        )
    }

    private var particleCountForScore: Int {
        if score > 0.7 {
            return 12
        } else if score > 0.5 {
            return 8
        } else {
            return 5
        }
    }
}

// MARK: - Active Connection Glow

/// Effet de glow pour les connexions avec opportunités
struct ActiveConnectionGlow: View {

    let size: CGFloat
    let color: Color

    @State private var pulsePhase: Double = 0

    var body: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 2)
                .frame(width: size + 12, height: size + 12)
                .scaleEffect(1 + pulsePhase * 0.1)
                .opacity(1 - pulsePhase * 0.5)

            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.2), .clear],
                        center: .center,
                        startRadius: size / 2 - 5,
                        endRadius: size / 2 + 15
                    )
                )
                .frame(width: size + 30, height: size + 30)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulsePhase = 1.0
            }
        }
    }
}

// MARK: - Sparkle Effect

/// Effet d'étincelles occasionnelles autour d'une bulle
struct SparkleEffect: View {

    let size: CGFloat
    let color: Color

    @State private var sparkles: [SparkleParticle] = []
    @State private var timer: Timer?

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)

            for sparkle in sparkles {
                let x = center.x + cos(sparkle.angle) * sparkle.distance
                let y = center.y + sin(sparkle.angle) * sparkle.distance

                // Draw 4-point star
                let starPath = createStarPath(at: CGPoint(x: x, y: y), size: sparkle.size)

                context.fill(
                    starPath,
                    with: .color(color.opacity(sparkle.opacity))
                )
            }
        }
        .frame(width: size + 50, height: size + 50)
        .onAppear {
            startSparkles()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func createStarPath(at center: CGPoint, size: CGFloat) -> Path {
        var path = Path()

        let points: [(CGFloat, CGFloat)] = [
            (0, -1), (0.3, -0.3), (1, 0), (0.3, 0.3),
            (0, 1), (-0.3, 0.3), (-1, 0), (-0.3, -0.3)
        ]

        for (i, point) in points.enumerated() {
            let x = center.x + point.0 * size
            let y = center.y + point.1 * size

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        path.closeSubpath()
        return path
    }

    private func startSparkles() {
        // Create initial sparkles
        for _ in 0..<3 {
            addSparkle()
        }

        // Periodically add new sparkles
        timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            addSparkle()

            // Remove old sparkles
            sparkles.removeAll { $0.age > 1.5 }

            // Update ages
            for i in sparkles.indices {
                sparkles[i].age += 0.1
                sparkles[i].opacity = max(0, 1 - sparkles[i].age / 1.5)
            }
        }
    }

    private func addSparkle() {
        let sparkle = SparkleParticle(
            angle: Double.random(in: 0...(2 * .pi)),
            distance: size / 2 + CGFloat.random(in: 5...20),
            size: CGFloat.random(in: 3...6),
            opacity: 1.0,
            age: 0
        )
        sparkles.append(sparkle)
    }
}

private struct SparkleParticle {
    let angle: Double
    let distance: CGFloat
    let size: CGFloat
    var opacity: Double
    var age: Double
}

// MARK: - Preview

#Preview("Bubble Particles") {
    ZStack {
        Color(red: 0.04, green: 0.05, blue: 0.15)
            .ignoresSafeArea()

        Circle()
            .fill(Color.blue.opacity(0.3))
            .frame(width: 60, height: 60)
            .overlay {
                BubbleParticles(
                    bubbleSize: 60,
                    intensity: 0.8,
                    color: .mint
                )
            }
    }
}

#Preview("Active Glow") {
    ZStack {
        Color(red: 0.04, green: 0.05, blue: 0.15)
            .ignoresSafeArea()

        Circle()
            .fill(Color.blue.opacity(0.3))
            .frame(width: 60, height: 60)
            .background {
                ActiveConnectionGlow(size: 60, color: .yellow)
            }
    }
}
