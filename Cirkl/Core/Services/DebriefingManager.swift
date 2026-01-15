//
//  DebriefingManager.swift
//  Cirkl
//
//  Created by Claude on 15/01/2026.
//

import Foundation
import SwiftUI
import UserNotifications

// MARK: - Debriefing Manager

/// Gestionnaire des debriefings post-connexion
/// Stocke les debriefings en attente, gère les rappels et expirations
@MainActor
@Observable
final class DebriefingManager {

    // MARK: - Singleton

    static let shared = DebriefingManager()

    // MARK: - Published State

    private(set) var pendingDebriefings: [PendingDebriefing] = []
    private(set) var detectedSynergies: [DetectedSynergy] = []

    // MARK: - Computed Properties

    /// Nombre de debriefings en attente
    var pendingCount: Int {
        pendingDebriefings.count
    }

    /// Nombre de synergies hautes priorité (>60%)
    var highSynergyCount: Int {
        detectedSynergies.filter { $0.isHighPriority && !$0.isActedUpon }.count
    }

    /// Nombre de synergies basses priorité (30-60%)
    var lowSynergyCount: Int {
        detectedSynergies.filter { $0.isLowPriority && !$0.isActedUpon }.count
    }

    /// État actuel du bouton AI basé sur les debriefings et synergies
    var currentState: AIAssistantState {
        AIAssistantState.resolve(
            pendingDebriefings: pendingCount,
            highSynergies: highSynergyCount,
            lowSynergies: lowSynergyCount,
            hasMorningBrief: MorningBriefManager.shared.hasPendingBrief
        )
    }

    /// Badge count à afficher
    var badgeCount: Int {
        switch currentState {
        case .idle, .morningBrief:
            return 0  // Morning brief n'a pas de badge count
        case .debriefing:
            return pendingCount
        case .synergyLow, .synergyHigh:
            return highSynergyCount + lowSynergyCount
        }
    }

    /// Le prochain debriefing à traiter (le plus ancien)
    var nextDebriefing: PendingDebriefing? {
        pendingDebriefings.first
    }

    // MARK: - Storage Keys

    private let debriefingsKey = "pendingDebriefings"
    private let synergiesKey = "detectedSynergies"

    // MARK: - Init

    private init() {
        loadFromStorage()
        scheduleExpirationCheck()
    }

    // MARK: - Debriefing Management

    /// Ajoute un nouveau debriefing après une connexion IRL
    func addDebriefing(
        connectionId: String,
        connectionName: String,
        connectionAvatarURL: URL? = nil,
        publicProfile: ConnectionPublicProfile
    ) {
        let debriefing = PendingDebriefing(
            connectionId: connectionId,
            connectionName: connectionName,
            connectionAvatarURL: connectionAvatarURL,
            publicProfile: publicProfile
        )

        pendingDebriefings.append(debriefing)
        saveToStorage()

        // Programmer le rappel dans 4h
        scheduleReminder(for: debriefing)

        #if DEBUG
        print("📝 Debriefing ajouté pour \(connectionName) - Total: \(pendingCount)")
        #endif
    }

    /// Marque un debriefing comme complété
    func completeDebriefing(id: UUID) {
        pendingDebriefings.removeAll { $0.id == id }
        saveToStorage()

        #if DEBUG
        print("✅ Debriefing complété - Restants: \(pendingCount)")
        #endif
    }

    /// Marque un debriefing comme expiré (sans le supprimer de la connexion)
    func expireDebriefing(id: UUID) {
        if let index = pendingDebriefings.firstIndex(where: { $0.id == id }) {
            let debriefing = pendingDebriefings[index]
            pendingDebriefings.remove(at: index)
            saveToStorage()

            #if DEBUG
            print("⏰ Debriefing expiré pour \(debriefing.connectionName)")
            #endif

            // TODO: Marquer la connexion comme "debriefing manqué" dans Neo4j
        }
    }

    // MARK: - Synergy Management

    /// Ajoute une synergie détectée
    func addSynergy(_ synergy: DetectedSynergy) {
        // Éviter les doublons
        guard !detectedSynergies.contains(where: {
            $0.connectionAId == synergy.connectionAId &&
            $0.connectionBId == synergy.connectionBId &&
            $0.synergyType == synergy.synergyType
        }) else { return }

        detectedSynergies.append(synergy)
        saveToStorage()

        #if DEBUG
        print("🔗 Synergie détectée: \(synergy.synergyType.displayName) entre \(synergy.connectionAName) et \(synergy.connectionBName)")
        #endif
    }

