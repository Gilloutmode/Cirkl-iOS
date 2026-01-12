import SwiftUI
import PhotosUI

// MARK: - InvitedContactDetailView
/// Vue détaillée pour voir et éditer un contact invité
struct InvitedContactDetailView: View {

    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    private let invitedContactsService = InvitedContactsService.shared

    let contact: InvitedContact
    let onUpdate: (InvitedContact) -> Void

    // États d'édition
    @State private var editedContact: InvitedContact
    @State private var isEditing = false
    @State private var isSaving = false

    // Pickers
    @State private var showRelationshipPicker = false
    @State private var showMeetingDatePicker = false
    @State private var showBirthdayPicker = false
    @State private var tempMeetingDate = Date()
    @State private var tempBirthdayDate = Date()

    // Relationship profile editing (initialized from contact)
    @State private var editedRelationshipProfile: RelationshipProfile

    // Photo picker
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showPhotoOptions = false

    // Delete
    @State private var showDeleteConfirmation = false

    // MARK: - Init
    init(contact: InvitedContact, onUpdate: @escaping (InvitedContact) -> Void) {
        self.contact = contact
        self.onUpdate = onUpdate
        _editedContact = State(initialValue: contact)
        // Initialize relationship profile from existing profile or migrate from legacy
        _editedRelationshipProfile = State(initialValue: contact.effectiveRelationshipProfile)
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header avec photo et relation
                    profileHeaderSection

                    // Section Relation
                    relationshipSection

                    // Section Dates
                    datesSection

                    // Section Informations personnelles
                    personalInfoSection

                    // Section Professionnelle
                    if hasAnyProfessionalInfo || isEditing {
                        professionalSection
                    }

                    // Section Contact
                    if hasAnyContactInfo || isEditing {
                        contactInfoSection
                    }

                    // Section Notes
                    notesSection

                    // Bouton suppression
                    if isEditing {
                        deleteButton
                    }
                }
                .padding(16)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(isEditing ? "Modifier" : "Fiche contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if isEditing {
                            editedContact = contact
                            isEditing = false
                        } else {
                            dismiss()
                        }
                    } label: {
                        if isEditing {
                            Text("Annuler")
                                .foregroundStyle(.red)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if isEditing {
                            saveChanges()
                        } else {
                            isEditing = true
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text(isEditing ? "Enregistrer" : "Modifier")
                                .fontWeight(.semibold)
                                .foregroundStyle(DesignTokens.Colors.mint)
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .sheet(isPresented: $showRelationshipPicker) {
                RelationshipProfilePicker(profile: $editedRelationshipProfile)
                    .onDisappear {
                        // Sync the relationship profile back to the contact on dismiss
                        editedContact.relationshipProfile = editedRelationshipProfile

                        // Auto-save when editing
                        if isEditing {
                            var contactToSave = editedContact
                            contactToSave.relationshipProfile = editedRelationshipProfile
                            invitedContactsService.updateContact(contactToSave)
                            onUpdate(contactToSave)
                            print("✅ Profil relationnel sauvegardé: \(editedRelationshipProfile.summary)")
                        }
                    }
            }
            .sheet(isPresented: $showMeetingDatePicker) {
                DatePickerSheet(
                    title: "Date de rencontre",
                    date: $tempMeetingDate,
                    onSave: {
                        editedContact.meetingDate = tempMeetingDate
                    }
                )
            }
            .sheet(isPresented: $showBirthdayPicker) {
                DatePickerSheet(
                    title: "Date d'anniversaire",
                    date: $tempBirthdayDate,
                    displayedComponents: [.date],
                    onSave: {
                        let components = Calendar.current.dateComponents([.year, .month, .day], from: tempBirthdayDate)
                        editedContact.birthday = CodableDateComponents(from: components)
                    }
                )
            }
            .alert("Supprimer ce contact ?", isPresented: $showDeleteConfirmation) {
                Button("Supprimer", role: .destructive) {
                    deleteContact()
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Cette action supprimera le contact de vos invitations en attente.")
            }
        }
    }

    // MARK: - Profile Header
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Photo
            ZStack {
                if let photo = editedContact.photo {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    editedContact.color.opacity(0.3),
                                    editedContact.color.opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(editedContact.initials)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(editedContact.color)
                        )
                }

                Circle()
                    .stroke(editedContact.color.opacity(0.4), lineWidth: 3)
                    .frame(width: 100, height: 100)

                // Camera button in edit mode
                if isEditing {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Circle().fill(.mint))
                                    .shadow(radius: 3)
                            }
                        }
                    }
                    .frame(width: 100, height: 100)
                }
            }

            // Name
            if isEditing {
                TextField("Nom", text: $editedContact.name)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
            } else {
                Text(editedContact.name)
                    .font(.title2.weight(.bold))
            }

            // Relationship profile display (multi-dimensional)
            if editedContact.hasRelationship {
                RelationshipProfileCompactView(profile: editedContact.effectiveRelationshipProfile)
                    .padding(.horizontal, 8)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Relationship Section
    private var relationshipSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Relation", icon: "person.2.fill")

            Button {
                showRelationshipPicker = true
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        if editedContact.hasRelationship {
                            // Display existing multi-dimensional profile
                            VStack(alignment: .leading, spacing: 8) {
                                // Spheres
                                if !editedRelationshipProfile.spheres.isEmpty {
                                    SphereChipsCompactView(spheres: editedRelationshipProfile.spheres)
                                }

                                // Natures
                                if !editedRelationshipProfile.natures.isEmpty {
                                    NatureChipsCompactView(natures: editedRelationshipProfile.natures)
                                }

                                // Closeness
                                HStack(spacing: 8) {
                                    Text("Proximité:")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    ClosenessIndicator(closeness: editedRelationshipProfile.closeness, showLabel: true)
                                }
                            }
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(DesignTokens.Colors.mint)
                            Text("Définir la relation")
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
            }
            .buttonStyle(.plain)
            .disabled(!isEditing)

            // iOS imported relation hint (legacy migration notice)
            if let iOSLabel = editedContact.iOSRelationLabel, !editedContact.hasRelationship {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Relation iOS importée: \"\(iOSLabel)\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)
            }

            // Legacy migration notice
            if editedContact.relationshipType != nil && editedContact.relationshipProfile == nil {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.orange)
                    Text("Relation migrée depuis l'ancien système")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Dates Section
    private var datesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Dates", icon: "calendar")

            VStack(spacing: 1) {
                // Date d'invitation (read-only)
                dateRow(
                    icon: "envelope.fill",
                    label: "Invitation envoyée",
                    value: editedContact.invitedAt.formatted(date: .long, time: .omitted),
                    color: .orange,
                    isEditable: false
                )

                Divider().padding(.leading, 52)

                // Date de rencontre
                if editedContact.needsMeetingDate {
                    Button {
                        tempMeetingDate = editedContact.meetingDate ?? Date()
                        showMeetingDatePicker = true
                    } label: {
                        dateRow(
                            icon: "person.2.fill",
                            label: "Date de rencontre",
                            value: editedContact.meetingDateDisplay,
                            color: .mint,
                            isEditable: true
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!isEditing)
                } else {
                    dateRow(
                        icon: "infinity",
                        label: "Connaissance depuis",
                        value: "Depuis toujours",
                        color: .pink,
                        isEditable: false
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
    }

    // MARK: - Personal Info Section
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Personnel", icon: "person.fill")

            VStack(spacing: 1) {
                // Birthday
                Button {
                    if let bd = editedContact.birthdayDate {
                        tempBirthdayDate = bd
                    }
                    showBirthdayPicker = true
                } label: {
                    infoRow(
                        icon: "gift.fill",
                        label: "Anniversaire",
                        value: editedContact.birthdayDisplayString ?? "Non renseigné",
                        color: .purple,
                        showChevron: isEditing
                    )
                }
                .buttonStyle(.plain)
                .disabled(!isEditing)
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
    }

    // MARK: - Professional Section
    private var professionalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Professionnel", icon: "briefcase.fill")

            VStack(spacing: 1) {
                if isEditing {
                    editableRow(
                        icon: "person.text.rectangle.fill",
                        label: "Poste",
                        text: Binding(
                            get: { editedContact.jobTitle ?? "" },
                            set: { editedContact.jobTitle = $0.isEmpty ? nil : $0 }
                        ),
                        placeholder: "Titre du poste..."
                    )

                    Divider().padding(.leading, 52)

                    editableRow(
                        icon: "building.2.fill",
                        label: "Organisation",
                        text: Binding(
                            get: { editedContact.organizationName ?? "" },
                            set: { editedContact.organizationName = $0.isEmpty ? nil : $0 }
                        ),
                        placeholder: "Entreprise..."
                    )
                } else {
                    if let job = editedContact.jobTitle {
                        infoRow(icon: "person.text.rectangle.fill", label: "Poste", value: job, color: .blue)
                        Divider().padding(.leading, 52)
                    }
                    if let org = editedContact.organizationName {
                        infoRow(icon: "building.2.fill", label: "Organisation", value: org, color: .blue)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
    }

    // MARK: - Contact Info Section
    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Contact", icon: "phone.fill")

            VStack(spacing: 1) {
                if let phone = editedContact.phoneNumber {
                    infoRow(icon: "phone.fill", label: "Téléphone", value: phone, color: .green)
                    if !editedContact.emails.isEmpty {
                        Divider().padding(.leading, 52)
                    }
                }

                ForEach(Array(editedContact.emails.enumerated()), id: \.offset) { index, email in
                    if index > 0 {
                        Divider().padding(.leading, 52)
                    }
                    infoRow(icon: "envelope.fill", label: "Email", value: email, color: .blue)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Notes", icon: "note.text")

            if isEditing {
                TextEditor(text: Binding(
                    get: { editedContact.note ?? "" },
                    set: { editedContact.note = $0.isEmpty ? nil : $0 }
                ))
                .font(.subheadline)
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
            } else {
                Text(editedContact.note ?? "Aucune note")
                    .font(.subheadline)
                    .foregroundStyle(editedContact.note == nil ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )
            }
        }
    }

    // MARK: - Delete Button
    private var deleteButton: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Supprimer ce contact")
            }
            .font(.headline)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.red.opacity(0.1))
            )
        }
    }

    // MARK: - Helper Views
    private func sectionHeader(title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
    }

    private func dateRow(icon: String, label: String, value: String, color: Color, isEditable: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }

            Spacer()

            if isEditable && isEditing {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
    }

    private func infoRow(icon: String, label: String, value: String, color: Color, showChevron: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }

            Spacer()

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
    }

    private func editableRow(icon: String, label: String, text: Binding<String>, placeholder: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField(placeholder, text: text)
                    .font(.subheadline)
                    .textFieldStyle(.plain)
            }

            Spacer()
        }
        .padding(16)
    }

    // MARK: - Computed
    private var hasAnyProfessionalInfo: Bool {
        editedContact.jobTitle != nil || editedContact.organizationName != nil
    }

    private var hasAnyContactInfo: Bool {
        editedContact.phoneNumber != nil || !editedContact.emails.isEmpty
    }

    // MARK: - Actions
    private func saveChanges() {
        isSaving = true
        invitedContactsService.updateContact(editedContact)
        onUpdate(editedContact)
        isEditing = false
        isSaving = false
    }

    private func deleteContact() {
        invitedContactsService.removeInvitedContact(id: contact.id)
        dismiss()
    }
}

