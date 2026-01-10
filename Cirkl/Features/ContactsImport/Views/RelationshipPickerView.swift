import SwiftUI

// MARK: - RelationshipPickerView
/// Vue pour sélectionner le type de relation avec une UX incitative
struct RelationshipPickerView: View {

    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedRelationship: RelationshipType?
    let contactName: String
    let onSave: (RelationshipType?) -> Void

    @State private var selectedCategory: RelationshipCategory?
    @State private var selectedSubtype: RelationshipSubtype?

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header incitative
                    headerSection

                    // Category selection
                    if selectedCategory == nil {
                        categorySelectionSection
                    } else {
                        // Selected category with subtypes
                        selectedCategorySection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Type de relation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Passer") {
                        selectedRelationship = nil
                        onSave(nil)
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .onAppear {
                // Initialize from existing selection
                if let existing = selectedRelationship {
                    selectedCategory = existing.category
                    selectedSubtype = existing.subtype
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Icon with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.mint.opacity(0.3), .blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Image(systemName: "person.2.fill")
                    .font(.title2)
                    .foregroundStyle(.mint)
            }

            Text("Comment connaissez-vous \(contactName) ?")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Cette information aide CirKL AI à mieux comprendre votre réseau")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Category Selection
    private var categorySelectionSection: some View {
        VStack(spacing: 12) {
            ForEach(RelationshipCategory.allCases) { category in
                CategoryCard(
                    category: category,
                    isSelected: selectedCategory == category,
                    onTap: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                    }
                )
            }
        }
    }

    // MARK: - Selected Category Section
    @ViewBuilder
    private var selectedCategorySection: some View {
        if let category = selectedCategory {
            VStack(spacing: 16) {
                // Back button with category info
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = nil
                            selectedSubtype = nil
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Retour")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.mint)
                    }

                    Spacer()

                    Label(category.displayName, systemImage: category.icon)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(category.color)
                }

                // Subtypes grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(category.subtypes) { subtype in
                        SubtypeCard(
                            subtype: subtype,
                            isSelected: selectedSubtype == subtype,
                            color: category.color,
                            onTap: {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                selectedSubtype = subtype
                                saveAndDismiss()
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Actions
    private func saveAndDismiss() {
        guard let category = selectedCategory else { return }
        let relationship = RelationshipType(category: category, subtype: selectedSubtype)
        // Mettre à jour le binding directement pour garantir la synchronisation
        selectedRelationship = relationship
        onSave(relationship)
        dismiss()
    }
}

// MARK: - CategoryCard
private struct CategoryCard: View {
    let category: RelationshipCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: category.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(category.color)
                }

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(categoryDescription(category))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func categoryDescription(_ category: RelationshipCategory) -> String {
        switch category {
        case .family: return "Frère, sœur, parents, cousins..."
        case .innerCircle: return "Amis proches, confidents..."
        case .professional: return "Collègues, clients, mentors..."
        case .network: return "Connaissances, networking..."
        case .education: return "Camarades, professeurs..."
        }
    }
}

// MARK: - SubtypeCard
private struct SubtypeCard: View {
    let subtype: RelationshipSubtype
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(subtype.displayName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? color : Color(UIColor.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Picker for inline use
struct RelationshipChipView: View {
    let relationship: RelationshipType?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                if let rel = relationship {
                    Image(systemName: rel.icon)
                        .foregroundStyle(rel.color)
                    Text(rel.displayName)
                        .foregroundStyle(.primary)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.mint)
                    Text("Ajouter une relation")
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview("Picker") {
    RelationshipPickerView(
        selectedRelationship: .constant(nil),
        contactName: "David",
        onSave: { _ in }
    )
}

#Preview("Chip - Empty") {
    RelationshipChipView(relationship: nil) { }
        .padding()
}

#Preview("Chip - With Value") {
    RelationshipChipView(relationship: RelationshipType(subtype: .brother)) { }
        .padding()
}
