//
//  AIAssistantState.swift
//  Cirkl
//
//  Created by Claude on 15/01/2026.
//

import SwiftUI
import UIKit

// MARK: - AI Assistant State

/// Les 5 états du bouton AI "vivant"
enum AIAssistantState: String, Codable, Sendable {
    case idle              // Blanc translucide - rien à signaler
    case morningBrief      // VERT MENTHE - brief matinal disponible
    case debriefing        // BLEU - debriefing(s) en attente après connexion
    case synergyLow        // JAUNE - synergie faible détectée (30-60%)
    case synergyHigh       // ROUGE - synergie forte détectée (>60%)

    // MARK: - Colors

    var color: Color {
        switch self {
        case .idle:
            return .white.opacity(0.3)  // Liquid Glass translucide
        case .morningBrief:
            return Color(red: 0, green: 0.78, blue: 0.506)  // #00C781 - Vert menthe
        case .debriefing:
            return Color(red: 0, green: 0.478, blue: 1)  // #007AFF - Bleu électrique iOS
        case .synergyLow:
            return Color(red: 1, green: 0.839, blue: 0.039)  // #FFD60A - Jaune vif
        case .synergyHigh:
            return Color(red: 1, green: 0.231, blue: 0.188)  // #FF3B30 - Rouge iOS
        }
    }

    // MARK: - Priority

    /// Priorité d'affichage (synergyHigh > debriefing > morningBrief > synergyLow > idle)
    var priority: Int {
        switch self {
        case .idle: return 0
        case .synergyLow: return 1
        case .morningBrief: return 2
        case .debriefing: return 3
        case .synergyHigh: return 4  // Plus haute priorité
        }
    }

    // MARK: - Display Properties

    var title: String {
        switch self {
        case .idle: return "Assistant Cirkl"
        case .morningBrief: return "Brief du matin"
        case .debriefing: return "Debriefing en attente"
        case .synergyLow: return "Opportunité détectée"
        case .synergyHigh: return "Opportunité importante !"
        }
    }

    var icon: String {
        switch self {
        case .idle: return "mic.fill"
        case .morningBrief: return "sun.max.fill"
        case .debriefing: return "bubble.left.and.text.bubble.right.fill"
        case .synergyLow: return "link.circle.fill"
        case .synergyHigh: return "sparkles"
        }
    }

    var hapticType: UINotificationFeedbackGenerator.FeedbackType {
        switch self {
        case .idle: return .success
        case .morningBrief: return .success
        case .debriefing: return .warning
        case .synergyLow: return .success
        case .synergyHigh: return .success
        }
    }

    // MARK: - Animation Properties

    var pulseScale: CGFloat {
        switch self {
        case .idle: return 0.0        // Pas de pulse
        case .morningBrief: return 0.12  // Pulse doux pour le morning brief
        case .debriefing: return 0.15
        case .synergyLow: return 0.20
        case .synergyHigh: return 0.30
        }
    }

    var pulseDuration: Double {
        switch self {
        case .idle: return 0.0
        case .morningBrief: return 2.5  // Pulse lent et apaisant
        case .debriefing: return 2.0
        case .synergyLow: return 1.5
        case .synergyHigh: return 1.0  // Plus rapide = plus urgent
        }
    }

    var glowOpacity: CGFloat {
        switch self {
        case .idle: return 0.0
        case .morningBrief: return 0.35
        case .debriefing: return 0.4
        case .synergyLow: return 0.5
        case .synergyHigh: return 0.7
        }
    }

    /// Indique si l'état nécessite une action de l'utilisateur
    var requiresAction: Bool {
        switch self {
        case .idle: return false
        case .morningBrief: return true  // Le brief attend d'être lu
        case .debriefing, .synergyLow, .synergyHigh: return true
        }
    }

    /// Indique si l'état doit afficher un badge count
    var showsBadge: Bool {
        switch self {
        case .idle, .morningBrief: return false  // Morning brief n'a pas de badge count
        case .debriefing, .synergyLow, .synergyHigh: return true
        }
    }
}

// MARK: - State Resolution

