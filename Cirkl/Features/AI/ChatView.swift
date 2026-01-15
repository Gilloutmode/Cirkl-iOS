import SwiftUI

// MARK: - ChatMessage Model
struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    var intent: CirklIntent?
    var isVoiceMessage: Bool

    init(
        id: UUID = UUID(),
        content: String,
        isUser: Bool,
        timestamp: Date = Date(),
        intent: CirklIntent? = nil,
        isVoiceMessage: Bool = false
    ) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.intent = intent
        self.isVoiceMessage = isVoiceMessage
    }
}

// MARK: - ChatView
struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool

    /// Optional initial audio data from voice recording
    var initialAudioData: Data?

    /// Optional assistant context from Living Button state (debriefings, synergies)
    var initialSynergyContext: AIAssistantContext?

    init(initialAudioData: Data? = nil, initialSynergyContext: AIAssistantContext? = nil) {
        self.initialAudioData = initialAudioData
        self.initialSynergyContext = initialSynergyContext
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient for glass effect
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Messages list
                    ScrollViewReader { proxy in
                        ScrollView {
                            if viewModel.messages.isEmpty && viewModel.isLoading {
                                // Loading state
                                VStack {
                                    Spacer(minLength: 150)
                                    ProgressView()
                                        .scaleEffect(1.2)
                                    Text("Chargement...")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 12)
                                    Spacer()
                                }
                                .frame(minHeight: 400)
                            } else if viewModel.messages.isEmpty && !viewModel.isLoading {
                                // Empty state - aucune conversation
                                VStack {
                                    Spacer(minLength: 80)
                                    CirklEmptyState.chat(onStart: {
                                        CirklHaptics.selection()
                                        isInputFocused = true
                                    })
                                    Spacer()
                                }
                                .frame(minHeight: 400)
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.messages) { message in
                                        MessageBubble(message: message)
                                            .id(message.id)
                                    }

                                    if viewModel.isLoading {
                                        LoadingBubble()
                                            .id("loading")
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                        }
                        .onChange(of: viewModel.messages.count) { _, _ in
                            withAnimation {
                                if let lastId = viewModel.messages.last?.id {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: viewModel.isLoading) { _, isLoading in
                            if isLoading {
                                withAnimation {
                                    proxy.scrollTo("loading", anchor: .bottom)
                                }
                            }
                        }
                    }

                    // Input bar with glass effect (iMessage style: mic | text | send)
                    InputBar(
                        text: $viewModel.inputText,
                        isLoading: viewModel.isLoading,
                        textFieldFocused: $isInputFocused,
                        onSend: {
                            Task {
                                await viewModel.sendMessage()
                            }
                        },
                        onSendAudio: { audioData in
                            Task {
                                await viewModel.sendAudioMessage(audioData)
                            }
                        }
                    )
                }
            }
            .navigationTitle("Cirkl AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.clearChat()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(viewModel.messages.isEmpty)
                }
            }
        }
        .task {
            // PERFORMANCE FIX: Load history asynchronously to not block main thread
            // This prevents the "Reporter disconnected" spam and slow chat opening
            await viewModel.loadHistoryAsync()

            #if DEBUG
            print("💬 ChatView onAppear: messagesCount = \(viewModel.messages.count), hasSynergyContext = \(initialSynergyContext != nil), hasAudio = \(initialAudioData != nil)")
            #endif

            // CRITICAL FIX: Handle audio FIRST, before any early returns
            // Audio from voice recording should ALWAYS be sent, regardless of history
            if let audioData = initialAudioData {
                #if DEBUG
                print("🎤 ChatView: Sending voice note (\(audioData.count) bytes)")
                #endif
                await viewModel.sendAudioMessage(audioData)
            }

            // SIMPLE LOGIC: History is source of truth
            // If there's ANY history, show it and don't add anything
            guard viewModel.messages.isEmpty else {
                #if DEBUG
                print("💬 Showing existing history (\(viewModel.messages.count) messages)")
                #endif
                return
            }

            // No history - this is a fresh conversation
            // Priority: synergy context > welcome message
            if let context = initialSynergyContext {
                #if DEBUG
                print("💬 Fresh chat with synergy context")
                #endif
                viewModel.addSynergyContextMessage(context)
            } else {
                #if DEBUG
                print("💬 Fresh chat with welcome message")
                #endif
                viewModel.addWelcomeMessage()
            }
        }
    }
}

