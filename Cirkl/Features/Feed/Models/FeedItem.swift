import Foundation
import SwiftUI

// MARK: - Feed Item Model
/// Représente un élément du feed d'actualités réseau
/// Chaque type a ses propres champs spécifiques

struct FeedItem: Identifiable, Equatable {
    let id: String
    let type: FeedItemType
    let timestamp: Date
    var isRead: Bool

    // MARK: - Champs communs à tous les types

    /// Nom de la connexion principale concernée (var pour permettre la synchronisation avec ProfileDetailView)
    var connectionName: String?

    /// URL de l'avatar de la connexion
    let connectionAvatar: URL?

    /// Contexte relationnel avec l'utilisateur
    /// Ex: "Ton mentor", "Rencontré à Station F", "Ton ancien collaborateur"
    let contextWithUser: String?

    /// ID de la connexion pour navigation
    let connectionId: String?

    // MARK: - Champs spécifiques à Update (📢)

    /// Contenu de la mise à jour
    /// Ex: "Est maintenant CTO @ Stripe"
    let updateContent: String?

    // MARK: - Champs spécifiques à Synergy (🔮)

    /// Première personne de la synergie
    /// Ex: "Sarah cherche un appart"
    let synergyPerson1: String?

    /// Nom de la première personne
    let synergyPerson1Name: String?

    /// Deuxième personne de la synergie
    /// Ex: "Dan est agent immobilier"
    let synergyPerson2: String?

    /// Nom de la deuxième personne
    let synergyPerson2Name: String?

    /// Point de match de la synergie
    /// Ex: "à Netanya"
    let synergyMatch: String?

    // MARK: - Champs spécifiques à Network Pulse (💓)

    /// Statut pulse de la connexion
    let pulseStatus: PulseStatus?

    /// Nombre de jours depuis le dernier contact
    let daysSinceContact: Int?

    /// Contexte de la dernière interaction
    /// Ex: "Café @ WeWork République"
    let lastInteractionContext: String?

    // MARK: - Champs spécifiques à Incoming Synergy (🤝)

    /// Nom de l'introducteur
    /// Ex: "Gil Toobool"
    let introducerName: String?

    /// ID de l'introducteur
    let introducerId: String?

    /// Nom de la personne présentée
    /// Ex: "Dan Levy"
    let introducedPersonName: String?

    /// Rôle/métier de la personne présentée
    /// Ex: "Agent immobilier"
    let introducedPersonRole: String?

    /// Localisation de la personne présentée
    /// Ex: "Tel Aviv"
    let introducedPersonLocation: String?

    /// Message d'introduction
    /// Ex: "Dan pourrait t'aider à trouver un appartement"
    let introductionMessage: String?

    /// ID de la requête de synergie pour accept/decline
    let synergyRequestId: String?

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

// MARK: - Pulse Status

enum PulseStatus: String, Equatable {
    case active = "active"
    case dormant = "dormant"
    case atRisk = "at_risk"

    var color: Color {
        switch self {
        case .active: return DesignTokens.Colors.success
        case .dormant: return DesignTokens.Colors.warning
        case .atRisk: return DesignTokens.Colors.error
        }
    }

    var emoji: String {
        switch self {
        case .active: return "🟢"
        case .dormant: return "🟡"
        case .atRisk: return "🔴"
        }
    }

    var label: String {
        switch self {
        case .active: return "Actif"
        case .dormant: return "Dormant"
        case .atRisk: return "À risque"
        }
    }
}

// MARK: - Feed Item Type

enum FeedItemType: String, CaseIterable, Equatable {
    case update = "update"
    case synergy = "synergy"
    case networkPulse = "network_pulse"
    case incomingSynergy = "incoming_synergy"

    var icon: String {
        switch self {
        case .update: return "megaphone.fill"
        case .synergy: return "sparkles"
        case .networkPulse: return "heart.text.square.fill"
        case .incomingSynergy: return "person.2.fill"
        }
    }

    var emoji: String {
        switch self {
        case .update: return "📢"
        case .synergy: return "🔮"
        case .networkPulse: return "💓"
        case .incomingSynergy: return "🤝"
        }
    }

    var color: Color {
        switch self {
        case .update: return DesignTokens.Colors.electricBlue
        case .synergy: return DesignTokens.Colors.purple
        case .networkPulse: return DesignTokens.Colors.warning
        case .incomingSynergy: return DesignTokens.Colors.success
        }
    }