extension AIAssistantState {
    /// Résout l'état final en fonction des debriefings, synergies et morning brief
    /// Priorité : synergyHigh > debriefing > morningBrief > synergyLow > idle
    static func resolve(
        pendingDebriefings: Int,
        highSynergies: Int,
        lowSynergies: Int,
        hasMorningBrief: Bool = false
    ) -> AIAssistantState {
        // Priorité haute : synergies urgentes
        if highSynergies > 0 {
            return .synergyHigh
        }
        // Debriefings en attente
        if pendingDebriefings > 0 {
            return .debriefing
        }
        // Morning brief disponible
        if hasMorningBrief {
            return .morningBrief
        }
        // Synergies faibles
        if lowSynergies > 0 {
            return .synergyLow
        }
        return .idle
    }
}

// MARK: - Synergy Type

/// Types de synergies détectables entre connexions
enum SynergyType: String, Codable, CaseIterable, Sendable {
    // Professionnelles
    case vcStartup = "vc_startup"
    case mentorMentee = "mentor_mentee"
    case recruiterCandidate = "recruiter_candidate"
    case businessPartners = "business_partners"
    case sameIndustry = "same_industry"

    // Personnelles
    case sharedInterests = "shared_interests"
    case sameLocation = "same_location"
    case mutualConnections = "mutual_connections"

    // Communautaires
    case sameEvent = "same_event"
    case sameSchool = "same_school"
    case sameClub = "same_club"

    var displayName: String {
        switch self {
        case .vcStartup: return "Investisseur ↔ Startup"
        case .mentorMentee: return "Mentor ↔ Mentee"
        case .recruiterCandidate: return "Recruteur ↔ Candidat"
        case .businessPartners: return "Partenaires business"
        case .sameIndustry: return "Même industrie"
        case .sharedInterests: return "Intérêts communs"
        case .sameLocation: return "Même localisation"
        case .mutualConnections: return "Connexions communes"
        case .sameEvent: return "Même événement"
        case .sameSchool: return "Même école"
        case .sameClub: return "Même club"
        }
    }

    var icon: String {
        switch self {
        case .vcStartup: return "dollarsign.circle"
        case .mentorMentee: return "person.2.wave.2"
        case .recruiterCandidate: return "briefcase"
        case .businessPartners: return "handshake"
        case .sameIndustry: return "building.2"
        case .sharedInterests: return "heart.circle"
        case .sameLocation: return "mappin.circle"
        case .mutualConnections: return "person.3"
        case .sameEvent: return "calendar.circle"
        case .sameSchool: return "graduationcap"
        case .sameClub: return "figure.socialdance"
        }
    }

    var category: SynergyCategory {
        switch self {
        case .vcStartup, .mentorMentee, .recruiterCandidate, .businessPartners, .sameIndustry:
            return .professional
        case .sharedInterests, .sameLocation, .mutualConnections:
            return .personal
        case .sameEvent, .sameSchool, .sameClub:
            return .community
        }
    }
}

enum SynergyCategory: String, Codable {
    case professional
    case personal
    case community

    var displayName: String {
        switch self {
        case .professional: return "Professionnelle"
        case .personal: return "Personnelle"
        case .community: return "Communautaire"
        }
    }

    var color: Color {
        switch self {
        case .professional: return DesignTokens.Colors.electricBlue
        case .personal: return DesignTokens.Colors.pink
        case .community: return DesignTokens.Colors.mint
        }
    }
}

// MARK: - Detected Synergy Model

/// Synergie détectée entre deux connexions
struct DetectedSynergy: Identifiable, Codable, Sendable {
    let id: UUID
    let connectionAId: String
    let connectionAName: String
    let connectionBId: String
    let connectionBName: String
    let synergyType: SynergyType
    let score: Double  // 0.0 - 1.0
    let reason: String
    let detectedAt: Date
    var isActedUpon: Bool

    init(
        id: UUID = UUID(),
        connectionAId: String,
        connectionAName: String,
        connectionBId: String,
        connectionBName: String,
        synergyType: SynergyType,
        score: Double,
        reason: String,
        detectedAt: Date = Date(),
        isActedUpon: Bool = false
    ) {
        self.id = id
        self.connectionAId = connectionAId
        self.connectionAName = connectionAName
        self.connectionBId = connectionBId
        self.connectionBName = connectionBName
        self.synergyType = synergyType
        self.score = score
        self.reason = reason
        self.detectedAt = detectedAt
        self.isActedUpon = isActedUpon
    }

    /// Score élevé si > 60%
    var isHighPriority: Bool {
        score > 0.6
    }

    /// Score faible si 30-60%
    var isLowPriority: Bool {
        score >= 0.3 && score <= 0.6
    }
}
