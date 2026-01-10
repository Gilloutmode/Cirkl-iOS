import SwiftUI
import MessageUI

// MARK: - InvitationService
/// Service pour générer et envoyer des invitations CirKL
@Observable
@MainActor
final class InvitationService {

    // MARK: - Singleton
    static let shared = InvitationService()

    // MARK: - Constants
    private let baseURL = "https://cirkl.app/verify"
    private let appStoreURL = "https://apps.apple.com/app/cirkl/id123456789"  // TODO: Remplacer par vrai ID

    // MARK: - Init
    private init() {}

    // MARK: - Link Generation

    /// Génère un lien d'invitation unique
    func generateInvitationLink(
        fromUserId: String,
        fromUserName: String,
        toContactName: String
    ) -> URL {
        // Générer un token unique pour cette invitation
        let token = UUID().uuidString.prefix(8).lowercased()
        let timestamp = Int(Date().timeIntervalSince1970)

        // Construire l'URL avec les paramètres
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "from", value: fromUserId),
            URLQueryItem(name: "name", value: fromUserName),
            URLQueryItem(name: "to", value: toContactName),
            URLQueryItem(name: "token", value: String(token)),
            URLQueryItem(name: "t", value: String(timestamp))
        ]

        return components.url ?? URL(string: baseURL)!
    }

    /// Génère un deep link pour l'app
    func generateDeepLink(
        fromUserId: String,
        fromUserName: String,
        token: String
    ) -> URL {
        var components = URLComponents()
        components.scheme = "cirkl"
        components.host = "verify"
        components.queryItems = [
            URLQueryItem(name: "from", value: fromUserId),
            URLQueryItem(name: "name", value: fromUserName),
            URLQueryItem(name: "token", value: token)
        ]

        return components.url ?? URL(string: "cirkl://verify")!
    }

    // MARK: - Message Generation

    /// Crée le message d'invitation
    func createInvitationMessage(
        fromUserName: String,
        toContactName: String,
        link: URL
    ) -> String {
        """
        Salut \(toContactName) ! 👋

        On s'est rencontrés récemment et j'aimerais garder le contact avec toi.

        J'utilise CirKL, une app qui permet de maintenir des liens authentiques avec les personnes qu'on rencontre vraiment.

        Confirme qu'on s'est vus en cliquant ici :
        \(link.absoluteString)

        À bientôt !
        \(fromUserName)
        """
    }

    /// Crée un message court pour SMS
    func createShortMessage(
        fromUserName: String,
        link: URL
    ) -> String {
        """
        Hey ! C'est \(fromUserName). On s'est rencontrés récemment. Confirme notre rencontre sur CirKL : \(link.absoluteString)
        """
    }

    /// Crée un message viral pour le copier-coller (WhatsApp, etc.)
    func createViralMessage(
        fromUserName: String,
        toContactName: String,
        link: URL
    ) -> String {
        """
        Hey \(toContactName) ! 👋

        C'est \(fromUserName). On s'est croisés récemment et j'ai pensé à toi !

        J'utilise CirKL - c'est une app qui permet de garder le lien avec les personnes qu'on rencontre vraiment IRL. Fini les contacts fantômes qu'on ne revoit jamais 👻

        ✨ Je t'ai ajouté à mon réseau réel - confirme qu'on s'est vus :
        \(link.absoluteString)

        À très vite ! 🚀
        """
    }

    // MARK: - SMS

    /// Vérifie si l'appareil peut envoyer des SMS
    func canSendSMS() -> Bool {
        MFMessageComposeViewController.canSendText()
    }

    // MARK: - WhatsApp

    /// Vérifie si WhatsApp est installé
    func canOpenWhatsApp() -> Bool {
        guard let url = URL(string: "whatsapp://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    /// Crée l'URL WhatsApp pour envoyer un message
    func createWhatsAppURL(phone: String, message: String) -> URL? {
        // Nettoyer le numéro de téléphone (garder uniquement les chiffres et le +)
        let cleanPhone = phone.components(separatedBy: CharacterSet(charactersIn: "+0123456789").inverted).joined()

        // Encoder le message pour l'URL
        guard let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }

        // Format: whatsapp://send?phone=NUMERO&text=MESSAGE
        let urlString = "whatsapp://send?phone=\(cleanPhone)&text=\(encodedMessage)"
        return URL(string: urlString)
    }

    /// Ouvre WhatsApp avec le message
    func openWhatsApp(phone: String, message: String) {
        guard let url = createWhatsAppURL(phone: phone, message: message) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Share

    /// Crée les items pour le partage via UIActivityViewController
    func createShareItems(
        fromUserName: String,
        toContactName: String,
        link: URL
    ) -> [Any] {
        let message = createInvitationMessage(
            fromUserName: fromUserName,
            toContactName: toContactName,
            link: link
        )
        return [message, link]
    }

    /// Copie le message viral complet dans le presse-papier
    func copyMessageToClipboard(
        fromUserName: String,
        toContactName: String,
        link: URL
    ) {
        let message = createViralMessage(
            fromUserName: fromUserName,
            toContactName: toContactName,
            link: link
        )
        UIPasteboard.general.string = message
    }
}

// MARK: - SMS Composer Representable
/// UIViewControllerRepresentable pour MFMessageComposeViewController
struct MessageComposerView: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    let onDismiss: (MessageComposeResult) -> Void

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.recipients = recipients
        controller.body = body
        controller.messageComposeDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onDismiss: (MessageComposeResult) -> Void

        init(onDismiss: @escaping (MessageComposeResult) -> Void) {
            self.onDismiss = onDismiss
        }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            controller.dismiss(animated: true) {
                self.onDismiss(result)
            }
        }
    }
}

// MARK: - Invitation Result
enum InvitationResult {
    case sent
    case cancelled
    case failed
}
