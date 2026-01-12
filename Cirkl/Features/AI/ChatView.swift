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

    /// Optional synergy context from Living Button state
    var initialSynergyContext: SynergyContext?

    init(initialAudioData: Data? = nil, initialSynergyContext: SynergyContext? = nil) {
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
                            if viewModel.messages.isEmpty && !viewModel.isLoading {
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

                    // Input bar with glass effect
                    InputBar(
                        text: $viewModel.inputText,
                        isLoading: viewModel.isLoading,
                        onSend: {
                            Task {
                                await viewModel.sendMessage()
                            }
                        }
                    )
                    .focused($isInputFocused)
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
        .onAppear {
            #if DEBUG
            print("💬 ChatView onAppear: messagesCount = \(viewModel.messages.count), hasSynergyContext = \(initialSynergyContext != nil)")
            #endif

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

            // Handle initial audio data from voice recording
            if let audioData = initialAudioData {
                Task {
                    await viewModel.sendAudioMessage(audioData)
                }
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
    private var pendingSynergyContext: SynergyContext?

    init() {
        loadHistory()
    }

    /// Load chat history from persistence
    private func loadHistory() {
        messages = historyService.loadMessages()
        #if DEBUG
        print("📚 ChatViewModel loaded \(messages.count) messages from history")
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

    func addSynergyContextMessage(_ context: SynergyContext) {
        // Store context to prepend to first user message
        pendingSynergyContext = context

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
    private func buildContextPrefix(from context: SynergyContext) -> String {
        let synergiesText = context.synergies.enumerated().map { index, syn in
            "\(index + 1). \(syn.description ?? "Opportunité \(index + 1)")"
        }.joined(separator: "\n")

        return """
        [CONTEXTE: J'ai vu ces opportunités dans mon réseau:
        \(synergiesText)
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
            // User bubble: Liquid Glass with primary tint
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignTokens.Colors.electricBlue.opacity(0.3),
                                    DesignTokens.Colors.purple.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
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
            // AI bubble: Clear Liquid Glass with accent
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignTokens.Colors.electricBlue.opacity(0.1),
                                    DesignTokens.Colors.mint.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
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

// MARK: - LoadingBubble with Liquid Glass
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
                    .fill(.ultraThinMaterial.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        DesignTokens.Colors.electricBlue.opacity(0.1),
                                        DesignTokens.Colors.mint.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(DesignTokens.Colors.glassBorder, lineWidth: 0.5)
                    )
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

// MARK: - InputBar with Liquid Glass
struct InputBar: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Text field with glass effect
            TextField("Message...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
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
                )
                .lineLimit(1...5)
                .disabled(isLoading)

            // Send button with glass effect
            Button(action: onSend) {
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
                            .fill(.ultraThinMaterial.opacity(canSend ? 0.3 : 0))
                            .frame(width: 36, height: 36)
                    )
            }
            .disabled(!canSend)
            .scaleEffect(canSend ? 1.0 : 0.9)
            .animation(.spring(response: 0.3), value: canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
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
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
}

// MARK: - Preview
#Preview {
    ChatView()
}
