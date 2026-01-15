//
//  SynergyLineView.swift
//  Cirkl
//
//  Created by Claude on 15/01/2026.
//

import SwiftUI

// MARK: - Synergy Line View

/// Vue affichant les lignes lumineuses entre les bulles en synergie
struct SynergyLineView: View {

    // MARK: - Properties

    /// Position du premier point (bulle A)
    let startPoint: CGPoint

    /// Position du deuxième point (bulle B)
    let endPoint: CGPoint

    /// Intensité de la synergie (0-1)
    let intensity: Double

    /// Type de synergie pour la couleur
    let synergyType: SynergyType

    // MARK: - State

    @State private var animationPhase: Double = 0
    @State private var glowOpacity: Double = 0.3

    // MARK: - Body

    var body: some View {
        Canvas { context, size in
            // Draw the curved synergy line
            let path = createCurvedPath()

            // Main line with gradient
            context.stroke(
                path,
                with: .linearGradient(
                    gradient,
                    startPoint: startPoint,
                    endPoint: endPoint
                ),
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )

            // Glow effect
            context.blendMode = .plusLighter
            context.stroke(
                path,
                with: .linearGradient(
                    glowGradient,
                    startPoint: startPoint,
                    endPoint: endPoint
                ),
                style: StrokeStyle(
                    lineWidth: lineWidth + 4,
                    lineCap: .round
                )
            )

            // Animated particle along the line
            let particlePosition = pointOnPath(at: animationPhase)
            let particleRect = CGRect(
                x: particlePosition.x - 4,
                y: particlePosition.y - 4,
                width: 8,
                height: 8
            )

            context.fill(
                Path(ellipseIn: particleRect),
                with: .color(lineColor.opacity(0.9))
            )

            // Particle glow
            let glowRect = CGRect(
                x: particlePosition.x - 8,
                y: particlePosition.y - 8,
                width: 16,
                height: 16
            )
            context.fill(
                Path(ellipseIn: glowRect),
                with: .radialGradient(
                    Gradient(colors: [lineColor.opacity(0.5), .clear]),
                    center: particlePosition,
                    startRadius: 0,
                    endRadius: 12
                )
            )
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Computed Properties

    private var lineColor: Color {
        synergyType.category.color
    }

    private var gradient: Gradient {
        Gradient(colors: [
            lineColor.opacity(0.3),
            lineColor.opacity(0.7),
            lineColor.opacity(0.3)
        ])
    }

    private var glowGradient: Gradient {
        Gradient(colors: [
            lineColor.opacity(glowOpacity * 0.3),
            lineColor.opacity(glowOpacity * 0.6),
            lineColor.opacity(glowOpacity * 0.3)
        ])
    }

    private var lineWidth: CGFloat {
        1.5 + CGFloat(intensity) * 2.0
    }

    // MARK: - Path Creation

    private func createCurvedPath() -> Path {
        var path = Path()

        // Calculate control point for bezier curve
        let midX = (startPoint.x + endPoint.x) / 2
        let midY = (startPoint.y + endPoint.y) / 2

        // Offset control point perpendicular to the line
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let length = sqrt(dx * dx + dy * dy)

        // Perpendicular offset based on distance (more curve for longer lines)
        let curveOffset = min(length * 0.2, 40)
        let controlX = midX - (dy / length) * curveOffset
        let controlY = midY + (dx / length) * curveOffset

        path.move(to: startPoint)
        path.addQuadCurve(
            to: endPoint,
            control: CGPoint(x: controlX, y: controlY)
        )

        return path
    }

    private func pointOnPath(at t: Double) -> CGPoint {
        // Quadratic bezier point calculation
        let midX = (startPoint.x + endPoint.x) / 2
        let midY = (startPoint.y + endPoint.y) / 2

        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let length = sqrt(dx * dx + dy * dy)

        let curveOffset = min(length * 0.2, 40)
        let controlX = midX - (dy / length) * curveOffset
        let controlY = midY + (dx / length) * curveOffset

        let control = CGPoint(x: controlX, y: controlY)

        // B(t) = (1-t)²P₀ + 2(1-t)tP₁ + t²P₂
        let oneMinusT = 1 - t
        let x = oneMinusT * oneMinusT * startPoint.x + 2 * oneMinusT * t * control.x + t * t * endPoint.x
        let y = oneMinusT * oneMinusT * startPoint.y + 2 * oneMinusT * t * control.y + t * t * endPoint.y

        return CGPoint(x: x, y: y)
    }

    // MARK: - Animations

    private func startAnimations() {
        // Particle animation along the line
        withAnimation(.linear(duration: 2.0 / max(intensity, 0.3)).repeatForever(autoreverses: false)) {
            animationPhase = 1.0
        }

        // Glow pulsing
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowOpacity = 0.6 + intensity * 0.4
        }
    }
}

// MARK: - Synergy Lines Overlay

/// Overlay qui affiche toutes les lignes de synergie sur l'OrbitalView
struct SynergyLinesOverlay: View {

    /// Synergies à afficher
    let synergies: [DetectedSynergy]

    /// Mapping des IDs de connexion vers leurs positions
    let connectionPositions: [String: CGPoint]

    var body: some View {
        ZStack {
            ForEach(synergies.filter { !$0.isActedUpon }) { synergy in
                if let startPos = connectionPositions[synergy.connectionAId],
                   let endPos = connectionPositions[synergy.connectionBId] {
                    SynergyLineView(
                        startPoint: startPos,
                        endPoint: endPos,
                        intensity: synergy.score,
                        synergyType: synergy.synergyType
                    )
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Synergy Line") {
    ZStack {
        Color(red: 0.04, green: 0.05, blue: 0.15)
            .ignoresSafeArea()

        SynergyLineView(
            startPoint: CGPoint(x: 100, y: 200),
            endPoint: CGPoint(x: 300, y: 400),
            intensity: 0.75,
            synergyType: .vcStartup
        )
    }
}
