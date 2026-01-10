import Foundation

// MARK: - Neo4j Service
/// Service pour communiquer directement avec la base Neo4j via HTTP API
@MainActor
final class Neo4jService: ObservableObject {
    static let shared = Neo4jService()

    // Configuration Neo4j Railway
    private let baseURL = "https://neo4j-production-1adf.up.railway.app"
    private let username = "neo4j"
    private let password = "9gmbz1wrn95agl6u0b0r28vfwibt7cd9"

    // États publiés
    @Published private(set) var connectionCount: Int = 0
    @Published private(set) var connections: [Neo4jConnection] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private init() {}

    // MARK: - Public API

    /// Récupère le nombre de connexions de Gil (pas toutes les relations de la base)
    func fetchConnectionCount() async {
        isLoading = true
        error = nil

        // Compter uniquement les connexions directes de Gil
        let query = "MATCH (g:Person {name: 'Gil'})-[r:CONNECTED_TO]->(p) RETURN count(p) as count"

        do {
            let result = try await executeCypher(query)
            if let row = result.first,
               let count = row["count"] as? Int {
                connectionCount = count
            }
        } catch {
            self.error = error.localizedDescription
            print("❌ Neo4j fetchConnectionCount error: \(error)")
        }

        isLoading = false
    }

    /// Récupère les connexions de Gil (pas tous les Person nodes de la base)
    func fetchConnections() async {
        isLoading = true
        error = nil

        // Récupérer uniquement les personnes connectées à Gil
        let query = """
            MATCH (g:Person {name: 'Gil'})-[:CONNECTED_TO]->(p:Person)
            RETURN p.name as name, p.role as role, p.company as company,
                   p.industry as industry, p.createdAt as createdAt,
                   p.meetingPlace as meetingPlace, p.connectionType as connectionType,
                   p.selfiePhoto as selfiePhoto, p.notes as notes, p.tags as tags,
                   p.relationshipCategory as relationshipCategory,
                   p.relationshipSubtype as relationshipSubtype,
                   p.spheres as spheres, p.natures as natures,
                   p.closenessLevel as closenessLevel,
                   p.interactionFrequency as interactionFrequency,
                   p.profileMeetingContext as profileMeetingContext,
                   p.sharedInterests as sharedInterests,
                   p.sharedCircles as sharedCircles,
                   id(p) as id
            ORDER BY p.createdAt DESC
        """

        do {
            let results = try await executeCypher(query)
            connections = results.compactMap { row -> Neo4jConnection? in
                guard let name = row["name"] as? String else { return nil }

                // Parse connection type
                let typeString = row["connectionType"] as? String ?? "Personnel"
                let connectionType = ConnectionType(rawValue: typeString) ?? .personnel

                // Parse meeting date from ISO string
                var meetingDate: Date?
                if let dateString = row["createdAt"] as? String {
                    let formatter = ISO8601DateFormatter()
                    meetingDate = formatter.date(from: dateString)
                }

                // Parse tags
                let tags = (row["tags"] as? [String]) ?? []

                // Parse relationship type from category and subtype (legacy)
                var relationshipType: RelationshipType?
                if let categoryRaw = row["relationshipCategory"] as? String,
                   !categoryRaw.isEmpty,
                   let category = RelationshipCategory(rawValue: categoryRaw) {
                    var subtype: RelationshipSubtype?
                    if let subtypeRaw = row["relationshipSubtype"] as? String,
                       !subtypeRaw.isEmpty {
                        subtype = RelationshipSubtype(rawValue: subtypeRaw)
                    }
                    relationshipType = RelationshipType(category: category, subtype: subtype)
                }

                // Parse RelationshipProfile (multi-dimensional)
                var relationshipProfile: RelationshipProfile?
                let spheresRaw = row["spheres"] as? [String] ?? []
                let naturesRaw = row["natures"] as? [String] ?? []

                // Only create profile if we have spheres or natures data
                if !spheresRaw.isEmpty || !naturesRaw.isEmpty {
                    let spheres = Set(spheresRaw.compactMap { Sphere(rawValue: $0) })
                    let natures = Set(naturesRaw.compactMap { RelationNature(rawValue: $0) })
                    let closenessLevel = ClosenessLevel(rawValue: row["closenessLevel"] as? Int ?? 3) ?? .moderate
                    let interactionFrequencyRaw = row["interactionFrequency"] as? String ?? ""
                    let interactionFrequency = InteractionFrequency(rawValue: interactionFrequencyRaw)
                    let meetingContext = row["profileMeetingContext"] as? String
                    let sharedInterests = row["sharedInterests"] as? [String] ?? []
                    let sharedCircles = row["sharedCircles"] as? [String] ?? []

                    relationshipProfile = RelationshipProfile(
                        spheres: spheres,
                        natures: natures,
                        closeness: closenessLevel,
                        interactionFrequency: interactionFrequency,
                        meetingContext: meetingContext?.isEmpty == true ? nil : meetingContext,
                        sharedInterests: sharedInterests,
                        sharedCircles: sharedCircles
                    )
                }

                return Neo4jConnection(
                    id: "\(row["id"] ?? 0)",
                    name: name,
                    role: row["role"] as? String,
                    company: row["company"] as? String,
                    industry: row["industry"] as? String,
                    meetingPlace: row["meetingPlace"] as? String,
                    meetingDate: meetingDate,
                    connectionType: connectionType,
                    selfiePhotoBase64: row["selfiePhoto"] as? String,
                    relationshipType: relationshipType,
                    relationshipProfile: relationshipProfile,
                    notes: row["notes"] as? String,
                    tags: tags
                )
            }
            print("✅ Fetched \(connections.count) connections from Neo4j")
        } catch {
            self.error = error.localizedDescription
            print("❌ Neo4j fetchConnections error: \(error)")
        }

        isLoading = false
    }

