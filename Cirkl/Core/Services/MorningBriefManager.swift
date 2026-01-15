//
//  MorningBriefManager.swift
//  Cirkl
//
//  Created by Claude on 15/01/2026.
//

import Foundation
import SwiftUI
import UserNotifications

// MARK: - Morning Brief Model

/// Contenu du brief matinal personnalisé
struct MorningBrief: Codable, Sendable {
    let briefText: String
    let highlights: [BriefHighlight]
    let stats: BriefStats
    let actionItems: [BriefActionItem]
    let generatedAt: Date

    struct BriefHighlight: Codable, Sendable, Identifiable {
        var id: String { title }
        let type: HighlightType
        let title: String
        let description: String
        let connectionId: String?
        let connectionName: String?

        enum HighlightType: String, Codable, Sendable {
            case jobChange = "job_change"
            case newMutual = "new_mutual"
            case synergy = "synergy"
            case opportunity = "opportunity"
            case anniversary = "anniversary"
            case dormant = "dormant"
        }
    }

    struct BriefStats: Codable, Sendable {
        let synchronicityScore: Int
        let scoreChange: Int
        let rank: String
        let activeConnections: Int
        let dormantConnections: Int
    }

    struct BriefActionItem: Codable, Sendable, Identifiable {
        var id: String { title }
        let title: String
        let description: String
        let priority: Priority
        let connectionId: String?

        enum Priority: String, Codable, Sendable {
            case high
            case medium
            case low
        }
    }
}

// MARK: - Morning Brief Manager

/// Gestionnaire du brief matinal quotidien
/// Gère le fetch, stockage et état de lecture du brief du jour
@MainActor
@Observable
final class MorningBriefManager {

    // MARK: - Singleton

    static let shared = MorningBriefManager()

    // MARK: - State

    private(set) var currentBrief: MorningBrief?
    private(set) var isLoading = false
    private(set) var lastError: Error?

    // MARK: - Storage

    @ObservationIgnored
    @AppStorage("lastBriefDate") private var lastBriefDateString: String = ""

    @ObservationIgnored
    @AppStorage("morningBriefHour") private var preferredHour: Int = 8

    private let briefStorageKey = "currentMorningBrief"

    // MARK: - Computed Properties

    /// Date du dernier brief lu au format yyyy-MM-dd
    private var lastBriefDate: Date? {
        guard !lastBriefDateString.isEmpty else { return nil }
        return Self.dateFormatter.date(from: lastBriefDateString)
    }

    /// Indique si un brief est disponible et non lu pour aujourd'hui
    var hasPendingBrief: Bool {
        let today = Self.dateFormatter.string(from: Date())
        return lastBriefDateString != today
    }

