//
//  SynergyDetectionService.swift
//  Cirkl
//
//  Created by Claude on 15/01/2026.
//

import Foundation

// MARK: - Synergy Detection Service

/// Service hybride de détection de synergies
/// Analyse locale rapide + analyse N8N profonde
@MainActor
final class SynergyDetectionService {

    // MARK: - Singleton

    static let shared = SynergyDetectionService()

    // MARK: - Configuration

    /// Seuil minimum pour envoi à N8N (30%)
    private let minimumScoreForN8N: Double = 0.30

    /// Seuil pour synergie haute priorité (60%)
    private let highPriorityThreshold: Double = 0.60

    // MARK: - Init

    private init() {}

    // MARK: - Public Methods

    /// Analyse toutes les connexions pour détecter des synergies
    /// - Parameter connections: Liste des connexions à analyser
    /// - Returns: Liste des synergies détectées
    func analyzeConnections(_ connections: [Connection]) async -> [DetectedSynergy] {
        var synergies: [DetectedSynergy] = []

        // Compare each pair of connections
        for i in 0..<connections.count {
            for j in (i + 1)..<connections.count {
                let connectionA = connections[i]
                let connectionB = connections[j]

                // Local analysis first
                if let synergy = analyzeLocally(connectionA, connectionB) {
                    synergies.append(synergy)

                    // If score is high enough, enhance with N8N
                    if synergy.score >= minimumScoreForN8N {
                        Task {
                            await enhanceWithN8N(synergy)
                        }
                    }
                }
            }
        }

        return synergies
    }

    /// Analyse une nouvelle connexion contre les existantes
    /// - Parameters:
    ///   - newConnection: Nouvelle connexion
    ///   - existingConnections: Connexions existantes
    /// - Returns: Synergies détectées avec la nouvelle connexion
    func analyzeNewConnection(_ newConnection: Connection, against existingConnections: [Connection]) async -> [DetectedSynergy] {
        var synergies: [DetectedSynergy] = []

        for existing in existingConnections {
            if let synergy = analyzeLocally(newConnection, existing) {
                synergies.append(synergy)

                // Notify DebriefingManager
                DebriefingManager.shared.addSynergy(synergy)

                // Enhance with N8N if needed
                if synergy.score >= minimumScoreForN8N {
                    Task {
                        await enhanceWithN8N(synergy)
                    }
                }
            }
        }

        // Notify if synergies found
        if !synergies.isEmpty {
            NotificationCenter.default.post(name: .synergyDetected, object: nil)
        }

        return synergies
    }

    // MARK: - Local Analysis

    /// Analyse locale rapide entre deux connexions
    private func analyzeLocally(_ a: Connection, _ b: Connection) -> DetectedSynergy? {
        var score: Double = 0
        var matchedTypes: [SynergyType] = []
        var reasons: [String] = []

        // 1. Check VC + Startup match
        if let vcMatch = checkVCStartupMatch(a, b) {
            score += 0.4
            matchedTypes.append(.vcStartup)
            reasons.append(vcMatch)
        }

        // 2. Check Mentor + Mentee match
        if let mentorMatch = checkMentorMatch(a, b) {
            score += 0.35
            matchedTypes.append(.mentorMentee)
            reasons.append(mentorMatch)
        }

        // 3. Check Recruiter + Candidate match
        if let recruiterMatch = checkRecruiterMatch(a, b) {
            score += 0.35
            matchedTypes.append(.recruiterCandidate)
            reasons.append(recruiterMatch)
        }

        // 4. Check same industry
        if let industryMatch = checkSameIndustry(a, b) {
            score += 0.15
            matchedTypes.append(.sameIndustry)
            reasons.append(industryMatch)
        }

        // 5. Check shared interests
        if let interestsMatch = checkSharedInterests(a, b) {
            score += 0.20
            matchedTypes.append(.sharedInterests)
            reasons.append(interestsMatch)
        }

        // 6. Check same location
        if let locationMatch = checkSameLocation(a, b) {
            score += 0.10
            matchedTypes.append(.sameLocation)
            reasons.append(locationMatch)
        }

        // 7. Check mutual connections
        if let mutualMatch = checkMutualConnections(a, b) {
            score += 0.15
            matchedTypes.append(.mutualConnections)
            reasons.append(mutualMatch)
        }

        // Only return synergy if score is meaningful (>= 20%)
        guard score >= 0.20, let primaryType = matchedTypes.first else {
            return nil
        }

        // Cap score at 1.0
        score = min(score, 1.0)

        return DetectedSynergy(
            connectionAId: a.id.uuidString,
            connectionAName: a.name,
            connectionBId: b.id.uuidString,
            connectionBName: b.name,
            synergyType: primaryType,
            score: score,
            reason: reasons.joined(separator: " + ")
        )
    }

