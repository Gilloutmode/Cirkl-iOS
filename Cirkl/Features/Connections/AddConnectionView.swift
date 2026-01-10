import SwiftUI
import PhotosUI

// MARK: - Add Connection View
/// Vue pour créer une nouvelle connexion
struct AddConnectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var neo4jService = Neo4jService.shared

    let onAdd: (OrbitalContact) -> Void

    // Form fields
    @State private var name: String = ""
    @State private var role: String = ""
    @State private var company: String = ""
    @State private var industry: String = ""
    @State private var meetingPlace: String = ""
    @State private var notes: String = ""
    @State private var connectionType: ConnectionType = .personnel
    @State private var tags: [String] = []
    @State private var newTag: String = ""

    // Photo
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selfieImage: UIImage?
    @State private var showCamera = false

    // UI states
    @State private var isSaving = false

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Photo section
                    photoSection

                    // Basic info
                    basicInfoSection

                    // Connection type
                    connectionTypeSection

                    // Professional info
                    professionalInfoSection

                    // Meeting info
                    meetingInfoSection

                    // Tags
                    tagsSection

                    // Notes
                    notesSection
                }
                .padding(20)
            }
            .background(Color(white: 0.97))
            .navigationTitle("Nouvelle connexion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await saveConnection() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Créer")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isValid || isSaving)
                    .foregroundColor(isValid ? Color(red: 0.5, green: 0.3, blue: 0.8) : .gray)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView { image in
                    selfieImage = image
                }
            }
        }
    }

    // MARK: - Photo Section
    private var photoSection: some View {
        VStack(spacing: 16) {
            ZStack {
                if let image = selfieImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(connectionType.color.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(connectionType.color.opacity(0.5))
                        )
                }

                Circle()
                    .stroke(connectionType.color.opacity(0.3), lineWidth: 3)
                    .frame(width: 100, height: 100)
            }

            HStack(spacing: 16) {
                Button {
                    showCamera = true
                } label: {
                    Label("Caméra", systemImage: "camera.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.5, green: 0.3, blue: 0.8))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.5, green: 0.3, blue: 0.8).opacity(0.1))
                        )
                }

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Galerie", systemImage: "photo.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.5, green: 0.3, blue: 0.8))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.5, green: 0.3, blue: 0.8).opacity(0.1))
                        )
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selfieImage = image
                        }
                    }
                }
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
    }

    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Informations", icon: "person.fill")

            VStack(spacing: 12) {
                formField(icon: "person.fill", label: "Nom *", text: $name, placeholder: "Prénom Nom")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
            )
        }
    }

    // MARK: - Connection Type Section
    private var connectionTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Type de connexion", icon: "tag.fill")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ConnectionType.allCases) { type in
                        Button {
                            connectionType = type
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 12))
                                Text(type.rawValue)
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(connectionType == type ? .white : type.color)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(connectionType == type ? type.color : type.color.opacity(0.12))
                            )
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Professional Info Section
    private var professionalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Professionnel", icon: "briefcase.fill")

            VStack(spacing: 12) {
                formField(icon: "person.text.rectangle", label: "Rôle", text: $role, placeholder: "Poste")
                Divider()
                formField(icon: "building.2", label: "Entreprise", text: $company, placeholder: "Société")
                Divider()
                formField(icon: "square.grid.2x2", label: "Secteur", text: $industry, placeholder: "Industrie")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
            )
        }
    }

    // MARK: - Meeting Info Section
    private var meetingInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Rencontre", icon: "calendar")

            VStack(spacing: 12) {
                // Date auto (read-only info)
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundColor(connectionType.color)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Date")
                            .font(.system(size: 12))
                            .foregroundColor(Color(white: 0.5))
                        Text(Date().formatted(date: .long, time: .omitted))
                            .font(.system(size: 15))
                            .foregroundColor(Color(white: 0.3))
                    }

                    Spacer()

                    Text("Auto")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(white: 0.5))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(white: 0.95))
                        )
                }

                Divider()

                formField(icon: "mappin.and.ellipse", label: "Lieu", text: $meetingPlace, placeholder: "Où vous êtes-vous rencontrés ?")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
            )
        }
    }

    // MARK: - Tags Section
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Tags", icon: "tag")

            VStack(alignment: .leading, spacing: 12) {
                // Tags chips
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        TagChip(tag: tag, color: connectionType.color, isEditing: true) {
                            tags.removeAll { $0 == tag }
                        }
                    }

                    // Add new tag
                    HStack(spacing: 4) {
                        TextField("Ajouter...", text: $newTag)
                            .font(.system(size: 13))
                            .frame(width: 80)
                            .onSubmit {
                                addTag()
                            }

                        if !newTag.isEmpty {
                            Button {
                                addTag()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(connectionType.color)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(connectionType.color.opacity(0.3), lineWidth: 1)
                    )
                }

                // Suggested tags
                Text("Suggestions:")
                    .font(.system(size: 12))
                    .foregroundColor(Color(white: 0.5))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestedTags, id: \.self) { tag in
                            Button {
                                if !tags.contains(tag) {
                                    tags.append(tag)
                                }
                            } label: {
                                Text(tag)
                                    .font(.system(size: 12))
                                    .foregroundColor(connectionType.color.opacity(0.8))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .stroke(connectionType.color.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .disabled(tags.contains(tag))
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
            )
        }
    }

    private var suggestedTags: [String] {
        switch connectionType {
        case .professionnel: return ["business", "collaboration", "tech", "finance", "consulting"]
        case .personnel: return ["ami", "famille", "voisin", "confiance"]
        case .evenement: return ["conférence", "meetup", "salon", "workshop"]
        case .networking: return ["linkedin", "opportunité", "réseau", "intro"]
        case .famille: return ["parent", "cousin", "proche", "famille"]
        case .amiDami: return ["recommandation", "intro", "common"]
        case .communaute: return ["club", "association", "groupe", "passion"]
        case .etudes: return ["école", "université", "formation", "alumni"]
        case .voyage: return ["trip", "rencontre", "aventure", "destination"]
        case .sport: return ["équipe", "club", "compétition", "passion"]
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Notes", icon: "note.text")

            TextEditor(text: $notes)
                .font(.system(size: 15))
                .frame(minHeight: 80)
                .padding(12)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
        }
    }

    // MARK: - Helper Views
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
            Text(title)
                .font(.system(size: 16, weight: .bold))
        }
        .foregroundColor(Color(white: 0.3))
    }

    private func formField(icon: String, label: String, text: Binding<String>, placeholder: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(connectionType.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(Color(white: 0.5))
                TextField(placeholder, text: text)
                    .font(.system(size: 15))
                    .textFieldStyle(.plain)
            }

            Spacer()
        }
    }

    // MARK: - Actions
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        tags.append(trimmed)
        newTag = ""
    }

    private func saveConnection() async {
        isSaving = true

        // Create photo data
        var photoData: Data?
        if let image = selfieImage {
            photoData = image.jpegData(compressionQuality: 0.7)
        }

        // Create Neo4jConnection
        let newConnection = Neo4jConnection(
            id: UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            role: role.isEmpty ? nil : role,
            company: company.isEmpty ? nil : company,
            industry: industry.isEmpty ? nil : industry,
            meetingPlace: meetingPlace.isEmpty ? nil : meetingPlace,
            meetingDate: Date(),
            connectionType: connectionType,
            selfiePhotoBase64: photoData?.base64EncodedString(),
            notes: notes.isEmpty ? nil : notes,
            tags: tags
        )

        do {
            try await neo4jService.createConnection(newConnection)

            // Create OrbitalContact for local display
            let colors: [Color] = [
                Color(red: 0.6, green: 0.75, blue: 0.9),
                Color(red: 0.9, green: 0.7, blue: 0.8),
                Color(red: 0.7, green: 0.85, blue: 0.7),
                Color(red: 0.95, green: 0.8, blue: 0.6),
            ]
            let randomColor = colors.randomElement() ?? .blue

            let orbitalContact = OrbitalContact(
                id: newConnection.id,
                name: newConnection.name,
                photoName: nil,
                xPercent: 0.5,
                yPercent: 0.5,
                avatarColor: randomColor,
                trustLevel: .verified,  // Vérification physique via l'app
                role: newConnection.role,
                company: newConnection.company,
                industry: newConnection.industry,
                meetingPlace: newConnection.meetingPlace,
                meetingDate: newConnection.meetingDate,
                connectionType: newConnection.connectionType,
                selfiePhotoData: photoData,
                notes: newConnection.notes,
                tags: newConnection.tags
            )

            onAdd(orbitalContact)
            dismiss()
        } catch {
            print("❌ Failed to create connection: \(error)")
        }

        isSaving = false
    }
}

// MARK: - Preview
#Preview {
    AddConnectionView { _ in }
}