    /// Indique si on est dans la fenêtre horaire du morning brief (6h-12h)
    var isInMorningWindow: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 6 && hour < 12
    }

    /// Indique si le brief devrait être affiché (pending + dans la fenêtre OU brief non lu de la veille)
    var shouldShowBrief: Bool {
        hasPendingBrief
    }

    // MARK: - Date Formatter

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter
    }()

    // MARK: - Init

    private init() {
        loadStoredBrief()
    }

    // MARK: - Public Methods

    /// Fetch le brief matinal depuis N8N
    /// - Parameter userId: L'identifiant de l'utilisateur
    /// - Returns: Le MorningBrief ou nil en cas d'erreur
    @discardableResult
    func fetchBrief(userId: String) async -> MorningBrief? {
        isLoading = true
        lastError = nil

        defer { isLoading = false }

        do {
            let brief = try await performFetchRequest(userId: userId)
            currentBrief = brief
            saveBriefToStorage(brief)

            #if DEBUG
            print("🌅 Morning brief fetched successfully")
            #endif

            return brief
        } catch {
            lastError = error

            #if DEBUG
            print("❌ Morning brief fetch failed: \(error.localizedDescription)")
            #endif

            return nil
        }
    }

    /// Marque le brief comme lu
    func markBriefAsRead() {
        let today = Self.dateFormatter.string(from: Date())
        lastBriefDateString = today

        #if DEBUG
        print("✅ Morning brief marked as read for \(today)")
        #endif
    }

    /// Configure l'heure préférée pour le brief (notification push)
    func setPreferredHour(_ hour: Int) {
        guard hour >= 0 && hour <= 23 else { return }
        preferredHour = hour
        scheduleDailyNotification()
    }

    /// Programme la notification quotidienne pour le brief
    func scheduleDailyNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Brief du matin"
        content.body = "Ton réseau a respiré cette nuit. Découvre ce qui a changé !"
        content.sound = .default
        content.categoryIdentifier = "MORNING_BRIEF"

        var dateComponents = DateComponents()
        dateComponents.hour = preferredHour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "morning-brief-daily",
            content: content,
            trigger: trigger
        )

        // Remove existing and add new
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["morning-brief-daily"]
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule morning brief notification: \(error)")
            } else {
                #if DEBUG
                print("🔔 Morning brief notification scheduled for \(self.preferredHour):00")
                #endif
            }
        }
    }

    // MARK: - Private Methods

    private func performFetchRequest(userId: String) async throws -> MorningBrief {
        let urlString = "https://gilloutmode.app.n8n.cloud/webhook/morning-brief"

        guard let url = URL(string: urlString) else {
            throw MorningBriefError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Cirkl-iOS", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30

        let body = ["userId": userId]
        request.httpBody = try JSONEncoder().encode(body)

        #if DEBUG
        print("🌅 Fetching morning brief for userId: \(userId)")
        #endif

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MorningBriefError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw MorningBriefError.httpError(statusCode: httpResponse.statusCode)
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🌅 Morning brief response: \(jsonString.prefix(500))...")
        }
        #endif

        // Configure decoder with ISO8601 date strategy for N8N responses
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(MorningBrief.self, from: data)
    }

    private func loadStoredBrief() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let data = UserDefaults.standard.data(forKey: briefStorageKey),
              let brief = try? decoder.decode(MorningBrief.self, from: data) else {
            return
        }

        // Only load if brief is from today
        let briefDate = Self.dateFormatter.string(from: brief.generatedAt)
        let today = Self.dateFormatter.string(from: Date())

        if briefDate == today {
            currentBrief = brief
        }
    }

    private func saveBriefToStorage(_ brief: MorningBrief) {
        if let encoded = try? JSONEncoder().encode(brief) {
            UserDefaults.standard.set(encoded, forKey: briefStorageKey)
        }
    }

    // MARK: - Debug Helpers

    #if DEBUG
    /// Crée un brief de test
    func createTestBrief() -> MorningBrief {
        MorningBrief(
            briefText: """
            Bonjour Gil ! 🌅 Ton réseau a bougé cette nuit.

            Marc Dubois vient de changer de poste - il est maintenant CTO chez Stripe !
            2 personnes de ton réseau seront au WeWork République cet après-midi.
            Ta connexion avec Lisa Chen arrive à son 30ème jour sans contact.

            Veux-tu que j'orchestre quelque chose ?
            """,
            highlights: [
                .init(
                    type: .jobChange,
                    title: "Changement de poste",
                    description: "Marc Dubois est maintenant CTO chez Stripe",
                    connectionId: "marc-123",
                    connectionName: "Marc Dubois"
                ),
                .init(
                    type: .opportunity,
                    title: "Opportunité de rencontre",
                    description: "2 connexions au WeWork République",
                    connectionId: nil,
                    connectionName: nil
                ),
                .init(
                    type: .dormant,
                    title: "Connexion dormante",
                    description: "30 jours sans contact avec Lisa Chen",
                    connectionId: "lisa-456",
                    connectionName: "Lisa Chen"
                )
            ],
            stats: .init(
                synchronicityScore: 847,
                scoreChange: 12,
                rank: "Top 3%",
                activeConnections: 45,
                dormantConnections: 23
            ),
            actionItems: [
                .init(
                    title: "Féliciter Marc",
                    description: "Envoyer un message de félicitations pour son nouveau poste",
                    priority: .high,
                    connectionId: "marc-123"
                ),
                .init(
                    title: "Recontacter Lisa",
                    description: "Reprendre contact après 30 jours",
                    priority: .medium,
                    connectionId: "lisa-456"
                )
            ],
            generatedAt: Date()
        )
    }

    /// Simule un brief disponible pour les tests
    func simulatePendingBrief() {
        lastBriefDateString = ""
        currentBrief = createTestBrief()
    }

    /// Reset le manager pour les tests
    func reset() {
        lastBriefDateString = ""
        currentBrief = nil
        UserDefaults.standard.removeObject(forKey: briefStorageKey)
    }
    #endif
}

// MARK: - Errors

enum MorningBriefError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid morning brief URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .decodingFailed(let error):
            return "Failed to decode brief: \(error.localizedDescription)"
        }
    }
}

