import SwiftUI
import Combine

// MARK: - Notification for button state updates from chat
extension Notification.Name {
    static let cirklButtonStateUpdate = Notification.Name("cirklButtonStateUpdate")
}

// MARK: - CIRKL AI BUTTON AVEC LIVING STATE + LIQUID GLASS
// Bouton AI avec design Liquid Glass, polling API pour état dynamique
// Supporte: tap pour chat, long press pour enregistrement vocal

struct CirklAIButton: View {
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - State Properties
    @State private var isPressed = false
    @State private var pulsePhase: Double = 0
    @State private var showChat = false

    // Living Button state - NEW: Uses AIAssistantState + DebriefingManager
    @State private var assistantState: AIAssistantState = .idle
    @State private var badgeCount: Int = 0
    @State private var livingPulsePhase: Double = 0
    @State private var glowIntensity: Double = 0
    @State private var pollingTask: Task<Void, Never>?

    // Debriefing manager reference
    private var debriefingManager: DebriefingManager { DebriefingManager.shared }

    // Audio recording state
    @StateObject private var audioService = AudioRecorderService.shared
    @State private var audioData: Data?
    @State private var isLongPressing = false
    @State private var longPressStartTime: Date?

    // MARK: - Configuration
    private let userId = "gil" // TODO: Get from AuthService
    private let pollingInterval: TimeInterval = 30
    private let buttonSize: CGFloat = 70
    private let longPressThreshold: TimeInterval = 0.3

    // MARK: - Colors by State (NEW: AIAssistantState colors)
    // idle = Blanc translucide (Liquid Glass)
    // morningBrief = Vert menthe (#00C781)
    // debriefing = Bleu électrique
    // synergyLow = Jaune
    // synergyHigh = Rouge
    private let recordingColor = DesignTokens.Colors.error

    // Morning brief manager reference
    private var morningBriefManager: MorningBriefManager { MorningBriefManager.shared }

    private var currentColor: Color {
        if audioService.state.isRecording {
            return recordingColor
        }
        return assistantState.color
    }

