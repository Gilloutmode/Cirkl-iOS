import SwiftUI
import Combine

/// ViewModel managing the orbital interface logic
@MainActor
class OrbitalViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentUser: User
    @Published var connections: [Connection] = []
    @Published var visibleConnections: [Connection] = []
    @Published var searchQuery: String = "" {
        didSet {
            filterConnections()
        }
    }
    // Assistant state is now managed by DebriefingManager
    var assistantState: AIAssistantState {
        DebriefingManager.shared.currentState
    }

    // MARK: - Computed Properties
    var totalConnections: Int {
        connections.count
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let maxVisibleConnections = 12
    
    // MARK: - Initialization
    init() {
        // Initialize with mock user - replace with real auth
        self.currentUser = User(
            name: "Gil",
            email: "gil@cirkl.com",
            bio: "CEO & Founder of Cirkl",
            isPremium: true,
            primaryColor: "#DC267F",
            sphere: .business
        )
        
        loadConnections()
        setupSubscribers()
    }
    
    // MARK: - Public Methods

    /// Assistant state is managed by DebriefingManager - this method is for legacy compatibility
    func activateAssistant() {
        // State is now managed by DebriefingManager based on pending debriefings and synergies
        // This method can be used to manually refresh state if needed
        #if DEBUG
        print("Assistant state: \(assistantState)")
        #endif
    }
    
    func refreshConnections() {
        loadConnections()
    }
    
    // MARK: - Private Methods
    private func loadConnections() {
        // Load mock data - replace with real API call
        connections = generateMockConnections()
        filterConnections()
    }
    
    private func filterConnections() {
        if searchQuery.isEmpty {
            // Show most relevant connections
            visibleConnections = Array(
                connections
                    .sorted { $0.relationshipStrength > $1.relationshipStrength }
                    .prefix(maxVisibleConnections)
            )
        } else {
            // Natural language search
            visibleConnections = connections.filter { connection in
                connection.name.localizedCaseInsensitiveContains(searchQuery) ||
                connection.tags.contains { $0.localizedCaseInsensitiveContains(searchQuery) } ||
                connection.sharedInterests.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
            }
        }
    }
    
    private func setupSubscribers() {
        // Monitor search query changes
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.filterConnections()
            }
            .store(in: &cancellables)
    }
    
    private func generateMockConnections() -> [Connection] {
        let names = ["Denis", "Shay", "Dan", "Judith", "Gilles", "Salomé",
                     "Marie", "Thomas", "Sophie", "Alexandre", "Emma", "Lucas"]

        return names.enumerated().map { index, name in
            Connection(
                name: name,
                relationshipStrength: CGFloat.random(in: 0.3...1.0),
                interactionFrequency: CGFloat.random(in: 0.2...1.0),
                maturityLevel: MaturityLevel(rawValue: index % 5) ?? .new,
                hasActiveOpportunity: index % 3 == 0,
                opportunityType: index % 3 == 0 ? OpportunityType.allCases.randomElement() : nil,
                tags: ["Tel Aviv", "Tech", "Startup"].shuffled().prefix(2).map { $0 },
                sharedInterests: ["AI", "Music", "Travel", "Design"].shuffled().prefix(2).map { $0 }
            )
        }
    }
}