    // MARK: - Matching Helpers

    private func checkVCStartupMatch(_ a: Connection, _ b: Connection) -> String? {
        let vcKeywords = ["vc", "venture", "investor", "capital", "fund", "investment"]
        let startupKeywords = ["startup", "founder", "ceo", "co-founder", "entrepreneur", "raising", "seed", "series"]

        let aIsVC = containsKeywords(a, vcKeywords)
        let bIsVC = containsKeywords(b, vcKeywords)
        let aIsStartup = containsKeywords(a, startupKeywords)
        let bIsStartup = containsKeywords(b, startupKeywords)

        if aIsVC && bIsStartup {
            return "\(a.name) (VC) peut investir dans \(b.name) (Startup)"
        } else if bIsVC && aIsStartup {
            return "\(b.name) (VC) peut investir dans \(a.name) (Startup)"
        }

        return nil
    }

    private func checkMentorMatch(_ a: Connection, _ b: Connection) -> String? {
        let mentorKeywords = ["mentor", "coach", "advisor", "consultant", "expert", "senior", "director", "vp", "chief"]
        let menteeKeywords = ["junior", "student", "intern", "learning", "seeking advice", "new to", "early career"]

        let aIsMentor = containsKeywords(a, mentorKeywords)
        let bIsMentor = containsKeywords(b, mentorKeywords)
        let aIsMentee = containsKeywords(a, menteeKeywords)
        let bIsMentee = containsKeywords(b, menteeKeywords)

        if aIsMentor && bIsMentee {
            return "\(a.name) peut mentorer \(b.name)"
        } else if bIsMentor && aIsMentee {
            return "\(b.name) peut mentorer \(a.name)"
        }

        return nil
    }

    private func checkRecruiterMatch(_ a: Connection, _ b: Connection) -> String? {
        let recruiterKeywords = ["recruiter", "talent", "hr", "hiring", "recruitment", "headhunter"]
        let candidateKeywords = ["looking for", "job", "available", "freelance", "open to"]

        let aIsRecruiter = containsKeywords(a, recruiterKeywords)
        let bIsRecruiter = containsKeywords(b, recruiterKeywords)
        let aIsCandidate = containsKeywords(a, candidateKeywords)
        let bIsCandidate = containsKeywords(b, candidateKeywords)

        if aIsRecruiter && bIsCandidate {
            return "\(a.name) peut recruter \(b.name)"
        } else if bIsRecruiter && aIsCandidate {
            return "\(b.name) peut recruter \(a.name)"
        }

        return nil
    }

    private func checkSameIndustry(_ a: Connection, _ b: Connection) -> String? {
        // Use industry property directly from Connection
        guard let industryA = a.industry?.lowercased(),
              let industryB = b.industry?.lowercased(),
              !industryA.isEmpty && !industryB.isEmpty else {
            return nil
        }

        // Check for industry keywords overlap
        let industriesA = Set(industryA.split(separator: " ").map(String.init))
        let industriesB = Set(industryB.split(separator: " ").map(String.init))
        let common = industriesA.intersection(industriesB)

        if !common.isEmpty {
            return "Même secteur: \(common.prefix(2).joined(separator: ", "))"
        }

        // Also check if industries match exactly
        if industryA == industryB {
            return "Même secteur: \(industryA.capitalized)"
        }

        return nil
    }

