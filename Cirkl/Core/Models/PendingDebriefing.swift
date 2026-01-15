//
//  PendingDebriefing.swift
//  Cirkl
//
//  Created by Claude on 15/01/2026.
//

import Foundation

// MARK: - Pending Debriefing

/// Représente un debriefing en attente après une connexion IRL
struct PendingDebriefing: Identifiable, Codable, Sendable {
    let id: UUID
    let connectionId: String
    let connectionName: String
    let connectionAvatarURL: URL?
    let connectedAt: Date
    var reminderSentAt: Date?
    let publicProfile: ConnectionPublicProfile

    init(
        id: UUID = UUID(),
        connectionId: String,
        connectionName: String,
        connectionAvatarURL: URL? = nil,
        connectedAt: Date = Date(),
        reminderSentAt: Date? = nil,
        publicProfile: ConnectionPublicProfile
    ) {
        self.id = id
        self.connectionId = connectionId
        self.connectionName = connectionName
        self.connectionAvatarURL = connectionAvatarURL
        self.connectedAt = connectedAt
        self.reminderSentAt = reminderSentAt
        self.publicProfile = publicProfile
    }

    // MARK: - Computed Properties

    /// Délai depuis la connexion (pour calcul expiration)
    var hoursSinceConnection: Double {
        Date().timeIntervalSince(connectedAt) / 3600
    }

    /// True si le rappel devrait être envoyé (après 4h)
    var shouldSendReminder: Bool {
        guard reminderSentAt == nil else { return false }
        return hoursSinceConnection >= 4
    }

    /// True si le debriefing a expiré (après 48h)
    var isExpired: Bool {
        hoursSinceConnection >= 48
    }

    /// Temps restant avant expiration (en heures)
    var hoursUntilExpiration: Double {
        max(0, 48 - hoursSinceConnection)
    }

    /// Texte de temps restant formaté
    var expirationText: String {
        let hours = hoursUntilExpiration
        if hours > 24 {
            return "Expire dans \(Int(hours / 24))j"
        } else if hours > 1 {
            return "Expire dans \(Int(hours))h"
        } else if hours > 0 {
            return "Expire bientôt !"
        }
        return "Expiré"
    }
}

// MARK: - Connection Public Profile

/// Profil public d'une connexion (infos révélables lors du debriefing)
struct ConnectionPublicProfile: Codable, Sendable {
    let name: String
    let role: String?
    let company: String?
    let industry: String?
    let bio: String?
    let tags: [String]
    let sharedInterests: [String]
    let mutualConnectionsCount: Int
    let mutualConnectionNames: [String]
    let meetingPlace: String?
    let connectionType: String?

    init(
        name: String,
        role: String? = nil,
        company: String? = nil,
        industry: String? = nil,
        bio: String? = nil,
        tags: [String] = [],
        sharedInterests: [String] = [],
        mutualConnectionsCount: Int = 0,
        mutualConnectionNames: [String] = [],
        meetingPlace: String? = nil,
        connectionType: String? = nil
    ) {
        self.name = name
        self.role = role
        self.company = company
        self.industry = industry
        self.bio = bio
        self.tags = tags
        self.sharedInterests = sharedInterests
        self.mutualConnectionsCount = mutualConnectionsCount
        self.mutualConnectionNames = mutualConnectionNames
        self.meetingPlace = meetingPlace
        self.connectionType = connectionType
    }

    /// Génère un résumé du profil pour l'IA
    var summary: String {
        var parts: [String] = []

        if let role = role, let company = company {
            parts.append("\(role) chez \(company)")
        } else if let role = role {
            parts.append(role)
        } else if let company = company {
            parts.append("travaille chez \(company)")
        }

        if let industry = industry {
            parts.append("dans le secteur \(industry)")
        }

        if !tags.isEmpty {
            parts.append("passionné(e) par \(tags.prefix(3).joined(separator: ", "))")
        }

        if mutualConnectionsCount > 0 {
            parts.append("\(mutualConnectionsCount) connexion(s) en commun")
        }

        return parts.isEmpty ? name : "\(name) - \(parts.joined(separator: ", "))"
    }

    /// Nombre de points communs (pour décider template vs IA)
    var commonPointsCount: Int {
        var count = 0
        if mutualConnectionsCount > 0 { count += mutualConnectionsCount }
        count += sharedInterests.count
        if meetingPlace != nil { count += 1 }
        return count
    }
}

// MARK: - Debriefing Result

/// Résultat d'un debriefing complété
struct DebriefingResult: Codable, Sendable {
    let debriefingId: UUID
    let connectionId: String
    let completedAt: Date
    let userFeedback: String
    let extractedTags: [String]
    let extractedInterests: [String]
    let relationshipType: String?
    let notes: String?
    let sentiment: DebriefingSentiment

    enum DebriefingSentiment: String, Codable {
        case positive
        case neutral
        case negative
    }
}
