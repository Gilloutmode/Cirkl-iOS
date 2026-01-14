import SwiftUI
import Kingfisher

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
                DesignTokens.Colors.background
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
                    if neo4jService.isLoading && contacts.isEmpty {
                        // Skeleton Loading State
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(0..<5, id: \.self) { _ in
                                    ConnectionRowSkeleton()
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    } else if filteredContacts.isEmpty {
                        // Empty State
                        VStack {
                            Spacer()
                            if searchText.isEmpty {
                                CirklEmptyState.connections(onAdd: {
                                    showAddConnection = true
                                })
                            } else {
                                CirklEmptyState.noSearchResults
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        // Contacts List
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredContacts) { contact in
                                    Button {
                                        CirklHaptics.selection()
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
            }
            .navigationTitle("Connexions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        CirklHaptics.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        CirklHaptics.medium()
                        showAddConnection = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(DesignTokens.Colors.purple)
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
                .foregroundColor(DesignTokens.Colors.textSecondary)

            TextField("Rechercher une connexion...", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(DesignTokens.Colors.textPrimary)

            if !searchText.isEmpty {
                Button {
                    CirklHaptics.light()
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Colors.surface)
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
                color: DesignTokens.Colors.purple
            )

            StatBadge(
                icon: "building.2.fill",
                value: "\(uniqueCompanies)",
                label: "Entreprises",
                color: DesignTokens.Colors.electricBlue
            )

            StatBadge(
                icon: "tag.fill",
                value: "\(uniqueRoles)",
                label: "Rôles",
                color: DesignTokens.Colors.warning
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
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Colors.surface)
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
                        .foregroundColor(DesignTokens.Colors.textPrimary)

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
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                } else if let role = contact.role {
                    Text(role)
                        .font(.system(size: 13))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                } else if let company = contact.company {
                    Text(company)
                        .font(.system(size: 13))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }

                // Meeting info
                if let place = contact.meetingPlace {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 10))
                        Text(place)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(DesignTokens.Colors.textSecondary)
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
                .foregroundColor(DesignTokens.Colors.textTertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignTokens.Colors.surface)
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

            // Photo with Kingfisher caching or placeholder
            // Priority: selfiePhotoData > contactPhotoData > photoName URL > photoName asset > initials
            if let photoData = contact.selfiePhotoData,
               let uiImage = UIImage(data: photoData) {
                // Selfie photo (taken during verification)
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else if let photoData = contact.contactPhotoData,
               let uiImage = UIImage(data: photoData) {
                // Contact photo from Data (e.g., imported from contacts)
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else if let photoName = contact.photoName, !photoName.isEmpty {
                // Check if photoName is a URL string
                if let url = URL(string: photoName), url.scheme != nil {
                    // Remote image with Kingfisher caching
                    KFImage(url)
                        .placeholder {
                            // Shimmer placeholder while loading
                            Circle()
                                .fill(DesignTokens.Colors.surface)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text(contact.name.prefix(1).uppercased())
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(contact.avatarColor.opacity(0.5))
                                )
                        }
                        .fade(duration: 0.25)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    // Local asset image - use SegmentedAsyncImage for async loading
                    // Same approach as GlassBubbleView for consistent behavior
                    SegmentedAsyncImage(
                        imageName: photoName,
                        size: CGSize(width: 44, height: 44),
                        placeholderColor: contact.avatarColor
                    )
                }
            } else {
                // Initials fallback
                initialsView
            }

            // Border
            Circle()
                .stroke(contact.avatarColor.opacity(0.3), lineWidth: 2)
                .frame(width: 48, height: 48)
        }
    }

    private var initialsView: some View {
        Text(contact.name.prefix(1).uppercased())
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundColor(contact.avatarColor)
    }
}

// MARK: - Connection Row Skeleton
/// Skeleton placeholder for ConnectionRowView during loading
struct ConnectionRowSkeleton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 14) {
            // Avatar skeleton
            Circle()
                .fill(DesignTokens.Colors.surface)
                .frame(width: 48, height: 48)
                .overlay(
                    Circle()
                        .fill(shimmerGradient)
                        .opacity(isAnimating ? 0.6 : 0.3)
                )

            // Info skeleton
            VStack(alignment: .leading, spacing: 8) {
                // Name
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 120, height: 16)
                    .opacity(isAnimating ? 0.6 : 0.3)

                // Role
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 180, height: 12)
                    .opacity(isAnimating ? 0.5 : 0.25)

                // Tags
                HStack(spacing: 6) {
                    ForEach(0..<2, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(shimmerGradient)
                            .frame(width: 60, height: 20)
                            .opacity(isAnimating ? 0.4 : 0.2)
                    }
                }
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignTokens.Colors.surface)
                .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
        )
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Chargement...")
    }

    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                DesignTokens.Colors.textTertiary.opacity(0.3),
                DesignTokens.Colors.textTertiary.opacity(0.5),
                DesignTokens.Colors.textTertiary.opacity(0.3)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Preview
#Preview {
    ConnectionsListView(contacts: OrbitalContact.all)
}

#Preview("Skeleton Loading") {
    ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()
        VStack(spacing: 12) {
            ConnectionRowSkeleton()
            ConnectionRowSkeleton()
            ConnectionRowSkeleton()
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
