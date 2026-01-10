import Foundation
import UIKit

// MARK: - N8NService
/// Service for communicating with N8N Cirkl backend v17.29
@MainActor
final class N8NService {

    // MARK: - Singleton
    static let shared = N8NService()

    // MARK: - Configuration
    private let baseURL = "https://gilloutmode.app.n8n.cloud/webhook/cirkl-ios"
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        encoder = JSONEncoder()
        // N8N expects camelCase (userId, messageType, etc.)
        // Do NOT use snake_case conversion
        decoder = JSONDecoder()
        // Response from N8N is also camelCase
    }

    // MARK: - Request Models

    struct MessageRequest: Encodable {
        let userId: String
        let messageType: String
        let content: String
        let sessionId: String
        let deviceInfo: DeviceInfo
        let authToken: String?
    }

    // MARK: - Update Connection Request (v17.29)

    /// Request for updating an existing connection's relationship profile
    struct UpdateConnectionRequest: Encodable {
        let userId: String
        let action: String  // "update_connection"
        let connectionId: String
        let connectionProfile: ConnectionProfilePayload
        let sessionId: String
        let authToken: String?

        struct ConnectionProfilePayload: Encodable {
            let id: String
            let relationshipProfile: RelationshipProfilePayload

            struct RelationshipProfilePayload: Encodable {
                let spheres: [String]
                let natures: [String]
                let closeness: Int
                let interactionFrequency: String
                let meetingContext: String
                let sharedInterests: [String]
                let sharedCircles: [String]
            }
        }
    }

    /// Response from update connection endpoint
    struct UpdateConnectionResponse: Decodable, Sendable {
        let success: Bool
        let message: String?
    }

    struct DeviceInfo: Codable, Sendable {
        let appVersion: String
        let osVersion: String
        let deviceModel: String

        @MainActor
        static var current: DeviceInfo {
            DeviceInfo(
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
                osVersion: UIDevice.current.systemVersion,
                deviceModel: UIDevice.current.model
            )
        }
    }

    // MARK: - Response Models

    struct AssistantResponse: Decodable, Sendable {
        let success: Bool
        let response: String
        let intent: String?
        let buttonState: String?  // "idle", "synergy", "opportunity", "newConnection"
        let metadata: ResponseMetadata?

        struct ResponseMetadata: Decodable, Sendable {
            let hasNewConnection: Bool?
            let connectionProfile: ConnectionProfile?
            let suggestions: [String]?
            let buttonState: String?  // Also available in metadata
        }

        struct ConnectionProfile: Decodable, Sendable {
            let name: String?
            let context: String?
            let sphere: String?
        }
    }

    // MARK: - Public Methods

    /// Send a text message to the Cirkl AI assistant
    func sendMessage(_ message: String, userId: String, sessionId: String? = nil) async throws -> AssistantResponse {
        let request = MessageRequest(
            userId: userId,
            messageType: "text",
            content: message,
            sessionId: sessionId ?? UUID().uuidString,
            deviceInfo: DeviceInfo.current,
            authToken: nil
        )

        return try await performRequest(request)
    }

    /// Send audio data to the Cirkl AI assistant
    func sendAudio(_ audioData: Data, userId: String, sessionId: String? = nil) async throws -> AssistantResponse {
        let base64Audio = audioData.base64EncodedString()

        let request = MessageRequest(
            userId: userId,
            messageType: "audio",
            content: base64Audio,
            sessionId: sessionId ?? UUID().uuidString,
            deviceInfo: DeviceInfo.current,
            authToken: nil
        )

        return try await performRequest(request)
    }

    // MARK: - Update Connection (v17.29)

    /// Update an existing connection's relationship profile in Google Sheets
    /// - Parameters:
    ///   - connectionId: The unique identifier of the connection to update
    ///   - relationshipProfile: The updated relationship profile
    ///   - userId: The current user's identifier
    /// - Returns: UpdateConnectionResponse indicating success or failure
    func updateConnection(
        connectionId: String,
        relationshipProfile: RelationshipProfile,
        userId: String
    ) async throws -> UpdateConnectionResponse {
        let profilePayload = UpdateConnectionRequest.ConnectionProfilePayload(
            id: connectionId,
            relationshipProfile: UpdateConnectionRequest.ConnectionProfilePayload.RelationshipProfilePayload(
                spheres: relationshipProfile.spheres.map { $0.rawValue },
                natures: relationshipProfile.natures.map { $0.rawValue },
                closeness: relationshipProfile.closeness.rawValue,
                interactionFrequency: relationshipProfile.interactionFrequency?.rawValue ?? "monthly",
                meetingContext: relationshipProfile.meetingContext ?? "",
                sharedInterests: relationshipProfile.sharedInterests,
                sharedCircles: relationshipProfile.sharedCircles
            )
        )

        let request = UpdateConnectionRequest(
            userId: userId,
            action: "update_connection",
            connectionId: connectionId,
            connectionProfile: profilePayload,
            sessionId: UUID().uuidString,
            authToken: nil
        )

        return try await performUpdateRequest(request)
    }

    /// Perform the update connection request
    private func performUpdateRequest(_ updateRequest: UpdateConnectionRequest) async throws -> UpdateConnectionResponse {
        guard let url = URL(string: baseURL) else {
            throw N8NError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Cirkl-iOS/\(DeviceInfo.current.appVersion)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30

        do {
            request.httpBody = try encoder.encode(updateRequest)
        } catch {
            throw N8NError.encodingFailed(error)
        }

        #if DEBUG
        if let body = request.httpBody, let jsonString = String(data: body, encoding: .utf8) {
            print("📤 N8N Update Connection Request: \(jsonString)")
        }
        #endif

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw N8NError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw N8NError.invalidResponse
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📥 N8N Update Connection Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif

        guard 200...299 ~= httpResponse.statusCode else {
            throw N8NError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        // Try to decode structured response, fallback to success if empty
        if data.isEmpty {
            return UpdateConnectionResponse(success: true, message: "Updated")
        }

        do {
            return try decoder.decode(UpdateConnectionResponse.self, from: data)
        } catch {
            // If decoding fails but HTTP was successful, assume success
            return UpdateConnectionResponse(success: true, message: "Updated")
        }
    }

    /// Acknowledge synergies - updates Neo4j to clear button state
    /// Call this when user has seen and responded to synergy opportunities
    func acknowledgeSynergies(userId: String) async throws {
        let acknowledgeURL = "https://gilloutmode.app.n8n.cloud/webhook/acknowledge-synergies"

        guard let url = URL(string: acknowledgeURL) else {
            throw N8NError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body = ["userId": userId]
        request.httpBody = try encoder.encode(body)

        #if DEBUG
        print("📤 Acknowledge synergies for userId: \(userId)")
        #endif

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            #if DEBUG
            print("❌ Acknowledge synergies failed")
            #endif
            throw N8NError.invalidResponse
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("✅ Acknowledge synergies response: \(jsonString)")
        }
        #endif
    }

    // MARK: - Private Methods

    private func performRequest(_ messageRequest: MessageRequest) async throws -> AssistantResponse {
        guard let url = URL(string: baseURL) else {
            throw N8NError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Cirkl-iOS/\(DeviceInfo.current.appVersion)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 60

        do {
            request.httpBody = try encoder.encode(messageRequest)
        } catch {
            throw N8NError.encodingFailed(error)
        }

        #if DEBUG
        if let body = request.httpBody, let jsonString = String(data: body, encoding: .utf8) {
            print("📤 N8N Request: \(jsonString)")
        }
        #endif

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw N8NError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw N8NError.invalidResponse
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📥 N8N Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif

        guard 200...299 ~= httpResponse.statusCode else {
            throw N8NError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        do {
            return try decoder.decode(AssistantResponse.self, from: data)
        } catch {
            throw N8NError.decodingFailed(error)
        }
    }
}

// MARK: - Error Types

enum N8NError: LocalizedError, Sendable {
    case invalidURL
    case encodingFailed(Error)
    case networkError(Error)
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingFailed(Error)
    case authenticationFailed
    case messageSendFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid N8N webhook URL"
        case .encodingFailed(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, let data):
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            return "HTTP error \(statusCode): \(message)"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .authenticationFailed:
            return "Authentication with N8N failed"
        case .messageSendFailed:
            return "Failed to send message to N8N"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkError, .httpError(statusCode: 500...599, _):
            return true
        default:
            return false
        }
    }
}

// MARK: - Convenience Extensions

extension N8NService.AssistantResponse {
    /// The detected intent from the AI
    var detectedIntent: CirklIntent? {
        guard let intent = intent else { return nil }
        return CirklIntent(rawValue: intent)
    }

    /// Whether this response indicates a new connection was created
    var createdNewConnection: Bool {
        metadata?.hasNewConnection ?? false
    }
}

/// Known intents from the Cirkl AI
enum CirklIntent: String, Sendable {
    case newConnection = "new_connection"
    case memorySearch = "memory_search"
    case analyticsReport = "analytics_report"
    case opportunityMatch = "opportunity_match"
    case generalChat = "general_chat"
}

// MARK: - Button State API (Living Button)

/// Button state types from API
enum AIButtonState: String, Codable, Sendable {
    case idle
    case synergy
    case opportunity
    case newConnection = "new_connection"
}

/// Response from button-state endpoint
struct ButtonStateResponse: Decodable, Sendable {
    let success: Bool
    let buttonState: AIButtonState
    let synergiesCount: Int
    let synergies: [SynergyInfo]
    let timestamp: String

    struct SynergyInfo: Decodable, Sendable, Equatable {
        let id: String?
        let type: String?
        let description: String?
    }
}

extension N8NService {

    // MARK: - Button State Polling

    private static let buttonStateBaseURL = "https://gilloutmode.app.n8n.cloud/webhook/button-state"

    /// Fetch current button state for a user
    /// - Parameter userId: The user's identifier
    /// - Returns: ButtonStateResponse with current state
    func fetchButtonState(userId: String) async throws -> ButtonStateResponse {
        guard var urlComponents = URLComponents(string: Self.buttonStateBaseURL) else {
            throw N8NError.invalidURL
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "userId", value: userId)
        ]

        guard let url = urlComponents.url else {
            throw N8NError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Cirkl-iOS/\(DeviceInfo.current.appVersion)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 5 // 5 second timeout as specified

        #if DEBUG
        print("🔘 Button State Request: \(url.absoluteString)")
        #endif

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw N8NError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw N8NError.invalidResponse
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🔘 Button State Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif

        guard 200...299 ~= httpResponse.statusCode else {
            throw N8NError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        do {
            return try decoder.decode(ButtonStateResponse.self, from: data)
        } catch {
            throw N8NError.decodingFailed(error)
        }
    }
}
