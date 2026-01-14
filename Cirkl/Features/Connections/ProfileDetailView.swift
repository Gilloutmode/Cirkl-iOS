import SwiftUI
import PhotosUI
import UIKit

// MARK: - Profile Detail View
/// Vue détaillée pour voir et éditer un profil de connexion
struct ProfileDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var neo4jService = Neo4jService.shared
    private let n8nService = N8NService.shared

    // TODO: Get from AuthService when implemented
    private let currentUserId = "gil"

    let contact: OrbitalContact
    let onUpdate: (OrbitalContact) -> Void

    // États d'édition
    @State private var editedName: String = ""
    @State private var editedRole: String = ""
    @State private var editedCompany: String = ""
    @State private var editedIndustry: String = ""
    @State private var editedMeetingPlace: String = ""
    @State private var editedNotes: String = ""
    @State private var editedConnectionType: ConnectionType = .personnel
    @State private var editedRelationshipType: RelationshipType?  // Legacy
    @State private var editedRelationshipProfile: RelationshipProfile = RelationshipProfile()  // Multi-dimensionnel
    @State private var editedMeetingDate: Date?
    @State private var editedTags: [String] = []
    @State private var newTag: String = ""

    // Photo picker
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selfieImage: UIImage?
    @State private var showPhotoOptions = false
    @State private var showPhotoPicker = false
    @State private var showCamera = false

    // Pickers
    @State private var showRelationshipPicker = false
    @State private var showMeetingDatePicker = false
    @State private var tempMeetingDate: Date = Date()

    // UI states
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var showDeleteConfirmation = false

    // Indique si la date de rencontre est requise (non pour la famille)
    private var needsMeetingDate: Bool {
        // Vérifier d'abord le profil multi-dimensionnel
        if editedRelationshipProfile.spheres.contains(.family) {
            return false
        }
        // Sinon, vérifier le type legacy
        guard let relationship = editedRelationshipType else { return true }
        return !relationship.impliesLifelongRelation
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header avec photo
                    profileHeader

                    // Niveau de confiance
                    trustLevelSection

                    // Informations de rencontre
                    meetingInfoSection

                    // Informations professionnelles
                    professionalInfoSection

                    // Tags
                    tagsSection

                    // Notes
                    notesSection

                    // Bouton de suppression (si en mode édition)
                    if isEditing {
                        deleteButton
                    }
                }
                .padding(20)
            }
            .background(DesignTokens.Colors.background)
            .navigationTitle(isEditing ? "Modifier" : contact.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        CirklHaptics.light()
                        if isEditing {
                            // Annuler les modifications
                            resetFields()
                            isEditing = false
                        } else {
                            dismiss()
                        }
                    } label: {
                        if isEditing {
                            Text("Annuler")
                                .foregroundColor(DesignTokens.Colors.error)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(DesignTokens.Colors.textTertiary)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        CirklHaptics.medium()
                        if isEditing {
                            Task { await saveChanges() }
                        } else {
                            isEditing = true
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text(isEditing ? "Enregistrer" : "Modifier")
                                .fontWeight(.semibold)
                                .foregroundColor(DesignTokens.Colors.purple)
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .onAppear {
                resetFields()
            }
            .confirmationDialog("Changer la photo", isPresented: $showPhotoOptions) {
                Button("Prendre une photo") {
                    showCamera = true
                }
                Button("Choisir dans la galerie") {
                    showPhotoPicker = true
                }
                Button("Annuler", role: .cancel) {}
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selfieImage = image
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView { image in
                    selfieImage = image
                }
            }
            .alert("Supprimer cette connexion ?", isPresented: $showDeleteConfirmation) {
                Button("Supprimer", role: .destructive) {
                    Task { await deleteConnection() }
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Cette action est irréversible.")
            }
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                // Photo de profil (priorité: selfieImage édité → selfiePhotoData → contactPhotoData → photoName asset → placeholder)
                if let image = selfieImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else if let data = contact.selfiePhotoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else if let data = contact.contactPhotoData, let uiImage = UIImage(data: data) {
                    // Photo du contact importé (pour les invités)
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else if let photoName = contact.photoName, !photoName.isEmpty {
                    // Local asset image - use SegmentedAsyncImage for async loading
                    // Same approach as GlassBubbleView for consistent behavior
                    SegmentedAsyncImage(
                        imageName: photoName,
                        size: CGSize(width: 120, height: 120),
                        placeholderColor: contact.avatarColor
                    )
                } else {
                    // Placeholder
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    contact.avatarColor.opacity(0.3),
                                    contact.avatarColor.opacity(0.5)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Text(contact.name.prefix(1).uppercased())
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(contact.avatarColor)
                        )
                }

                // Bordure
                Circle()
                    .stroke(contact.avatarColor.opacity(0.5), lineWidth: 4)
                    .frame(width: 120, height: 120)

                // Bouton caméra (mode édition) - déclenche le dialog de choix
                // CRITICAL FIX: Added .contentShape(Circle()) and .buttonStyle(.plain) for reliable hit-testing on device
                if isEditing {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                showPhotoOptions = true
                            } label: {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(DesignTokens.Colors.purple))
                                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                            }
                            .buttonStyle(.plain)
                            .contentShape(Circle())
                        }
                    }
                    .frame(width: 120, height: 120)
                }
            }

            // Nom
            if isEditing {
                TextField("Nom", text: $editedName)
                    .font(DesignTokens.Typography.title2)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
            } else {
                Text(contact.name)
                    .font(DesignTokens.Typography.title2)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }

            // Badge type de connexion
            connectionTypeBadge
        }
        .padding(.vertical, DesignTokens.Spacing.xl)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .background(
            // CRITICAL FIX: Use ultraThinMaterial instead of glassEffect
            // glassEffect blocks touch events (camera button) on iOS 26 real devices
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(Color.primary.opacity(0.04))
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        .dynamicCardReflection(intensity: 0.5, cornerRadius: DesignTokens.Radius.xl)
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }

    // MARK: - Connection Type Badge
    private var connectionTypeBadge: some View {
        Group {
            if isEditing {
                // Picker pour le type
                Menu {
                    ForEach(ConnectionType.allCases) { type in
                        Button {
                            editedConnectionType = type
                        } label: {
                            Label(type.rawValue, systemImage: type.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: editedConnectionType.icon)
                        Text(editedConnectionType.rawValue)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(editedConnectionType.color)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(editedConnectionType.color.opacity(0.12))
                    )
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: contact.connectionType.icon)
                    Text(contact.connectionType.rawValue)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(contact.connectionType.color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(contact.connectionType.color.opacity(0.12))
                )
            }
        }
    }

    // MARK: - Trust Level Section
    private var trustLevelSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Niveau de confiance", icon: "checkmark.shield")

            VerificationBadge(trustLevel: contact.trustLevel, style: .expanded)
        }
    }

    // MARK: - Meeting Info Section
    private var meetingInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Relation & Rencontre", icon: "person.2.fill")

            VStack(spacing: 12) {
                // Profil relationnel multi-dimensionnel (cliquable pour ouvrir le picker)
                Button {
                    showRelationshipPicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: editedRelationshipProfile.isEmpty ? "plus.circle.fill" : "person.2.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(editedRelationshipProfile.isEmpty ? DesignTokens.Colors.mint : DesignTokens.Colors.electricBlue)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Relation")
                                .font(.system(size: 12))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            if editedRelationshipProfile.isEmpty {
                                Text("Définir la relation")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                            } else {
                                Text(editedRelationshipProfile.summary)
                                    .font(.system(size: 15))
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .contentShape(Rectangle())

                Divider()

                // Date de rencontre OU "Depuis toujours" pour la famille
                if needsMeetingDate {
                    // Date de rencontre (modifiable)
                    Button {
                        tempMeetingDate = editedMeetingDate ?? Date()
                        showMeetingDatePicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.system(size: 16))
                                .foregroundColor(contact.avatarColor)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Date de rencontre")
                                    .font(.system(size: 12))
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                Text(editedMeetingDate?.formatted(date: .long, time: .omitted) ?? "Sélectionner une date")
                                    .font(.system(size: 15))
                                    .foregroundColor(editedMeetingDate != nil ? DesignTokens.Colors.textPrimary : .secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                } else {
                    // "Depuis toujours" pour la famille
                    HStack(spacing: 12) {
                        Image(systemName: "infinity")
                            .font(.system(size: 16))
                            .foregroundColor(DesignTokens.Colors.pink)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Connaissance depuis")
                                .font(.system(size: 12))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            Text("Depuis toujours")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.pink)
                        }

                        Spacer()
                    }
                }

                // Date d'invitation (si contact invité)
                if let invitedAt = contact.invitedAt {
                    Divider()
                    infoRow(
                        icon: "paperplane",
                        label: "Invité le",
                        value: invitedAt.formatted(date: .long, time: .omitted),
                        isEditable: false
                    )
                }

                Divider()

                // Lieu de rencontre
                if isEditing {
                    editableInfoRow(
                        icon: "mappin.and.ellipse",
                        label: "Lieu",
                        text: $editedMeetingPlace,
                        placeholder: "Lieu de rencontre..."
                    )
                } else {
                    infoRow(
                        icon: "mappin.and.ellipse",
                        label: "Lieu",
                        value: contact.meetingPlace ?? "Non spécifié"
                    )
                }
            }
            .padding(16)
            .background(
                // CRITICAL FIX: Use ultraThinMaterial instead of glassEffect
                // glassEffect blocks touch events (relation picker, date picker) on iOS 26 real devices
                RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                    .fill(Color.primary.opacity(0.04))
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .dynamicCardReflection(intensity: 0.4, cornerRadius: DesignTokens.Radius.large)
            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        }
        .sheet(isPresented: $showRelationshipPicker) {
            RelationshipProfilePicker(profile: $editedRelationshipProfile)
                .presentationDetents([.large])
                .onChange(of: editedRelationshipProfile) { _, newProfile in
                    // Si famille, effacer la date de rencontre
                    if newProfile.spheres.contains(.family) {
                        editedMeetingDate = nil
                    }
                }
        }
        .sheet(isPresented: $showMeetingDatePicker) {
            NavigationStack {
                VStack(spacing: 24) {
                    Text("Date de rencontre")
                        .font(.headline)

                    DatePicker(
                        "Date",
                        selection: $tempMeetingDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 20)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Annuler") {
                            showMeetingDatePicker = false
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Valider") {
                            editedMeetingDate = tempMeetingDate
                            showMeetingDatePicker = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - Professional Info Section
    private var professionalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Professionnel", icon: "briefcase")

            VStack(spacing: 12) {
                if isEditing {
                    editableInfoRow(icon: "person.text.rectangle", label: "Rôle", text: $editedRole, placeholder: "Poste...")
                    Divider()
                    editableInfoRow(icon: "building.2", label: "Entreprise", text: $editedCompany, placeholder: "Entreprise...")
                    Divider()
                    editableInfoRow(icon: "square.grid.2x2", label: "Secteur", text: $editedIndustry, placeholder: "Industrie...")
                } else {
                    infoRow(icon: "person.text.rectangle", label: "Rôle", value: contact.role ?? "Non spécifié")
                    Divider()
                    infoRow(icon: "building.2", label: "Entreprise", value: contact.company ?? "Non spécifié")
                    Divider()
                    infoRow(icon: "square.grid.2x2", label: "Secteur", value: contact.industry ?? "Non spécifié")
                }
            }
            .padding(16)
            .background(
                // CRITICAL FIX: Use ultraThinMaterial instead of glassEffect
                // glassEffect blocks touch events (TextFields) on iOS 26 real devices
                RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                    .fill(Color.primary.opacity(0.04))
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .dynamicCardReflection(intensity: 0.4, cornerRadius: DesignTokens.Radius.large)
            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        }
    }

    // MARK: - Tags Section
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Tags", icon: "tag")

            VStack(alignment: .leading, spacing: 12) {
                // Tags existants
                FlowLayout(spacing: 8) {
                    ForEach(editedTags, id: \.self) { tag in
                        TagChip(tag: tag, color: contact.avatarColor, isEditing: isEditing) {
                            editedTags.removeAll { $0 == tag }
                        }
                    }

                    // Ajouter un tag (mode édition)
                    if isEditing {
                        HStack(spacing: 4) {
                            TextField("Ajouter...", text: $newTag)
                                .font(.system(size: 13))
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .frame(width: 80)

                            if !newTag.isEmpty {
                                // CRITICAL FIX: Added .contentShape() and .buttonStyle() for reliable hit-testing on device
                                Button {
                                    addTag()
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(contact.avatarColor)
                                }
                                .buttonStyle(.plain)
                                .contentShape(Circle())
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .stroke(contact.avatarColor.opacity(0.3), lineWidth: 1)
                        )
                    }
                }

                if editedTags.isEmpty && !isEditing {
                    Text("Aucun tag")
                        .font(DesignTokens.Typography.footnote)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            .padding(16)
            .background(
                // CRITICAL FIX: Use ultraThinMaterial instead of glassEffect
                // glassEffect blocks touch events (tag add button, TextField) on iOS 26 real devices
                RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                    .fill(Color.primary.opacity(0.04))
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .dynamicCardReflection(intensity: 0.4, cornerRadius: DesignTokens.Radius.large)
            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Notes", icon: "note.text")

            VStack(alignment: .leading, spacing: 8) {
                if isEditing {
                    TextEditor(text: $editedNotes)
                        .font(.system(size: 15))
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(DesignTokens.Colors.surfaceSecondary)
                        .cornerRadius(DesignTokens.Radius.small)
                } else {
                    Text(contact.notes?.isEmpty == false ? contact.notes! : "Aucune note")
                        .font(DesignTokens.Typography.subheadline)
                        .foregroundColor(contact.notes?.isEmpty == false ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textSecondary)
                }
            }
            .padding(16)
            .background(
                // CRITICAL FIX: Use ultraThinMaterial instead of glassEffect
                // glassEffect blocks touch events (TextEditor) on iOS 26 real devices
                RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                    .fill(Color.primary.opacity(0.04))
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .dynamicCardReflection(intensity: 0.4, cornerRadius: DesignTokens.Radius.large)
            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        }
    }

    // MARK: - Delete Button
    // CRITICAL FIX: Added .contentShape() and .buttonStyle() for reliable hit-testing on device
    private var deleteButton: some View {
        Button {
            CirklHaptics.warning()
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Supprimer cette connexion")
            }
            .font(DesignTokens.Typography.bodyBold)
            .foregroundColor(DesignTokens.Colors.error)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                    .fill(DesignTokens.Colors.error.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.large))
    }

    // MARK: - Helper Views
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
            Text(title)
                .font(DesignTokens.Typography.headline)
        }
        .foregroundColor(DesignTokens.Colors.textSecondary)
    }

    private func infoRow(icon: String, label: String, value: String, isEditable: Bool = true) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm + 4) {
            Image(systemName: icon)
                .font(.system(size: DesignTokens.Sizes.iconSmall))
                .foregroundColor(contact.avatarColor)
                .frame(width: DesignTokens.Spacing.lg)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(DesignTokens.Typography.caption1)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                Text(value)
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }

            Spacer()
        }
    }

    private func editableInfoRow(icon: String, label: String, text: Binding<String>, placeholder: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm + 4) {
            Image(systemName: icon)
                .font(.system(size: DesignTokens.Sizes.iconSmall))
                .foregroundColor(contact.avatarColor)
                .frame(width: DesignTokens.Spacing.lg)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(DesignTokens.Typography.caption1)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                TextField(placeholder, text: text)
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .textFieldStyle(.plain)
            }

            Spacer()
        }
    }

    // MARK: - Actions
    private func resetFields() {
        editedName = contact.name
        editedRole = contact.role ?? ""
        editedCompany = contact.company ?? ""
        editedIndustry = contact.industry ?? ""
        editedMeetingPlace = contact.meetingPlace ?? ""
        editedNotes = contact.notes ?? ""
        editedConnectionType = contact.connectionType
        editedRelationshipType = contact.relationshipType
        editedRelationshipProfile = contact.relationshipProfile ?? contact.effectiveRelationshipProfile
        editedMeetingDate = contact.meetingDate
        editedTags = contact.tags

        // Photo: priorité au selfie, puis contactPhotoData pour les invités
        if let data = contact.selfiePhotoData {
            selfieImage = UIImage(data: data)
        } else if let data = contact.contactPhotoData {
            selfieImage = UIImage(data: data)
        }
    }

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !editedTags.contains(trimmed) else { return }
        editedTags.append(trimmed)
        newTag = ""
    }

    private func saveChanges() async {
        isSaving = true

        // Créer le contact mis à jour
        var updated = contact
        updated.name = editedName
        updated.role = editedRole.isEmpty ? nil : editedRole
        updated.company = editedCompany.isEmpty ? nil : editedCompany
        updated.industry = editedIndustry.isEmpty ? nil : editedIndustry
        updated.meetingPlace = editedMeetingPlace.isEmpty ? nil : editedMeetingPlace
        updated.notes = editedNotes.isEmpty ? nil : editedNotes
        updated.connectionType = editedConnectionType
        updated.relationshipType = editedRelationshipType
        updated.relationshipProfile = editedRelationshipProfile.isEmpty ? nil : editedRelationshipProfile
        updated.meetingDate = editedMeetingDate
        updated.tags = editedTags

        // Photo
        if let image = selfieImage {
            updated.selfiePhotoData = image.jpegData(compressionQuality: 0.7)
        }

        // Sync to Neo4j
        do {
            try await neo4jService.updateConnection(updated.toNeo4jConnection())

            // v17.29: Also sync RelationshipProfile to Google Sheets via N8N
            if let profile = updated.relationshipProfile, !profile.isEmpty {
                do {
                    let _ = try await n8nService.updateConnection(
                        connectionId: contact.id,
                        relationshipProfile: profile,
                        userId: currentUserId
                    )
                    #if DEBUG
                    print("✅ N8N: Connection \(contact.id) synced to Google Sheets")
                    #endif
                } catch {
                    // Don't fail the whole save if N8N sync fails
                    // The local data is already saved to Neo4j
                    #if DEBUG
                    print("⚠️ N8N sync failed (non-critical): \(error)")
                    #endif
                }
            }

            onUpdate(updated)
            // Toast de succès
            ToastManager.shared.success("Profil mis à jour")
            // Dismiss the view so user sees updated data in the list
            dismiss()
        } catch {
            print("❌ Failed to save: \(error)")
            ToastManager.shared.error("Erreur lors de la sauvegarde")
            // On error, stay in edit mode so user can retry
            isSaving = false
        }
    }

    private func deleteConnection() async {
        isSaving = true
        do {
            try await neo4jService.deleteConnection(contact.toNeo4jConnection())
            ToastManager.shared.success("Connexion supprimée")
            dismiss()
        } catch {
            print("❌ Failed to delete: \(error)")
            ToastManager.shared.error("Erreur lors de la suppression")
        }
        isSaving = false
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let tag: String
    let color: Color
    let isEditing: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.system(size: 13, weight: .medium))

            if isEditing {
                // CRITICAL FIX: Added .contentShape() for reliable hit-testing on device
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
            }
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
        )
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraDevice = .front
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    ProfileDetailView(contact: OrbitalContact.all[0]) { _ in }
}
