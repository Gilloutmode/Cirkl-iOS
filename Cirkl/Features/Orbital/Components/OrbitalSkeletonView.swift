//
//  OrbitalSkeletonView.swift
//  Cirkl
//
//  Created by Claude on 12/01/2026.
//

import SwiftUI

// MARK: - Orbital Skeleton View

/// Skeleton loading view for the orbital interface
/// Displays placeholder bubbles while connections are loading
struct OrbitalSkeletonView: View {

    // MARK: - Properties

    let centerX: CGFloat
    let centerY: CGFloat
    let width: CGFloat
    let height: CGFloat

    /// Number of skeleton bubbles to display
    private let skeletonCount = 6

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        ZStack {
            // Skeleton bubbles positioned in orbital pattern
            ForEach(0..<skeletonCount, id: \.self) { index in
                skeletonBubble(at: index)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Chargement des connexions")
    }

    // MARK: - Skeleton Bubble

    @ViewBuilder
    private func skeletonBubble(at index: Int) -> some View {
        let position = calculatePosition(for: index)
        let size = calculateSize(for: index)
        let delay = Double(index) * 0.1

        ConnectionBubbleSkeleton(size: size)
            .position(x: position.x, y: position.y)
            .opacity(reduceMotion ? 0.6 : 1.0)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.3).delay(delay),
                value: index
            )
    }

    // MARK: - Position Calculation

    /// Calculate position for skeleton bubble based on index
    private func calculatePosition(for index: Int) -> CGPoint {
        // Distribute bubbles in a circular pattern around center
        let angle = (2 * .pi / Double(skeletonCount)) * Double(index) - .pi / 2
        let radius = min(width, height) * 0.28

        let x = centerX + radius * cos(angle)
        let y = centerY + radius * sin(angle)

        return CGPoint(x: x, y: y)
    }

    /// Calculate size for skeleton bubble
    private func calculateSize(for index: Int) -> CGFloat {
        // Vary sizes slightly for visual interest
        let baseSizes: [CGFloat] = [70, 60, 65, 55, 75, 58]
        return baseSizes[index % baseSizes.count]
    }
}

// MARK: - Preview

#Preview("Orbital Skeleton Loading") {
    GeometryReader { geometry in
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()

            OrbitalSkeletonView(
                centerX: geometry.size.width / 2,
                centerY: geometry.size.height * 0.42,
                width: geometry.size.width,
                height: geometry.size.height
            )

            // Center placeholder
            Circle()
                .fill(DesignTokens.Colors.surface)
                .frame(width: 80, height: 80)
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height * 0.42
                )
        }
    }
    .preferredColorScheme(.dark)
}