    var displayName: String {
        switch self {
        case .update: return "Updates"
        case .synergy: return "Synergies"
        case .networkPulse: return "Rappels"
        case .incomingSynergy: return "Mises en relation"
        }
    }
}

// MARK: - Feed Filter

enum FeedFilter: String, CaseIterable {
    case all = "Tous"
    case updates = "Updates"
    case synergies = "Synergies"
    case introductions = "Mises en relation"
    case reminders = "Rappels"

    var matchingTypes: [FeedItemType] {
        switch self {
        case .all: return FeedItemType.allCases
        case .updates: return [.update]
        case .synergies: return [.synergy]
        case .introductions: return [.incomingSynergy]
        case .reminders: return [.networkPulse]
        }
    }
}

// MARK: - Mock Data

extension FeedItem {
    static let mockItems: [FeedItem] = [
        // Incoming Synergy (🤝) - En premier pour test
        FeedItem(
            id: "0",
            type: .incomingSynergy,
            timestamp: Date().addingTimeInterval(-7200), // 2h ago
            isRead: false,
            connectionName: nil,
            connectionAvatar: nil,
            contextWithUser: nil,
            connectionId: nil,
            updateContent: nil,
            synergyPerson1: nil,
            synergyPerson1Name: nil,
            synergyPerson2: nil,
            synergyPerson2Name: nil,
            synergyMatch: nil,
            pulseStatus: nil,
            daysSinceContact: nil,
            lastInteractionContext: nil,
            introducerName: "Gil Toobool",
            introducerId: "user-gil-123",
            introducedPersonName: "Dan Levy",
            introducedPersonRole: "Agent immobilier",
            introducedPersonLocation: "Tel Aviv",
            introductionMessage: "Dan pourrait t'aider à trouver un appartement à Netanya",
            synergyRequestId: "synergy-req-456"
        ),

        // Updates (📢)
        FeedItem(
            id: "1",
            type: .update,
            timestamp: Date().addingTimeInterval(-7200), // 2h ago
            isRead: false,
            connectionName: "Marc Dubois",
            connectionAvatar: nil,
            contextWithUser: "Ton ancien collaborateur @ StartupX",
            connectionId: "marc",
            updateContent: "Est maintenant CTO @ Stripe",
            synergyPerson1: nil,
            synergyPerson1Name: nil,
            synergyPerson2: nil,
            synergyPerson2Name: nil,
            synergyMatch: nil,
            pulseStatus: nil,
            daysSinceContact: nil,
            lastInteractionContext: nil,
            introducerName: nil,
            introducerId: nil,
            introducedPersonName: nil,
            introducedPersonRole: nil,
            introducedPersonLocation: nil,
            introductionMessage: nil,
            synergyRequestId: nil
        ),
        FeedItem(
            id: "2",
            type: .update,
            timestamp: Date().addingTimeInterval(-172800), // 2 days ago
            isRead: true,
            connectionName: "Shay Cohen",
            connectionAvatar: nil,
            contextWithUser: "Rencontré à Station F en 2023",
            connectionId: "shay",
            updateContent: "A lancé sa startup TechFlow en mode stealth",
            synergyPerson1: nil,
            synergyPerson1Name: nil,
            synergyPerson2: nil,
            synergyPerson2Name: nil,
            synergyMatch: nil,
            pulseStatus: nil,
            daysSinceContact: nil,
            lastInteractionContext: nil,
            introducerName: nil,
            introducerId: nil,
            introducedPersonName: nil,
            introducedPersonRole: nil,
            introducedPersonLocation: nil,
            introductionMessage: nil,
            synergyRequestId: nil
        ),
        FeedItem(
            id: "3",
            type: .update,
            timestamp: Date().addingTimeInterval(-432000), // 5 days ago
            isRead: true,
            connectionName: "Gilles Dupont",
            connectionAvatar: nil,
            contextWithUser: "Ton partenaire business depuis 1 an",
            connectionId: "gilles",
            updateContent: "Anniversaire : 1 an de collaboration ! 47K€ générés ensemble",
            synergyPerson1: nil,
            synergyPerson1Name: nil,
            synergyPerson2: nil,
            synergyPerson2Name: nil,
            synergyMatch: nil,
            pulseStatus: nil,
            daysSinceContact: nil,
            lastInteractionContext: nil,
            introducerName: nil,
            introducerId: nil,
            introducedPersonName: nil,
            introducedPersonRole: nil,
            introducedPersonLocation: nil,
            introductionMessage: nil,
            synergyRequestId: nil
        ),

        // Synergies (🔮)
        FeedItem(
            id: "4",
            type: .synergy,
            timestamp: Date().addingTimeInterval(-3600), // 1h ago
            isRead: false,
            connectionName: nil,
            connectionAvatar: nil,
            contextWithUser: nil,
            connectionId: nil,
            updateContent: nil,
            synergyPerson1: "cherche un appartement",
            synergyPerson1Name: "Sarah Martinez",
            synergyPerson2: "est agent immobilier",
            synergyPerson2Name: "Dan Levy",
            synergyMatch: "à Netanya",
            pulseStatus: nil,
            daysSinceContact: nil,
            lastInteractionContext: nil,
            introducerName: nil,
            introducerId: nil,
            introducedPersonName: nil,
            introducedPersonRole: nil,
            introducedPersonLocation: nil,
            introductionMessage: nil,
            synergyRequestId: nil
        ),
        FeedItem(
            id: "5",
            type: .synergy,
            timestamp: Date().addingTimeInterval(-259200), // 3 days ago
            isRead: true,
            connectionName: nil,
            connectionAvatar: nil,
            contextWithUser: nil,
            connectionId: nil,
            updateContent: nil,
            synergyPerson1: "cherche un expert iOS",
            synergyPerson1Name: "Lisa Chen",
            synergyPerson2: "est développeur iOS senior",
            synergyPerson2Name: "Thomas Bernard",
            synergyMatch: "freelance disponible",
            pulseStatus: nil,
            daysSinceContact: nil,
            lastInteractionContext: nil,
            introducerName: nil,
            introducerId: nil,
            introducedPersonName: nil,
            introducedPersonRole: nil,
            introducedPersonLocation: nil,
            introductionMessage: nil,
            synergyRequestId: nil
        ),

        // Network Pulse (💓)
        FeedItem(
            id: "6",
            type: .networkPulse,
            timestamp: Date().addingTimeInterval(-86400), // 1 day ago
            isRead: false,
            connectionName: "Judith Chen",
            connectionAvatar: nil,
            contextWithUser: "Ta mentor product",
            connectionId: "judith",
            updateContent: nil,
            synergyPerson1: nil,
            synergyPerson1Name: nil,
            synergyPerson2: nil,
            synergyPerson2Name: nil,
            synergyMatch: nil,
            pulseStatus: .dormant,
            daysSinceContact: 21,
            lastInteractionContext: "Café @ WeWork République",
            introducerName: nil,
            introducerId: nil,
            introducedPersonName: nil,
            introducedPersonRole: nil,
            introducedPersonLocation: nil,
            introductionMessage: nil,
            synergyRequestId: nil
        ),
        FeedItem(
            id: "7",
            type: .networkPulse,
            timestamp: Date().addingTimeInterval(-345600), // 4 days ago
            isRead: false,
            connectionName: "Dan Levy",
            connectionAvatar: nil,
            contextWithUser: "Ton ami entrepreneur",
            connectionId: "dan",
            updateContent: nil,
            synergyPerson1: nil,
            synergyPerson1Name: nil,
            synergyPerson2: nil,
            synergyPerson2Name: nil,
            synergyMatch: nil,
            pulseStatus: .atRisk,
            daysSinceContact: 45,
            lastInteractionContext: "Déjeuner business @ La Felicità",
            introducerName: nil,
            introducerId: nil,
            introducedPersonName: nil,
            introducedPersonRole: nil,
            introducedPersonLocation: nil,
            introductionMessage: nil,
            synergyRequestId: nil
        ),
        FeedItem(
            id: "8",
            type: .networkPulse,
            timestamp: Date().addingTimeInterval(-604800), // 7 days ago
            isRead: true,
            connectionName: "Marie Laurent",
            connectionAvatar: nil,
            contextWithUser: "Rencontrée via Denis",
            connectionId: "marie",
            updateContent: nil,
            synergyPerson1: nil,
            synergyPerson1Name: nil,
            synergyPerson2: nil,
            synergyPerson2Name: nil,
            synergyMatch: nil,
            pulseStatus: .dormant,
            daysSinceContact: 18,
            lastInteractionContext: "Event networking @ 42",
            introducerName: nil,
            introducerId: nil,
            introducedPersonName: nil,
            introducedPersonRole: nil,
            introducedPersonLocation: nil,
            introductionMessage: nil,
            synergyRequestId: nil
        )
    ]
}
