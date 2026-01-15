import Foundation
import SwiftUI

// MARK: - Network Pulse ViewModel
/// Gère la classification des connexions par santé relationnelle
/// Classification: Active (< 7j) | Dormant (7-30j) | At Risk (> 30j)

@MainActor
@Observable
final class NetworkPulseViewModel {

    // MARK: - Types

    enum PulseStatus: String, CaseIterable {
        case active = "Active"
        case dormant = "Dormant"
        case atRisk = "At Risk"

        var emoji: String {
            switch self {
            case .active: return "🟢"
            case .dormant: return "🟡"
            case .atRisk: return "🔴"
            }
        }

        var color: Color {
            switch self {
            case .active: return DesignTokens.Colors.mint
            case .dormant: return DesignTokens.Colors.warning
            case .atRisk: return DesignTokens.Colors.error
            }
        }

        var description: String {
            switch self {
            case .active: return "Contact récent"
            case .dormant: return "À relancer"
            case .atRisk: return "Risque de perte"
            }
        }
    }

    struct PulseConnection: Identifiable, Equatable {
        let id: String
        let name: String
        let role: String?
        let company: String?
        let lastInteraction: Date?
        let status: PulseStatus
        var suggestion: String?
        var isLoadingSuggestion: Bool = false

        var displayRole: String {
            if let role = role, let company = company {
                return "\(role) @ \(company)"
            }
            return role ?? company ?? ""
        }

        var daysSinceInteraction: Int {
            guard let lastInteraction = lastInteraction else { return 999 }
            return Calendar.current.dateComponents([.day], from: lastInteraction, to: Date()).day ?? 0
        }

        var lastInteractionText: String {
            guard lastInteraction != nil else { return "Jamais" }
            let days = daysSinceInteraction
            if days == 0 { return "Aujourd'hui" }
            if days == 1 { return "Hier" }
            if days < 7 { return "Il y a \(days) jours" }
            if days < 30 { return "Il y a \(days / 7) semaines" }
            return "Il y a \(days / 30) mois"
        }
    }

    enum ViewState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    // MARK: - Properties

    private(set) var state: ViewState = .idle
    private(set) var connections: [PulseConnection] = []

    // Stats
    var activeCount: Int { connections.filter { $0.status == .active }.count }
    var dormantCount: Int { connections.filter { $0.status == .dormant }.count }
    var atRiskCount: Int { connections.filter { $0.status == .atRisk }.count }
    var totalCount: Int { connections.count }

    // Grouped connections
    var activeConnections: [PulseConnection] {
        connections.filter { $0.status == .active }
    }
    var dormantConnections: [PulseConnection] {
        connections.filter { $0.status == .dormant }
    }
    var atRiskConnections: [PulseConnection] {
        connections.filter { $0.status == .atRisk }
    }

    // MARK: - Classification Logic

    /// Classifie une connexion selon la date de dernière interaction
    /// - Active: < 7 jours
    /// - Dormant: 7-30 jours
    /// - At Risk: > 30 jours
    private func classify(daysSinceInteraction: Int) -> PulseStatus {
        switch daysSinceInteraction {
        case 0..<7:
            return .active
        case 7..<30:
            return .dormant
        default:
            return .atRisk
        }
    }

    // MARK: - Data Fetching

    /// Charge les connexions depuis Neo4j avec lastInteraction
    func load() async {
        state = .loading

        do {
            let neo4jConnections = try await fetchConnectionsWithInteraction()

            connections = neo4jConnections.map { conn in
                return PulseConnection(
                    id: conn.id,
                    name: conn.name,
                    role: conn.role,
                    company: conn.company,
                    lastInteraction: conn.lastInteraction,
                    status: classify(daysSinceInteraction: conn.daysSinceInteraction)
                )
            }.sorted { $0.daysSinceInteraction > $1.daysSinceInteraction }

            state = .loaded

            #if DEBUG
            print("📊 NetworkPulse loaded: \(activeCount) active, \(dormantCount) dormant, \(atRiskCount) at risk")
            #endif
        } catch {
            state = .error(error.localizedDescription)
            #if DEBUG
            print("❌ NetworkPulse load error: \(error)")
            #endif
        }
    }

    /// Récupère les connexions avec leur date de dernière interaction
    private func fetchConnectionsWithInteraction() async throws -> [ConnectionWithInteraction] {
        // Query Neo4j pour récupérer lastInteraction sur la relation
        let query = """
            MATCH (g:Person {name: 'Gil'})-[r:CONNECTED_TO]->(p:Person)
            RETURN p.name as name, p.role as role, p.company as company,
                   id(p) as id,
                   coalesce(r.lastInteraction, r.createdAt, datetime()) as lastInteraction
            ORDER BY lastInteraction ASC
        """

        let results = try await Neo4jService.shared.executeQuery(query)

        return results.compactMap { row -> ConnectionWithInteraction? in
            guard let name = row["name"] as? String else { return nil }

            var lastInteraction: Date?
            if let dateString = row["lastInteraction"] as? String {
                let formatter = ISO8601DateFormatter()

                // Try with fractional seconds first
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                lastInteraction = formatter.date(from: dateString)

                // Fallback without fractional seconds
                if lastInteraction == nil {
                    formatter.formatOptions = [.withInternetDateTime]
                    lastInteraction = formatter.date(from: dateString)
                }

                // Fallback for Neo4j datetime format (2026-01-14T10:00Z)
                if lastInteraction == nil {
                    formatter.formatOptions = [.withFullDate, .withTime, .withTimeZone]
                    lastInteraction = formatter.date(from: dateString)
                }

                #if DEBUG
                if lastInteraction == nil {
                    print("⚠️ Failed to parse date: \(dateString)")
                }
                #endif
            }

            return ConnectionWithInteraction(
                id: "\(row["id"] ?? 0)",
                name: name,
                role: row["role"] as? String,
                company: row["company"] as? String,
                lastInteraction: lastInteraction
            )
        }
    }

    // MARK: - AI Suggestions

    /// Demande une suggestion IA pour reconnecter avec une connexion
    func fetchSuggestion(for connectionId: String) async {
        guard let index = connections.firstIndex(where: { $0.id == connectionId }) else { return }

        connections[index].isLoadingSuggestion = true

        do {
            let connection = connections[index]
            let suggestion = try await N8NService.shared.fetchSuggestion(
                userId: "gil",
                connectionName: connection.name,
                context: "Dernière interaction: \(connection.lastInteractionText). Status: \(connection.status.rawValue)"
            )

            connections[index].suggestion = suggestion
            connections[index].isLoadingSuggestion = false

            #if DEBUG
            print("💡 Suggestion for \(connection.name): \(suggestion)")
            #endif
        } catch {
            connections[index].isLoadingSuggestion = false
            #if DEBUG
            print("❌ Failed to fetch suggestion: \(error)")
            #endif
        }
    }

    /// Efface la suggestion pour une connexion
    func clearSuggestion(for connectionId: String) {
        guard let index = connections.firstIndex(where: { $0.id == connectionId }) else { return }
        connections[index].suggestion = nil
    }
}

// MARK: - Helper Types

private struct ConnectionWithInteraction {
    let id: String
    let name: String
    let role: String?
    let company: String?
    let lastInteraction: Date?

    var daysSinceInteraction: Int {
        guard let lastInteraction = lastInteraction else { return 999 }
        return Calendar.current.dateComponents([.day], from: lastInteraction, to: Date()).day ?? 0
    }
}