// MARK: - DatePickerSheet
private struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    @Binding var date: Date
    var displayedComponents: DatePickerComponents = [.date]
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker(
                    title,
                    selection: $date,
                    displayedComponents: displayedComponents
                )
                .datePickerStyle(.graphical)
                .padding()

                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Valider") {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview
#Preview("With Multi-Dimensional Profile") {
    let contact = InvitedContact(
        id: "preview",
        name: "David Benittah",
        phoneNumber: "+33 6 12 34 56 78",
        emails: ["david@example.com"],
        invitedAt: Date(),
        avatarColor: CodableColor(color: .blue),
        photoData: nil,
        relationshipType: nil,
        relationshipProfile: .previewMultiDimensional,
        organizationName: "Tech Corp",
        jobTitle: "Developer"
    )

    InvitedContactDetailView(contact: contact) { _ in }
}

#Preview("With Legacy Migration") {
    let contact = InvitedContact(
        id: "preview-legacy",
        name: "Marie Dupont",
        phoneNumber: "+33 6 98 76 54 32",
        emails: ["marie@example.com"],
        invitedAt: Date(),
        avatarColor: CodableColor(color: .purple),
        photoData: nil,
        relationshipType: RelationshipType(subtype: .mentor),
        relationshipProfile: nil,
        organizationName: "Innovation Labs",
        jobTitle: "CTO"
    )

    InvitedContactDetailView(contact: contact) { _ in }
}

#Preview("Empty Profile") {
    let contact = InvitedContact(
        id: "preview-empty",
        name: "Nouveau Contact",
        phoneNumber: nil,
        emails: [],
        invitedAt: Date(),
        avatarColor: CodableColor(color: .gray),
        photoData: nil,
        relationshipType: nil,
        relationshipProfile: nil
    )

    InvitedContactDetailView(contact: contact) { _ in }
}