// MARK: - ChatViewModel
@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let userId = "gil" // TODO: Get from auth
    private let historyService = ChatHistoryService.shared

    /// Session ID from history service
    private var sessionId: String {
        historyService.currentSessionId
    }

    /// Stored synergy context to include with first user message
    private var pendingSynergyContext: AIAssistantContext?

    /// Track active debriefing for completion
    private var activeDebriefingId: UUID?

    init() {
        // PERFORMANCE FIX: Don't load history synchronously in init
        // This was blocking the main thread and causing slow ChatView opening
        // History is now loaded asynchronously in loadHistoryAsync()
    }

    /// Load chat history asynchronously (PERFORMANCE FIX)
    /// Call this from onAppear to avoid blocking main thread
    func loadHistoryAsync() async {
        isLoading = true
        let loaded = await historyService.loadMessages()
        messages = loaded
        isLoading = false
        #if DEBUG
        print("📚 ChatViewModel loaded \(messages.count) messages from history (async)")
        #endif
    }

    /// Save a message to persistence
    private func saveMessage(_ message: ChatMessage) {
        historyService.saveMessage(message)
    }

    func addWelcomeMessage() {
        let welcome = ChatMessage(
            content: "Salut ! Je suis Cirkl, ton assistant pour gérer et valoriser ton réseau. Comment puis-je t'aider aujourd'hui ?",
            isUser: false
        )
        messages.append(welcome)
        saveMessage(welcome)
    }

    func addSynergyContextMessage(_ context: AIAssistantContext) {
        // Store context to prepend to first user message
        pendingSynergyContext = context

        // Track active debriefing for completion
        if context.state == .debriefing, let firstDebriefing = context.pendingDebriefings.first {
            activeDebriefingId = firstDebriefing.id
            #if DEBUG
            print("💬 Tracking debriefing for: \(firstDebriefing.connectionName) (id: \(firstDebriefing.id))")
            #endif
        }

        // Display locally and persist
        let synergyMessage = ChatMessage(
            content: context.promptMessage,
            isUser: false
        )
        messages.append(synergyMessage)
        saveMessage(synergyMessage)

        #if DEBUG
        print("💡 Synergy context stored, will be sent with first user message")
        #endif
    }

    /// Build context prefix for N8N
    private func buildContextPrefix(from context: AIAssistantContext) -> String {
        var contextParts: [String] = []

        // Add debriefings context
        if !context.pendingDebriefings.isEmpty {
            let debriefingText = context.pendingDebriefings.map { debriefing in
                "- \(debriefing.connectionName): \(debriefing.publicProfile.summary)"
            }.joined(separator: "\n")
            contextParts.append("Debriefings en attente:\n\(debriefingText)")
        }

        // Add synergies context
        if !context.detectedSynergies.isEmpty {
            let synergiesText = context.detectedSynergies.enumerated().map { index, synergy in
                "\(index + 1). \(synergy.synergyType.displayName): \(synergy.connectionAName) <-> \(synergy.connectionBName) - \(synergy.reason)"
            }.joined(separator: "\n")
            contextParts.append("Synergies détectées:\n\(synergiesText)")
        }

        guard !contextParts.isEmpty else { return "" }

        return """
        [CONTEXTE:
        \(contextParts.joined(separator: "\n\n"))
        ]

        Ma réponse:
        """
    }

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        // Add user message (display original text)
        let userMessage = ChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        saveMessage(userMessage)
        inputText = ""

        // Build message to send - include context if pending
        var messageToSend = text
        if let context = pendingSynergyContext {
            messageToSend = buildContextPrefix(from: context) + text
            pendingSynergyContext = nil // Clear after first use

            #if DEBUG
            print("📤 Sending message with synergy context: \(messageToSend)")
            #endif
        }

        // Send to API
        isLoading = true
        errorMessage = nil

        do {
            let response = try await N8NService.shared.sendMessage(
                messageToSend,
                userId: userId,
                sessionId: sessionId
            )

            if response.success {
                let assistantMessage = ChatMessage(
                    content: response.response,
                    isUser: false,
                    intent: response.detectedIntent
                )
                messages.append(assistantMessage)
                saveMessage(assistantMessage)

                // DEBRIEFING COMPLETION: Mark debriefing as complete after user responds
                if let debriefingId = activeDebriefingId {
                    DebriefingManager.shared.completeDebriefing(id: debriefingId)
                    activeDebriefingId = nil
                    #if DEBUG
                    print("✅ Debriefing completed: \(debriefingId)")
                    #endif

                    // Notify button to update state
                    NotificationCenter.default.post(name: .debriefingStateChanged, object: nil)
                }

                // Propagate button state update to CirklAIButton
                if let newButtonState = response.buttonState ?? response.metadata?.buttonState {
                    #if DEBUG
                    print("📢 Posting button state update: \(newButtonState)")
                    #endif
                    NotificationCenter.default.post(
                        name: .cirklButtonStateUpdate,
                        object: nil,
                        userInfo: ["buttonState": newButtonState]
                    )

                    // If state changed to idle, persist to backend (Neo4j)
                    if newButtonState == "idle" {
                        Task {
                            do {
                                try await N8NService.shared.acknowledgeSynergies(userId: userId)
                            } catch {
                                #if DEBUG
                                print("⚠️ Failed to acknowledge synergies: \(error)")
                                #endif
                            }
                        }
                    }
                }
            } else {
                let errorMsg = ChatMessage(
                    content: "Désolé, je n'ai pas pu traiter ta demande. Réessaie dans quelques instants.",
                    isUser: false
                )
                messages.append(errorMsg)
                saveMessage(errorMsg)
            }
        } catch {
            errorMessage = error.localizedDescription
            let errorMsg = ChatMessage(
                content: "Erreur de connexion: \(error.localizedDescription)",
                isUser: false
            )
            messages.append(errorMsg)
            saveMessage(errorMsg)

            #if DEBUG
            print("❌ Chat error: \(error)")
            #endif
        }

        isLoading = false
    }

    /// Send audio message to the AI
    func sendAudioMessage(_ audioData: Data) async {
        guard !isLoading else { return }

        // Add placeholder user message for voice
        let userMessage = ChatMessage(
            content: "🎤 Message vocal",
            isUser: true,
            isVoiceMessage: true
        )
        messages.append(userMessage)
        saveMessage(userMessage)

        isLoading = true
        errorMessage = nil

        do {
            let response = try await N8NService.shared.sendAudio(
                audioData,
                userId: userId,
                sessionId: sessionId
            )

            if response.success {
                let assistantMessage = ChatMessage(
                    content: response.response,
                    isUser: false,
                    intent: response.detectedIntent
                )
                messages.append(assistantMessage)
                saveMessage(assistantMessage)

                // DEBRIEFING COMPLETION: Mark debriefing as complete after user responds (audio)
                if let debriefingId = activeDebriefingId {
                    DebriefingManager.shared.completeDebriefing(id: debriefingId)
                    activeDebriefingId = nil
                    #if DEBUG
                    print("✅ Debriefing completed (audio): \(debriefingId)")
                    #endif

                    // Notify button to update state
                    NotificationCenter.default.post(name: .debriefingStateChanged, object: nil)
                }

                // Propagate button state update to CirklAIButton
                if let newButtonState = response.buttonState ?? response.metadata?.buttonState {
                    #if DEBUG
                    print("📢 Posting button state update (audio): \(newButtonState)")
                    #endif
                    NotificationCenter.default.post(
                        name: .cirklButtonStateUpdate,
                        object: nil,
                        userInfo: ["buttonState": newButtonState]
                    )

                    // If state changed to idle, persist to backend (Neo4j)
                    if newButtonState == "idle" {
                        Task {
                            do {
                                try await N8NService.shared.acknowledgeSynergies(userId: userId)
                            } catch {
                                #if DEBUG
                                print("⚠️ Failed to acknowledge synergies (audio): \(error)")
                                #endif
                            }
                        }
                    }
                }
            } else {
                let errorMsg = ChatMessage(
                    content: "Désolé, je n'ai pas pu traiter ton message vocal. Réessaie dans quelques instants.",
                    isUser: false
                )
                messages.append(errorMsg)
                saveMessage(errorMsg)
            }
        } catch {
            errorMessage = error.localizedDescription
            let errorMsg = ChatMessage(
                content: "Erreur de connexion: \(error.localizedDescription)",
                isUser: false
            )
            messages.append(errorMsg)
            saveMessage(errorMsg)

            #if DEBUG
            print("❌ Audio chat error: \(error)")
            #endif
        }

        isLoading = false
    }

    func clearChat() {
        historyService.clearCurrentSession()
        messages.removeAll()

        // Add welcome for immediate display, but DON'T save it
        // When chat reopens, onAppear will decide what to show
        // (synergy context or welcome) based on empty history
        let welcome = ChatMessage(
            content: "Salut ! Je suis Cirkl, ton assistant pour gérer et valoriser ton réseau. Comment puis-je t'aider aujourd'hui ?",
            isUser: false
        )
        messages.append(welcome)
        // Note: intentionally not calling saveMessage() here
    }

    /// Clear messages for synergy context display (without clearing persistence)
    func clearForSynergyContext() {
        messages.removeAll()
        #if DEBUG
        print("🔄 Cleared messages for synergy context display")
        #endif
    }
}

