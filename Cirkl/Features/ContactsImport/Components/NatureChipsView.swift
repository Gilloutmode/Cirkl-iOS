import SwiftUI

// MARK: - NatureChipsView
/// Vue de sélection multiple des natures de relation sous forme de chips
/// Les natures affichées sont filtrées selon les sphères sélectionnées
struct NatureChipsView: View {
    @Binding var selectedNatures: Set<RelationNature>
    let selectedSpheres: Set<Sphere>

    /// Natures disponibles basées sur les sphères sélectionnées
    private var availableNatures: [RelationNature] {
        RelationNature.natures(for: selectedSpheres)
    }

    /// Natures groupées par sphère pour l'affichage
    private var groupedNatures: [(sphere: Sphere, natures: [RelationNature])] {
        let relevantSpheres = selectedSpheres.isEmpty ? Sphere.allCases : Array(selectedSpheres)
        return relevantSpheres
            .sorted { $0.rawValue < $1.rawValue }
            .map { sphere in
                (sphere: sphere, natures: RelationNature.natures(for: sphere))
            }
            .filter { !$0.natures.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Type de relation")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("Comment décririez-vous votre relation ?")
                .font(.caption)
                .foregroundStyle(.tertiary)

            if selectedSpheres.isEmpty {
                // Message si aucune sphère sélectionnée
                Text("Sélectionnez d'abord une sphère de vie")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // Affichage groupé par sphère
                ForEach(groupedNatures, id: \.sphere) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        // Header de groupe
                        HStack(spacing: 4) {
                            Image(systemName: group.sphere.icon)
                                .font(.caption2)
                            Text(group.sphere.displayName)
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(group.sphere.color)

                        // Chips du groupe
                        FlowLayout(spacing: 8) {
                            ForEach(group.natures) { nature in
                                NatureChip(
                                    nature: nature,
                                    isSelected: selectedNatures.contains(nature),
                                    accentColor: group.sphere.color,
                                    onTap: { toggleNature(nature) }
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    private func toggleNature(_ nature: RelationNature) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedNatures.contains(nature) {
                selectedNatures.remove(nature)
            } else {
                selectedNatures.insert(nature)
            }
        }
    }
}

// MARK: - NatureChip
/// Chip individuel pour une nature de relation
struct NatureChip: View {
    let nature: RelationNature
    let isSelected: Bool
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: nature.icon)
                    .font(.system(size: 12))
                Text(nature.displayName)
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? accentColor.opacity(0.2) : Color(.systemGray6))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 1.5)
            )
            .foregroundStyle(isSelected ? accentColor : .secondary)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Compact Version
/// Version compacte pour affichage en lecture seule
struct NatureChipsCompactView: View {
    let natures: Set<RelationNature>

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(Array(natures).sorted { $0.rawValue < $1.rawValue }) { nature in
                HStack(spacing: 3) {
                    Image(systemName: nature.icon)
                        .font(.system(size: 9))
                    Text(nature.displayName)
                        .font(.caption2)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color(.systemGray5))
                .foregroundStyle(.secondary)
                .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Preview
#Preview("NatureChipsView") {
    struct PreviewWrapper: View {
        @State private var spheres: Set<Sphere> = [.professional, .personal]
        @State private var natures: Set<RelationNature> = [.mentor]

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    SphereChipsView(selectedSpheres: $spheres)

                    Divider()

                    NatureChipsView(
                        selectedNatures: $natures,
                        selectedSpheres: spheres
                    )

                    Divider()

                    Text("Sélectionnées: \(natures.map { $0.displayName }.joined(separator: ", "))")
                        .font(.caption)
                }
                .padding()
            }
        }
    }

    return PreviewWrapper()
}

#Preview("Compact") {
    NatureChipsCompactView(natures: [.mentor, .friend])
        .padding()
}
