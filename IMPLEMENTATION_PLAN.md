# Implementation Plan: Feed d'Actualité - Corrections Complètes

> **Scope**: Cross-cutting | **Risk**: Agressif | **Validation**: Build + Logs détaillés

## Summary

Correction de tous les bugs du Feed CirKL : state management incorrect, boutons non fonctionnels (Updates, Synergies, Rappels), réactivité UI cassée, et intégration backend manquante. Refactoring agressif autorisé pour une solution propre.

## Tasks

- [x] Task 1: Fix ViewModel state management - Converted FeedViewModel from @Observable to ObservableObject with @Published properties. Changed FeedView to use @StateObject for proper state persistence across view updates.

- [ ] Task 2: Implémenter loading state dans FeedViewModel - Ajouter une propriété `isLoading: Bool` et `loadingItemId: String?` pour tracker les opérations en cours. Ces états seront utilisés pour désactiver les boutons pendant le traitement.

- [ ] Task 3: Créer la méthode N8NService.createSynergyConnection() - Dans N8NService.swift, ajouter une méthode async pour créer une connexion synergie via le webhook. Utiliser l'endpoint `/webhook/acknowledge-synergies` ou créer un nouveau.

- [ ] Task 4: Connecter createSynergyConnection() au backend - Dans FeedViewModel.createSynergyConnection(), appeler N8NService.createSynergyConnection() avec try/await. Supprimer l'item du Feed UNIQUEMENT après confirmation backend. Ajouter error handling.

- [ ] Task 5: Implémenter le bouton "Reprendre contact" - Dans FeedView.swift, remplacer le TODO du bouton Network Pulse par une vraie action. Options: ouvrir une conversation, créer un rappel, ou proposer un message suggéré par l'IA.

- [ ] Task 6: Ajouter loading state aux boutons SynergyCard - Dans SynergyCard.swift, ajouter un binding `isLoading` pour désactiver le bouton et afficher un ProgressView pendant le traitement.

- [ ] Task 7: Ajouter loading state au bouton NetworkPulseCard - Dans FeedView.swift section .networkPulse, ajouter loading state au bouton "Reprendre contact".

- [ ] Task 8: Fix réactivité isRead - S'assurer que FeedItem.isRead est correctement observé. Utiliser `items[index].isRead = true` avec animation pour forcer le re-render SwiftUI.

- [ ] Task 9: Implémenter le callback ProfileDetailView - Dans FeedView.swift, remplacer le callback vide `{ _ in }` par une vraie implémentation qui synchronise les modifications.

- [ ] Task 10: Ajouter logs de debug complets - Ajouter des print() dans: handleItemTap(), markAsRead(), createSynergyConnection(), tous les boutons d'action. Format: "[Feed] Action: description"

- [ ] Task 11: Vérifier et corriger les compteurs de filtres - Dans FeedViewModel, s'assurer que updateCount, synergyCount et reminderCount retournent les bonnes valeurs basées sur les items filtrés.

- [ ] Task 12: Ajouter feedback visuel (toasts) - Ajouter des toasts de confirmation pour: création synergie réussie, erreur réseau, action "reprendre contact". Utiliser les composants existants ou créer un simple overlay.

- [ ] Task 13: Build et test final - Compiler le projet avec xcodebuild, lancer sur simulateur, tester tous les boutons et vérifier les logs de debug. Corriger tout bug restant.