// MARK: - MessageBubble with Liquid Glass
struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if message.isVoiceMessage {
                        Image(systemName: "waveform")
                            .font(.system(size: 14))
                            .foregroundColor(message.isUser ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textSecondary)
                    }

                    Text(message.content)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(bubbleBackground)
                .foregroundColor(message.isUser ? .primary : .primary)

                if let intent = message.intent, intent != .generalChat {
                    intentBadge(intent)
                }
            }

            if !message.isUser { Spacer(minLength: 60) }
        }
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if message.isUser {
            // User bubble: Native Liquid Glass iOS 26 with primary tint
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            DesignTokens.Colors.electricBlue.opacity(0.25),
                            DesignTokens.Colors.purple.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    DesignTokens.Colors.glassBorder,
                                    DesignTokens.Colors.glassBorder.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: DesignTokens.Colors.electricBlue.opacity(0.2), radius: 8, x: 0, y: 4)
        } else {
            // AI bubble: Native Liquid Glass iOS 26 with accent
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            DesignTokens.Colors.electricBlue.opacity(0.08),
                            DesignTokens.Colors.mint.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .glassEffect(.regular, in: .rect(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    DesignTokens.Colors.glassBorder,
                                    DesignTokens.Colors.glassBorder.opacity(0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        }
    }

    @ViewBuilder
    private func intentBadge(_ intent: CirklIntent) -> some View {
        Text(intentLabel(intent))
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial.opacity(0.5))
            )
    }

    private func intentLabel(_ intent: CirklIntent) -> String {
        switch intent {
        case .newConnection: return "🔗 Nouvelle connexion"
        case .memorySearch: return "🔍 Recherche mémoire"
        case .analyticsReport: return "📊 Analytics"
        case .opportunityMatch: return "✨ Opportunité"
        case .generalChat: return ""
        }
    }
}

