import SwiftUI

// MARK: - Filter Pill
/// Composant de filtre pour le Feed
/// Affiche un titre et un compteur optionnel

struct FilterPill: View {
    let title: String
    let count: Int?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(DesignTokens.Typography.buttonSmall)

                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(DesignTokens.Typography.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.2) : DesignTokens.Colors.textTertiary.opacity(0.2))
                        )
                }
            }
            .foregroundStyle(
                isSelected ? Color.white : DesignTokens.Colors.textSecondary
            )
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? DesignTokens.Colors.electricBlue : DesignTokens.Colors.cardBackground)
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? Color.clear : DesignTokens.Colors.cardBorder,
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    HStack {
        FilterPill(title: "Tout", count: nil, isSelected: true) { }
        FilterPill(title: "Updates", count: 3, isSelected: false) { }
        FilterPill(title: "Synergies", count: 2, isSelected: false) { }
    }
    .padding()
    .background(Color.black)
}
