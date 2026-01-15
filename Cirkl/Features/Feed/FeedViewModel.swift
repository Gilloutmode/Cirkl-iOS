import Foundation
import SwiftUI

// MARK: - Feed ViewModel
/// Gère les actualités du réseau avec filtrage et marquage lu/non-lu

@MainActor
@Observable
final class FeedViewModel {

    // MARK: - Properties

    private(set) var items: [FeedItem] = []
    private(set) var isLoading = false
    private(set) var error: String?

    var selectedFilter: FeedFilter = .all

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
        withAnimation(DesignTokens.Animations.fast) {
            selectedFilter = filter
        }
    }

    // MARK: - Synergy Actions

    /// Crée une connexion entre les deux personnes d'une synergie
    func createSynergyConnection(_ itemId: String) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else { return }
        let item = items[index]

        // Mark as read
        items[index].isRead = true

        #if DEBUG
        if let person1 = item.synergyPerson1Name,
           let person2 = item.synergyPerson2Name {
            print("🔮 Creating connection: \(person1) ↔ \(person2)")
        }
        #endif

        // TODO: Appeler N8NService pour créer la connexion
        // En MVP, on simule juste le succès

        // Remove the synergy item after action
        withAnimation(DesignTokens.Animations.normal) {
            items.remove(at: index)
        }
    }

    /// Dismiss une synergie (pas intéressé pour le moment)
    func dismissSynergy(_ itemId: String) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else { return }

        // Mark as read
        items[index].isRead = true

        #if DEBUG
        print("🔮 Synergy dismissed: \(itemId)")
        #endif

        // Remove the synergy item
        withAnimation(DesignTokens.Animations.normal) {
            items.remove(at: index)
        }
    }
}