    var body: some View {
        ZStack {
            // === GLOW EFFECT pour synergies (jaune/rouge) et morning brief (vert) ===
            if assistantState == .synergyLow || assistantState == .synergyHigh || assistantState == .morningBrief {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [currentColor.opacity(0.5), currentColor.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                    .opacity(glowIntensity)
            }

            // === LIVING PULSE RING (quand état actif) ===
            if assistantState != .idle && !audioService.state.isRecording {
                Circle()
                    .stroke(currentColor.opacity(0.5), lineWidth: 2.5)
                    .frame(width: buttonSize + 10, height: buttonSize + 10)
                    .scaleEffect(1.0 + livingPulsePhase * pulseScale)
                    .opacity(1.0 - livingPulsePhase * 0.6)
            }

            // === FOND INTÉRIEUR TRANSPARENT TEINTÉ (Liquid Glass) ===
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            currentColor.opacity(0.15),
                            currentColor.opacity(0.25),
                            currentColor.opacity(0.10)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: buttonSize * 0.5
                    )
                )
                .frame(width: buttonSize - 4, height: buttonSize - 4)

            // === ICÔNE MIC / WAVEFORM ===
            Image(systemName: iconName)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            currentColor.opacity(0.9),
                            currentColor.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .symbolEffect(.pulse, isActive: audioService.state.isRecording)

            // === OVERLAY GLASS BUBBLE (effet transparent) ===
            GlassBubbleOverlay(size: buttonSize, tintColor: currentColor)

            // === REFLET DYNAMIQUE QUI BOUGE AVEC LE DEVICE ===
            Circle()
                .fill(Color.clear)
                .frame(width: buttonSize, height: buttonSize)
                .dynamicGlassReflection(intensity: 0.8)

            // === RING D'ENREGISTREMENT (rouge pulsant) ===
            if audioService.state.isRecording {
                Circle()
                    .stroke(recordingColor.opacity(0.8), lineWidth: 3)
                    .frame(width: buttonSize + 8, height: buttonSize + 8)
                    .scaleEffect(1.0 + CGFloat(audioService.audioLevel) * 0.15)
                    .animation(.easeOut(duration: 0.1), value: audioService.audioLevel)
            }

            // === BADGE COUNT (debriefings ou synergies) ===
            if badgeCount > 0 && !audioService.state.isRecording {
                Text("\(badgeCount)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(currentColor))
                    .offset(x: 28, y: -28)
            }

            // === DURATION INDICATOR pendant enregistrement ===
            if audioService.state.isRecording {
                Text(formatDuration(audioService.recordingDuration))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(DesignTokens.Colors.error))
                    .offset(y: 50)
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .scaleEffect(1.0 + pulsePhase * 0.02)
        .shadow(color: currentColor.opacity(0.3), radius: 12, x: 0, y: 6)
        // TAP SENSITIVITY FIX: Expanded hit area (88pt) for better touch detection
        // Visual size stays at 70pt but touch area is larger
        .frame(width: 88, height: 88)
        .contentShape(Circle())
        // Use minimumDistance: 0 for immediate tap response
        // minimumDistance: 5 was causing taps to not register
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    handlePressStart()
                }
                .onEnded { _ in
                    handlePressEnd()
                }
        )
        .onAppear {
            #if DEBUG
            print("🟢 CirklAIButton onAppear - starting animations and polling")
            #endif
            startAnimations()
            startPolling()
        }
        .onDisappear {
            stopPolling()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
        .sheet(isPresented: $showChat) {
            ChatView(
                initialAudioData: audioData,
                initialSynergyContext: buildSynergyContext()
            )
            .onDisappear {
                audioData = nil
            }
        }
        // Listen for debriefing state changes
        .onReceive(NotificationCenter.default.publisher(for: .debriefingStateChanged)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                assistantState = debriefingManager.currentState
                badgeCount = debriefingManager.badgeCount
                restartLivingPulse()
            }
        }
        // Listen for new synergy detections
        .onReceive(NotificationCenter.default.publisher(for: .synergyDetected)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                assistantState = debriefingManager.currentState
                badgeCount = debriefingManager.badgeCount
                restartLivingPulse()
            }
        }
    }

    // MARK: - Computed Properties

    private var iconName: String {
        switch audioService.state {
        case .recording:
            return "waveform.circle.fill"
        case .processing:
            return "ellipsis.circle.fill"
        case .requestingPermission:
            return "mic.circle"
        case .error:
            return "exclamationmark.circle.fill"
        case .idle:
            // Use state-specific icon when not recording
            return assistantState.icon
        }
    }

    private var pulseScale: CGFloat {
        assistantState.pulseScale
    }

    private var pulseDuration: Double {
        assistantState.pulseDuration
    }

    // MARK: - Context Building

    private func buildSynergyContext() -> AIAssistantContext? {
        // Only provide context if there's something to show
        guard assistantState != .idle else { return nil }

        #if DEBUG
        print("🔘 buildSynergyContext: state=\(assistantState.rawValue), debriefings=\(debriefingManager.pendingCount), synergies=\(debriefingManager.highSynergyCount + debriefingManager.lowSynergyCount), hasMorningBrief=\(morningBriefManager.hasPendingBrief)")
        #endif

        return AIAssistantContext(
            state: assistantState,
            pendingDebriefings: Array(debriefingManager.pendingDebriefings.prefix(3)),
            detectedSynergies: Array(debriefingManager.detectedSynergies.filter { !$0.isActedUpon }.prefix(3)),
            morningBrief: assistantState == .morningBrief ? morningBriefManager.currentBrief : nil
        )
    }

    // MARK: - Polling

    private func startPolling() {
        #if DEBUG
        print("🟢 startPolling() called for userId: \(userId)")
        #endif
        pollingTask?.cancel()
        pollingTask = Task {
            #if DEBUG
            print("🟢 Polling Task started")
            #endif
            // Initial fetch
            await fetchButtonState()

            // Polling loop
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(pollingInterval))
                if Task.isCancelled { break }
                await fetchButtonState()
            }
        }
    }

    private func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    @MainActor
    private func fetchButtonState() async {
        #if DEBUG
        print("🟢 fetchButtonState() - checking DebriefingManager")
        #endif

        let previousState = assistantState

        // Get state from DebriefingManager (local first)
        let newState = debriefingManager.currentState
        let newBadgeCount = debriefingManager.badgeCount

        // Also fetch N8N synergies (background analysis)
        do {
            let response = try await N8NService.shared.fetchButtonState(userId: userId)

            // If N8N has synergies, add them to DebriefingManager
            for synergyInfo in response.synergies {
                if let synergy = synergyInfo.toDetectedSynergy() {
                    debriefingManager.addSynergy(synergy)
                }
            }
        } catch {
            #if DEBUG
            print("⚠️ N8N fetch failed (using local state): \(error.localizedDescription)")
            #endif
        }

        // Update state from DebriefingManager (might have changed with N8N data)
        assistantState = debriefingManager.currentState
        badgeCount = debriefingManager.badgeCount

        // Restart pulse animation if state changed
        if previousState != assistantState {
            restartLivingPulse()

            // Haptic feedback on state change
            if assistantState != .idle {
                CirklHaptics.light()
            }
        }

        #if DEBUG
        print("🔘 Button state: \(assistantState.rawValue), badge: \(badgeCount)")
        #endif
    }

    private func restartLivingPulse() {
        livingPulsePhase = 0
        glowIntensity = 0

        guard assistantState != .idle else { return }

        // Pulse animation
        withAnimation(.easeInOut(duration: pulseDuration).repeatForever(autoreverses: false)) {
            livingPulsePhase = 1.0
        }

        // Glow animation for synergies (jaune/rouge) et morning brief (vert)
        if assistantState == .synergyLow || assistantState == .synergyHigh || assistantState == .morningBrief {
            withAnimation(.easeInOut(duration: pulseDuration).repeatForever(autoreverses: true)) {
                glowIntensity = assistantState.glowOpacity
            }
        }
    }

    // MARK: - Lifecycle

    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            #if DEBUG
            print("🔘 App active - resuming polling")
            #endif
            startPolling()
        case .background, .inactive:
            #if DEBUG
            print("🔘 App background - stopping polling")
            #endif
            stopPolling()
        @unknown default:
            break
        }
    }

    // MARK: - Gesture Handling

    private func handlePressStart() {
        // Debounce: Only handle once per press cycle
        guard !isLongPressing else { return }

        isLongPressing = true
        longPressStartTime = Date()

        // Haptic feedback on press
        CirklHaptics.medium()

        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            isPressed = true
        }

        // Start recording after long press threshold
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Int(longPressThreshold * 1000)))

            // Check we're still pressing
            guard isLongPressing else { return }

            // Heavy haptic for recording start
            CirklHaptics.heavy()

            do {
                try await audioService.startRecording()
                #if DEBUG
                print("🎤 Recording started via long press")
                #endif
            } catch {
                #if DEBUG
                print("❌ Failed to start recording: \(error)")
                #endif
            }
        }
    }

    private func handlePressEnd() {
        let pressDuration = Date().timeIntervalSince(longPressStartTime ?? Date())

        withAnimation(.easeOut(duration: 0.2)) {
            isPressed = false
        }

        if audioService.state.isRecording {
            // Long press terminé → arrêter l'enregistrement et envoyer
            Task {
                do {
                    let data = try await audioService.stopRecording()
                    #if DEBUG
                    print("🎤 Recording stopped: \(data.count) bytes")
                    #endif
                    audioData = data
                    showChat = true
                } catch {
                    #if DEBUG
                    print("❌ Failed to stop recording: \(error)")
                    #endif
                    audioService.cancelRecording()
                }
            }
        } else if pressDuration < longPressThreshold {
            // Tap court → ouvrir le chat
            showChat = true
        }

        isLongPressing = false
        longPressStartTime = nil
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration) % 60
        let tenths = Int((duration - Double(Int(duration))) * 10)
        return String(format: "%d.%d", seconds, tenths)
    }

    private func startAnimations() {
        // Base breathing animation
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            pulsePhase = 1.0
        }

        // Initial living pulse if not idle
        restartLivingPulse()
    }
}