    // MARK: - CRUD Operations

    /// Créer une nouvelle connexion
    func createConnection(_ connection: Neo4jConnection) async throws {
        isLoading = true
        error = nil

        let tagsString = connection.tags.map { "'\($0)'" }.joined(separator: ", ")

        // Sérialiser le relationshipType legacy en deux propriétés séparées
        let relationshipCategory = connection.relationshipType?.category.rawValue ?? ""
        let relationshipSubtype = connection.relationshipType?.subtype?.rawValue ?? ""

        // Sérialiser le RelationshipProfile multi-dimensionnel
        let profile = connection.relationshipProfile
        let spheresString = profile?.spheres.map { "'\($0.rawValue)'" }.joined(separator: ", ") ?? ""
        let naturesString = profile?.natures.map { "'\($0.rawValue)'" }.joined(separator: ", ") ?? ""
        let closenessLevel = profile?.closeness.rawValue ?? 3  // Default: moderate
        let interactionFrequency = profile?.interactionFrequency?.rawValue ?? ""
        let meetingContext = profile?.meetingContext ?? ""
        let sharedInterestsString = profile?.sharedInterests.map { "'\(escapeString($0))'" }.joined(separator: ", ") ?? ""
        let sharedCirclesString = profile?.sharedCircles.map { "'\(escapeString($0))'" }.joined(separator: ", ") ?? ""

        let query = """
            CREATE (p:Person {
                name: '\(escapeString(connection.name))',
                role: '\(escapeString(connection.role ?? ""))',
                company: '\(escapeString(connection.company ?? ""))',
                industry: '\(escapeString(connection.industry ?? ""))',
                meetingPlace: '\(escapeString(connection.meetingPlace ?? ""))',
                connectionType: '\(connection.connectionType.rawValue)',
                selfiePhoto: '\(connection.selfiePhotoBase64 ?? "")',
                relationshipCategory: '\(relationshipCategory)',
                relationshipSubtype: '\(relationshipSubtype)',
                spheres: [\(spheresString)],
                natures: [\(naturesString)],
                closenessLevel: \(closenessLevel),
                interactionFrequency: '\(interactionFrequency)',
                profileMeetingContext: '\(escapeString(meetingContext))',
                sharedInterests: [\(sharedInterestsString)],
                sharedCircles: [\(sharedCirclesString)],
                notes: '\(escapeString(connection.notes ?? ""))',
                tags: [\(tagsString)],
                createdAt: datetime()
            })
            WITH p
            MATCH (g:Person {name: 'Gil'})
            MERGE (g)-[r:CONNECTED_TO]->(p)
            ON CREATE SET r.createdAt = datetime()
            RETURN id(p) as id, p.name as name
        """

        do {
            let result = try await executeCypher(query)
            if let row = result.first, let name = row["name"] as? String {
                print("✅ Created connection: \(name)")
            }
            await fetchConnections()
            await fetchConnectionCount()
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to create connection: \(error)")
            throw error
        }

        isLoading = false
    }

