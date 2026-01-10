import SwiftUI
import MessageUI

// MARK: - InvitationOptionsSheet
/// Sheet présentant les options d'envoi d'invitation (SMS, WhatsApp, Copier)
struct InvitationOptionsSheet: View {

    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    let contact: PhoneContact
    let currentUser: User
    let onComplete: (InvitationResult) -> Void

    @State private var showSMSComposer = false
    @State private var showCopiedToast = false
    @State private var invitationLink: URL?

    private let invitationService = InvitationService.shared

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Contact info
                contactHeader

                // Invitation options
                VStack(spacing: 12) {
                    // SMS option
                    if invitationService.canSendSMS(), contact.primaryPhone != nil {
                        invitationOption(
                            icon: "message.fill",
                            title: "Envoyer par SMS",
                            subtitle: contact.displayPhone,
                            color: .green
                        ) {
                            sendViaSMS()
                        }
                    }

                    // WhatsApp option
                    if invitationService.canOpenWhatsApp(), contact.primaryPhone != nil {
                        invitationOption(
                            icon: "bubble.left.and.bubble.right.fill",
                            title: "Envoyer via WhatsApp",
                            subtitle: contact.displayPhone,
                            color: Color(red: 0.15, green: 0.68, blue: 0.38)
                        ) {
                            sendViaWhatsApp()
                        }
                    }

                    // Copy message option
                    invitationOption(
                        icon: "doc.on.doc.fill",
                        title: "Copier le message",
                        subtitle: "Message prêt à coller sur WhatsApp, etc.",
                        color: .blue
                    ) {
                        copyLink()
                    }

                    // Share sheet option
                    invitationOption(
                        icon: "square.and.arrow.up.fill",
                        title: "Autres options",
                        subtitle: "Partager via une autre application",
                        color: .purple
                    ) {
                        shareViaSheet()
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                // Cancel button
                Button("Annuler") {
                    onComplete(.cancelled)
                    dismiss()
                }
                .foregroundStyle(.secondary)
                .padding(.bottom, 20)
            }
            .padding(.top, 24)
            .navigationBarHidden(true)
            .overlay {
                if showCopiedToast {
                    copiedToast
                }
            }
            .sheet(isPresented: $showSMSComposer) {
                if let phone = contact.primaryPhone, let link = invitationLink {
                    MessageComposerView(
                        recipients: [phone],
                        body: invitationService.createShortMessage(
                            fromUserName: currentUser.name,
                            link: link
                        ),
                        onDismiss: { result in
                            showSMSComposer = false
                            switch result {
                            case .sent:
                                onComplete(.sent)
                                dismiss()
                            case .cancelled, .failed:
                                break
                            @unknown default:
                                break
                            }
                        }
                    )
                }
            }
            .onAppear {
                generateLink()
            }
        }
    }

    // MARK: - Contact Header
    private var contactHeader: some View {
        VStack(spacing: 12) {
            // Avatar
            ZStack {
                if let image = contact.contactImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.mint, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    Text(contact.initials)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }

            // Name
            Text("Inviter \(contact.fullName)")
                .font(.title3.weight(.semibold))

            Text("Choisissez comment envoyer l'invitation")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Invitation Option Button
    private func invitationOption(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(color)
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Copied Toast
    private var copiedToast: some View {
        VStack {
            Spacer()

            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white)
                Text("Message copié !")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.8))
            .clipShape(Capsule())
            .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.3), value: showCopiedToast)
    }

    // MARK: - Actions

    private func generateLink() {
        invitationLink = invitationService.generateInvitationLink(
            fromUserId: currentUser.id.uuidString,
            fromUserName: currentUser.name,
            toContactName: contact.fullName
        )
    }

    private func sendViaSMS() {
        guard invitationLink != nil else { return }
        showSMSComposer = true
    }

    private func sendViaWhatsApp() {
        guard let phone = contact.primaryPhone,
              let link = invitationLink else { return }

        let message = invitationService.createShortMessage(
            fromUserName: currentUser.name,
            link: link
        )

        invitationService.openWhatsApp(phone: phone, message: message)

        // Considérer comme envoyé (on ne peut pas vérifier)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onComplete(.sent)
            dismiss()
        }
    }

    private func copyLink() {
        guard let link = invitationLink else { return }
        invitationService.copyMessageToClipboard(
            fromUserName: currentUser.name,
            toContactName: contact.fullName,
            link: link
        )

        // Show toast
        withAnimation {
            showCopiedToast = true
        }

        // Hide toast after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedToast = false
            }
        }
    }

    private func shareViaSheet() {
        guard let link = invitationLink else { return }

        let items = invitationService.createShareItems(
            fromUserName: currentUser.name,
            toContactName: contact.fullName,
            link: link
        )

        // Present UIActivityViewController
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Preview
#Preview {
    InvitationOptionsSheet(
        contact: PhoneContact.mockContacts[0],
        currentUser: User(
            name: "Gil",
            email: "gil@cirkl.app",
            sphere: .professional
        ),
        onComplete: { _ in }
    )
}