// MARK: - LoadingBubble with Native Liquid Glass
struct LoadingBubble: View {
    @State private var animationPhase = 0.0

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(DesignTokens.Colors.electricBlue.opacity(0.8))
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationPhase == Double(index) ? 1.2 : 0.8)
                        .opacity(animationPhase == Double(index) ? 1 : 0.5)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignTokens.Colors.electricBlue.opacity(0.08),
                                DesignTokens.Colors.mint.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .glassEffect(.regular, in: .rect(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(DesignTokens.Colors.glassBorder, lineWidth: 0.5)
            )

            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: false)) {
                animationPhase = 3
            }
        }
    }
}

// MARK: - InputBar with Native Liquid Glass (Style iMessage)
struct InputBar: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void
    let onSendAudio: ((Data) -> Void)?

    // PERFORMANCE FIX: Use local state for text input to avoid triggering ViewModel updates on every keystroke
    // This prevents RTIInputSystemClient lag and unnecessary view rebuilds
    @State private var localText: String = ""

    // Audio recording state
    @StateObject private var audioService = AudioRecorderService.shared
    @State private var isRecording = false
    @State private var recordingPulse: CGFloat = 1.0

    // Focus state passed from parent (ChatView) - NOT isolated
    var textFieldFocused: FocusState<Bool>.Binding

    init(text: Binding<String>, isLoading: Bool, textFieldFocused: FocusState<Bool>.Binding, onSend: @escaping () -> Void, onSendAudio: ((Data) -> Void)? = nil) {
        self._text = text
        self.isLoading = isLoading
        self.textFieldFocused = textFieldFocused
        self.onSend = onSend
        self.onSendAudio = onSendAudio
        // Initialize local text from binding
        self._localText = State(initialValue: text.wrappedValue)
    }

    var body: some View {
        HStack(spacing: 12) {
            // MARK: Mic Button (Left - iMessage style)
            // CRITICAL FIX: Removed glassEffect - it blocks touch events on iOS 26 real devices
            // Using ultraThinMaterial background instead
            Button {
                toggleRecording()
            } label: {
                ZStack {
                    // Background circle with material instead of glassEffect
                    Circle()
                        .fill(isRecording ? Color.red.opacity(0.15) : Color.primary.opacity(0.06))
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                        .frame(width: 36, height: 36)

                    // Pulsing ring when recording
                    if isRecording {
                        Circle()
                            .stroke(Color.red.opacity(0.4), lineWidth: 2)
                            .frame(width: 36, height: 36)
                            .scaleEffect(recordingPulse)
                            .opacity(2 - recordingPulse)
                    }

                    // Icon
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(
                            isRecording
                                ? Color.red
                                : DesignTokens.Colors.electricBlue
                        )
                }
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            .disabled(isLoading)
            .animation(.spring(response: 0.3), value: isRecording)

            // MARK: Text Field (Center)
            // CRITICAL FIX: Removed ALL glassEffect from TextField - it blocks touch events on iOS 26 real devices
            // Using .ultraThinMaterial instead which doesn't intercept touches
            // PERFORMANCE FIX: Using localText to avoid ViewModel updates on every keystroke
            TextField("Message...", text: $localText, axis: .vertical)
                .textFieldStyle(.plain)
                .focused(textFieldFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.primary.opacity(0.06))
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    DesignTokens.Colors.glassBorder,
                                    DesignTokens.Colors.glassBorder.opacity(0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
                .lineLimit(1...5)
                // PERFORMANCE FIX: Disable animations during text input to prevent RTIInputSystemClient issues
                .transaction { $0.animation = nil }

            // MARK: Send Button (Right)
            // CRITICAL FIX: Removed glassEffect - it blocks touch events on iOS 26 real devices
            Button {
                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                // PERFORMANCE FIX: Sync localText to binding before sending
                text = localText
                onSend()
                // Clear local text after sending
                localText = ""
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        canSend
                            ? LinearGradient(
                                colors: [DesignTokens.Colors.electricBlue, DesignTokens.Colors.electricBlue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [DesignTokens.Colors.textTertiary.opacity(0.5), DesignTokens.Colors.textTertiary.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .background(
                        Circle()
                            .fill(Color.primary.opacity(canSend ? 0.08 : 0))
                            .background(
                                canSend ? AnyView(Circle().fill(.ultraThinMaterial)) : AnyView(EmptyView())
                            )
                            .frame(width: 36, height: 36)
                    )
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            .disabled(!canSend)
            .scaleEffect(canSend ? 1.0 : 0.9)
            .animation(.spring(response: 0.3), value: canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Color.primary.opacity(0.02))
                .background(.ultraThinMaterial) // Use material instead of glassEffect to not block touches
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignTokens.Colors.glassBorder.opacity(0.5),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
        // CRITICAL FIX: Removed .glassEffect(.regular) from container - it was blocking all touch events on real device
        // The individual TextField already has its own glassEffect which doesn't block touches
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                startPulseAnimation()
            }
        }
        // PERFORMANCE FIX: Sync from binding when it changes externally (e.g., viewModel clears inputText)
        .onChange(of: text) { _, newValue in
            if newValue != localText {
                localText = newValue
            }
        }
    }

    // PERFORMANCE FIX: Use localText for canSend to match the TextField binding
    private var canSend: Bool {
        !localText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading && !isRecording
    }

    private func toggleRecording() {
        Task {
            if isRecording {
                // Stop recording and send
                isRecording = false
                do {
                    let data = try await audioService.stopRecording()
                    // Haptic feedback
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    onSendAudio?(data)
                } catch {
                    #if DEBUG
                    print("❌ Stop recording error: \(error)")
                    #endif
                }
            } else {
                // Start recording
                do {
                    try await audioService.startRecording()
                    // Haptic feedback on success
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    isRecording = true
                } catch {
                    #if DEBUG
                    print("❌ Start recording error: \(error)")
                    #endif
                    // Haptic feedback for error
                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.error)
                }
            }
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            recordingPulse = 1.5
        }
    }
}

// MARK: - Preview
#Preview {
    ChatView()
}
