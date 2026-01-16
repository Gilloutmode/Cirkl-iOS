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
            .contentShape(Capsule()) // Zone de tap AVANT background
            .background(pillBackground) // Sans closure pour éviter hit testing issues
        }
        .buttonStyle(.borderless) // borderless au lieu de plain pour meilleur hit testing
    }

    @ViewBuilder
    private var pillBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(isSelected ? DesignTokens.Colors.electricBlue : .clear)
                .glassEffect(.regular, in: .capsule)
        } else {
            if isSelected {
                Capsule()
                    .fill(DesignTokens.Colors.electricBlue)
            } else {
                Capsule()
                    .fill(.ultraThinMaterial)
            }
        }
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
