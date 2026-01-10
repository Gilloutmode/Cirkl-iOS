import SwiftUI

// MARK: - ContactRow
/// Ligne de contact avec sélection pour l'import
struct ContactRow: View {

    // MARK: - Properties
    let contact: PhoneContact
    let isSelected: Bool
    let onTap: () -> Void

    // MARK: - Body
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Avatar
                contactAvatar

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.fullName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)

                    if let phone = contact.primaryPhone {
                        Text(phone)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Checkbox
                selectionIndicator
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.mint.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.mint.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    // MARK: - Avatar
    private var contactAvatar: some View {
        ZStack {
            if let image = contact.contactImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(avatarGradient)
                    .frame(width: 48, height: 48)

                Text(contact.initials)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }

    private var avatarGradient: LinearGradient {
        // Couleur basée sur les initiales pour consistance
        let colors = avatarColors(for: contact.fullName)
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func avatarColors(for name: String) -> [Color] {
        let hash = abs(name.hashValue)
        let colorSets: [[Color]] = [
            [Color(red: 0.55, green: 0.75, blue: 0.85), Color(red: 0.35, green: 0.55, blue: 0.75)],
            [Color(red: 0.75, green: 0.55, blue: 0.70), Color(red: 0.55, green: 0.35, blue: 0.60)],
            [Color(red: 0.50, green: 0.70, blue: 0.60), Color(red: 0.30, green: 0.50, blue: 0.45)],
            [Color(red: 0.85, green: 0.65, blue: 0.45), Color(red: 0.70, green: 0.45, blue: 0.30)],
            [Color(red: 0.65, green: 0.60, blue: 0.75), Color(red: 0.45, green: 0.40, blue: 0.60)],
            [Color(red: 0.80, green: 0.55, blue: 0.55), Color(red: 0.60, green: 0.35, blue: 0.40)]
        ]
        return colorSets[hash % colorSets.count]
    }

    // MARK: - Selection Indicator
    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .stroke(isSelected ? Color.mint : Color.gray.opacity(0.3), lineWidth: 2)
                .frame(width: 26, height: 26)

            if isSelected {
                Circle()
                    .fill(Color.mint)
                    .frame(width: 26, height: 26)

                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Contact Section Header
/// Header de section pour le regroupement alphabétique
struct ContactSectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Empty Contacts View
/// Vue affichée quand aucun contact n'est trouvé
struct EmptyContactsView: View {
    let searchQuery: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: searchQuery.isEmpty ? "person.crop.circle.badge.questionmark" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(searchQuery.isEmpty ? "Aucun contact" : "Aucun résultat")
                .font(.headline)
                .foregroundStyle(.primary)

            Text(searchQuery.isEmpty
                 ? "Vos contacts apparaîtront ici une fois l'accès autorisé."
                 : "Aucun contact ne correspond à \"\(searchQuery)\"")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
#Preview("Contact Row") {
    VStack(spacing: 8) {
        ContactRow(
            contact: PhoneContact.mockContacts[0],
            isSelected: false,
            onTap: {}
        )

        ContactRow(
            contact: PhoneContact.mockContacts[1],
            isSelected: true,
            onTap: {}
        )

        ContactRow(
            contact: PhoneContact.mockContacts[2],
            isSelected: false,
            onTap: {}
        )
    }
    .padding()
}
