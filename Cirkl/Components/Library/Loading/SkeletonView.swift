//
//  SkeletonView.swift
//  Cirkl
//
//  Created by Claude on 12/01/2026.
//

import SwiftUI

// MARK: - Skeleton View Component

/// A shimmer skeleton loading placeholder
/// Used to show content loading state with animated shimmer effect
struct SkeletonView: View {

    // MARK: - Properties

    /// Shape of the skeleton
    var shape: SkeletonShape = .rectangle

    /// Corner radius for rectangle shapes
    var cornerRadius: CGFloat = DesignTokens.Radius.medium

    /// Width of the skeleton (nil = fill available space)
    var width: CGFloat? = nil

    /// Height of the skeleton
    var height: CGFloat = 20

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - State

    @State private var shimmerOffset: CGFloat = -1

    // MARK: - Computed Properties

    private var baseColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color.black.opacity(0.08)
    }

    private var shimmerColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.2)
            : Color.white.opacity(0.6)
    }

    // MARK: - Body

    var body: some View {
        skeletonShape
            .fill(baseColor)
            .overlay {
                if !reduceMotion {
                    shimmerGradient
                        .mask(skeletonShape)
                }
            }
            .frame(width: width, height: height)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    shimmerOffset = 2
                }
            }
            .accessibilityLabel("Chargement en cours")
            .accessibilityHidden(true)
    }

    // MARK: - Skeleton Shape

    private var skeletonShape: AnyShape {
        switch shape {
        case .rectangle:
            AnyShape(RoundedRectangle(cornerRadius: cornerRadius))
        case .circle:
            AnyShape(Circle())
        case .capsule:
            AnyShape(Capsule())
        }
    }

    // MARK: - Shimmer Gradient

    private var shimmerGradient: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [
                    .clear,
                    shimmerColor,
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 0.6)
            .offset(x: shimmerOffset * geometry.size.width)
        }
    }
}

// MARK: - Skeleton Shape Enum

enum SkeletonShape {
    case rectangle
    case circle
    case capsule
}

// MARK: - Skeleton Row Component

/// A complete skeleton row with avatar, title, and subtitle
struct SkeletonRow: View {

    var avatarSize: CGFloat = 48
    var showSubtitle: Bool = true

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Avatar
            SkeletonView(shape: .circle, height: avatarSize)
                .frame(width: avatarSize)

            // Text content
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                SkeletonView(
                    cornerRadius: DesignTokens.Radius.small,
                    width: 140,
                    height: 16
                )

                if showSubtitle {
                    SkeletonView(
                        cornerRadius: DesignTokens.Radius.small,
                        width: 200,
                        height: 12
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
}

// MARK: - Connection Bubble Skeleton

/// Skeleton placeholder for orbital connection bubbles
struct ConnectionBubbleSkeleton: View {

    var size: CGFloat = 60

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.3,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size * 1.2, height: size * 1.2)
                .scaleEffect(isAnimating ? 1.1 : 1.0)

            // Main bubble
            SkeletonView(shape: .circle, height: size)
                .frame(width: size)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Chat Message Skeleton

/// Skeleton placeholder for chat messages
struct ChatMessageSkeleton: View {

    var isFromUser: Bool = false

    var body: some View {
        HStack {
            if isFromUser { Spacer() }

            VStack(alignment: isFromUser ? .trailing : .leading, spacing: DesignTokens.Spacing.xs) {
                SkeletonView(
                    cornerRadius: DesignTokens.Radius.medium,
                    width: 200,
                    height: 16
                )

                SkeletonView(
                    cornerRadius: DesignTokens.Radius.medium,
                    width: 150,
                    height: 16
                )

                SkeletonView(
                    cornerRadius: DesignTokens.Radius.medium,
                    width: 100,
                    height: 16
                )
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                    .fill(Color.white.opacity(0.05))
            )

            if !isFromUser { Spacer() }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
    }
}

// MARK: - Skeleton List

/// A list of skeleton rows for loading states
struct SkeletonList: View {

    var count: Int = 5
    var showSubtitles: Bool = true

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(0..<count, id: \.self) { _ in
                SkeletonRow(showSubtitle: showSubtitles)
            }
        }
    }
}

// MARK: - View Modifier for Skeleton Loading

extension View {

    /// Shows a skeleton overlay when loading
    func skeletonLoading(_ isLoading: Bool) -> some View {
        self.redacted(reason: isLoading ? .placeholder : [])
            .shimmering(active: isLoading)
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {

    var active: Bool

    @State private var phase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                if active && !reduceMotion {
                    GeometryReader { geometry in
                        LinearGradient(
                            colors: [
                                .clear,
                                Color.white.opacity(0.3),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                    }
                    .mask(content)
                    .onAppear {
                        withAnimation(
                            .linear(duration: 1.5)
                            .repeatForever(autoreverses: false)
                        ) {
                            phase = 1
                        }
                    }
                }
            }
    }
}

extension View {
    func shimmering(active: Bool = true) -> some View {
        modifier(ShimmerModifier(active: active))
    }
}

// MARK: - Previews

#Preview("Skeleton View") {
    ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()

        VStack(spacing: 24) {
            SkeletonView(shape: .rectangle, width: 200, height: 20)
            SkeletonView(shape: .circle, height: 60)
            SkeletonView(shape: .capsule, width: 120, height: 36)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Skeleton Row") {
    ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()

        SkeletonList(count: 5)
    }
    .preferredColorScheme(.dark)
}

#Preview("Connection Bubble Skeleton") {
    ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()

        HStack(spacing: 20) {
            ConnectionBubbleSkeleton(size: 50)
            ConnectionBubbleSkeleton(size: 60)
            ConnectionBubbleSkeleton(size: 70)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Chat Message Skeleton") {
    ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()

        VStack(spacing: 16) {
            ChatMessageSkeleton(isFromUser: false)
            ChatMessageSkeleton(isFromUser: true)
            ChatMessageSkeleton(isFromUser: false)
        }
    }
    .preferredColorScheme(.dark)
}
