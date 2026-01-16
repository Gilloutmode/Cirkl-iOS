# Implementation Plan: Post-Merge Build Fixes

> **Scope**: Cross-cutting | **Risk**: Aggressif | **Validation**: Build + App Launch

## Summary

Le merge de feature/dev a causé des incompatibilités de types entre deux systèmes AI (AIButtonState vs AIAssistantState). Les switch statements sont incomplets et ChatView.swift référence des types inexistants. Correction prioritaire pour restaurer le build.

## Tasks

- [ ] Task 1: Fix CirklAIButton.swift switch statements - Ajouter les cas `synergyLow` et `synergyHigh` dans tous les switch sur `AIButtonState` (lignes ~54, 258, 267, 492, 501). Mapper vers les couleurs/comportements appropriés.

- [ ] Task 2: Restaurer ChatView.swift depuis feature/dev - Exécuter `git show feature/dev:Cirkl/Features/AI/ChatView.swift > Cirkl/Features/AI/ChatView.swift` pour récupérer la version cohérente.

- [ ] Task 3: Créer CirklIntent.swift si manquant - Vérifier si le type `CirklIntent` existe. Si non, créer dans `Cirkl/Core/Models/CirklIntent.swift` avec les cas nécessaires pour ChatView.

- [ ] Task 4: Exporter SynergyContext - Si SynergyContext est défini dans CirklAIButton.swift mais utilisé ailleurs, le déplacer vers un fichier séparé `Cirkl/Core/Models/SynergyContext.swift` ou s'assurer qu'il est accessible.

- [ ] Task 5: Vérifier imports ChatView - S'assurer que tous les imports de ChatView.swift sont corrects: CirklEmptyState, CirklHaptics, ChatHistoryService doivent être accessibles.

- [ ] Task 6: Build validation - Exécuter `xcodebuild -scheme Cirkl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` et corriger toute erreur restante.

- [ ] Task 7: Test launch - Lancer l'app sur simulateur et vérifier que l'écran principal s'affiche sans crash.

- [ ] Task 8: Test Feed navigation - Naviguer vers l'onglet Feed et vérifier qu'il affiche les cards correctement.
