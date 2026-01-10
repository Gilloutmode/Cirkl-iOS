import SwiftUI

// MARK: - Connections List View
/// Vue liste affichant toutes les connexions avec leurs détails
struct ConnectionsListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var neo4jService = Neo4jService.shared

    @State private var contacts: [OrbitalContact]
    @State private var searchText = ""
    @State private var selectedContact: OrbitalContact?
    @State private var showAddConnection = false

    init(contacts: [OrbitalContact]) {
        _contacts = State(initialValue: contacts)
    }

    private var filteredContacts: [OrbitalContact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter { $0.matches(query: searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(white: 0.97)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    // Stats header
                    statsHeader
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    // List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredContacts) { contact in
                                Button {
                                    selectedContact = contact
                                } label: {
                                    ConnectionRowView(contact: contact)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Connexions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color(white: 0.7))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddConnection = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color(red: 0.5, green: 0.3, blue: 0.8))
                    }
                }
            }
            .sheet(item: $selectedContact) { contact in
                ProfileDetailView(contact: contact) { updated in
                    // Update local list when contact is modified
                    if let index = contacts.firstIndex(where: { $0.id == updated.id }) {
                        contacts[index] = updated
                    }
                }
            }
            .sheet(isPresented: $showAddConnection) {
                AddConnectionView { newContact in
                    contacts.append(newContact)
                }
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(white: 0.5))

            TextField("Rechercher une connexion...", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(Color(white: 0.2))

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(white: 0.5))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        )
    }

    // MARK: - Stats Header
    private var statsHeader: some View {
        HStack(spacing: 16) {
            StatBadge(
                icon: "person.2.fill",
                value: "\(contacts.count)",
                label: "Total",
                color: Color(red: 0.5, green: 0.3, blue: 0.8)
            )

            StatBadge(
                icon: "building.2.fill",
                value: "\(uniqueCompanies)",
                label: "Entreprises",
                color: Color(red: 0.3, green: 0.6, blue: 0.8)
            )

            StatBadge(
                icon: "tag.fill",
                value: "\(uniqueRoles)",
                label: "Rôles",
                color: Color(red: 0.8, green: 0.5, blue: 0.3)
            )
        }
    }

    private var uniqueCompanies: Int {
        Set(contacts.compactMap { $0.company }).count
    }

    private var uniqueRoles: Int {
        Set(contacts.compactMap { $0.role }).count
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundColor(color)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(white: 0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        )
    }
}

// MARK: - Connection Row View
struct ConnectionRowView: View {
    let contact: OrbitalContact

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            avatarView

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(contact.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(white: 0.15))

                    // Connection type badge
                    HStack(spacing: 4) {
                        Image(systemName: contact.connectionType.icon)
                            .font(.system(size: 8))
                        Text(contact.connectionType.rawValue)
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(contact.connectionType.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(contact.connectionType.color.opacity(0.12))
                    )
                }

                if let role = contact.role, let company = contact.company {
                    Text("\(role) @ \(company)")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.5))
                } else if let role = contact.role {
                    Text(role)
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.5))
                } else if let company = contact.company {
                    Text(company)
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.5))
                }

                // Meeting info
                if let place = contact.meetingPlace {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 10))
                        Text(place)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(Color(white: 0.55))
                }

                // Tags
                if !contact.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(contact.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(contact.avatarColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(contact.avatarColor.opacity(0.12))
                                )
                        }
                    }
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(white: 0.7))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
        )
    }

    @ViewBuilder
    private var avatarView: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            contact.avatarColor.opacity(0.15),
                            contact.avatarColor.opacity(0.25)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 24
                    )
                )
                .frame(width: 48, height: 48)

            // Photo or placeholder
            if let photoName = contact.photoName, UIImage(named: photoName) != nil {
                Image(photoName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else {
                // Initials
                Text(contact.name.prefix(1).uppercased())
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(contact.avatarColor)
            }

            // Border
            Circle()
                .stroke(contact.avatarColor.opacity(0.3), lineWidth: 2)
                .frame(width: 48, height: 48)
        }
    }
}

// MARK: - Preview
#Preview {
    ConnectionsListView(contacts: OrbitalContact.all)
}