// MARK: - AI Assistant Context Model

/// Contexte passé au ChatView quand le bouton est cliqué
struct AIAssistantContext: Equatable {
    let state: AIAssistantState
    let pendingDebriefings: [PendingDebriefing]
    let detectedSynergies: [DetectedSynergy]
    let morningBrief: MorningBrief?

    init(
        state: AIAssistantState,
        pendingDebriefings: [PendingDebriefing] = [],
        detectedSynergies: [DetectedSynergy] = [],
        morningBrief: MorningBrief? = nil
    ) {
        self.state = state
        self.pendingDebriefings = pendingDebriefings
        self.detectedSynergies = detectedSynergies
        self.morningBrief = morningBrief
    }

    static func == (lhs: AIAssistantContext, rhs: AIAssistantContext) -> Bool {
        lhs.state == rhs.state &&
        lhs.pendingDebriefings.map(\.id) == rhs.pendingDebriefings.map(\.id) &&
        lhs.detectedSynergies.map(\.id) == rhs.detectedSynergies.map(\.id) &&
        lhs.morningBrief?.generatedAt == rhs.morningBrief?.generatedAt
    }

    var stateDescription: String {
        state.title
    }

    var emoji: String {
        switch state {
        case .idle: return ""
        case .morningBrief: return "🌅"
        case .debriefing: return "💬"
        case .synergyLow: return "🤝"
        case .synergyHigh: return "🔥"
        }
    }

