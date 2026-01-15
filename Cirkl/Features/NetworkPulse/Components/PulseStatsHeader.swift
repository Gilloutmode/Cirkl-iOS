import SwiftUI

// MARK: - Pulse Stats Header
/// Affiche les 3 indicateurs de santé du réseau avec effet Liquid Glass
/// Active (vert) | Dormant (jaune) | At Risk (rouge)

struct PulseStatsHeader: View {

    let activeCount: Int
    let dormantCount: Int
    let atRiskCount: Int
    let totalCount: Int

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Title
            Text("Santé de ton réseau")
                .font(DesignTokens.Typography.title2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            // Stats circles
            HStack(spacing: DesignTokens.Spacing.lg) {
                StatCircle(
                    count: activeCount,
                    label: "Actives",
                    emoji: "🟢",
                    color: DesignTokens.Colors.mint
                )

                StatCircle(
                    count: dormantCount,
                    label: "Dormantes",
                    emoji: "🟡",
                    color: DesignTokens.Colors.warning
                )

                StatCircle(
                    count: atRiskCount,
                    label: "À risque",
                    emoji: "🔴",
                    color: DesignTokens.Colors.error
                )
            }

            // Total
            Text("\(totalCount) connexions au total")
                .font(DesignTokens.Typography.caption1)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
        .padding(.vertical, DesignTokens.Spacing.lg)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity)
        .glassBackground()
    }
}

// MARK: - Stat Circle Component

private struct StatCircle: View {
    let count: Int
    let label: String
    let emoji: String
    let color: Color

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // Circle with count
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.3), color.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: 10)
                    .opacity(count > 0 ? 1 : 0.3)

                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .strokeBorder(color.opacity(0.5), lineWidth: 2)
                    )

                // Count
                VStack(spacing: 2) {
                    Text("\(count)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(color)

                    Text(emoji)
                        .font(.system(size: 12))
                }
            }
            .scaleEffect(isAnimating ? 1.05 : 1.0)

            // Label
            Text(label)
                .font(DesignTokens.Typography.caption1)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
        .onAppear {
            if count > 0 {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
    }
}

// MARK: - Glass Background Modifier

private extension View {
    @ViewBuilder
    func glassBackground() -> some View {
        if #available(iOS 26.0, *) {
            self.background {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                    .fill(.clear)
                    .glassEffect()
            }
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.large))
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        PulseStatsHeader(
            activeCount: 12,
            dormantCount: 23,
            atRiskCount: 3,
            totalCount: 38
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
