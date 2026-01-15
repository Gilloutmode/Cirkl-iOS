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
    @State private var showActionSheet = false
    @State private var showNetworkPulse = false

    // Living Button state
    @State private var buttonState: AIButtonState = .idle
    @State private var synergiesCount: Int = 0
    @State private var synergies: [ButtonStateResponse.SynergyInfo] = []
    @State private var livingPulsePhase: Double = 0
    @State private var glowIntensity: Double = 0
    @State private var pollingTask: Task<Void, Never>?

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

    // MARK: - Colors by State (using DesignTokens for brand consistency)
    private let idleColor = DesignTokens.Colors.purple      // Violet original
    private let synergyColor = DesignTokens.Colors.electricBlue // Cyan → Electric Blue
    private let opportunityColor = DesignTokens.Colors.mint // #34C759 Green → Mint
    private let newConnectionColor = DesignTokens.Colors.pink // Orange → Pink (brand color)
    private let recordingColor = DesignTokens.Colors.error

    private var currentColor: Color {
        if audioService.state.isRecording {
            return recordingColor
        }
        switch buttonState {
        case .idle: return idleColor
        case .synergy: return synergyColor
        case .opportunity: return opportunityColor
        case .newConnection: return newConnectionColor
        }
    }

    var body: some View {
        ZStack {
            // === GLOW EFFECT pour opportunity/new_connection ===
            if buttonState == .opportunity || buttonState == .newConnection {
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
            if buttonState != .idle && !audioService.state.isRecording {
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

            // === BADGE SYNERGIES COUNT ===
            if synergiesCount > 0 && !audioService.state.isRecording {
                Text("\(synergiesCount)")
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
        .sheet(isPresented: $showNetworkPulse) {
            NetworkPulseView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Que veux-tu faire ?", isPresented: $showActionSheet, titleVisibility: .visible) {
            Button {
                showChat = true
            } label: {
                Label("Parler à l'IA", systemImage: "bubble.left.fill")
            }

            Button {
                showNetworkPulse = true
            } label: {
                Label("Santé de mon réseau", systemImage: "heart.text.square.fill")
            }

            Button("Annuler", role: .cancel) { }
        } message: {
            Text("Choisis une option pour interagir avec ton assistant")
        }
        // Listen for button state updates from chat responses
        .onReceive(NotificationCenter.default.publisher(for: .cirklButtonStateUpdate)) { notification in
            if let newStateString = notification.userInfo?["buttonState"] as? String,
               let newState = AIButtonState(rawValue: newStateString) {
                #if DEBUG
                print("🔔 Button received state update: \(newStateString)")
                #endif
                withAnimation(.easeInOut(duration: 0.3)) {
                    buttonState = newState
                    if newState == .idle {
                        synergiesCount = 0
                        synergies = []
                    }
                }
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
            return "mic.fill"
        }
    }

    private var pulseScale: CGFloat {
        switch buttonState {
        case .idle: return 0
        case .synergy: return 0.15
        case .opportunity: return 0.25
        case .newConnection: return 0.35
        }
    }

    private var pulseDuration: Double {
        switch buttonState {
        case .idle: return 0
        case .synergy: return 2.0
        case .opportunity: return 1.5
        case .newConnection: return 0.8
        }
    }

    // MARK: - Synergy Context

    private func buildSynergyContext() -> SynergyContext? {
        // Only require non-idle state, synergies array can be empty
        guard buttonState != .idle else { return nil }

        #if DEBUG
        print("🔘 buildSynergyContext: state=\(buttonState.rawValue), count=\(synergiesCount), synergies=\(synergies.count)")
        #endif

        return SynergyContext(
            state: buttonState,
            count: synergiesCount,
            synergies: synergies
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
        print("🟢 fetchButtonState() starting for userId: \(userId)")
        #endif
        do {
            let response = try await N8NService.shared.fetchButtonState(userId: userId)

            let previousState = buttonState
            buttonState = response.buttonState
            synergiesCount = response.synergiesCount
            synergies = response.synergies

            // Restart pulse animation if state changed
            if previousState != buttonState {
                restartLivingPulse()

                // Haptic feedback on state change
                if buttonState != .idle {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
            }

            #if DEBUG
            print("🔘 Button state updated: \(buttonState.rawValue), synergies: \(synergiesCount)")
            #endif
        } catch {
            // Keep previous state on error
            #if DEBUG
            print("❌ Button state fetch failed: \(error.localizedDescription)")
            #endif
        }
    }

    private func restartLivingPulse() {
        livingPulsePhase = 0
        glowIntensity = 0

        guard buttonState != .idle else { return }

        // Pulse animation
        withAnimation(.easeInOut(duration: pulseDuration).repeatForever(autoreverses: false)) {
            livingPulsePhase = 1.0
        }

        // Glow animation for opportunity/new_connection
        if buttonState == .opportunity || buttonState == .newConnection {
            withAnimation(.easeInOut(duration: pulseDuration).repeatForever(autoreverses: true)) {
                glowIntensity = 0.8
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
            // Tap court → Toujours afficher le menu d'options
            showActionSheet = true
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

// MARK: - Synergy Context Model

struct SynergyContext: Equatable {
    let state: AIButtonState
    let count: Int
    let synergies: [ButtonStateResponse.SynergyInfo]

    var stateDescription: String {
        switch state {
        case .idle: return ""
        case .synergy: return "Synergie détectée"
        case .opportunity: return "Opportunité"
        case .newConnection: return "Nouvelle connexion"
        }
    }

    var emoji: String {
        switch state {
        case .idle: return ""
        case .synergy: return "🤝"
        case .opportunity: return "💡"
        case .newConnection: return "✨"
        }
    }

    /// Build a prompt message describing the synergies
    var promptMessage: String {
        guard !synergies.isEmpty else {
            return "J'ai \(count) \(stateDescription.lowercased()) à te montrer. Que veux-tu savoir ?"
        }

        let descriptions = synergies.compactMap { $0.description }.prefix(3)
        if descriptions.isEmpty {
            return "\(emoji) \(stateDescription): J'ai détecté \(count) élément(s). Veux-tu que je t'en dise plus ?"
        }

        let descList = descriptions.joined(separator: "\n• ")
        return "\(emoji) \(stateDescription):\n• \(descList)\n\nVeux-tu que je t'en dise plus ?"
    }
}
