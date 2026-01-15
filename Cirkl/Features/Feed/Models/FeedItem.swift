import Foundation
import SwiftUI

// MARK: - Feed Item Model
/// Représente un élément du feed d'actualités réseau

struct FeedItem: Identifiable, Equatable {
    let id: String
    let type: FeedItemType
    let title: String
    let message: String
    let timestamp: Date
    let connectionName: String?
    let connectionRole: String?
    let connectionId: String?
    var isRead: Bool

    // MARK: - Computed Properties

    var relativeTimestamp: String {
        let now = Date()
        let components = Calendar.current.dateComponents(
            [.minute, .hour, .day, .weekOfYear],
            from: timestamp,
            to: now
        )

        if let weeks = components.weekOfYear, weeks >= 1 {
            return weeks == 1 ? "Il y a 1 semaine" : "Il y a \(weeks) semaines"
        }
        if let days = components.day, days >= 1 {
            if days == 1 { return "Hier" }
            return "Il y a \(days) jours"
        }
        if let hours = components.hour, hours >= 1 {
            return hours == 1 ? "Il y a 1h" : "Il y a \(hours)h"
        }
        if let minutes = components.minute, minutes >= 1 {
            return minutes == 1 ? "Il y a 1 min" : "Il y a \(minutes) min"
        }
        return "À l'instant"
    }

    var icon: String {
        type.icon
    }

    var accentColor: Color {
        type.color
    }
}

// MARK: - Feed Item Type

enum FeedItemType: String, CaseIterable, Equatable {
    case update = "update"
    case synergy = "synergy"
    case networkPulse = "network_pulse"

    var icon: String {
        switch self {
        case .update: return "megaphone.fill"
        case .synergy: return "sparkles"
        case .networkPulse: return "heart.text.square.fill"
        }
    }

    var emoji: String {
        switch self {
        case .update: return "📢"
        case .synergy: return "🔮"
        case .networkPulse: return "💓"
        }
    }

    var color: Color {
        switch self {
        case .update: return DesignTokens.Colors.electricBlue
        case .synergy: return DesignTokens.Colors.purple
        case .networkPulse: return DesignTokens.Colors.warning
        }
    }

    var displayName: String {
        switch self {
        case .update: return "Updates"
        case .synergy: return "Synergies"
        case .networkPulse: return "Rappels"
        }
    }
}

// MARK: - Feed Filter

enum FeedFilter: String, CaseIterable {
    case all = "Tous"
    case updates = "Updates"
    case synergies = "Synergies"
    case reminders = "Rappels"

    var matchingTypes: [FeedItemType] {
        switch self {
        case .all: return FeedItemType.allCases
        case .updates: return [.update]
        case .synergies: return [.synergy]
        case .reminders: return [.networkPulse]
        }
    }
}

// MARK: - Mock Data

extension FeedItem {
    static let mockItems: [FeedItem] = [
        FeedItem(
            id: "1",
            type: .update,
            title: "Changement de poste",
            message: "Denis vient de devenir Lead Designer chez Apple",
            timestamp: Date().addingTimeInterval(-3600), // 1h ago
            connectionName: "Denis Martin",
            connectionRole: "Lead Designer @ Apple",
            connectionId: "denis",
            isRead: false
        ),
        FeedItem(
            id: "2",
            type: .synergy,
            title: "Synergie détectée",
            message: "Sarah et Marc travaillent tous les deux sur l'IA générative. Tu pourrais les connecter !",
            timestamp: Date().addingTimeInterval(-7200), // 2h ago
            connectionName: nil,
            connectionRole: nil,
            connectionId: nil,
            isRead: false
        ),
        FeedItem(
            id: "3",
            type: .networkPulse,
            title: "Connexion dormante",
            message: "Tu n'as pas échangé avec Judith depuis 3 semaines",
            timestamp: Date().addingTimeInterval(-86400), // 1 day ago
            connectionName: "Judith Chen",
            connectionRole: "Product Manager @ BigTech",
            connectionId: "judith",
            isRead: true
        ),
        FeedItem(
            id: "4",
            type: .update,
            title: "Nouvelle entreprise",
            message: "Shay a lancé sa startup TechFlow en mode stealth",
            timestamp: Date().addingTimeInterval(-172800), // 2 days ago
            connectionName: "Shay Cohen",
            connectionRole: "Founder @ TechFlow",
            connectionId: "shay",
            isRead: true
        ),
        FeedItem(
            id: "5",
            type: .synergy,
            title: "Opportunité business",
            message: "3 de tes connexions cherchent un expert iOS cette semaine",
            timestamp: Date().addingTimeInterval(-259200), // 3 days ago
            connectionName: nil,
            connectionRole: nil,
            connectionId: nil,
            isRead: true
        ),
        FeedItem(
            id: "6",
            type: .networkPulse,
            title: "Connexion à risque",
            message: "Dan s'éloigne de ton réseau - 45 jours sans contact",
            timestamp: Date().addingTimeInterval(-345600), // 4 days ago
            connectionName: "Dan Levy",
            connectionRole: "Entrepreneur @ StartupX",
            connectionId: "dan",
            isRead: false
        ),
        FeedItem(
            id: "7",
            type: .update,
            title: "Anniversaire professionnel",
            message: "Ça fait 1 an que tu connais Gilles ! Votre collaboration a généré 47K€",
            timestamp: Date().addingTimeInterval(-432000), // 5 days ago
            connectionName: "Gilles Dupont",
            connectionRole: "Consultant @ Advisory Co",
            connectionId: "gilles",
            isRead: true
        )
    ]
}