    /// Mettre à jour une connexion existante
    func updateConnection(_ connection: Neo4jConnection) async throws {
        isLoading = true
        error = nil

        let tagsString = connection.tags.map { "'\($0)'" }.joined(separator: ", ")

        // Déterminer si l'ID est numérique (Neo4j ID) ou string (mock contact)
        // Mock contacts utilisent des IDs comme "denis", "shay" - on utilise le nom pour les matcher
        let isNumericId = Int(connection.id) != nil
        let whereClause: String
        if isNumericId {
            whereClause = "WHERE id(p) = \(connection.id)"
        } else {
            // Pour les mock contacts, on match par nom original (stocké dans id pour les mocks)
            // On essaie d'abord par le nom capitalisé du contact
            whereClause = "WHERE p.name = '\(escapeString(connection.name))' OR toLower(p.name) = '\(connection.id.lowercased())'"
        }

        // Sérialiser le relationshipType legacy en deux propriétés séparées
        let relationshipCategory = connection.relationshipType?.category.rawValue ?? ""
        let relationshipSubtype = connection.relationshipType?.subtype?.rawValue ?? ""

        // Sérialiser le RelationshipProfile multi-dimensionnel
        let profile = connection.relationshipProfile
        let spheresString = profile?.spheres.map { "'\($0.rawValue)'" }.joined(separator: ", ") ?? ""
        let naturesString = profile?.natures.map { "'\($0.rawValue)'" }.joined(separator: ", ") ?? ""
        let closenessLevel = profile?.closeness.rawValue ?? 3  // Default: moderate
        let interactionFrequency = profile?.interactionFrequency?.rawValue ?? ""
        let meetingContext = profile?.meetingContext ?? ""
        let sharedInterestsString = profile?.sharedInterests.map { "'\(escapeString($0))'" }.joined(separator: ", ") ?? ""
        let sharedCirclesString = profile?.sharedCircles.map { "'\(escapeString($0))'" }.joined(separator: ", ") ?? ""

        let query = """
            MATCH (p:Person)
            \(whereClause)
            SET p.name = '\(escapeString(connection.name))',
                p.role = '\(escapeString(connection.role ?? ""))',
                p.company = '\(escapeString(connection.company ?? ""))',
                p.industry = '\(escapeString(connection.industry ?? ""))',
                p.meetingPlace = '\(escapeString(connection.meetingPlace ?? ""))',
                p.connectionType = '\(connection.connectionType.rawValue)',
                p.selfiePhoto = '\(connection.selfiePhotoBase64 ?? "")',
                p.relationshipCategory = '\(relationshipCategory)',
                p.relationshipSubtype = '\(relationshipSubtype)',
                p.spheres = [\(spheresString)],
                p.natures = [\(naturesString)],
                p.closenessLevel = \(closenessLevel),
                p.interactionFrequency = '\(interactionFrequency)',
                p.profileMeetingContext = '\(escapeString(meetingContext))',
                p.sharedInterests = [\(sharedInterestsString)],
                p.sharedCircles = [\(sharedCirclesString)],
                p.notes = '\(escapeString(connection.notes ?? ""))',
                p.tags = [\(tagsString)],
                p.updatedAt = datetime()
            RETURN p.name as name
        """

        do {
            let result = try await executeCypher(query)
            if let row = result.first, let name = row["name"] as? String {
                print("✅ Updated connection: \(name)")
            } else {
                print("⚠️ No matching connection found for update: \(connection.name) (id: \(connection.id))")
            }
            await fetchConnections()
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to update connection: \(error)")
            throw error
        }

        isLoading = false
    }

    /// Supprimer une connexion
    func deleteConnection(_ connection: Neo4jConnection) async throws {
        isLoading = true
        error = nil

        // Déterminer si l'ID est numérique (Neo4j ID) ou string (mock contact)
        let isNumericId = Int(connection.id) != nil
        let whereClause: String
        if isNumericId {
            whereClause = "WHERE id(p) = \(connection.id)"
        } else {
            whereClause = "WHERE p.name = '\(escapeString(connection.name))' OR toLower(p.name) = '\(connection.id.lowercased())'"
        }

        let query = """
            MATCH (p:Person)
            \(whereClause)
            DETACH DELETE p
            RETURN count(p) as deleted
        """

        do {
            let result = try await executeCypher(query)
            if let row = result.first, let deleted = row["deleted"] as? Int, deleted > 0 {
                print("✅ Deleted connection: \(connection.name)")
            } else {
                print("⚠️ No matching connection found for delete: \(connection.name) (id: \(connection.id))")
            }
            await fetchConnections()
            await fetchConnectionCount()
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to delete connection: \(error)")
            throw error
        }

        isLoading = false
    }

