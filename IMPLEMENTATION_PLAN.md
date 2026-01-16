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

- [x] Task 6: Ajouter loading state aux boutons SynergyCard - Already implemented in SynergyCard.swift with `isLoading: Bool` parameter. Shows ProgressView, changes button text to "Création...", disables both buttons during loading, and dims background. Connected via `viewModel.isItemLoading(item.id)` in FeedView.

- [x] Task 7: Ajouter loading state au bouton NetworkPulseCard - Not required. The "Reprendre contact" button in FeedItemDetailSheet opens a share sheet (synchronous UIActivityViewController). No async network call, so no loading state needed. The share sheet itself provides immediate visual feedback.

- [x] Task 8: Fix réactivité isRead - Updated markAsRead() and markAllAsRead() in FeedViewModel to use copy-and-replace pattern for guaranteed SwiftUI reactivity. Added early return for already-read items. Added animation modifier to feed cards to animate isRead changes. Added debug logging with format "[Feed] markAsRead: itemId → isRead=true".

- [x] Task 9: Implémenter le callback ProfileDetailView - Added `updateConnectionInFeed(OrbitalContact)` method to FeedViewModel that updates connection names in feed items when profile is modified. Updated FeedItemDetailSheet to accept `onConnectionUpdated` callback and pass it to ProfileDetailView. Changed `connectionName` in FeedItem model from `let` to `var` to allow modification. Full data flow: ProfileDetailView → FeedItemDetailSheet → FeedView → FeedViewModel.updateConnectionInFeed().

- [x] Task 10: Ajouter logs de debug complets - Added debug logs with [Feed] format to: SynergyCard buttons ("Créer la connexion" and "Pas maintenant"), UpdateCard onTap, NetworkPulseCard onTap. FeedViewModel methods (markAsRead, createSynergyConnection, handleItemTap) already had comprehensive logging.

- [ ] Task 11: Vérifier et corriger les compteurs de filtres - Dans FeedViewModel, s'assurer que updateCount, synergyCount et reminderCount retournent les bonnes valeurs basées sur les items filtrés.

- [ ] Task 12: Ajouter feedback visuel (toasts) - Ajouter des toasts de confirmation pour: création synergie réussie, erreur réseau, action "reprendre contact". Utiliser les composants existants ou créer un simple overlay.

- [ ] Task 13: Build et test final - Compiler le projet avec xcodebuild, lancer sur simulateur, tester tous les boutons et vérifier les logs de debug. Corriger tout bug restant.
