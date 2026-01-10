import SwiftUI

// MARK: - RelationshipProfilePicker
/// Vue principale de sélection du profil relationnel multi-dimensionnel
struct RelationshipProfilePicker: View {
    @Binding var profile: RelationshipProfile
    @Environment(\.dismiss) private var dismiss

    @State private var showingAdvancedOptions = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header explicatif
                    headerSection

                    // Section Sphères
                    sectionCard {
                        SphereChipsView(selectedSpheres: $profile.spheres)
                    }

                    // Section Natures
                    sectionCard {
                        NatureChipsView(
                            selectedNatures: $profile.natures,
                            selectedSpheres: profile.spheres
                        )
                    }

                    // Section Proximité
                    sectionCard {
                        ClosenessSliderView(closeness: $profile.closeness)
                    }

                    // Options avancées (pliables)
                    advancedOptionsSection

                    // Résumé
                    if !profile.isEmpty {
                        summarySection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Définir la relation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 40))
                .foregroundStyle(.blue)

            Text("Relation multi-dimensionnelle")
                .font(.headline)

            Text("Une personne peut appartenir à plusieurs sphères et avoir plusieurs types de relation avec vous.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Advanced Options Section
    private var advancedOptionsSection: some View {
        DisclosureGroup(isExpanded: $showingAdvancedOptions) {
            VStack(spacing: 16) {
                // Fréquence d'interaction
                frequencyPicker

                // Contexte de rencontre
                contextField

                // Intérêts partagés
                interestsField
            }
            .padding(.top, 12)
        } label: {
            HStack {
                Image(systemName: "slider.horizontal.3")
                Text("Options avancées")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Frequency Picker
    private var frequencyPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fréquence d'interaction")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Picker("Fréquence", selection: Binding(
                get: { profile.interactionFrequency ?? .monthly },
                set: { profile.interactionFrequency = $0 }
            )) {
                ForEach(InteractionFrequency.allCases) { frequency in
                    HStack {
                        Image(systemName: frequency.icon)
                        Text(frequency.displayName)
                    }
                    .tag(frequency)
                }
            }
            .pickerStyle(.menu)
        }
    }

    // MARK: - Context Field
    private var contextField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Contexte de rencontre")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            TextField(
                "Ex: Conférence SwiftUI 2024",
                text: Binding(
                    get: { profile.meetingContext ?? "" },
                    set: { profile.meetingContext = $0.isEmpty ? nil : $0 }
                )
            )
            .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Interests Field
    private var interestsField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Intérêts partagés")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            TextField(
                "Ex: Swift, Design, Entrepreneuriat",
                text: Binding(
                    get: { profile.sharedInterests.joined(separator: ", ") },
                    set: { profile.sharedInterests = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                )
            )
            .textFieldStyle(.roundedBorder)

            Text("Séparez les intérêts par des virgules")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Summary Section
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Résumé")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                // Sphères
                if !profile.spheres.isEmpty {
                    SphereChipsCompactView(spheres: profile.spheres)
                }

                Spacer()

                // Proximité
                ClosenessIndicator(closeness: profile.closeness)
            }

            // Natures
            if !profile.natures.isEmpty {
                NatureChipsCompactView(natures: profile.natures)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Section Card Helper
    @ViewBuilder
    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Compact Display View
/// Vue compacte pour afficher un profil relationnel (lecture seule)
struct RelationshipProfileCompactView: View {
    let profile: RelationshipProfile

    var body: some View {
        if profile.isEmpty {
            Text("Non défini")
                .font(.caption)
                .foregroundStyle(.tertiary)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                // Sphères + Proximité sur une ligne
                HStack {
                    SphereChipsCompactView(spheres: profile.spheres)
                    Spacer()
                    ClosenessIndicator(closeness: profile.closeness, showLabel: true)
                }

                // Natures
                if !profile.natures.isEmpty {
                    NatureChipsCompactView(natures: profile.natures)
                }
            }
        }
    }
}

// MARK: - Button to Open Picker
/// Bouton pour ouvrir le picker de profil relationnel
struct RelationshipProfileButton: View {
    @Binding var profile: RelationshipProfile
    @State private var showingPicker = false

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Relation")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if profile.isEmpty {
                        Text("Définir la relation")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    } else {
                        Text(profile.summary)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPicker) {
            RelationshipProfilePicker(profile: $profile)
        }
    }
}

// MARK: - Preview
#Preview("Full Picker") {
    struct PreviewWrapper: View {
        @State private var profile = RelationshipProfile.previewMultiDimensional

        var body: some View {
            RelationshipProfilePicker(profile: $profile)
        }
    }

    return PreviewWrapper()
}

#Preview("Button") {
    struct PreviewWrapper: View {
        @State private var profile = RelationshipProfile()

        var body: some View {
            VStack(spacing: 20) {
                RelationshipProfileButton(profile: $profile)

                Divider()

                RelationshipProfileCompactView(profile: profile)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("Compact View") {
    VStack(spacing: 20) {
        RelationshipProfileCompactView(profile: .previewMultiDimensional)
        RelationshipProfileCompactView(profile: .previewSimple)
        RelationshipProfileCompactView(profile: .empty)
    }
    .padding()
}
