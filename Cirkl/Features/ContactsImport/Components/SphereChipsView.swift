import SwiftUI

// MARK: - SphereChipsView
/// Vue de sélection multiple des sphères de vie sous forme de chips
struct SphereChipsView: View {
    @Binding var selectedSpheres: Set<Sphere>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sphères de vie")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("Dans quels contextes connaissez-vous cette personne ?")
                .font(.caption)
                .foregroundStyle(.tertiary)

            FlowLayout(spacing: 8) {
                ForEach(Sphere.allCases) { sphere in
                    SphereChip(
                        sphere: sphere,
                        isSelected: selectedSpheres.contains(sphere),
                        onTap: { toggleSphere(sphere) }
                    )
                }
            }
        }
    }

    private func toggleSphere(_ sphere: Sphere) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedSpheres.contains(sphere) {
                selectedSpheres.remove(sphere)
            } else {
                selectedSpheres.insert(sphere)
            }
        }
    }
}

// MARK: - SphereChip
/// Chip individuel pour une sphère
struct SphereChip: View {
    let sphere: Sphere
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: sphere.icon)
                    .font(.system(size: 14))
                Text(sphere.displayName)
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? sphere.color.opacity(0.2) : Color(.systemGray6))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? sphere.color : Color.clear, lineWidth: 2)
            )
            .foregroundStyle(isSelected ? sphere.color : .secondary)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Compact Version
/// Version compacte pour affichage en lecture seule
struct SphereChipsCompactView: View {
    let spheres: Set<Sphere>

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(Array(spheres).sorted { $0.rawValue < $1.rawValue }) { sphere in
                HStack(spacing: 4) {
                    Image(systemName: sphere.icon)
                        .font(.system(size: 10))
                    Text(sphere.shortDescription)
                        .font(.caption2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(sphere.color.opacity(0.15))
                .foregroundStyle(sphere.color)
                .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Preview
#Preview("SphereChipsView") {
    struct PreviewWrapper: View {
        @State private var selected: Set<Sphere> = [.professional]

        var body: some View {
            VStack(spacing: 20) {
                SphereChipsView(selectedSpheres: $selected)

                Divider()

                Text("Sélectionnées: \(selected.map { $0.displayName }.joined(separator: ", "))")
                    .font(.caption)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("Compact") {
    SphereChipsCompactView(spheres: [.professional, .personal])
        .padding()
}
