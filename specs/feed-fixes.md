# Specification: Feed d'Actualité - Corrections Complètes

> **Version**: 1.0 | **Date**: 2026-01-16
> **Scope**: Cross-cutting | **Risk**: Agressif | **Validation**: Build + Logs détaillés

## Overview

Correction de tous les bugs du Feed d'actualité CirKL, incluant les boutons Updates, Synergies et Rappels qui ne fonctionnent pas.

## Fichiers Concernés

| Fichier | Chemin |
|---------|--------|
| FeedView.swift | `Cirkl/Features/Feed/FeedView.swift` |
| FeedViewModel.swift | `Cirkl/Features/Feed/FeedViewModel.swift` |
| FeedItem.swift | `Cirkl/Features/Feed/Models/FeedItem.swift` |
| SynergyCard.swift | `Cirkl/Features/Feed/Components/SynergyCard.swift` |
| UpdateCard.swift | `Cirkl/Features/Feed/Components/UpdateCard.swift` |
| NetworkPulseCard.swift | `Cirkl/Features/Feed/Components/NetworkPulseCard.swift` |
| FeedCard.swift | `Cirkl/Features/Feed/Components/FeedCard.swift` |
| N8NService.swift | `Cirkl/Core/Services/N8NService.swift` |

---

## User Stories

### US1: État du ViewModel Persistant
- [ ] En tant qu'utilisateur, quand je sélectionne un filtre (Updates/Synergies/Rappels), il reste sélectionné même après navigation
- [ ] En tant qu'utilisateur, quand je marque un item comme lu, il reste marqué comme lu

### US2: Bouton "Créer la connexion" (Synergies)
- [ ] En tant qu'utilisateur, quand je tape "Créer la connexion", la synergie est créée en backend
- [ ] En tant qu'utilisateur, je vois un loading indicator pendant la création
- [ ] En tant qu'utilisateur, je vois un message de confirmation ou d'erreur
- [ ] En tant qu'utilisateur, le bouton est désactivé pendant le traitement (pas de double-clic)

### US3: Bouton "Reprendre contact" (Network Pulse)
- [ ] En tant qu'utilisateur, quand je tape "Reprendre contact", une action se produit
- [ ] En tant qu'utilisateur, je peux envoyer un message ou créer un rappel

### US4: Mise à jour visuelle des items
- [ ] En tant qu'utilisateur, quand je lis un item, le point bleu "non lu" disparaît immédiatement
- [ ] En tant qu'utilisateur, les compteurs de filtres reflètent l'état réel

### US5: Modification de profil depuis le Feed
- [ ] En tant qu'utilisateur, quand je modifie un profil depuis le detail sheet, les modifications sont sauvegardées

---

## Acceptance Criteria

### AC1: ViewModel State Management
```
GIVEN le FeedView est affiché
WHEN l'utilisateur sélectionne le filtre "Synergies"
AND navigue vers un autre écran puis revient
THEN le filtre "Synergies" est toujours sélectionné
```

### AC2: Synergie Backend Integration
```
GIVEN une carte synergie est affichée
WHEN l'utilisateur tape "Créer la connexion"
THEN N8NService.createSynergyConnection() est appelé
AND un loading state est affiché
AND l'item est supprimé APRÈS confirmation backend
```

### AC3: Reprendre Contact Fonctionnel
```
GIVEN une carte Network Pulse est affichée
WHEN l'utilisateur tape "Reprendre contact"
THEN une action concrète se produit (conversation ou rappel)
AND un feedback visuel confirme l'action
```

### AC4: Indicateur Non Lu Réactif
```
GIVEN un item non lu est affiché (point bleu visible)
WHEN l'utilisateur tape sur l'item
THEN le point bleu disparaît immédiatement
AND l'item est marqué comme lu dans le ViewModel
```

---

## Edge Cases

### EC1: Erreur Réseau
- Si N8NService échoue lors de création de synergie → afficher erreur toast, ne pas supprimer l'item
- Si timeout → permettre retry

### EC2: Double-Clic
- Les boutons d'action doivent être disabled pendant le traitement
- Empêcher les actions dupliquées

### EC3: État Vide
- Si aucun item dans un filtre → afficher message "Aucun élément"

---

## Out of Scope

- Refactoring complet de l'architecture Feed
- Ajout de nouvelles fonctionnalités
- Tests unitaires (validation manuelle pour MVP)
- Animations avancées

---

## Technical Notes

### Pattern ViewModel
```swift
// AVANT (incorrect)
@State private var viewModel = FeedViewModel()

// APRÈS (correct)
@StateObject private var viewModel = FeedViewModel()
```

### N8N Endpoint pour Synergies
- Endpoint existant: `/webhook/acknowledge-synergies`
- Peut être utilisé ou nouveau endpoint à créer

### Logs de Debug
Ajouter des `print()` statements pour tracer :
- Tap events
- State changes
- Network calls
- Errors

---

## Validation Checklist

- [ ] Build compile sans erreur
- [ ] Filtre Updates fonctionne
- [ ] Filtre Synergies fonctionne
- [ ] Filtre Rappels fonctionne
- [ ] Bouton "Créer la connexion" appelle le backend
- [ ] Bouton "Reprendre contact" déclenche une action
- [ ] Indicateur non lu se met à jour
- [ ] Logs de debug visibles dans console
