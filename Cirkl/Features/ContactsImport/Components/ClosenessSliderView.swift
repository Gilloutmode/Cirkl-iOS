import SwiftUI

// MARK: - ClosenessSliderView
/// Vue de sélection du niveau de proximité avec un slider
struct ClosenessSliderView: View {
    @Binding var closeness: ClosenessLevel

    /// Valeur pour le slider (conversion Int -> Double)
    private var sliderValue: Binding<Double> {
        Binding(
            get: { Double(closeness.rawValue) },
            set: { closeness = ClosenessLevel(rawValue: Int($0)) ?? .moderate }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Proximité")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(closeness.emoji) \(closeness.displayName)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(closeness.color)
            }

            // Slider customisé
            VStack(spacing: 8) {
                Slider(value: sliderValue, in: 1...5, step: 1)
                    .tint(closeness.color)
                    .sensoryFeedback(.selection, trigger: closeness)

                // Labels sous le slider
                HStack {
                    Text("Distant")
                        .font(.caption2)
                    Spacer()
                    Text("Très proche")
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
            }

            // Description du niveau actuel
            Text(closeness.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - ClosenessIndicator
/// Indicateur compact du niveau de proximité (lecture seule)
struct ClosenessIndicator: View {
    let closeness: ClosenessLevel
    var showLabel: Bool = true

    var body: some View {
        HStack(spacing: 4) {
            // Dots
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { level in
                    Circle()
                        .fill(level <= closeness.rawValue ? closeness.color : Color(.systemGray4))
                        .frame(width: 6, height: 6)
                }
            }

            if showLabel {
                Text(closeness.emoji)
                    .font(.caption)
            }
        }
    }
}

// MARK: - ClosenessStepperView
/// Alternative au slider: sélection par boutons discrets
struct ClosenessStepperView: View {
    @Binding var closeness: ClosenessLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Proximité")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(ClosenessLevel.allCases) { level in
                    ClosenessButton(
                        level: level,
                        isSelected: closeness == level,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                closeness = level
                            }
                        }
                    )
                }
            }

            // Description
            Text(closeness.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

// MARK: - ClosenessButton
/// Bouton individuel pour un niveau de proximité
private struct ClosenessButton: View {
    let level: ClosenessLevel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(level.emoji)
                    .font(.title2)
                Text("\(level.rawValue)")
                    .font(.caption2.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? level.color.opacity(0.2) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? level.color : Color.clear, lineWidth: 2)
            )
            .foregroundStyle(isSelected ? level.color : .secondary)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Preview
#Preview("Slider") {
    struct PreviewWrapper: View {
        @State private var closeness: ClosenessLevel = .moderate

        var body: some View {
            VStack(spacing: 30) {
                ClosenessSliderView(closeness: $closeness)

                Divider()

                ClosenessIndicator(closeness: closeness)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("Stepper") {
    struct PreviewWrapper: View {
        @State private var closeness: ClosenessLevel = .moderate

        var body: some View {
            ClosenessStepperView(closeness: $closeness)
                .padding()
        }
    }

    return PreviewWrapper()
}
