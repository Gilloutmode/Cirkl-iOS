import Foundation
import SwiftData

// MARK: - SwiftData Model for Chat Messages

@Model
final class ChatMessageEntity {
    @Attribute(.unique) var id: UUID
    var content: String
    var isUser: Bool
    var timestamp: Date
    var intentRaw: String?
    var isVoiceMessage: Bool
    var sessionId: String

    init(
        id: UUID = UUID(),
        content: String,
        isUser: Bool,
        timestamp: Date = Date(),
        intent: CirklIntent? = nil,
        isVoiceMessage: Bool = false,
        sessionId: String
    ) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.intentRaw = intent?.rawValue
        self.isVoiceMessage = isVoiceMessage
        self.sessionId = sessionId
    }

    var intent: CirklIntent? {
        guard let raw = intentRaw else { return nil }
        return CirklIntent(rawValue: raw)
    }

    /// Convert to display model
    func toChatMessage() -> ChatMessage {
        ChatMessage(
            id: id,
            content: content,
            isUser: isUser,
            timestamp: timestamp,
            intent: intent,
            isVoiceMessage: isVoiceMessage
        )
    }
}

// MARK: - Chat History Service

@MainActor
final class ChatHistoryService {
    static let shared = ChatHistoryService()

    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?

    /// Current session ID - persisted across app launches
    private(set) var currentSessionId: String

    private let sessionIdKey = "cirkl_chat_session_id"

    private init() {
        // Load or create session ID
        if let savedSessionId = UserDefaults.standard.string(forKey: sessionIdKey) {
            currentSessionId = savedSessionId
        } else {
            currentSessionId = UUID().uuidString
            UserDefaults.standard.set(currentSessionId, forKey: sessionIdKey)
        }

        setupSwiftData()
    }

    private func setupSwiftData() {
        do {
            let schema = Schema([ChatMessageEntity.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: config)
            modelContext = modelContainer?.mainContext

            #if DEBUG
            print("✅ ChatHistoryService: SwiftData initialized")
            #endif
        } catch {
            #if DEBUG
            print("❌ ChatHistoryService: Failed to initialize SwiftData: \(error)")
            #endif
        }
    }

    // MARK: - Public Methods

    /// Load all messages for current session
    func loadMessages() -> [ChatMessage] {
        guard let context = modelContext else { return [] }

        let descriptor = FetchDescriptor<ChatMessageEntity>(
            predicate: #Predicate { $0.sessionId == currentSessionId },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )

        do {
            let entities = try context.fetch(descriptor)
            #if DEBUG
            print("📚 Loaded \(entities.count) messages from history")
            #endif
            return entities.map { $0.toChatMessage() }
        } catch {
            #if DEBUG
            print("❌ Failed to load messages: \(error)")
            #endif
            return []
        }
    }

    /// Save a new message
    func saveMessage(_ message: ChatMessage) {
        guard let context = modelContext else { return }

        let entity = ChatMessageEntity(
            id: message.id,
            content: message.content,
            isUser: message.isUser,
            timestamp: message.timestamp,
            intent: message.intent,
            isVoiceMessage: message.isVoiceMessage,
            sessionId: currentSessionId
        )

        context.insert(entity)

        do {
            try context.save()
            #if DEBUG
            print("💾 Message saved: \(message.content.prefix(30))...")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to save message: \(error)")
            #endif
        }
    }

    /// Clear all messages for current session
    func clearCurrentSession() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<ChatMessageEntity>(
            predicate: #Predicate { $0.sessionId == currentSessionId }
        )

        do {
            let entities = try context.fetch(descriptor)
            for entity in entities {
                context.delete(entity)
            }
            try context.save()

            // Create new session
            currentSessionId = UUID().uuidString
            UserDefaults.standard.set(currentSessionId, forKey: sessionIdKey)

            #if DEBUG
            print("🗑️ Chat history cleared, new session: \(currentSessionId)")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to clear history: \(error)")
            #endif
        }
    }

    /// Start a new session (keeps history but creates new session ID)
    func startNewSession() {
        currentSessionId = UUID().uuidString
        UserDefaults.standard.set(currentSessionId, forKey: sessionIdKey)

        #if DEBUG
        print("🆕 New session started: \(currentSessionId)")
        #endif
    }

    /// Get message count
    func messageCount() -> Int {
        guard let context = modelContext else { return 0 }

        let descriptor = FetchDescriptor<ChatMessageEntity>(
            predicate: #Predicate { $0.sessionId == currentSessionId }
        )

        do {
            return try context.fetchCount(descriptor)
        } catch {
            return 0
        }
    }
}
