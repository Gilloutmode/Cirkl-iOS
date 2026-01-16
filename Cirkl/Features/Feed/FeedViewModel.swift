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
        guard let index = items.firstIndex(where: { $0.id == itemId }) else { return }
        items[index].isRead = true

        #if DEBUG
        print("📰 Marked as read: \(itemId)")
        #endif
    }

    func markAllAsRead() {
        for index in items.indices {
            items[index].isRead = true
        }

        #if DEBUG
        print("📰 Marked all as read")
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
    /// Note: Async pour supporter l'appel backend futur
    func createSynergyConnection(_ itemId: String) async {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else {
            print("[Feed] createSynergyConnection: item \(itemId) not found")
            return
        }
        let item = items[index]

        // Set loading state
        loadingItemId = itemId

        #if DEBUG
        print("[Feed] Creating synergy connection for item: \(itemId)")
        if let person1 = item.synergyPerson1Name,
           let person2 = item.synergyPerson2Name {
            print("[Feed] Connecting: \(person1) ↔ \(person2)")
        }
        #endif

        // TODO: Task 4 - Appeler N8NService.createSynergyConnection()
        // Pour l'instant, on simule un délai réseau
        try? await Task.sleep(for: .milliseconds(500))

        // Clear loading state
        loadingItemId = nil

        // Remove the synergy item - animation gérée côté View
        items.remove(at: index)

        #if DEBUG
        print("[Feed] Synergy connection created successfully")
        #endif
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
}