    /// Escape special characters for Cypher queries
    private func escapeString(_ str: String) -> String {
        str.replacingOccurrences(of: "'", with: "\\'")
           .replacingOccurrences(of: "\\", with: "\\\\")
    }

    // MARK: - Seed Mock Contacts

    /// Structure pour les données complètes des contacts mock
    private struct MockContactData {
        let name: String
        let role: String
        let company: String
        let industry: String
        let meetingPlace: String
        let connectionType: String
        let tags: [String]
        let avatarColorRGB: (r: Double, g: Double, b: Double)
    }

    /// Ajoute les contacts mock dans Neo4j (une seule fois)
    /// Crée Gil comme noeud central + les 6 contacts avec relations CONNECTED_TO
    /// Inclut TOUTES les données: meetingPlace, connectionType, tags, avatarColor
    func seedMockContacts() async {
        isLoading = true
        error = nil

        // Définition COMPLÈTE des contacts mock (données identiques à OrbitalContact.all)
        let mockContacts: [MockContactData] = [
            MockContactData(name: "Denis", role: "Designer", company: "Studio Créatif", industry: "Design",
                           meetingPlace: "Meetup Design", connectionType: "Événement",
                           tags: ["design", "créatif"], avatarColorRGB: (0.85, 0.65, 0.45)),
            MockContactData(name: "Shay", role: "Developer", company: "Tech Corp", industry: "Tech",
                           meetingPlace: "Conférence Swift", connectionType: "Professionnel",
                           tags: ["tech", "iOS"], avatarColorRGB: (0.55, 0.75, 0.85)),
            MockContactData(name: "Salomé", role: "Marketing", company: "Brand Agency", industry: "Marketing",
                           meetingPlace: "Networking Event", connectionType: "Networking",
                           tags: ["marketing", "stratégie"], avatarColorRGB: (0.75, 0.55, 0.70)),
            MockContactData(name: "Dan", role: "Entrepreneur", company: "StartupX", industry: "Startup",
                           meetingPlace: "Station F", connectionType: "Professionnel",
                           tags: ["startup", "business"], avatarColorRGB: (0.50, 0.70, 0.60)),
            MockContactData(name: "Gilles", role: "Consultant", company: "Advisory Co", industry: "Consulting",
                           meetingPlace: "Linkedin", connectionType: "Networking",
                           tags: ["conseil", "stratégie"], avatarColorRGB: (0.65, 0.60, 0.75)),
            MockContactData(name: "Judith", role: "Product Manager", company: "BigTech", industry: "Tech",
                           meetingPlace: "Product School", connectionType: "Événement",
                           tags: ["product", "management"], avatarColorRGB: (0.80, 0.55, 0.55))
        ]

        do {
            // 1. Créer le noeud Gil s'il n'existe pas
            let createGilQuery = """
                MERGE (g:Person {name: 'Gil', userId: 'gil'})
                ON CREATE SET g.role = 'Founder', g.company = 'Cirkl', g.industry = 'Tech', g.createdAt = datetime()
                RETURN g.name as name
            """
            _ = try await executeCypher(createGilQuery)
            print("✅ Gil node ensured")

            // 2. Créer chaque contact mock avec TOUTES les données + relation CONNECTED_TO
            for contact in mockContacts {
                let tagsString = contact.tags.map { "'\($0)'" }.joined(separator: ", ")
                let colorString = "\(contact.avatarColorRGB.r),\(contact.avatarColorRGB.g),\(contact.avatarColorRGB.b)"

                let createContactQuery = """
                    MERGE (p:Person {name: '\(escapeString(contact.name))'})
                    ON CREATE SET
                        p.role = '\(escapeString(contact.role))',
                        p.company = '\(escapeString(contact.company))',
                        p.industry = '\(escapeString(contact.industry))',
                        p.meetingPlace = '\(escapeString(contact.meetingPlace))',
                        p.connectionType = '\(contact.connectionType)',
                        p.tags = [\(tagsString)],
                        p.avatarColor = '\(colorString)',
                        p.createdAt = datetime()
                    ON MATCH SET
                        p.role = '\(escapeString(contact.role))',
                        p.company = '\(escapeString(contact.company))',
                        p.industry = '\(escapeString(contact.industry))',
                        p.meetingPlace = '\(escapeString(contact.meetingPlace))',
                        p.connectionType = '\(contact.connectionType)',
                        p.tags = [\(tagsString)],
                        p.avatarColor = '\(colorString)',
                        p.updatedAt = datetime()
                    WITH p
                    MATCH (g:Person {name: 'Gil'})
                    MERGE (g)-[r:CONNECTED_TO]->(p)
                    ON CREATE SET r.createdAt = datetime(), r.source = 'mock_data'
                    RETURN p.name as name
                """
                _ = try await executeCypher(createContactQuery)
                print("✅ Created/updated contact with full data: \(contact.name)")
            }

            print("✅ All mock contacts seeded with COMPLETE data")

            // Rafraîchir les données
            await fetchConnectionCount()
            await fetchConnections()

        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to seed mock contacts: \(error)")
        }

        isLoading = false
    }

