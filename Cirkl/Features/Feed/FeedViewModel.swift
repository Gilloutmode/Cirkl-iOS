import Foundation
import SwiftUI

// MARK: - Feed ViewModel
/// Gère les actualités du réseau avec filtrage et marquage lu/non-lu
/// Note: Pas de withAnimation ici - animations gérées côté View
/// Uses ObservableObject + @StateObject for proper state persistence across view updates

@MainActor
final class FeedViewModel: ObservableObject {

    // MARK: - Properties

    @Published private(set) var items: [FeedItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    /// ID de l'item en cours de traitement (pour désactiver les boutons pendant l'opération)
    @Published private(set) var loadingItemId: String?

    @Published var selectedFilter: FeedFilter = .all

    // MARK: - Computed Properties

    var filteredItems: [FeedItem] {
        switch selectedFilter {
        case .all:
            return items
        default:
            return items.filter { selectedFilter.matchingTypes.contains($0.type) }
        }
    }

    var unreadCount: Int {
        items.filter { !$0.isRead }.count
    }

    var hasUnread: Bool {
        unreadCount > 0
    }

    // Filter counts
    var updateCount: Int {
        items.filter { $0.type == .update }.count
    }

    var synergyCount: Int {
        items.filter { $0.type == .synergy }.count
    }

    var reminderCount: Int {
        items.filter { $0.type == .networkPulse }.count
    }

    // MARK: - Loading

    func load() async {
        isLoading = true
        error = nil

        // Simulate network delay
        try? await Task.sleep(for: .milliseconds(500))

        // For MVP, use mock data
        items = FeedItem.mockItems.sorted { $0.timestamp > $1.timestamp }

        isLoading = false

        #if DEBUG
        print("📰 Feed loaded: \(items.count) items, \(unreadCount) unread")
        print("   └─ Updates: \(updateCount), Synergies: \(synergyCount), Pulse: \(reminderCount)")
        #endif
    }

    // MARK: - Actions

    func markAsRead(_ itemId: String) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else {
            #if DEBUG
            print("[Feed] markAsRead: item \(itemId) not found")
            #endif
            return
        }

        // Already read, skip
        guard !items[index].isRead else {
            #if DEBUG
            print("[Feed] markAsRead: item \(itemId) already read, skipping")
            #endif
            return
        }

        // Create a copy, modify, and replace to ensure SwiftUI detects the change
        var updatedItem = items[index]
        updatedItem.isRead = true
        items[index] = updatedItem

        #if DEBUG
        print("[Feed] markAsRead: \(itemId) → isRead=true (unreadCount now: \(unreadCount))")
        #endif
    }

    func markAllAsRead() {
        let unreadBefore = unreadCount

        // Update all items using copy-and-replace pattern for SwiftUI reactivity
        for index in items.indices where !items[index].isRead {
            var updatedItem = items[index]
            updatedItem.isRead = true
            items[index] = updatedItem
        }

        #if DEBUG
        print("[Feed] markAllAsRead: \(unreadBefore) → 0 unread")
        #endif
    }

    func refresh() async {
        await load()
    }

    // MARK: - Filter Selection

    func selectFilter(_ filter: FeedFilter) {
        let oldFilter = selectedFilter
        selectedFilter = filter

        #if DEBUG
        print("📰 Filter: \(oldFilter.rawValue) → \(filter.rawValue)")
        print("   └─ filteredItems.count: \(filteredItems.count)")
        #endif
    }

    // MARK: - Synergy Actions

    /// Vérifie si un item est en cours de traitement
    func isItemLoading(_ itemId: String) -> Bool {
        loadingItemId == itemId
    }

    /// Crée une connexion entre les deux personnes d'une synergie
    /// Appelle le backend N8N et supprime l'item uniquement après confirmation
    func createSynergyConnection(_ itemId: String) async {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else {
            print("[Feed] createSynergyConnection: item \(itemId) not found")
            return
        }
        let item = items[index]

        // Set loading state
        loadingItemId = itemId
        error = nil

        let person1 = item.synergyPerson1Name ?? "Unknown"
        let person2 = item.synergyPerson2Name ?? "Unknown"

        #if DEBUG
        print("[Feed] Creating synergy connection for item: \(itemId)")
        print("[Feed] Connecting: \(person1) ↔ \(person2)")
        #endif

        do {
            // Call N8NService to create the synergy connection
            let response = try await N8NService.shared.createSynergyConnection(
                userId: "demo-user", // TODO: Use actual userId from auth
                synergyId: itemId,
                person1Name: person1,
                person2Name: person2,
                matchContext: item.synergyMatch
            )

            // Clear loading state
            loadingItemId = nil

            if response.success {
                // Remove the synergy item ONLY after backend confirmation
                items.remove(at: index)

                #if DEBUG
                print("[Feed] Synergy connection created successfully: \(response.message ?? "OK")")
                #endif
            } else {
                // Backend returned failure
                error = response.message ?? "Échec de la création de connexion"
                #if DEBUG
                print("[Feed] Synergy creation failed: \(response.message ?? "Unknown error")")
                #endif
            }
        } catch {
            // Network or other error - don't remove the item
            loadingItemId = nil
            self.error = error.localizedDescription

            #if DEBUG
            print("[Feed] Synergy connection error: \(error.localizedDescription)")
            #endif
        }
    }

    /// Dismiss une synergie (pas intéressé pour le moment)
    func dismissSynergy(_ itemId: String) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else { return }

        #if DEBUG
        print("🔮 Synergy dismissed: \(itemId)")
        #endif

        // Remove the synergy item - animation gérée côté View
        items.remove(at: index)
    }

    // MARK: - Network Pulse Actions

    /// Génère un message suggéré pour reprendre contact avec une connexion dormante
    func generateResumeContactMessage(for item: FeedItem) -> String {
        let name = item.connectionName ?? "cette personne"
        let context = item.lastInteractionContext ?? "notre dernière rencontre"

        #if DEBUG
        print("[Feed] Generating resume contact message for: \(name)")
        #endif

        // Message personnalisé basé sur le contexte
        if let days = item.daysSinceContact {
            if days > 30 {
                return "Hey \(name) ! Ça fait un moment depuis \(context). Je pensais à toi, comment vas-tu ?"
            } else {
                return "Salut \(name) ! Je repensais à \(context). On se fait un café bientôt ?"
            }
        }

        return "Hey \(name) ! Je pensais à toi. On se fait un café bientôt ?"
    }

    /// Marque l'action "Reprendre contact" comme effectuée et marque l'item comme lu
    func markResumeContactDone(_ itemId: String) {
        markAsRead(itemId)

        #if DEBUG
        print("[Feed] Resume contact action completed for: \(itemId)")
        #endif
    }
}