    /// Marque une synergie comme traitée
    func markSynergyActedUpon(id: UUID) {
        if let index = detectedSynergies.firstIndex(where: { $0.id == id }) {
            detectedSynergies[index].isActedUpon = true
            saveToStorage()
        }
    }

    /// Supprime une synergie
    func removeSynergy(id: UUID) {
        detectedSynergies.removeAll { $0.id == id }
        saveToStorage()
    }

    /// Efface toutes les synergies traitées
    func clearActedSynergies() {
        detectedSynergies.removeAll { $0.isActedUpon }
        saveToStorage()
    }

    // MARK: - Reminders & Expiration

    private func scheduleReminder(for debriefing: PendingDebriefing) {
        let content = UNMutableNotificationContent()
        content.title = "Debriefing en attente"
        content.body = "Tu as rencontré \(debriefing.connectionName) il y a 4h. Raconte-moi comment ça s'est passé !"
        content.sound = .default
        content.userInfo = ["debriefingId": debriefing.id.uuidString]

        // Trigger dans 4 heures
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 4 * 3600, repeats: false)

        let request = UNNotificationRequest(
            identifier: "debriefing-reminder-\(debriefing.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule reminder: \(error)")
            }
        }
    }

    private func scheduleExpirationCheck() {
        // Vérifier toutes les heures
        Task {
            while true {
                try? await Task.sleep(for: .seconds(3600))
                await checkExpirations()
            }
        }
    }

    private func checkExpirations() async {
        let expiredIds = pendingDebriefings.filter { $0.isExpired }.map { $0.id }

        for id in expiredIds {
            expireDebriefing(id: id)
        }

        // Mettre à jour les rappels envoyés
        for (index, debriefing) in pendingDebriefings.enumerated() {
            if debriefing.shouldSendReminder {
                pendingDebriefings[index].reminderSentAt = Date()
            }
        }

        saveToStorage()
    }

    // MARK: - Persistence

    private func loadFromStorage() {
        // Load debriefings
        if let data = UserDefaults.standard.data(forKey: debriefingsKey),
           let decoded = try? JSONDecoder().decode([PendingDebriefing].self, from: data) {
            pendingDebriefings = decoded.filter { !$0.isExpired }
        }

        // Load synergies
        if let data = UserDefaults.standard.data(forKey: synergiesKey),
           let decoded = try? JSONDecoder().decode([DetectedSynergy].self, from: data) {
            detectedSynergies = decoded
        }
    }

    private func saveToStorage() {
        // Save debriefings
        if let encoded = try? JSONEncoder().encode(pendingDebriefings) {
            UserDefaults.standard.set(encoded, forKey: debriefingsKey)
        }

        // Save synergies
        if let encoded = try? JSONEncoder().encode(detectedSynergies) {
            UserDefaults.standard.set(encoded, forKey: synergiesKey)
        }
    }

    // MARK: - Debug Helpers

    #if DEBUG
    /// Ajoute un debriefing de test
    func addTestDebriefing() {
        let profile = ConnectionPublicProfile(
            name: "Sarah Martin",
            role: "CEO",
            company: "TechStart",
            industry: "Tech",
            tags: ["AI", "Startup", "Innovation"],
            mutualConnectionsCount: 3,
            mutualConnectionNames: ["Marc", "Julie", "Denis"]
        )

        addDebriefing(
            connectionId: UUID().uuidString,
            connectionName: "Sarah Martin",
            publicProfile: profile
        )
    }

    /// Ajoute une synergie de test
    func addTestSynergy() {
        let synergy = DetectedSynergy(
            connectionAId: "vc-123",
            connectionAName: "Pierre Durand",
            connectionBId: "startup-456",
            connectionBName: "Sarah Martin",
            synergyType: .vcStartup,
            score: 0.75,
            reason: "Pierre est VC chez Sequoia, Sarah cherche à lever 2M€ pour TechStart"
        )

        addSynergy(synergy)
    }

    /// Reset tout pour les tests
    func resetAll() {
        pendingDebriefings = []
        detectedSynergies = []
        saveToStorage()
    }
    #endif
}

// MARK: - Notification Names

extension Notification.Name {
    static let debriefingStateChanged = Notification.Name("debriefingStateChanged")
    static let synergyDetected = Notification.Name("synergyDetected")
}