    // MARK: - Cypher Execution

    private func executeCypher(_ query: String) async throws -> [[String: Any]] {
        let endpoint = "\(baseURL)/db/neo4j/tx/commit"

        guard let url = URL(string: endpoint) else {
            throw Neo4jError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Basic Auth
        let credentials = "\(username):\(password)"
        if let credentialData = credentials.data(using: .utf8) {
            let base64Credentials = credentialData.base64EncodedString()
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }

        // Body
        let body: [String: Any] = [
            "statements": [
                ["statement": query]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw Neo4jError.requestFailed
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]],
              let firstResult = results.first,
              let columns = firstResult["columns"] as? [String],
              let dataRows = firstResult["data"] as? [[String: Any]] else {
            throw Neo4jError.invalidResponse
        }

        // Transformer les résultats en dictionnaires
        return dataRows.compactMap { row -> [String: Any]? in
            guard let rowValues = row["row"] as? [Any] else { return nil }
            var dict: [String: Any] = [:]
            for (index, column) in columns.enumerated() where index < rowValues.count {
                dict[column] = rowValues[index]
            }
            return dict
        }
    }
}

// MARK: - Models

struct Neo4jConnection: Identifiable, Equatable, Hashable {
    let id: String
    var name: String
    var role: String?
    var company: String?
    var industry: String?

    // Meeting context
    var meetingPlace: String?
    var meetingDate: Date?
    var connectionType: ConnectionType
    var selfiePhotoBase64: String?  // Base64 encoded photo for Neo4j storage

    // Relationship
    var relationshipType: RelationshipType?
    var relationshipProfile: RelationshipProfile?

    // Notes and tags
    var notes: String?
    var tags: [String]

    // MARK: - Computed Properties

    var displayRole: String {
        if let role = role, let company = company {
            return "\(role) @ \(company)"
        }
        return role ?? company ?? ""
    }

    var formattedMeetingDate: String? {
        guard let date = meetingDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }

    /// Retourne le profil relationnel, migré depuis le type legacy si nécessaire
    var effectiveRelationshipProfile: RelationshipProfile {
        if let profile = relationshipProfile {
            return profile
        }
        if let legacyType = relationshipType {
            return RelationshipProfile.from(legacy: legacyType)
        }
        return RelationshipProfile()
    }

    /// Indique si le contact a une relation définie (profile ou legacy)
    var hasRelationship: Bool {
        relationshipProfile != nil || relationshipType != nil
    }

    init(
        id: String,
        name: String,
        role: String? = nil,
        company: String? = nil,
        industry: String? = nil,
        meetingPlace: String? = nil,
        meetingDate: Date? = nil,
        connectionType: ConnectionType = .personnel,
        selfiePhotoBase64: String? = nil,
        relationshipType: RelationshipType? = nil,
        relationshipProfile: RelationshipProfile? = nil,
        notes: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.company = company
        self.industry = industry
        self.meetingPlace = meetingPlace
        self.meetingDate = meetingDate
        self.connectionType = connectionType
        self.selfiePhotoBase64 = selfiePhotoBase64
        self.relationshipType = relationshipType
        self.relationshipProfile = relationshipProfile
        self.notes = notes
        self.tags = tags
    }
}

// MARK: - Errors

enum Neo4jError: LocalizedError {
    case invalidURL
    case requestFailed
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid Neo4j URL"
        case .requestFailed: return "Neo4j request failed"
        case .invalidResponse: return "Invalid Neo4j response"
        }
    }
}
