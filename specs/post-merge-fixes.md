# Post-Merge Fix Specifications

> **Date**: 16 Janvier 2026
> **Context**: Merge de feature/dev dans main a causé des incompatibilités
> **Priority**: CRITIQUE - Build cassé

## Problème Principal

Le merge de `feature/dev` (22 commits) dans `main` a créé des incompatibilités entre deux systèmes parallèles pour le bouton AI:

1. **main** utilisait `AIAssistantState` (système debriefing/synergy)
2. **feature/dev** utilisait `AIButtonState` (système polling N8N)

## Erreurs de Compilation

### 1. CirklAIButton.swift - Switch non exhaustifs

**Fichier**: `Cirkl/Features/AI/CirklAIButton.swift`
**Lignes**: 54, 258, 267, 492, 501

**Problème**: `AIButtonState` a 6 cas mais les switch n'en couvrent que 4:
- Couverts: `idle`, `synergy`, `opportunity`, `newConnection`
- Manquants: `synergyLow`, `synergyHigh`

**Fix**: Ajouter les cas manquants dans tous les switch statements.

### 2. ChatView.swift - Types manquants

**Fichier**: `Cirkl/Features/AI/ChatView.swift`

**Problèmes**:
- Ligne 9, 17: `CirklIntent` type inexistant
- Ligne 39, 41: `SynergyContext` hors scope (défini dans CirklAIButton)
- Ligne 81: `CirklEmptyState` hors scope
- Ligne 82: `CirklHaptics` hors scope
- Ligne 210: `ChatHistoryService` hors scope
- Ligne 260: `AIButtonState.debriefing` n'existe pas
- Ligne 260, 285, 286: `SynergyContext.pendingDebriefings` propriété inexistante
- Ligne 293, 294: `SynergyContext.detectedSynergies` propriété inexistante

**Fix**: Rétablir la version de ChatView.swift depuis feature/dev OU adapter au système actuel.

### 3. SynergyContext - Propriétés manquantes

**Fichier**: `Cirkl/Features/AI/CirklAIButton.swift` (ligne 486+)

**Définition actuelle**:
```swift
struct SynergyContext: Equatable {
    // ???
}
```

**Attendu par ChatView**:
```swift
struct SynergyContext {
    var pendingDebriefings: [...]
    var detectedSynergies: [...]
}
```

## Architecture Cible

### Option A: Unifier vers AIButtonState (Recommandé)

Garder le système N8N polling de feature/dev et adapter ChatView:

1. `AIButtonState` reste l'enum principal (6 états)
2. `SynergyContext` est étendu pour inclure les données nécessaires
3. ChatView utilise `SynergyContext` sans référencer le système debriefing

### Option B: Garder les deux systèmes

Plus complexe, risque de confusion.

## Plan de Correction

### Task 1: Fixer CirklAIButton.swift switch statements

Ajouter les cas `synergyLow` et `synergyHigh` dans:
- `currentColor` (ligne ~54)
- Autres switch concernés

**Mapping suggéré**:
```swift
case .synergyLow: return synergyColor.opacity(0.7)
case .synergyHigh: return synergyColor
```

### Task 2: Restaurer ChatView.swift depuis feature/dev

```bash
git show feature/dev:Cirkl/Features/AI/ChatView.swift > Cirkl/Features/AI/ChatView.swift
```

### Task 3: Vérifier les imports et dépendances de ChatView

S'assurer que tous les types utilisés par ChatView existent:
- `CirklIntent` → À créer ou supprimer
- `SynergyContext` → Exporter depuis CirklAIButton ou créer fichier séparé
- `CirklEmptyState` → Existe dans Components/Library/
- `CirklHaptics` → Existe dans Components/Library/Feedback/
- `ChatHistoryService` → Existe dans Core/Services/

### Task 4: Build et validation

```bash
xcodebuild -scheme Cirkl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Fichiers Concernés

| Fichier | Action |
|---------|--------|
| `Cirkl/Features/AI/CirklAIButton.swift` | Compléter switch statements |
| `Cirkl/Features/AI/ChatView.swift` | Restaurer depuis feature/dev |
| `Cirkl/Core/Models/CirklIntent.swift` | Créer si nécessaire |

## Tests de Validation

Après fix, tester:
- [ ] Build passe
- [ ] App se lance sur simulateur
- [ ] Onglet Feed visible
- [ ] Filtres fonctionnent
- [ ] Cards s'ouvrent au tap
- [ ] Bouton AI fonctionne

## Références

- `AIButtonState`: `Cirkl/Core/Services/N8NService.swift:501`
- `AIAssistantState`: `Cirkl/Core/Models/AIAssistantState.swift:14`
- `SynergyContext`: `Cirkl/Features/AI/CirklAIButton.swift:486`
