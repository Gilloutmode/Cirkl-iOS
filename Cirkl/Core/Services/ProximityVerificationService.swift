import Foundation
import MultipeerConnectivity
import Combine

// MARK: - ProximityVerificationService
/// Service de vérification de proximité utilisant MultipeerConnectivity
/// Permet la découverte et l'échange de données avec les utilisateurs Cirkl proches
@MainActor
final class ProximityVerificationService: NSObject, ObservableObject {

    // MARK: - Singleton
    static let shared = ProximityVerificationService()

    // MARK: - Published Properties
    @Published private(set) var state: ProximityState = .idle
    @Published private(set) var nearbyPeers: [MCPeerID] = []
    @Published private(set) var connectedPeer: MCPeerID?
    @Published private(set) var receivedData: VerificationData?

    // MARK: - MultipeerConnectivity Properties
    private let serviceType = "cirkl-meet" // Max 15 chars, lowercase alphanumeric + hyphen
    private var peerID: MCPeerID?
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    // MARK: - Configuration
    private let searchTimeout: TimeInterval = 30.0
    private var searchTimer: Timer?
    private var currentUserData: VerificationData?

    // MARK: - Callbacks
    var onDataReceived: ((VerificationData) -> Void)?
    var onConnectionEstablished: ((MCPeerID) -> Void)?
    var onError: ((ProximityError) -> Void)?

    // MARK: - Initialization
    private override init() {
        super.init()
    }

    // MARK: - Public Methods

    /// Démarre la vérification de proximité
    /// - Parameters:
    ///   - userId: ID de l'utilisateur courant
    ///   - userName: Nom de l'utilisateur courant
    ///   - avatarURL: URL de l'avatar (optionnel)
    func startVerification(userId: String, userName: String, avatarURL: URL? = nil) {
        // Créer les données de vérification
        currentUserData = VerificationData(
            userId: userId,
            userName: userName,
            avatarURL: avatarURL,
            method: .proximity
        )

        // Initialiser MultipeerConnectivity
        setupMultipeerConnectivity(displayName: userName)

        // Démarrer l'advertising et le browsing
        startAdvertising()
        startBrowsing()

        state = .scanning

        // Timer de timeout
        searchTimer = Timer.scheduledTimer(withTimeInterval: searchTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, case .scanning = self.state else { return }
                self.handleError(.searchTimeout)
            }
        }
    }

    /// Arrête la vérification
    func stopVerification() {
        searchTimer?.invalidate()
        searchTimer = nil

        stopAdvertising()
        stopBrowsing()
        disconnectSession()

        nearbyPeers.removeAll()
        connectedPeer = nil
        receivedData = nil
        state = .idle
    }

    /// Se connecte à un peer découvert
    /// - Parameter peer: Le peer auquel se connecter
    func connectTo(_ peer: MCPeerID) {
        guard let browser = browser else { return }

        state = .connecting

        browser.invitePeer(
            peer,
            to: session!,
            withContext: nil,
            timeout: 10.0
        )
    }

    /// Envoie les données de vérification au peer connecté
    func sendVerificationData() throws {
        guard let session = session,
              let connectedPeer = connectedPeer,
              let userData = currentUserData else {
            throw ProximityError.connectionLost
        }

        let encoder = JSONEncoder()
        let data = try encoder.encode(userData)

        try session.send(data, toPeers: [connectedPeer], with: .reliable)
    }

    /// Envoie les données de vérification avec le token NearbyInteraction
    func sendVerificationData(withDiscoveryToken tokenData: Data?) throws {
        guard let session = session,
              let connectedPeer = connectedPeer,
              var userData = currentUserData else {
            throw ProximityError.connectionLost
        }

        // Créer une nouvelle instance avec le token
        let updatedData = VerificationData(
            id: userData.id,
            userId: userData.userId,
            userName: userData.userName,
            avatarURL: userData.avatarURL,
            timestamp: userData.timestamp,
            method: userData.method,
            location: userData.location,
            latitude: userData.latitude,
            longitude: userData.longitude,
            distance: userData.distance,
            discoveryTokenData: tokenData
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(updatedData)

        try session.send(data, toPeers: [connectedPeer], with: .reliable)
    }

    // MARK: - Private Methods

    private func setupMultipeerConnectivity(displayName: String) {
        peerID = MCPeerID(displayName: displayName)

        session = MCSession(
            peer: peerID!,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        session?.delegate = self
    }

    private func startAdvertising() {
        guard let peerID = peerID else { return }

        advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: ["app": "Cirkl", "version": "1.0"],
            serviceType: serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    private func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
    }

    private func startBrowsing() {
        guard let peerID = peerID else { return }

        browser = MCNearbyServiceBrowser(
            peer: peerID,
            serviceType: serviceType
        )
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }

    private func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
    }

    private func disconnectSession() {
        session?.disconnect()
        session = nil
        peerID = nil
    }

    private func handleError(_ error: ProximityError) {
        state = .error(error)
        onError?(error)
    }
}

// MARK: - MCSessionDelegate
extension ProximityVerificationService: MCSessionDelegate {

    nonisolated func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        Task { @MainActor in
            switch state {
            case .connected:
                self.connectedPeer = peerID
                self.state = .measuring
                self.onConnectionEstablished?(peerID)

                // Envoyer nos données de vérification
                do {
                    try self.sendVerificationData()
                } catch {
                    self.handleError(.unknown("Erreur d'envoi: \(error.localizedDescription)"))
                }

            case .connecting:
                self.state = .connecting

            case .notConnected:
                if self.connectedPeer == peerID {
                    self.connectedPeer = nil
                    if case .verified = self.state {
                        // Ne pas changer l'état si déjà vérifié
                    } else {
                        self.handleError(.connectionLost)
                    }
                }

            @unknown default:
                break
            }
        }
    }

    nonisolated func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        Task { @MainActor in
            do {
                let decoder = JSONDecoder()
                let verificationData = try decoder.decode(VerificationData.self, from: data)
                self.receivedData = verificationData
                self.onDataReceived?(verificationData)
            } catch {
                self.handleError(.unknown("Erreur de décodage: \(error.localizedDescription)"))
            }
        }
    }

    nonisolated func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {
        // Non utilisé
    }

    nonisolated func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
        // Non utilisé
    }

    nonisolated func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {
        // Non utilisé
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension ProximityVerificationService: MCNearbyServiceAdvertiserDelegate {

    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        Task { @MainActor in
            // Accepter automatiquement les invitations
            invitationHandler(true, self.session)
        }
    }

    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: Error
    ) {
        Task { @MainActor in
            self.handleError(.localNetworkPermissionDenied)
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension ProximityVerificationService: MCNearbyServiceBrowserDelegate {

    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        Task { @MainActor in
            // Vérifier que c'est bien une app Cirkl
            guard info?["app"] == "Cirkl" else { return }

            if !self.nearbyPeers.contains(where: { $0.displayName == peerID.displayName }) {
                self.nearbyPeers.append(peerID)

                // Notifier qu'un utilisateur a été trouvé
                self.state = .found(peerName: peerID.displayName, peerId: peerID.displayName)
            }
        }
    }

    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {
        Task { @MainActor in
            self.nearbyPeers.removeAll { $0.displayName == peerID.displayName }

            if self.nearbyPeers.isEmpty && self.connectedPeer == nil {
                self.state = .scanning
            }
        }
    }

    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: Error
    ) {
        Task { @MainActor in
            self.handleError(.localNetworkPermissionDenied)
        }
    }
}
