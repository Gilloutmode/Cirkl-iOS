# Implementation Plan: Feed d'Actualité - Corrections Complètes

> **Scope**: Cross-cutting | **Risk**: Agressif | **Validation**: Build + Logs détaillés

## Summary

Correction de tous les bugs du Feed CirKL : state management incorrect, boutons non fonctionnels (Updates, Synergies, Rappels), réactivité UI cassée, et intégration backend manquante. Refactoring agressif autorisé pour une solution propre.

## Tasks

- [x] Task 1: Fix ViewModel state management - Converted FeedViewModel from @Observable to ObservableObject with @Published properties. Changed FeedView to use @StateObject for proper state persistence across view updates.

- [x] Task 2: Implémenter loading state dans FeedViewModel - Added `loadingItemId: String?` property and `isItemLoading()` helper method. Made `createSynergyConnection()` async with loading state tracking. Updated SynergyCard to accept `isLoading` parameter with ProgressView and disabled state during operations.

- [x] Task 3: Créer la méthode N8NService.createSynergyConnection() - Added `CreateSynergyRequest` and `CreateSynergyResponse` structs. Implemented `createSynergyConnection(userId:synergyId:person1Name:person2Name:matchContext:)` method that POSTs to `/webhook/acknowledge-synergies` with full synergy data. Includes debug logging and proper error handling.

- [x] Task 4: Connecter createSynergyConnection() au backend - Updated FeedViewModel.createSynergyConnection() to call N8NService.shared.createSynergyConnection() with try/await. Item is removed from feed ONLY after backend confirmation. Added proper error handling that sets ViewModel.error on failure without removing the item.

- [x] Task 5: Implémenter le bouton "Reprendre contact" - Implemented in FeedItemDetailSheet within FeedView.swift. Added ShareSheet component (Components/Library/Sharing/ShareSheet.swift) for UIActivityViewController integration. Button generates a personalized message based on connection context (name, days since contact, last interaction) and opens iOS share sheet. Added helper method generateResumeContactMessage() and debug logging.

- [ ] Task 6: Ajouter loading state aux boutons SynergyCard - Dans SynergyCard.swift, ajouter un binding `isLoading` pour désactiver le bouton et afficher un ProgressView pendant le traitement.

- [ ] Task 7: Ajouter loading state au bouton NetworkPulseCard - Dans FeedView.swift section .networkPulse, ajouter loading state au bouton "Reprendre contact".

- [ ] Task 8: Fix réactivité isRead - S'assurer que FeedItem.isRead est correctement observé. Utiliser `items[index].isRead = true` avec animation pour forcer le re-render SwiftUI.

- [ ] Task 9: Implémenter le callback ProfileDetailView - Dans FeedView.swift, remplacer le callback vide `{ _ in }` par une vraie implémentation qui synchronise les modifications.

- [ ] Task 10: Ajouter logs de debug complets - Ajouter des print() dans: handleItemTap(), markAsRead(), createSynergyConnection(), tous les boutons d'action. Format: "[Feed] Action: description"

- [ ] Task 11: Vérifier et corriger les compteurs de filtres - Dans FeedViewModel, s'assurer que updateCount, synergyCount et reminderCount retournent les bonnes valeurs basées sur les items filtrés.

- [ ] Task 12: Ajouter feedback visuel (toasts) - Ajouter des toasts de confirmation pour: création synergie réussie, erreur réseau, action "reprendre contact". Utiliser les composants existants ou créer un simple overlay.

- [ ] Task 13: Build et test final - Compiler le projet avec xcodebuild, lancer sur simulateur, tester tous les boutons et vérifier les logs de debug. Corriger tout bug restant.