    /// Génère le message initial de l'IA selon l'état
    var promptMessage: String {
        switch state {
        case .idle:
            return "Salut ! Comment puis-je t'aider avec ton réseau ?"

        case .morningBrief:
            // Utilise le brief passé dans le contexte
            if let brief = morningBrief {
                return brief.briefText
            }
            return "🌅 **Brief du matin**\n\nTon réseau a respiré cette nuit. Laisse-moi te raconter ce qui s'est passé..."

        case .debriefing:
            guard let debriefing = pendingDebriefings.first else {
                return "Tu as des debriefings en attente. Clique pour voir."
            }
            let profile = debriefing.publicProfile
            var message = "💬 Super ! Tu t'es connecté à **\(profile.name)** !\n\n"

            // Infos publiques
            if let role = profile.role, let company = profile.company {
                message += "📋 \(role) chez \(company)\n"
            }
            if profile.mutualConnectionsCount > 0 {
                message += "👥 \(profile.mutualConnectionsCount) connexion(s) en commun"
                if !profile.mutualConnectionNames.isEmpty {
                    message += " : \(profile.mutualConnectionNames.prefix(3).joined(separator: ", "))"
                }
                message += "\n"
            }
            if !profile.tags.isEmpty {
                message += "🏷️ Intérêts : \(profile.tags.prefix(3).joined(separator: ", "))\n"
            }

            message += "\n**Qu'as-tu pensé de cette rencontre ?**"
            return message

        case .synergyLow, .synergyHigh:
            let count = detectedSynergies.count
            if count == 0 {
                return "\(emoji) J'ai détecté des opportunités dans ton réseau. Veux-tu en savoir plus ?"
            }

            var message = "\(emoji) **\(state == .synergyHigh ? "Opportunité importante" : "Opportunité détectée")** !\n\n"

            for synergy in detectedSynergies.prefix(3) {
                message += "• **\(synergy.connectionAName)** ↔ **\(synergy.connectionBName)**\n"
                message += "  \(synergy.synergyType.displayName) (score: \(Int(synergy.score * 100))%)\n"
                message += "  _\(synergy.reason)_\n\n"
            }

            message += "Veux-tu que je facilite une mise en relation ?"
            return message
        }
    }
}

// MARK: - Legacy SynergyContext (backward compatibility)

/// Ancien modèle pour compatibilité avec l'API N8N existante
struct SynergyContext: Equatable {
    let state: AIButtonState
    let count: Int
    let synergies: [ButtonStateResponse.SynergyInfo]

    var stateDescription: String {
        switch state {
        case .idle: return ""
        case .synergy, .synergyLow: return "Synergie détectée"
        case .opportunity, .synergyHigh: return "Opportunité importante"
        case .newConnection: return "Nouvelle connexion"
        }
    }

    var emoji: String {
        switch state {
        case .idle: return ""
        case .synergy, .synergyLow: return "🤝"
        case .opportunity, .synergyHigh: return "🔥"
        case .newConnection: return "✨"
        }
    }

    var promptMessage: String {
        guard !synergies.isEmpty else {
            return "J'ai \(count) \(stateDescription.lowercased()) à te montrer."
        }
        let descriptions = synergies.compactMap { $0.description }.prefix(3)
        let descList = descriptions.joined(separator: "\n• ")
        return "\(emoji) \(stateDescription):\n• \(descList)"
    }
}