    private func checkSharedInterests(_ a: Connection, _ b: Connection) -> String? {
        // Use sharedInterests property directly from Connection
        let interestsA = Set(a.sharedInterests)
        let interestsB = Set(b.sharedInterests)

        let common = interestsA.intersection(interestsB)

        if common.count >= 2 {
            return "Intérêts communs: \(common.prefix(3).joined(separator: ", "))"
        }

        return nil
    }

    private func checkSameLocation(_ a: Connection, _ b: Connection) -> String? {
        // Check if both have location tags
        let tagsA = Set(a.tags.map { $0.lowercased() })
        let tagsB = Set(b.tags.map { $0.lowercased() })

        let locationKeywords = ["paris", "lyon", "marseille", "toulouse", "nice", "nantes", "bordeaux", "lille", "france", "usa", "london", "berlin", "tel aviv", "new york", "san francisco"]

        let locationsA = tagsA.intersection(Set(locationKeywords))
        let locationsB = tagsB.intersection(Set(locationKeywords))

        let commonLocations = locationsA.intersection(locationsB)

        if !commonLocations.isEmpty {
            return "Même localisation: \(commonLocations.first!.capitalized)"
        }

        // Also check meetingPlace
        if let placeA = a.meetingPlace?.lowercased(),
           let placeB = b.meetingPlace?.lowercased(),
           !placeA.isEmpty && !placeB.isEmpty && placeA == placeB {
            return "Même lieu de rencontre: \(placeA.capitalized)"
        }

        return nil
    }

    private func checkMutualConnections(_ a: Connection, _ b: Connection) -> String? {
        // Check for matching tags that could indicate shared circles/communities
        let tagsA = Set(a.tags.map { $0.lowercased() })
        let tagsB = Set(b.tags.map { $0.lowercased() })

        // Filter out location-related tags
        let locationKeywords = Set(["paris", "lyon", "marseille", "toulouse", "nice", "nantes", "bordeaux", "lille", "france", "usa", "london", "berlin", "tel aviv", "new york", "san francisco"])
        let circleTagsA = tagsA.subtracting(locationKeywords)
        let circleTagsB = tagsB.subtracting(locationKeywords)

        let common = circleTagsA.intersection(circleTagsB)

        if common.count >= 2 {
            return "\(common.count) tags en commun: \(common.prefix(2).joined(separator: ", "))"
        }

        return nil
    }

    private func containsKeywords(_ connection: Connection, _ keywords: [String]) -> Bool {
        let searchText = [
            connection.name,
            connection.notes ?? "",
            connection.tags.joined(separator: " "),
            connection.role ?? "",
            connection.company ?? "",
            connection.industry ?? "",
            connection.meetingPlace ?? ""
        ].joined(separator: " ").lowercased()

        return keywords.contains { searchText.contains($0) }
    }

    // MARK: - N8N Enhancement

    /// Enrich synergy with N8N deep analysis
    private func enhanceWithN8N(_ synergy: DetectedSynergy) async {
        #if DEBUG
        print("🔗 Enhancing synergy with N8N: \(synergy.connectionAName) <-> \(synergy.connectionBName)")
        #endif

        // TODO: Implement N8N call for deep analysis
        // For now, synergies are based on local analysis only
        // The N8N enhancement would:
        // 1. Send both profiles to N8N
        // 2. Use GPT/Claude to analyze deeper compatibility
        // 3. Return enhanced score and detailed reason
        // 4. Update the synergy in DebriefingManager
    }

    // MARK: - Periodic Scan

    /// Run periodic synergy scan (call from app lifecycle)
    func runPeriodicScan(connections: [Connection]) async {
        #if DEBUG
        print("🔍 Running periodic synergy scan for \(connections.count) connections")
        #endif

        let synergies = await analyzeConnections(connections)

        for synergy in synergies {
            DebriefingManager.shared.addSynergy(synergy)
        }

        if !synergies.isEmpty {
            #if DEBUG
            print("🔗 Found \(synergies.count) synergies")
            #endif
            NotificationCenter.default.post(name: .synergyDetected, object: nil)
        }
    }
}

